#import "http";
#import "Basic";
#import "Communication";
#import "Scene";
#import "Thread";
#import "Hash_Table";

prepare_typed_message :: (payload: $T) -> [] u8 {
	message := NewArray(size_of(T) + 8, u8, false,, temp);
	(cast(*u64)message.data).* = xx size_of(T);
	memcpy(message.data + 8, xx *payload, size_of(T));
	return message;
}

prepare_message :: (payload: [] u8) -> [] u8 {
	message := NewArray(payload.count + 8, u8, false,, temp);
	(cast(*u64)message.data).* = xx payload.count;
	memcpy(message.data + 8, payload.data, payload.count);
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

	players: [..] Player;
	player_generation := 0;

	socket_to_player_id: Table(*Websocket, int);

	Queue :: struct {
		commands : [128] Command;
		socket   : [128] *Websocket; // null is for broadcast
		count    := 0;
	};

	queue: Queue;
	queue_semaphore: Semaphore;
}
state: State;

append_queue :: (cmd: $T, socket: *Websocket) {
	wait_for(*state.queue_semaphore);
	defer {
		signal(*state.queue_semaphore);
	}

	if state.queue.count >= state.queue.commands.count {
		print("Queue overflow!\n");
		return;
	}

	state.queue.socket[state.queue.count] = socket;
	state.queue.commands[state.queue.count] = make_command(cmd);
	state.queue.count += 1;
}


sync :: (state: State) {
	print("Sync\n");
	for * state.players {
		msg: Command.Sync_Player;
		msg.player_id = it.id;
		msg.direction = it.direction;
		msg.position = it.position;

		broadcast(state.server, msg);
	}
}

main :: () {
	init(*state.queue_semaphore, 1);

	http_listen(port=5623);

	server := websocket_listen("/ws");
	server.onopen = (ws: *Websocket) {
		print("Connect\n");
		state.player_generation += 1;

		for ws.server.websockets {
			if it == ws
				continue;

			spawn: Command.Spawn;
			spawn.player_id = state.player_generation;
			spawn.its_you = false;
			append_queue(spawn, it);
		}

		array_add(*state.players, .{ id = state.player_generation });
		table_add(*state.socket_to_player_id, ws, state.player_generation);

		for state.players {
			spawn: Command.Spawn;
			spawn.player_id = it.id;
			spawn.its_you = (it_index + 1) == state.players.count;
			append_queue(spawn, ws);
		}
	};
	server.onmsg = (ws: *Websocket, msg: string) {
		print("received\n");
		data: [] u8;
		data.data = msg.data;
		data.count = msg.count;
		broadcast_prepared(ws.server, data);
	};
	server.onclose = (ws: *Websocket) {
		print("Closed\n");

		found, id := table_find_new(*state.socket_to_player_id, ws);
		if found {
			table_remove(*state.socket_to_player_id, ws);

			for * state.players {
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

	while 1 {
		now := current_time_monotonic();
		{
			dt := to_float64_seconds(now - state.last_sync_sent_time);
			if dt > 0.1 {
				sync(state);
				state.last_sync_sent_time = current_time_monotonic();
			}
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

		sleep_milliseconds(1);
	}
}

