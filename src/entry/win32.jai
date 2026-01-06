#import "Platform";
#import "Window_Creation";
#import "Input";
#import "File_Watcher";
#import "miniaudio";
#import "Basic"()(MEMORY_DEBUGGER=true);
#import "Hash_Table";
#import "Algebra";
#import "String";
#import "File";
#import "Math";
#import "Random";
STB :: #import "stb_image";
#import "SDL";
#import "Reflection";
#import "Curl";
Win32 :: #import "Windows";

sdl_window: *SDL_Window;
sdl_gl_context: SDL_GLContext;
g_Time: u64 = 0;

pressed: [Key_COUNT] bool;

curl: *CURL;
curl_connected := false;
curl_errbuf: [CURL_ERROR_SIZE] u8;
curl_buffer: [] u8;

fake_one_way_ping := 0.0;

launcher_context: #Context;

map_sdl_to_key :: (key: SDL_Keycode) -> Key {
	if key == {
		case SDLK_a; return Key.A;
		case SDLK_z; return Key.Z;
		case SDLK_e; return Key.E;
		case SDLK_r; return Key.R;
		case SDLK_t; return Key.T;
		case SDLK_y; return Key.Y;
		case SDLK_u; return Key.U;
		case SDLK_i; return Key.I;
		case SDLK_o; return Key.O;
		case SDLK_p; return Key.P;
		case SDLK_q; return Key.Q;
		case SDLK_s; return Key.S;
		case SDLK_d; return Key.D;
		case SDLK_f; return Key.F;
		case SDLK_g; return Key.G;
		case SDLK_h; return Key.H;
		case SDLK_j; return Key.J;
		case SDLK_k; return Key.K;
		case SDLK_l; return Key.L;
		case SDLK_m; return Key.M;
		case SDLK_w; return Key.W;
		case SDLK_x; return Key.X;
		case SDLK_c; return Key.C;
		case SDLK_v; return Key.V;
		case SDLK_b; return Key.B;
		case SDLK_n; return Key.N;
		case SDLK_SPACE; return Key.Space;
		case SDLK_ESCAPE; return Key.Escape;
		case SDLK_F1; return Key.F1;
		case SDLK_F2; return Key.F2;
		case SDLK_F3; return Key.F3;
		case SDLK_F4; return Key.F4;
		case SDLK_F5; return Key.F5;
		case SDLK_F6; return Key.F6;
		case SDLK_F7; return Key.F7;
		case SDLK_F8; return Key.F8;
		case SDLK_F9; return Key.F9;
		case SDLK_F10; return Key.F10;
		case SDLK_F11; return Key.F11;
		case SDLK_F12; return Key.F12;
		case SDLK_TAB; return Key.Tab;
		case SDLK_LSHIFT; return Key.Shift;
		case SDLK_RSHIFT; return Key.Shift;
		case SDLK_PERIOD; return Key.Period;
		case SDLK_KP_PERIOD; return Key.Period;
		case SDLK_BACKSPACE; return Key.Backspace;
		case SDLK_LEFT; return Key.Left;
		case SDLK_RIGHT; return Key.Right;
	}
	return xx key;
}

Message :: struct {
	data: [..] u8;
	sent_time: Apollo_Time;
}
messages_pending: [..] Message;
message_arrived: [..] Message;

#scope_export

win32_connect_server :: (address: string, port: int, protocol: string) -> Connection, bool {
	push_context,defer_pop launcher_context;
	curl_easy_cleanup(curl);
	curl = curl_easy_init();
	url := tprint("%://%:%/ws\0", protocol, address, port);
	print("Connecting to %\n", url);
	curl_easy_setopt(curl, .URL, url.data);
	curl_easy_setopt(curl, .ERRORBUFFER, curl_errbuf.data);
	curl_easy_setopt(curl, .CONNECTTIMEOUT_MS, 5000);
	curl_easy_setopt(curl, .CONNECT_ONLY, 2);
	curl_easy_setopt(curl, .SSL_VERIFYPEER, 0);
	curl_easy_setopt(curl, .SSL_VERIFYHOST, 0);
	curl_code := curl_easy_perform(curl);
	curl_connected = curl_code == .OK;
	if !curl_connected {
		str: string;
		str.data = curl_errbuf.data;
		str.count = c_style_strlen(curl_errbuf.data);
		print("Failed to connect(%) to server: %\n", curl_code, str);
	}
	return 0, curl_connected;
}

win32_is_server_connected :: () -> bool {
	push_context,defer_pop launcher_context;
	if !curl_connected
		return false;

	sock: curl_socket_t;
	curl_connected = curl_easy_getinfo(curl, .ACTIVESOCKET, *sock) == .OK;
	curl_connected &= sock != 0xFFFFFFFFFFFFFFFF;
	return curl_connected;
}

win32_read_entire_file :: (path: string, data: [] u8) -> int {
	push_context,defer_pop launcher_context;
	if !data.data {

		f := Win32.CreateFileA(to_c_string(path,, temp), Win32.FILE_GENERIC_READ);
		defer Win32.CloseHandle(f);

		size_struct: Win32.LARGE_INTEGER; // Kind of pointless, just pass *s64?
		size_success := Win32.GetFileSizeEx(f, *size_struct);
		if !size_success {
			return 0;
		}
		return size_struct.QuadPart.(int);
	}

	_data, ok := read_entire_file(path,, temp);
	if !ok {
		return 0;
	}

	memcpy(data.data, _data.data, xx min(_data.count, data.count));
	return min(_data.count, data.count);
}

win32_load_image :: (data: [] u8) -> Image {
	push_context,defer_pop launcher_context;
	image: Image;
	x: s32;
	y: s32;
	c: s32;
	STB.stbi_set_flip_vertically_on_load(1);
	image.data.data = STB.stbi_load_from_memory(
		xx data.data, xx data.count, *x, *y, *c, 4
	);
	image.data.count = x * y * 4;
	image.width = xx x;
	image.height = xx y;
	image.channels = 4;
	return image;
}

win32_free_image :: (image: *Image) {
	push_context,defer_pop launcher_context;
	STB.stbi_image_free(image.data.data);
	image.data.data = null;
	image.data.count = 0;
}

send_web_message :: (msg: [] u8, connection: Connection) {
	push_context,defer_pop launcher_context;
	message: Message;
	array_resize(*message.data, msg.count);
	memcpy(message.data.data, msg.data, msg.count);
	message.sent_time = current_time_monotonic();
	array_add(*messages_pending, message);
}

win32_get_token :: () -> int {
	push_context,defer_pop launcher_context;
	args := get_command_line_arguments();

	for 1..args.count-1 {
		if compare(args[it - 1], "-token") == 0 {
			token := 0;
			if scan2(args[it], "%", *token) {
				return token;
			}
		}
	}

	// print("Reading token from file...\n");
	// token, ok := read_entire_file("token.txt",, temp);
	// if !ok
	// 	return 1;
	
	// print("Read back \"%\"\n", token);
	// token_value := 0;
	// if scan2(token, "%", *token_value) {
	// 	return token_value;
	// }

	return 1;
}

win32_set_token :: (token: int) {
	// push_context,defer_pop launcher_context;
	// print("Writing token to file: %\n", token);
	// write_entire_file("token.txt", tprint("%", token));
}

win32_get_frame_info :: (info: *Frame_Info) {
	push_context,defer_pop launcher_context;
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
	info.time = current_time_monotonic();
	info.mouse_position.x = xx mx;
	info.mouse_position.y = xx (info.window_size.y - my);
	info.window_focused =  (SDL_GetWindowFlags(sdl_window) & SDL_WINDOW_MOUSE_FOCUS) > 0;


	GetKeyboardLayout :: (n: Win32.DWORD) -> Win32.HANDLE #foreign user32;
	LANG_ENGLISH :: 0x09;
	LANG_FRENCH  :: 0x0C;
	layout := GetKeyboardLayout(0);
	if (layout & 0xFF).(int) == {
		case LANG_ENGLISH;
			info.layout = .QWERTY;
		case LANG_FRENCH;
			info.layout = .AZERTY;
	}

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
			key := event.key.keysym.sym;
			map := map_sdl_to_key(xx key);
			if map < pressed.count
				pressed[map] = false;
		}
		if event.type == SDL_KEYDOWN {
			key := event.key.keysym.sym;
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
	while curl_connected {
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
			info.message_received[info.message_received_count - 1].data = NewArray(
				it.data.count, u8, initialized = false,, temp
			);
			// There is only one possible sender (the server), so whatever
			info.message_received[info.message_received_count - 1].sender = 0;
			memcpy(
				info.message_received[info.message_received_count - 1].data.data,
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

frame_counter := 0;
win32_end_frame :: () {
	push_context,defer_pop launcher_context;
	// SDL_GL_SwapWindow(sdl_window);

	cursor := 0;
	if curl_connected for * messages_pending {
		dt := to_float64_seconds(current_time_monotonic() - it.sent_time);
		if true || dt * 1000 >= fake_one_way_ping {
			sent: u64 = 0;
			code := curl_ws_send(curl, it.data.data, xx it.data.count, *sent, 0, CURLWS_BINARY);
			if code {
				str: string;
				str.data = curl_errbuf.data;
				str.count = c_style_strlen(curl_errbuf.data);
				print("Error sending message: %\n", str);
				curl_connected = false;
			}

			array_free(it.data);
		} else {
			messages_pending[cursor] = it.*;
			cursor += 1;
		}
	}
frame_counter += 1;
	messages_pending.count = cursor;
	process_changes(*watcher);
}

Win32_Sound :: struct {
	audio_id: int;
	sound: *ma_sound;
	decoder: *ma_decoder;
}

audio_id_to_data: Table(int, string);
sound_id_to_sound: Table(int, Win32_Sound);

audio_counter := 0;
sound_counter := 0;

load_audio :: (data: string, compressed: bool) -> Audio {
	push_context,defer_pop launcher_context;
	audio_counter += 1;

	audio: Audio;
	audio.id = audio_counter;
	// Load audio data

	table_add(*audio_id_to_data, audio.id, data);
	audio.loaded = true;
	return audio;
}
play_audio :: (audio: Audio, position: V3f) -> Sound {
	push_context,defer_pop launcher_context;
	ok, data := table_find(*audio_id_to_data, audio.id);
	
	config := ma_decoder_config_init(.unknown, 0, 0);
	sound_counter += 1;
	sound: Sound;
	sound.audio_id = audio.id;
	sound.id = sound_counter;
	sound.position = position;
	sound.playing = false;
	sound.volume = audio.volume;
	sound.pitch = audio.pitch;
	sound.loop = audio.repeating || audio.kind == .Music;

	if ok {
		decoder := New(ma_decoder);
		result := ma_decoder_init_memory(xx data.data, xx data.count, *config, decoder);
		if result != ma_result.SUCCESS {
			free(decoder);
			return sound;
		}

		msound := New(ma_sound);
		flags : ma_sound_flags = xx 0;
		if audio.kind == .Music {
			flags = ma_sound_flags.NO_SPATIALIZATION;
		}
		ma_sound_init_from_data_source(*audio_engine, decoder.ds.pCurrent, xx flags, null, msound);
		ma_sound_set_looping(msound, xx sound.loop);
		ma_sound_set_volume(msound, audio.volume);
		ma_sound_set_pitch(msound, pow(2, audio.pitch / 12.0));
		ma_sound_set_min_gain(msound, 0.0);
		ma_sound_set_max_gain(msound, 1.0);
		ma_sound_set_min_distance(msound, 1.0);
		ma_sound_set_max_distance(msound, 1000.0);
		ma_sound_set_rolloff(msound, audio.exponent);
		ma_sound_set_attenuation_model(msound, .exponential);
		ma_sound_set_pinned_listener_index(msound, 0);
		ma_sound_set_position(msound, position.x, position.y, position.z);
		ma_sound_set_fade_in_milliseconds(msound, 0.0, 1.0, xx audio.fade_in);
		ma_sound_set_start_time_in_milliseconds(
			msound, ma_engine_get_time_in_milliseconds(*audio_engine) + xx audio.delay
		);
		ma_sound_start(msound);

		sound.playing = true;
		win32_sound: Win32_Sound;
		win32_sound.audio_id = audio.id;
		win32_sound.sound = msound;
		win32_sound.decoder = decoder;
		table_add(*sound_id_to_sound, sound.id, win32_sound);
	}
	return sound;
}
set_listener_info :: (listener: Listener) {
	push_context,defer_pop launcher_context;
	ma_engine_listener_set_position(
		*audio_engine, 0, listener.position.x, listener.position.y, listener.position.z
	);
	ma_engine_listener_set_direction(
		*audio_engine, 0, listener.direction.x, listener.direction.y, listener.direction.z
	);
	ma_engine_listener_set_world_up(*audio_engine, 0, 0.0, 0.0, 1.0);
	ma_engine_listener_set_enabled(*audio_engine, 0, xx true);
}
query_sound :: (sound_id: int) -> Sound {
	push_context,defer_pop launcher_context;
	sound: Sound;
	sound.id = -1;
	ok, win32_sound := table_find(*sound_id_to_sound, sound_id);
	if ok {
		sound.audio_id = win32_sound.audio_id;
		sound.position = .{0,0,0};
		sound.playing = false;
		sound.volume = 1.0;
		sound.pitch = 1.0;
		sound.loop = false;

		if win32_sound.sound {
			pos := ma_sound_get_position(win32_sound.sound);
			sound.position = .{ pos.x, pos.y, pos.z };
			sound.playing = ma_sound_is_playing(win32_sound.sound) != 0;
			sound.volume = ma_sound_get_volume(win32_sound.sound);
			sound.pitch = ma_sound_get_pitch(win32_sound.sound);
			sound.loop = ma_sound_is_looping(win32_sound.sound) != 0;
		}
	}
	return sound;
}
set_sound :: (sound: Sound) {
	push_context,defer_pop launcher_context;
	ok, win32_sound := table_find(*sound_id_to_sound, sound.id);
	if ok && win32_sound.sound {
		ma_sound_set_position(
			win32_sound.sound, sound.position.x, sound.position.y, sound.position.z
		);
		if sound.playing && !ma_sound_is_playing(win32_sound.sound) {
			ma_sound_start(win32_sound.sound);
		} else if !sound.playing && ma_sound_is_playing(win32_sound.sound) {
			ma_sound_stop(win32_sound.sound);
		}
		ma_sound_set_looping(win32_sound.sound, xx sound.loop);
		ma_sound_set_volume(win32_sound.sound, sound.volume);
		// ma_sound_set_pitch(win32_sound.sound, sound.pitch);
	}
}

master_volume := 1.0;
volume_audio :: (x: float) -> float {
	push_context,defer_pop launcher_context;
	if x < 0
		return master_volume;
	master_volume = x;
	ma_engine_set_volume(*audio_engine, master_volume);
	return master_volume;
}

watcher: File_Watcher(Platform);
frame_file_change: [1024] string;
frame_file_change_count := 0;

audio_engine: ma_engine;

init_platform :: () -> Platform {
	platform: Platform;
	memset(pressed.data, 0, pressed.count);

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
	add_directories(*watcher, tprint("%/../../assets/", #filepath));

	{
		config: ma_engine_config = ma_engine_config_init();
		config.listenerCount = 1;
		ok := ma_engine_init(null, *audio_engine);
		if ok != ma_result.SUCCESS {
			print("Failed to initialize audio engine.\n");
		}

		ok2 := ma_engine_start(*audio_engine);
		if ok2 != ma_result.SUCCESS {
			print("Failed to start audio engine.\n");
		}

		ma_engine_listener_set_enabled(*audio_engine, 0, xx true);
	}

	curl_buffer = NewArray(1024*1024*32, u8, false);

	sdl_window = SDL_CreateWindow(
		tprint("Ice Escape %\0", win32_get_token()).data,
		SDL_WINDOWPOS_CENTERED,
		SDL_WINDOWPOS_CENTERED,
		1366,
		768,
		SDL_WINDOW_SHOWN
	);

	if sdl_window == null {
		return .{};
	}

	platform.connect_server = win32_connect_server;
	platform.is_server_connected = win32_is_server_connected;
	platform.read_entire_file = win32_read_entire_file;
	platform.load_image = win32_load_image;
	platform.free_image = win32_free_image;
	platform.get_frame_info = win32_get_frame_info;
	platform.end_frame = win32_end_frame;
	platform.send_web_message = send_web_message;
	platform.get_token = win32_get_token;
	platform.set_token = win32_set_token;
	platform.query_sound = query_sound;
	platform.set_sound = set_sound;
	platform.load_audio = load_audio;
	platform.play_audio = play_audio;
	platform.volume_audio = volume_audio;
	platform.set_listener_info = set_listener_info;

	wgpuCreateInstance :: (
		descriptor: *WGPUInstanceDescriptor
	) -> WGPUInstance #foreign wgpu_native;
	wgpuInstanceRequestAdapter :: (
		instance: WGPUInstance,
		options: *WGPURequestAdapterOptions,
		callbackInfo: WGPURequestAdapterCallbackInfo
	) -> WGPUFuture #foreign wgpu_native;
	wgpuAdapterGetLimits :: (
		adapter: WGPUAdapter, limits: *WGPULimits
	) -> WGPUStatus #foreign wgpu_native;
	wgpuSupportedFeaturesFreeMembers :: (
		supportedFeatures: WGPUSupportedFeatures
	) -> void #foreign wgpu_native;
	wgpuAdapterGetFeatures :: (
		adapter: WGPUAdapter, features: *WGPUSupportedFeatures
	) -> void #foreign wgpu_native;
	wgpuAdapterRelease :: (
		adapter: WGPUAdapter
	) -> void #foreign wgpu_native;
	wgpuAdapterRequestDevice :: (
		adapter: WGPUAdapter,
		descriptor: *WGPUDeviceDescriptor,
		callbackInfo: WGPURequestDeviceCallbackInfo
	) -> WGPUFuture #foreign wgpu_native;
	wgpuDeviceGetQueue :: (
		device: WGPUDevice
	) -> WGPUQueue #foreign wgpu_native;
	wgpuQueueRelease :: (
		queue: WGPUQueue
	) -> void #foreign wgpu_native;
	wgpuQueueSubmit :: (
		queue: WGPUQueue,
		commandCount: u64,
		commands: *WGPUCommandBuffer
	) -> void #foreign wgpu_native;
	wgpuQueueWriteBuffer :: (
		queue: WGPUQueue,
		buffer: WGPUBuffer,
		bufferOffset: u64,
		data: *void,
		dataSize: u64
	) -> void #foreign wgpu_native;
	wgpuQueueWriteTexture :: (
		queue: WGPUQueue,
		destination: *WGPUTexelCopyTextureInfo,
		data: *void,
		dataSize: u64,
		dataLayout: *WGPUTexelCopyBufferLayout,
		writeSize: *WGPUExtent3D
	) -> void #foreign wgpu_native;
	wgpuDeviceCreateCommandEncoder :: (
		device: WGPUDevice,
		descriptor: *WGPUCommandEncoderDescriptor
	) -> WGPUCommandEncoder #foreign wgpu_native;
	wgpuCommandEncoderFinish :: (
		encoder: WGPUCommandEncoder,
		descriptor: *WGPUCommandBufferDescriptor
	) -> WGPUCommandBuffer #foreign wgpu_native;
	wgpuCommandEncoderInsertDebugMarker :: (
		encoder: WGPUCommandEncoder,
		markerLabel: WGPUStringView
	) -> void #foreign wgpu_native;
	wgpuCommandBufferRelease :: (
		commandBuffer: WGPUCommandBuffer
	) -> void #foreign wgpu_native;
	wgpuCommandEncoderRelease :: (
		encoder: WGPUCommandEncoder
	) -> void #foreign wgpu_native;
	wgpuDeviceCreateBuffer :: (
		device: WGPUDevice,
		descriptor: *WGPUBufferDescriptor
	) -> WGPUBuffer #foreign wgpu_native;
	wgpuBufferRelease :: (
		buffer: WGPUBuffer
	) -> void #foreign wgpu_native;
	wgpuBufferGetMappedRange :: (
		buffer: WGPUBuffer,
		offset: u64,
		size: u64
	) -> *void #foreign wgpu_native;
	wgpuBufferUnmap :: (
		buffer: WGPUBuffer
	) -> void #foreign wgpu_native;
	wgpuSurfacePresent :: (
		surface: WGPUSurface
	) -> WGPUStatus #foreign wgpu_native;
	wgpuMyInstanceCreateSurface :: (
		instance: WGPUInstance,
		descriptor: *WGPUSurfaceDescriptor
	) -> WGPUSurface #c_call {
		wgpuInstanceCreateSurface :: (
			instance: WGPUInstance,
			descriptor: *WGPUSurfaceDescriptor
		) -> WGPUSurface #foreign wgpu_native;

		chained: WGPUSurfaceSourceWindowsHWND = .{};
		chained.hinstance = Win32.GetModuleHandleW(null);
		chained.chain.sType = .SurfaceSourceWindowsHWND;
		chained.chain.next = null;
		info: SDL_SysWMinfo = .{};

		ctx: #Context;
		push_context ctx {
			SDL_VERSION(*info.version);
			SDL_GetWindowWMInfo(sdl_window, *info);
		}
		chained.hwnd = xx info.info.win.window;

		_desc : WGPUSurfaceDescriptor = .{};
		if descriptor
			_desc = descriptor.*;

		_desc.nextInChain = xx *chained;

		return wgpuInstanceCreateSurface(instance, *_desc);
	};
	wgpuDeviceCreateShaderModule :: (
		device: WGPUDevice,
		descriptor: *WGPUShaderModuleDescriptor
	) -> WGPUShaderModule #foreign wgpu_native;
	wgpuDeviceCreateRenderPipeline :: (
		device: WGPUDevice,
		descriptor: *WGPURenderPipelineDescriptor
	) -> WGPURenderPipeline #foreign wgpu_native;

	wgpuCommandEncoderBeginRenderPass :: (
		encoder: WGPUCommandEncoder,
		descriptor: *WGPURenderPassDescriptor
	) -> WGPURenderPassEncoder #foreign wgpu_native;
	wgpuRenderPassEncoderRelease :: (
		pass: WGPURenderPassEncoder
	) -> void #foreign wgpu_native;
	wgpuRenderPassEncoderSetPipeline :: (
		pass: WGPURenderPassEncoder,
		pipeline: WGPURenderPipeline
	) -> void #foreign wgpu_native;
	wgpuRenderPassEncoderDraw :: (
		pass: WGPURenderPassEncoder,
		vertexCount: u32,
		instanceCount: u32,
		firstVertex: u32,
		firstInstance: u32
	) -> void #foreign wgpu_native;
	wgpuRenderPassEncoderEnd :: (
		pass: WGPURenderPassEncoder
	) -> void #foreign wgpu_native;
	wgpuSurfaceGetCurrentTexture :: (
		surface: WGPUSurface,
		surfaceTexture: *WGPUSurfaceTexture
	) -> void #foreign wgpu_native;
	wgpuTextureCreateView :: (
		texture: WGPUTexture,
		descriptor: *WGPUTextureViewDescriptor
	) -> WGPUTextureView #foreign wgpu_native;
	wgpuTextureViewRelease :: (
		textureView: WGPUTextureView
	) -> void #foreign wgpu_native;
	wgpuSurfaceConfigure :: (
		surface: WGPUSurface,
		descriptor: *WGPUSurfaceConfiguration
	) -> void #foreign wgpu_native;
	wgpuTextureGetFormat :: (
		texture: WGPUTexture
	) -> WGPUTextureFormat #foreign wgpu_native;
	wgpuDeviceCreateBindGroupLayout :: (
		device: WGPUDevice,
		descriptor: *WGPUBindGroupLayoutDescriptor
	) -> WGPUBindGroupLayout #foreign wgpu_native;
	wgpuBindGroupLayoutRelease :: (
		bindGroupLayout: WGPUBindGroupLayout
	) -> void #foreign wgpu_native;
	wgpuDeviceCreateBindGroup :: (
		device: WGPUDevice,
		descriptor: *WGPUBindGroupDescriptor
	) -> WGPUBindGroup #foreign wgpu_native;
	wgpuBindGroupRelease :: (
		bindGroup: WGPUBindGroup
	) -> void #foreign wgpu_native;
	wgpuRenderPipelineGetBindGroupLayout :: (
		pipeline: WGPURenderPipeline,
		index: u32
	) -> WGPUBindGroupLayout #foreign wgpu_native;
	wgpuRenderPassEncoderSetBindGroup :: (
		pass: WGPURenderPassEncoder,
		index: u32,
		bindGroup: WGPUBindGroup,
		dynamicOffsetCount: u64,
		dynamicOffsets: *u32
	) -> void #foreign wgpu_native;
	wgpuRenderPassEncoderSetVertexBuffer :: (
		pass: WGPURenderPassEncoder,
		slot: u32,
		buffer: WGPUBuffer,
		offset: u64,
		size: u64
	) -> void #foreign wgpu_native;
	wgpuDeviceCreateTexture :: (
		device: WGPUDevice,
		descriptor: *WGPUTextureDescriptor
	) -> WGPUTexture #foreign wgpu_native;
	wgpuTextureRelease :: (
		texture: WGPUTexture
	) -> void #foreign wgpu_native;
	wgpuDeviceCreateSampler :: (
		device: WGPUDevice,
		descriptor: *WGPUSamplerDescriptor
	) -> WGPUSampler #foreign wgpu_native;
	wgpuSamplerRelease :: (
		sampler: WGPUSampler
	) -> void #foreign wgpu_native;
	wgpuDeviceCreatePipelineLayout :: (
		device: WGPUDevice,
		descriptor: *WGPUPipelineLayoutDescriptor
	) -> WGPUPipelineLayout #foreign wgpu_native;
	wgpuPipelineLayoutRelease :: (
		pipelineLayout: WGPUPipelineLayout
	) -> void #foreign wgpu_native;
	wgpuRenderPassEncoderSetViewport :: (
		pass: WGPURenderPassEncoder,
		x: float32,
		y: float32,
		width: float32,
		height: float32,
		minDepth: float32,
		maxDepth: float32
	) -> void #foreign wgpu_native;
	webgpu_meta_run :: () -> string {
		sb: String_Builder;

		info : *Type_Info_Struct = cast(*Type_Info_Struct) type_info(GPU_proc);
		for info.members {
			capitalizedName := tprint("%", it.name);
			if capitalizedName.count > 0 {
				capitalizedName.data[0] = to_upper(capitalizedName.data[0]);
			}

			print(*sb, "platform.gpu.% = wgpu%;\n", it.name, capitalizedName);
		}

		return builder_to_string(*sb);
	}
	#insert #run webgpu_meta_run();

	return platform;
}


exit_platform :: (platform: Platform) {
	push_context,defer_pop launcher_context;
	SDL_GL_DeleteContext(sdl_gl_context);
	SDL_DestroyWindow(sdl_window);
	SDL_Quit();
}


dll: Win32.HMODULE;
dll_last_write: u64 = 0;
dll_generation := 0;
app: App;

load_dll :: () {
	Win32.CopyFileA("IceEscape.dll", "IceEscape_temp.dll", 0);

	dll = Win32.LoadLibraryA("IceEscape_temp.dll");
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

	// Win32.DeleteFileA("IceEscape_temp.dll");
	dll_name := tprint("IceEscape_temp_%.dll\0", dll_generation);
	Win32.CopyFileA("IceEscape.dll", dll_name.data, 0);

	dll_reloaded := Win32.LoadLibraryA(dll_name.data);
	if dll_reloaded == null {
		print("Failed to reload IceEscape.dll\n");
		return;
	}
	dll = dll_reloaded;

	// Get the function pointer of app_init
	app_reload := Win32.GetProcAddress(dll, "app_reload").(#type (app: *App) -> ());
	if app_reload {
		app_reload(*app);
	}
}

#import "tracy"(ENABLED = false);

main :: () {
	dll_generation = xx random_get();

	args := get_command_line_arguments();
	defer array_free(args);

	platform := init_platform();
	app.platform = *platform;
	app.user_data = null;

	load_dll();

	loop := true;
	while (loop) {
		FrameMarkStart();
		if dll {
			file := Win32.CreateFileA("IceEscape.dll", Win32.FILE_GENERIC_READ);
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
		FrameMarkEnd();
	}

	app_quit := Win32.GetProcAddress(dll, "app_quit").(#type (app: *App) -> ());
	if app_quit {
		app_quit(*app);
	}
}

wgpu_native :: #library "../lib/wgpu_native";
user32      :: #library,system "user32";
