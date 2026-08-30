#import "Basic";
#import "Platform";
#import "File_Watcher";
#import "File";
#import "http";
#import "Hash_Table";
Win32 :: #import "Windows";

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
	found, ws := table_find(*connection_to_websocket, target);
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
		found, connection := table_find(*websocket_to_connection, ws);
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
	print("WebSocket closed\n");
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


dll: Win32.HMODULE;
dll_last_write: u64 = 0;
app: App;

load_dll :: () {
	Win32.FreeLibrary(dll);

	Win32.DeleteFileA(identity_cstr(GAME_SERVER_TEMP_DLL));
	Win32.CopyFileA(identity_cstr(GAME_SERVER_DLL), identity_cstr(GAME_SERVER_TEMP_DLL), 0);

	dll = Win32.LoadLibraryA(identity_cstr(GAME_SERVER_TEMP_DLL));
	if dll == null {
		print("Failed to load %\n", GAME_SERVER_DLL);
		return;
	}

	// Get the function pointer of app_init
	app_init := Win32.GetProcAddress(dll, "app_init").(#type (app: *App) -> ());
	if app_init {
		app_init(*app);
	}
}

reload_dll :: () {
	Win32.FreeLibrary(dll);

	Win32.DeleteFileA(identity_cstr(GAME_SERVER_TEMP_DLL));
	Win32.CopyFileA(identity_cstr(GAME_SERVER_DLL), identity_cstr(GAME_SERVER_TEMP_DLL), 0);

	dll_reloaded := Win32.LoadLibraryA(identity_cstr(GAME_SERVER_TEMP_DLL));
	if dll_reloaded == null {
		print("Failed to reload %\n", GAME_SERVER_DLL);
		return;
	}
	dll = dll_reloaded;

	// Get the function pointer of app_init
	app_reload := Win32.GetProcAddress(dll, "app_reload").(#type (app: *App) -> ());
	if app_reload {
		app_reload(*app);
	}
}

main :: () {
	print("Context size in client is % bytes\n", size_of(#Context));

	args := get_command_line_arguments();
	defer array_free(args);

	platform := init_platform();
	app.platform = *platform;
	app.allocator = context.allocator;
	app.user_data = null;

	load_dll();

	loop := true;
	while (loop) {
		if dll {
			file := Win32.CreateFileA(identity_cstr(GAME_SERVER_DLL), Win32.FILE_GENERIC_READ);
			defer Win32.CloseHandle(file);

			time_struct: Win32.FILETIME;
			Win32.GetFileTime(file, null, null, *time_struct);

			if time_struct.QuadPart != dll_last_write {
				print("Reloading DLL...\n");
				reload_dll();
				dll_last_write = time_struct.QuadPart;
			}
		}

		if dll {
			// Get the function pointer of app_loop
			app_loop := Win32.GetProcAddress(dll, "app_loop").(#type (app: *App) -> bool);
			if app_loop {
				loop = app_loop(*app);
			}
		}
	}

	app_quit := Win32.GetProcAddress(dll, "app_quit").(#type (app: *App) -> ());
	if app_quit {
		app_quit(*app);
	}
}
