#import "Basic";
#import "Platform";
#import "File_Watcher";
#import "File";
#import "Hash_Table";
#if OS == .WINDOWS
	Win32 :: #import "Windows";

receive_buffer: [] u8;

init_platform :: () -> Platform {
	platform: Platform;

	platform.open_server = win32_open_server;
	platform.send_web_message = win32_send_web_message;
	platform.gather_web_messages = win32_gather_web_messages;

	return platform;
}

win32_open_server :: (port: int) -> bool {
	ws_listen :: (url: *u8, buffer: *void, buffer_capacity: u64) #foreign;

	receive_buffer = NewArray(1024 * 1024 * 64, u8, false);

	url := tprint("ws://localhost:%\0", port);
	ws_listen(url.data, receive_buffer.data, xx receive_buffer.count);
	return true;
}

win32_send_web_message :: (msg: [] u8, target: Connection) {
	ws_send :: (uid: u64, data: *u8, count: u64) #foreign;

	if target >= 0
		ws_send(target.(u64), msg.data, xx msg.count);
}

win32_gather_web_messages :: () -> [] Web_Message {
	ws_poll :: () #foreign;
	ws_poll();

	received := receive_buffer.data.(*u64)[0];
	dropped  := receive_buffer.data.(*u64)[1];

	if dropped > 0 {
		print("[WARNING] The server dropped % messages\n", dropped);
	}

	cursor   := 16;

	msgs := NewArray(xx received, Web_Message, false,, temp);
	for * msgs {
		it.sender = xx (*receive_buffer[cursor]).(*u64).*;
		it.data.count = xx (*receive_buffer[cursor + 8]).(*u64).*;
		it.data.data  = receive_buffer.data + cursor + 16;
		cursor = (it.data.count.(u64) + (it.data.data.(u64) - receive_buffer.data.(u64))).(s64);
	}
	
	return msgs;
}

app: App;

#if OS == .WINDOWS {
	dll: Win32.HMODULE;
	dll_last_write: u64 = 0;

	load_dll :: () {
		Win32.FreeLibrary(dll);

		Win32.DeleteFileA("IceEscapeServer_temp.dll");
		Win32.CopyFileA("IceEscapeServer.dll", "IceEscapeServer_temp.dll", 0);

		dll = Win32.LoadLibraryA("IceEscapeServer_temp.dll");
		if dll == null {
			print("Failed to load IceEscape.dll\n");
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

		Win32.DeleteFileA("IceEscapeServer_temp.dll");
		Win32.CopyFileA("IceEscapeServer.dll", "IceEscapeServer_temp.dll", 0);

		dll_reloaded := Win32.LoadLibraryA("IceEscapeServer_temp.dll");
		if dll_reloaded == null {
			print("Failed to reload IceEscapeServer.dll\n");
			return;
		}
		dll = dll_reloaded;

		// Get the function pointer of app_init
		app_reload := Win32.GetProcAddress(dll, "app_reload").(#type (app: *App) -> ());
		if app_reload {
			app_reload(*app);
		}
	}
} else {
	#import "main_server";
}

main :: () {
	print("Context size in client is % bytes\n", size_of(#Context));

	args := get_command_line_arguments();
	defer array_free(args);

	platform := init_platform();
	app.platform = *platform;
	app.allocator = context.allocator;
	app.user_data = null;

	#if OS == .WINDOWS
		load_dll();
	else
		app_init(*app);

	loop := true;
	while (loop) {
		#if OS == .WINDOWS {
			if dll {
				file := Win32.CreateFileA("IceEscapeServer.dll", Win32.FILE_GENERIC_READ);
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
		} else {
			loop := app_loop(*app);
		}
	}

	#if OS == .WINDOWS {
		app_quit := Win32.GetProcAddress(dll, "app_quit").(#type (app: *App) -> ());
		if app_quit {
			app_quit(*app);
		}
	} else {
		app_quit(*app);
	}
}
