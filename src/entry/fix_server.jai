#import "Basic";
#import "Platform";
#import "File_Watcher";
#import "File";
#import "http";
#import "Hash_Table";

server: *Websocket_Server;
websocket_to_connection: Table(*Websocket, Connection);
connection_to_websocket: Table(Connection, *Websocket);
connection_generation := 0;

message_received: [1024] Web_Message;
message_received_count := 0;

connection_change: [1024] Connection_Change;
connection_change_count := 0;

init_platform :: () -> Platform {
	platform: Platform;

	platform.open_server = win32_open_server;
	platform.send_web_message = win32_send_web_message;
	platform.gather_web_messages = win32_gather_web_messages;
	platform.gather_connection_changes = win32_gather_connection_changes;

	return platform;
}

win32_open_server :: (port: int) -> bool {
	http_listen(port=xx port);

	server = websocket_listen("/ws");
	server.onopen = ws_onopen;
	server.onmsg = ws_onmsg;
	server.onclose = ws_onclose;

	return true;
}

win32_send_web_message :: (msg: [] u8, target: Connection) {
	found, ws := table_find_new(*connection_to_websocket, target);
	if found {
		websocket_send(ws, xx msg, .BINARY);
	}
}

win32_gather_web_messages :: () -> [] Web_Message {
	msgs := NewArray(message_received_count, Web_Message,, temp);

	for 0..message_received_count - 1 {
		msgs[it].data = NewArray(message_received[it].data.count, u8,, temp);
		memcpy(msgs[it].data.data, message_received[it].data.data, message_received[it].data.count);
		msgs[it].sender = message_received[it].sender;
		free(message_received[it].data.data);
	}

	message_received_count = 0;
	return msgs;
}

win32_gather_connection_changes :: () -> [] Connection_Change {
	changes := NewArray(connection_change_count, Connection_Change,, temp);

	for 0..connection_change_count - 1 {
		changes[it] = connection_change[it];
	}

	return changes;
}

ws_onopen :: (ws: *Websocket) {
	connection := connection_generation;
	connection_generation += 1;

	table_set(*websocket_to_connection, ws, connection);
	table_set(*connection_to_websocket, connection, ws);

	if connection_change_count < connection_change.count {
		connection_change[connection_change_count].connection = connection;
		connection_change[connection_change_count].entered = true;
		connection_change_count += 1;
	} else {
		print("Connection change buffer full!\n");
	}
}

ws_onmsg :: (ws: *Websocket, msg: string) {
	data := NewArray(msg.count, u8);
	memcpy(data.data, msg.data, msg.count);

	if message_received_count < message_received.count {
		found, connection := table_find_new(*websocket_to_connection, ws);
		if !found {
			connection = -1;
		}

		message_received[message_received_count].data = data;
		message_received[message_received_count].sender = connection;
		message_received_count += 1;
	} else {
		print("Message received but buffer full!\n");
	}
}

ws_onclose :: (ws: *Websocket) {
	found, connection := table_find_new(*websocket_to_connection, ws);
	if !found
		return;

	table_remove(*websocket_to_connection, ws);
	table_remove(*connection_to_websocket, connection);

	if connection_change_count < connection_change.count {
		connection_change[connection_change_count].connection = connection;
		connection_change[connection_change_count].entered = false;
		connection_change_count += 1;
	} else {
		print("Connection change buffer full!\n");
	}
}


app: App;
#import "main_server";

main :: () {
	platform := init_platform();
	app.platform = *platform;
	app.allocator = context.allocator;
	app.user_data = null;

	app_init(*app);
	while (app_loop(*app)) {
	}

	app_quit(*app);
}
