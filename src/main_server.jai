Terrain :: #import "Terrain";
#import "http";
#import "Basic";
#import "Communication";
Scene :: #import "Scene";
#import "Thread";
#import "Hash_Table";
#import "Utils";

STARTER_TERRAIN_ASCII :: #string TERRAIN
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGSGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
TERRAIN

prepare_typed_message :: (_payload: $T) -> [] u8 {
	payload := _payload;
	#if T == Command {
		payload.sent_timestamp = to_float64_seconds(current_time_monotonic());
	}

	message := NewArray(size_of(T) + 8, u8, false,, temp);
	(cast(*u64)message.data).* = xx size_of(T);
	memcpy(message.data + 8, xx *payload, size_of(T));
	return message;
}

broadcast :: (server: Websocket_Server, data: $T) {
	message := prepare_typed_message(data);
	broadcast_prepared(server, message);
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

State :: struct {
	server: *Websocket_Server = null;
	last_sync_sent_time: Apollo_Time;

	sync_count_player: Counter(1);
	sync_count_skull: Counter(20);
	sync_moving_frame: Counter(10);
	sync_count_key: Counter(50);

	player_generation := 0;

	socket_to_player_id: Table(*Websocket, int);

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

	scene: Scene.Scene;
}
state: State;

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

parse_message :: (data: [] u8) -> Command, bool {
	if data.count < 8 {
		print("Message too short: %\n", data);
		return .{}, false;
	}

	size := (cast(*u64)data.data).*;
	if size > xx (data.count - 8) {
		print("Message size mismatch: expected % but got %\n", size, data.count - 8);
		return .{}, false;
	}

	command: Command;
	memcpy(cast(*void)*command, data.data + 8, size_of(Command));
	return command, true;

}

sync :: (state: State) {
	reset_temporary_storage();
	if check(*state.sync_count_player) {
		for * state.scene.players {
			msg: Command.Sync_Player;
			msg.player_id = it.id;
			msg.direction = it.server.direction;
			msg.position = it.server.position;
			msg.dead = it.server.dead;

			broadcast(state.server, make_command(msg));
		}
	}

	if check(*state.sync_moving_frame) {
		for * state.scene.moving_frames {
			msg: Command.Sync_Moving_Frame;
			msg.frame_id = it.id;
			msg.t = it.server.t;

			broadcast(state.server, make_command(msg));
		}
	}

	if check(*state.sync_count_skull) {
		for * state.scene.skulls {
			msg: Command.Sync_Skull;
			msg.skull_id = it.id;
			msg.t = it.server.t;

			broadcast(state.server, make_command(msg));
		}
	}

	if check(*state.sync_count_key) {
		for * state.scene.keys {
			msg: Command.Sync_Key;
			msg.key_id = it.id;
			msg.holder = it.holder;
			msg.position = it.server.position;

			broadcast(state.server, make_command(msg));
		}
	}
}

process_response: Scene.Process_Response;
frame_result: Scene.Frame_Result;

tick :: (state: *State) {
	reset_temporary_storage();
	Scene.clear(*process_response);
	Scene.clear(*frame_result);

	// Early test
	if state.received.count > 0 {
		wait_for(*state.received_semaphore);
		defer {
			signal(*state.received_semaphore);
		}

		for 0..state.received.count - 1 {
			cmd := state.received.commands[it];

			Scene.process(*state.scene, cmd, *process_response);
		}

		state.received.count = 0; // Clear the queue after processing.
	}

	for process_response.move {
		broadcast(state.server, make_command(it));
	}
	for process_response.coin_spawn {
		broadcast(state.server, make_command(it));
	}

	Scene.update(*state.scene, state.tick_period.period, *frame_result);

	for frame_result.died {
		broadcast(state.server, make_command(it));
	}
	for frame_result.respawn {
		broadcast(state.server, make_command(it));
	}
	for frame_result.sync_gate {
		broadcast(state.server, make_command(it));
	}
}

main :: () {

	init(*state.queue_semaphore, 1);
	init(*state.received_semaphore, 1);

	state.sync_period.last = current_time_monotonic();
	state.tick_period.last = current_time_monotonic();
	state.scene.is_server = true;
	Terrain.init_roundabout(*state.scene);

	http_listen(port=5623);

	server := websocket_listen("/ws");
	server.onopen = (ws: *Websocket) {
		state.player_generation += 1;

		// Notify the existing player of a new player
		for ws.server.websockets {
			if it == ws
				continue;

			spawn: Command.Spawn;
			spawn.player_id = state.player_generation;
			spawn.its_you = false;
			append_queue(spawn, it);
		}

		{
			// tell the serve a new guy just connected
			spawn: Command.Spawn;
			spawn.player_id = state.player_generation;
			spawn.its_you = false;
			append_received(make_command(spawn), null);

			// Tell the new player about everyone else
			for * state.scene.players {
				spawn: Command.Spawn;
				spawn.player_id = it.id;
				spawn.its_you = false;
				append_queue(spawn, ws);
			}
			spawn.its_you = true;
			append_queue(spawn, ws);
		}
		table_add(*state.socket_to_player_id, ws, state.player_generation);
	};
	server.onmsg = (ws: *Websocket, msg: string) {
		data: [] u8;
		data.data = msg.data;
		data.count = msg.count;

		cmd, ok := parse_message(data);
		if ok {
			append_received(cmd, ws);
		}
	};
	server.onclose = (ws: *Websocket) {
		found, id := table_find_new(*state.socket_to_player_id, ws);
		if found {
			table_remove(*state.socket_to_player_id, ws);

			for * state.scene.players {
				if it.id == id {
					remove it;
					break;
				}
			}

			for ws.server.websockets {
				if it != ws {
					quit: Command.Quit;
					quit.player_id = id;
					append_queue(quit, it);
				}
			}
		}
	};

	state.server = server;

	error := 0.0;
	while 1 {
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
	}
}

