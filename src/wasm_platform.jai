#scope_file
#import "Window_Creation";
#import "WAllocator";
#import "Input";
#import "Basic";
#import "String";
#import "Hash_Table";
Render :: #import "Render";
Sound :: #import "Sound_Player";
WebGL :: #import "Toolchains/Web/WebGL";

window: Window_Type;
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

	update_window_events();

	for events_this_frame {
		if it.type == {
			case .KEYBOARD;
				mapped := map_key_to_key(xx it.key_code);
				if mapped >= 0 {
					pressed[mapped] = it.key_pressed > 0;
				}
			case .QUIT;
				info.quit = true;
			case .MOUSE_WHEEL;
				info.mouse_wheel = it.wheel_delta;
		}
	}

	x, y := get_mouse_pointer_position(window, false);
	info.mouse_position.x = xx x;
	info.mouse_position.y = xx y;

	wx, wy, ww, wh := get_dimensions(window, false);
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

wasm_end_frame ::  () {
	js_webgl_swap_buffers :: (window: Window_Type, vsync: bool) #foreign;
	js_webgl_swap_buffers(window, false);
	Sound.update();
}

init_platform :: () -> Platform {

	window := create_window(1366, 768, "Ice Escape");
	for * pressed
		it.* = false;
	js_webgl_swap_buffers :: (window: Window_Type, vsync: bool) #foreign;
	js_webgl_swap_buffers(window, false);

	Sound.sound_player_init(.{ audible_when_window_is_not_in_focus = true });
	web_buffer = NewArray(1024*1024*32, u8, false);

	platform: Platform;

	platform.get_frame_info = wasm_get_frame_info;
	platform.end_frame = wasm_end_frame;
	platform.send_web_message = send_web_message;
	platform.get_token = get_token;
	platform.set_token = set_token;
	platform.query_audio = query_audio;
	platform.load_audio = load_audio;
	platform.play_audio = play_audio;
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
	#insert #run meta_run();
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
	jsInstanceCreateSurface(*instance, *surface);
	return surface;
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
	.{ "bufferUnmap", WGPUProcBufferUnmap, "wasmBufferUnmap" }
];


