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

// wgpu_functions :: string.[
// 	"WGPUProcInstanceRequestAdapter"
// ];

// #run {
// 	WGPU_Function_Entry :: struct {
// 		name: string;
// 		info: *Type_Info_Procedure;
// 	}

// 	#insert #run -> string {
// 		sb: String_Builder;
// 		print_to_builder(
// 			*sb, "wgpu_functions_types := NewArray(%, WGPU_Function_Entry);\n", wgpu_functions.count
// 		);
// 		for wgpu_functions {
// 			print_to_builder(*sb, "wgpu_functions_types[%].name = \"%\";\n", it_index, it);
// 			// print_to_builder(*sb, "wgpu_functions_types[%].type = %;\n", it_index, it);
// 			print_to_builder(*sb, "wgpu_functions_types[%].info = type_info(%);\n", it_index, it);
// 		}
// 		return builder_to_string(*sb);
// 	};

// 	sb: String_Builder;
// 	for wgpu_functions_types {
// 		type_proc_name := copy_string(it.name);
// 		type_proc_name.data += 8;
// 		type_proc_name.count -= 8;
// 		type_proc_name[0] = to_lower(type_proc_name[0]);

// 		print_to_builder(*sb, "% :: % {\n", type_proc_name, header_proc(it.info));
// 		print_to_builder(*sb, "    ")
// 	}

// 	str := builder_to_string(*sb);
// 	print(str);
// }

// #insert #run -> string {
// 	sb: String_Builder;
// 	for wgpu_functions {
// 		print_to_builder(*sb, "type_info(%)\n", it);
// 	}
// 	return builder_to_string(*sb);
// };


