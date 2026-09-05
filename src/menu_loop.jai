#import "Sort";

Create_Instance :: struct {
	open := false;

	filter: GUI.String;
	name: GUI.String;
	password: GUI.String;
	auto_revive: bool;
	private: bool;

	Terrain_Entry :: struct {
		name: string;
		author: string;
		id: int;
		created_ms: int;
		selected := false;
	}

	terrain_entries: [..] Terrain_Entry;
	terrain_page := 0;

	roster_list: [..] Terrain_Entry;
}

Create_Bomberman :: struct {
	open := false;

	name: GUI.String;
	password: GUI.String;
	private: bool;
	max_players: int;
}

Menu :: struct {
	big_assets_sending: [..] Big_Asset;
	big_assets_receiving: Table(int, Big_Asset);
	thumbnail_receiving: [..] Thumbnail_Pending;

	login_popup_open: bool = false;
	login_popup_password: GUI.String;

	scene_name_leadeboard: GUI.String;
	terrain_name_selected_leaderboard: string = "";

	create_instance: Create_Instance;
	create_bomberman: Create_Bomberman;

	enter_instance_password: GUI.String;

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

	string_pool: GUI.String_Pool;
	username: GUI.String;
}


push_left_main_menu :: (
	gui: *GUI.GUI_State,
	menu: *Menu,
	platform: *Platform
) {
	cursor := v2(8.0, 8.0);
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

	input := GUI.labeled_input_text(
		gui, "Username:", *menu.username, 256, 24, id = "username_input"
	);
	if input.changed {
		set_username: Command.Set_Username;
		set_username.profile_id = menu.profile.id;
		set_username.username = GUI.view(*menu.username);
		send_web_message(platform, gui.controls.time, make_command(set_username));
	}

	cursor.x = 8.0;
	cursor.y = 16.0 + 64.0;
	GUI.default_params(gui).cursor = cursor;
	GUI._atom_label(gui, "The terrible bug that messed up some people is gone", scale = 16, color = GUI.GRAY_00);
	GUI._atom_label(gui, "I have only prayer to offer to my dear player base", scale = 16, color = GUI.GRAY_00);
	GUI._atom_label(gui, "Sorry :'(", scale = 16, color = GUI.GRAY_00);
	// GUI._atom_label(gui, "Stats", id = "stats_label", color = GUI.GRAY_00);
	// GUI._atom_label(
	// 	gui,
	// 	tprint("     Death count: %", menu.profile.stats.death_count),
	// 	id = "death_label",
	// 	color = GUI.GRAY_00
	// );
	// GUI._atom_label(
	// 	gui,
	// 	tprint("     Win count: %", menu.profile.stats.win_count),
	// 	id = "win_label",
	// 	color = GUI.GRAY_00
	// );
	// GUI._atom_label(
	// 	gui,
	// 	tprint("     Revive count: %", menu.profile.stats.revive_count),
	// 	id = "revive_label",
	// 	color = GUI.GRAY_00
	// );

	// GUI.space(gui, 24.0);


	if GUI.labeled_input_text(
		gui, "Scene name:", *menu.scene_name_leadeboard, 256, 24, id = "scene_name_leaderboard_input"
	).changed {
		ask_list_terrain: Command.Ask_List_Terrain;
		ask_list_terrain.filter = GUI.view(*menu.scene_name_leadeboard);
		ask_list_terrain.correlation_id = 0;
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
		rows[it_index].play = "Play";
	}
	scene_table := GUI.table(gui, rows, v2(512.0, 24.0 * 6 + 12), id = "terrain_table");
	if scene_table.clicked_row_index >= 0 {
		entry := terrain_list_view[scene_table.clicked_row_index];
		if scene_table.clicked_col_index == 2 {
			get_terrain_leaderboard: Command.Get_Terrain_Leaderboard;
			get_terrain_leaderboard.terrain_id = entry.id;
			send_web_message(platform, gui.controls.time, make_command(get_terrain_leaderboard));
		}
		if scene_table.clicked_col_index == 3 {
			ask_enter_custom_instance: Command.Ask_Enter_Quick_Instance;
			ask_enter_custom_instance.terrain_id = entry.id;
			send_web_message(
				platform, gui.controls.time, make_command(ask_enter_custom_instance)
			);
		}
	}

	GUI.space(gui, 24 * 7);
	leaderboard_string := "Leaderboard for: Unselected";
	if menu.terrain_name_selected_leaderboard.count > 0
		leaderboard_string = tprint("Leaderboard for: %", menu.terrain_name_selected_leaderboard);
	
	GUI._atom_label(
		gui, leaderboard_string, id = "leaderboard_label", color = GUI.GRAY_00
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

		GUI.labeled_input_text(
			gui,
			"Passcode:",
			*menu.login_popup_password,
			400 - 16,
			24,
			id = "login_passcode_input",
			placeholder = "0123456789A"
		);

		GUI.space(gui, 64.0);
		GUI.default_params(gui).cursor = window.pos + v2(window.size.x - 8.0, window.size.y - 8.0);
		GUI.default_params(gui).align = .Bottom_Right;
		GUI.default_params(gui).direction = .Left;

		if GUI._text_button(gui, "Login", id = "login_confirm_btn") {
			command: Command.Login;
			command.passcode = string_to_code(GUI.view(*menu.login_popup_password));
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

process_menu :: (app_user: *App_User, command: Command) -> bool {
	state := *app_user.state;
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
		
		ask_list_terrain: Command.Ask_List_Terrain;
		ask_list_terrain.filter = "";
		ask_list_terrain.correlation_id = 0;
		send_web_message(state.platform, state.current_time, make_command(ask_list_terrain));

		ask_list_terrain = .{};
		ask_list_terrain.filter = "";
		ask_list_terrain.correlation_id = 1;
		send_web_message(state.platform, state.current_time, make_command(ask_list_terrain));

		return true;
	}

	get_profile_stats := isa(command.payload, Command.Get_Profile_Stats);
	if get_profile_stats {
		state.menu.profile.stats = get_profile_stats.stats;
		return true;
	}

	get_thumbnail := isa(command.payload, Command.Get_Thumbnail);
	if get_thumbnail {
		big_asset := table_find_pointer(*state.menu.big_assets_receiving, get_thumbnail.asset.id);
		if big_asset {
			big_asset.buffer = NewArray(get_thumbnail.asset.size, u8, false);
			return true;
		}
	}

	asset_chunk := isa(command.payload, Command.Asset_Chunk);
	if asset_chunk {
		big_asset := table_find_pointer(*state.menu.big_assets_receiving, asset_chunk.asset.id);
		if big_asset {
			memcpy(
				big_asset.buffer.data + asset_chunk.offset,
				asset_chunk.data.data,
				min(asset_chunk.data.count, big_asset.buffer.count - asset_chunk.offset)
			);
			big_asset.written += asset_chunk.data.count;
			big_asset.last_written = state.current_time;
			if big_asset.written >= big_asset.buffer.count {
				handle_received_asset(app_user, big_asset);
			}
			return true;
		}
	}
	get_username := isa(command.payload, Command.Get_Username);
	if get_username {
		free(state.menu.profile.username);
		state.menu.profile.username = sprint("%", get_username.username);
		GUI.set(*state.menu.username, get_username.username);
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
		if ans_list_terrain.correlation_id == 0 {
			for * state.menu.terrain_entries {
				free(it.name);
				free(it.author);
			}
			array_resize(*state.menu.terrain_entries, ans_list_terrain.terrains_id.count);
			for * state.menu.terrain_entries {
				it.id = ans_list_terrain.terrains_id[it_index];
				it.name = sprint("%", ans_list_terrain.terrains_name[it_index]);
				it.author = sprint("%", ans_list_terrain.authors_name[it_index]);
			}
		} else if ans_list_terrain.correlation_id == 1 {
			for * state.menu.create_instance.roster_list {
				free(it.name);
				free(it.author);
			}
			array_resize(
				*state.menu.create_instance.terrain_entries, ans_list_terrain.terrains_id.count
			);
			for * state.menu.create_instance.terrain_entries {
				it.id = ans_list_terrain.terrains_id[it_index];
				it.name = sprint("%", ans_list_terrain.terrains_name[it_index]);
				it.author = sprint("%", ans_list_terrain.authors_name[it_index]);
				it.created_ms = ans_list_terrain.creation_time_ms[it_index];

				if !thumbnail_here_or_coming(*app_user.store, it.id) {
					get_thumbnail: Command.Get_Thumbnail;
					get_thumbnail.asset.id = app_user.counter;
					get_thumbnail.terrain_id = it.id;
					app_user.counter += 1;
					send_web_message(state.platform, state.current_time, make_command(get_thumbnail));

					big_asset: Big_Asset;
					big_asset.id = get_thumbnail.asset.id;
					big_asset.kind = .Receiving;
					big_asset.last_written = state.platform.get_current_time();

					pending: Thumbnail_Pending;
					pending.asset_id = get_thumbnail.asset.id;
					pending.terrain_id = it.id;
					array_add(*state.menu.thumbnail_receiving, pending);
					table_add(*state.menu.big_assets_receiving, big_asset.id, big_asset);
				}

			}
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
			pw := GUI.view(*state.menu.login_popup_password);
			state.menu.passstring = sprint(
				"% % %",
				slice(pw, 0, 4),
				slice(pw, 4, 7),
				slice(pw, 7, 11)
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

		if state.menu.terrain_name_selected_leaderboard
			free(state.menu.terrain_name_selected_leaderboard);
		state.menu.terrain_name_selected_leaderboard = sprint(
			"%", get_terrain_leaderboard.scene_name
		);

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
					"localhost", LOCAL_SERVER_PORT, "ws"
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
		push_main_menu(app_user, *app_user.gui_state, *state.menu);

		push_left_main_menu(*app_user.gui_state, *state.menu, _app.platform);
		// #if OS == .WASM {
		// 	version_string :: "0.0.1 (1 March 2026, 23:13:10)";
		// }
		GUI.default_params(*app_user.gui_state).cursor.x = controls.window_size.x - 12.0;
		GUI.default_params(*app_user.gui_state).cursor.y = 8.0;
		GUI.default_params(*app_user.gui_state).align = .Top_Right;
		GUI._atom_label(
			*app_user.gui_state,
			tprint("Version: %", version_string),
			id = "version_label",
			color = GUI.GRAY_00,
			offset_pos = v2(-4.0, 0.0),
			scale = 10
		);

		// Editor button
		editor_clicked, _, _ := GUI.text_button(
			*app_user.gui_state,
			"Level Editor",
			V2f.{ 20, controls.window_size.y - 40 },
			z = 5,
			id = "editor_btn"
		);
		if editor_clicked {
			state.screen_state = .Editor;
		}
	}

	frame := WRender.begin_frame(*framegraph, controls.time);
	WRender.render_gui(frame, *framegraph, app_user.gui_state, *store);
	WRender.end_frame(*framegraph, frame);

	return true;
}

push_create_instance_menu :: (
	app_user: *App_User,
	gui: *GUI.GUI_State,
	menu: *Menu
) {
	popup := GUI.begin_window(
		gui,
		gui.controls.window_size / 2,
		V2f.{ 1280, 720 },
		GUI.Align.Center,
		"create_instance_popup",
		10
	);

	GUI.atom_label(
		gui,
		"Create Instance",
		popup.pos + V2f.{ popup.size.x / 2, 4 },
		scale = 24,
		z = 10.1,
		align = GUI.Align.Top_Center,
		color = V4f.{ 0, 0, 0, 1 }
	);

	GUI.push_quad_screen(
		gui,
		popup.pos + V2f.{ 0, 32 },
		V2f.{ popup.size.x, 1 },
		v3(GUI.GRAY_10),
		z = 10.1
	);

	cursor := 32.0 + 8 + 8;

	content_aabb := pos_size(popup.pos + V2f.{ 8, 40 }, popup.size - V2f.{ 16, 32 + 16 });

	terrain_list_aabb := content_aabb;
	terrain_list_aabb = span_x(terrain_list_aabb, 0.0, 0.5);

	roster_list_aabb := content_aabb;
	roster_list_aabb = span_x(roster_list_aabb, 0.5, 0.75);

	param_aabb := content_aabb;
	param_aabb = span_x(param_aabb, 0.75, 1.0);

	draw_create_instance_terrain_panel(app_user, gui, menu, terrain_list_aabb);
	draw_create_instance_roster_panel(app_user, gui, menu, roster_list_aabb);
	draw_create_instance_param_panel(app_user, gui, menu, param_aabb);

	GUI.end_window(gui, "create_instance_popup");
}

push_create_bomberman_menu :: (
	app_user: *App_User,
	gui: *GUI.GUI_State,
	menu: *Menu
) {
	store := *app_user.store;
	platform := app_user.app.platform;

	popup := GUI.begin_window(
		gui,
		gui.controls.window_size / 2,
		V2f.{ 480, 720 },
		GUI.Align.Center,
		"create_bomberman_popup",
		10
	);

	GUI.atom_label(
		gui,
		"Create Bomberman",
		popup.pos + V2f.{ popup.size.x / 2, 4 },
		scale = 24,
		z = 10.1,
		align = GUI.Align.Top_Center,
		color = V4f.{ 0, 0, 0, 1 }
	);

	GUI.push_quad_screen(
		gui,
		popup.pos + V2f.{ 0, 32 },
		V2f.{ popup.size.x, 1 },
		v3(GUI.GRAY_10),
		z = 10.1
	);

	cursor := 32.0 + 8 + 8;

	content_aabb := pos_size(popup.pos + V2f.{ 8, 40 }, popup.size - V2f.{ 16, 32 + 16 });

	GUI.push_id(gui, 456);
	defer GUI.pop_id(gui);

	GUI.atom_label(
		gui,
		"Parameters",
		v2(content_aabb.min.x + 8, content_aabb.min.y + 8),
		scale = 16,
		color = GUI.GRAY_10,
		z = 26.2,
		align = .Top_Left
	);
	GUI.push_quad_screen(
		gui,
		pos = v2(content_aabb.min.x + 4, content_aabb.min.y + 32),
		size = v2(width(content_aabb) - 8, 1),
		color = v3(GUI.GRAY_20),
		z = 26.1
	);

	GUI.push_default_params(gui, GUI.default_params(gui).*);
	defer GUI.pop_default_params(gui);
	GUI.default_params(gui).cursor = v2(content_aabb.min.x + 8, content_aabb.min.y + 40);
	GUI.default_params(gui).direction = .Down;
	GUI.default_params(gui).align = .Top_Left;
	GUI.default_params(gui).z = 26.2;
	
	GUI.labeled_input_text(
		gui,
		"Name",
		*menu.create_bomberman.name,
		width(content_aabb) - 8,
		24,
		scale = 16,
		max_chars = 8,
		id = "instance_name_input",
	);

	menu.create_bomberman.private = GUI._labeled_checkbox(
		gui, "Private Instance", width(content_aabb) - 8, 16, id = "private_instance_checkbox"
	).checked;

	if menu.create_bomberman.private {
		GUI.labeled_input_text(
			gui,
			"Password",
			*menu.create_bomberman.password,
			width(content_aabb) - 8,
			24,
			scale = 16,
			placeholder = "****",
			max_chars = 8,
			id = "private_instance_password_input",
		);
	}

	menu.create_bomberman.max_players = GUI.labeled_int_input(
		gui,
		"Max players",
		width(content_aabb) - 8,
		24,
		menu.create_bomberman.max_players,
		1,
		64,
		id = "max_players_input"
	).value;

	GUI.default_params(gui).direction = .Left;
	GUI.default_params(gui).align = .Bottom_Right;
	GUI.default_params(gui).cursor = v2(content_aabb.max.x - 8, content_aabb.max.y - 8);
	create_clicked, create_button, create_widget := GUI._text_button(
		gui, "Create", id = "create_bomberman_button"
	);
	if create_clicked {
		command: Command.Create_Bomberman;
		string_to_array(GUI.view(*menu.create_bomberman.name), command.name);
		string_to_array(GUI.view(*menu.create_bomberman.password), command.password);
		command.private = menu.create_bomberman.private;
		command.max_players = menu.create_bomberman.max_players;
		send_web_message(platform, gui.controls.time, make_command(command));
		menu.create_bomberman.open = false;
	}

	cancel_clicked := GUI._text_button(
		gui, "Cancel", id = "cancel_create_instance_button"
	);
	if cancel_clicked
		menu.create_bomberman.open = false;

	GUI.end_window(gui, "create_bomberman_popup");
}

push_main_menu :: (
	app_user: *App_User,
	gui: *GUI.GUI_State,
	menu: *Menu
) {
	_app := app_user.app;

	GUI.push_quad_screen(
		gui,
		pos = .{ 0, 0 },
		size = gui.controls.window_size,
		color = v3(GUI.GRAY_80),
		z = 0.01
	);

	GUI.atom_label(
		gui,
		"Name game",
		.{ gui.controls.window_size.x / 2, 16 },
		32,
		z = 1,
		align = .Top_Center,
		color = V4f.{ 0, 0, 0, 1 }
	);
	GUI.push_quad_screen(
		gui,
		.{ 16, 64 },
		.{ gui.controls.window_size.x - 32, 1 },
		v3(GUI.GRAY_10),
		z = 0.02
	);
	Row :: struct {
		instance_name: string; @"name(\"Name\")" @"size(128)" @"align(Left)"
		players_count: string; @"name(\"# Players\")" @"align(Right)"
		level_name: string; @"name(\"Level name\")" @"align(Right)"
		auto_revive: bool; @"name(\"Auto-revive\")" @"align(Right)"
		private: bool; @"name(\"Private\")" @"align(Right)"
	}

	rows := NewArray(menu.instances_list.count, Row,, temp);
	for * rows {
		it.instance_name = string_from_arr(menu.instances_list[it_index].name);
		it.players_count = tprint(
			"% / %",
			formatInt(menu.instances_list[it_index].current_players, 10, 3, #char " "),
			formatInt(menu.instances_list[it_index].max_players, 10, 3, #char " ")
		);
		it.level_name = string_from_arr(menu.instances_list[it_index].level_name);
		it.auto_revive = menu.instances_list[it_index].auto_revive;
		it.private = menu.instances_list[it_index].private;
	}

	table := GUI.atom_table(
		gui,
		.{ gui.controls.window_size.x - 16, 64 + 16 },
		.{ 512 + 128, gui.controls.window_size.y - 64 - 16 - 16 - 32 },
		rows,
		id = "table",
		align = GUI.Align.Top_Right
	);

	selected_instance_id := -1;
	if table.selected_row_index >= 0 && table.selected_row_index < menu.instances_list.count {
		selected_instance_id = menu.instances_list[table.selected_row_index].instance_id;
	}

	lower_input_aabb := pos_size(
		V2f.{ table.aabb_min.x, table.aabb_max.y + 4 },
		V2f.{ table.aabb_max.x - table.aabb_min.x, 32 }
	);
	GUI.push_quad_screen(gui, lower_input_aabb, v3(GUI.GRAY_70), z = 0.02);

	text_button_state: GUI.Text_Button;
	cursor := V2f.{ table.aabb_min.x + 8, table.aabb_max.y + 4 + 16 };
	reload_instances_clicked:, text_button_state = GUI.text_button(
		gui, "Reload", cursor, 1, id = "reload", align = GUI.Align.Center_Left
	);
	if reload_instances_clicked {
		command: Command.Ask_Instance_List;
		send_web_message(_app.platform, gui.controls.time, make_command(command));
	}
	cursor.x += GUI.widget_width(gui, "reload") + 4;
	enter_instance_clicked:, text_button_state = GUI.text_button(
		gui, "Enter instance", cursor, 1, id = "enter_instance", align = GUI.Align.Center_Left
	);
	if enter_instance_clicked && selected_instance_id >= 0 {
		command: Command.Ask_Enter_Instance;
		command.instance_id = selected_instance_id;
		string_to_array(GUI.view(*menu.enter_instance_password), command.password);
		send_web_message(_app.platform, gui.controls.time, make_command(command));
	}
	cursor.x += GUI.widget_width(gui, "enter_instance") + 4;
	create_instance_clicked:, text_button_state = GUI.text_button(
		gui, "Create instance", cursor, 1, id = "create_instance", align = GUI.Align.Center_Left
	);
	if create_instance_clicked {
		menu.create_instance.open = !menu.create_instance.open;
	}
	cursor.x += GUI.widget_width(gui, "create_instance") + 4;
	cretate_bomberman_clicked:, text_button_state = GUI.text_button(
		gui, "Create Bomberman", cursor, 1, id = "create_bomberman", align = GUI.Align.Center_Left
	);
	if cretate_bomberman_clicked {
		menu.create_bomberman.open = !menu.create_bomberman.open;
	}

	input_text_aabb := pos_size(v2(0.0), v2(128.0, 24.0));
	input_text_aabb = GUI.align_aabb(
		input_text_aabb, shrink(lower_input_aabb, 4), GUI.Align.Bottom_Right
	);
	GUI.atom_input_text(
		gui,
		*menu.enter_instance_password,
		24,
		128.0,
		id = GUI.string_id("password_input"),
		placeholder = "Password",
		max_chars = 8,
		_z=1,
		_pos = input_text_aabb.min,
		_align = GUI.Align.Bottom_Left
	);

	cursor =  .{ 16, 64 + 16 };

	if menu.create_instance.open {
		push_create_instance_menu(app_user, gui, menu);
	}
	if menu.create_bomberman.open {
		push_create_bomberman_menu(app_user, gui, menu);
	}
}

draw_create_instance_param_panel :: (
	app: *App_User,
	gui: *GUI.GUI_State,
	menu: *Menu,
	aabb: AABBf
) {
	store := *app.store;
	platform := app.app.platform;

	GUI.push_id(gui, 456);
	defer GUI.pop_id(gui);

	// vertical separator
	GUI.push_quad_screen(
		gui,
		pos = v2(aabb.min.x - 1, aabb.min.y),
		size = v2(1.0, height(aabb)),
		color = v3(GUI.GRAY_20),
		z = 26.1
	);
	GUI.atom_label(
		gui,
		"Parameters",
		v2(aabb.min.x + 8, aabb.min.y + 8),
		scale = 16,
		color = GUI.GRAY_10,
		z = 26.2,
		align = .Top_Left
	);
	GUI.push_quad_screen(
		gui,
		pos = v2(aabb.min.x + 4, aabb.min.y + 32),
		size = v2(width(aabb) - 8, 1),
		color = v3(GUI.GRAY_20),
		z = 26.1
	);

	GUI.push_default_params(gui, GUI.default_params(gui).*);
	defer GUI.pop_default_params(gui);
	GUI.default_params(gui).cursor = v2(aabb.min.x + 8, aabb.min.y + 40);
	GUI.default_params(gui).direction = .Down;
	GUI.default_params(gui).align = .Top_Left;
	GUI.default_params(gui).z = 26.2;
	
	GUI.labeled_input_text(
		gui,
		"Name",
		*menu.create_instance.name,
		width(aabb) - 8,
		24,
		scale = 16,
		max_chars = 8,
		id = "instance_name_input",
	);

	create_instance_private := GUI._labeled_checkbox(
		gui, "Private Instance", width(aabb) - 8, 16, id = "private_instance_checkbox"
	).checked;

	if create_instance_private {
		GUI.labeled_input_text(
			gui,
			"Password",
			*menu.create_instance.password,
			width(aabb) - 8,
			24,
			scale = 16,
			placeholder = "****",
			max_chars = 8,
			id = "private_instance_password_input",
		);
	}

	create_instance_auto_revive := GUI._labeled_checkbox(
		gui,
		"Auto revive",
		width(aabb) - 8,
		16,
		id = "auto_revive_checkbox"
	).checked;

	GUI.default_params(gui).direction = .Left;
	GUI.default_params(gui).align = .Bottom_Right;
	GUI.default_params(gui).cursor = v2(aabb.max.x - 8, aabb.max.y - 8);
	create_clicked, create_button, create_widget := GUI._text_button(
		gui, "Create", id = "create_instance_button"
	);
	if create_clicked {
		command: Command.Create_Instance;
		string_to_array(GUI.view(*menu.create_instance.name), command.name);
		string_to_array(GUI.view(*menu.create_instance.password), command.password);
		command.auto_revive = menu.create_instance.auto_revive;
		command.private = menu.create_instance.private;
		command.roster = NewArray(menu.create_instance.roster_list.count, int,, temp);
		for menu.create_instance.roster_list {
			command.roster[it_index] = it.id;
		}
		send_web_message(app.app.platform, gui.controls.time, make_command(command));
		menu.create_instance.open = false;
	}

	cancel_clicked := GUI._text_button(
		gui, "Cancel", id = "cancel_create_instance_button"
	);
	if cancel_clicked
		menu.create_instance.open = false;

}


draw_create_instance_roster_panel :: (
	app: *App_User,
	gui: *GUI.GUI_State,
	menu: *Menu,
	aabb: AABBf
) {
	store := *app.store;
	platform := app.app.platform;
	GUI.push_id(gui, 123);
	defer GUI.pop_id(gui);

	// vertical separator
	GUI.push_quad_screen(
		gui,
		pos = v2(aabb.min.x - 1, aabb.min.y),
		size = v2(1.0, height(aabb)),
		color = v3(GUI.GRAY_20),
		z = 26.1
	);

	GUI.atom_label(
		gui,
		"Roster",
		v2(aabb.min.x + 8, aabb.min.y + 8),
		scale = 16,
		color = GUI.GRAY_10,
		z = 26.2,
		align = .Top_Left
	);
	GUI.push_quad_screen(
		gui,
		pos = v2(aabb.min.x + 4, aabb.min.y + 32),
		size = v2(width(aabb) - 8, 1),
		color = v3(GUI.GRAY_20),
		z = 26.1
	);

	cursor := v2(aabb.min.x, aabb.min.y);
	cursor.y += 40;
	terrain_entry_row_height := 64.0;
	terrain_entry_row_width := width(aabb);

	for * menu.create_instance.roster_list {
		GUI.push_id(gui, it_index);
		defer GUI.pop_id(gui);

		row_aabb := pos_size(
			cursor,
			v2(terrain_entry_row_width, terrain_entry_row_height)
		);

		GUI.push_quad_screen(gui, row_aabb, v3(GUI.GRAY_90));

		thumbnail_aabb: AABBf;
		thumbnail_aabb.min = row_aabb.min + v2(4.0, 4);
		thumbnail_aabb.max = thumbnail_aabb.min + v2(56.0, 56);
		quad := GUI.push_late_quad_screen(gui, thumbnail_aabb, GUI.GRAY_70);
		quad.custom_texture_idx = user_texture_idx_thumbnail_for(store, it.id);
		if quad.custom_texture_idx >= 0 {
			quad.texture_rect = v4(0.0, 0.0, 1, 1);
		}

		cal := platform.to_calendar(milliseconds_to_apollo(it.created_ms));
		date := tprint(
			"%/% %:%",
			cal.day_of_month_starting_at_0 + 1, cal.month_starting_at_0 + 1, cal.hour, cal.minute
		);
		GUI.atom_label(
			gui,
			it.name,
			row_aabb.min + v2(72.0, 10.0),
			scale = 16,
			color = GUI.GRAY_10,
			z = 26.2,
			align = .Top_Left
		);
		GUI.atom_label(
			gui,
			ifx it.author.count == 0 then "Anonymous" else it.author,
			row_aabb.min + v2(72.0, 36.0),
			scale = 14,
			color = GUI.GRAY_20,
			z = 26.2,
			align = .Top_Left
		);
		GUI.atom_label(
			gui,
			date,
			row_aabb.min + v2(terrain_entry_row_width - 78, 36.0),
			scale = 14,
			color = GUI.GRAY_20,
			align = .Top_Right,
			z = 26.2
		);

		if it_index < menu.create_instance.roster_list.count - 1
		&& menu.create_instance.roster_list.count > 1
		{
			clicked := GUI.text_button(
				gui,
				"Down",
				v2(row_aabb.max.x - 8, row_aabb.max.y - 12.0),
				id = "down_btn",
				z = 26.2,
				align = .Bottom_Right
			);
			if clicked {
				t := menu.create_instance.roster_list[it_index];
				menu.create_instance.roster_list[it_index] =
					menu.create_instance.roster_list[it_index + 1];
				menu.create_instance.roster_list[it_index + 1] = t;
			}
		}
		if it_index > 0 && menu.create_instance.roster_list.count > 1
		{
			clicked := GUI.text_button(
				gui,
				"Up",
				v2(row_aabb.max.x - 8, row_aabb.min.y + 12.0),
				id = "up_btn",
				z = 26.2,
				align = .Top_Right
			);
			if clicked {
				t := menu.create_instance.roster_list[it_index];
				menu.create_instance.roster_list[it_index] =
					menu.create_instance.roster_list[it_index - 1];
				menu.create_instance.roster_list[it_index - 1] = t;
			}
		}

		cursor.y += terrain_entry_row_height;
		cursor.y += 8;
	}
}

draw_create_instance_terrain_panel :: (
	app: *App_User,
	gui: *GUI.GUI_State,
	menu: *Menu,
	aabb: AABBf
) {
	platform := app.app.platform;
	store := *app.store;

	GUI.push_default_params(gui, GUI.default_params(gui).*);
	GUI.default_params(gui).z = 26;
	GUI.default_params(gui).align = .Top_Left;
	GUI.default_params(gui).cursor = v2(aabb.min.x + 4, aabb.min.y + 8);
	GUI.default_params(gui).direction = .Down;
	defer GUI.pop_default_params(gui);

	if GUI.labeled_input_text(
		gui,
		"Filter",
		*menu.create_instance.filter,
		width(aabb) - 8,
		16,
		max_input_width = 256,
		_z = 26,
		_align = .Top_Left
	).changed {
		ask_list_terrain: Command.Ask_List_Terrain;
		ask_list_terrain.filter = GUI.view(*menu.create_instance.filter);
		ask_list_terrain.correlation_id = 1;
		send_web_message(platform, gui.controls.time, make_command(ask_list_terrain));
	}
	GUI.push_quad_screen(
		gui,
		GUI.default_params(gui).cursor,
		v2(width(aabb) - 8, 1),
		v3(GUI.GRAY_20),
		z = 26
	);

	scroll_aabb := pos_size(
		v2(aabb.min.x + 4, aabb.min.y + 40),
		v2(width(aabb) - 8, height(aabb) - 80)
	);

	cursor := v2(scroll_aabb.min.x, scroll_aabb.min.y);
	terrain_entry_row_height := 64.0;
	terrain_entry_row_width := width(scroll_aabb);
	PAGE_SIZE :: 8;
	page_count := max((menu.create_instance.terrain_entries.count + PAGE_SIZE - 1) / PAGE_SIZE, 1);
	menu.create_instance.terrain_page = clamp(
		menu.create_instance.terrain_page,
		0,
		max((menu.create_instance.terrain_entries.count + PAGE_SIZE - 1) / PAGE_SIZE - 1, 0)
	);

	beg := menu.create_instance.terrain_page * PAGE_SIZE;
	end := beg + PAGE_SIZE;
	end = min(end, menu.create_instance.terrain_entries.count);
	terrain_list_view: []Create_Instance.Terrain_Entry;
	terrain_list_view.count = end - beg;
	terrain_list_view.data = menu.create_instance.terrain_entries.data + beg;
	for * terrain_list_view {
		GUI.push_id(gui, it_index);
		defer GUI.pop_id(gui);

		row_aabb := pos_size(
			cursor,
			v2(terrain_entry_row_width, terrain_entry_row_height)
		);

		state, widget := GUI.widget(gui, "row_button", struct {});
		widget.physical = .Mouse;
		widget.aabb = row_aabb;

		if widget.hovered {
			GUI.push_quad_screen(gui, row_aabb, v3(GUI.GRAY_40), z = 26.1);
		} else if it.selected {
			GUI.push_quad_screen(gui, row_aabb, v3(GUI.GRAY_50), z = 26.1);
		}
		if widget.just_pressed {
			if it.selected {
				it.selected = false;
				cursor := 0;
				for x: menu.create_instance.roster_list {
					if x.id == it.id
						continue;
					menu.create_instance.roster_list[cursor] = x;
					cursor += 1;
				}
				menu.create_instance.roster_list.count = cursor;
			} else {
				it.selected = true;
				array_add(*menu.create_instance.roster_list, it);
			}
		}

		GUI.push_quad_screen(gui, row_aabb, v3(GUI.GRAY_90));

		thumbnail_aabb: AABBf;
		thumbnail_aabb.min = row_aabb.min + v2(4.0, 4);
		thumbnail_aabb.max = thumbnail_aabb.min + v2(56.0, 56);
		quad := GUI.push_late_quad_screen(gui, thumbnail_aabb, GUI.GRAY_70);
		quad.custom_texture_idx = user_texture_idx_thumbnail_for(store, it.id);
		if quad.custom_texture_idx >= 0 {
			quad.texture_rect = v4(0.0, 0.0, 1, 1);
		}

		cal := platform.to_calendar(milliseconds_to_apollo(it.created_ms));
		date := tprint(
			"%/% %:%",
			cal.day_of_month_starting_at_0 + 1, cal.month_starting_at_0 + 1, cal.hour, cal.minute
		);
		GUI.atom_label(
			gui,
			it.name,
			row_aabb.min + v2(72.0, 10.0),
			scale = 16,
			color = GUI.GRAY_10,
			z = 26.2,
			align = .Top_Left
		);
		GUI.atom_label(
			gui,
			ifx it.author.count == 0 then "Anonymous" else it.author,
			row_aabb.min + v2(72.0, 36.0),
			scale = 14,
			color = GUI.GRAY_20,
			z = 26.2,
			align = .Top_Left
		);
		GUI.atom_label(
			gui,
			date,
			row_aabb.min + v2(terrain_entry_row_width - 78, 36.0),
			scale = 14,
			color = GUI.GRAY_20,
			align = .Top_Right,
			z = 26.2
		);

		cursor.y += terrain_entry_row_height;
		cursor.y += 8;
	}
	cursor.y = scroll_aabb.max.y;
	cursor.y += 8;
	GUI.default_params(gui).cursor.x = cursor.x + terrain_entry_row_width - 4;
	GUI.default_params(gui).cursor.y = cursor.y;
	GUI.default_params(gui).direction = .Left;
	GUI.default_params(gui).align = .Bottom_Right;

	clicked := GUI._text_button(gui, ">", id = "load_dialog_next_page");
	if clicked {
		menu.create_instance.terrain_page = (menu.create_instance.terrain_page + 1) % page_count;
	}
	clicked = GUI._text_button(gui, "<", id = "load_dialog_prev_page");
	if clicked {
		menu.create_instance.terrain_page = (menu.create_instance.terrain_page + page_count - 1) % page_count;
	}
}