CONSOLE_Z :: 200.0;
CONSOLE_LOG_CAP :: 256;
CONSOLE_HISTORY_CAP :: 32;
CONSOLE_HEIGHT_FRACTION :: 0.4;

Console_Command :: struct {
	name: string;
	invoke: (*Console_State) -> ();
}

#placeholder console_commands;

Console_State :: struct {
	open := false;
	ate_input := false;

	string_pool: GUI.String_Pool;
	input: GUI.String;
	history_draft: GUI.String;

	lines: [..] string;
	history: [..] string;
	history_index := -1;
	end_level_preview_action: End_Level_Preview_Action;
	// Borrowed only during the synchronous update/command invocation.
	app_user: *App_User;
	arguments: string;
}

init_console :: (app_user: *App_User) {
	c := *app_user.console;
	GUI.init(*c.string_pool);
	c.input = GUI.make(*c.string_pool, 64);
	c.history_draft = GUI.make(*c.string_pool, 64);
	c.lines.allocator = context.allocator;
	c.history.allocator = context.allocator;
}

rebind_console :: (app_user: *App_User) {
	GUI.rebind(*app_user.console.string_pool);
}

console_print :: (c: *Console_State, text: string) {
	copied := copy_string(text);
	if c.lines.count >= CONSOLE_LOG_CAP {
		free(c.lines[0]);
		array_ordered_remove_by_index(*c.lines, 0);
	}
	array_add(*c.lines, copied);
}

console_print :: (c: *Console_State, fmt: string, args: .. Any) {
	console_print(c, tprint(fmt, ..args));
}

handle_console :: (app_user: *App_User) {
	c := *app_user.console;
	c.app_user = app_user;
	c.ate_input = false;

	pressed := app_user.gui_state.controls.just_pressed;
	if pressed[Key.F10] {
		c.open = !c.open;
		c.ate_input = true;
		c.history_index = -1;
		if c.open && c.lines.count == 0 {
			console_print(c, "F10 toggle. Type help.");
		}
	} else if c.open && pressed[Key.Escape] {
		c.open = false;
		c.ate_input = true;
	}

	if c.open || c.ate_input {
		console_steal(*app_user.gui_state.controls);
		console_steal(*app_user.controls);
	}
}

console_steal :: (controls: *Controls.State) {
	controls.captured_keyboard = true;
	controls.captured_mouse = true;
}

console_steal_if_needed :: (c: *Console_State, controls: *Controls.State) {
	if c.open || c.ate_input {
		console_steal(controls);
	}
}

draw_console :: (c: *Console_State, gui: *GUI.GUI_State) {
	if !c.open return;

	window := gui.controls.window_size;
	panel_h := window.y * CONSOLE_HEIGHT_FRACTION;
	if panel_h < 80 panel_h = 80;

	panel: AABBf;
	panel.min = .{ 0, 0 };
	panel.max = .{ window.x, panel_h };

	GUI.push_id(gui, "console");
	defer GUI.pop_id(gui);

	GUI.widget_sized(gui, "panel", struct {}, panel, CONSOLE_Z, .Solid);
	GUI.push_quad_screen(gui, panel, V3f.{ 0, 0, 0 }, CONSOLE_Z, a = 0.85);

	line_h := 16.0;
	input_h := 22.0;
	y := panel_h - input_h - 6 - line_h;
	i := c.lines.count - 1;
	while i >= 0 && y >= 4 {
		GUI.atom_label(
			gui,
			c.lines[i],
			.{ 8, y },
			14,
			CONSOLE_Z + 1,
			.Top_Left,
			GUI.GRAY_90
		);
		y -= line_h;
		i -= 1;
	}

	GUI.atom_label(
		gui,
		">",
		.{ 8, panel_h - 6 },
		16,
		CONSOLE_Z + 2,
		.Bottom_Left,
		GUI.GRAY_90
	);

	cursor_to_end := false;
	if gui.controls.just_pressed[Key.Up] {
		console_history_up(c);
		cursor_to_end = true;
	}
	if gui.controls.just_pressed[Key.Down] {
		console_history_down(c);
		cursor_to_end = true;
	}
	if gui.controls.just_pressed[Key.Tab] {
		if console_tab_complete(c) cursor_to_end = true;
	}

	result := GUI.atom_input_text(
		gui,
		*c.input,
		18,
		window.x - 32,
		.{ 24, panel_h - 4 },
		CONSOLE_Z + 2,
		.Bottom_Left,
		placeholder = "help",
		unfocus_on_commit = false,
		force_focus = true,
		cursor_to_end = cursor_to_end
	);

	if result.committed {
		run_console_line(c, GUI.view(*c.input));
		GUI.set(*c.input, "");
		c.history_index = -1;
	}
}

console_history_up :: (c: *Console_State) {
	if c.history.count <= 0 return;

	if c.history_index < 0 {
		GUI.set(*c.history_draft, GUI.view(*c.input));
		c.history_index = c.history.count - 1;
	} else if c.history_index > 0 {
		c.history_index -= 1;
	}
	GUI.set(*c.input, c.history[c.history_index]);
}

console_history_down :: (c: *Console_State) {
	if c.history_index < 0 return;

	if c.history_index + 1 < c.history.count {
		c.history_index += 1;
		GUI.set(*c.input, c.history[c.history_index]);
	} else {
		c.history_index = -1;
		GUI.set(*c.input, GUI.view(*c.history_draft));
	}
}

console_tab_complete :: (c: *Console_State) -> bool {
	prefix := GUI.view(*c.input);
	matches: [..] string;
	matches.allocator = temp;
	for console_commands {
		if begins_with(it.name, prefix) {
			array_add(*matches, it.name);
		}
	}
	if matches.count == 0 return false;

	if matches.count == 1 {
		GUI.set(*c.input, matches[0]);
		return true;
	}

	common := matches[0];
	for 1..matches.count - 1 {
		common = console_common_prefix(common, matches[it]);
	}
	GUI.set(*c.input, common);
	console_print(c, ":");
	for matches console_print(c, "  %", it);
	return true;
}

console_common_prefix :: (a: string, b: string) -> string {
	n := min(a.count, b.count);
	i := 0;
	while i < n && a[i] == b[i] {
		i += 1;
	}
	result := a;
	result.count = i;
	return result;
}

run_console_line :: (c: *Console_State, raw: string) {
	line := trim(raw);
	if line.count == 0 return;

	console_print(c, "] %", line);
	console_push_history(c, line);

	name := line;
	rest: string;
	for line {
		if console_argument_space(it) {
			name.count = it_index;
			rest.data = line.data + it_index;
			rest.count = line.count - it_index;
			rest = trim(rest);
			break;
		}
	}

	for console_commands {
		if it.name == name {
			c.arguments = rest;
			defer c.arguments = "";
			it.invoke(c);
			return;
		}
	}
	console_print(c, "unknown: %", name);
}

console_push_history :: (c: *Console_State, line: string) {
	if c.history.count > 0 && c.history[c.history.count - 1] == line {
		return;
	}
	if c.history.count >= CONSOLE_HISTORY_CAP {
		free(c.history[0]);
		array_ordered_remove_by_index(*c.history, 0);
	}
	array_add(*c.history, copy_string(line));
}

help :: (c: *Console_State) {
	if !console_no_arguments(c, "help") return;
	console_print(c, "% command(s):", console_commands.count);
	for console_commands {
		console_print(c, "  %", console_command_usage(it.name));
	}
	console_print(c, "Tile kinds: None=0, Ice=1, Grass=2, Slippy_Ice=3, Dirt=4, Funny_Ice=5.");
	console_print(c, "Tile names ignore case. who_host reports the server host player_id.");
} @console

clear :: (c: *Console_State) {
	if !console_no_arguments(c, "clear") return;
	for c.lines {
		free(it);
	}
	c.lines.count = 0;
} @console

previewendlevel :: (c: *Console_State) {
	if !console_no_arguments(c, "previewendlevel") return;
	c.end_level_preview_action = .Show;
	console_print(c, "Showing dummy end-level results. Countdown held; animation clock running.");
} @console

hideendlevel :: (c: *Console_State) {
	if !console_no_arguments(c, "hideendlevel") return;
	c.end_level_preview_action = .Hide;
	console_print(c, "End-level preview hidden.");
} @console

console_argument_space :: (c: u8) -> bool {
	return c == #char " " || c == #char "\t" || c == #char "\r" || c == #char "\n";
}

console_take_argument :: (remaining: *string) -> string {
	while remaining.count > 0 && console_argument_space(remaining.data[0]) {
		remaining.data += 1;
		remaining.count -= 1;
	}
	argument := remaining.*;
	argument.count = 0;
	while argument.count < remaining.count && !console_argument_space(remaining.data[argument.count]) argument.count += 1;
	remaining.data += argument.count;
	remaining.count -= argument.count;
	return argument;
}

console_no_arguments :: (c: *Console_State, usage: string) -> bool {
	remaining := c.arguments;
	if console_take_argument(*remaining).count == 0 return true;
	console_print(c, "usage: %", usage);
	return false;
}

// Accumulate against the unsigned magnitude limit before multiplication. This
// accepts the full signed int range without overflow or a lossy scan conversion.
console_parse_integer :: (input: string, signed_allowed: bool) -> int, bool {
	text := input;
	if text.count == 0 return 0, false;
	negative := false;
	if signed_allowed && (text[0] == #char "-" || text[0] == #char "+") {
		negative = text[0] == #char "-";
		text.data += 1;
		text.count -= 1;
	}
	if text.count == 0 return 0, false;
	limit: u64 = 0x7fff_ffff_ffff_ffff;
	if negative limit = 0x8000_0000_0000_0000;
	value: u64;
	for text {
		if it < #char "0" || it > #char "9" return 0, false;
		digit: u64 = xx (it - #char "0");
		if value > (limit - digit) / 10 return 0, false;
		value = value * 10 + digit;
	}
	if negative {
		if value == 0x8000_0000_0000_0000 return -9223372036854775807 - 1, true;
		return -cast(int) value, true;
	}
	return cast(int) value, true;
}

console_equal_fold :: (a: string, b: string) -> bool {
	if a.count != b.count return false;
	for 0..a.count-1 {
		left := a[it];
		right := b[it];
		if left >= #char "A" && left <= #char "Z" left += 32;
		if right >= #char "A" && right <= #char "Z" right += 32;
		if left != right return false;
	}
	return true;
}

console_parse_tile_kind :: (text: string) -> int, bool {
	value, valid := console_parse_integer(text, false);
	if valid return value, value >= 0 && value <= 5;
	names := enum_names(Scene.Tile.Kind);
	for names if console_equal_fold(it, text) return it_index, true;
	return 0, false;
}

console_command_usage :: (name: string) -> string {
	if name == "kill" return "kill <player_id>";
	if name == "res" return "res <player_id>";
	if name == "kick" return "kick <player_id>";
	if name == "edit" return "edit <x> <y> <tile_kind>";
	if name == "open" return "open <gate_id>";
	if name == "break_rock" return "break_rock <rock_id>";
	return name;
}

console_debug_send :: (c: *Console_State, request: Command.Debug_Request) {
	app_user := c.app_user;
	if !app_user || !app_user.state.is_communication_established || !app_user.state.is_connected {
		console_print(c, "error: not connected to a server.");
		return;
	}
	// The server owns permission checks and all mutations, including self
	// operations. Do not alter the local scene before authoritative sync arrives.
	send_web_message(app_user.state.platform, app_user.state.current_time, make_command(request));
}

console_debug_without_arguments :: (c: *Console_State, kind: Debug_Operation, usage: string) {
	if !console_no_arguments(c, usage) return;
	request: Command.Debug_Request;
	request.kind = kind;
	console_debug_send(c, request);
}

console_debug_target :: (c: *Console_State, kind: Debug_Operation, usage: string) {
	remaining := c.arguments;
	argument := console_take_argument(*remaining);
	value, valid := console_parse_integer(argument, false);
	if !valid || console_take_argument(*remaining).count != 0 {
		console_print(c, "usage: % (id must be a nonnegative integer)", usage);
		return;
	}
	request: Command.Debug_Request;
	request.kind = kind;
	request.target_id = value;
	console_debug_send(c, request);
}

console_debug_reply :: (app_user: *App_User, reply: Command.Debug_Reply) {
	c := *app_user.console;
	label := "ok";
	if reply.status == .Rejected label = "rejected";
	if reply.status == .Invalid label = "invalid";
	console_print(c, "%: %", label, reply.message);
	if reply.kind == .Who_Host && reply.status == .Accepted {
		if reply.host_player_id < 0 {
			console_print(c, "host: none");
		} else {
			if reply.host_player_id == reply.sender_player_id {
				console_print(c, "host player_id: % (you)", reply.host_player_id);
			} else {
				console_print(c, "host player_id: %", reply.host_player_id);
			}
		}
	}
}

killme :: (c: *Console_State) {
	console_debug_without_arguments(c, .Kill_Self, "killme");
} @console

kill :: (c: *Console_State) {
	console_debug_target(c, .Kill, "kill <player_id>");
} @console

resme :: (c: *Console_State) {
	console_debug_without_arguments(c, .Revive_Self, "resme");
} @console

res :: (c: *Console_State) {
	console_debug_target(c, .Revive, "res <player_id>");
} @console

next_level :: (c: *Console_State) {
	console_debug_without_arguments(c, .Next_Level, "next_level");
} @console

wipe_level :: (c: *Console_State) {
	console_debug_without_arguments(c, .Wipe_Level, "wipe_level");
} @console

prev_level :: (c: *Console_State) {
	console_debug_without_arguments(c, .Prev_Level, "prev_level");
} @console

kick :: (c: *Console_State) {
	console_debug_target(c, .Kick, "kick <player_id>");
} @console

edit :: (c: *Console_State) {
	remaining := c.arguments;
	x, x_valid := console_parse_integer(console_take_argument(*remaining), true);
	y, y_valid := console_parse_integer(console_take_argument(*remaining), true);
	kind, kind_valid := console_parse_tile_kind(console_take_argument(*remaining));
	if !x_valid || !y_valid || !kind_valid || console_take_argument(*remaining).count != 0 {
		console_print(c, "usage: edit <x> <y> <tile_kind> (integer coordinates; tile kind 0..5 or name)");
		return;
	}
	request: Command.Debug_Request;
	request.kind = .Edit;
	request.tile_x = x;
	request.tile_y = y;
	request.tile_kind = kind;
	console_debug_send(c, request);
} @console

open :: (c: *Console_State) {
	console_debug_target(c, .Open_Gate, "open <gate_id>");
} @console

break_rock :: (c: *Console_State) {
	console_debug_target(c, .Break_Rock, "break_rock <rock_id>");
} @console

who_host :: (c: *Console_State) {
	console_debug_without_arguments(c, .Who_Host, "who_host");
} @console
