Platform :: #import "Platform";
#import "Basic";
#import "String";
#import "Algebra";

#scope_export

CONTROL_FIXED_DT :: 1.0 / 60.0;
CAPTURE_WIDTH :: 1366;
CAPTURE_HEIGHT :: 768;

Control_Kind :: enum {
	Key;
	Mouse;
	Mouse_Delta;
	Wheel;
	Pause;
	Resume;
	Step;
	Wait;
	Status;
	Quit;
	Capture_Once;
	Capture_Start;
	Capture_Stop;
	Layout;
}

Control_Command :: struct {
	kind: Control_Kind;
	key: Platform.Key;
	key_down: bool;
	x: s32;
	y: s32;
	count: s32;
	layout: Platform.Layout;
}

Control_Line :: struct {
	is_frame: bool;
	first: s32;
	count: s32;
}

State :: struct {
	paused := false;
	step_frames: u32;
	wait_frames: u32;
	quit_requested := false;
	capture_enabled := false;
	capture_requested := false;
	wait_for_capture := false;
	capture_serial: u64;
	last_capture_serial: u64;
	frame_index: u64;

	key_down: [Platform.Key_COUNT] bool;
	has_mouse := false;
	mouse_x: s32;
	mouse_y: s32;
	wheel: s32;
	layout_override := Platform.Layout.Unknown;

	commands: [..] Control_Command;
	queue: [..] Control_Line;
	queue_head := 0;
	batch_active := false;
	response: [..] u8;
	pending_capture_reply := false;
}

key_from_name :: (name: string) -> Platform.Key, bool {
	n := trim(name);
	for enum_names(Platform.Key) {
		if equal_nocase(n, it) return cast(Platform.Key) it_index, true;
	}
	return .A, false;
}

key_to_name :: (key: Platform.Key) -> string {
	i := key.(int);
	names := enum_names(Platform.Key);
	if i < 0 || i >= names.count return "unknown";
	return names[i];
}

is_session_kind :: (kind: Control_Kind) -> bool {
	if #complete kind == {
		case .Key; return false;
		case .Mouse; return false;
		case .Mouse_Delta; return false;
		case .Wheel; return false;
		case .Pause; #through;
		case .Resume; #through;
		case .Step; #through;
		case .Wait; #through;
		case .Status; #through;
		case .Quit; #through;
		case .Capture_Once; #through;
		case .Capture_Start; #through;
		case .Capture_Stop; #through;
		case .Layout; return true;
		case; return true;
	}
}

control_line_commands :: (state: *State, line: Control_Line) -> [] Control_Command {
	if line.count <= 0 return .{};
	return .{ data = state.commands.data + line.first, count = line.count };
}

parse_text :: (text: string, state: *State) -> bool {
	remaining := trim_right(text, "\r\n");
	for split(remaining, #char "\n") {
		if !parse_line(it, state) return false;
	}
	return true;
}

parse_line :: (line: string, state: *State) -> bool {
	found, code, _ := split_from_left(line, #char "#");
	stripped := trim(ifx found then code else line);
	parsed: Control_Line;
	parsed.first = xx state.commands.count;
	if stripped.count == 0 {
		parsed.is_frame = true;
		array_add(*state.queue, parsed);
		return true;
	}

	saw_session := false;
	saw_input := false;
	for split(stripped, #char ";") {
		cmd_text := trim(it);
		if cmd_text.count == 0 continue;
		cmd, ok := parse_command(cmd_text);
		if !ok return false;
		session := is_session_kind(cmd.kind);
		if session saw_session = true;
		else saw_input = true;
		array_add(*state.commands, cmd);
	}
	if saw_session && saw_input return false;
	parsed.count = xx (state.commands.count - parsed.first);
	parsed.is_frame = !saw_session;
	array_add(*state.queue, parsed);
	return true;
}

parse_command :: (text: string) -> Control_Command, bool {
	cmd: Control_Command;
	t := control_normalize(text);
	found, verb, rest := split_from_left(t, #char " ");
	if !found {
		if scan2(t, "pause") {
			cmd.kind = .Pause;
			return cmd, true;
		}
		if scan2(t, "resume") {
			cmd.kind = .Resume;
			return cmd, true;
		}
		if scan2(t, "status") {
			cmd.kind = .Status;
			return cmd, true;
		}
		if scan2(t, "quit") {
			cmd.kind = .Quit;
			return cmd, true;
		}
		if scan2(t, "step") {
			cmd.kind = .Step;
			cmd.count = 1;
			return cmd, true;
		}
		if scan2(t, "wait") {
			cmd.kind = .Wait;
			cmd.count = 1;
			return cmd, true;
		}
		return cmd, false;
	}

	n: s32;
	if scan2(verb, "step") {
		if !scan2(rest, "%", *n) || n < 1 return cmd, false;
		cmd.kind = .Step;
		cmd.count = n;
		return cmd, true;
	}
	if scan2(verb, "wait") {
		if !scan2(rest, "%", *n) || n < 1 return cmd, false;
		cmd.kind = .Wait;
		cmd.count = n;
		return cmd, true;
	}
	if scan2(verb, "wheel") {
		if !scan2(rest, "%", *n) return cmd, false;
		cmd.kind = .Wheel;
		cmd.count = n;
		return cmd, true;
	}

	capture: Capture_Token;
	if scan2(verb, "capture") {
		if !scan2(rest, "%", *capture) return cmd, false;
		if #complete capture == {
			case .once; cmd.kind = .Capture_Once;
			case .start; cmd.kind = .Capture_Start;
			case .stop; cmd.kind = .Capture_Stop;
			case; return cmd, false;
		}
		return cmd, true;
	}

	layout: Layout_Token;
	if scan2(verb, "layout") {
		if !scan2(rest, "%", *layout) return cmd, false;
		cmd.kind = .Layout;
		if #complete layout == {
			case .azerty; cmd.layout = .AZERTY;
			case .qwerty; cmd.layout = .QWERTY;
			case; return cmd, false;
		}
		return cmd, true;
	}

	x: s32;
	y: s32;
	if scan2(verb, "mouse_delta") {
		if !scan2(rest, "% %", *x, *y) return cmd, false;
		cmd.kind = .Mouse_Delta;
		cmd.x = x;
		cmd.y = y;
		return cmd, true;
	}
	if scan2(verb, "mouse_button") {
		button: Mouse_Button_Token;
		action: Key_Action;
		if !scan2(rest, "% %", *button, *action) return cmd, false;
		cmd.kind = .Key;
		if #complete button == {
			case .left; cmd.key = .MouseLeft;
			case .right; cmd.key = .MouseRight;
			case .middle; cmd.key = .MouseMiddle;
			case; return cmd, false;
		}
		if #complete action == {
			case .down; cmd.key_down = true;
			case .up; cmd.key_down = false;
			case; return cmd, false;
		}
		return cmd, true;
	}
	if scan2(verb, "mouse") {
		if !scan2(rest, "% %", *x, *y) return cmd, false;
		cmd.kind = .Mouse;
		cmd.x = x;
		cmd.y = y;
		return cmd, true;
	}
	if scan2(verb, "key") {
		found_action, key_name, action_text := split_from_left(rest, #char " ");
		if !found_action return cmd, false;
		key, ok := key_from_name(key_name);
		if !ok return cmd, false;
		action: Key_Action;
		if !scan2(action_text, "%", *action) return cmd, false;
		cmd.kind = .Key;
		cmd.key = key;
		if #complete action == {
			case .down; cmd.key_down = true;
			case .up; cmd.key_down = false;
			case; return cmd, false;
		}
		return cmd, true;
	}
	return cmd, false;
}

apply_input_command :: (state: *State, cmd: Control_Command) {
	if #complete cmd.kind == {
		case .Key;
			index := cmd.key.(int);
			if index >= 0 && index < state.key_down.count {
				state.key_down[index] = cmd.key_down;
			}
		case .Mouse;
			state.mouse_x = cmd.x;
			state.mouse_y = cmd.y;
			state.has_mouse = true;
		case .Mouse_Delta;
			state.mouse_x += cmd.x;
			state.mouse_y += cmd.y;
			state.has_mouse = true;
		case .Wheel;
			state.wheel += cmd.count;
		case .Pause;
		case .Resume;
		case .Step;
		case .Wait;
		case .Status;
		case .Quit;
		case .Capture_Once;
		case .Capture_Start;
		case .Capture_Stop;
		case .Layout;
		case;
	}
}

append_response :: (state: *State, text: string) {
	old := state.response.count;
	array_resize(*state.response, old + text.count);
	memcpy(state.response.data + old, text.data, text.count);
}

apply_session_command :: (state: *State, cmd: Control_Command) {
	if #complete cmd.kind == {
		case .Key;
		case .Mouse;
		case .Mouse_Delta;
		case .Wheel;
		case .Pause;
			state.paused = true;
			append_response(state, "ok paused\n");
		case .Resume;
			state.paused = false;
			state.step_frames = 0;
			append_response(state, "ok resumed\n");
		case .Step;
			state.paused = true;
			state.step_frames += xx cmd.count;
			append_response(state, tprint("ok step_frames=%\n", state.step_frames));
		case .Wait;
			n := cmd.count;
			if n < 1 n = 1;
			state.wait_frames += xx n;
			if state.paused {
				state.step_frames += xx n;
			}
			append_response(state, tprint("ok wait=%\n", n));
		case .Status;
			append_response(state, tprint(
				"ok paused=% step_frames=% wait_frames=% frame=% mouse=% % capture_serial=%\n",
				state.paused,
				state.step_frames,
				state.wait_frames,
				state.frame_index,
				state.mouse_x,
				state.mouse_y,
				state.last_capture_serial
			));
		case .Quit;
			state.quit_requested = true;
			append_response(state, "ok quit\n");
		case .Capture_Once;
			state.capture_serial += 1;
			state.capture_requested = true;
			state.wait_for_capture = true;
			state.pending_capture_reply = true;
			if state.paused && state.step_frames == 0 {
				state.step_frames = 1;
			}
		case .Capture_Start;
			state.capture_enabled = true;
			append_response(state, "ok capture_enabled=true\n");
		case .Capture_Stop;
			state.capture_enabled = false;
			append_response(state, "ok capture_enabled=false\n");
		case .Layout;
			state.layout_override = cmd.layout;
			append_response(state, "ok layout\n");
		case;
	}
}

enqueue_text :: (state: *State, text: string) -> bool {
	line_before := state.queue.count;
	cmd_before := state.commands.count;
	ok := parse_text(text, state);
	state.batch_active = true;
	if !ok {
		state.queue.count = line_before;
		state.commands.count = cmd_before;
		append_response(state, "error parse\n");
		return false;
	}
	if state.paused {
		for i: line_before..state.queue.count-1 {
			if state.queue[i].is_frame {
				state.step_frames += 1;
			}
		}
	}
	return true;
}

control_queue_count :: (state: State) -> int {
	return state.queue.count - state.queue_head;
}

control_queue_head :: (state: *State) -> *Control_Line {
	return *state.queue[state.queue_head];
}

control_pop_head :: (state: *State) {
	state.queue_head += 1;
	if state.queue_head == state.queue.count {
		state.queue.count = 0;
		state.queue_head = 0;
		state.commands.count = 0;
	}
}

process_ready_lines :: (state: *State) {
	while control_queue_count(state.*) > 0 {
		line := control_queue_head(state);
		if line.is_frame return;
		if state.wait_frames > 0 return;
		if state.wait_for_capture return;
		for control_line_commands(state, line.*) apply_session_command(state, it);
		control_pop_head(state);
	}
}

consume_frame_line :: (state: *State) {
	state.wheel = 0;
	if control_queue_count(state.*) > 0 && control_queue_head(state).is_frame {
		for control_line_commands(state, control_queue_head(state).*) apply_input_command(state, it);
		control_pop_head(state);
	}
}

should_tick :: (state: State) -> bool {
	if !state.paused return true;
	return state.step_frames > 0;
}

begin_tick :: (state: *State) {
	if state.capture_enabled && !state.capture_requested {
		state.capture_serial += 1;
		state.capture_requested = true;
	}
}

end_tick :: (state: *State, capture_wrote: bool) {
	state.frame_index += 1;
	if state.paused && state.step_frames > 0 {
		state.step_frames -= 1;
	}
	if state.wait_frames > 0 {
		state.wait_frames -= 1;
	}
	if state.pending_capture_reply {
		if capture_wrote {
			state.last_capture_serial = state.capture_serial;
			append_response(state, tprint(
				"ok capture path=captures/frame_%.png width=% height=% serial=%\n",
				state.capture_serial,
				CAPTURE_WIDTH,
				CAPTURE_HEIGHT,
				state.capture_serial
			));
		} else {
			append_response(state, "error capture missing\n");
		}
		state.pending_capture_reply = false;
		state.wait_for_capture = false;
	}
	state.capture_requested = false;
}

batch_finished :: (state: State) -> bool {
	if !state.batch_active return false;
	if control_queue_count(state) > 0 return false;
	if state.wait_frames > 0 return false;
	if state.wait_for_capture return false;
	return true;
}

capture_path :: (serial: u64) -> string {
	return tprint("captures/frame_%.png", serial);
}

// Canonical mouse is top-left, Y down. Frame_Info is still bottom-left until that TODO lands.
mouse_to_frame_info :: (top_left: V2f, window_size: V2f) -> V2f {
	return .{ top_left.x, window_size.y - top_left.y };
}

merge_into_frame_info :: (state: *State, info: *Platform.Frame_Info) {
	for i: 0..state.key_down.count-1 {
		info.key_pressed[i] = info.key_pressed[i] || state.key_down[i];
	}
	if state.has_mouse {
		info.mouse_position = mouse_to_frame_info(
			.{ xx state.mouse_x, xx state.mouse_y },
			info.window_size
		);
	}
	info.mouse_wheel += state.wheel;
	state.wheel = 0;
	if state.layout_override != .Unknown {
		info.layout = state.layout_override;
	}
	info.capture_frame = state.capture_requested || state.capture_enabled;
	info.capture_serial = state.capture_serial;
	info.quit = info.quit || state.quit_requested;
	if state.paused {
		info.delta_time = CONTROL_FIXED_DT;
	}
}

reset_batch :: (state: *State) {
	state.batch_active = false;
	state.response.count = 0;
}

#scope_file

Capture_Token :: enum {
	once;
	start;
	stop;
}

Layout_Token :: enum {
	azerty;
	qwerty;
}

Mouse_Button_Token :: enum {
	left;
	right;
	middle;
}

Key_Action :: enum {
	down;
	up;
}

control_normalize :: (text: string) -> string {
	parts := split(to_lower_copy(trim(text),, temp), #char " ");
	kept: [..] string;
	kept.allocator = temp;
	for parts {
		part := trim(it);
		if part.count == 0 continue;
		array_add(*kept, part);
	}
	if kept.count == 0 return "";
	return join(..kept, separator = " ");
}
