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
		if it == #char " " {
			name.count = it_index;
			rest.data = line.data + it_index;
			rest.count = line.count - it_index;
			rest = trim(rest);
			break;
		}
	}

	if rest.count > 0 {
		console_print(c, "v1: commands take no arguments.");
		return;
	}

	for console_commands {
		if it.name == name {
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
	console_print(c, "% command(s):", console_commands.count);
	for console_commands {
		console_print(c, "  %", it.name);
	}
} @console

clear :: (c: *Console_State) {
	for c.lines {
		free(it);
	}
	c.lines.count = 0;
} @console
