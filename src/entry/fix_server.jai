#import "Basic";
#import "Platform";
#import "File_Watcher";
#import "File";
#import "Hash_Table";

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
	received := receive_buffer.data.(*u64)[0];
	dropped  := receive_buffer.data.(*u64)[1];

	cursor   := 16;

	msgs := NewArray(xx received, Web_Message, false,, temp);
	for * msgs {
		it.sender = xx (*receive_buffer[cursor]).(*u64).*;
		it.data.count = xx (*receive_buffer[cursor + 8]).(*u64).*;
		it.data.data  = receive_buffer.data + cursor + 16;
	}

	return msgs;
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
		ws_poll :: () #foreign;
		ws_poll();
	}

	app_quit(*app);
}
