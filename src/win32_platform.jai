#import "Platform";
#import "Window_Creation";
#import "Input";
#import "File_Watcher";
Sound :: #import "Sound_Player"(VERBOSE = false);
#import "Basic";
#import "Hash_Table";
#import "String";
GL :: #import "GL";
#import "SDL";
#import "Reflection";
#import "Curl";

sdl_window: *SDL_Window;
sdl_gl_context: SDL_GLContext;
g_Time: u64 = 0;

pressed: [Key_COUNT] bool;

curl: *CURL;
curl_errbuf: [CURL_ERROR_SIZE] u8;
curl_buffer: [] u8;

fake_one_way_ping := 0.0;

map_sdl_to_key :: (key: int) -> int {
	if key == {
		case xx SDLK_a; return xx Key.A;
		case xx SDLK_z; return xx Key.Z;
		case xx SDLK_e; return xx Key.E;
		case xx SDLK_r; return xx Key.R;
		case xx SDLK_t; return xx Key.T;
		case xx SDLK_y; return xx Key.Y;
		case xx SDLK_u; return xx Key.U;
		case xx SDLK_i; return xx Key.I;
		case xx SDLK_o; return xx Key.O;
		case xx SDLK_p; return xx Key.P;
		case xx SDLK_q; return xx Key.Q;
		case xx SDLK_s; return xx Key.S;
		case xx SDLK_d; return xx Key.D;
		case xx SDLK_f; return xx Key.F;
		case xx SDLK_g; return xx Key.G;
		case xx SDLK_h; return xx Key.H;
		case xx SDLK_j; return xx Key.J;
		case xx SDLK_k; return xx Key.K;
		case xx SDLK_l; return xx Key.L;
		case xx SDLK_m; return xx Key.M;
		case xx SDLK_w; return xx Key.W;
		case xx SDLK_x; return xx Key.X;
		case xx SDLK_c; return xx Key.C;
		case xx SDLK_v; return xx Key.V;
		case xx SDLK_b; return xx Key.B;
		case xx SDLK_n; return xx Key.N;
		case xx SDLK_SPACE; return xx Key.Space;
		case xx SDLK_F1; return xx Key.F1;
		case xx SDLK_F2; return xx Key.F2;
		case xx SDLK_F3; return xx Key.F3;
		case xx SDLK_F4; return xx Key.F4;
		case xx SDLK_F5; return xx Key.F5;
		case xx SDLK_F6; return xx Key.F6;
		case xx SDLK_F7; return xx Key.F7;
		case xx SDLK_F8; return xx Key.F8;
		case xx SDLK_F9; return xx Key.F9;
		case xx SDLK_F10; return xx Key.F10;
		case xx SDLK_F11; return xx Key.F11;
		case xx SDLK_F12; return xx Key.F12;
	}
	return key;
}

Message :: struct {
	data: [..] u8;
	sent_time: Apollo_Time;
}
messages_pending: [..] Message;
message_arrived: [..] Message;

#scope_export

send_web_message :: (msg: [] u8) {
	message: Message;
	array_resize(*message.data, msg.count);
	memcpy(message.data.data, msg.data, msg.count);
	message.sent_time = current_time_monotonic();
	array_add(*messages_pending, message);
}

win32_get_token :: () -> int {
	args := get_command_line_arguments();

	for 1..args.count-1 {
		if compare(args[it - 1], "-token") == 0 {
			token := 0;
			if scan2(args[it], "%", *token) {
				return token;
			}
		}
	}

	return 1;
}

win32_set_token :: (token: int) {
	// no-op
}

win32_get_frame_info :: (info: *Frame_Info) {
	info.* = .{};
	// Setup display size (every frame to accommodate for window resizing)
	w, h: s32;
	SDL_GetWindowSize(sdl_window, *w, *h);
	display_w, display_h: s32;
	SDL_GL_GetDrawableSize(sdl_window, *display_w, *display_h);

	info.window_size = .{ xx w, xx h };
	info.framebuffer_size = .{ xx display_w, xx display_h };

	frequency := SDL_GetPerformanceFrequency();
	current_time := SDL_GetPerformanceCounter();
	if g_Time > 0 {
		info.delta_time = cast(float)((cast(float64)(current_time - g_Time)) / frequency);
	} else {
		info.delta_time = (1.0/60.0);
	}
	g_Time = current_time;

	// Setup inputs
	// (we already got mouse wheel, keyboard keys & characters from SDL_PollEvent())
	mx, my: s32;
	mouseMask := SDL_GetMouseState(*mx, *my);
	info.mouse_position.x = xx mx;
	info.mouse_position.y = xx (info.window_size.y - my);
	info.window_focused =  (SDL_GetWindowFlags(sdl_window) & SDL_WINDOW_MOUSE_FOCUS) > 0;

	event: SDL_Event;
	while SDL_PollEvent(*event) {
		if event.type == SDL_MOUSEWHEEL {
			if event.wheel.y > 0
				info.mouse_wheel = 1;
			if event.wheel.y < 0
				info.mouse_wheel = -1;
		}
		if event.type == SDL_MOUSEBUTTONDOWN {
			if event.button.button == SDL_BUTTON_LEFT   pressed[Key.MouseLeft] = true;
			if event.button.button == SDL_BUTTON_RIGHT  pressed[Key.MouseRight] = true;
			if event.button.button == SDL_BUTTON_MIDDLE pressed[Key.MouseMiddle] = true;
		}
		if event.type == SDL_MOUSEBUTTONUP {
			if event.button.button == SDL_BUTTON_LEFT   pressed[Key.MouseLeft] = false;
			if event.button.button == SDL_BUTTON_RIGHT  pressed[Key.MouseRight] = false;
			if event.button.button == SDL_BUTTON_MIDDLE pressed[Key.MouseMiddle] = false;
		}
		// if event.type == SDL_TEXTINPUT {
		//     io.AddInputCharactersUTF8(io, xx event.text.text.data);
		// }
		if event.type == SDL_KEYUP {
			key := event.key.keysym.sym & (xx ~(1<<30));
			map := map_sdl_to_key(xx key);
			if map < pressed.count
				pressed[map] = false;
		}
		if event.type == SDL_KEYDOWN {
			key := event.key.keysym.sym & (xx ~(1<<30));
			map := map_sdl_to_key(xx key);
			if map < pressed.count
				pressed[map] = true;
			// kmod := SDL_GetModState();
			// io.KeyShift = ((kmod & KMOD_SHIFT) != 0);
			// io.KeyCtrl = ((kmod & KMOD_CTRL) != 0);
			// io.KeyAlt = ((kmod & KMOD_ALT) != 0);
			// io.KeySuper = ((kmod & KMOD_GUI) != 0);
		}
		if event.type == SDL_QUIT
			info.quit = true;
		if event.type == SDL_WINDOWEVENT
		&& event.window.event == SDL_WINDOWEVENT_CLOSE
		&& event.window.windowID == SDL_GetWindowID(sdl_window)
			info.quit = true;
	}

	for * info.key_pressed {
		it.* = pressed[it_index];
	}

	frame: *curl_ws_frame;
	recv: u64;

	buffer := curl_buffer;
	total_recv := 0;
	while true {
		recv = 0;
		curl_ws_recv(curl, buffer.data, xx buffer.count, *recv, *frame);
		if !frame || recv == 0
			break;
		buffer.data += recv;
		buffer.count -= xx recv;
		total_recv += xx recv;
	}

	cursor := 0;
	while cursor < (xx total_recv) && info.message_received_count < info.message_received.count {
		next_message_length := (cast(*u64)(curl_buffer.data + cursor)).*;

		msg: Message;
		array_resize(*msg.data, xx next_message_length);
		memcpy(msg.data.data, curl_buffer.data + cursor, xx next_message_length);
		msg.sent_time = current_time_monotonic();
		array_add(*message_arrived, msg);

		cursor += xx next_message_length;
	}

	info.message_received_count = 0;
	cursor = 0;
	for * message_arrived {
		dt := to_float64_seconds(current_time_monotonic() - it.sent_time);

		if 1000 * dt >= fake_one_way_ping {
			info.message_received_count += 1;
			info.message_received[info.message_received_count - 1] = NewArray(
				it.data.count, u8, initialized = false,, temp
			);
			memcpy(
				info.message_received[info.message_received_count - 1].data,
				it.data.data,
				it.data.count
			);
		} else {
			message_arrived[cursor] = it.*;
			cursor += 1;
		}
	}
	message_arrived.count = cursor;

	info.file_change_count = frame_file_change_count;
	for 0..frame_file_change_count-1 {
		info.file_change[it] = talloc_string(frame_file_change[it].count);
		memcpy(
			info.file_change[it].data,
			frame_file_change[it].data,
			frame_file_change[it].count
		);
		free(frame_file_change[it]);
	}
	frame_file_change_count = 0;
}

win32_end_frame :: () {
	SDL_GL_SwapWindow(sdl_window);

	cursor := 0;
	for * messages_pending {
		dt := to_float64_seconds(current_time_monotonic() - it.sent_time);
		if dt * 1000 >= fake_one_way_ping {
			sent: u64 = 0;
			code := curl_ws_send(curl, it.data.data, xx it.data.count, *sent, 0, CURLWS_TEXT);
			if code {
				str: string;
				str.data = curl_errbuf.data;
				str.count = c_style_strlen(curl_errbuf.data);
				print("Error sending message: %\n", str);
			}

			array_free(it.data);
		} else {
			messages_pending[cursor] = it.*;
			cursor += 1;
		}
	}

	messages_pending.count = cursor;
	Sound.update();
	process_changes(*watcher);
}

audio_table: Table(int, *Sound.Sound_Data);
audio_counter := 0;

load_audio :: (data: string) -> Audio {
	audio_counter += 1;

	audio: Audio;
	audio.id = audio_counter;
	// Load audio data
	sound := Sound.load_audio_data("Machin", data);
	sound_ptr := New(Sound.Sound_Data);
	sound_ptr.* = sound;
	table_set(*audio_table, audio.id, sound_ptr);

	return audio;
}
play_audio :: (audio: *Audio) {
	ok, sound := table_find_new(*audio_table, audio.id);
	if ok {
		stream: *Sound.Sound_Stream;
		if audio.kind == {
			case .Music;
				stream = Sound.make_stream(sound, .MUSIC);
			case .Sound;
				stream = Sound.make_stream(sound, .GENERAL_SFX);
		}
		stream.user_volume_scale = audio.volume;
		stream.internal_flags &= ~.WAITING_FOR_INITIAL_DECODER_PAGES;
		Sound.set_repeating(stream, audio.repeating);
		Sound.start_playing(stream);
	}
}
query_audio :: (audio: *Audio) -> bool {
	return false;
}

master_volume := 1.0;
volume_audio :: (x: float) -> float {
	if x < 0
		return master_volume;
	master_volume = x;
	Sound.set_master_volume(master_volume);
	return master_volume;
}

watcher: File_Watcher(Platform);
frame_file_change: [1024] string;
frame_file_change_count := 0;

init_platform :: () -> Platform {
	platform: Platform;
	for * pressed
		it.* = false;

	version := curl_version_info(.LAST);
	curl = curl_easy_init();
	curl_easy_setopt(curl, .URL, "ws://localhost:5623/ws");
	curl_easy_setopt(curl, .ERRORBUFFER, curl_errbuf.data);
	curl_easy_setopt(curl, .CONNECT_ONLY, 2);
	curl_code := curl_easy_perform(curl);
	init(*watcher, (watcher: *File_Watcher(Platform), change: *File_Change, user_data: *Platform) {
		frame_file_change_count %= frame_file_change.count;
		frame_file_change[frame_file_change_count] = alloc_string(change.full_path.count);
		memcpy(
			frame_file_change[frame_file_change_count].data,
			change.full_path.data,
			change.full_path.count
		);
		frame_file_change_count += 1;
	}, *platform);
	add_directories(*watcher, tprint("%/../assets/", #filepath));

	Sound.sound_player_init(.{
		audible_when_window_is_not_in_focus = true,
		update_from_a_thread = false
	});

	curl_buffer = NewArray(1024*1024*32, u8, false);

	sdl_window = SDL_CreateWindow(
		tprint("Ice Escape %\0", win32_get_token()).data,
		SDL_WINDOWPOS_CENTERED,
		SDL_WINDOWPOS_CENTERED,
		1366,
		768,
		SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE
	);

	if sdl_window == null {
		return .{};
	}

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

	sdl_gl_context = SDL_GL_CreateContext(sdl_window);
	if !sdl_gl_context {
		return .{};
	}

	platform.get_frame_info = win32_get_frame_info;
	platform.end_frame = win32_end_frame;
	platform.send_web_message = send_web_message;
	platform.get_token = win32_get_token;
	platform.set_token = win32_set_token;
	platform.query_audio = query_audio;
	platform.load_audio = load_audio;
	platform.play_audio = play_audio;
	platform.volume_audio = volume_audio;

	GL.gl_load(*GL.gl, SDL_GL_GetProcAddress);

	meta_run :: () -> string {
		sb: String_Builder;

		info : *Type_Info_Struct = cast(*Type_Info_Struct) type_info(RHI_proc);
		for info.members {
			print(*sb, "platform.rhi.% = GL.%;\n", it.name, it.name);
		}

		return builder_to_string(*sb);
	}
	#insert #run meta_run();

	context.rhi = platform.rhi;
	return platform;
}


exit_platform :: (platform: Platform) {
	SDL_GL_DeleteContext(sdl_gl_context);
	SDL_DestroyWindow(sdl_window);
	SDL_Quit();
}