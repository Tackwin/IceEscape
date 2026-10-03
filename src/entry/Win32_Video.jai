#import "Basic";
#import "String";
#import "Thread";

// RGB24 is copied into a fixed FIFO. Only the worker writes FFmpeg's stdin;
// neither a slow encoder nor MP4 finalization waits in the render/control loop.
// FFmpeg's stdout is a CREATE_NEW file, so filenames never enter its command
// line and an existing recording cannot be overwritten, even in a race.
video_GetTickCount64 :: () -> u64 #foreign kernel32 "GetTickCount64";
video_CancelSynchronousIo :: (thread: HANDLE) -> BOOL #foreign kernel32 "CancelSynchronousIo";
video_GetFileType :: (file: HANDLE) -> DWORD #foreign kernel32 "GetFileType";

VIDEO_QUEUE_CAPACITY :: 4;
VIDEO_WRITE_TIMEOUT_MS :: 10000;
VIDEO_STOP_TIMEOUT_MS :: 15000;

Video_State :: enum {
	Idle;
	Recording;
	Stopping;
	Complete;
	Failed;
}

Video_Frame :: struct {
	rgb: [] u8;
	repeat: int;
}

Win32_Video :: struct {
	initialized := false;
	mutex: Mutex;
	work: Semaphore;
	worker: Thread;
	worker_started := false;
	state: Video_State;
	process: HANDLE;
	process_id: u32;
	input: HANDLE;
	path: string;
	log_path: string;
	frames: [VIDEO_QUEUE_CAPACITY] Video_Frame;
	head: int;
	count: int;
	fps: int;
	width: int;
	height: int;
	submitted: u64;
	written: u64;
	io_started: u64;
	stop_started: u64;
	exit_code: u32;
	error_code: u32;
	reason: string;
}

win32_video: Win32_Video;
win32_video_serial: u64;

win32_video_init :: () {
	if win32_video.initialized return;
	init(*win32_video.mutex);
	init(*win32_video.work);
	win32_video.initialized = true;
}

video_ascii_lower :: (c: u8) -> u8 {
	if c >= #char "A" && c <= #char "Z" return c + 32;
	return c;
}

video_equal_fold :: (a: string, b: string) -> bool {
	if a.count != b.count return false;
	for 0..a.count-1 {
		if video_ascii_lower(a[it]) != video_ascii_lower(b[it]) return false;
	}
	return true;
}

video_reserved_component :: (part: string) -> bool {
	base := part;
	for part {
		if it == #char "." {
			base.count = it_index;
			break;
		}
	}
	while base.count > 0 && base[base.count - 1] == #char " " base.count -= 1;
	if video_equal_fold(base, "con") || video_equal_fold(base, "prn") ||
		video_equal_fold(base, "aux") || video_equal_fold(base, "nul") ||
		video_equal_fold(base, "conin$") || video_equal_fold(base, "conout$") ||
		video_equal_fold(base, "clock$") return true;
	if base.count == 4 && base[3] >= #char "1" && base[3] <= #char "9" {
		base.count = 3;
		if video_equal_fold(base, "com") || video_equal_fold(base, "lpt") return true;
	}
	return false;
}

// Returned strings live in temporary storage; start copies the successful path.
video_output_path :: (requested: string) -> string, string {
	path := requested;
	if path.count == 0 {
		CreateDirectoryA("captures\0".data, null);
		win32_video_serial += 1;
		path = tprint("captures/video_%_%_%.mp4", video_GetTickCount64(), Win32.GetCurrentProcessId(), win32_video_serial);
	}
	for path {
		if it < 32 || it > 126 return "", "path must use printable ASCII characters";
		if it == #char "\"" || it == #char "<" || it == #char ">" ||
			it == #char "|" || it == #char "?" || it == #char "*" return "", "invalid path character";
		if it == #char ":" && it_index != 1 return "", "alternate data streams are unsupported";
	}
	if path.count >= 2 && (path[0] == #char "\\" || path[0] == #char "/") &&
		(path[1] == #char "\\" || path[1] == #char "/") return "", "UNC and device paths are unsupported";
	if path.count < 4 return "", "output path must end in .mp4";
	ext := path;
	ext.data += ext.count - 4;
	ext.count = 4;
	if !video_equal_fold(ext, ".mp4") return "", "output path must end in .mp4";
	buffer: [4096] u8;
	count := Win32.GetFullPathNameA(to_c_string(path,, temp), buffer.count, buffer.data, null);
	if count == 0 || count >= 230 return "", "output path is invalid or too long (maximum 229 bytes)";
	full := copy_string(.{data = buffer.data, count = xx count},, temp);
	// Validate canonical components, including Win32 aliases with trailing dots
	// or spaces. This also prevents an innocuous .mp4 suffix naming a device.
	start := 3;
	for 3..full.count {
		if it != full.count && full[it] != #char "\\" && full[it] != #char "/" continue;
		part: string = .{data = full.data + start, count = it - start};
		if part.count == 0 return "", "empty path component";
		last := part[part.count - 1];
		if last == #char "." || last == #char " " || video_reserved_component(part) return "", "reserved Windows path component";
		start = it + 1;
	}
	attributes := Win32.GetFileAttributesA(to_c_string(full,, temp));
	if attributes != Win32.INVALID_FILE_ATTRIBUTES return "", "output already exists";
	return full, "";
}

video_fail_locked :: (reason: string, code: u32 = 0) {
	if win32_video.state == .Failed return;
	win32_video.state = .Failed;
	win32_video.reason = reason;
	win32_video.error_code = code;
	win32_video.stop_started = video_GetTickCount64();
}

win32_video_status :: () -> string {
	win32_video_init();
	lock(*win32_video.mutex);
	defer unlock(*win32_video.mutex);
	state := "idle";
	if win32_video.state == {
		case .Recording; state = "recording";
		case .Stopping; state = "stopping";
		case .Complete; state = "complete";
		case .Failed; state = "failed";
	}
	prefix := "ok";
	if win32_video.state == .Failed prefix = "error";
	return tprint("% capture_video state=% path=\"%\" log=\"%\" fps=% width=% height=% frames=% submitted=% queued=% pid=% exit=% win32_error=% reason=\"%\"\n",
		prefix, state, win32_video.path, win32_video.log_path, win32_video.fps,
		win32_video.width, win32_video.height, win32_video.written, win32_video.submitted,
		win32_video.count, win32_video.process_id, win32_video.exit_code, win32_video.error_code, win32_video.reason);
}

win32_video_poll :: () {
	if !win32_video.initialized return;
	lock(*win32_video.mutex);
	if !win32_video.worker_started {
		unlock(*win32_video.mutex);
		return;
	}
	now := video_GetTickCount64();
	terminate := false;
	if win32_video.io_started != 0 && now - win32_video.io_started > VIDEO_WRITE_TIMEOUT_MS {
		video_fail_locked("FFmpeg stdin stalled", 1460);
		terminate = true;
	}
	if win32_video.stop_started != 0 && now - win32_video.stop_started > VIDEO_STOP_TIMEOUT_MS {
		video_fail_locked("FFmpeg finalization timed out", 1460);
		terminate = true;
	}
	process := win32_video.process;
	if process && win32_video.state == .Recording {
		code: u32;
		if Win32.GetExitCodeProcess(process, *code) && code != STILL_ACTIVE {
			win32_video.exit_code = code;
			video_fail_locked("FFmpeg exited during recording; inspect log", code);
			signal(*win32_video.work);
		}
	}
	unlock(*win32_video.mutex);
	if terminate {
		if process Win32.TerminateProcess(process, 1460);
		video_CancelSynchronousIo(win32_video.worker.windows_thread);
		signal(*win32_video.work);
	}
	if thread_is_done(*win32_video.worker) {
		thread_deinit(*win32_video.worker);
		lock(*win32_video.mutex);
		win32_video.worker_started = false;
		if win32_video.process CloseHandle(win32_video.process);
		win32_video.process = null;
		win32_video.io_started = 0;
		win32_video.stop_started = 0;
		win32_video.count = 0;
		unlock(*win32_video.mutex);
	}
}

win32_video_active :: () -> bool {
	if !win32_video.initialized return false;
	lock(*win32_video.mutex);
	defer unlock(*win32_video.mutex);
	return win32_video.state == .Recording;
}

win32_video_can_submit :: () -> bool {
	if !win32_video.initialized return false;
	lock(*win32_video.mutex);
	defer unlock(*win32_video.mutex);
	return win32_video.state == .Recording && win32_video.count < VIDEO_QUEUE_CAPACITY;
}

win32_video_submit :: (rgb: [] u8, width: int, height: int, repeat: int = 1) -> bool {
	if !win32_video.initialized return false;
	lock(*win32_video.mutex);
	defer unlock(*win32_video.mutex);
	if win32_video.state != .Recording return false;
	if width != win32_video.width || height != win32_video.height || rgb.count != width * height * 3 || repeat < 1 || repeat > 600 {
		video_fail_locked("invalid RGB24 frame or repeat count");
		signal(*win32_video.work);
		return false;
	}
	if win32_video.count == VIDEO_QUEUE_CAPACITY return false;
	slot := *win32_video.frames[(win32_video.head + win32_video.count) % VIDEO_QUEUE_CAPACITY];
	memcpy(slot.rgb.data, rgb.data, rgb.count);
	slot.repeat = repeat;
	win32_video.count += 1;
	win32_video.submitted += xx repeat;
	signal(*win32_video.work);
	return true;
}

win32_video_stop :: () -> string {
	win32_video_init();
	lock(*win32_video.mutex);
	if win32_video.state == .Recording {
		win32_video.state = .Stopping;
		win32_video.stop_started = video_GetTickCount64();
		signal(*win32_video.work);
	}
	unlock(*win32_video.mutex);
	return win32_video_status();
}

video_worker_proc :: (thread: *Thread) -> s64 {
	while true {
		lock(*win32_video.mutex);
		failed := win32_video.state == .Failed;
		stopping := win32_video.state != .Recording;
		count := win32_video.count;
		frame := win32_video.frames[win32_video.head];
		unlock(*win32_video.mutex);
		if failed || (stopping && count == 0) break;
		if count == 0 {
			wait_for(*win32_video.work, 100);
			continue;
		}
		for 1..frame.repeat {
			remaining := frame.rgb;
			while remaining.count > 0 {
				lock(*win32_video.mutex);
				if win32_video.state == .Failed {
					unlock(*win32_video.mutex);
					break;
				}
				win32_video.io_started = video_GetTickCount64();
				unlock(*win32_video.mutex);
				written: DWORD;
				ok := WriteFile(win32_video.input, remaining.data, xx remaining.count, *written, null);
				error := GetLastError();
				lock(*win32_video.mutex);
				win32_video.io_started = 0;
				if !ok || written == 0 {
					video_fail_locked("FFmpeg stdin write failed; inspect log", error);
				}
				failed = win32_video.state == .Failed;
				unlock(*win32_video.mutex);
				if failed break;
				remaining.data += written;
				remaining.count -= xx written;
			}
			lock(*win32_video.mutex);
			failed = win32_video.state == .Failed;
			if !failed win32_video.written += 1;
			unlock(*win32_video.mutex);
			if failed break;
		}
		lock(*win32_video.mutex);
		win32_video.head = (win32_video.head + 1) % VIDEO_QUEUE_CAPACITY;
		win32_video.count -= 1;
		unlock(*win32_video.mutex);
	}
	CloseHandle(win32_video.input);
	win32_video.input = null;
	// Waiting here keeps the app responsive while FFmpeg writes the trailer.
	result := Win32.WaitForSingleObject(win32_video.process, VIDEO_STOP_TIMEOUT_MS);
	if result == Win32.WAIT_TIMEOUT {
		Win32.TerminateProcess(win32_video.process, 1460);
		Win32.WaitForSingleObject(win32_video.process, 2000);
		lock(*win32_video.mutex);
		video_fail_locked("FFmpeg finalization timed out", 1460);
		unlock(*win32_video.mutex);
	}
	code: u32;
	Win32.GetExitCodeProcess(win32_video.process, *code);
	lock(*win32_video.mutex);
	win32_video.exit_code = code;
	if win32_video.state != .Failed {
		if code != 0 {
			video_fail_locked("FFmpeg encoding failed; inspect log", code);
		} else if win32_video.written == 0 {
			video_fail_locked("recording stopped without any frames");
		} else {
			win32_video.state = .Complete;
		}
	}
	unlock(*win32_video.mutex);
	return 0;
}

win32_video_start :: (path: string, fps: int, width: int, height: int) -> string {
	win32_video_init();
	win32_video_poll();
	if win32_video.worker_started return "error capture_video recording or finalization already active\n";
	if fps < 1 || fps > 60 return "error capture_video fps must be 1..60\n";
	if width < 1 || height < 1 || width > 8192 || height > 8192 return "error capture_video invalid dimensions\n";
	output, reason := video_output_path(path);
	if reason.count return tprint("error capture_video %\n", reason);
	// Release only our previous recording's memory, never its files.
	free(win32_video.path);
	free(win32_video.log_path);
	win32_video.path = copy_string(output);
	win32_video.log_path = "";
	win32_video.state = .Idle;
	win32_video.reason = "";
	win32_video.error_code = 0;
	win32_video.exit_code = 0;
	win32_video.process_id = 0;
	win32_video.fps = fps;
	win32_video.width = width;
	win32_video.height = height;
	win32_video.head = 0;
	win32_video.count = 0;
	win32_video.submitted = 0;
	win32_video.written = 0;
	win32_video.io_started = 0;
	win32_video.stop_started = 0;
	security: Win32.SECURITY_ATTRIBUTES;
	security.nLength = size_of(Win32.SECURITY_ATTRIBUTES);
	security.bInheritHandle = 1;
	output_handle := Win32.CreateFileA(to_c_string(output,, temp), Win32.GENERIC_WRITE, Win32.FILE_SHARE_READ, *security, Win32.CREATE_NEW);
	if output_handle == INVALID_HANDLE_VALUE {
		video_fail_locked("cannot create output (existing file or invalid directory/access)", GetLastError());
		return win32_video_status();
	}
	defer CloseHandle(output_handle);
	if video_GetFileType(output_handle) != 1 {
		video_fail_locked("output must be a regular disk file");
		return win32_video_status();
	}
	log_handle: HANDLE = INVALID_HANDLE_VALUE;
	for 1..32 {
		win32_video_serial += 1;
		log_path := tprint("%.ffmpeg_%.log", output, win32_video_serial);
		log_handle = Win32.CreateFileA(to_c_string(log_path,, temp), Win32.GENERIC_WRITE, Win32.FILE_SHARE_READ, *security, Win32.CREATE_NEW);
		if log_handle != INVALID_HANDLE_VALUE {
			win32_video.log_path = copy_string(log_path);
			break;
		}
	}
	if log_handle == INVALID_HANDLE_VALUE {
		video_fail_locked("cannot create FFmpeg diagnostic log", GetLastError());
		return win32_video_status();
	}
	defer CloseHandle(log_handle);
	read_pipe: HANDLE;
	write_pipe: HANDLE;
	if !Win32.CreatePipe(*read_pipe, *write_pipe, *security, 65536) {
		video_fail_locked("cannot create FFmpeg input pipe", GetLastError());
		return win32_video_status();
	}
	defer CloseHandle(read_pipe);
	if !Win32.SetHandleInformation(write_pipe, Win32.HANDLE_FLAG_INHERIT, 0) {
		video_fail_locked("cannot configure FFmpeg input pipe", GetLastError());
		CloseHandle(write_pipe);
		return win32_video_status();
	}
	// Fragmented MP4 works with stdout (no seek), remains inspectable during
	// recording, and keeps the file owned exclusively by our atomic CREATE_NEW.
	command := tprint("ffmpeg.exe -hide_banner -loglevel error -nostdin -f rawvideo -pixel_format rgb24 -video_size %x% -framerate % -i pipe:0 -an -c:v libx264 -preset ultrafast -threads 2 -g % -crf 20 -pix_fmt yuv420p -vf pad=ceil(iw/2)*2:ceil(ih/2)*2 -movflags +frag_keyframe+empty_moov+default_base_moof -f mp4 pipe:1\0", width, height, fps, fps);
	startup: Win32.STARTUPINFOA;
	startup.cb = size_of(Win32.STARTUPINFOA);
	startup.dwFlags = Win32.STARTF_USESTDHANDLES;
	startup.hStdInput = read_pipe;
	startup.hStdOutput = output_handle;
	startup.hStdError = log_handle;
	info: Win32.PROCESS_INFORMATION;
	if !Win32.CreateProcessA(null, command.data, null, null, 1, .CREATE_NO_WINDOW, null, null, *startup, *info) {
		video_fail_locked("FFmpeg startup failed (ffmpeg.exe must be on PATH)", GetLastError());
		CloseHandle(write_pipe);
		return win32_video_status();
	}
	CloseHandle(info.hThread);
	win32_video.process = info.hProcess;
	win32_video.process_id = info.dwProcessId;
	win32_video.input = write_pipe;
	bytes := width * height * 3;
	for * win32_video.frames {
		free(it.rgb.data);
		it.rgb.data = cast(*u8) alloc(bytes);
		it.rgb.count = bytes;
		it.repeat = 0;
	}
	win32_video.state = .Recording;
	if !thread_init(*win32_video.worker, video_worker_proc) {
		video_fail_locked("cannot start FFmpeg writer thread", GetLastError());
		CloseHandle(write_pipe);
		win32_video.input = null;
		Win32.TerminateProcess(info.hProcess, 1);
		CloseHandle(info.hProcess);
		win32_video.process = null;
		return win32_video_status();
	}
	win32_video.worker_started = true;
	thread_start(*win32_video.worker);
	return win32_video_status();
}

win32_video_shutdown :: () {
	if !win32_video.initialized return;
	win32_video_stop();
	deadline := video_GetTickCount64() + VIDEO_STOP_TIMEOUT_MS + 3000;
	while win32_video.worker_started && video_GetTickCount64() < deadline {
		win32_video_poll();
		if win32_video.worker_started Win32.Sleep(10);
	}
	if win32_video.worker_started {
		if win32_video.process Win32.TerminateProcess(win32_video.process, 1460);
		video_CancelSynchronousIo(win32_video.worker.windows_thread);
		signal(*win32_video.work);
		thread_is_done(*win32_video.worker, 2000);
		win32_video_poll();
	}
	// Never destroy a still-running worker's storage; process exit owns the
	// extremely unlikely cancellation failure. Only our FFmpeg was terminated.
	if win32_video.worker_started return;
	for * win32_video.frames {
		free(it.rgb.data);
		it.rgb = .{};
	}
	free(win32_video.path);
	free(win32_video.log_path);
	win32_video.path = "";
	win32_video.log_path = "";
	destroy(*win32_video.work);
	destroy(*win32_video.mutex);
	win32_video.initialized = false;
}
