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

ARENA_CONTROL_PIPE_NAME :: GAME_CONTROL_PIPE_PATH;

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
	control.state.video_command = win32_control_video_command;
	return control.pipe != INVALID_HANDLE_VALUE;
}

win32_control_shutdown :: (control: *Win32_Control) {
	win32_video_shutdown();
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
	win32_video_poll();
	now := SDL_GetPerformanceCounter();
	if video_clock != 0 && win32_video_active() && !control.state.paused && !control.state.quit_requested {
		video_phase += (now - video_clock).(float64) / SDL_GetPerformanceFrequency();
	}
	video_clock = now;
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

// This flag comes from the exclusive PNG write in the game callback.
win32_control_note_capture :: (control: *Win32_Control) -> bool {
	return capture_write_ok;
}

capture_write_ok := false;
video_clock: u64;
video_fps := 30;
video_phase: float64;
video_repeat: int;
video_frame_requested := false;
video_frame_submitted := false;
video_skipped: u64;
video_readback_failures: u64;

win32_control_video_command :: (state: *Control.State, cmd: Control.Control_Command) {
	response: string;
	if cmd.kind == .Capture_Video_Start {
		path: string = .{ data = cmd.video_path.data, count = cmd.video_path_count };
		response = win32_video_start(path, cmd.video_fps, Control.CAPTURE_WIDTH, Control.CAPTURE_HEIGHT);
		if begins_with(response, "ok ") {
			video_fps = cmd.video_fps;
			video_phase = 0;
			video_skipped = 0;
			video_readback_failures = 0;
			video_clock = SDL_GetPerformanceCounter();
		}
	} else if cmd.kind == .Capture_Video_Stop {
		response = win32_video_stop();
	} else {
		response = tprint("% timing=% skipped=% readback_failures=%",
			trim_right(win32_video_status(), "\r\n"),
			ifx state.paused then "simulation" else "live",
			video_skipped, video_readback_failures);
	}
	Control.append_response(state, trim_right(response, "\r\n"));
	Control.append_response(state, "\n");
}

win32_control_begin_tick :: (control: *Win32_Control) {
	capture_write_ok = false;
	Control.begin_tick(*control.state);
	if control.state.capture_requested {
		// Serial numbers survive old runs by skipping every existing destination.
		while Win32.GetFileAttributesA(to_c_string(Control.capture_path(control.state.capture_serial),, temp)) != Win32.INVALID_FILE_ATTRIBUTES {
			control.state.capture_serial += 1;
		}
	}
	video_frame_requested = false;
	video_frame_submitted = false;
	video_repeat = 0;
	if !win32_video_active() || control.state.quit_requested return;
	if control.state.paused video_phase += Control.CONTROL_FIXED_DT;
	due := floor(video_phase * video_fps + 0.000001).(int);
	if due <= 0 || !win32_video_can_submit() return;
	// Cap catch-up after a long stall to keep worker work bounded as well as memory.
	video_repeat = min(due, 60);
	video_skipped += xx (due - video_repeat);
	video_phase -= due.(float64) / video_fps;
	video_frame_requested = true;
}

win32_control_end_video_tick :: () {
	if video_frame_requested && !video_frame_submitted {
		video_readback_failures += 1;
		video_phase += video_repeat.(float64) / video_fps;
	}
}

win32_control_video_frame :: (rgb: [] u8, width: int, height: int) {
	video_frame_submitted = win32_video_submit(rgb, width, height, video_repeat);
}

win32_write_capture_file :: (path: string, data: [] u8) -> bool {
	file := Win32.CreateFileA(to_c_string(path,, temp), Win32.GENERIC_WRITE,
		Win32.FILE_SHARE_READ, null, Win32.CREATE_NEW, Win32.FILE_ATTRIBUTE_NORMAL);
	if file == Win32.INVALID_HANDLE_VALUE return false;
	written: Win32.DWORD;
	ok := Win32.WriteFile(file, data.data, xx data.count, *written, null);
	Win32.CloseHandle(file);
	capture_write_ok = ok != 0 && written == data.count;
	if !capture_write_ok Win32.DeleteFileA(to_c_string(path,, temp));
	return capture_write_ok;
}
