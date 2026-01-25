#scope_file
#import "Platform";
#import "Basic";
#import "String";
#import "Algebra";
#import "Hash_Table";

pressed: [Key_COUNT] bool;

web_buffer: [] u8;
controls_buffer: [] u8;
last_frame: Apollo_Time;
last_frame_init := false;
#scope_export

send_web_message :: (msg: [] u8, target: Connection) {
	js_send_web_message :: (data: *void, count: int) #foreign;
	js_send_web_message(msg.data, msg.count);
}

send_web_message :: (msg_pool: [] u8, msg_indices: [] int, target: Connection) {
	js_send_web_messages :: (
		data: *void, count: int, data_indices: *void, count_indices: int
	) #foreign;
	js_send_web_messages(msg_pool.data, msg_pool.count, msg_indices.data, msg_indices.count);
}

wasm_read_entire_file :: (path: string, data: [] u8) -> int {
	print("Don't read files in wasm you fool!\n");
	return 0;
}

wasm_get_current_time :: () -> Apollo_Time {
	js_get_current_time_monotonic :: (low_ptr: *u64, high_ptr: *u64) #foreign;
	now: Apollo_Time;
	js_get_current_time_monotonic((*now).(*u64), (*now).(*u64) + 1);
	return now;
}

wasm_sleep :: (ms: int) {
	js_sleep :: (ms: int) #foreign;
	js_sleep(ms);
}

wasm_get_frame_info :: (info: *Frame_Info) {
	info.* = .{};

	now: Apollo_Time;
	js_get_current_time_monotonic :: (low_ptr: *u64, high_ptr: *u64) #foreign;
	js_get_current_time_monotonic((*now).(*u64), (*now).(*u64) + 1);

	info.delta_time = 1.0 / 60.0;
	if last_frame_init {
		info.delta_time = xx to_float64_seconds(
			now - last_frame
		);
	}
	last_frame = now;
	last_frame_init = true;
	info.time = now;
	info.framebuffer_size = .{ xx 1366, xx 768 };
	info.quit = false;
	info.window_focused = true;
	info.window_size = .{ xx 1366, xx 768 };
	info.layout = .Unknown;

	Mouse_X :: 128;
	Mouse_Y :: 132;
	Mouse_Wheel :: 136;
	Window_W :: 140;
	Window_H :: 144;
	info.mouse_position.x = xx (controls_buffer.data + Mouse_X).(*u32).*;
	info.mouse_position.y = xx (controls_buffer.data + Mouse_Y).(*u32).*;
	info.mouse_wheel = xx (controls_buffer.data + Mouse_Wheel).(*float32).*;

	dim: [4] u32;
	ww := dim[2];
	wh := dim[3];
	info.framebuffer_size = .{
		xx (controls_buffer.data + Window_W).(*u32).*, xx (controls_buffer.data + Window_H).(*u32).*
	};
	info.window_size = .{
		xx (controls_buffer.data + Window_W).(*u32).*, xx (controls_buffer.data + Window_H).(*u32).*
	};
	info.mouse_position.y = info.window_size.y - info.mouse_position.y;
	for 0..Key_COUNT-1 {
		info.key_pressed[it] = controls_buffer.data[it] > 0;
	}

	frame_buffer_count: u64 = 0;
	js_get_web_message_received_buffer_count :: (count_ptr: *u64) #foreign;
	js_get_web_message_received_buffer_count(*frame_buffer_count);

	js_get_web_message_received :: (data: *void, count: int, recv: *void) #foreign;
	{
		web_buffer_count := min(web_buffer.count.(u64), frame_buffer_count);
		recv := 0;
		if web_buffer_count > 0
			js_get_web_message_received(web_buffer.data, web_buffer_count.(int), *recv);

		n := 0;
		cursor := 0;
		while cursor < (xx recv) && info.message_received_count < info.message_received.count {
			next_message_length := (cast(*u64)(web_buffer.data + cursor)).*;

			msg: Web_Message;
			msg.data.data = web_buffer.data + cursor;
			msg.data.count = xx next_message_length;
			info.message_received[info.message_received_count] = msg;
			info.message_received_count += 1;

			cursor += xx next_message_length;
			n += 1;
		}
	}
}

// audio_table: Table(int, *Sound.Sound_Data);
// audio_counter := 0;

load_audio :: (data: string, compressed: bool, out: *Audio) -> Platform.extern_ref {
	print("Loading audio in wasm is not supported yet!\n");
	// Params :: struct {
	// 	data: *u8;
	// 	count: s64;
	// 	id: *s64;
	// 	compressed: u64;
	// }
	// js_load_audio :: (params: *Params) -> Platform.extern_ref #foreign;
	// params: Params;
	// params.data = cast(*u8) data.data;
	// params.count = xx data.count;
	// params.compressed = xx compressed;
	// params.id = *out.id;

	// return js_load_audio(*params);
}

wasm_wait :: (promise: Platform.extern_ref) {
	js_wait :: (promise: Platform.extern_ref) #foreign;
	js_wait(promise);
}

play_audio :: (audio: Audio, position: V3f) -> Sound {
	return .{};
	// Params :: struct {
	// 	id: s64;
	// 	x: float32;
	// 	y: float32;
	// 	z: float32;
	// 	volume: float32;
	// 	pitch: float32;
	// 	repeating: u32;
	// 	kind: s32;
	// 	fade_in: s32;
	// 	exponent: float32;

	// 	sound_id: *s64;

	// 	delay: float32;
	// }

	// js_play_audio :: (params: *Params) #foreign;
	// sound: Sound;
	// params: Params;
	// params.id = xx audio.id;
	// params.x = xx position.x;
	// params.y = xx position.y;
	// params.z = xx position.z;
	// params.volume = xx audio.volume;
	// params.pitch = xx audio.pitch;
	// params.repeating = xx audio.repeating;
	// params.kind = xx audio.kind;
	// params.fade_in = xx audio.fade_in;
	// params.sound_id = *sound.id;
	// params.exponent = xx audio.exponent;
	// params.delay = xx audio.delay;
	// js_play_audio(*params);

	// sound.audio_id = audio.id;
	// sound.playing = true;
	// sound.position = position;
	// sound.loop = audio.repeating || audio.kind == .Music;
	// return sound;
}
query_sound :: (sound_id: int) -> Sound {
	return .{};
	// Params :: struct {
	// 	sound_id: s64;
	// 	id: *s64;
	// 	x: *float32;
	// 	y: *float32;
	// 	z: *float32;
	// 	volume: *float32;
	// 	pitch: *float32;
	// 	playing: *u32;
	// 	looping: *u32;
	// }
	// js_query_sound :: (params: *Params) #foreign;
	// params: Params;
	// sound: Sound;
	// params.sound_id = xx sound_id;
	// params.id = *sound.id;
	// params.x = *sound.position.x;
	// params.y = *sound.position.y;
	// params.z = *sound.position.z;
	// params.volume = *sound.volume;
	// params.pitch = *sound.pitch;
	// u32_looping : u32 = 0;
	// params.looping = *u32_looping;
	// u32_playing : u32 = 0;
	// params.playing = *u32_playing;
	// js_query_sound(*params);
	// sound.playing = u32_playing != 0;
	// sound.loop = u32_looping != 0;
	// return sound;
}
set_sound :: (sound: Sound) {
	return;
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
	return;
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

wasm_load_image :: (data: [] u8) -> Image {
	image: Image;

	return image;
}

wasm_free_image :: (image: *Image) {
}

wasm_connect_server :: (address: string, port: int, protocol: string) -> Connection, bool {
	js_connect_server :: (
		protocol: *void, protocol_count: int, addr: *void, addr_count: int, port: s32, success: *s32
	) #foreign;
	success: s32;
	js_connect_server(
		protocol.data, xx protocol.count, address.data, xx address.count, xx port, *success
	);
	return 0, true;
}

wasm_is_server_connected :: () -> bool {
	js_is_server_connected :: (success: *s32) #foreign;
	connected: s32;
	js_is_server_connected(*connected);
	return connected != 0;
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

	platform.connect_server = wasm_connect_server;
	platform.is_server_connected = wasm_is_server_connected;
	platform.read_entire_file = wasm_read_entire_file;
	platform.load_image = wasm_load_image;
	platform.free_image = wasm_free_image;
	platform.get_frame_info = wasm_get_frame_info;
	platform.get_current_time = wasm_get_current_time;
	platform.end_frame = wasm_end_frame;
	platform.sleep = wasm_sleep;
	platform.send_web_message = send_web_message;
	platform.get_token = get_token;
	platform.set_token = set_token;
	platform.load_audio = load_audio;
	platform.wait = wasm_wait;
	platform.play_audio = play_audio;
	platform.query_sound = query_sound;
	platform.set_sound = set_sound;
	platform.set_listener_info = set_listener_info;
	platform.volume_audio = (x: float) -> float {
		X := x;
		js_volume_audio :: (volume: *float) #foreign;
		// Clamp the volume between 0.0 and 1.0
		if X < 0.0 {
			X = 0.0;
		} else if X > 1.0 {
			X = 1.0;
		}

		js_volume_audio(*X);
		return X;
	};


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


// Main

#import "main_game";

app: App;
platform: Platform;

main_thread_wasm_context: #Context;
main_thread_temporary_storage: Temporary_Storage;
main_thread_temporary_storage_data: [TEMPORARY_STORAGE_SIZE] u8 #align 64;

update_thread_wasm_context: #Context;
update_thread_temporary_storage: Temporary_Storage;
update_thread_temporary_storage_data: [TEMPORARY_STORAGE_SIZE] u8 #align 64;

#program_export "wasm_get_main_context" wasm_get_context :: () -> *#Context #c_call {
	return *main_thread_wasm_context;
}
#program_export "wasm_get_update_context" wasm_get_update_context :: () -> *#Context #c_call {
	return *update_thread_wasm_context;
}

#program_export "wasm_get_controls_buffer" wasm_get_controls_buffer :: () -> u64 #c_call {
	return controls_buffer.data.(u64);
}

#program_export "wasm_init_buffers" wasm_init_buffers :: () #c_call {
	main_thread_temporary_storage.data          = main_thread_temporary_storage_data.data;
	main_thread_temporary_storage.original_data = main_thread_temporary_storage_data.data;
	main_thread_temporary_storage.size          = main_thread_temporary_storage_data.count;
	main_thread_temporary_storage.original_size = main_thread_temporary_storage_data.count;
	main_thread_wasm_context.temporary_storage  = *main_thread_temporary_storage;

	update_thread_temporary_storage.data          = update_thread_temporary_storage_data.data;
	update_thread_temporary_storage.original_data = update_thread_temporary_storage_data.data;
	update_thread_temporary_storage.size          = update_thread_temporary_storage_data.count;
	update_thread_temporary_storage.original_size = update_thread_temporary_storage_data.count;
	update_thread_wasm_context.temporary_storage  = *update_thread_temporary_storage;

	push_context, defer_pop main_thread_wasm_context;
	context.allocator.proc(.STARTUP, 0, 0, null, null);
	app.allocator = context.allocator;
	app.user_data = null;

	controls_buffer = NewArray(1024 * 4, u8);
}
#program_export "wasm_init" wasm_init :: () #c_call {
	push_context, defer_pop main_thread_wasm_context;

	platform = init_platform();
	app.platform = *platform;

	app_init(*app);
}

#program_export "wasm_main_loop" wasm_main_loop :: () #c_call {
	push_context, defer_pop main_thread_wasm_context;
	app_loop(*app);
}



#program_export "wasm_worker_loop" wasm_worker_loop :: () #c_call {
	jsDontOptimize :: (params: [] u8) #foreign;
	offset_stack: [8*1024*1024] u8 = ---;
	jsDontOptimize(offset_stack);
	push_context, defer_pop update_thread_wasm_context;
	app_update_loop(*app);
}

// main :: () {

// 	while (app_loop(*app)) {
// 		// Main loop
// 	}

// 	app_quit(*app);
// 	exit_platform(platform);
// }
// We expose malloc to just use the default allocator with a fresh context so that our c code 
// has a usable malloc/realloc/free it can use whenever it wants and you can't accidentaly
// malloc something with temporary storage as that's not something you can do on other platforms (yet?)
ptr_to_size: Table(*void, s64);

#program_export "malloc"
jai_default_alloc :: (size: s64) -> *void #c_call {
    push_context,defer_pop;
    Basic :: #import "Basic";
    ret := Basic.alloc(size,, context.default_allocator);;
	table_set(*ptr_to_size, ret, size);
	return ret;
}

#program_export "realloc"
jai_default_realloc :: (old_memory: *void, new_size: s64) -> *void #c_call {
    push_context,defer_pop;
    Basic :: #import "Basic";

	ok, old_size := table_find(*ptr_to_size, old_memory);
	if !ok
		old_size = 0;

	ret := Basic.realloc(old_memory, new_size, old_size,, context.default_allocator);

	memcpy(ret, old_memory, min(old_size, new_size));
	table_set(*ptr_to_size, ret, new_size);
	return ret;
}

#program_export "free"
jai_default_free :: (memory: *void) #c_call {
    push_context,defer_pop;
    Basic :: #import "Basic";
    Basic.free(memory,, context.default_allocator);
	table_remove(*ptr_to_size, memory);
}


// we expose these so that you can allocate memory from js if you need to
#program_export context_alloc :: (ctx: *#Context, size: s64) -> *void #c_call {
	push_context, defer_pop ctx.*;
    Basic :: #import "Basic";
    ptr := Basic.alloc(size);
	print("allocated % bytes at %\n", size, ptr);
	return ptr;
}

#program_export context_free :: (ctx: *#Context, memory: *void) #c_call {
	push_context, defer_pop ctx.*;
    Basic :: #import "Basic";
    Basic.free(memory);
}

