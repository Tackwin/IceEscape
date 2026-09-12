CONSOLE_Z :: 200.0;
CONSOLE_LOG_CAP :: 256;
CONSOLE_HISTORY_CAP :: 32;
CONSOLE_HEIGHT_FRACTION :: 0.4;

Console_Command :: struct {
	name: string;
	invoke: () -> ();
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

g_console: *Console_State;
g_console_user: *App_User;

bind_console :: (app_user: *App_User) {
	g_console_user = app_user;
	g_console = *app_user.console;
}

init_console :: (app_user: *App_User) {
	bind_console(app_user);
	GUI.init(*app_user.console.string_pool);
	app_user.console.input = GUI.make(*app_user.console.string_pool, 64);
	app_user.console.history_draft = GUI.make(*app_user.console.string_pool, 64);
	app_user.console.lines.allocator = context.allocator;
	app_user.console.history.allocator = context.allocator;
}

rebind_console :: (app_user: *App_User) {
	bind_console(app_user);
	GUI.rebind(*app_user.console.string_pool);
}

console_is_open :: () -> bool {
	return g_console && g_console.open;
}

console_ate_input :: () -> bool {
	return g_console && g_console.ate_input;
}

console_print :: (text: string) {
	if !g_console return;

	copied := copy_string(text);
	if g_console.lines.count >= CONSOLE_LOG_CAP {
		free(g_console.lines[0]);
		array_ordered_remove_by_index(*g_console.lines, 0);
	}
	array_add(*g_console.lines, copied);
}

console_print :: (fmt: string, args: .. Any) {
	console_print(tprint(fmt, ..args));
}

handle_console :: (app_user: *App_User) {
	bind_console(app_user);
	c := *app_user.console;
	c.ate_input = false;

	pressed := app_user.gui_state.controls.just_pressed;
	if pressed[Key.F10] {
		c.open = !c.open;
		c.ate_input = true;
		c.history_index = -1;
		if c.open && c.lines.count == 0 {
			console_print("F10 toggle. Type help.");
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

console_steal_if_needed :: (controls: *Controls.State) {
	if console_is_open() || console_ate_input() {
		console_steal(controls);
	}
}

draw_console :: (gui: *GUI.GUI_State) {
	if !g_console || !g_console.open return;

	c := g_console;
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
		run_console_line(GUI.view(*c.input));
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
	console_print(":");
	for matches console_print("  %", it);
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

run_console_line :: (raw: string) {
	line := trim(raw);
	if line.count == 0 return;

	console_print("] %", line);
	console_push_history(line);

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
		console_print("v1: commands take no arguments.");
		return;
	}

	for console_commands {
		if it.name == name {
			it.invoke();
			return;
		}
	}
	console_print("unknown: %", name);
}

console_push_history :: (line: string) {
	if !g_console return;
	if g_console.history.count > 0 && g_console.history[g_console.history.count - 1] == line {
		return;
	}
	if g_console.history.count >= CONSOLE_HISTORY_CAP {
		free(g_console.history[0]);
		array_ordered_remove_by_index(*g_console.history, 0);
	}
	array_add(*g_console.history, copy_string(line));
}

help :: () {
	console_print("% command(s):", console_commands.count);
	for console_commands {
		console_print("  %", it.name);
	}
} @console

clear :: () {
	if !g_console return;
	for g_console.lines {
		free(it);
	}
	g_console.lines.count = 0;
} @console
