#import "websocket";
#import "Basic";
#import "Communication";

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

broadcast :: (server: Websocket_Server, payload: [] u8) {
	message := prepare_message(payload);
	str: string;
	str.data = message.data;
	str.count = message.count;

	for server.websockets {
		websocket_send(it, str, .TEXT);
	}
}

send :: (ws: *Websocket, prepared_payload: [] u8) {
	str: string;
	str.data = prepared_payload.data;
	str.count = prepared_payload.count;

	websocket_send(ws, str, .TEXT);
}


State :: struct {
	player_count := 0;
}

state: State;

main :: () {
	http_listen(port=2356);

	server := websocket_listen("/ws");
	server.onopen = (ws: *Websocket) {
		print("Opened\n");

		spawn: Command.Spawn;
		spawn.player_id = state.player_count;
		state.player_count += 1;

		for ws.server.websockets {
			if it != ws {
				send(it, prepare_typed_message(spawn));
			}
		}
		spawn.its_you = true;
		send(ws, prepare_typed_message(spawn));

	};
	server.onmsg = (ws: *Websocket, msg: string) {
		print("Received\n");
		data: [] u8;
		data.data = msg.data;
		data.count = msg.count;
		broadcast(ws.server, data);
	};
	server.onclose = (ws: *Websocket) {
		print("Closed\n");
	};

	while 1 {
		sleep_milliseconds(10_000); // uhh, the program just exits instantly without this xxx
		broadcast(server, .[ 1, 2, 3, 4, 5, 6 ]);
	}
}

