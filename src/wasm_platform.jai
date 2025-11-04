#scope_file
// #import "Window_Creation";
#import "WAllocator";
// #import "Input";
#import "Basic";
#import "String";
#import "Hash_Table";
// Sound :: #import "Sound_Player";
// WebGL :: #import "Toolchains/Web/WebGL";

// window: Window_Type;
pressed: [Key_COUNT] bool;

web_buffer: [] u8;
last_frame: Apollo_Time;
last_frame_init := false;
map_key_to_key :: (key: int) -> int {
	if key == {
		case #char "A"; return xx Key.A;
		case #char "Z"; return xx Key.Z;
		case #char "E"; return xx Key.E;
		case #char "R"; return xx Key.R;
		case #char "T"; return xx Key.T;
		case #char "Y"; return xx Key.Y;
		case #char "U"; return xx Key.U;
		case #char "I"; return xx Key.I;
		case #char "O"; return xx Key.O;
		case #char "P"; return xx Key.P;
		case #char "Q"; return xx Key.Q;
		case #char "S"; return xx Key.S;
		case #char "D"; return xx Key.D;
		case #char "F"; return xx Key.F;
		case #char "G"; return xx Key.G;
		case #char "H"; return xx Key.H;
		case #char "J"; return xx Key.J;
		case #char "K"; return xx Key.K;
		case #char "L"; return xx Key.L;
		case #char "M"; return xx Key.M;
		case #char "W"; return xx Key.W;
		case #char "X"; return xx Key.X;
		case #char "C"; return xx Key.C;
		case #char "V"; return xx Key.V;
		case #char "B"; return xx Key.B;
		case #char "N"; return xx Key.N;
		case xx Key_Code.MOUSE_BUTTON_LEFT; return xx Key.MouseLeft;
		case xx Key_Code.MOUSE_BUTTON_RIGHT; return xx Key.MouseRight;
		case xx Key_Code.MOUSE_BUTTON_MIDDLE; return xx Key.MouseMiddle;
		case xx Key_Code.SPACEBAR; return xx Key.Space;
		case xx Key_Code.F1; return xx Key.F1;
		case xx Key_Code.F2; return xx Key.F2;
		case xx Key_Code.F3; return xx Key.F3;
		case xx Key_Code.F4; return xx Key.F4;
		case xx Key_Code.F5; return xx Key.F5;
		case xx Key_Code.F6; return xx Key.F6;
		case xx Key_Code.F7; return xx Key.F7;
		case xx Key_Code.F8; return xx Key.F8;
		case xx Key_Code.F9; return xx Key.F9;
		case xx Key_Code.F10; return xx Key.F10;
		case xx Key_Code.F11; return xx Key.F11;
		case xx Key_Code.F12; return xx Key.F12;
		case xx Key_Code.TAB; return xx Key.Tab;
	}
	return -1;
}
#scope_export

send_web_message :: (msg: [] u8) {
	js_send_web_message :: (data: *void, count: int) #foreign;
	js_send_web_message(msg.data, msg.count);
}

wasm_get_frame_info :: (info: *Frame_Info) {
	info.* = .{};

	info.delta_time = 1.0 / 60.0;
	if last_frame_init {
		info.delta_time = xx to_float64_seconds(
			current_time_monotonic() - last_frame
		);
	}
	last_frame = current_time_monotonic();
	last_frame_init = true;
	info.framebuffer_size = .{ xx 1366, xx 768 };
	info.quit = false;
	info.window_focused = true;
	info.window_size = .{ xx 1366, xx 768 };

	jsGetKeyState :: (key_map_ptr: *bool, key_map_count: s64) #foreign;
	jsGetKeyState(pressed.data, pressed.count);
	// update_window_events();
// 
	// for events_this_frame {
	// 	if it.type == {
	// 		case .KEYBOARD;
	// 			mapped := map_key_to_key(xx it.key_code);
	// 			if mapped >= 0 {
	// 				pressed[mapped] = it.key_pressed > 0;
	// 			}
	// 		case .QUIT;
	// 			info.quit = true;
	// 		case .MOUSE_WHEEL;
	// 			info.mouse_wheel = it.wheel_delta;
	// 	}
	// }

	x: u32;
	y: u32;
	jsGetMousePointer :: (x_ptr: *u32, y_ptr: *u32) #foreign;
	jsGetMousePointer(*x, *y);
	info.mouse_position.x = xx x;
	info.mouse_position.y = xx y;

	delta: float32;
	jsGetMouseWheelDelta :: (delta_ptr: *float32) #foreign;
	jsGetMouseWheelDelta(*delta);
	info.mouse_wheel = xx delta;

	dim: [4] u32;
	jsGetDimensions :: (dim_ptr: *u32) #foreign;
	jsGetDimensions(dim.data);
	wx := dim[0];
	wy := dim[1];
	ww := dim[2];
	wh := dim[3];
	info.framebuffer_size = .{ xx ww, xx wh };
	info.window_size = .{ xx ww, xx wh };
	info.mouse_position.y = info.window_size.y - info.mouse_position.y;

	for * info.key_pressed {
		it.* = pressed[it_index];
	}

	js_get_web_message_received :: (data: *void, count: int, recv: *void) #foreign;
	{
		recv := 0;
		js_get_web_message_received(web_buffer.data, web_buffer.count, *recv);

		n := 0;
		cursor := 0;
		while cursor < (xx recv) && info.message_received_count < info.message_received.count {
			next_message_length := (cast(*u64)(web_buffer.data + cursor)).*;

			msg: Web_Message;
			msg.data = web_buffer.data + cursor;
			msg.count = xx next_message_length;
			info.message_received[info.message_received_count] = msg;
			info.message_received_count += 1;

			cursor += xx next_message_length;
			n += 1;
		}
	}
}

// audio_table: Table(int, *Sound.Sound_Data);
// audio_counter := 0;

load_audio :: (data: string, compressed: bool) -> Audio {
	Params :: struct {
		data: *u8;
		count: s64;
		id: *s64;
		compressed: u64;
	}
	js_load_audio :: (params: *Params) #foreign;
	audio: Audio;
	params: Params;
	params.data = cast(*u8) data.data;
	params.count = xx data.count;
	params.compressed = xx compressed;
	params.id = *audio.id;
	js_load_audio(*params);

	return audio;
}
play_audio :: (audio: Audio, position: V3f) -> Sound {
	Params :: struct {
		id: s64;
		x: float32;
		y: float32;
		z: float32;
		volume: float32;
		pitch: float32;
		repeating: u32;
		kind: s32;
		fade_in: s32;
		exponent: float32;

		sound_id: *s64;

		delay: float32;
	}

	js_play_audio :: (params: *Params) #foreign;
	sound: Sound;
	params: Params;
	params.id = xx audio.id;
	params.x = xx position.x;
	params.y = xx position.y;
	params.z = xx position.z;
	params.volume = xx audio.volume;
	params.pitch = xx audio.pitch;
	params.repeating = xx audio.repeating;
	params.kind = xx audio.kind;
	params.fade_in = xx audio.fade_in;
	params.sound_id = *sound.id;
	params.exponent = xx audio.exponent;
	params.delay = xx audio.delay;
	js_play_audio(*params);

	sound.audio_id = audio.id;
	sound.playing = true;
	sound.position = position;
	sound.loop = audio.repeating || audio.kind == .Music;
	return sound;
}
query_sound :: (sound_id: int) -> Sound {
	Params :: struct {
		sound_id: s64;
		id: *s64;
		x: *float32;
		y: *float32;
		z: *float32;
		volume: *float32;
		pitch: *float32;
		playing: *u32;
		looping: *u32;
	}
	js_query_sound :: (params: *Params) #foreign;
	params: Params;
	sound: Sound;
	params.sound_id = xx sound_id;
	params.id = *sound.id;
	params.x = *sound.position.x;
	params.y = *sound.position.y;
	params.z = *sound.position.z;
	params.volume = *sound.volume;
	params.pitch = *sound.pitch;
	u32_looping : u32 = 0;
	params.looping = *u32_looping;
	u32_playing : u32 = 0;
	params.playing = *u32_playing;
	js_query_sound(*params);
	sound.playing = u32_playing != 0;
	sound.loop = u32_looping != 0;
	return sound;
}
set_sound :: (sound: Sound) {
	Params :: struct {
		sound_id: s64;
		x: float32;
		y: float32;
		z: float32;
		volume: float32;
		pitch: float32;
		playing: u32;
		looping: u32;
	}
	js_set_sound :: (params: *Params) #foreign;
	params: Params;
	params.sound_id = xx sound.id;
	params.x = xx sound.position.x;
	params.y = xx sound.position.y;
	params.z = xx sound.position.z;
	params.volume = xx sound.volume;
	params.pitch = xx sound.pitch;
	params.playing = xx sound.playing;
	params.looping = xx sound.loop;
	js_set_sound(*params);
	// Sound.update();
}
set_listener_info :: (listener: Listener) {
	Params :: struct {
		x: float32;
		y: float32;
		z: float32;
		dx: float32;
		dy: float32;
		dz: float32;
	}
	js_set_listener_info :: (params: *Params) #foreign;
	params: Params;
	params.x = xx listener.position.x;
	params.y = xx listener.position.y;
	params.z = xx listener.position.z;
	params.dx = xx listener.direction.x;
	params.dy = xx listener.direction.y;
	params.dz = xx listener.direction.z;
	js_set_listener_info(*params);
}

wasm_end_frame ::  () {
	// js_webgl_swap_buffers :: (window: Window_Type, vsync: bool) #foreign;
	// js_webgl_swap_buffers(window, false);
	// Sound.update();
}

init_platform :: () -> Platform {

	// window := create_window(1366, 768, "Ice Escape");
	for * pressed
		it.* = false;
	// js_webgl_swap_buffers :: (window: Window_Type, vsync: bool) #foreign;
	// js_webgl_swap_buffers(window, false);

	// Sound.sound_player_init(.{ audible_when_window_is_not_in_focus = true });
	web_buffer = NewArray(1024*1024*32, u8, false);

	platform: Platform;

	platform.get_frame_info = wasm_get_frame_info;
	platform.end_frame = wasm_end_frame;
	platform.send_web_message = send_web_message;
	platform.get_token = get_token;
	platform.set_token = set_token;
	platform.load_audio = load_audio;
	platform.play_audio = play_audio;
	platform.query_sound = query_sound;
	platform.set_sound = set_sound;
	platform.set_listener_info = set_listener_info;
	platform.volume_audio = (x: float) -> float {
		// Clamp the volume between 0.0 and 1.0
		if x < 0.0 {
			x = 0.0;
		} else if x > 1.0 {
			x = 1.0;
		}
		return x;
	};

	meta_run :: () -> string {
		sb: String_Builder;

		blacklist : [] string = .[
			"glColorMaski",
			"glClearDepth",
			"glPolygonMode",
			"glVertexAttrib1d",
			"glVertexAttrib1dv",
			"glVertexAttrib1s",
			"glVertexAttrib1sv",
			"glVertexAttrib2d",
			"glVertexAttrib2dv",
			"glVertexAttrib2s",
			"glVertexAttrib2sv",
			"glVertexAttrib3d",
			"glVertexAttrib3dv",
			"glVertexAttrib3s",
			"glVertexAttrib3sv",
			"glVertexAttrib4Nbv",
			"glVertexAttrib4Niv",
			"glVertexAttrib4Nsv",
			"glVertexAttrib4Nuv",
			"glVertexAttrib4Nub",
			"glVertexAttrib4Nubv",
			"glVertexAttrib4Nuiv",
			"glVertexAttrib4Nusv",
			"glVertexAttrib4bv",
			"glVertexAttrib4d",
			"glVertexAttrib4dv",
			"glVertexAttrib4iv",
			"glVertexAttrib4s",
			"glVertexAttrib4sv",
			"glVertexAttrib4ubv",
			"glVertexAttrib4uiv",
			"glVertexAttrib4usv",
			"glGetAttribLocation",
			"glIsEnabled",
		];

		info : *Type_Info_Struct = cast(*Type_Info_Struct) type_info(RHI_proc);
		for info.members {
			found := false;

			for b: blacklist {
				if compare(b, it.name) == 0 {
					found = true;
					break;
				}
			}

			if !found
				print(*sb, "platform.rhi.% = WebGL.%;\n", it.name, it.name);
		}

		return builder_to_string(*sb);
	}
	// #insert #run meta_run();
	context.rhi = platform.rhi;

	#insert #run -> string {
		sb: String_Builder;

		for entries {
			if it.special_function.count > 0 {
				print(*sb, "platform.gpu.% = %;\n", it.name, it.special_function);
			}
		}

		return builder_to_string(*sb);
	};


	return platform;
}

exit_platform :: (platform: Platform) {
	
}

get_token :: () -> int {
	js_get_token :: () -> s32 #foreign;
	return js_get_token();
}

set_token :: (token: int) {
	js_set_token :: (window: s32) #foreign;
	js_set_token(xx token);
}

get_type_name :: (info: *Type_Info) -> string {
    if info.type == {
        case .INTEGER;
            int_info := cast(*Type_Info_Integer) info;
            if int_info.signed {
                if int_info.runtime_size == 1 return "s8";
                if int_info.runtime_size == 2 return "s16";
                if int_info.runtime_size == 4 return "s32";
                if int_info.runtime_size == 8 return "s64";
                return "int";
            } else {
                if int_info.runtime_size == 1 return "u8";
                if int_info.runtime_size == 2 return "u16";
                if int_info.runtime_size == 4 return "u32";
                if int_info.runtime_size == 8 return "u64";
                return "uint";
            }
        case .FLOAT;
            float_info := cast(*Type_Info_Float) info;
            if float_info.runtime_size == 4 return "float32";
            if float_info.runtime_size == 8 return "float64";
            return "float";
        case .BOOL;
            return "bool";
        case .STRING;
            return "string";
        case .POINTER;
            pointer_info := cast(*Type_Info_Pointer) info;
            pointee_name := get_type_name(pointer_info.pointer_to);
            return tprint("*%", pointee_name);
        case .ARRAY;
            array_info := cast(*Type_Info_Array) info;
            element_name := get_type_name(array_info.element_type);
            if array_info.array_type == .FIXED {
                return tprint("[%]%", array_info.array_count, element_name);
            } else {
                return tprint("[]%", element_name);
            }
        case .STRUCT;
            struct_info := cast(*Type_Info_Struct) info;
            return struct_info.name;
        case .ENUM;
            enum_info := cast(*Type_Info_Enum) info;
            return enum_info.name;
        case .PROCEDURE;
            return "procedure"; // Could recursively call procedure_type_to_string here
        case .VOID;
            return "void";
    }
    
    return "unknown_type";
}

header_proc :: (info: *Type_Info_Procedure) -> string {
    sb: String_Builder;
    
    // Start with opening parenthesis
    append(*sb, "(");
    
    // Add arguments
    for i: 0..info.argument_types.count-1 {
        if i > 0 append(*sb, ", ");
        
        // Add argument type
        type_name := get_type_name(info.argument_types[i]);
        append(*sb, type_name);
    }
    
    append(*sb, ")");
    
    // Add return type if present
    if info.return_types.count > 0 {
        append(*sb, " -> ");
        
        if info.return_types.count == 1 {
            type_name := get_type_name(info.return_types[0]);
            append(*sb, type_name);
        } else {
            // Multiple return types - need parentheses
            append(*sb, "(");
            for i: 0..info.return_types.count-1 {
                if i > 0 append(*sb, ", ");
                type_name := get_type_name(info.return_types[i]);
                append(*sb, type_name);
            }
            append(*sb, ")");
        }
    }
    
    return builder_to_string(*sb);
}

Entry :: struct {
	name: string;
	type: Type;
	special_function := "";
}

wasmCreateInstance :: (descriptor: *WGPUInstanceDescriptor) -> WGPUInstance #c_call {
	jsCreateInstance :: (params: *void, returns: *void) #foreign;
	instance: WGPUInstance;
	jsCreateInstance(null, *instance);
	return instance;
}
wasmInstanceRequestAdapter :: (
	instance: WGPUInstance,
	options: *WGPURequestAdapterOptions,
	callbackInfo: WGPURequestAdapterCallbackInfo
) -> WGPUFuture #c_call {
	jsInstanceRequestAdapter :: (params: *void, returns: *void) #foreign;
	adapter: WGPUAdapter;
	jsInstanceRequestAdapter(null, *adapter);
	callbackInfo.callback(.Success, adapter, .{}, callbackInfo.userdata1, callbackInfo.userdata2);
	return .{};
}
wasmAdapterGetLimits :: (
	adapter: WGPUAdapter,
	limits: *WGPULimits
) -> WGPUStatus #c_call
{
	jsAdapterGetLimits :: (params: *void, returns: *void) #foreign;

	params: struct {
		adapter: WGPUAdapter;
		limits: *WGPULimits;
	};
	params.adapter = adapter;
	params.limits = limits;

	result: WGPUStatus;
	jsAdapterGetLimits(*params, *result);
	return result;
}
wasmAdapterGetFeatures :: (
	adapter: WGPUAdapter,
	features: *WGPUSupportedFeatures
) #c_call
{
	jsAdapterGetFeatures :: (params: *void, returns: *void) #foreign;

	params: struct {
		adapter: WGPUAdapter;
		features: *WGPUSupportedFeatures;
	};
	params.adapter = adapter;
	params.features = features;

	result: WGPUStatus;
	jsAdapterGetFeatures(*params, *result);
}
wasmSupportedFeaturesFreeMembers :: (features: WGPUSupportedFeatures) #c_call {
	jsSupportedFeaturesFreeMembers :: (params: *void, returns: *void) #foreign;
	jsSupportedFeaturesFreeMembers(*features, null);
}
wasmAdapterRelease :: (adapter: WGPUAdapter) -> void #c_call {
	jsAdapterRelease :: (params: *void, returns: *void) #foreign;
	jsAdapterRelease(*adapter, null);
}


// we expose these so that you can allocate memory from js if you need to
#program_export jaiAdapterRequestDeviceErrorCallback :: (
	ctx: *#Context,
	device: *WGPUDevice,
	message: *void,
	message_count: u64,
	cb: *void,
	userdata1: *void,
	userdata2: *void
) -> void #c_call {
	push_context,defer_pop ctx;
	typed_cb := cb.(WGPUUncapturedErrorCallback);
	typed_cb(
		device, .Unknown, .{ data = xx message, length = xx message_count }, userdata1, userdata2
	);
}
wasmAdapterRequestDevice :: (
	adapter: WGPUAdapter,
	descriptor: *WGPUDeviceDescriptor,
	callbackInfo: WGPURequestDeviceCallbackInfo
) -> WGPUFuture #c_call {
	jsAdapterRequestDevice :: (params: *void, returns: *void) #foreign;
	device: WGPUDevice;

	params: struct {
		adapter: WGPUAdapter;
		descriptor: *WGPUDeviceDescriptor;
	};
	params.adapter = adapter;
	params.descriptor = descriptor;
	jsAdapterRequestDevice(*params, *device);
	callbackInfo.callback(.Success, device, .{}, callbackInfo.userdata1, callbackInfo.userdata2);
	return .{};
}
wasmDeviceGetQueue :: (device: WGPUDevice) -> WGPUQueue #c_call {
	jsDeviceGetQueue :: (params: *void, returns: *void) #foreign;
	queue: WGPUQueue;
	jsDeviceGetQueue(*device, *queue);
	return queue;
}
wasmQueueRelease :: (queue: WGPUQueue) -> void #c_call {
	jsQueueRelease :: (params: *void, returns: *void) #foreign;
	jsQueueRelease(*queue, null);
}
wasmQueueSubmit :: (
	queue: WGPUQueue,
	commandCount: u64,
	commands: *WGPUCommandBuffer
) -> void #c_call {
	jsQueueSubmit :: (params: *void, returns: *void) #foreign;

	params: struct {
		queue: WGPUQueue;
		commandCount: u64;
		commands: *WGPUCommandBuffer;
	};
	params.queue = queue;
	params.commandCount = commandCount;
	params.commands = commands;

	jsQueueSubmit(*params, null);
}
wasmQueueWriteBuffer :: (
	queue: WGPUQueue,
	buffer: WGPUBuffer,
	bufferOffset: u64,
	data: *void,
	dataSize: u64
) -> void #c_call {
	jsQueueWriteBuffer :: (params: *void, returns: *void) #foreign;

	params: struct {
		queue: WGPUQueue;
		buffer: WGPUBuffer;
		bufferOffset: u64;
		data: *void;
		dataSize: u64;
	};
	params.queue = queue;
	params.buffer = buffer;
	params.bufferOffset = bufferOffset;
	params.data = data;
	params.dataSize = dataSize;

	jsQueueWriteBuffer(*params, null);
}
wasmQueueWriteTexture :: (
	queue: WGPUQueue,
	region: *WGPUTexelCopyTextureInfo,
	data: *void,
	dataSize: u64,
	dataLayout: *WGPUTexelCopyBufferLayout,
	writeSize: *WGPUExtent3D
) -> void #c_call {
	jsQueueWriteTexture :: (params: *void, returns: *void) #foreign;

	params: struct {
		queue: WGPUQueue;
		region: *WGPUTexelCopyTextureInfo;
		data: *void;
		dataSize: u64;
		dataLayout: *WGPUTexelCopyBufferLayout;
		writeSize: *WGPUExtent3D;
	};
	params.queue = queue;
	params.region = region;
	params.data = data;
	params.dataSize = dataSize;
	params.dataLayout = dataLayout;
	params.writeSize = writeSize;

	jsQueueWriteTexture(*params, null);
}
wasmDeviceCreateCommandEncoder :: (
	device: WGPUDevice,
	descriptor: *WGPUCommandEncoderDescriptor
) -> WGPUCommandEncoder #c_call {
	jsDeviceCreateCommandEncoder :: (params: *void, returns: *void) #foreign;
	encoder: WGPUCommandEncoder;

	params: struct {
		device: WGPUDevice;
		descriptor: *WGPUCommandEncoderDescriptor;
	};
	params.device = device;
	params.descriptor = descriptor;

	jsDeviceCreateCommandEncoder(*params, *encoder);
	return encoder;
}
wasmCommandEncoderFinish :: (
	encoder: WGPUCommandEncoder,
	descriptor: *WGPUCommandBufferDescriptor
) -> WGPUCommandBuffer #c_call {
	jsCommandEncoderFinish :: (params: *void, returns: *void) #foreign;
	command_buffer: WGPUCommandBuffer;

	params: struct {
		encoder: WGPUCommandEncoder;
		descriptor: *WGPUCommandBufferDescriptor;
	};
	params.encoder = encoder;
	params.descriptor = descriptor;

	jsCommandEncoderFinish(*params, *command_buffer);
	return command_buffer;
}
wasmCommandEncoderInsertDebugMarker :: (
	encoder: WGPUCommandEncoder,
	markerLabel: WGPUStringView
) -> void #c_call {
	jsCommandEncoderInsertDebugMarker :: (params: *void, returns: *void) #foreign;

	params: struct {
		encoder: WGPUCommandEncoder;
		markerLabel: *WGPUStringView;
	};
	params.encoder = encoder;
	params.markerLabel = *markerLabel;

	jsCommandEncoderInsertDebugMarker(*params, null);
}
wasmCommandBufferRelease :: (
	buffer: WGPUCommandBuffer
) -> void #c_call {
	jsCommandBufferRelease :: (params: *void, returns: *void) #foreign;
	jsCommandBufferRelease(*buffer, null);
}
wasmCommandEncoderRelease :: (
	encoder: WGPUCommandEncoder
) -> void #c_call {
	jsCommandEncoderRelease :: (params: *void, returns: *void) #foreign;
	jsCommandEncoderRelease(*encoder, null);
}
wasmDeviceCreateBuffer :: (
	device: WGPUDevice,
	descriptor: *WGPUBufferDescriptor
) -> WGPUBuffer #c_call {
	jsDeviceCreateBuffer :: (params: *void, returns: *void) #foreign;
	buffer: WGPUBuffer;

	params: struct {
		device: WGPUDevice;
		descriptor: *WGPUBufferDescriptor;
	};
	params.device = device;
	params.descriptor = descriptor;

	jsDeviceCreateBuffer(*params, *buffer);
	return buffer;
}
wasmBufferRelease :: (
	buffer: WGPUBuffer
) -> void #c_call {
	jsBufferRelease :: (params: *void, returns: *void) #foreign;
	jsBufferRelease(*buffer, null);
}
wasmBufferGetMappedRange :: (
	buffer: WGPUBuffer,
	offset: u64,
	size: u64
) -> *void #c_call {
	jsBufferGetMappedRange :: (params: *void, returns: *void) #foreign;
	result: *void;

	params: struct {
		buffer: WGPUBuffer;
		offset: u64;
		size: u64;
	};
	params.buffer = buffer;
	params.offset = offset;
	params.size = size;

	jsBufferGetMappedRange(*params, *result);
	return result;
}
wasmBufferUnmap :: (
	buffer: WGPUBuffer
) -> void #c_call {
	jsBufferUnmap :: (params: *void, returns: *void) #foreign;
	jsBufferUnmap(*buffer, null);
}
wasmInstanceCreateSurface :: (
	instance: WGPUInstance,
	descriptor: *WGPUSurfaceDescriptor
) -> WGPUSurface #c_call {
	jsInstanceCreateSurface :: (params: *void, returns: *void) #foreign;
	surface: WGPUSurface;

	params: struct {
		instance: WGPUInstance;
		descriptor: *WGPUSurfaceDescriptor;
	};
	params.instance = instance;
	params.descriptor = descriptor;

	jsInstanceCreateSurface(*params, *surface);
	return surface;
}
wasmDeviceCreateShaderModule :: (
	device: WGPUDevice,
	descriptor: *WGPUShaderModuleDescriptor
) -> WGPUShaderModule #c_call {
	jsDeviceCreateShaderModule :: (params: *void, returns: *void) #foreign;
	shader_module: WGPUShaderModule;

	params: struct {
		device: WGPUDevice;
		descriptor: *WGPUShaderModuleDescriptor;
	};
	params.device = device;
	params.descriptor = descriptor;

	jsDeviceCreateShaderModule(*params, *shader_module);
	return shader_module;
}
wasmDeviceCreateRenderPipeline :: (
	device: WGPUDevice,
	descriptor: *WGPURenderPipelineDescriptor
) -> WGPURenderPipeline #c_call {
	jsDeviceCreateRenderPipeline :: (params: *void, returns: *void) #foreign;
	render_pipeline: WGPURenderPipeline;

	params: struct {
		device: WGPUDevice;
		descriptor: *WGPURenderPipelineDescriptor;
	};
	params.device = device;
	params.descriptor = descriptor;

	jsDeviceCreateRenderPipeline(*params, *render_pipeline);
	return render_pipeline;
}
wasmCommandEncoderBeginRenderPass :: (
	encoder: WGPUCommandEncoder,
	descriptor: *WGPURenderPassDescriptor
) -> WGPURenderPassEncoder #c_call {
	jsCommandEncoderBeginRenderPass :: (params: *void, returns: *void) #foreign;
	render_pass: WGPURenderPassEncoder;

	params: struct {
		encoder: WGPUCommandEncoder;
		descriptor: *WGPURenderPassDescriptor;
	};
	params.encoder = encoder;
	params.descriptor = descriptor;

	jsCommandEncoderBeginRenderPass(*params, *render_pass);
	return render_pass;
}
wasmRenderPassEncoderSetPipeline :: (
	pass: WGPURenderPassEncoder,
	pipeline: WGPURenderPipeline
) -> void #c_call {
	jsRenderPassEncoderSetPipeline :: (params: *void, returns: *void) #foreign;

	params: struct {
		pass: WGPURenderPassEncoder;
		pipeline: WGPURenderPipeline;
	};
	params.pass = pass;
	params.pipeline = pipeline;

	jsRenderPassEncoderSetPipeline(*params, null);
}
wasmRenderPassEncoderDraw :: (
	pass: WGPURenderPassEncoder,
	vertexCount: u32,
	instanceCount: u32,
	firstVertex: u32,
	firstInstance: u32
) -> void #c_call {
	jsRenderPassEncoderDraw :: (params: *void, returns: *void) #foreign;

	params: struct {
		pass: WGPURenderPassEncoder;
		vertexCount: u32;
		instanceCount: u32;
		firstVertex: u32;
		firstInstance: u32;
	};
	params.pass = pass;
	params.vertexCount = vertexCount;
	params.instanceCount = instanceCount;
	params.firstVertex = firstVertex;
	params.firstInstance = firstInstance;

	jsRenderPassEncoderDraw(*params, null);
}
wasmRenderPassEncoderEnd :: (
	pass: WGPURenderPassEncoder
) -> void #c_call {
	jsRenderPassEncoderEnd :: (params: *void, returns: *void) #foreign;
	jsRenderPassEncoderEnd(*pass, null);
}
wasmSurfaceGetCurrentTexture :: (
	surface: WGPUSurface,
	surfaceTexture: *WGPUSurfaceTexture
) -> void #c_call {
	texture: WGPUTexture;
	jsSurfaceGetCurrentTexture :: (params: *void, returns: *void) #foreign;
	jsSurfaceGetCurrentTexture(*surface, *texture);

	surfaceTexture.texture = texture;
	surfaceTexture.status = .SuccessOptimal;
}
wasmTextureCreateView :: (
	texture: WGPUTexture,
	descriptor: *WGPUTextureViewDescriptor
) -> WGPUTextureView #c_call {
	jsTextureCreateView :: (params: *void, returns: *void) #foreign;
	texture_view: WGPUTextureView;

	params: struct {
		texture: WGPUTexture;
		descriptor: *WGPUTextureViewDescriptor;
	};
	params.texture = texture;
	params.descriptor = descriptor;

	jsTextureCreateView(*params, *texture_view);
	return texture_view;
}
wasmTextureViewRelease :: (
	view: WGPUTextureView
) -> void #c_call {
	jsTextureViewRelease :: (params: *void, returns: *void) #foreign;
	jsTextureViewRelease(*view, null);
}
wasmSurfaceConfigure :: (
	surface: WGPUSurface,
	descriptor: *WGPUSurfaceConfiguration
) -> void #c_call {
	jsSurfaceConfigure :: (params: *void, returns: *void) #foreign;

	params: struct {
		surface: WGPUSurface;
		descriptor: *WGPUSurfaceConfiguration;
	};
	params.surface = surface;
	params.descriptor = descriptor;

	jsSurfaceConfigure(*params, null);
}
wasmRenderPassEncoderRelease :: (
	pass: WGPURenderPassEncoder
) -> void #c_call {
	jsRenderPassEncoderRelease :: (params: *void, returns: *void) #foreign;
	jsRenderPassEncoderRelease(*pass, null);
}
wasmSurfacePresent :: (
	surface: WGPUSurface
) -> WGPUStatus #c_call {
	jsSurfacePresent :: (params: *void, returns: *void) #foreign;
	jsSurfacePresent(*surface, null);
	return .Success;
}
wasmTextureGetFormat :: (
	texture: WGPUTexture
) -> WGPUTextureFormat #c_call {
	jsTextureGetFormat :: (params: *void, returns: *void) #foreign;
	format: WGPUTextureFormat;
	jsTextureGetFormat(*texture, *format);
	return format;
}
wasmDeviceCreateBindGroupLayout :: (
	device: WGPUDevice,
	descriptor: *WGPUBindGroupLayoutDescriptor
) -> WGPUBindGroupLayout #c_call {
	jsDeviceCreateBindGroupLayout :: (params: *void, returns: *void) #foreign;
	bind_group_layout: WGPUBindGroupLayout;

	params: struct {
		device: WGPUDevice;
		descriptor: *WGPUBindGroupLayoutDescriptor;
	};
	params.device = device;
	params.descriptor = descriptor;

	jsDeviceCreateBindGroupLayout(*params, *bind_group_layout);
	return bind_group_layout;
}
wasmBindGroupLayoutRelease :: (
	layout: WGPUBindGroupLayout
) -> void #c_call {
	jsBindGroupLayoutRelease :: (params: *void, returns: *void) #foreign;
	jsBindGroupLayoutRelease(*layout, null);
}
wasmDeviceCreateBindGroup :: (
	device: WGPUDevice,
	descriptor: *WGPUBindGroupDescriptor
) -> WGPUBindGroup #c_call {
	jsDeviceCreateBindGroup :: (params: *void, returns: *void) #foreign;
	bind_group: WGPUBindGroup;

	params: struct {
		device: WGPUDevice;
		descriptor: *WGPUBindGroupDescriptor;
	};
	params.device = device;
	params.descriptor = descriptor;

	jsDeviceCreateBindGroup(*params, *bind_group);
	return bind_group;
}
wasmBindGroupRelease :: (
	group: WGPUBindGroup
) -> void #c_call {
	jsBindGroupRelease :: (params: *void, returns: *void) #foreign;
	jsBindGroupRelease(*group, null);
}
wasmRenderPipelineGetBindGroupLayout :: (
	pipeline: WGPURenderPipeline,
	index: u32
) -> WGPUBindGroupLayout #c_call {
	jsRenderPipelineGetBindGroupLayout :: (params: *void, returns: *void) #foreign;
	bind_group_layout: WGPUBindGroupLayout;

	params: struct {
		pipeline: WGPURenderPipeline;
		index: u32;
	};
	params.pipeline = pipeline;
	params.index = index;

	jsRenderPipelineGetBindGroupLayout(*params, *bind_group_layout);
	return bind_group_layout;
}
wasmRenderPassEncoderSetBindGroup :: (
	pass: WGPURenderPassEncoder,
	index: u32,
	bindGroup: WGPUBindGroup,
	dynamicOffsetCount: u64,
	dynamicOffsets: *u32
) -> void #c_call {
	jsRenderPassEncoderSetBindGroup :: (params: *void, returns: *void) #foreign;

	params: struct {
		pass: WGPURenderPassEncoder;
		index: u64;
		bindGroup: WGPUBindGroup;
		dynamicOffsetCount: u64;
		dynamicOffsets: *u32;
	};
	params.pass = pass;
	params.index = xx index;
	params.bindGroup = bindGroup;
	params.dynamicOffsetCount = xx dynamicOffsetCount;
	params.dynamicOffsets = dynamicOffsets;

	jsRenderPassEncoderSetBindGroup(*params, null);
}
wasmRenderPassEncoderSetVertexBuffer :: (
	pass: WGPURenderPassEncoder,
	slot: u32,
	buffer: WGPUBuffer,
	offset: u64,
	size: u64
) -> void #c_call {
	jsRenderPassEncoderSetVertexBuffer :: (params: *void, returns: *void) #foreign;
	params: struct {
		pass: WGPURenderPassEncoder;
		slot: u32;
		buffer: WGPUBuffer;
		offset: u64;
		size: u64;
	};

	params.pass = pass;
	params.slot = slot;
	params.buffer = buffer;
	params.offset = offset;
	params.size = size;
	jsRenderPassEncoderSetVertexBuffer(*params, null);
}
wasmDeviceCreateTexture :: (
	device: WGPUDevice,
	descriptor: *WGPUTextureDescriptor
) -> WGPUTexture #c_call {
	jsDeviceCreateTexture :: (params: *void, returns: *void) #foreign;
	texture: WGPUTexture;

	params: struct {
		device: WGPUDevice;
		descriptor: *WGPUTextureDescriptor;
	};
	params.device = device;
	params.descriptor = descriptor;

	jsDeviceCreateTexture(*params, *texture);
	return texture;
}
wasmDeviceCreateSampler :: (
	device: WGPUDevice,
	descriptor: *WGPUSamplerDescriptor
) -> WGPUSampler #c_call {
	jsDeviceCreateSampler :: (params: *void, returns: *void) #foreign;
	sampler: WGPUSampler;

	params: struct {
		device: WGPUDevice;
		descriptor: *WGPUSamplerDescriptor;
	};
	params.device = device;
	params.descriptor = descriptor;

	jsDeviceCreateSampler(*params, *sampler);
	return sampler;
}
wasmSamplerRelease :: (
	sampler: WGPUSampler
) -> void #c_call {
	jsSamplerRelease :: (params: *void, returns: *void) #foreign;
	jsSamplerRelease(*sampler, null);
}
wasmTextureRelease :: (
	texture: WGPUTexture
) -> void #c_call {
	jsTextureRelease :: (params: *void, returns: *void) #foreign;
	jsTextureRelease(*texture, null);
}
wasmDeviceCreatePipelineLayout :: (
	device: WGPUDevice,
	descriptor: *WGPUPipelineLayoutDescriptor
) -> WGPUPipelineLayout #c_call {
	jsDeviceCreatePipelineLayout :: (params: *void, returns: *void) #foreign;
	pipeline_layout: WGPUPipelineLayout;

	params: struct {
		device: WGPUDevice;
		descriptor: *WGPUPipelineLayoutDescriptor;
	};
	params.device = device;
	params.descriptor = descriptor;

	jsDeviceCreatePipelineLayout(*params, *pipeline_layout);
	return pipeline_layout;
}
wasmPipelineLayoutRelease :: (
	layout: WGPUPipelineLayout
) -> void #c_call {
	jsPipelineLayoutRelease :: (params: *void, returns: *void) #foreign;
	jsPipelineLayoutRelease(*layout, null);
}
wasmRenderPassEncoderSetViewport :: (
	pass: WGPURenderPassEncoder,
	x: float32,
	y: float32,
	width: float32,
	height: float32,
	minDepth: float32,
	maxDepth: float32
) -> void #c_call {
	jsRenderPassEncoderSetViewport :: (params: *void, returns: *void) #foreign;

	params: struct {
		pass: WGPURenderPassEncoder;
		x: float32;
		y: float32;
		width: float32;
		height: float32;
		minDepth: float32;
		maxDepth: float32;
	};
	params.pass = pass;
	params.x = x;
	params.y = y;
	params.width = width;
	params.height = height;
	params.minDepth = minDepth;
	params.maxDepth = maxDepth;

	jsRenderPassEncoderSetViewport(*params, null);
}
entries :: Entry.[
	.{ "createInstance", WGPUProcCreateInstance, "wasmCreateInstance" },
	.{ "myInstanceCreateSurface", WGPUProcInstanceCreateSurface, "wasmInstanceCreateSurface" },
	.{ "instanceRequestAdapter", WGPUProcInstanceRequestAdapter, "wasmInstanceRequestAdapter" },
	.{ "adapterGetLimits", WGPUProcAdapterGetLimits, "wasmAdapterGetLimits" },
	.{ "supportedFeaturesFreeMembers", WGPUProcSupportedFeaturesFreeMembers, "wasmSupportedFeaturesFreeMembers" },
	.{ "adapterGetFeatures", WGPUProcAdapterGetFeatures, "wasmAdapterGetFeatures" },
	.{ "adapterRelease", WGPUProcAdapterRelease, "wasmAdapterRelease" },
	.{ "adapterRequestDevice", WGPUProcAdapterRequestDevice, "wasmAdapterRequestDevice" },
	.{ "deviceGetQueue", WGPUProcDeviceGetQueue, "wasmDeviceGetQueue" },
	.{ "queueRelease", WGPUProcQueueRelease, "wasmQueueRelease" },
	.{ "queueSubmit", WGPUProcQueueSubmit, "wasmQueueSubmit" },
	.{ "queueWriteBuffer", WGPUProcQueueWriteBuffer, "wasmQueueWriteBuffer" },
	.{ "queueWriteTexture", WGPUProcQueueWriteTexture, "wasmQueueWriteTexture" },
	.{ "deviceCreateCommandEncoder", WGPUProcDeviceCreateCommandEncoder, "wasmDeviceCreateCommandEncoder" },
	.{ "commandEncoderFinish", WGPUProcCommandEncoderFinish, "wasmCommandEncoderFinish" },
	.{ "commandEncoderInsertDebugMarker", WGPUProcCommandEncoderInsertDebugMarker, "wasmCommandEncoderInsertDebugMarker" },
	.{ "commandBufferRelease", WGPUProcCommandBufferRelease, "wasmCommandBufferRelease" },
	.{ "commandEncoderRelease", WGPUProcCommandEncoderRelease, "wasmCommandEncoderRelease" },
	.{ "deviceCreateBuffer", WGPUProcDeviceCreateBuffer, "wasmDeviceCreateBuffer" },
	.{ "bufferRelease", WGPUProcBufferRelease, "wasmBufferRelease" },
	.{ "bufferGetMappedRange", WGPUProcBufferGetMappedRange, "wasmBufferGetMappedRange" },
	.{ "bufferUnmap", WGPUProcBufferUnmap, "wasmBufferUnmap" },
	.{ "deviceCreateShaderModule", WGPUProcDeviceCreateShaderModule, "wasmDeviceCreateShaderModule" },
	.{ "deviceCreateRenderPipeline", WGPUProcDeviceCreateRenderPipeline, "wasmDeviceCreateRenderPipeline" },
	.{ "commandEncoderBeginRenderPass", WGPUProcCommandEncoderBeginRenderPass, "wasmCommandEncoderBeginRenderPass" },
	.{ "renderPassEncoderSetPipeline", WGPUProcRenderPassEncoderSetPipeline, "wasmRenderPassEncoderSetPipeline" },
	.{ "renderPassEncoderDraw", WGPUProcRenderPassEncoderDraw, "wasmRenderPassEncoderDraw" },
	.{ "renderPassEncoderEnd", WGPUProcRenderPassEncoderEnd, "wasmRenderPassEncoderEnd" },
	.{ "surfaceGetCurrentTexture", WGPUProcSurfaceGetCurrentTexture, "wasmSurfaceGetCurrentTexture" },
	.{ "textureCreateView", WGPUProcTextureCreateView, "wasmTextureCreateView" },
	.{ "renderPassEncoderEnd", WGPUProcRenderPassEncoderEnd, "wasmRenderPassEncoderEnd" },
	.{ "textureViewRelease", WGPUProcTextureViewRelease, "wasmTextureViewRelease" },
	.{ "surfaceConfigure", WGPUProcSurfaceConfigure, "wasmSurfaceConfigure" },
	.{ "renderPassEncoderRelease", WGPUProcRenderPassEncoderRelease, "wasmRenderPassEncoderRelease" },
	.{ "surfacePresent", WGPUProcSurfacePresent, "wasmSurfacePresent" },
	.{ "textureGetFormat", WGPUProcTextureGetFormat, "wasmTextureGetFormat" },
	.{ "deviceCreateBindGroupLayout", WGPUProcDeviceCreateBindGroupLayout, "wasmDeviceCreateBindGroupLayout" },
	.{ "bindGroupLayoutRelease", WGPUProcBindGroupLayoutRelease, "wasmBindGroupLayoutRelease" },
	.{ "deviceCreateBindGroup", WGPUProcDeviceCreateBindGroup, "wasmDeviceCreateBindGroup" },
	.{ "bindGroupRelease", WGPUProcBindGroupRelease, "wasmBindGroupRelease" },
	.{ "renderPipelineGetBindGroupLayout", WGPUProcRenderPipelineGetBindGroupLayout, "wasmRenderPipelineGetBindGroupLayout" },
	.{ "renderPassEncoderSetBindGroup", WGPUProcRenderPassEncoderSetBindGroup, "wasmRenderPassEncoderSetBindGroup" },
	.{ "renderPassEncoderSetVertexBuffer", WGPUProcRenderPassEncoderSetVertexBuffer, "wasmRenderPassEncoderSetVertexBuffer" },
	.{ "deviceCreateTexture", WGPUProcDeviceCreateTexture, "wasmDeviceCreateTexture" },
	.{ "deviceCreateSampler", WGPUProcDeviceCreateSampler, "wasmDeviceCreateSampler" },
	.{ "samplerRelease", WGPUProcSamplerRelease, "wasmSamplerRelease" },
	.{ "textureRelease", WGPUProcTextureRelease, "wasmTextureRelease" },
	.{ "deviceCreatePipelineLayout", WGPUProcDeviceCreatePipelineLayout, "wasmDeviceCreatePipelineLayout" },
	.{ "pipelineLayoutRelease", WGPUProcPipelineLayoutRelease, "wasmPipelineLayoutRelease" },
	.{ "renderPassEncoderSetViewport", WGPUProcRenderPassEncoderSetViewport, "wasmRenderPassEncoderSetViewport" }
];


