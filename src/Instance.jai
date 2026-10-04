// So a bit of nomenclature first:
// A User represent a connected client. It's not meant to hold any persistent data about a player.
// A Profile represent the persistent data from a real world player.
// A Person is what makes it possible to connect a User to a Profile to a Player in an Instance.

Scene :: #import "Scene";
Play_Session :: #import "Play_Session";
Terrain :: #import "Terrain";
#import "Xar";
#import "Math";
#import "File";
#import "Basic";
#import "Utils";
#import "String";
#import "Hash_Table";
#import "Communication";
#import "Common";
#import "Pool";

#scope_export
Person :: struct {
	person_id: int;
	player_id: int;
	profile_id: int;
	user_id: int;

	last_seen_time: Apollo_Time;

	participant_id: int = -1;
}

End_Scene_Event :: struct {
	user_id: int;

	scene_id: int;
	time_ms: int;

	revive_count: int;
	death_count: int;

	winner := false;
}

Terrain_Roster :: struct {
	id: int;
	terrain_ids: [128] int;
}

Instance_Mode :: enum {
	Standard;
	Bomberman;
}

Instance :: struct {
	id: int;
	id_generation := 0;

	mode: Instance_Mode;

	hidden := false;
	private := false;
	user_created := false;

	name: [64] u8;
	password: [64] u8;

	terrain_roster: Terrain_Roster;

	pick_scene_id: int;
	playing_scene_id: int;
	persons: [..] Person;
	play_session: Play_Session.Play_Session;

	scenes: Xar(Scene.Scene, 2, 20);
	scene_parameters: Scene.Scene_Parameters;

	sync_count_player: Counter(1);
	sync_count_key: Counter(50);
	sync_count_bomb: Counter(50);

	process_response: Scene.Process_Response;
	frame_result: Scene.Frame_Result;

	To_Send :: struct {
		command: Command;
		target_user_id: int; // -1 means broadcast
	}
	Received :: struct {
		command: Command;
		sender_user_id: int;
	}

	to_send: [1024] To_Send;
	to_send_count := 0;

	received: [1024] Received;
	received_count := 0;
	debug_pending: [128] Debug_Pending;
	debug_pending_count := 0;

	last_activity_time: Apollo_Time;
	max_inactive_duration := 60.0 * 60.0; // seconds

	names_to_scene_id: Table(string, int);

	end_scene_events: [..] End_Scene_Event;

	Bomberman :: struct {
		max_player_count: int;
	}
}

init_play_session :: (instance: *Instance, allocator := context.allocator) {
	// Called after the instance id is assigned. Do not allocate in a Scene pool:
	// a session spans runs, and Instances themselves can move in the server array.
	if !instance.play_session.initialized
		Play_Session.init(*instance.play_session, allocator, instance.id, 1);
}

make_instance_sync_scene :: (instance: *Instance, scene: *Scene.Scene) -> Command.Sync_Scene {
	init_play_session(instance);
	message := Scene.make_sync_scene(scene, scene.params);
	message.instance_id = instance.id;
	message.session_id = instance.play_session.id;
	message.session_revision = instance.play_session.revision;
	return message;
}

make_end_level_message :: (instance: *Instance, scene: *Scene.Scene, result: Play_Session.Result) -> Command.End_Level {
	message: Command.End_Level;
	message.result = Play_Session.make_result_message(result);
	message.winner_id = result.winner_id;
	message.next_scene_id = scene.next_id;
	message.next_level_scheduled_in_seconds = max(cast(float64) 0,
		scene.end_scene_countdown - to_float64_seconds(current_time_monotonic() - scene.end_scene_countdown_time)).(float32);
	message.time = (result.duration_ms / 1000.0).(float32);
	message.most_death_id = result.most_death_id;
	message.most_revive_id = result.most_revive_id;
	for i: 0..min(message.best_scores_id.count, result.ranked_player_ids.count)-1
		message.best_scores_id[i] = result.ranked_player_ids[i];
	message.instance_id = instance.id;
	message.session_id = instance.play_session.id;
	message.session_revision = instance.play_session.revision;
	return message;
}

consume_level_events :: (instance: *Instance, scene: *Scene.Scene) {
	session := *instance.play_session;
	broadcast_cursor := 0;
	for event: instance.frame_result.level_events {
		level := Play_Session.ensure_level(session, scene.id, event.run_generation);
		if #complete event.kind == {
			case .Participation;
				Play_Session.register_level_player(session, level, event.player_id, event.icon_id);
			case .Death;
				Play_Session.record_level_death(session, level, event.player_id);
			case .Revive;
				Play_Session.record_level_revive(session, level, event.player_id, event.other_player_id);
			case .Finish;
				if level.completed_round_id continue;
				for i: broadcast_cursor..event.broadcast_index-1
					queue_scene_scoped_broadcast(instance, scene.id, instance.frame_result.broadcast[i]);
				broadcast_cursor = event.broadcast_index;
				next_scene := find_by_scene_id(instance, scene.next_id);
				next_name := ifx next_scene then string_from_arr(next_scene.info.name) else "";
				settled := Play_Session.complete_level(session, level, scene.info.id,
					string_from_arr(scene.info.name), next_name, event.player_id,
					event.duration_ms, scene.params.personal_share_weight);
				queue_scene_scoped_broadcast(instance, scene.id, make_command(make_end_level_message(instance, scene, settled.*)));
		}
	}
	for i: broadcast_cursor..instance.frame_result.broadcast.count-1
		queue_scene_scoped_broadcast(instance, scene.id, instance.frame_result.broadcast[i]);
	// A wipe can occur inside update_scene. Retire that generation's ledger even
	// when the frame has no events after the restart; completed history is untouched.
	Play_Session.ensure_level(session, scene.id, scene.run_generation);
}

reload :: (instance: *Instance) {
	for *instance.scenes {
		Scene.reload(it);
	}
}

free :: (instance: *Instance) {
	Play_Session.free(*instance.play_session);
	array_free(instance.persons);
	for *instance.scenes
		Scene.free(it);
	xar_reset(*instance.scenes);
	deinit(*instance.names_to_scene_id);
}

find_scene_of_player_id :: (instance: Instance, player_id: int) -> *Scene.Scene {
	for * instance.scenes {
		player := Scene.find_by_player_id(it, player_id);
		if player {
			return it;
		}
	}
	return null;
}

player_id_to_user_id :: (instance: Instance, player_id: int) -> int {
	for * instance.persons {
		if it.player_id == player_id {
			return it.user_id;
		}
	}
	return -1;
}

queue_send :: (instance: *Instance, cmd: Command, target_user_id: int) {
	if instance.to_send_count >= instance.to_send.count {
		print("Instance to_send overflow!\n");
		return;
	}

	entry := *instance.to_send[instance.to_send_count];
	entry.command = cmd;
	entry.target_user_id = target_user_id;
	instance.to_send_count += 1;
}

queue_scene_scoped_broadcast :: (instance: *Instance, scene_id: int, cmd: Command) {
	scene := find_by_scene_id(instance, scene_id);
	if scene {
		cmd_timestamped := cmd;
		cmd_timestamped.sent_timestamp = scene.server.clock;
		for scene.players {
			user_id := player_id_to_user_id(instance, it.id);
			if user_id >= 0 {
				queue_send(instance, cmd_timestamped, user_id);
			}
		}
	}
}

find_person_by_id :: (instance: Instance, person_id: int) -> *Person {
	for * instance.persons {
		if it.person_id == person_id {
			return it;
		}
	}
	return null;
}

find_person_by_user_id :: (instance: Instance, user_id: int) -> *Person {
	for * instance.persons {
		if it.user_id == user_id {
			return it;
		}
	}
	return null;
}

find_person_by_player_id :: (instance: Instance, player_id: int) -> *Person {
	for * instance.persons {
		if it.player_id == player_id {
			return it;
		}
	}
	return null;
}

get_current_level_name :: (instance: Instance) -> string {
	scene := find_by_scene_id(instance, instance.playing_scene_id);
	if !scene
		return "??";
	
	name_count := scene.info.name.count;
	for scene.info.name {
		if it == 0 {
			name_count = it_index;
			break;
		}
	}

	return string.{ name_count, scene.info.name.data };
}

sync :: (instance: *Instance) {
	if check(*instance.sync_count_player) {
		for * scene: instance.scenes {
			for * scene.players {
				msg := Scene.make_sync_player(it);
				queue_scene_scoped_broadcast(instance, scene.id, make_command(msg));
			}
		}
	}

	if check(*instance.sync_count_key) {
		for * scene: instance.scenes {
			for * scene.keys {
				msg: Command.Sync_Key;
				msg.key_id = it.id;
				msg.holder = it.holder;
				msg.position = it.server.position;
				queue_scene_scoped_broadcast(instance, scene.id, make_command(msg));
			}
		}
	}

	if check(*instance.sync_count_bomb) {
		for * scene: instance.scenes {
			for * scene.bombs {
				msg := Scene.make_sync_bomb(it);
				queue_scene_scoped_broadcast(instance, scene.id, make_command(msg));
			}
			for * scene.bomb_spawners {
				msg := Scene.make_sync_bomb_spawner(it);
				queue_scene_scoped_broadcast(instance, scene.id, make_command(msg));
			}
		}
	}
}

set_bomberman_scene :: (instance: *Instance, terrain_text: string, info: Scene.Scene_Info) -> int {
	scene := xar_add(*instance.scenes, .{});
	Scene.make(scene);
	scene.id = 0;
	scene.is_server = true;
	scene.server_rng.s[0] = 123456789;
	scene.server_rng.s[1] = 987654321;
	Scene.clear_scene_run(scene);
	Terrain.parse_terrain(terrain_text, scene);
	scene.params = instance.scene_parameters;
	scene.auto_revive |= scene.params.auto_revive;
	scene.info = info;
	scene.params.mode = .Bomberman;
	return scene.id;
}

add_scene :: (instance: *Instance, text: string, info: Scene.Scene_Info) -> int {
	scene := xar_add(*instance.scenes, .{});
	Scene.make(scene);
	scene.id = instance.scenes.count + 1;
	scene.is_server = true;
	scene.server_rng.s[0] = 123456789;
	scene.server_rng.s[1] = 987654321;
	Scene.clear_scene_run(scene);
	Terrain.parse_terrain(text, scene);
	scene.params = instance.scene_parameters;
	scene.auto_revive |= scene.params.auto_revive;
	scene.info = info;
	return scene.id;
}

handle_file_change :: (instance: *Instance, path: string) {
	for scene_id, name: instance.names_to_scene_id {
		if contains(path, name) {
			data, ok := read_entire_file(path,, temp);
			if ok {
				scene := find_by_scene_id(instance, scene_id);
				if scene {
					Scene.clear_scene_run(scene);
					Terrain.parse_terrain(data, scene);
					sync_scene := make_instance_sync_scene(instance, scene);
					queue_scene_scoped_broadcast(instance, scene_id, make_command(sync_scene));
				}
			}
		}
	}
}

init_instance_with_custom_terrain :: (
	instance: *Instance, terrain_data: string
) {
	instance.pick_scene_id = add_scene(instance, terrain_data, .{});
	instance.playing_scene_id = instance.pick_scene_id;
	instance.last_activity_time = current_time_monotonic();
}

init_instance :: (instance: *Instance) {
	terrains :: string.[
		"pick",
		"good_intro", // OK
		"good_too", // OK
		"good_ice", // Ok
		"good_night", // OK
		"good_three", // OK
		"good_pounding", // OK
		"good_light", // OK
		"good_bomb", // OK
		"good_steady", // OK
		"good_turn", // OK
		"big_round",
		"roundabout",
		"funny",
		"chamber",
		"buzz",
		"right",
		"frogger",
		"here_and_there",
		"volcano",
		"tetris",
	];
	
	for terrains {
		txt := sprint("../assets/terrain/%.terrain", it);
		data, ok := read_entire_file(txt);
		id := add_scene(instance, data);

		table_add(*instance.names_to_scene_id, it, id);
	}
	if instance.scenes.count > 0 {
		instance.pick_scene_id = instance.scenes[0].id;
		for 0..instance.scenes.count-2 {
			instance.scenes[it].next_id = instance.scenes[it+1].id;
		}
		instance.playing_scene_id = instance.scenes[0].next_id;
	}

	instance.last_activity_time = current_time_monotonic();
}

process :: (
	instance: *Instance, command: Command, sender_user_id: int, response: *Scene.Process_Response
) -> bool {
	if process_instance_debug(instance, command, sender_user_id) return true;
	respawn_request := isa(command.payload, Command.Ask_Respawn);
	if respawn_request {
		person := find_person_by_user_id(instance, sender_user_id);
		if !person || person.player_id != respawn_request.player_id return true;
	}
	cheat_action: *Command.Cheat_Action = isa(command.payload, Command.Cheat_Action);
	if cheat_action {
		person := find_person_by_user_id(instance, sender_user_id);
		if !person || person.player_id != debug_host_player_id(instance) return true;
		if cheat_action.kind == .Next_Level {
			scene := find_by_scene_id(instance, instance.playing_scene_id);
			if scene move_playing_scene(instance, scene.next_id);
			return true;
		}
		if cheat_action.kind == .Reset_Level {
			move_playing_scene(instance, instance.playing_scene_id);
			return true;
		}
		if cheat_action.kind == .Reset_Progression {
			move_playing_scene(instance, instance.pick_scene_id);
			return true;
		}
		if cheat_action.kind == .Kick {
			person := find_person_by_player_id(instance, cheat_action.player_id);
			if person {
				remove_person(instance, person.user_id);
			}
			return true;
		}
		return true;
	}

	request_stats: *Command.Request_Stats = isa(command.payload, Command.Request_Stats);
	if request_stats {
		for request_stats.player_ids {
			person := find_person_by_player_id(instance, it);
			if person {
				sync_stats: Command.Sync_Stats;
				sync_stats.player_id = it;
				participant := Play_Session.find_participant(*instance.play_session, person.participant_id);
				sync_stats.death = participant.death_count;
				sync_stats.revive = participant.revive_count;
				sync_stats.wins = participant.win_count;
				queue_send(instance, make_command(sync_stats), sender_user_id);
				return true;
			}
		}
	}

	signal_pick: *Command.Signal_Pick = isa(command.payload, Command.Signal_Pick);
	if signal_pick {
		person := find_person_by_user_id(instance, sender_user_id);
		if person {
			scene := find_scene_of_player_id(instance, person.player_id);
			if scene {
				Scene.process(scene, command, current_time_monotonic(), response);
				return true;
			}
		}
	}

	ntp: *Command.NTP = isa(command.payload, Command.NTP);
	if ntp {
		is_over := false;
		send_back := false;
		reply := ntp.*;
		if reply.t0 == FLOAT64_MAX {
			reply.t0 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		}
		else if reply.t1 == FLOAT64_MAX {
			reply.t1 = to_float64_seconds(current_time_monotonic());
			reply.t2 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		}
		else if reply.t2 == FLOAT64_MAX {
			reply.t2 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		}
		else if reply.t3 == FLOAT64_MAX {
			reply.t3 = to_float64_seconds(current_time_monotonic());
			reply.t4 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		} else {
			is_over = true;
			send_back = false;
		}

		if send_back && response
			Scene.add(response, -1, reply);

		return true;
	}

	return false;
}

move_playing_scene :: (instance: *Instance, scene_id: int, should_register := false) {
	old_scene := find_by_scene_id(instance, instance.playing_scene_id);

	scene := find_by_scene_id(instance, scene_id);
	if !scene
		return;

	if should_register {
		level := Play_Session.find_level(*instance.play_session, old_scene.id, old_scene.run_generation);
		result := ifx level then Play_Session.find_result(*instance.play_session, level.completed_round_id) else null;
		if result for result.players {
			event: End_Scene_Event;
			event.user_id = player_id_to_user_id(instance, it.player_id);
			participant := Play_Session.find_participant(*instance.play_session, it.participant_id);
			if participant event.user_id = player_id_to_user_id(instance, participant.player_id);
			event.scene_id = result.level_id;
			event.time_ms = result.duration_ms;
			event.revive_count = it.revive_count;
			event.death_count = it.death_count;
			event.winner = it.player_id == result.winner_id;
			array_add(*instance.end_scene_events, event);
		}
	}

	Scene.restart(scene, scene.params);
	Play_Session.ensure_level(*instance.play_session, scene.id, scene.run_generation);
	current_time := current_time_monotonic();

	for old_scene.players {
		spawn: Command.Spawn;
		spawn.player_id = it.id;
		spawn.scene_id = scene_id;
		spawn.model_id = it.server.model_id;
		Scene.process(scene, make_command(spawn), current_time, null);
	}

	sync_scene := make_instance_sync_scene(instance, scene);
	for * scene.players {
		user := player_id_to_user_id(instance, it.id);
		if user >= 0 {
			control: Command.Give_Control;
			control.player_id = it.id;

			queue_send(instance, make_command(sync_scene), user);
			queue_send(instance, make_command(control), user);
		}
	}
	instance.playing_scene_id = scene_id;

	if old_scene != scene old_scene.players.count = 0;
}
gc_persons :: (instance: *Instance) {
	now := current_time_monotonic();
	for instance.persons {
		dt := to_float64_seconds(now - it.last_seen_time);

		if dt > 60 {
			remove_person(instance, it.user_id);
		}
	}
}

update_instance :: (instance: *Instance, dt: float32) {
	if instance.persons.count == 0
		return;
	init_play_session(instance);

	Scene.clear(*instance.process_response);
	time := current_time_monotonic();

	for 0..instance.received_count-1 {
		received := instance.received[it];
		sender_id := received.sender_user_id;

		person : *Person;
		person = find_person_by_user_id(instance, sender_id);
		if person {
			person.last_seen_time = current_time_monotonic();
		}

		// We give priority to the instance to respond to any command as it sees fit.
		if process(instance, received.command, sender_id, *instance.process_response)
			continue;

		// Then the scenes get to process the command.
		for * scene: instance.scenes {
			if Scene.process(scene, received.command, time, *instance.process_response)
				break scene;
		}
	}
	instance.received_count = 0; // Clear the queue after processing.

	for instance.process_response.entries {
		ntp: *Command.NTP = isa(it.command.payload, Command.NTP);
		if ntp {
			if ntp.player_id < 0 {
				queue_send(instance, it.command, -1);
			} else {
				user_id := player_id_to_user_id(instance, ntp.player_id);
				if user_id >= 0 {
					queue_send(instance, it.command, user_id);
				}
			}
		} else {
			if it.scene_id >= 0 {
				queue_scene_scoped_broadcast(instance, it.scene_id, it.command);
			}
			else {
				user_id := player_id_to_user_id(instance, it.player_id);
				if user_id >= 0 {
					queue_send(instance, it.command, user_id);
				}
			}
		}
	}

	sync(instance);
	if !instance.frame_result.made
		Scene.make(*instance.frame_result);

	for * scene: instance.scenes {
		Play_Session.ensure_level(*instance.play_session, scene.id, scene.run_generation);
		Scene.clear_frame_result_frame(*instance.frame_result);
		apply_instance_debug(instance, scene);
		Scene.update_scene(scene, time, dt, *instance.frame_result);

		for instance.frame_result.died_player_id {
			person := find_person_by_player_id(instance, it);
			if person {
				participant := Play_Session.find_participant(*instance.play_session, person.participant_id);
				participant.death_count += 1;
				instance.play_session.revision += 1;

				player := Scene.find_by_player_id(scene, it);
				if player {
					sync_score: Command.Sync_Score;
					sync_score.player_id = it;
					sync_score.souls = player.server.souls;
					queue_send(instance, make_command(sync_score), person.user_id);
				}
			}
		}

		for instance.frame_result.revived_someone_player_id {
			person := find_person_by_player_id(instance, it);
			if person {
				participant := Play_Session.find_participant(*instance.play_session, person.participant_id);
				participant.revive_count += 1;
				instance.play_session.revision += 1;

				player := Scene.find_by_player_id(scene, it);
				if player {
					sync_score: Command.Sync_Score;
					sync_score.player_id = it;
					sync_score.souls = player.server.souls;
					queue_send(instance, make_command(sync_score), person.user_id);
				}
			}
		}

		for instance.frame_result.win_player_id {
			person := find_person_by_player_id(instance, it);
			if person {
				participant := Play_Session.find_participant(*instance.play_session, person.participant_id);
				participant.win_count += 1;
				instance.play_session.revision += 1;
			}
		}

		consume_level_events(instance, scene);

		for instance.frame_result.move_instance_to_world {
			move_player_to_currently_playing_world(
				instance, it.player_id, instance.playing_scene_id, it.model_id, it.standin_id
			);
		}

		if scene.end_scene_countdown_started {
			t := current_time_monotonic();
			dt := to_float64_seconds(t - scene.end_scene_countdown_time);
			if dt >= scene.end_scene_countdown {
				scene.end_scene_countdown_started = false;
				move_playing_scene(instance, scene.next_id, should_register=true);
			}
		}

	}

	gc_persons(instance);

	// for * state.users {
	// 	if to_float64_seconds(current_time_monotonic() - it.last_ping) > TIMEOUT_DURATION {
	// 		quit_user(it);
	// 	}
	// }
}

find_by_scene_id :: (instance: Instance, scene_id: int) -> *Scene.Scene {
	for * instance.scenes {
		if it.id == scene_id {
			return it;
		}
	}
	return null;
}

resync_old_person :: (instance: *Instance, user_id: int) {
	person := find_person_by_user_id(instance, user_id);
	if !person
		return;

	scene: *Scene.Scene;
	for * instance.scenes {
		player := Scene.find_by_player_id(it, person.player_id);
		if player {
			cmd := make_command(make_instance_sync_scene(instance, it));
			queue_send(instance, cmd, user_id);
			if it.end_scene_countdown_started {
				level := Play_Session.find_level(*instance.play_session, it.id, it.run_generation);
				result := ifx level then Play_Session.find_result(*instance.play_session, level.completed_round_id) else null;
				if result queue_send(instance, make_command(make_end_level_message(instance, it, result.*)), user_id);
			}

			spawn: Command.Spawn;
			spawn.player_id = person.player_id;
			spawn.scene_id = it.id;
			spawn.model_id = player.server.model_id;
			spawn.its_you = true;
			queue_send(instance, make_command(spawn), user_id);

			return;
		}
	}
}

add_new_person :: (
	instance: *Instance, user_id: int, profile_id: int = -1, display_name: string = ""
) -> bool {
	pick_scene := find_by_scene_id(instance, instance.pick_scene_id);
	if !pick_scene return false;
	new_person: Person;
	new_person.person_id = instance.id_generation;
	new_person.player_id = instance.id_generation;
	init_play_session(instance);
	new_person.user_id = user_id;
	new_person.profile_id = profile_id;
	new_person.participant_id = Play_Session.join(*instance.play_session, new_person.player_id, profile_id, display_name);
	new_person.last_seen_time = current_time_monotonic();
	array_add(*instance.persons, new_person);

	instance.id_generation += 1;

	// Notify existing players in the pick scene about the new person
	for instance.persons {
		player := Scene.find_by_player_id(pick_scene, it.player_id);
		if player {
			spawn: Command.Spawn;
			spawn.player_id = new_person.player_id;
			spawn.scene_id = instance.pick_scene_id;
			spawn.model_id = player.server.model_id;
			spawn.its_you = false;
			queue_send(instance, make_command(spawn), it.user_id);
		}
	}

	Scene.spawn_player(pick_scene, new_person.player_id, -1);
	queue_send(instance, make_command(make_instance_sync_scene(instance, pick_scene)), user_id);

	spawn: Command.Spawn;
	spawn.player_id = new_person.player_id;
	spawn.scene_id = instance.pick_scene_id;
	spawn.model_id = -1;
	spawn.its_you = true;
	queue_send(instance, make_command(spawn), user_id);

	return true;
}

remove_person :: (instance: *Instance, user_id: int) {
	person := find_person_by_user_id(instance, user_id);
	if !person
		return;

	Play_Session.leave(*instance.play_session, person.participant_id);

	// Notify existing players in the pick scene about the departing person
	scene := find_scene_of_player_id(instance, person.player_id);
	if scene {
		quit: Command.Quit;
		quit.player_id = person.player_id;
		Scene.process(scene, make_command(quit), current_time_monotonic(), null);
		queue_scene_scoped_broadcast(instance, scene.id, make_command(quit));

		for * scene.players {
			if it.id == person.player_id {
				remove it;
				break;
			}
		}
	}

	// Finally remove the person from the instance
	for * instance.persons {
		if it.user_id == user_id {
			remove it;
			break;
		}
	}
}

move_player_to_currently_playing_world :: (
	instance: *Instance, player_id: int, to_scene_id: int, with_model_id: int, from_standin_id: int
)
{
	// Find the scene from where the player is coming from.
	old_scene: *Scene.Scene = null;
	{
		player: *Scene.Player = null;
		for * scene: instance.scenes {
			old_scene = scene;
			player = Scene.find_by_player_id(scene, player_id);
			if player
				break;
		}
		if !player
			return;

		// Remove the player from the old scene.
		for * old_scene.players {
			if it.id == player_id {
				remove it;
				break;
			}
		}
	}

	// Now find the new scene to spawn the player into.
	new_scene := find_by_scene_id(instance, to_scene_id);
	if !new_scene
		return;

	// Create the new player in the new scene.
	spawn: Command.Spawn;
	spawn.player_id = player_id;
	spawn.scene_id = to_scene_id;
	spawn.model_id = with_model_id;
	// Process it on the server
	Scene.process(new_scene, make_command(spawn), current_time_monotonic(), null);

	// Send a sync of the new scene to the moved player.
	sync_scene := make_instance_sync_scene(instance, new_scene);
	user_id := player_id_to_user_id(instance, player_id);
	queue_send(instance, make_command(sync_scene), user_id);

	// Signal to the rest of the users in the scene that a new player popped in.
	for new_scene.players {
		if it.id == player_id
			continue;

		user_id := player_id_to_user_id(instance, it.id);
		if user_id < 0
			continue;

		spawn: Command.Spawn;
		spawn.player_id = player_id;
		spawn.scene_id = to_scene_id;
		spawn.model_id = with_model_id;
		queue_send(instance, make_command(spawn), user_id);
	}

	// Signal to the rest of the users in the old scene that a player left.
	for old_scene.players {
		quit: Command.Quit;
		quit.player_id = player_id;
		queue_send(instance, make_command(quit), player_id_to_user_id(instance, it.id));
	}
}

Debug_Pending :: struct {
	request: Command.Debug_Request;
	sender_user_id: int;
	scene_id: int;
	run_generation: int;
}

debug_host_player_id :: (instance: *Instance) -> int {
	host := -1;
	for instance.persons {
		if it.player_id >= 0 && it.user_id >= 0 && (host < 0 || it.player_id < host) host = it.player_id;
	}
	return host;
}

debug_reply :: (instance: *Instance, request: Command.Debug_Request, sender_user_id: int,
	status: Debug_Status, message: string) {
	reply: Command.Debug_Reply;
	reply.kind = request.kind;
	reply.status = status;
	reply.host_player_id = debug_host_player_id(instance);
	person := find_person_by_user_id(instance, sender_user_id);
	if person reply.sender_player_id = person.player_id;
	reply.message = message;
	queue_send(instance, make_command(reply), sender_user_id);
}

process_instance_debug :: (instance: *Instance, command: Command, sender_user_id: int) -> bool {
	request := isa(command.payload, Command.Debug_Request);
	if !request return false;
	person := find_person_by_user_id(instance, sender_user_id);
	if !person { debug_reply(instance, request.*, sender_user_id, .Rejected, "You are not in this instance."); return true; }
	if request.kind == .Who_Host {
		debug_reply(instance, request.*, sender_user_id, .Accepted, "Host is the lowest player id in this instance.");
		return true;
	}
	if person.player_id != debug_host_player_id(instance) {
		debug_reply(instance, request.*, sender_user_id, .Rejected, "Only the host may run this command."); return true;
	}
	if request.kind.(int) < Debug_Operation.Kill_Self.(int) || request.kind.(int) > Debug_Operation.Who_Host.(int) || request.kind == .Kick {
		debug_reply(instance, request.*, sender_user_id, .Invalid, "Unknown debug operation."); return true;
	}
	value := request.*;
	scene: *Scene.Scene;
	if value.kind == .Next_Level || value.kind == .Prev_Level || value.kind == .Wipe_Level {
		scene = find_by_scene_id(instance, instance.playing_scene_id);
	} else if value.kind == .Kill || value.kind == .Revive || value.kind == .Kill_Self || value.kind == .Revive_Self {
		if value.kind == .Kill_Self || value.kind == .Revive_Self value.target_id = person.player_id;
		if value.target_id >= 0 && find_person_by_player_id(instance, value.target_id)
			scene = find_scene_of_player_id(instance.*, value.target_id);
	} else {
		scene = find_scene_of_player_id(instance.*, person.player_id);
	}
	if !scene { debug_reply(instance, value, sender_user_id, .Invalid, "Target player or level was not found."); return true; }
	if instance.debug_pending_count >= instance.debug_pending.count {
		debug_reply(instance, value, sender_user_id, .Rejected, "Debug command queue is full."); return true;
	}
	instance.debug_pending[instance.debug_pending_count] = .{ value, sender_user_id, scene.id, scene.run_generation };
	instance.debug_pending_count += 1;
	return true;
}

apply_instance_debug :: (instance: *Instance, scene: *Scene.Scene) {
	remaining := 0;
	for i: 0..instance.debug_pending_count-1 {
		pending := instance.debug_pending[i];
		if pending.scene_id != scene.id { instance.debug_pending[remaining] = pending; remaining += 1; continue; }
		request := pending.request;
		person := find_person_by_user_id(instance, pending.sender_user_id);
		if !person || person.player_id != debug_host_player_id(instance) {
			debug_reply(instance, request, pending.sender_user_id, .Rejected, "Only the current host may run this command."); continue;
		}
		if pending.run_generation != scene.run_generation {
			debug_reply(instance, request, pending.sender_user_id, .Rejected, "Level changed before the command could run."); continue;
		}
		message := "";
		success := false;
		if request.kind == .Next_Level || request.kind == .Prev_Level || request.kind == .Wipe_Level {
			target_scene_id := scene.id;
			if request.kind == .Next_Level target_scene_id = scene.next_id;
			if request.kind == .Prev_Level {
				target_scene_id = -1;
				for instance.scenes if it.id != instance.pick_scene_id && it.next_id == scene.id { target_scene_id = it.id; break; }
			}
			if target_scene_id < 0 || !find_by_scene_id(instance, target_scene_id) {
				message = "No level exists in that direction.";
			} else {
				move_playing_scene(instance, target_scene_id);
				success = true;
				message = tprint("Playing level %.", target_scene_id);
			}
		} else {
			success, message = Scene.apply_debug(scene, request, *instance.frame_result);
		}
		debug_reply(instance, request, pending.sender_user_id, ifx success then .Accepted else .Invalid, message);
	}
	instance.debug_pending_count = remaining;
}
