Terrain :: #import "Terrain";
#import "http";
#import "String";
#import "Basic";
#import "Math";
#import "Communication";
Scene :: #import "Scene";
#import "Thread";
#import "Hash_Table";
#import "Utils";
#import "File";
Platform :: #import "Platform";
#import "File_Watcher";

TIMEOUT_DURATION := 1000.0;

prepare_typed_message :: (_payload: $T) -> [] u8 {
	payload := _payload;

	buffer: [..] u8;
	buffer.allocator = temp;

	#if T == Command {
		payload.sent_timestamp = to_float64_seconds(current_time_monotonic());
		serialize(payload, *buffer);
	}

	return buffer;
}

scene_scoped_broadcast :: (scene_id: int, data: $T) {
	message := prepare_typed_message(data);
	scene_scoped_broadcast_prepared(scene_id, message);
}
broadcast :: (server: Websocket_Server, data: $T) {
	message := prepare_typed_message(data);
	broadcast_prepared(server, message);
}
scene_scoped_broadcast_prepared :: (scene_id: int, payload: [] u8) {
	for state.users {
		if it.scene_id == scene_id {
			websocket_send(it.websocket, .{ data = payload.data, count = payload.count }, .BINARY);
		}
	}
}
broadcast_prepared :: (server: Websocket_Server, payload: [] u8) {
	for server.websockets {
		websocket_send(it, .{ data = payload.data, count = payload.count }, .BINARY);
	}
}

send :: (ws: *Websocket, data: $T) {
	message := prepare_typed_message(data);
	send_prepared(ws, message);
}
send_prepared :: (ws: *Websocket, prepared_payload: [] u8) {
	str: string;
	str.data = prepared_payload.data;
	str.count = prepared_payload.count;

	websocket_send(ws, str, .BINARY);
}

User :: struct {
	token := -1;

	player_id: int;
	scene_id: int;
	websocket: *Websocket;

	last_ping: Apollo_Time;
}

State :: struct {
	server: *Websocket_Server = null;
	last_sync_sent_time: Apollo_Time;

	users: [..] User;

	sync_count_player: Counter(1);
	sync_count_skull: Counter(20);
	sync_moving_frame: Counter(10);
	sync_count_key: Counter(50);

	player_generation := 0;
	user_generation := 0;

	socket_to_token_id: Table(*Websocket, int);

	Queue :: struct(N: int) {
		commands : [N] Command;
		socket   : [N] *Websocket; // null is for broadcast
		count    := 0;
	};

	queue: Queue(128);
	queue_semaphore: Semaphore;

	received: Queue(1024);
	received_semaphore: Semaphore;

	sync_period: Period(0.05);
	tick_period: Period(0.005);

	NTP_Result :: struct {
		offset: float64 = 0;
		ping: float64 = 0;
		time: float64 = 0;
	}

	ntp_history: [64] NTP_Result;
	ntp_history_cursor := 0;

	scenes: [..] Scene.Scene;

	pick_scene_id: int;
	first_world_id: int;
	second_world_id: int;

	playing_scene_id: int;
}
state: State;

find_user_by_player_id :: (player_id: int) -> *User {
	for * user: state.users {
		if user.player_id == player_id
			return user;
	}
	return null;
}

find_by_scene_id :: (scene_id: int) -> *Scene.Scene {
	for * state.scenes {
		if it.id == scene_id
			return it;
	}
	return null;
}

append_queue :: (cmd: $T, socket: *Websocket) {
	wait_for(*state.queue_semaphore);
	defer {
		signal(*state.queue_semaphore);
	}

	if state.queue.count >= state.queue.N {
		print("Queue overflow!\n");
		return;
	}

	state.queue.socket[state.queue.count] = socket;
	state.queue.commands[state.queue.count] = make_command(cmd);
	state.queue.count += 1;
}

append_received :: (cmd: Command, socket: *Websocket) {
	wait_for(*state.received_semaphore);
	defer {
		signal(*state.received_semaphore);
	}

	if state.received.count >= state.received.N {
		print("Received queue overflow!\n");
		return;
	}

	state.received.socket[state.received.count] = socket;
	state.received.commands[state.received.count] = cmd;
	state.received.count += 1;
}

append_received_sync :: (cmd: Command, socket: *Websocket) {
	if state.received.count >= state.received.N {
		print("Received queue overflow!\n");
		return;
	}

	state.received.socket[state.received.count] = socket;
	state.received.commands[state.received.count] = cmd;
	state.received.count += 1;
}

parse_message :: (data: [] u8) -> Command, bool {
	if data.count < 8 {
		print("Message too short: %\n", data);
		return .{}, false;
	}

	size := (cast(*u64)data.data).*;
	if size > xx data.count {
		print("Message size mismatch: expected % but got %\n", size, data.count);
		return .{}, false;
	}

	cmd, ok := deserialize(data);

	if !ok {
		print("Failed to deserialize command\n");
		return .{}, false;
	}

	return cmd, true;
}

sync :: (state: State) {
	reset_temporary_storage();
	if check(*state.sync_count_player) {
		for * scene: state.scenes {
			for * scene.players {
				msg := Scene.make_sync(it);
				scene_scoped_broadcast(scene.id, make_command(msg));
			}
		}
	}

	if check(*state.sync_moving_frame) {
		for * scene: state.scenes {
			for * scene.moving_frames {
				msg := Scene.make_sync(it);
				scene_scoped_broadcast(scene.id, make_command(msg));
			}
		}
	}

	if check(*state.sync_count_skull) {
		for * scene: state.scenes {
			for * scene.skulls {
				msg := Scene.make_sync(it);
				scene_scoped_broadcast(scene.id, make_command(msg));
			}
		}
	}

	if check(*state.sync_count_key) {
		for * scene: state.scenes {
			for * scene.keys {
				msg: Command.Sync_Key;
				msg.key_id = it.id;
				msg.holder = it.holder;
				msg.position = it.server.position;
				scene_scoped_broadcast(scene.id, make_command(msg));
			}
		}
	}
}

process_response: Scene.Process_Response;
frame_result: Scene.Frame_Result;

quit_user :: (user: *User) {
	id := user.player_id;
	table_remove(*state.socket_to_token_id, user.websocket);
	for state.users {
		if it.websocket == user.websocket {
			remove it;
			break;
		}
	}


	for * scene: state.scenes {
		for * player, player_idx: scene.players {
			if player.id == id {
				scene.players[player_idx] = scene.players[scene.players.count - 1];
				scene.players.count -= 1;
				break player;
			}
		}
	}

	for state.server.websockets {
		if it != user.websocket {
			quit: Command.Quit;
			quit.player_id = id;
			append_queue(quit, it);
		}
	}
}

tick :: (state: *State) {
	reset_temporary_storage();

	Scene.clear(*process_response);

	// Early test
	if state.received.count > 0 {
		wait_for(*state.received_semaphore);
		defer {
			signal(*state.received_semaphore);
		}

		cursor := 0;
		while true {
			defer cursor += 1;
			if cursor >= state.received.count
				break;

			cmd := state.received.commands[cursor];
			socket := state.received.socket[cursor];

			if process(state, cmd, socket, *process_response)
				continue;
			for * scene: state.scenes {
				if Scene.process(scene, cmd, *process_response)
					break scene;
			}
		}

		state.received.count = 0; // Clear the queue after processing.
	}

	for process_response.entries {
		ntp: *Command.NTP = isa(it.command.payload, Command.NTP);
		if ntp {
			if ntp.player_id < 0 {
				broadcast(state.server, it.command);
			} else {
				user := find_user_by_player_id(ntp.player_id);
				if user {
					send(user.websocket, it.command);
				}
			}
		} else {
			scene_scoped_broadcast(it.scene_id, it.command);
		}
	}

	for * scene: state.scenes {
		Scene.clear(*frame_result);
		Scene.update(scene, state.tick_period.period, *frame_result);

		for frame_result.end_level {
			scene_scoped_broadcast(scene.id, make_command(it));
		}

		for frame_result.move_to_player_world {
			move_player_to_scene(it.player_id, state.playing_scene_id, it.model_id);
		}

		for frame_result.died {
			scene_scoped_broadcast(scene.id, make_command(it));
		}
		for frame_result.respawn {
			scene_scoped_broadcast(scene.id, make_command(it));
		}
		for frame_result.sync_gate {
			scene_scoped_broadcast(scene.id, make_command(it));
		}
		for frame_result.wipe_scene {
			scene_scoped_broadcast(scene.id, make_command(it));
		}

		if scene.end_scene_countdown_started {
			t := current_time_monotonic();
			dt := to_float64_seconds(t - scene.end_scene_countdown_time);
			if dt >= scene.end_scene_countdown {
				scene.end_scene_countdown_started = false;
				move_playing_scene(scene.next_id);
			}
		}
	}


	for * state.users {
		if to_float64_seconds(current_time_monotonic() - it.last_ping) > TIMEOUT_DURATION {
			quit_user(it);
		}
	}
}

process_complete_ntp :: (state: *State, ntp: Command.NTP) {
	t5 := to_float64_seconds(current_time_monotonic());
	result: State.NTP_Result;
	result.offset = (ntp.t3 + ntp.t4) / 2 - (ntp.t2 + t5) / 2;
	result.ping = (t5 - ntp.t2) - (ntp.t4 - ntp.t3);
	result.time = t5;
	state.ntp_history[state.ntp_history_cursor] = result;
	state.ntp_history_cursor += 1;
	state.ntp_history_cursor %= state.ntp_history.count;
}


process :: (
	state: *State, command: Command, socket: *Websocket, response: *Scene.Process_Response
) -> bool {
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
			is_over = false;
			send_back = true;
		} else {
			is_over = true;
			send_back = false;
		}

		if send_back && response
			Scene.add(response, -1, reply);

		if is_over
			process_complete_ntp(state, reply);

		return true;
	}

	connect: *Command.Connect = isa(command.payload, Command.Connect);
	if connect {
		state.user_generation += 1;

		if connect.token < 0 {
			// The client didn't provide a token, so we generate one for him.
			connect.token = state.user_generation;
		}

		// Let's check the token to see if the user has an history here.
		user: *User = null;
		for * u: state.users {
			if u.token == connect.token {
				// We are going to hijack this user to point to the new connection.
				u.websocket = socket;
				u.last_ping = current_time_monotonic();
				user = u;
				break;
			}
		}

		// If we didn't find a user with the same token, we need to create a new one.
		if !user {
			state.player_generation += 1;

			new_user: User;
			new_user.token = connect.token;
			new_user.player_id = state.player_generation;
			new_user.scene_id = state.pick_scene_id;
			new_user.last_ping = current_time_monotonic();
			new_user.websocket = socket;
			array_add(*state.users, new_user);
			user = *state.users[state.users.count - 1];

			for state.users {
				// Notify the existing player of a new player
				if it.scene_id != user.scene_id
					continue;
				// Don't notify the new player about themselves
				if it.player_id == user.player_id
					continue;

				spawn: Command.Spawn;
				spawn.player_id = user.player_id;
				spawn.its_you = false;
				spawn.scene_id = it.scene_id;
				append_queue(spawn, it.websocket);
			}

			// Also let's do a virtual message to tell the server a new guy just connected
			spawn: Command.Spawn;
			spawn.player_id = user.player_id;
			spawn.its_you = false;
			spawn.scene_id = user.scene_id;
			append_received_sync(make_command(spawn), null);
		}

		// Then we serve the state of the scene to the new player.
		scene := find_by_scene_id(user.scene_id);
		if scene
			append_queue(Scene.make_sync(scene), user.websocket);

		// We also need to tell the new player about their own spawn
		spawn: Command.Spawn;
		spawn.player_id = user.player_id;
		spawn.its_you = true;
		spawn.scene_id = user.scene_id;
		append_queue(spawn, user.websocket);

		// And finally we can respond to the user with the connection token
		connect_response: Command.Connect;
		connect_response.token = connect.token;
		append_queue(connect_response, user.websocket);

		// bookkeep the socket to token mapping
		table_set(*state.socket_to_token_id, socket, connect.token);
		return true;
	}

	return false;
}

add_scene :: (text: string) -> int {
	scene: Scene.Scene;
	scene.id = state.scenes.count + 1;
	scene.is_server = true;
	Terrain.parse_terrain(text, *scene);
	array_add(*state.scenes, scene);
	return scene.id;
}

set_scene :: (scene: *Scene.Scene, text: string) -> int {
	scene.is_server = true;
	Terrain.parse_terrain(text, scene);
	return scene.id;
}

move_playing_scene :: (scene_id: int) {
	old_scene := find_by_scene_id(state.playing_scene_id);

	scene := find_by_scene_id(scene_id);
	if !scene
		return;

	Scene.restart(scene);
	sync_scene := Scene.make_sync(scene);
	for state.users {
		if it.scene_id == state.playing_scene_id {
			send(it.websocket, make_command(sync_scene));
		}
	}
	state.playing_scene_id = scene_id;
	for old_scene.players {
		move_player_to_scene(it.id, scene_id, -1);
	}
}

move_player_to_scene :: (player_id: int, scene_id: int, model_id: int) {
	{
		player: *Scene.Player = null;
		old_scene: *Scene.Scene = null;
		for * scene: state.scenes {
			old_scene = scene;
			player = Scene.find_by_player_id(scene, player_id);
			if player
				break;
		}
		if !player
			return;

		for * old_scene.players {
			if it.id == player_id {
				remove it;
				break;
			}
		}
	}

	new_scene := find_by_scene_id(scene_id);
	if !new_scene
		return;

	spawn: Command.Spawn;
	spawn.player_id = player_id;
	spawn.scene_id = scene_id;
	spawn.model_id = model_id;
	Scene.process(new_scene, make_command(spawn), null);

	find_user_by_player_id(player_id).scene_id = scene_id;

	user := find_user_by_player_id(player_id);
	if user {
		scene := find_by_scene_id(state.first_world_id);
		if scene {
			player := Scene.find_by_player_id(scene, player_id);
			if player && model_id >= 0 {
				player.server.model_id = model_id;
			}

			sync_scene := Scene.make_sync(scene);

			send(user.websocket, make_command(sync_scene));
		}
	}

	// Signal to the rest of the users in the scene that a new player popped in.
	for state.users {
		if it.scene_id != scene_id
			continue;
		
		if it.player_id == player_id
			continue;

		spawn: Command.Spawn;
		spawn.player_id = player_id;
		spawn.scene_id = scene_id;
		spawn.model_id = model_id;
		send(it.websocket, make_command(spawn));
	}
}

watcher: File_Watcher(void);
frame_file_change: [1024] string;
frame_file_change_count := 0;

name_to_scene_id: Table(string, int);

#add_context _platform: Platform.Platform;
main :: () {

	init(*state.queue_semaphore, 1);
	init(*state.received_semaphore, 1);

	state.sync_period.last = current_time_monotonic();
	state.tick_period.last = current_time_monotonic();

	state.pick_scene_id = add_scene(Terrain.PICK_STRING);
	{
		plain_terrain_txt := sprint("%/../assets/terrain/here_and_there.terrain", #filepath);
		data, ok := read_entire_file(plain_terrain_txt);
		state.first_world_id = add_scene(data);

		table_add(*name_to_scene_id, "here_and_there.terrain", state.first_world_id);
	}
	state.second_world_id = add_scene(Terrain.ROUNDABOUT_STRING);

	for 0..state.scenes.count-2 {
		state.scenes[it].next_id = state.scenes[it+1].id;
	}

	state.playing_scene_id = state.first_world_id;

	http_listen(port=5623);

	server := websocket_listen("/ws");
	server.onopen = (ws: *Websocket) {
	};
	server.onmsg = (ws: *Websocket, msg: string) {
		ok, token := table_find_new(*state.socket_to_token_id, ws);
		if ok for * state.users {
			if it.token == token {
				it.last_ping = current_time_monotonic();
				break;
			}
		}

		data: [] u8;
		data.data = msg.data;
		data.count = msg.count;

		cmd, ok2 := parse_message(data);
		if ok2 {
			append_received(cmd, ws);
		}
	};
	server.onclose = (ws: *Websocket) {
		table_remove(*state.socket_to_token_id, ws);
	};

	state.server = server;

	init(*watcher, (watcher: *File_Watcher(void), change: *File_Change, user_data: *void) {
		frame_file_change_count %= frame_file_change.count;
		frame_file_change[frame_file_change_count] = alloc_string(change.full_path.count);
		memcpy(
			frame_file_change[frame_file_change_count].data,
			change.full_path.data,
			change.full_path.count
		);
		frame_file_change_count += 1;
	}, null);
	add_directories(*watcher, tprint("%/../assets/", #filepath));

	error := 0.0;
	while 1 {
		process_changes(*watcher);
		for 0..frame_file_change_count-1 {
			change := frame_file_change[it];

			for id, name: name_to_scene_id {
				if ends_with(change, name) {

					data, ok := read_entire_file(change);
					scene := find_by_scene_id(id);

					if scene && ok {
						for user: state.users {
							if user.scene_id == id {
								set_scene(scene, data);
								sync_scene := Scene.make_sync(scene);

								send(user.websocket, make_command(sync_scene));
							}
						}
					}

				}
			}
		}

		if check(*state.sync_period) {
			sync(state);
		}

		to_tick, dt := check(*state.tick_period);
		if to_tick {
			if dt + error > (2 * state.tick_period.period) {
				print(
					"Long tick detected: % seconds, doing % iterations\n",
					dt + error,
					cast(int) ((dt + error) / state.tick_period.period)
				);
			}

			while (dt + error) > state.tick_period.period {
				tick(*state);
				dt -= state.tick_period.period;
			}
			error += dt;
		}

		// Purge the command queue.
		{
			// Early test
			if state.queue.count > 0 {
				wait_for(*state.queue_semaphore);
				defer {
					signal(*state.queue_semaphore);
				}

				for 0..state.queue.count - 1 {
					cmd := state.queue.commands[it];
					if state.queue.socket[it]
						send(state.queue.socket[it], cmd);
					else
						broadcast(state.server, cmd);

				}

				state.queue.count = 0; // Clear the queue after processing.
			}
		}

		frame_file_change_count = 0;
	}
}

