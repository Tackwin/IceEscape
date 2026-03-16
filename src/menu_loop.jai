#import "Sort";

Menu :: struct {
	create_instance_popup_open: bool = false;
	create_instance_name: string = "";
	create_instance_password: string = "";

	login_popup_open: bool = false;
	login_popup_password: string = "";

	scene_name_leadeboard: string = "";

	enter_instance_password: string = "";

	instances_list: [..] Command.Ans_Instance_List.Instance_Info;

	Terrain_Entry :: struct {
		name: string;
		author: string;
		id: int;
	}
	terrain_entries: [..] Terrain_Entry;
	terrain_entries_page := 0;

	Entry_Leaderboard :: struct {
		username: string;
		time_ms: int;
		timestamp_ms: int;
	}
	entries_leaderboard: [..] Entry_Leaderboard;

	passcode: u64 = 0;
	passstring: string = "";

	profile: Profile;
}


push_left_main_menu :: (
	gui: *GUI.GUI_State,
	menu: *Menu,
	platform: *Platform
) {
	cursor := v2(8.0, gui.controls.window_size.y - 8);
	GUI.default_params(gui).cursor = cursor;
	GUI.default_params(gui).direction = .Down;
	GUI.default_params(gui).align = .Top_Left;
	GUI.default_params(gui).z = 2;

	{
		GUI.push_default_params(gui, GUI.default_params(gui).*);
		defer GUI.pop_default_params(gui);
		GUI.default_params(gui).direction = .Right;

		GUI.space(gui, 8.0);
		if GUI._text_button(gui, "Login", id = "login_btn") {
			menu.login_popup_open = true;
		}
		GUI.space(gui, 8.0);
		clicked, state := GUI._text_button(gui, "Reveal", id = "see_passcode_btn");
		GUI.space(gui, 8.0);
		passcode_label := "Passcode: ---- --- ----";
		if state.pressed {
			passcode_label = tprint("Passcode: %", menu.passstring);
		}
		GUI._atom_label(
			gui,
			passcode_label,
			id = "passcode_label",
			color = GUI.GRAY_00,
			offset_pos = v2(4.0, 0.0)
		);
	}
	GUI.space(gui, 24.0);

	new_username := GUI.labeled_input_text(
		gui, "Username:", menu.profile.username, 256, 24, id = "username_input"
	);
	if new_username != menu.profile.username {
		if menu.profile.username.count > 0 && menu.profile.username.data
			free(menu.profile.username);
		menu.profile.username = sprint("%", new_username);

		set_username: Command.Set_Username;
		set_username.profile_id = menu.profile.id;
		set_username.username = tprint("%", menu.profile.username);
		send_web_message(platform, gui.controls.time, make_command(set_username));
	}

	cursor.x = 8.0;
	cursor.y = gui.controls.window_size.y - 16.0 - 64.0;
	GUI.default_params(gui).cursor = cursor;
	GUI._atom_label(gui, "Stats", id = "stats_label", color = GUI.GRAY_00);
	GUI._atom_label(
		gui,
		tprint("     Death count: %", menu.profile.stats.death_count),
		id = "death_label",
		color = GUI.GRAY_00
	);
	GUI._atom_label(
		gui,
		tprint("     Win count: %", menu.profile.stats.win_count),
		id = "win_label",
		color = GUI.GRAY_00
	);
	GUI._atom_label(
		gui,
		tprint("     Revive count: %", menu.profile.stats.revive_count),
		id = "revive_label",
		color = GUI.GRAY_00
	);

	GUI.space(gui, 24.0);


	new_scene_name := GUI.labeled_input_text(
		gui, "Scene name:", menu.scene_name_leadeboard, 256, 24, id = "scene_name_leaderboard_input"
	);
	if new_scene_name != menu.scene_name_leadeboard {
		free(menu.scene_name_leadeboard);
		menu.scene_name_leadeboard = sprint("%", new_scene_name);

		// get_terrain: Command.Get_Terrain_Leaderboard;
		// get_terrain.terrain_id = -1;
		// get_terrain.scene_name = tprint("%", menu.scene_name_leadeboard);
		// send_web_message(platform, gui.controls.time, make_command(get_terrain));
		ask_list_terrain: Command.Ask_List_Terrain;
		ask_list_terrain.filter = menu.scene_name_leadeboard;
		send_web_message(platform, gui.controls.time, make_command(ask_list_terrain));
	}

	Row_Terrain :: struct {
		name: string; @name("Name") @size(213)
		author: string; @name("Author") @size(128)
		leaderboard: string; @name("Leaderboard") @button @align(Right)
		play: string; @name("Play") @button @align(Right)
	}
	PAGE_SIZE := 5;
	page_count := max((menu.terrain_entries.count + PAGE_SIZE - 1) / PAGE_SIZE, 1);
	menu.terrain_entries_page = clamp(
		menu.terrain_entries_page,
		0,
		max((menu.terrain_entries.count + PAGE_SIZE - 1) / PAGE_SIZE - 1, 0)
	);

	beg := menu.terrain_entries_page * PAGE_SIZE;
	end := beg + PAGE_SIZE;
	end = min(end, menu.terrain_entries.count);
	terrain_list_view: []Menu.Terrain_Entry;
	terrain_list_view.count = end - beg;
	terrain_list_view.data = menu.terrain_entries.data + beg;

	rows := NewArray(terrain_list_view.count, Row_Terrain,, temp);
	for terrain_list_view {
		rows[it_index].name = it.name;
		rows[it_index].author = it.author;
		rows[it_index].leaderboard = "View";
		rows[it_index].play = "----";
	}
	scene_table := GUI.table(gui, rows, v2(512.0, 24.0 * 6 + 12), id = "terrain_table");
	if scene_table.clicked_row_index >= 0 {
		entry := terrain_list_view[scene_table.clicked_row_index];
		if scene_table.clicked_col_index == 2 {
			get_terrain_leaderboard: Command.Get_Terrain_Leaderboard;
			get_terrain_leaderboard.terrain_id = entry.id;
			send_web_message(platform, gui.controls.time, make_command(get_terrain_leaderboard));
		}
	}

	GUI.space(gui, 24 * 7);
	GUI._atom_label(
		gui, "Leaderboard", id = "leaderboard_label", color = GUI.GRAY_00
	);

	Row_Leaderboard :: struct {
		usermame: string; @name("Name") @size(118)
		time_ms: string; @name("Time(s)")
		timestamp_ms: string; @name("Date") @size(178) @align(Right)
	}
	rows_leaderboard := NewArray(menu.entries_leaderboard.count, Row_Leaderboard,, temp);
	for menu.entries_leaderboard {
		entry := menu.entries_leaderboard[it_index];
		row := *rows_leaderboard[it_index];
		row.usermame = entry.username;
		if row.usermame.count == 0
			row.usermame = "Anonymous";
		row.time_ms = tprint(
			"%1.%2%3%4",
			entry.time_ms / 1000,
			entry.time_ms % 1000 / 100,
			entry.time_ms % 100 / 10,
			entry.time_ms % 10
		);
		cal := platform.to_calendar(milliseconds_to_apollo(entry.timestamp_ms));
		row.timestamp_ms = tprint(
			"%/% %:%",
			cal.day_of_month_starting_at_0 + 1,
			cal.month_starting_at_0 + 1,
			cal.hour,
			cal.minute
		);
		if it_index > 5
			break;
	}

	GUI.table(gui, rows_leaderboard, v2(256.0 + 128, 24.0 * 6), id = "leaderboard_table");

	if menu.login_popup_open {
		window := GUI.begin_window(
			gui,
			gui.controls.window_size / 2,
			V2f.{ 400, 300 },
			id = "login_window",
			z = 10
		);
		defer GUI.end_window(gui, id = "login_window");

		new_passcode := GUI.labeled_input_text(
			gui,
			"Passcode:",
			menu.login_popup_password,
			400 - 16,
			24,
			id = "login_passcode_input",
			placeholder = "0123456789A"
		);
		if new_passcode != menu.login_popup_password {
			if menu.login_popup_password.count > 0 && menu.login_popup_password.data
				free(menu.login_popup_password);
			menu.login_popup_password = sprint("%", new_passcode);
		}

		GUI.space(gui, 64.0);
		GUI.default_params(gui).cursor = window.pos + v2(window.size.x, 0.0) - v2(8.0, -8.0);
		GUI.default_params(gui).align = .Bottom_Right;
		GUI.default_params(gui).direction = .Left;

		if GUI._text_button(gui, "Login", id = "login_confirm_btn") {
			command: Command.Login;
			command.passcode = string_to_code(menu.login_popup_password);
			command.token = platform.get_token();
			send_web_message(platform, gui.controls.time, make_command(command));
			menu.login_popup_open = false;
		}
		if GUI._text_button(gui, "Cancel", id = "login_cancel_btn") {
			menu.login_popup_open = false;
		}
	}
}

code_to_string :: (code: u64) -> string {
	unit :: "0123456789ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnopqrstuvwxyz";
	_code := code;
	str8 := NewArray(11, u8,, temp);

	for 0..str8.count-1 {
		str8[it] = unit[(_code % unit.count).(int)];
		_code /= unit.count;
	}
	left: string;
	left.count = 4;
	left.data = str8.data;

	mid: string;
	mid.count = 3;
	mid.data = str8.data + 4;

	right: string;
	right.count = 4;
	right.data = str8.data + 7;
	return sprint("% % %", left, mid, right);
}
string_to_code :: (str: string) -> u64 {
	unit :: "0123456789ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnopqrstuvwxyz";
	lut := NewArray(256, u64,, temp);
	for unit {
		lut[it.(u64)] = it_index.(u64);
	}
	code : u64 = 0;
	power : u64 = 1;
	for c: str {
		if c == #char " "
			continue;
		code += lut[c.(u64)] * power;
		power *= unit.count;
	}
	return code;
}

process_menu :: (state: *State, command: Command) -> bool {
	connect := isa(command.payload, Command.Connect);
	if connect {
		state.is_connected = true;
		state.menu.passcode = connect.passcode;
		state.menu.passstring = code_to_string(connect.passcode);
		state.platform.set_token(connect.token);

		ask_instance: Command.Ask_Instance_List;
		send_web_message(state.platform, state.current_time, make_command(ask_instance));

		get_profile_stats: Command.Get_Profile_Stats;
		send_web_message(state.platform, state.current_time, make_command(get_profile_stats));

		get_username: Command.Get_Username;
		send_web_message(state.platform, state.current_time, make_command(get_username));

		return true;
	}

	get_profile_stats := isa(command.payload, Command.Get_Profile_Stats);
	if get_profile_stats {
		state.menu.profile.stats = get_profile_stats.stats;
		return true;
	}

	get_username := isa(command.payload, Command.Get_Username);
	if get_username {
		free(state.menu.profile.username);
		state.menu.profile.username = sprint("%", get_username.username);
		return true;
	}

	ans_instance_list := isa(command.payload, Command.Ans_Instance_List);
	if ans_instance_list {
		array_resize(*state.menu.instances_list, ans_instance_list.instances.count);
		for ans_instance_list.instances
			state.menu.instances_list[it_index] = it;
		return true;
	}

	ans_enter_instance := isa(command.payload, Command.Ans_Enter_Instance);
	if ans_enter_instance {

		return true;
	}

	ans_list_terrain := isa(command.payload, Command.Ans_List_Terrain);
	if ans_list_terrain {
		array_resize(*state.menu.terrain_entries, ans_list_terrain.terrains_id.count);
		for * state.menu.terrain_entries {
			it.id = ans_list_terrain.terrains_id[it_index];
			it.name = ans_list_terrain.terrains_name[it_index];
			it.author = ans_list_terrain.authors_name[it_index];
		}
		return true;
	}

	sync_scene := isa(command.payload, Command.Sync_Scene);
	if sync_scene {
		state.screen_state = .Game;
		return false;
	}

	login := isa(command.payload, Command.Login);
	if login {
		if login.feedback == .Accepted {
			if state.menu.passstring
				free(state.menu.passstring);
			state.menu.passstring = sprint(
				"% % %",
				slice(state.menu.login_popup_password, 0, 4),
				slice(state.menu.login_popup_password, 4, 7),
				slice(state.menu.login_popup_password, 7, 11)
			);
		}
		state.platform.set_token(login.token);
	}

	get_terrain_leaderboard := isa(command.payload, Command.Get_Terrain_Leaderboard);
	if get_terrain_leaderboard {
		array_resize(*state.menu.entries_leaderboard, get_terrain_leaderboard.entries.count);
		for get_terrain_leaderboard.entries {
			entry := *state.menu.entries_leaderboard[it_index];
			entry.username = it.username;
			entry.time_ms = it.time_ms;
			entry.timestamp_ms = it.timestamp_ms;
		}

		quick_sort(state.menu.entries_leaderboard, x => x.time_ms);
	}

	return false;
}

menu_loop :: (_app: *App) -> bool {
	app_user := _app.user_data.(*App_User);
	using app_user;

	app_user.graphics.gpu = _app.platform.gpu;
	WRender.graphics = *app_user.graphics;

	GUI.push_quad_screen(
		*app_user.gui_state,
		V2f.{ 0, 0 },
		V2f.{ controls.window_size.x, controls.window_size.y },
		V3f.{ 0.1, 0.1, 0.1 },
		0,
	);
	if !state.is_connected {
		no_connection_ret := GUI.push_no_connection(*app_user.gui_state);

		if no_connection_ret.retry_clicked {
			if !state.is_communication_established {
				connection:, state.is_communication_established = _app.platform.connect_server(
					"tackwin.fr", 443, "wss"
				);
			}

			if state.is_communication_established {
				connect: Command.Connect;
				connect.token = _app.platform.get_token();
				send_web_message(_app.platform, controls.time, make_command(connect));
			}
		}
		if no_connection_ret.retry_localhost_clicked {
			if !state.is_communication_established {
				connection:, state.is_communication_established = _app.platform.connect_server(
					"localhost", 8000, "ws"
				);
			}

			if state.is_communication_established {
				print("Launching localhost connect\n");
				connect: Command.Connect;
				connect.token = _app.platform.get_token();
				send_web_message(_app.platform, controls.time, make_command(connect));
			}
		}
	} else {
		main_menu_args: GUI.Main_Menu_Args;
		main_menu_args.instances = NewArray(
			state.menu.instances_list.count, GUI.Instance_Info,, temp
		);
		main_menu_args.create_instance_popup_open = state.menu.create_instance_popup_open;
		main_menu_args.create_instance_name = state.menu.create_instance_name;
		main_menu_args.create_instance_password = state.menu.create_instance_password;
		main_menu_args.enter_instance_password = state.menu.enter_instance_password;
		for state.menu.instances_list {
			gui_instance := *main_menu_args.instances[it_index];
			gui_instance.name.data = it.name.data;
			gui_instance.name.count = it.name.count;
			for gui_instance.name if it == 0 { gui_instance.name.count = it_index; break; }
			gui_instance.player_count = it.current_players;
			gui_instance.player_capacity = it.max_players;
			gui_instance.level_name.data = it.level_name.data;
			gui_instance.level_name.count = it.level_name.count;
			for gui_instance.level_name if it == 0 {
				gui_instance.level_name.count = it_index;
				break;
			}
			gui_instance.private = it.private;
			gui_instance.auto_revive = it.auto_revive;
			gui_instance.instance_id = it.instance_id;
		}
		main_menu_ret := GUI.push_main_menu(*app_user.gui_state, main_menu_args);
	
		if state.menu.create_instance_name.count > 0 &&  state.menu.create_instance_name.data
			free(state.menu.create_instance_name);
		state.menu.create_instance_name = sprint("%", main_menu_ret.temp_create_instance_name);

		if state.menu.create_instance_password.count > 0 &&  state.menu.create_instance_password.data
			free(state.menu.create_instance_password);
		state.menu.create_instance_password = sprint("%", main_menu_ret.temp_create_instance_password);

		if state.menu.enter_instance_password.count > 0 &&  state.menu.enter_instance_password.data
			free(state.menu.enter_instance_password);
		state.menu.enter_instance_password = sprint("%", main_menu_ret.temp_enter_instance_password);

		if main_menu_ret.create_instance_cancel_clicked {
			state.menu.create_instance_popup_open = false;
		}

		if main_menu_ret.create_instance_create_clicked {
			command: Command.Create_Instance;
			string_to_array(state.menu.create_instance_name, command.name);
			string_to_array(state.menu.create_instance_password, command.password);
			command.auto_revive = main_menu_ret.create_instance_auto_revive;
			command.private = main_menu_ret.create_instance_private;
			send_web_message(_app.platform, controls.time, make_command(command));
			state.menu.create_instance_popup_open = false;
		}

		if main_menu_ret.reload_instances_clicked {
			command: Command.Ask_Instance_List;
			send_web_message(_app.platform, controls.time, make_command(command));
		}

		if main_menu_ret.enter_instance_clicked && main_menu_ret.selected_instance_id >= 0 {
			command: Command.Ask_Enter_Instance;
			command.instance_id = main_menu_ret.selected_instance_id;
			string_to_array(state.menu.enter_instance_password, command.password);
			send_web_message(_app.platform, controls.time, make_command(command));
		}

		if main_menu_ret.create_instance_clicked {
			state.menu.create_instance_popup_open = !state.menu.create_instance_popup_open;
		}

		push_left_main_menu(*app_user.gui_state, *state.menu, _app.platform);
		// #if OS == .WASM {
		// 	version_string :: "0.0.1 (1 March 2026, 23:13:10)";
		// }
		GUI.default_params(*app_user.gui_state).cursor.x = controls.window_size.x - 12.0;
		GUI.default_params(*app_user.gui_state).cursor.y = controls.window_size.y - 8.0;
		GUI.default_params(*app_user.gui_state).align = .Top_Right;
		GUI._atom_label(
			*app_user.gui_state,
			tprint("Version: %", version_string),
			id = "version_label",
			color = GUI.GRAY_00,
			offset_pos = v2(-4.0, 0.0),
			scale = 10
		);
	}

	// Editor button (always visible)
	editor_clicked, _, _ := GUI.text_button(
		*app_user.gui_state,
		"Level Editor",
		V2f.{ 20, 20 },
		z = 10,
		id = "editor_btn"
	);
	if editor_clicked {
		state.screen_state = .Editor;
	}

	frame := WRender.begin_frame(*framegraph, controls.time);
	WRender.render_gui(frame, *framegraph, app_user.gui_state, store);
	WRender.end_frame(*framegraph, frame);

	return true;
}
