#import "Basic";
#import "String";
#import "File";

kernel32 :: #library,system "kernel32";

HANDLE :: *void;
DWORD :: u32;
BOOL :: s32;
INVALID_HANDLE_VALUE :: cast(HANDLE) 0xFFFFFFFFFFFFFFFF;

PIPE_ACCESS_DUPLEX :: 0x00000003;
PIPE_TYPE_BYTE :: 0x00000000;
PIPE_READMODE_BYTE :: 0x00000000;
PIPE_NOWAIT :: 0x00000001;
PIPE_REJECT_REMOTE_CLIENTS :: 0x00000008;
ERROR_PIPE_CONNECTED :: 535;
ERROR_BROKEN_PIPE :: 109;
ERROR_NO_DATA :: 232;
ERROR_PIPE_LISTENING :: 536;

CreateNamedPipeA :: (
	name: *u8, open_mode: DWORD, pipe_mode: DWORD, max_instances: DWORD,
	out_buffer: DWORD, in_buffer: DWORD, timeout: DWORD, security: *void
) -> HANDLE #foreign kernel32;
ConnectNamedPipe :: (pipe: HANDLE, overlapped: *void) -> BOOL #foreign kernel32;
DisconnectNamedPipe :: (pipe: HANDLE) -> BOOL #foreign kernel32;
FlushFileBuffers :: (file: HANDLE) -> BOOL #foreign kernel32;
ReadFile :: (
	file: HANDLE, buffer: *void, to_read: DWORD, read: *DWORD, overlapped: *void
) -> BOOL #foreign kernel32;
WriteFile :: (
	file: HANDLE, buffer: *void, to_write: DWORD, written: *DWORD, overlapped: *void
) -> BOOL #foreign kernel32;
CloseHandle :: (object: HANDLE) -> BOOL #foreign kernel32;
GetLastError :: () -> DWORD #foreign kernel32;
CreateDirectoryA :: (path: *u8, security: *void) -> BOOL #foreign kernel32;

ARENA_CONTROL_PIPE_NAME :: "\\\\.\\pipe\\ArenaControl\0";

Win32_Control :: struct {
	pipe: HANDLE = INVALID_HANDLE_VALUE;
	connected := false;
	client_waiting := false;
	leftover: [..] u8;
	state: Control.State;
}

win32_control_open :: (control: *Win32_Control) -> bool {
	CreateDirectoryA("captures\0".data, null);
	control.pipe = CreateNamedPipeA(
		ARENA_CONTROL_PIPE_NAME.data,
		PIPE_ACCESS_DUPLEX,
		PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_NOWAIT | PIPE_REJECT_REMOTE_CLIENTS,
		1,
		65536,
		65536,
		0,
		null
	);
	control.leftover.allocator = context.allocator;
	control.state.commands.allocator = context.allocator;
	control.state.queue.allocator = context.allocator;
	control.state.response.allocator = context.allocator;
	return control.pipe != INVALID_HANDLE_VALUE;
}

win32_control_shutdown :: (control: *Win32_Control) {
	if control.connected {
		DisconnectNamedPipe(control.pipe);
		control.connected = false;
	}
	if control.pipe != INVALID_HANDLE_VALUE {
		CloseHandle(control.pipe);
		control.pipe = INVALID_HANDLE_VALUE;
	}
}

win32_control_try_accept :: (control: *Win32_Control) {
	if control.pipe == INVALID_HANDLE_VALUE return;
	if control.connected return;
	if ConnectNamedPipe(control.pipe, null) {
		control.connected = true;
		return;
	}
	error := GetLastError();
	if error == ERROR_PIPE_CONNECTED {
		control.connected = true;
	}
}

win32_control_reply_and_disconnect :: (control: *Win32_Control) {
	if !control.client_waiting return;
	text := control.state.response;
	if text.count == 0 {
		Control.append_response(*control.state, "ok\n");
		text = control.state.response;
	}
	written: DWORD;
	WriteFile(control.pipe, text.data, xx text.count, *written, null);
	FlushFileBuffers(control.pipe);
	DisconnectNamedPipe(control.pipe);
	control.connected = false;
	control.client_waiting = false;
	control.leftover.count = 0;
	Control.reset_batch(*control.state);
}

win32_control_poll :: (control: *Win32_Control) {
	win32_control_try_accept(control);
	if !control.connected return;
	if control.client_waiting {
		Control.process_ready_lines(*control.state);
		if Control.batch_finished(control.state) {
			win32_control_reply_and_disconnect(control);
		}
		return;
	}

	bytes: [65536] u8;
	read: DWORD;
	if !ReadFile(control.pipe, *bytes[0], bytes.count, *read, null) {
		error := GetLastError();
		if error == ERROR_BROKEN_PIPE {
			DisconnectNamedPipe(control.pipe);
			control.connected = false;
			control.leftover.count = 0;
		}
		return;
	}
	if read == 0 return;

	old := control.leftover.count;
	array_resize(*control.leftover, old + xx read);
	memcpy(control.leftover.data + old, *bytes[0], xx read);

	complete := false;
	for control.leftover {
		if it == #char "\n" {
			complete = true;
			break;
		}
	}
	if !complete return;

	text: string = .{ data = control.leftover.data, count = control.leftover.count };
	control.client_waiting = true;
	if !Control.enqueue_text(*control.state, text) {
		win32_control_reply_and_disconnect(control);
		return;
	}
	control.leftover.count = 0;
	Control.process_ready_lines(*control.state);
	if Control.batch_finished(control.state) {
		win32_control_reply_and_disconnect(control);
	}
}

win32_control_note_capture :: (control: *Win32_Control) -> bool {
	if !control.state.capture_requested && !control.state.pending_capture_reply {
		return false;
	}
	path := Control.capture_path(control.state.capture_serial);
	data, ok := read_entire_file(path,, temp);
	return ok && data.count > 8;
}
