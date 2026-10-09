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
	instances_page := 0;
	selected_instance_id := -1;

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
		state.menu.profile.id = connect.profile_id;
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
		state.menu.profile.stats = .{ win_count = get_profile_stats.stats.win_count, death_count = get_profile_stats.stats.death_count, revive_count = get_profile_stats.stats.revive_count };
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
		selected_index := -1;
		for state.menu.instances_list {
			if it.instance_id == state.menu.selected_instance_id selected_index = it_index;
		}
		if selected_index < 0 {
			state.menu.selected_instance_id = ifx state.menu.instances_list.count > 0 then state.menu.instances_list[0].instance_id else -1;
			selected_index = 0;
		}
		state.menu.instances_page = selected_index / 5;
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
			// Catalogue refreshes do not own or invalidate the chosen roster.
			for * state.menu.create_instance.terrain_entries {
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
				it.selected = create_instance_roster_index(*state.menu.create_instance, it.id) >= 0;

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
			state.menu.profile.id = login.profile_id;
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
		for state.menu.entries_leaderboard free(it.username);
		array_resize(*state.menu.entries_leaderboard, get_terrain_leaderboard.entries.count);
		for get_terrain_leaderboard.entries {
			entry := *state.menu.entries_leaderboard[it_index];
			entry.username = sprint("%", it.username);
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

lobby_nine_slice :: (
	texture: *WRender.WTexture,
	borders: V4f,
	scale: float32 = 0.8,
	fill_color := V4f.{ 0, 0, 0, 0 },
	fill_inset: float32 = 0.0
) -> GUI.Nine_Slice_Style {
	style: GUI.Nine_Slice_Style;
	style.texture = texture;
	style.texture_size = V2f.{ texture.width.(float32), texture.height.(float32) };
	style.borders = borders;
	style.scale = scale;
	style.fill_color = fill_color;
	style.fill_inset = fill_inset;
	return style;
}

// Floating title plaques are decorations; they do not consume layout space.
push_lobby_panel :: (
	gui: *GUI.GUI_State, store: *Store, bounds: AABBf, title: string, z: float
) {
	GUI.push_felt_panel(gui, store, bounds.min, bounds.max - bounds.min, z);
	if title.count == 0 return;
	title_size := V2f.{ ifx equal(title, "GAME ROOMS") then 230.0 else 180.0, 32 };
	title_pos := v2((bounds.min.x + bounds.max.x - title_size.x) / 2, bounds.min.y - 13);
	skin := lobby_nine_slice(
		*store.lobby_button_frame,
		.{ 20, 20, 20, 20 },
		fill_color = GUI.LOBBY_BUTTON_DARK,
		fill_inset = 12
	);
	skin.center_mode = .Transparent;
	GUI.push_nine_slice(gui, title_pos, title_size, skin, z + 0.1);
	GUI.atom_label(
		gui, title, title_pos + title_size / 2, 17, z + 0.2, .Center,
		GUI.GOLD_ACCENT, id = GUI.string_id(tprint("panel_title_%", title))
	);
}

lobby_panel_begin :: (
	gui: *GUI.GUI_State, store: *Store, size: V2f, title := "",
	z := 2.0, inset := V2f.{ 18, 28 }, gap := V2f.{ 0, 6 }
) {
	bounds := GUI.box(gui, size, inset = inset, gap = gap, z = z + 0.5);
	push_lobby_panel(gui, store, bounds, title, z);
}

lobby_table_style :: (store: *Store, selected_rows := false) -> GUI.Table_Style {
	style: GUI.Table_Style;
	style.vertical_rules = false;
	style.dashed_header = false;
	style.header_size = 10;
	style.compact_icons = true;
	style.button_skin = GUI.compact_button_skin(store);
	style.selectable = selected_rows;
	style.background_color = GUI.LOBBY_TABLE_BACKGROUND;
	style.left_rail_color = .{ 0, 0, 0, 0 };
	style.header_color = GUI.GOLD_ACCENT;
	style.text_color = GUI.TEXT_NORMAL;
	style.separator_color = GUI.LOBBY_SEPARATOR;
	style.selected_color = GUI.LOBBY_ROW_SELECTED;
	style.hover_color = GUI.LOBBY_ROW_HOVER;
	return style;
}

lobby_button :: (
	gui: *GUI.GUI_State, text: string, id: string, store: *Store, size: V2f,
	font_size := 13.0, fill_color := GUI.LOBBY_BUTTON_DARK,
	icon := V2f.{ -1, -1 }, enabled := true
) -> bool, bool {
	clicked, pressed := GUI.themed_button(gui, store, text, id, size, fill_color, icon, enabled, font_size);
	return clicked, pressed;
}

draw_lobby_header :: (gui: *GUI.GUI_State, menu: *Menu, store: *Store) {
	lobby_panel_begin(gui, store, .{ 1318, 68 }, z = 1, inset = .{ 14, 12 }, gap = .{});
	GUI.box(gui, .{ 1290, 44 }, .Right);

	GUI.box(gui, .{ 360, 44 }, .Right, gap = .{ 8, 0 });
	GUI.box(gui, .{ 48, 32 }, .Down);
	GUI.space(gui, 6);
	if lobby_button(gui, "Login", "lobby_login", store, .{ 48, 32 }, 11) {
		menu.login_popup_open = true;
		menu.create_instance.open = false;
		menu.create_bomberman.open = false;
	}
	GUI.end(gui);
	GUI.box(gui, .{ 48, 32 }, .Down);
	GUI.space(gui, 6);
	_, reveal_pressed := lobby_button(
		gui, "", "lobby_reveal_passcode", store, .{ 38, 32 }, icon = GUI.EYE_SLOT
	);
	GUI.end(gui);
	passcode_text := "____ ___ ____";
	if reveal_pressed && menu.passstring.count > 0 passcode_text = menu.passstring;
	GUI.box(gui, .{ 160, 40 });
		GUI.space(gui, 8);
		GUI.label_box(
			gui, "YOUR PASSCODE", .{ 160, 14 }, 9, GUI.GOLD_ACCENT, id = "lobby_passcode_label"
		);
		GUI.label_box(
			gui, passcode_text, .{ 160, 14 }, 13, GUI.TEXT_NORMAL, id = "lobby_passcode_value", align = .Bottom_Left
		);
	GUI.end(gui);
	GUI.end(gui);

	GUI.box(gui, .{ 570, 44 });
	GUI.label_box(gui, "ADARENA", .{ 570, 48 }, 30, GUI.GOLD_ACCENT, .Center, "lobby_brand_title");
	GUI.end(gui);
	GUI.end(gui);
	GUI.end(gui);
}

draw_lobby_left :: (
	gui: *GUI.GUI_State, menu: *Menu, platform: *Platform, store: *Store
) {
	GUI.box(gui, .{ 536, 588 }, gap = .{ 0, 22 });
	lobby_panel_begin(gui, store, .{ 536, 116 }, "ACCOUNT", gap = .{ 0, 12 });
	GUI.box(gui, .{ 500, 30 }, .Right, gap = .{ 10, 0 });
	GUI.label_box(gui, "Username", .{ 68, 30 }, 11, GUI.GOLD_ACCENT, id = "lobby_username_label");
	username_input := GUI.input_text(gui, *menu.username, 30, width = 422, id = "username_input",
		max_chars = 32, placeholder = "Enter a name", dark_style = true, margin = 10);
	GUI.end(gui);
	if username_input.changed {
		command: Command.Set_Username;
		command.profile_id = menu.profile.id;
		command.username = GUI.view(*menu.username);
		send_web_message(platform, gui.controls.time, make_command(command));
	}
	GUI.label_box(gui, "The lobby is ready. Choose a map or join a room.", .{ 500, 26 }, 11,
		GUI.TEXT_MUTE, id = "lobby_account_note");
	GUI.end(gui);

	lobby_panel_begin(gui, store, .{ 536, 234 }, "MAPS");
	PAGE_SIZE :: 5;
	page_count := max((menu.terrain_entries.count + PAGE_SIZE - 1) / PAGE_SIZE, 1);
	menu.terrain_entries_page = clamp(menu.terrain_entries_page, 0, page_count - 1);
	GUI.box(gui, .{ 500, 28 }, .Right, gap = .{ 8, 0 });
	map_filter := GUI.input_text(gui, *menu.scene_name_leadeboard, 28, width = 350,
		id = "scene_name_leaderboard_input", max_chars = 48, placeholder = "Find a map...",
		dark_style = true, margin = 10);
	if map_filter.changed {
		menu.terrain_entries_page = 0;
		command: Command.Ask_List_Terrain;
		command.filter = GUI.view(*menu.scene_name_leadeboard);
		command.correlation_id = 0;
		send_web_message(platform, gui.controls.time, make_command(command));
	}
	GUI.box(gui, .{ 96, 28 }, .Right, gap = .{ 4, 0 });
	if lobby_button(gui, "<", "maps_previous", store, .{ 24, 28 }, 11,
		enabled = menu.terrain_entries_page > 0)
		menu.terrain_entries_page -= 1;
	GUI.label_box(gui, tprint("% / %", menu.terrain_entries_page + 1, page_count),
		.{ 40, 28 }, 10, GUI.TEXT_MUTE, .Center, "map_page");
	if lobby_button(gui, ">", "maps_next", store, .{ 24, 28 }, 11,
		enabled = menu.terrain_entries_page + 1 < page_count)
		menu.terrain_entries_page += 1;
	GUI.end(gui);
	GUI.label_box(gui, tprint("% maps", menu.terrain_entries.count), .{ 38, 28 }, 8,
		GUI.TEXT_MUTE, .Center_Right, "lobby_map_count");
	GUI.end(gui);

	Row_Terrain :: struct {
		name: string; @name("Map") @size(208)
		author: string; @name("Author") @size(136)
		leaderboard: string; @name("Records") @size(68) @align(Center) @button @icon(5,13)
		play: string; @name("Play") @size(64) @align(Center) @button @icon(11,15)
	}
	page_begin := menu.terrain_entries_page * PAGE_SIZE;
	page_end := min(page_begin + PAGE_SIZE, menu.terrain_entries.count);
	rows := NewArray(page_end - page_begin, Row_Terrain,, temp);
	for page_begin..page_end - 1 {
		entry := menu.terrain_entries[it];
		rows[it - page_begin] = .{ entry.name, ifx entry.author.count > 0 then entry.author else "-", "T", ">" };
	}
	map_skin := lobby_table_style(store);
	table := GUI.table(gui, rows, .{ 500, 156 }, id = "terrain_table", row_height = 26, skin = *map_skin);
	if table.clicked_row_index >= 0 && table.clicked_row_index < rows.count {
		entry := menu.terrain_entries[page_begin + table.clicked_row_index];
		if table.clicked_col_index == 2 {
			command: Command.Get_Terrain_Leaderboard;
			command.terrain_id = entry.id;
			send_web_message(platform, gui.controls.time, make_command(command));
		} else if table.clicked_col_index == 3 {
			command: Command.Ask_Enter_Quick_Instance;
			command.terrain_id = entry.id;
			send_web_message(platform, gui.controls.time, make_command(command));
		}
	}
	GUI.end(gui);

	lobby_panel_begin(gui, store, .{ 536, 194 }, "LEADERBOARD");
	caption := "No map selected";
	if menu.terrain_name_selected_leaderboard.count > 0
		caption = tprint("Records for: %", menu.terrain_name_selected_leaderboard);
	GUI.label_box(gui, GUI.fit_text(gui, caption, 11, 500), .{ 500, 18 }, 11,
		GUI.TEXT_NORMAL, id = "leaderboard_label");
	Row_Leaderboard :: struct {
		username: string; @name("Player") @size(228)
		time_ms: string; @name("Time") @size(98)
		timestamp_ms: string; @name("Date") @size(154) @align(Right)
	}
	count := min(menu.entries_leaderboard.count, 6);
	records := NewArray(count, Row_Leaderboard,, temp);
	for 0..count - 1 {
		entry := menu.entries_leaderboard[it];
		record := *records[it];
		record.username = ifx entry.username.count > 0 then entry.username else "Anonymous";
		record.time_ms = tprint("%1.%2%3%4", entry.time_ms / 1000, entry.time_ms % 1000 / 100, entry.time_ms % 100 / 10, entry.time_ms % 10);
		cal := platform.to_calendar(milliseconds_to_apollo(entry.timestamp_ms));
		record.timestamp_ms = tprint("%/% %:%", cal.day_of_month_starting_at_0 + 1, cal.month_starting_at_0 + 1, cal.hour, cal.minute);
	}
	leader_skin := lobby_table_style(store);
	GUI.table(gui, records, .{ 500, ifx count > 0 then 126.0 else 18.0 },
		id = "leaderboard_table", row_height = 18, skin = *leader_skin);
	if count == 0 {
		empty_text := ifx menu.terrain_name_selected_leaderboard.count > 0 then
			"No records for this map yet." else "Choose a map's trophy to view its records.";
		GUI.label_box(gui, empty_text, .{ 500, 40 }, 11,
			GUI.TEXT_MUTE, .Center, "leaderboard_empty");
	}
	GUI.end(gui);
	GUI.end(gui);
}

draw_lobby_rooms :: (
	gui: *GUI.GUI_State, menu: *Menu, platform: *Platform, store: *Store
) {
	lobby_panel_begin(gui, store, .{ 762, 588 }, "GAME ROOMS",
		inset = .{ 18, 30 }, gap = .{ 0, 12 });
	GUI.box(gui, .{ 726, 44 }, .Right);
	GUI.box(gui, .{ 620, 44 });
	GUI.label_box(gui, "FIND YOUR NEXT ADVENTURE", .{ 620, 18 }, 9,
		GUI.GOLD_ACCENT, id = "lobby_room_subtitle");
	GUI.label_box(gui, "Choose a room and brave the ice together.", .{ 620, 26 }, 11,
		GUI.TEXT_MUTE, id = "lobby_room_description");
	GUI.end(gui);
	GUI.label_box(gui, tprint("% rooms", menu.instances_list.count), .{ 106, 44 }, 10,
		GUI.TEXT_NORMAL, .Center_Right, "lobby_room_count");
	GUI.end(gui);

	ROOM_PAGE_SIZE :: 5;
	page_count := max((menu.instances_list.count + ROOM_PAGE_SIZE - 1) / ROOM_PAGE_SIZE, 1);
	menu.instances_page = clamp(menu.instances_page, 0, page_count - 1);
	page_begin := menu.instances_page * ROOM_PAGE_SIZE;
	page_end := min(page_begin + ROOM_PAGE_SIZE, menu.instances_list.count);
	Room_Row :: struct {
		instance_name: string; @name("Room") @size(204)
		players_count: string; @name("Players") @size(84) @align(Center)
		level_name: string; @name("Level") @size(170)
		auto_revive: string; @name("Auto-revive") @size(134) @align(Center)
		access: string; @name("Access") @size(110) @align(Center)
	}
	rows := NewArray(page_end - page_begin, Room_Row,, temp);
	selected := 0;
	for page_begin..page_end - 1 {
		room := *menu.instances_list[it];
		row := *rows[it - page_begin];
		row.instance_name = string_from_arr(room.name);
		row.players_count = tprint("% / %", room.current_players, room.max_players);
		row.level_name = string_from_arr(room.level_name);
		row.auto_revive = ifx room.auto_revive then "ON" else "-";
		row.access = ifx room.private then "Private" else "Public";
		if room.instance_id == menu.selected_instance_id selected = it - page_begin;
	}
	GUI.box(gui, .{ 726, 300 }, gap = .{ 0, 8 });
	skin := lobby_table_style(store, selected_rows = true);
	table := GUI.table(gui, rows, .{ 726, 264 }, id = "table",
		row_height = 40, skin = *skin, selected_row = *selected);
	if page_count > 1 {
		GUI.row(gui);
		if lobby_button(gui, "<", "lobby_rooms_previous", store, .{ 28, 28 },
			enabled = menu.instances_page > 0) menu.instances_page -= 1;
		GUI.label_box(gui, tprint("% / %", menu.instances_page + 1, page_count),
			.{ 80, 28 }, 11, GUI.TEXT_NORMAL, .Center, "lobby_room_page");
		if lobby_button(gui, ">", "lobby_rooms_next", store, .{ 28, 28 },
			enabled = menu.instances_page + 1 < page_count) menu.instances_page += 1;
		GUI.end(gui);
	}
	GUI.end(gui);

	selected_id := -1;
	room_name := "No rooms available";
	room_details := "Create a room to get started";
	is_private := false;
	is_full := false;
	if table.selected_row_index >= 0 && table.selected_row_index < rows.count {
		room := *menu.instances_list[page_begin + table.selected_row_index];
		selected_id = room.instance_id;
		room_name = string_from_arr(room.name);
		is_private = room.private;
		is_full = room.current_players >= room.max_players;
		room_details = tprint("%  -  % open places  -  %",
			string_from_arr(room.level_name), max(room.max_players - room.current_players, 0),
			ifx room.private then "Private room" else "Public room");
	}
	menu.selected_instance_id = selected_id;
	GUI.box(gui, .{ 726, 72 });
	GUI.horizontal_rule(gui, 726);
	GUI.space(gui, 7);
	GUI.box(gui, .{ 726, 64 }, .Right);
	GUI.box(gui, .{ 580, 64 });
	GUI.label_box(gui, "SELECTED ROOM", .{ 580, 16 }, 9, GUI.GOLD_ACCENT, id = "lobby_selected_room_caption");
	GUI.label_box(gui, GUI.fit_text(gui, room_name, 20, 570), .{ 580, 30 }, 20,
		GUI.TEXT_NORMAL, id = "lobby_selected_room_name");
	GUI.label_box(gui, GUI.fit_text(gui, room_details, 10, 570), .{ 580, 18 }, 10,
		GUI.TEXT_MUTE, id = "lobby_selected_room_details");
	GUI.end(gui);
	GUI.label_box(gui, ifx is_full then "Room full" else (ifx selected_id >= 0 then "Ready to join" else "Select a room"),
		.{ 146, 64 }, 9, GUI.LOBBY_READY, .Center_Right, "lobby_room_ready");
	GUI.end(gui);
	GUI.end(gui);

	GUI.box(gui, .{ 726, 40 }, .Right, gap = .{ 12, 0 });
	GUI.input_text(gui, *menu.enter_instance_password, 40, width = 526, id = "password_input",
		placeholder = ifx is_private then "Password required" else "No password required",
		password_mask = true, max_chars = 8, dark_style = true, margin = 10);
	if lobby_button(gui, "Enter instance", "enter_instance", store, .{ 188, 40 },
		fill_color = GUI.LOBBY_ACTION_OLIVE, enabled = selected_id >= 0 && !is_full) {
		command: Command.Ask_Enter_Instance;
		command.instance_id = selected_id;
		string_to_array(GUI.view(*menu.enter_instance_password), command.password);
		send_web_message(platform, gui.controls.time, make_command(command));
	}
	GUI.end(gui);

	GUI.box(gui, .{ 726, 36 }, .Right, gap = .{ 10, 0 });
	if lobby_button(gui, "", "reload_instances", store, .{ 36, 36 }, icon = GUI.RELOAD_SLOT) {
		command: Command.Ask_Instance_List;
		send_web_message(platform, gui.controls.time, make_command(command));
	}
	if lobby_button(gui, "Create instance", "create_instance", store, .{ 335, 36 },
		fill_color = GUI.LOBBY_ACTION_BLUE) {
		menu.create_instance.open = true;
		menu.create_bomberman.open = false;
		menu.login_popup_open = false;
	}
	if lobby_button(gui, "Create Bomberman", "create_bomberman", store, .{ 335, 36 }) {
		menu.create_bomberman.open = true;
		menu.create_instance.open = false;
		menu.login_popup_open = false;
	}
	GUI.end(gui);
	GUI.end(gui);
}

draw_lobby_right :: (
	app_user: *App_User, gui: *GUI.GUI_State, menu: *Menu, store: *Store
) {
	platform := app_user.app.platform;
	stack_depth := gui.flow_stack.count;
	GUI.push_quad_screen(gui, .{ 0, 0 }, gui.controls.window_size, GUI.LOBBY_BACKGROUND, z = 0.01);
	GUI.column(gui, .{ 24, 14 }, z = 1, align = .Top_Left);
	GUI.flow(gui).padding = .{};
	draw_lobby_header(gui, menu, store);
	GUI.space(gui, 26);
	GUI.box(gui, .{ 1318, 588 }, .Right, gap = .{ 20, 0 });
	draw_lobby_left(gui, menu, platform, store);
	draw_lobby_rooms(gui, menu, platform, store);
	GUI.end(gui);
	GUI.space(gui, 16);
	GUI.box(gui, .{ 1318, 34 }, .Right, z = 5);
	GUI.box(gui, .{ 360, 34 });
	if lobby_button(gui, "Level editor", "editor_btn", store, .{ 136, 34 }, 12)
		app_user.state.screen_state = .Editor;
	GUI.end(gui);
	GUI.label_box(gui, tprint("Version: %", version_string), .{ 360, 34 }, 9,
		GUI.TEXT_MUTE, .Center_Right, "version_label");
	GUI.end(gui);
	GUI.end(gui);
	assert(gui.flow_stack.count == max(stack_depth, 1));

	if menu.create_instance.open push_create_instance_menu(app_user, gui, menu);
	if menu.create_bomberman.open push_create_bomberman_menu(app_user, gui, menu);
	if menu.login_popup_open {
		window := GUI.begin_window(gui, gui.controls.window_size / 2, .{ 400, 300 },
			id = "login_window", z = 10, modal = true, store = store);
		defer GUI.end_window(gui, id = "login_window");
		GUI.labeled_input_text(gui, "Passcode:", *menu.login_popup_password, 400 - 16, 24,
			id = "login_passcode_input", placeholder = "0123456789A", label_color = GUI.TEXT_NORMAL,
			skin = GUI.compact_button_skin(store, GUI.LOBBY_BUTTON_DARK), dark_style = true);
		GUI.row(gui,
			window.pos + v2(window.size.x - 8.0 - (112 * 2 + 16), window.size.y - 8.0 - 36),
			.Right, align = .Bottom_Left);
		defer GUI.end(gui);
		if GUI.themed_button(gui, store, "Cancel", "login_cancel_btn", .{ 112, 36 })
			menu.login_popup_open = false;
		GUI.space(gui, 16);
		if GUI.themed_button(gui, store, "Login", "login_confirm_btn", .{ 112, 36 }, GUI.LOBBY_ACTION_BLUE) {
			command: Command.Login;
			command.passcode = string_to_code(GUI.view(*menu.login_popup_password));
			command.token = platform.get_token();
			send_web_message(platform, gui.controls.time, make_command(command));
			menu.login_popup_open = false;
		}
	}
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
		GUI.MENU_BASE_BACKGROUND,
		0,
	);

	if !state.is_connected && !app_user.end_level_preview.active {
		no_connection_ret := GUI.push_no_connection(*app_user.gui_state, *app_user.store);

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
		draw_lobby_right(app_user, *app_user.gui_state, *state.menu, *app_user.store);
	}

	push_end_level_preview(app_user);
	draw_console(*app_user.console, *app_user.gui_state);

	frame := WRender.begin_frame(*framegraph, controls.time);
	WRender.render_gui(frame, *framegraph, app_user.gui_state, *store);
	WRender.end_frame(*framegraph, frame);

	return true;
}

push_create_instance_menu :: (app_user: *App_User, gui: *GUI.GUI_State, menu: *Menu) {
	size := V2f.{ min(1280.0, gui.controls.window_size.x - 32), min(720.0, gui.controls.window_size.y - 32) };
	popup := GUI.begin_window(gui, gui.controls.window_size / 2, size, .Center,
		"create_instance_popup", 10, modal = true, store = *app_user.store);
	defer GUI.end_window(gui, "create_instance_popup");
	GUI.box(gui, popup.size - v2(16.0), inset = v2(16.0));
	defer GUI.end(gui);
	content_width := popup.size.x - 48;
	content_height := popup.size.y - 48;
	GUI.label_box(gui, "Create Instance", .{ content_width, 32 }, 24, GUI.GOLD_ACCENT, .Center, "title");
	GUI.horizontal_rule(gui, content_width);
	GUI.space(gui, 12);

	Drag :: struct {
		terrain_id: int = -1;
		press_pos: V2f;
		moved: bool;
	}
	drag, _ := GUI.widget(gui, "terrain_drag", Drag);
	if drag.terrain_id >= 0 && norm(gui.controls.mouse_pos - drag.press_pos) > 6 drag.moved = true;
	GUI.box(gui, .{ content_width, content_height - 45 }, .Right, gap = .{ 12, 0 }, z = 11);
	defer GUI.end(gui);
	param_width := min(288.0, content_width * 0.25);
	list_width := (content_width - param_width - 24) * 0.54;
	roster_width := content_width - param_width - list_width - 24;
	panel_height := content_height - 45;
	pressed_id := draw_create_instance_terrain_panel(app_user, gui, menu, .{ list_width, panel_height }, drag.moved);
	if pressed_id >= 0 {
		drag.terrain_id = pressed_id;
		drag.press_pos = gui.controls.mouse_pos;
		drag.moved = false;
	}
	roster_bounds, roster_page, page_size := draw_create_instance_roster_panel(app_user, gui, menu, .{ roster_width, panel_height });
	draw_create_instance_param_panel(app_user, gui, menu, .{ param_width, panel_height });

	// Dragging inserts into the visible roster; an ordinary row click also adds it.
	if drag.terrain_id >= 0 {
		over_roster := in(roster_bounds, gui.controls.mouse_pos);
		index := min(menu.create_instance.roster_list.count, roster_page * page_size +
			max(0, floor((gui.controls.mouse_pos.y - roster_bounds.min.y + 42) / 84).(int)));
		if drag.moved && over_roster {
			y := min(roster_bounds.max.y - 2, roster_bounds.min.y + (index - roster_page * page_size) * 84);
			GUI.push_quad_screen(gui, .{ roster_bounds.min.x, y }, .{ width(roster_bounds), 2 }, v3(GUI.GOLD_ACCENT), 12);
		}
		if gui.controls.just_released[Key.MouseLeft] {
			if drag.moved && over_roster for entry: menu.create_instance.terrain_entries {
				if entry.id == drag.terrain_id {
					add_create_instance_terrain(*menu.create_instance, entry, index);
					break;
				}
			}
			drag.terrain_id = -1;
			drag.moved = false;
		} else if !gui.controls.pressed[Key.MouseLeft] {
			drag.terrain_id = -1;
			drag.moved = false;
		} else if drag.moved {
			for entry: menu.create_instance.terrain_entries if entry.id == drag.terrain_id {
				GUI.atom_label(gui, GUI.fit_text(gui, entry.name, 14, 240),
					gui.controls.mouse_pos + v2(16.0, 12.0), 14, 12.1, .Top_Left, GUI.GOLD_ACCENT, outline = true);
				break;
			}
		}
	}
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
		V2f.{ 480, 400 },
		GUI.Align.Center,
		"create_bomberman_popup",
		10, modal = true, store = store
	);
	defer GUI.end_window(gui, "create_bomberman_popup");

	GUI.atom_label(
		gui,
		"Create Bomberman",
		popup.pos + V2f.{ popup.size.x / 2, 4 },
		scale = 24,
		z = 10.1,
		align = GUI.Align.Top_Center,
		color = GUI.GOLD_ACCENT
	);

	GUI.push_quad_screen(
		gui,
		popup.pos + V2f.{ 0, 32 },
		V2f.{ popup.size.x, 1 },
		v3(GUI.LOBBY_SEPARATOR),
		z = 10.1
	);

	cursor := 32.0 + 8 + 8;

	content_aabb := pos_size(popup.pos + V2f.{ 40, 40 }, popup.size - V2f.{ 80, 80 });

	GUI.push_id(gui, 456);
	defer GUI.pop_id(gui);

	GUI.atom_label(
		gui,
		"Parameters",
		v2(content_aabb.min.x + 8, content_aabb.min.y + 8),
		scale = 16,
		color = GUI.GOLD_ACCENT,
		z = 26.2,
		align = .Top_Left
	);
	GUI.push_quad_screen(
		gui,
		pos = v2(content_aabb.min.x + 4, content_aabb.min.y + 32),
		size = v2(width(content_aabb) - 8, 1),
		color = v3(GUI.LOBBY_SEPARATOR),
		z = 26.1
	);

	GUI.column(gui, v2(content_aabb.min.x + 8, content_aabb.min.y + 40), z = 26.2, align = .Top_Left);
	defer GUI.end(gui);
	
	GUI.labeled_input_text(
		gui,
		"Name",
		*menu.create_bomberman.name,
		width(content_aabb) - 8,
		24,
		scale = 16,
		max_chars = 8,
		id = "instance_name_input",
		label_color = GUI.TEXT_NORMAL,
		skin = GUI.compact_button_skin(store, GUI.LOBBY_BUTTON_DARK), dark_style = true,
	);

	menu.create_bomberman.private = GUI.labeled_checkbox(
		gui, "Private Instance", width(content_aabb) - 8, 16, id = "private_instance_checkbox",
		label_color = GUI.TEXT_NORMAL, skin = GUI.compact_button_skin(store, GUI.LOBBY_BUTTON_DARK)
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
			label_color = GUI.TEXT_NORMAL,
			skin = GUI.compact_button_skin(store, GUI.LOBBY_BUTTON_DARK), dark_style = true,
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
		id = "max_players_input",
		label_color = GUI.TEXT_NORMAL,
		skin = GUI.compact_button_skin(store, GUI.LOBBY_BUTTON_DARK)
	).value;

	GUI.row(gui, v2(content_aabb.max.x - 8 - (116 * 2 + 16), content_aabb.max.y - 8),
		.Right, align = .Bottom_Left);
	defer GUI.end(gui);
	create_clicked, _ := GUI.themed_button(gui, store, "Create", "create_bomberman_button",
		.{ 116, 36 }, GUI.LOBBY_ACTION_BLUE);
	if create_clicked {
		command: Command.Create_Bomberman;
		string_to_array(GUI.view(*menu.create_bomberman.name), command.name);
		string_to_array(GUI.view(*menu.create_bomberman.password), command.password);
		command.private = menu.create_bomberman.private;
		command.max_players = menu.create_bomberman.max_players;
		send_web_message(platform, gui.controls.time, make_command(command));
		menu.create_bomberman.open = false;
	}

	GUI.space(gui, 16);
	cancel_clicked, _ := GUI.themed_button(gui, store, "Cancel", "cancel_create_instance_button", .{ 116, 36 });
	if cancel_clicked
		menu.create_bomberman.open = false;

}

create_instance_roster_index :: (create: *Create_Instance, terrain_id: int) -> int {
	for create.roster_list if it.id == terrain_id return it_index;
	return -1;
}

add_create_instance_terrain :: (create: *Create_Instance, entry: Create_Instance.Terrain_Entry, index: int = -1) {
	if create_instance_roster_index(create, entry.id) >= 0 return;
	owned := entry;
	owned.name = copy_string(entry.name);
	owned.author = copy_string(entry.author);
	owned.selected = true;
	index = ifx index < 0 then create.roster_list.count else clamp(index, 0, create.roster_list.count);
	array_add(*create.roster_list, owned);
	for reverse: 0..create.roster_list.count - index - 2 {
		i := create.roster_list.count - reverse - 1;
		create.roster_list[i] = create.roster_list[i - 1];
	}
	create.roster_list[index] = owned;
}

remove_create_instance_terrain :: (create: *Create_Instance, index: int) {
	if index < 0 || index >= create.roster_list.count return;
	free(create.roster_list[index].name);
	free(create.roster_list[index].author);
	for i: index..create.roster_list.count - 2 create.roster_list[i] = create.roster_list[i + 1];
	create.roster_list.count -= 1;
}

// Shared card contents keep labels, thumbnails and actions inside their column.
draw_create_instance_terrain_card :: (
	app: *App_User, gui: *GUI.GUI_State, entry: Create_Instance.Terrain_Entry, size: V2f,
	selected: bool, roster_index: int = -1, roster_count: int = 0, dragging := false
) -> int, bool {
	GUI.push_id(gui, entry.id);
	defer GUI.pop_id(gui);
	bounds := GUI.box(gui, size, .Right, inset = v2(6.0), gap = .{ 8, 0 });
	defer GUI.end(gui);
	z := GUI.flow(gui).z;
	_, widget := GUI.widget_sized(gui, "terrain_card", struct {}, bounds, z,
		ifx roster_index < 0 then GUI.GUI_State.Widget.Physical.Mouse_Left else .Empty);
	color := ifx widget.hovered then GUI.LOBBY_ROW_HOVER else
		(ifx selected then GUI.LOBBY_ROW_SELECTED else GUI.LOBBY_BUTTON_DARK);
	GUI.push_quad_screen(gui, bounds, v3(color), z, a = 0.95);

	action_width := min(ifx roster_index >= 0 then 88.0 else 56.0, size.x * 0.4);
	thumbnail_width := min(48.0, max(0.0, size.x - 28 - action_width - 80));
	if thumbnail_width > 0 {
		thumbnail := GUI.box(gui, .{ thumbnail_width, 64 });
		quad := GUI.push_late_quad_screen(gui, thumbnail.min + v2(0.0, (64 - thumbnail_width) / 2), v2(thumbnail_width), GUI.GRAY_70, z + 0.05);
		quad.custom_texture_idx = user_texture_idx_thumbnail_for(*app.store, entry.id);
		if quad.custom_texture_idx >= 0 quad.texture_rect = .{ 0, 0, 1, 1 };
		GUI.end(gui);
	}
	text_width := max(1.0, size.x - 20 - action_width - (ifx thumbnail_width > 0 then thumbnail_width + 8 else 0));
	GUI.box(gui, .{ text_width, 64 }, z = z + 0.1);
	name := ifx roster_index >= 0 then tprint("%. %", roster_index + 1, entry.name) else entry.name;
	GUI.label_box(gui, GUI.fit_text(gui, name, 16, text_width), .{ text_width, 24 }, 16, GUI.TEXT_NORMAL, id = "name");
	GUI.label_box(gui, GUI.fit_text(gui, ifx entry.author.count > 0 then entry.author else "Anonymous", 13, text_width),
		.{ text_width, 20 }, 13, GUI.TEXT_MUTE, id = "author");
	cal := app.app.platform.to_calendar(milliseconds_to_apollo(entry.created_ms));
	date := tprint("%/% %:%", cal.day_of_month_starting_at_0 + 1, cal.month_starting_at_0 + 1, cal.hour, cal.minute);
	GUI.label_box(gui, GUI.fit_text(gui, date, 11, text_width), .{ text_width, 20 }, 11, GUI.TEXT_MUTE, id = "date");
	GUI.end(gui);
	GUI.box(gui, .{ action_width, 64 }, z = z + 0.2);
	action := 0; // Add, remove, move up, move down.
	if roster_index < 0 {
		GUI.space(gui, 16);
		clicked, _ := GUI.themed_button(gui, *app.store, ifx selected then "Undo" else "Add", "add_terrain",
			.{ action_width, 32 }, ifx selected then GUI.LOBBY_BUTTON_DARK else GUI.LOBBY_ACTION_BLUE);
		if clicked || (widget.released && !dragging) action = ifx selected then 2 else 1;
	} else {
		GUI.box(gui, .{ action_width, 28 }, .Right, gap = .{ 4, 0 });
		clicked, _ := GUI.themed_button(gui, *app.store, "^", "move_up", .{ (action_width - 4) / 2, 28 }, enabled = roster_index > 0);
		if clicked action = 3;
		clicked, _ = GUI.themed_button(gui, *app.store, "v", "move_down", .{ (action_width - 4) / 2, 28 }, enabled = roster_index < roster_count - 1);
		if clicked action = 4;
		GUI.end(gui);
		GUI.space(gui, 8);
		clicked, _ = GUI.themed_button(gui, *app.store, ifx action_width >= 70 then "Remove" else "X", "remove_terrain", .{ action_width, 28 }, font_size = 12);
		if clicked action = 2;
	}
	GUI.end(gui);
	return action, widget.just_pressed;
}

draw_create_instance_param_panel :: (app: *App_User, gui: *GUI.GUI_State, menu: *Menu, size: V2f) {
	GUI.push_id(gui, "parameters");
	defer GUI.pop_id(gui);
	bounds := GUI.box(gui, size, inset = v2(8.0));
	defer GUI.end(gui);
	store := *app.store;
	w := size.x - 16;
	GUI.label_box(gui, "Parameters", .{ w, 24 }, 16, GUI.GOLD_ACCENT, id = "heading");
	GUI.horizontal_rule(gui, w);
	GUI.space(gui, 12);
	GUI.label_box(gui, "Name", .{ w, 20 }, 14, GUI.TEXT_NORMAL, id = "name_label");
	GUI.input_text(gui, *menu.create_instance.name, 24, width = w, max_chars = 64, id = "instance_name_input",
		skin = GUI.compact_button_skin(store, GUI.LOBBY_BUTTON_DARK), dark_style = true);
	GUI.space(gui, 16);
	menu.create_instance.private = GUI.labeled_checkbox(gui, "Private Instance", w, 18, id = "private_instance_checkbox",
		default = menu.create_instance.private, label_color = GUI.TEXT_NORMAL, skin = GUI.compact_button_skin(store, GUI.LOBBY_BUTTON_DARK)).checked;
	GUI.space(gui, 12);
	if menu.create_instance.private {
		GUI.label_box(gui, "Password", .{ w, 20 }, 14, GUI.TEXT_NORMAL, id = "password_label");
		GUI.input_text(gui, *menu.create_instance.password, 24, width = w, max_chars = 64, id = "private_instance_password_input",
			password_mask = true, skin = GUI.compact_button_skin(store, GUI.LOBBY_BUTTON_DARK), dark_style = true);
		GUI.space(gui, 16);
	}
	menu.create_instance.auto_revive = GUI.labeled_checkbox(gui, "Auto revive", w, 18, id = "auto_revive_checkbox",
		default = menu.create_instance.auto_revive, label_color = GUI.TEXT_NORMAL, skin = GUI.compact_button_skin(store, GUI.LOBBY_BUTTON_DARK)).checked;
	GUI.space(gui, max(12.0, bounds.max.y - 8 - 68 - GUI.flow(gui).cursor.y));
	summary := ifx menu.create_instance.roster_list.count > 0 then tprint("% levels in roster", menu.create_instance.roster_list.count)
		else "Empty roster uses the default levels.";
	GUI.label_box(gui, GUI.fit_text(gui, summary, 12, w), .{ w, 24 }, 12, GUI.TEXT_MUTE, id = "roster_summary");
	GUI.space(gui, 8);
	GUI.box(gui, .{ w, 36 }, .Right, gap = .{ 8, 0 });
	defer GUI.end(gui);
	button_width := (w - 8) / 2;
	clicked, _ := GUI.themed_button(gui, store, "Create", "create_instance_button", .{ button_width, 36 }, GUI.LOBBY_ACTION_BLUE);
	if clicked {
		command: Command.Create_Instance;
		// send_web_message serializes these views before the input buffers can change.
		command.name = .{ data = menu.create_instance.name.data, count = menu.create_instance.name.count };
		command.password = .{ data = menu.create_instance.password.data, count = menu.create_instance.password.count };
		command.auto_revive = menu.create_instance.auto_revive;
		command.private = menu.create_instance.private;
		command.roster = NewArray(menu.create_instance.roster_list.count, int,, temp);
		for menu.create_instance.roster_list command.roster[it_index] = it.id;
		send_web_message(app.app.platform, gui.controls.time, make_command(command));
		menu.create_instance.open = false;
	}
	clicked, _ = GUI.themed_button(gui, store, "Cancel", "cancel_create_instance_button", .{ button_width, 36 });
	if clicked menu.create_instance.open = false;
}

draw_create_instance_roster_panel :: (app: *App_User, gui: *GUI.GUI_State, menu: *Menu, size: V2f) -> AABBf, int, int {
	GUI.push_id(gui, "roster");
	defer GUI.pop_id(gui);
	GUI.box(gui, size, inset = v2(8.0));
	defer GUI.end(gui);
	w := size.x - 16;
	GUI.label_box(gui, tprint("Roster (% levels)", menu.create_instance.roster_list.count), .{ w, 24 }, 16, GUI.GOLD_ACCENT, id = "heading");
	GUI.label_box(gui, GUI.fit_text(gui, "Click a map or drag it here. Arrows set the order.", 12, w), .{ w, 26 }, 12, GUI.TEXT_MUTE, id = "instructions");
	GUI.space(gui, 8);
	list_height := size.y - 114;
	page_size := max(1, floor((list_height + 8) / 84).(int));
	page_count := max(1, (menu.create_instance.roster_list.count + page_size - 1) / page_size);
	page, _ := GUI.widget(gui, "page", struct { value: int; });
	page.value = clamp(page.value, 0, page_count - 1);
	list_bounds := GUI.box(gui, .{ w, list_height }, gap = .{ 0, 8 });
	remove_index := -1;
	move_index := -1;
	move_delta := 0;
	for index: page.value * page_size..min(menu.create_instance.roster_list.count, (page.value + 1) * page_size) - 1 {
		entry := menu.create_instance.roster_list[index];
		action, _ := draw_create_instance_terrain_card(app, gui, entry, .{ w, 76 }, true, index, menu.create_instance.roster_list.count);
		if action == 2 remove_index = index;
		if action == 3 || action == 4 { move_index = index; move_delta = ifx action == 3 then -1 else 1; }
	}
	if menu.create_instance.roster_list.count == 0 {
		GUI.label_box(gui, GUI.fit_text(gui, "Add terrains from the left to build a new roster.", 13, w), .{ w, 48 }, 13, GUI.TEXT_MUTE, .Center, "empty_roster");
	}
	GUI.end(gui);
	if remove_index >= 0 remove_create_instance_terrain(*menu.create_instance, remove_index);
	if move_index >= 0 {
		target := move_index + move_delta;
		entry := menu.create_instance.roster_list[move_index];
		menu.create_instance.roster_list[move_index] = menu.create_instance.roster_list[target];
		menu.create_instance.roster_list[target] = entry;
		page.value = target / page_size;
	}
	GUI.space(gui, 8);
	GUI.box(gui, .{ w, 32 }, .Right, gap = .{ 8, 0 });
	clicked, _ := GUI.themed_button(gui, *app.store, "<", "previous_page", .{ 32, 32 }, enabled = page.value > 0);
	if clicked page.value -= 1;
	GUI.label_box(gui, tprint("% / %", page.value + 1, page_count), .{ w - 80, 32 }, 13, GUI.TEXT_MUTE, .Center, "page_number");
	clicked, _ = GUI.themed_button(gui, *app.store, ">", "next_page", .{ 32, 32 }, enabled = page.value < page_count - 1);
	if clicked page.value += 1;
	GUI.end(gui);
	return list_bounds, page.value, page_size;
}

draw_create_instance_terrain_panel :: (app: *App_User, gui: *GUI.GUI_State, menu: *Menu, size: V2f, dragging := false) -> int {
	GUI.push_id(gui, "catalogue");
	defer GUI.pop_id(gui);
	GUI.box(gui, size, inset = v2(8.0));
	defer GUI.end(gui);
	w := size.x - 16;
	GUI.label_box(gui, "Terrains", .{ w, 24 }, 16, GUI.GOLD_ACCENT, id = "heading");
	if GUI.labeled_input_text(gui, "Filter", *menu.create_instance.filter, w, 26, scale = 14,
		max_input_width = w - 56, label_color = GUI.TEXT_NORMAL,
		skin = GUI.compact_button_skin(*app.store, GUI.LOBBY_BUTTON_DARK), dark_style = true).changed {
		command: Command.Ask_List_Terrain;
		command.filter = GUI.view(*menu.create_instance.filter);
		command.correlation_id = 1;
		send_web_message(app.app.platform, gui.controls.time, make_command(command));
		menu.create_instance.terrain_page = 0;
	}
	GUI.space(gui, 8);
	list_height := size.y - 114;
	page_size := max(1, floor((list_height + 8) / 84).(int));
	page_count := max(1, (menu.create_instance.terrain_entries.count + page_size - 1) / page_size);
	menu.create_instance.terrain_page = clamp(menu.create_instance.terrain_page, 0, page_count - 1);
	GUI.box(gui, .{ w, list_height }, gap = .{ 0, 8 });
	pressed_id := -1;
	for index: menu.create_instance.terrain_page * page_size..min(menu.create_instance.terrain_entries.count, (menu.create_instance.terrain_page + 1) * page_size) - 1 {
		entry := menu.create_instance.terrain_entries[index];
		roster_index := create_instance_roster_index(*menu.create_instance, entry.id);
		action, pressed := draw_create_instance_terrain_card(app, gui, entry, .{ w, 76 }, roster_index >= 0, dragging = dragging);
		if action == 1 add_create_instance_terrain(*menu.create_instance, entry);
		if action == 2 remove_create_instance_terrain(*menu.create_instance, roster_index);
		if pressed pressed_id = entry.id;
	}
	if menu.create_instance.terrain_entries.count == 0
		GUI.label_box(gui, GUI.fit_text(gui, "No terrains match this filter.", 13, w), .{ w, 48 }, 13, GUI.TEXT_MUTE, .Center, "empty_catalogue");
	GUI.end(gui);
	GUI.space(gui, 8);
	GUI.box(gui, .{ w, 32 }, .Right, gap = .{ 8, 0 });
	clicked, _ := GUI.themed_button(gui, *app.store, "<", "previous_page", .{ 32, 32 }, enabled = menu.create_instance.terrain_page > 0);
	if clicked menu.create_instance.terrain_page -= 1;
	GUI.label_box(gui, tprint("% / %", menu.create_instance.terrain_page + 1, page_count), .{ w - 80, 32 }, 13, GUI.TEXT_MUTE, .Center, "page_number");
	clicked, _ = GUI.themed_button(gui, *app.store, ">", "next_page", .{ 32, 32 }, enabled = menu.create_instance.terrain_page < page_count - 1);
	if clicked menu.create_instance.terrain_page += 1;
	GUI.end(gui);
	return pressed_id;
}
