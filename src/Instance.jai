// So a bit of nomenclature first:
// A User represent a connected client. It's not meant to hold any persistent data about a player.
// A Profile represent the persistent data from a real world player.
// A Person is what makes it possible to connect a User to a Profile to a Player in an Instance.

Scene :: #import "Scene";
Terrain :: #import "Terrain";
#import "Xar";
#import "Math";
#import "File";
#import "Basic";
#import "Utils";
#import "String";
#import "Profile";
#import "Hash_Table";
#import "Communication";

#scope_export
Person :: struct {
	person_id: int;
	player_id: int;
	profile_id: int;
	user_id: int;

	last_seen_time: Apollo_Time;

	run_stats: Statistics;
}

Instance :: struct {
	id: int;
	id_generation := 0;

	private := false;
	user_created := false;

	name: [64] u8;
	password: [64] u8;

	pick_scene_id: int;
	playing_scene_id: int;
	persons: [..] Person;
	scenes: Xar(Scene.Scene, 2, 20);
	scene_parameters: Scene.Scene_Parameters;

	sync_count_player: Counter(1);
	sync_count_skull: Counter(20);
	sync_moving_frame: Counter(10);
	sync_count_key: Counter(50);

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

	last_activity_time: Apollo_Time;
	max_inactive_duration := 60.0 * 60.0; // seconds

	names_to_scene_id: Table(string, int);
}

reload :: (instance: *Instance) {
	for *instance.scenes {
		Scene.reload(it);
	}
}

free :: (instance: *Instance) {
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
		for scene.players {
			user_id := player_id_to_user_id(instance, it.id);
			if user_id >= 0 {
				queue_send(instance, cmd, user_id);
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
	
	name_count := scene.name.count;
	for scene.name {
		if it == 0 {
			name_count = it_index;
			break;
		}
	}

	return string.{ name_count, scene.name.data };
}

sync :: (instance: *Instance) {
	if check(*instance.sync_count_player) {
		for * scene: instance.scenes {
			for * scene.players {
				msg := Scene.make_sync(it);
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
}
add_scene :: (instance: *Instance, text: string) -> int {
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
					sync_scene := Scene.make_sync(scene, scene.params);
					queue_scene_scoped_broadcast(instance, scene_id, make_command(sync_scene));
				}
			}
		}
	}
}

init_instance :: (instance: *Instance) {
	terrains :: string.[
		"pick",
		"right",
		"turn", // OK
		"intro", // OK
		"roundabout", // OK
		"chamber", // OK
		"buzz", // OK
		"pounding", // OK
		"funny", // OK
		"frogger",
		"volcano", // OK
		"here_and_there", // OK
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
	cheat_action: *Command.Cheat_Action = isa(command.payload, Command.Cheat_Action);
	if cheat_action {
		if cheat_action.kind == .Next_Level {
			for * scene: instance.scenes
				move_playing_scene(instance, scene.next_id);
			return true;
		}
		if cheat_action.kind == .Reset_Level {
			for * scene: instance.scenes
				move_playing_scene(instance, scene.id);
			return true;
		}
		if cheat_action.kind == .Reset_Progression {
			move_playing_scene(instance, instance.pick_scene_id);
			return true;
		}
		// if cheat_action.kind == .Kick {
		// 	user := find_user_by_player_id(cheat_action.player_id);
		// 	if user {
		// 		quit_user(user);
		// 	}
		// 	return true;
		// }
		return true;
	}

	request_stats: *Command.Request_Stats = isa(command.payload, Command.Request_Stats);
	if request_stats {
		for request_stats.player_ids {
			person := find_person_by_player_id(instance, it);
			if person {
				sync_stats: Command.Sync_Stats;
				sync_stats.player_id = it;
				sync_stats.death = person.run_stats.death_count;
				sync_stats.revive = person.run_stats.revive_count;
				sync_stats.wins = person.run_stats.win_count;
				queue_send(instance, make_command(sync_stats), sender_user_id);
			}
		}
	}
	// request_score: *Command.Request_Score = isa(command.payload, Command.Request_Score);
	// if request_score {
	// 	sender := find_person_by_user_id(instance, sender_user_id);
	// 	if sender {
	// 		for request_score.player_ids {
	// 			if it < 0
	// 				continue;
				
	// 			person := find_person_by_player_id(instance, it);
	// 			if person {
	// 				sync_score: Command.Sync_Score;
	// 				sync_score.player_id = it;
	// 				sync_score.score = person.score;
	// 				Scene.add_single_reply(response, sender.player_id, sync_score);
	// 			}
	// 		}
	// 	}

	// 	return true;
	// }

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

		// if is_over
		// 	process_complete_ntp(state, reply);

		return true;
	}

	// connect: *Command.Connect = isa(command.payload, Command.Connect);
	// if connect {
	// 	state.user_generation += 1;

	// 	if connect.token < 0 {
	// 		// The client didn't provide a token, so we generate one for him.
	// 		connect.token = state.user_generation;
	// 	}

	// 	// Let's check the token to see if the user has an history here.
	// 	user: *User = null;
	// 	for * u: state.users {
	// 		if u.token == connect.token {
	// 			// We are going to hijack this user to point to the new connection.
	// 			u.websocket = socket;
	// 			u.last_ping = current_time_monotonic();
	// 			user = u;
	// 			break;
	// 		}
	// 	}

	// 	// If we didn't find a user with the same token, we need to create a new one.
	// 	if !user {
	// 		state.player_generation += 1;

	// 		new_user: User;
	// 		new_user.token = connect.token;
	// 		new_user.person_id = state.instance.persons.count;
	// 		new_user.player_id = state.player_generation;
	// 		new_user.scene_id = state.pick_scene_id;
	// 		new_user.last_ping = current_time_monotonic();
	// 		new_user.websocket = socket;
	// 		array_add(*state.users, new_user);
	// 		user = *state.users[state.users.count - 1];

	// 		person: Instance.Person;
	// 		person.person_id = new_user.person_id;
	// 		person.score = .{};
	// 		array_add(*state.instance.persons, person);

	// 		for state.users {
	// 			// Notify the existing player of a new player
	// 			if it.scene_id != user.scene_id
	// 				continue;
	// 			// Don't notify the new player about themselves
	// 			if it.player_id == user.player_id
	// 				continue;

	// 			spawn: Command.Spawn;
	// 			spawn.player_id = user.player_id;
	// 			spawn.its_you = false;
	// 			spawn.scene_id = it.scene_id;
	// 			append_queue(spawn, it.websocket);
	// 		}

	// 		// Also let's do a virtual message to tell the server a new guy just connected
	// 		spawn: Command.Spawn;
	// 		spawn.player_id = user.player_id;
	// 		spawn.its_you = false;
	// 		spawn.scene_id = user.scene_id;
	// 		append_received_sync(make_command(spawn), null);
	// 	}

	// 	// Then we serve the state of the scene to the new player.
	// 	scene := find_by_scene_id(user.scene_id);
	// 	if scene
	// 		append_queue(Scene.make_sync(scene), user.websocket);

	// 	// We also need to tell the new player about their own spawn
	// 	spawn: Command.Spawn;
	// 	spawn.player_id = user.player_id;
	// 	spawn.its_you = true;
	// 	spawn.scene_id = user.scene_id;
	// 	append_queue(spawn, user.websocket);

	// 	// And finally we can respond to the user with the connection token
	// 	connect_response: Command.Connect;
	// 	connect_response.token = connect.token;
	// 	append_queue(connect_response, user.websocket);

	// 	// bookkeep the socket to token mapping
	// 	table_set(*state.socket_to_token_id, socket, connect.token);
	// 	return true;
	// }

	return false;
}

move_playing_scene :: (instance: *Instance, scene_id: int) {
	old_scene := find_by_scene_id(instance, instance.playing_scene_id);

	scene := find_by_scene_id(instance, scene_id);
	if !scene
		return;

	Scene.restart(scene, scene.params);
	current_time := current_time_monotonic();

	for old_scene.players {
		spawn: Command.Spawn;
		spawn.player_id = it.id;
		spawn.scene_id = scene_id;
		spawn.model_id = it.server.model_id;
		Scene.process(scene, make_command(spawn), current_time, null);
	}

	sync_scene := Scene.make_sync(scene, scene.params);
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

	old_scene.players.count = 0;
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
		Scene.clear_frame_result_frame(*instance.frame_result);
		Scene.update(scene, time, dt, *instance.frame_result);

		for instance.frame_result.broadcast {
			queue_scene_scoped_broadcast(instance, scene.id, it);
		}

		for instance.frame_result.end_level {
			queue_scene_scoped_broadcast(instance, scene.id, make_command(it));
		}

		for instance.frame_result.move_to_player_world {
			move_player_to_currently_playing_world(
				instance, it.player_id, instance.playing_scene_id, it.model_id, it.standin_id
			);
		}

		for instance.frame_result.died {
			queue_scene_scoped_broadcast(instance, scene.id, make_command(it));
		}
		for instance.frame_result.respawn {
			queue_scene_scoped_broadcast(instance, scene.id, make_command(it));
		}
		for instance.frame_result.sync_gate {
			queue_scene_scoped_broadcast(instance, scene.id, make_command(it));
		}
		for instance.frame_result.wipe_scene {
			queue_scene_scoped_broadcast(instance, scene.id, make_command(it));
		}
		for instance.frame_result.explode {
			queue_scene_scoped_broadcast(instance, scene.id, make_command(it));
		}
		for instance.frame_result.antiair_shoot {
			queue_scene_scoped_broadcast(instance, scene.id, make_command(it));
		}
		for instance.frame_result.sync_present {
			queue_scene_scoped_broadcast(instance, scene.id, make_command(it));
		}
		for instance.frame_result.sync_player {
			queue_scene_scoped_broadcast(instance, scene.id, make_command(it));
		}
		for instance.frame_result.sync_safe_zone {
			queue_scene_scoped_broadcast(instance, scene.id, make_command(it));
		}
		for instance.frame_result.died_player_id {
			person := find_person_by_player_id(instance, it);
			if person
				person.run_stats.death_count += 1;
		}
		for instance.frame_result.revived_someone_player_id {
			person := find_person_by_player_id(instance, it);
			if person
				person.run_stats.revive_count += 1;
		}

		should_end_level := false;
		for instance.frame_result.win_player_id {
			person := find_person_by_player_id(instance, it);
			if person {
				should_end_level = true;

				person.run_stats.win_count += 1;
			}
		}

		if scene.end_scene_countdown_started {
			t := current_time_monotonic();
			dt := to_float64_seconds(t - scene.end_scene_countdown_time);
			if dt >= scene.end_scene_countdown {
				scene.end_scene_countdown_started = false;
				move_playing_scene(instance, scene.next_id);
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
			cmd := make_command(Scene.make_sync(it, it.params));
			queue_send(instance, cmd, user_id);

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
	instance: *Instance, user_id: int
) -> bool {
	new_person: Person;
	new_person.person_id = instance.id_generation;
	new_person.player_id = instance.id_generation;
	new_person.user_id = user_id;
	new_person.last_seen_time = current_time_monotonic();
	array_add(*instance.persons, new_person);

	instance.id_generation += 1;
	pick_scene := find_by_scene_id(instance, instance.pick_scene_id);
	if !pick_scene
		return false;

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
	queue_send(instance, make_command(Scene.make_sync(pick_scene, pick_scene.params)), user_id);

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
	sync_scene := Scene.make_sync(new_scene, new_scene.params);
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