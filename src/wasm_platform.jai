#import "Window_Creation";
#import "Input";
#import "String";
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
	}
	return -1;
}
#scope_export

send_web_message :: (msg: [] u8) {
	js_send_web_message :: (data: *void, count: int) #foreign;
	js_send_web_message(msg.data, msg.count);
}

wasm_get_frame_info :: () -> Frame_Info {

	info: Frame_Info;
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

	for * info.key_pressed {
		it.* = pressed[it_index];
	}

	js_get_web_message_received :: (data: *void, count: int, recv: *void) #foreign;
	{
		recv := 0;
		js_get_web_message_received(web_buffer.data, web_buffer.count, *recv);

		cursor := 0;
		while cursor < (xx recv) && info.message_received_count < info.message_received.count {
			next_message_length := (cast(*u64)(web_buffer.data + cursor)).*;

			msg: Web_Message;
			msg.data = web_buffer.data + cursor + 8;
			msg.count = xx next_message_length;
			info.message_received[info.message_received_count] = msg;
			info.message_received_count += 1;

			cursor += 8;
			cursor += xx next_message_length;
		}
	}

	return info;
}

wasm_end_frame ::  () {
	js_webgl_swap_buffers :: (window: Window_Type, vsync: bool) #foreign;
	js_webgl_swap_buffers(window, true);
}

init_platform :: () -> Platform {
	window := create_window(1366, 768, "Ice Escape");
	for * pressed
		it.* = false;

	web_buffer = NewArray(1024*1024*32, u8, false);

	platform: Platform;

	platform.get_frame_info = wasm_get_frame_info;
	platform.end_frame = wasm_end_frame;
	platform.send_web_message = send_web_message;

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