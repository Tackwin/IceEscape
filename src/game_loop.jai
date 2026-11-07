Game_Page :: struct {
	rebuild_pipelines := false;
	sound_enabled := false;
	joystick_active := false;

	Stats :: struct {
		win_count := 0;
		death_count := 0;
		revive_count := 0;
		score := 0;
	}
	player_stats: Table(int, Stats);
	next_terrain_name: string;
	wr_time_ms: int;
	wr_player_name: string;
}

process_game :: (
	app_user: *App_User,
	command: Command,
	controls: Controls.State,
	response: *Scene.Process_Response
) ->  bool {
	state := *app_user.state;
	ntp: *Command.NTP = isa(command.payload, Command.NTP);
	if ntp {
		is_over := false;
		send_back := false;
		reply := ntp.*;
		if reply.t0 == FLOAT64_MAX {
			reply.t0 = to_float64_seconds(state.current_time);
			is_over = false;
			send_back = true;
		} else if reply.t1 == FLOAT64_MAX {
			reply.t1 = to_float64_seconds(state.current_time);
			reply.t2 = to_float64_seconds(state.current_time);
			is_over = false;
			send_back = true;
		} else if reply.t2 == FLOAT64_MAX {
			reply.t2 = to_float64_seconds(state.current_time);
			is_over = false;
			send_back = true;
		} else if reply.t3 == FLOAT64_MAX {
			reply.t3 = to_float64_seconds(state.current_time);
			reply.t4 = to_float64_seconds(state.current_time);
			is_over = true;
			send_back = true;
		} else if reply.t4 == FLOAT64_MAX {
			reply.t4 = to_float64_seconds(state.current_time);
			is_over = true;
			send_back = true; // We still send back one last time to optimize the number of packets.
		} else {
			// Should never happen, the server's last send back was when t3 == FLOAT64_MAX
			is_over = false;
			send_back = false;
		}

		if send_back && response {
			Scene.add(response, state.scene.id, reply);
		}

		if is_over
			process_complete_ntp(state, reply);

		return true;
	}

	give_control: *Command.Give_Control = isa(command.payload, Command.Give_Control);
	if give_control {
		state.scene.controlled_player_id = give_control.player_id;
		return true;
	}

	get_instance_tab_stats: *Command.Get_Instance_Tab_Stats = isa(
		command.payload, Command.Get_Instance_Tab_Stats
	);
	if get_instance_tab_stats {
		table_reset(*state.game.player_stats);
		for entry: get_instance_tab_stats.players_stats {
			stats: Game_Page.Stats;
			stats.win_count = entry.wins;
			stats.death_count = entry.death;
			stats.revive_count = entry.revive;
			stats.score = entry.score;
			table_set(*state.game.player_stats, entry.player_id, stats);
		}
		if state.game.next_terrain_name
			free(state.game.next_terrain_name);
		state.game.next_terrain_name = sprint("%", get_instance_tab_stats.next_terrain_name);
		state.game.wr_time_ms = get_instance_tab_stats.wr_time_ms;
		if state.game.wr_player_name
			free(state.game.wr_player_name);
		state.game.wr_player_name = sprint("%", get_instance_tab_stats.wr_player_name);
		return true;
	}



	note_played: *Command.Note_Played = isa(command.payload, Command.Note_Played);
	if note_played {
		jukebox := Scene.find_by_jukebox_id(state.scene, note_played.jukebox_id);
		if jukebox {
			// Track data stays local and constant; the existing event advances this cursor.
			if jukebox.track_index < 0 {
				jukebox.track_index, jukebox.note_index = Scene.jukebox_roll_position(jukebox.position, 0);
			} else {
				jukebox.note_index += 1;
				if jukebox.note_index >= Scene.Jukebox.PIANO_ROLL[jukebox.track_index].notes.count {
					jukebox.note_index = 0;
					jukebox.track_index = (jukebox.track_index + 1) % Scene.Jukebox.PIANO_ROLL.count;
				}
			}
			if note_played.tune_finished {
				// These tracks have distinct final pitches: re-align after a late join or missed note.
				for Scene.Jukebox.PIANO_ROLL {
					if it.notes[it.notes.count - 1] != note_played.pitch continue;
					jukebox.track_index = it_index;
					jukebox.note_index = it.notes.count - 1;
					break;
				}
				jukebox.finished_track_index = jukebox.track_index;
				jukebox.tune_end_time = state.scene.client.clock;
			}
			jukebox.hit_time = state.scene.client.clock;
			trigger: Scene.Sound_Trigger;
			trigger.kind = .Note;
			trigger.pitch = xx note_played.pitch;
			trigger.position = jukebox.position;
			array_add(*state.scene.sound_triggers, trigger);
		}

		for * state.scene.coins {
			if it.id == note_played.from_coin_id {
				remove it;
				break;
			}
		}

		return true;
	}

	sync_scene: *Command.Sync_Scene = isa(command.payload, Command.Sync_Scene);
	if sync_scene {
		state.play_session.client.end_level_round_id = 0;
		Scene.clear_scene_run(*state.scene);
		Terrain.parse_terrain(sync_scene.terrain, *state.scene);
		state.scene.id = sync_scene.id;
		state.scene.info = Scene.read_info_message(sync_scene.info);
		state.scene.end_scene_countdown_started = false;
		if sync_scene.pity_time >= 0 {
			state.scene.pity_time_started = true;
			state.scene.pity_time = sync_scene.pity_time;
			state.scene.pity_time_start = controls.time;
			state.scene.pity_time_winner_id = sync_scene.pity_time_winner_id;
		}
		state.scene.params = .{ auto_revive = sync_scene.params.auto_revive, mode = xx sync_scene.params.mode, personal_share_weight = sync_scene.params.personal_share_weight };
		state.scene.auto_revive |= sync_scene.params.auto_revive;
		Scene.init_camera(*state.scene);
		// Remove all players not present in the sync.
		for * state.scene.players {
			found := false;
			for s: sync_scene.players {
				if it.id == s.player_id {
					found = true;
					break;
				}
			}

			if !found
				remove it;
		}
		state.scene.server.clock = sync_scene.clock;

		// Remove all presents, they are going to be synced from scratch.
		state.scene.presents.count = 0;

		// Add all new players.
		for sync_scene.players {
			player := Scene.find_by_player_id(state.scene, it.player_id);

			if !player {
				player: Scene.Player;
				player.id = it.player_id;
				array_add(*state.scene.players, player);
			}

			Scene.process(*state.scene, make_command(it), controls.time, response);
		}

		for sync_scene.robots {
			Scene.process(*state.scene, make_command(it), controls.time, response);
		}

		for sync_scene.antiairs {
			Scene.process(*state.scene, make_command(it), controls.time, response);
		}

		for sync_scene.tombstones {
			Scene.process(*state.scene, make_command(it), controls.time, response);
		}

		for sync_scene.presents {
			Scene.process(*state.scene, make_command(it), controls.time, response);
		}

		for sync_scene.safe_zones {
			Scene.process(*state.scene, make_command(it), controls.time, response);
		}

		for sync_scene.standins {
			Scene.process(*state.scene, make_command(it), controls.time, response);
		}
		if sync_scene.tile_kinds.count == state.scene.terrain.tiles.count {
			for * state.scene.terrain.tiles it.kind = xx sync_scene.tile_kinds[it_index];
		}
		for sync_scene.gates {
			Scene.process(*state.scene, make_command(it), controls.time, response);
		}
		for sync_scene.block_rocks {
			Scene.process(*state.scene, make_command(it), controls.time, response);
		}

		state.scene.server_rng.s = sync_scene.rng.s;
		return true;
	}

	processed := Scene.process(*state.scene, command, controls.time, response);
	if processed {
		leaderboard := isa(command.payload, Command.Get_Terrain_Leaderboard);
		if leaderboard update_end_level_record(app_user, leaderboard.*);
	}
	return processed;
}

gui_game_loop :: (app_user: *App_User, scene: Scene.Scene) {
	using app_user;

	controls.joystick = .{};
	controls.joystick_active = false;
	controls.joystick_released = false;
	was_joystick_active := state.game.joystick_active;
	if gui_state.controls.is_mobile && scene.state == .Normal && !scene.end_scene_countdown_started
		&& !state.playing.escape_menu_open && !console.open && !controls.pressed[Key.Tab]
		&& !app_user.end_level_preview.active {
		base_radius :: 112.0;
		thumb_radius :: 44.0;
		thumb_travel :: 64.0;
		joystick_base_atlas_rect :: V4f.{ 0.0, 6.0 / 16.0, 3.0 / 16.0, 3.0 / 16.0 };
		joystick_thumb_atlas_rect :: V4f.{ 3.0 / 16.0, 6.0 / 16.0, 1.0 / 16.0, 1.0 / 16.0 };
		center := gui_state.controls.window_size - v2(base_radius + 28);
		offset := gui_state.controls.mouse_pos - center;
		if norm(offset) <= base_radius {
			controls.captured_mouse = true;
			gui_state.controls.captured_mouse = true;
		}
		if gui_state.controls.touch_just_pressed && norm(offset) <= base_radius
			state.game.joystick_active = true;
		state.game.joystick_active &= gui_state.controls.touch_down;
		if state.game.joystick_active {
			offset /= max(1.0, norm(offset) / thumb_travel);
			controls.joystick = offset / thumb_travel;
			if norm(controls.joystick) < 0.08 controls.joystick = .{};
			controls.joystick_active = true;
		} else {
			offset = .{};
		}
		GUI2.push_quad_custom_texture(*gui_state, center - v2(base_radius), v2(base_radius * 2),
			*store.ui_atlas, joystick_base_atlas_rect, z = 20, color = .{ 1, 1, 1, 0.75 });
		GUI2.push_quad_custom_texture(*gui_state, center + offset - v2(thumb_radius), v2(thumb_radius * 2),
			*store.ui_atlas, joystick_thumb_atlas_rect, z = 21, color = .{ 1, 1, 1, 0.9 });
	} else {
		state.game.joystick_active = false;
	}
	controls.joystick_released = was_joystick_active && !state.game.joystick_active;
	if controls.joystick_active || controls.joystick_released {
		controls.captured_mouse = true;
		gui_state.controls.captured_mouse = true;
	}

	push_action_palette(*gui_state, scene, *store);
	push_buy_prompt(*gui_state, *scene, *store);

	push_scene_ui(*app_user.gui_state, state.scene, *app_user.store);
	if state.scene.end_scene_countdown_started && !app_user.end_level_preview.active {
		presentation: Play_Session.Presentation;
		presentation.clock = to_float64_seconds(controls.time - state.scene.end_scene_countdown_time);
		presentation.countdown_remaining = state.scene.end_scene_countdown - presentation.clock;
		result := Play_Session.find_result(*state.play_session, state.play_session.client.end_level_round_id);
		if result
			push_end_screen(*app_user.gui_state, result.*, presentation, *store);
	}

	push_breaking_news(*app_user.gui_state, state.news, *store);
	if controls.pressed[Key.Tab] && !console.open {
		push_score_tab(state.scene, *state.game, *app_user.gui_state, *app_user.store);
	}
	push_death_indicator(*app_user.gui_state, state.scene);

	if state.playing.escape_menu_open {
		escape_args: Escape_Menu_Args;
		escape_args.sound_enabled = state.volume_on;
		escape_args.keyboard_layout = state.keyboard_layout;
		escape_args.shadows_enabled = state.shadows_enabled;
		escape_args.lighting_enabled = state.light_enabled;
		escape_args.shadow_samples_index = cast(int) state.shadow_samples;
		escape_args.aa_mode_index = cast(int) state.aa_mode;
		escape_args.particles_enabled = state.particles_enabled;
		escape_args.props_enabled = state.props_enabled;
		escape_args.shadow_map_size_index = cast(int) state.shadow_map_size;
		ret := push_escape_menu(*app_user.gui_state, escape_args, *app_user.store);

		state.volume_on = ret.sound_checked;
		if ret.layout_changed {
			state.keyboard_layout = ret.keyboard_layout;
		}
		state.render_throttle = ret.slowdown_enabled;
		if ret.shadows_changed {
			state.shadows_enabled = ret.shadows_enabled;
		}
		if ret.lighting_changed {
			state.light_enabled = ret.lighting_enabled;
		}
		if ret.shadow_samples_changed {
			state.shadow_samples = cast(type_of(state.shadow_samples)) ret.shadow_samples_index;
		}
		if ret.aa_mode_changed {
			state.aa_mode = cast(type_of(state.aa_mode)) ret.aa_mode_index;
		}
		if ret.particles_changed {
			state.particles_enabled = ret.particles_enabled;
		}
		if ret.props_changed {
			state.props_enabled = ret.props_enabled;
		}
		if ret.shadow_map_size_changed {
			state.shadow_map_size = cast(type_of(state.shadow_map_size)) ret.shadow_map_size_index;
		}
		if ret.resume_clicked {
			state.playing.escape_menu_open = false;
		}
		if ret.leave_instance_clicked {
			command: Command.Leave_Instance;
			send_web_message(app.platform, controls.time, make_command(command));
			request_play_session(app_user, -1, -1, 0);
			state.screen_state = .Menu;
			state.playing.escape_menu_open = false;
		}
		state.game.rebuild_pipelines = ret.aa_mode_changed;
		state.game.rebuild_pipelines |= ret.shadow_map_size_changed;
		state.game.rebuild_pipelines |= ret.shadow_samples_changed;

	}

	if state.render_command_debug {
		n := min(100, state.received_command_history.count);
		y := 0;
		cursor := 0;
		while y < n && cursor < state.received_command_history.count {
			kind := state.received_command_history[
				state.received_command_history.count - 1 - cursor
			];
			cursor += 1;
			kind_idx := kind.(int);
			if !state.filter_command_debug[kind_idx]
				continue;

			GUI2.atom_label(*gui_state, tprint("%", kind), V2f.{ 500, 10 + y * 20.0 }, 18);
			y += 1;
		}

		for * state.filter_command_debug {
			result := GUI2.checkbox(
				*gui_state,
				.{ 18, 18 },
				value = state.filter_command_debug[it_index],
				id = tprint("Filter %", it_index.(Command.payload.Kind)),
				pos = .{ 400, 10.0 + it_index * 20.0 },
				align = .Top_Left
			);
			if result.changed
				state.filter_command_debug[it_index] = !state.filter_command_debug[it_index];
			GUI2.atom_label(
				*gui_state,
				tprint("%", it_index.(Command.payload.Kind)),
				V2f.{ 418.0, 10.0 + it_index * 20.0 },
				14,
				-0.5,
				align = .Center_Left
			);
		}

		{
			V := Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
			P := Scene.perspective(scene.camera);
			
			r := Scene.unproject_ndc(
				.{
					gui_state.controls.mouse_pos.x / gui_state.controls.window_size.x * 2 - 1,
					1 - gui_state.controls.mouse_pos.y / gui_state.controls.window_size.y * 2
				},
				V,
				P
			);
			target, ok := ray_plane(scene.camera.position, r, .{ 0, 0, 1 });
			if ok {
				GUI2.atom_label(
					*gui_state,
					tprint("Mouse under square % %", target.x.(int), target.y.(int)),
					pos = V2f.{ 4, 4 },
					height = 14,
					z = 5,
					GUI2.Align.Top_Left,
					outline = true
				);
			}
		}
	}

	if state.render_fps {
		// gui_demo_page(*gui_state, .{ 200, 500 }, 1024 );
		push_ms_histogram(
			*gui_state,
			.{ 10, gui_state.controls.window_size.y - 160 },
			.{ 600, 150 },
			state.history_app_render_loop_dt,
			state.history_app_render_cursor,
			"Render"
		);
		push_ms_histogram(
			*gui_state,
			.{ 10, gui_state.controls.window_size.y - 320 },
			.{ 600, 150 },
			state.history_app_update_loop_dt,
			state.history_app_update_cursor,
			"Update"
		);

		history_ping := NewArray(state.ntp_history.count, float32, false,, temp);
		for * history_ping {
			it.* = xx state.ntp_history[it_index].ping;
		}
		ping_cursor := (state.ntp_history_cursor + history_ping.count - 1) % history_ping.count;
		push_ping_histogram(*gui_state, .{ 10, gui_state.controls.window_size.y - 480 }, .{ 300, 150 }, history_ping, ping_cursor);
	}
}

input_game_loop :: (app_user: *App_User) {
	using app_user;
	if (console.open || console.ate_input) && !controls.joystick_released return;
	if controls.just_pressed[Key.Escape] {
		app_user.state.playing.escape_menu_open = !app_user.state.playing.escape_menu_open;
	}
	if controls.just_pressed[Key.Tab] {
		command: Command.Get_Instance_Tab_Stats;
		send_web_message(app.platform, controls.time, make_command(command));
	}
	if controls.pressed[Key.N] && controls.pressed[Key.P] {
		if controls.just_pressed[Key.K] {
			command: Command.Cheat_Action;
			command.kind = .Next_Level;
			send_web_message(app.platform, controls.time, make_command(command));
		}
		if controls.just_pressed[Key.L] {
			command: Command.Cheat_Action;
			command.kind = .Reset_Level;
			send_web_message(app.platform, controls.time, make_command(command));
		}
		if controls.just_pressed[Key.M] {
			command: Command.Cheat_Action;
			command.kind = .Reset_Progression;
			send_web_message(app.platform, controls.time, make_command(command));
		}
		if controls.just_pressed[Key.U] {
			command: Command.Cheat_Action;
			command.kind = .Kick;
			V := Scene.look_at(
				state.scene.camera.position, state.scene.camera.target, .{ 0, 0, 1 }
			);
			P := Scene.perspective(state.scene.camera);
			r := Scene.unproject_ndc(
				.{
					controls.mouse_pos.x / controls.window_size.x * 2 - 1,
					1 - controls.mouse_pos.y / controls.window_size.y * 2
				},
				V,
				P
			);
			target, ok := ray_plane(state.scene.camera.position, r, .{ 0, 0, 1 });
			if ok {
				closest_d := FLOAT32_MAX;
				closest_player_id := -1;
				for state.scene.players {
					p := it.client.position;
					d := norm(target - p);

					if d < closest_d {
						closest_d = d;
						closest_player_id = it.id;
					}
				}
				command.player_id = closest_player_id;
				send_web_message(app.platform, controls.time, make_command(command));
			}

		}
	}

	if controls.just_pressed[Key.H] {
		state.render_fps = !state.render_fps;
	}
	if controls.just_pressed[Key.P] {
		state.render_command_debug = !state.render_command_debug;
	}

	Scene.clear(*process_response);
	if !app_user.controls_state.captured_mouse || controls.joystick_active || controls.joystick_released {
		Scene.input(*state.scene, *controls, *process_response);
	}
}

update_game_loop :: (app_user: *App_User) {
	using app_user;

	if check(*state.ntp_period, controls.time) {
		ntp: Command.NTP;
		ntp.client_origin = true;
		ntp.player_id = state.scene.controlled_player_id;
		ntp.t0 = to_float64_seconds(state.current_time);
		ntp.t1 = FLOAT64_MAX;
		ntp.t2 = FLOAT64_MAX;
		ntp.t3 = FLOAT64_MAX;
		Scene.add(*process_response, state.scene.id, ntp);
	}
	state.scene.client.render_particles = app_user.state.particles_enabled;
	Scene.update_scene(*state.scene, controls.time, controls.delta_time, null);
	update_news(*state.scene, controls.time, *state.news);

	if state.scene.fade_in_screen_t > 0 {
		GUI2.push_quad_screen(
			*gui_state,
			AABBf.{ V2f.{ 0, 0 }, controls.window_size },
			.{ 0, 0, 0 },
			z = 100.0,
			a = state.scene.fade_in_screen_t
		);
	}
}

update_news :: (scene: *Scene.Scene, current_time: Apollo_Time, news: *[..] Scene.Breaking_News) {
	cursor := 0;
	for * news.* {
		if to_float64_seconds(current_time - it.time) < 5.0 {
			news.data[cursor] = it;
			cursor += 1;
		} else {
			// News expired
			free(it.text);
		}
	}

	array_resize(news, cursor + scene.news.count);
	for 0..scene.news.count-1 {
		news.data[it + cursor].text = scene.news[it];
		news.data[it + cursor].time = current_time;
	}
	scene.news.count = 0;
}

respond :: (platform: Platform, time: Apollo_Time, response: Scene.Process_Response) {
	for * response.entries {
		if isa(it.command.payload, Command.NTP)
			send_web_message(platform, time, it.command);
		if isa(it.command.payload, Command.Move)
			send_web_message(platform, time, it.command);
		if isa(it.command.payload, Command.Spawn_Coin)
			send_web_message(platform, time, it.command);
		if isa(it.command.payload, Command.Klaxon)
			send_web_message(platform, time, it.command);
		if isa(it.command.payload, Command.Drop)
			send_web_message(platform, time, it.command);
		if isa(it.command.payload, Command.Active_Item)
			send_web_message(platform, time, it.command);
		if isa(it.command.payload, Command.Buy_Ask)
			send_web_message(platform, time, it.command);
		if isa(it.command.payload, Command.Ask_Respawn)
			send_web_message(platform, time, it.command);
		if isa(it.command.payload, Command.Signal_Pick)
			send_web_message(platform, time, it.command);
	}
}

handle_received_asset :: (app_user: *App_User, big_asset: *Big_Asset) {
	store := *app_user.store;

	editor_page := *app_user.state.editor_page;
	for editor_page.thumbnail_receiving {
		if it.asset_id == big_asset.id {
			thumbnail4 := NewArray(128 * 128 * 4, u8, false);
			for i: 0..128*128 - 1 {
				thumbnail4[i * 4 + 0] = big_asset.buffer[i * 3 + 0];
				thumbnail4[i * 4 + 1] = big_asset.buffer[i * 3 + 1];
				thumbnail4[i * 4 + 2] = big_asset.buffer[i * 3 + 2];
				thumbnail4[i * 4 + 3] = 255;
			}
			thumbnail := thumbnail_for(store, it.terrain_id);
			queue_user_texture(store, thumbnail, thumbnail4);

			remove it;

			free(big_asset.buffer.data);
			table_remove(*editor_page.big_assets_receiving, big_asset.id);
			return;
		}
	}

	menu_page := *app_user.state.menu;
	for menu_page.thumbnail_receiving {
		if it.asset_id == big_asset.id {
			thumbnail4 := NewArray(128 * 128 * 4, u8, false);
			for i: 0..128*128 - 1 {
				thumbnail4[i * 4 + 0] = big_asset.buffer[i * 3 + 0];
				thumbnail4[i * 4 + 1] = big_asset.buffer[i * 3 + 1];
				thumbnail4[i * 4 + 2] = big_asset.buffer[i * 3 + 2];
				thumbnail4[i * 4 + 3] = 255;
			}
			thumbnail := thumbnail_for(store, it.terrain_id);
			queue_user_texture(store, thumbnail, thumbnail4);

			print("Matching thumbnail pending found for terrain id %\n", it.terrain_id);
			remove it;

			free(big_asset.buffer.data);
			table_remove(*menu_page.big_assets_receiving, big_asset.id);
			return;
		}
	}

}

game_loop :: (app_user: *App_User) -> bool {
	using app_user;

	app_user.graphics.gpu = app.platform.gpu;
	WRender.graphics = *graphics;

	gui_game_loop(app_user, state.scene);
	input_game_loop(app_user);
	update_game_loop(app_user);
	sounding(*state, *state.scene, store, app.platform);

	push_end_level_preview(app_user);
	draw_console(app_user);

	// Flush the command buffer
	for * state.scene.client_to_server {
		send_web_message(app.platform, controls.time, it);
	}
	state.scene.client_to_server.count = 0;

	// Rendering
	frame := WRender.begin_frame(*framegraph, controls.time);
	WRender.render_scene(frame, *framegraph, state.scene, store, delta_time = controls.delta_time);
	WRender.render_gui2(frame, *framegraph, app_user.gui_state, *store);
	if app_user.console.open WRender.render_gui2(frame, *framegraph, app_user.console.gui, *store);
	WRender.end_frame(*framegraph, frame);

	respond(app.platform, controls.time, process_response);

	return true;
}


sounding :: (
	state: *State, scene: *Scene.Scene, store: Store, platform: *Platform
) {
	skull_seen: Table(int, bool);
	skull_seen.allocator = temp;

	shurikens_seen: Table(int, bool);
	shurikens_seen.allocator = temp;

	for * scene.skulls {
		ok, sound := table_find(*state.skull_id_to_sound, it.id);
		if !ok {
			audio := get_boat_sailing(store, 0);
			if !audio
				continue;
			audio.kind = .Sound;
			audio.exponent = 2.5;
			audio.volume = 0.04;
			sound = platform.play_audio(audio, .{});
			sound.volume = audio.volume;
			sound.loop = true;
			platform.set_sound(sound);
			table_set(*state.skull_id_to_sound, it.id, sound);
		}
		sound.position = Scene.compute_skull_pos(scene, it.*);
		platform.set_sound(sound);
		table_set(*skull_seen, it.id, true);
	}

	for * scene.shurikens {
		frame := Scene.find_by_frame_id(scene, it.frame_id);
		if !frame
			continue;
		ok, sound := table_find(*state.shurikens_id_to_sound, it.id);
		if !ok {
			audio := get_drone_buzzing(store, 0);
			if !audio
				continue;
			audio.kind = .Sound;
			audio.exponent = 2.25;
			audio.volume = 0.020;
			sound = platform.play_audio(audio, .{});
			sound.volume = audio.volume;
			sound.loop = true;
			platform.set_sound(sound);
			table_set(*state.shurikens_id_to_sound, it.id, sound);
		}
		M := Scene.compute_moving_frame_server_world_matrix(scene, frame);
		pos := M * v4(it.server.position, 1);
		sound.position = v3(pos);
		platform.set_sound(sound);
		table_set(*shurikens_seen, it.id, true);
	}

	for value, key: state.skull_id_to_sound {
		if !table_contains(*skull_seen, key) {
			platform.kill_sound(value.id);
			table_remove(*state.skull_id_to_sound, key);
		}
	}

	for value, key: state.shurikens_id_to_sound {
		if !table_contains(*shurikens_seen, key) {
			platform.kill_sound(value.id);
			table_remove(*state.shurikens_id_to_sound, key)	;
		}
	}

	listener: Listener;
	listener.position = scene.camera.position;
	listener.direction = scene.camera.target - scene.camera.position;
	listener.position += listener.direction * 0.65;
	listener.direction = normalize(listener.direction);
	listener.volume = ifx state.volume_on then 1.0 else 0.0;
	platform.set_listener_info(listener);
	for scene.sound_triggers {
		for counter: 1..it.count {
			audio: Audio;
			audio.id = -1;
			audio.pitch = RNG.random_uniform(*scene.client_rng, 0.8, 1.2);
			if it.kind == {
				case .Footstep_Snow;
					idx := RNG.random_uniform(*scene.client_rng, 0, 5);
					audio_ptr := get_footstep_snow_sound(store, idx);
					if audio_ptr
						audio = audio_ptr.*;
					audio.volume = RNG.random_uniform(*scene.client_rng, 0.2, 0.4);
					audio.exponent = 1.0;
				case .Footstep_Ice;
					idx := RNG.random_uniform(*scene.client_rng, 0, 5);
					audio_ptr := get_footstep_ice_sound(store, idx);
					if audio_ptr
						audio = audio_ptr.*;
					audio.volume = RNG.random_uniform(*scene.client_rng, 0.75, 1.00);
					audio.exponent = 1.0;
				case .Car_Klaxon;
					idx := RNG.random_uniform(*scene.client_rng, 0, 3);
					audio_ptr := get_horn_car(store, idx);
					if audio_ptr
						audio = audio_ptr.*;
					audio.volume = RNG.random_uniform(*scene.client_rng, 0.65, 0.75);
					audio.exponent = 1.0;
				case .Explosion;
					idx := RNG.random_uniform(*scene.client_rng, 0, 9);
					audio_ptr := get_explosion_sound(store, idx);
					if audio_ptr
						audio = audio_ptr.*;
					audio.volume = RNG.random_uniform(*scene.client_rng, 1.0, 1.3);
					audio.exponent = 2.0;
				case .Loser;
					audio = store.loser_mp3;
					audio.volume = 2.0;
					audio.exponent = 1.0;
				case .Winner;
					audio = store.winner_mp3;
					audio.volume = 0.45;
					audio.exponent = 0.35;
					audio.pitch = 0.0;
					audio.fade_in = 10;
				case .Checkpoint_Ok;
					audio = store.checkpoint_ok_mp3;
					audio.volume = 2.0;
					audio.exponent = 2.0;
				case .Res;
					audio = store.res_mp3;
					audio.volume = 1.0;
					audio.exponent = 2.0;
				case .Coin_Launch;
					audio = store.coin_launch_mp3;
					audio.volume = 3.5;
					audio.exponent = 2.5;
				case .Point_Up;
					audio = store.point_up_mp3;
					audio.volume = 0.5;
				case .Note;
					audio = get_note_sound(store, xx it.pitch);
					audio.exponent = 1.0;
			}
			if audio.id == -1
				continue;
			if it.inhead
				audio.exponent = 0.0;

			audio.kind = .Sound;
			audio.repeating = false;
			audio.delay = counter * 50; // Stagger sounds to avoid audio clutter.
			platform.play_audio(audio, it.position);
		}
	}
	scene.sound_triggers.count = 0;
}


push_score_tab :: (scene: Scene.Scene, page: *Game_Page, state: *GUI2.GUI_State, store: *Store) {
	scoreboard_center := state.controls.window_size / 2;
	scoreboard_center.y -= state.controls.window_size.y / 12;
	scoreboard_size := V2f.{ 800, 441 }; // Two columns, with room for session scores.
	header_height := 56.0;
	footer_height := 28.0;

	cursor := V2f.{
		scoreboard_center.x - scoreboard_size.x / 2,
		scoreboard_center.y - scoreboard_size.y / 2
	};

	push_felt_panel(state, store, cursor - V2f.{ 14, 14 },
		scoreboard_size + V2f.{ 28, footer_height + 28 }, 5);

	GUI2.atom_label(
		state,
		string_from_arr(scene.info.name),
		.{ cursor.x + scoreboard_size.x / 2, cursor.y + 18 },
		height = 18,
		z = 10,
		align = .Center,
		color = GUI2.GOLD_ACCENT
	);

	if page.wr_time_ms > 0 {
		wr_time_ms := page.wr_time_ms;
		wr_minutes := wr_time_ms / 60000;
		wr_seconds := (wr_time_ms / 1000) % 60;
		wr_milliseconds := wr_time_ms % 1000;

		wr_string := tprint(
			"WR %:%s %ms (%)",
			formatInt(wr_minutes.(int), minimum_digits = 3, padding = #char "_"),
			formatInt(wr_seconds.(int), minimum_digits = 2, padding = #char "_"),
			formatInt(wr_milliseconds.(int), minimum_digits = 3, padding = #char "_"),
			page.wr_player_name
		);

		GUI2.atom_label(
			state,
			wr_string,
			.{ cursor.x + 16, cursor.y + 41 },
			height = 11,
			z = 100,
			align = .Center_Left
		);
	}

	if page.next_terrain_name.count > 0 GUI2.atom_label(
		state,
		tprint("Next up: %", page.next_terrain_name),
		.{ cursor.x + scoreboard_size.x - 16, cursor.y + 41 },
		height = 11,
		z = 100,
		align = .Center_Right
	);

	GUI2.push_quad_screen(
		state,
		pos = cursor,
		size = .{ scoreboard_size.x, header_height },
		color = v3(GUI2.LOBBY_BUTTON_DARK),
		z = 6
	);
	GUI2.push_quad_screen(
		state,
		pos = .{ cursor.x, cursor.y + scoreboard_size.y },
		size = .{ scoreboard_size.x, footer_height },
		color = v3(GUI2.LOBBY_BUTTON_DARK),
		z = 6
	);
	GUI2.push_quad_screen(
		state,
		pos = .{ cursor.x, cursor.y + scoreboard_size.y },
		size = .{ scoreboard_size.x, 1 },
		color = v3(GUI2.LOBBY_SEPARATOR),
		z = 7
	);
	GUI2.atom_label(state, "Release TAB to return to the game",
		.{ cursor.x + scoreboard_size.x / 2, cursor.y + scoreboard_size.y + footer_height / 2 },
		height = 11, z = 10, align = .Center, color = GUI2.TEXT_MUTE);

	GUI2.push_quad_screen(
		state,
		pos = .{ cursor.x, cursor.y + header_height },
		size = .{ scoreboard_size.x, 1 },
		color = v3(GUI2.LOBBY_SEPARATOR),
		z = 7
	);

	scoreline_size := V2f.{ scoreboard_size.x / 2, 48 };

	push_scoreline :: (x: float, y: float, player: Scene.Player) #expand {
		stat := table_find_pointer(*page.player_stats, player.id);
		if !stat
			return;
		
		cursor := scoreboard_center;
		cursor.x -= scoreboard_size.x / 2;
		cursor.y -= scoreboard_size.y / 2;
		cursor.y += header_height + 1;
		cursor.x += x * scoreline_size.x;
		cursor.y += y * scoreline_size.y;

		model_size :: V2f.{ 48, 48 };
		icon_size :: V2f.{ 24, 24 };

		GUI2.push_quad_screen(
			state,
			pos = cursor,
			size = scoreline_size,
			color = v3(GUI2.LOBBY_SEPARATOR),
			z = 10
		);
		GUI2.push_quad_screen(
			state,
			pos = .{ cursor.x + 1, cursor.y + 1 },
			size = .{ scoreline_size.x - 2, scoreline_size.y - 2 },
			color = v3(GUI2.LOBBY_BUTTON_DARK),
			z = 11
		);

		GUI2.push_quad_texture(
			state,
			pos = .{ cursor.x + 4, cursor.y + (scoreline_size.y - model_size.y) / 2 },
			size = model_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = model_id_to_slot(xx player.server.model_id),
			z = 12
		);

		cursor.x += 16;

		GUI2.push_quad_texture(
			state,
			pos = .{
				cursor.x + 4 + model_size.x + 4,
				cursor.y + (scoreline_size.y - icon_size.y) / 2
			},
			size = icon_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = GUI2.AWARD_SLOT,
			z = 12
		);
		GUI2.atom_label(
			state,
			tprint("%", stat.win_count),
			.{ cursor.x + 4 + model_size.x + 32, cursor.y + scoreline_size.y / 2 },
			height = 18,
			z = 12,
			align = GUI2.Align.Center_Left,
			outline = true,
			id = 0
		);

		GUI2.push_quad_texture(
			state,
			pos = .{
				cursor.x + model_size.x + 4 + 32 + icon_size.x + 4,
				cursor.y + (scoreline_size.y - icon_size.y) / 2
			},
			size = icon_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = GUI2.REVIVE_SLOT,
			z = 12
		);
		GUI2.atom_label(
			state,
			tprint("%", stat.revive_count),
			.{
				cursor.x + 4 + model_size.x + 32 + icon_size.x + 32,
				cursor.y + scoreline_size.y / 2
			},
			height = 18,
			z = 12,
			align = GUI2.Align.Center_Left,
			outline = true,
			id = 1
		);

		GUI2.push_quad_texture(
			state,
			pos = .{
				cursor.x + model_size.x + 4 + 32 + icon_size.x + 4 + 32 + icon_size.x + 4,
				cursor.y + (scoreline_size.y - icon_size.y) / 2
			},
			size = icon_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = GUI2.DEATH_SLOT,
			z = 12
		);
		GUI2.atom_label(
			state,
			tprint("%", stat.death_count),
			.{
				cursor.x + 4 + model_size.x + 32 + icon_size.x + 32 + icon_size.x + 32,
				cursor.y + scoreline_size.y / 2
			},
			height = 18,
			z = 12,
			align = GUI2.Align.Center_Left,
			outline = true,
			id = 2
		);
		GUI2.atom_label(state, tprint("%", stat.score),
			.{ cursor.x + scoreline_size.x - 24, cursor.y + scoreline_size.y / 2 },
			height = 28, z = 12, align = .Center_Right, color = GUI2.GOLD_ACCENT, id = 3);
	}

	for scene.players {
		x := it_index / 8;
		y := it_index % 8;
		push_scoreline(x.(float32), y.(float32), it);
	}
}


action_to_icon :: (action: Controls.Action_Key, layout: Layout) -> V2f {
	return key_to_icon(Controls.action_to_platform(action, layout));
}

key_to_icon :: (key: Key) -> V2f {
	if key == {
		case .W;
			return GUI2.W_OUTLINE_SLOT;
		case .A;
			return GUI2.A_OUTLINE_SLOT;
		case .Q;
			return GUI2.Q_OUTLINE_SLOT;
		case .S;
			return GUI2.S_OUTLINE_SLOT;
		case .D;
			return GUI2.D_OUTLINE_SLOT;
		case .Z;
			return GUI2.Z_OUTLINE_SLOT;
		case .C;
			return GUI2.C_OUTLINE_SLOT;
		case .X;
			return GUI2.X_OUTLINE_SLOT;
		case .E;
			return GUI2.E_OUTLINE_SLOT;
		case .R;
			return GUI2.R_OUTLINE_SLOT;
		case .V;
			return GUI2.V_OUTLINE_SLOT;
		case .F;
			return GUI2.F_OUTLINE_SLOT;
	}
	return GUI2.V_OUTLINE_SLOT;
}

model_id_to_slot :: (id: Scene.Model_Id) -> V2f {
	if id == {
		case .Racer; return GUI2.RACER_SLOT;
		case .SUV; return GUI2.SUV_SLOT;
		case .Speedster; return GUI2.SPEEDSTER_SLOT;
		case .Drag_Racer; return GUI2.DRAG_RACER_SLOT;
		case .Monster_Truck; return GUI2.MONSTER_TRUCK_SLOT;
		case .Boat_Row; return GUI2.BOAT_ROW_SLOT;
		case .Boat_Fishing; return GUI2.BOAT_FISHING_SLOT;
		case .Spaceship; return GUI2.SPACESHIP_SLOT;
		case .Ambulance; return GUI2.AMBULANCE_SLOT;
		case .Taxi; return GUI2.TAXI_SLOT;
		case .Police; return GUI2.POLICE_SLOT;
		case .Boat_Sail; return GUI2.BOAT_SAIL_SLOT;
		case .Tractor; return GUI2.TRACTOR_SLOT;
		case .Truck; return GUI2.TRUCK_SLOT;
		case .Boat_Speed; return GUI2.BOAT_SPEED_SLOT;
		case .Boat_Fan; return GUI2.BOAT_FAN_SLOT;
	}
	return GUI2.QUESTION_SLOT;
}

push_buy_prompt :: (state: *GUI2.GUI_State, scene: *Scene.Scene, store: *Store) {
	V := Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	P := Scene.perspective(scene.camera);

	player := Scene.find_by_player_id(scene, scene.controlled_player_id);
	if player && !player.server.dead {
		p := player.client.position;
		for * present: scene.presents {
			if present.server.available {
				q := present.position;

				needed := 1;
				if present.kind == .B
					needed = 2;

				d := norm(p - q);
				if d < player.server.radius_hitbox_key {

					prompt := tprint(
						"Not enough shares (% needed) ! Revive your friends to collect more shares!", needed
					);
					if player.server.souls >= needed {
						prompt = tprint("R to buy. % shares.", needed);
					}

					pos := v4(q, 1);
					pos = V * pos;
					pos = P * pos;
					pos /= abs(pos.w);
					screen_p: V2f;
					screen_p.x =
						pos.x * (state.controls.window_size.x) / 2 +
						state.controls.window_size.x / 2;
					screen_p.y =
						state.controls.window_size.y / 2 -
						pos.y * (state.controls.window_size.y) / 2;

					label := GUI2.atom_label(state, prompt, screen_p, 16, z=10, align = .Center, outline = true,
						color = GUI2.GOLD_ACCENT);
					GUI2.push_nine_slice(state,
						label.aabb_min - v2(10),
						label.aabb_max - label.aabb_min + v2(20),
						compact_button_skin(store, GUI2.LOBBY_BUTTON_DARK), 9.8);
				}
			}
		}
	}
}

push_breaking_news :: (state: *GUI2.GUI_State, news: [] Scene.Breaking_News, store: *Store) {
	cursor := V2f.{ state.controls.window_size.x / 2, 16};
	for news {
		t := to_float64_seconds(state.controls.time - it.time).(float);
		t = clamp(t / 5, 0.0, 1.0);

		alpha := 1.0 - t;
		text := tprint("NEWS: %", it.text);
		label := GUI2.atom_label(
			state, text, .{ cursor.x, cursor.y }, 20, z=20, align = .Top_Center, outline = true,
			color = V4f.{ GUI2.GOLD_ACCENT.x, GUI2.GOLD_ACCENT.y, GUI2.GOLD_ACCENT.z, alpha }
		);
		fill := GUI2.LOBBY_BUTTON_DARK;
		fill.w = alpha;
		GUI2.push_nine_slice(state, label.aabb_min - v2(10),
			label.aabb_max - label.aabb_min + v2(20), compact_button_skin(store, fill), 19.8);

		cursor.y += label.aabb_max.y - label.aabb_min.y + 4;
	}
}

push_app_loop_histogram :: (state: *GUI2.GUI_State, pos: V2f, size: V2f, data: [] float32, current_idx: int) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	ms_text := tprint("app_loop: %.2f ms, Avg %.2f ms", 1000 * data[current_idx], 1000 * avg);
	GUI2.atom_label(state, ms_text, .{ pos.x + 4, pos.y + 4 }, 16, z=11, align = .Top_Left);

	GUI2.push_quad_screen(
		state,
		pos = pos,
		size = size,
		color = .{ 0.0, 0.0, 0.0 },
		z = 10
	);

	project :: (x: float32) -> float32 #expand {
		return min(1.0, (600 / (1 + exp(-x / 5)) - 300) / 300) * size.y;
	}

	n := data.count;
	for data {
		ms := 1000 * it;
		h := project(ms);
		w := size.x / data.count - 1;

		x := (it_index * size.x) / data.count;

		color := V3f.{ 1.0, 1.0, 1.0 };
		if it_index == current_idx {
			// Pink color
			color = V3f.{ 1.0, 0.0, 1.0 };
			GUI2.push_quad_screen(
				state,
				pos = .{ pos.x + x, pos.y + 5 },
				size = .{ w, size.y - 10 },
				color = color,
				z = 10.1
			);
		}
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x + x, pos.y + size.y - 5 - h },
			size = .{ w, h },
			color = color,
			z = 11
		);
	}

	// Reference lines for ms thresholds
	{
		h := project(8.33); // 120 fps target
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = 12
		);
	}
	{
		h := project(16.67); // 60 fps target
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = 12
		);
	}
	{
		h := project(33.33); // 30 fps target
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = 12
		);
	}
}

push_ping_histogram :: (state: *GUI2.GUI_State, pos: V2f, size: V2f, data: [] float32, current_idx: int) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	fps_text := tprint("Ping: %, Avg % (ms)", (1000 * data[current_idx]).(s64), (1000 * avg).(s64));
	GUI2.atom_label(state, fps_text, .{ pos.x + 4, pos.y + 4 }, 16, z=11, align = .Top_Left);

	GUI2.push_quad_screen(
		state,
		pos = pos,
		size = size,
		color = .{ 0.0, 0.0, 0.0 },
		z = 10
	);

	project :: (x: float32) -> float32 #expand {
		return min(1.0, (600 / (1 + exp(-x / 100)) - 300) / 300) * size.y;
	}

	n := data.count;
	for data {
		h := project(1000 * it);
		w := size.x / data.count - 1;

		x := (it_index * size.x) / data.count;

		color := V3f.{ 1.0, 1.0, 1.0 };
		if it_index == current_idx {
			// Pink color
			color = V3f.{ 1.0, 0.0, 1.0 };
			GUI2.push_quad_screen(
				state,
				pos = .{ pos.x + x, pos.y + 5 },
				size = .{ w, size.y - 10 },
				color = color,
				z = 10.1
			);
		}
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x + x, pos.y + size.y - 5 - h },
			size = .{ w, h },
			color = color,
			z = 11
		);
	}

	{
		h := project(20);
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = 12
		);
	}
	{
		h := project(80);
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = 12
		);
	}
	{
		h := project(200);
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = 12
		);
	}
}

push_ms_histogram :: (state: *GUI2.GUI_State, pos: V2f, size: V2f, data: [] float32, current_idx: int, label_prefix: string) {
	avg := 0.0;
	for data
		avg += it;
	avg /= data.count;

	ms_text := tprint(
		"%: %.% ms, Avg %.% ms",
		label_prefix,
		(1000 * data[current_idx]).(s64),
		(10000 * data[current_idx]).(s64) % 10,
		(1000 * avg).(s64),
		(10000 * avg).(s64) % 10
	);
	GUI2.atom_label(state, ms_text, .{ pos.x + 4, pos.y + 4 }, 16, z=11, align = .Top_Left);

	GUI2.push_quad_screen(
		state,
		pos = pos,
		size = size,
		color = .{ 0.0, 0.0, 0.0 },
		z = 10
	);

	project :: (x: float32) -> float32 #expand {
		return min(1.0, (600 / (1 + exp(-x / 15)) - 300) / 300) * size.y;
	}

	n := data.count;
	for data {
		ms := 1000 * it;
		h := project(ms);
		w := max(size.x / data.count - 1, 1);

		x := (it_index * size.x) / data.count;

		color := V3f.{ 1.0, 1.0, 1.0 };
		if it_index == current_idx {
			// Pink color
			color = V3f.{ 1.0, 0.0, 1.0 };
			GUI2.push_quad_screen(
				state,
				pos = .{ pos.x + x, pos.y + 5 },
				size = .{ w, size.y - 10 },
				color = color,
				z = 10.1
			);
		}
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x + x, pos.y + size.y - 5 - h },
			size = .{ w, h },
			color = color,
			z = 11
		);
	}

	// Reference lines for ms thresholds
	{
		h := project(8.33); // 120 fps target
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 0.0, 1.0 },
			z = 12
		);
	}
	{
		h := project(16.67); // 60 fps target
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 0.0, 1.0, 0.0 },
			z = 12
		);
	}
	{
		h := project(33.33); // 30 fps target
		GUI2.push_quad_screen(
			state,
			pos = .{ pos.x, pos.y + size.y - 5 - h },
			size = .{ size.x, 1 },
			color = .{ 1.0, 0.0, 0.0 },
			z = 12
		);
	}
}

push_scene_ui :: (state: *GUI2.GUI_State, scene: Scene.Scene, store: *Store) {
	top_left_width := 325.0;
	top_left_padding := 8.0;

	GUI2.column(state, pos = .{ 0, 0 }, direction = .Down);
	defer GUI2.end(state);
	height := ifx scene.pity_time_started then 70.0 else 48.0;
	GUI2.push_nine_slice(
		state, GUI2.flow(state).cursor, v2(top_left_width, height),  compact_button_skin(store), color = .{ 1.0, 1.0, 1.0, 0.85 });
	GUI2.move_cursor(state, .{ top_left_padding, top_left_padding + 16.0 });

	name_anchor := GUI2.flow(state).cursor;
	time_anchor := name_anchor + v2(top_left_width - 2 * top_left_padding, 0);
	share_anchor := name_anchor + v2(0.0, 16);
	if scene.pity_time_started {
		remaining := ceil(Scene.pity_time_remaining(scene, state.controls.time)).(int);
		GUI2.atom_label(state, tprint("Trophy claimed! %s left to finish", remaining),
			share_anchor + v2(0.0, 22.0), 14, 1, align = .Bottom_Left, outline = true, color = GUI2.GOLD_ACCENT);
	}

	name: string;
	name.data = scene.info.name.data;
	name.count = scene.info.name.count;
	for name if it == 0 { name.count = it_index; break; }
	label := GUI2.atom_label(
		state,
		name,
		GUI2.flow(state).cursor,
		18,
		1,
		align = .Bottom_Left,
		outline = true,
		color = GUI2.GOLD_ACCENT
	);


	time := scene.client.clock;
	minutes := floor(time / 60);
	seconds := fmod_cycling(time, 60);
	milliseconds := frac(time) * 1000;
	time_label := GUI2.atom_label(
		state,
		tprint(
			"%:%s %ms",
			formatInt(minutes.(int), minimum_digits = 3, padding = #char "_"),
			formatInt(seconds.(int), minimum_digits = 2, padding = #char "_"),
			formatInt(milliseconds.(int), minimum_digits = 3, padding = #char "_")
		),
		time_anchor,
		height =14,
		z=1,
		align = .Bottom_Right,
		outline = true,
		color = GUI2.TEXT_NORMAL
	);

	player := Scene.find_by_player_id(scene, scene.controlled_player_id);
	if player {
		share_label := GUI2.atom_label(
			state,
			tprint("Share: %", player.server.souls),
			share_anchor,
			14,
			1,
			align = .Bottom_Left,
			outline = true,
			color = GUI2.TEXT_NORMAL
		);
	}
}

push_point_ui :: (state: *GUI2.GUI_State, player: Scene.Player, store: *Store) {
	cursor := V2f.{ 12, 40 + 12 };

	score_label := GUI2.atom_label(
		state,
		tprint("Souls: %", player.server.souls),
		cursor,
		24,
		1,
		align = .Center_Left,
		outline = true,
		color = GUI2.TEXT_NORMAL
	);

	GUI2.push_nine_slice(
		state, score_label.aabb_min - v2(8),
		score_label.aabb_max - score_label.aabb_min + v2(16),
		compact_button_skin(store, GUI2.LOBBY_BUTTON_DARK),
		0
	);
}

push_death_indicator :: (state: *GUI2.GUI_State, scene: Scene.Scene) {
	V := Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	P := Scene.perspective(scene.camera);

	// V * <world> = <view>
	// P * <view> = <clip>

	for scene.players {
		if it.server.dead && it.id != scene.controlled_player_id {
			p := v4(it.server.position, 1);
			p = V * p;
			p = P * p;
			p /= abs(p.w);

			if -1.0 <= p.x && p.x <= 1.0 && -1.0 <= p.y && p.y <= 1.0 // On screen
				continue;

			p2 := closest_aabb(V2f.{ p.x, p.y }, .{ -1.0, -1.0 }, .{ 1.0, 1.0 });
			indicator := GUI2.BUBBLE_INDICATOR_SLOT_UP;
			indicator_dt := V2f.{ 0, 0 };
			{
				dx := p.x - p2.x;
				dy := p.y - p2.y;
				if abs(dx) > abs(dy)
					if dx < 0 {
						indicator = GUI2.BUBBLE_INDICATOR_SLOT_LEFT;
						indicator_dt = V2f.{ -5, 0 };
					}
					else {
						indicator = GUI2.BUBBLE_INDICATOR_SLOT_RIGHT;
						indicator_dt = V2f.{ 5, 0 };
					}
				else
					if dy > 0 {
						indicator = GUI2.BUBBLE_INDICATOR_SLOT_UP;
						indicator_dt = V2f.{ 0, -5 };
					}
					else {
						indicator = GUI2.BUBBLE_INDICATOR_SLOT_DOWN;
						indicator_dt = V2f.{ 0, 5 };
					}
			}

			screen_p2: V2f;
			screen_p2.x =
				p2.x * (state.controls.window_size.x - 50) / 2 + state.controls.window_size.x / 2;
			screen_p2.y =
				state.controls.window_size.y / 2 -
				p2.y * (state.controls.window_size.y - 50) / 2;

			// Check if too close to the bottom left ui palette
			action_palette_safety := V2f.{ 196 + 25, 196 + 25 };
			if screen_p2.x < action_palette_safety.x && screen_p2.y > state.controls.window_size.y - action_palette_safety.y {
				dx := abs(screen_p2.x - action_palette_safety.x);
				dy := abs(screen_p2.y - (state.controls.window_size.y - action_palette_safety.y));
				if dx < dy
					screen_p2.x = action_palette_safety.x;
				else
					screen_p2.y = state.controls.window_size.y - action_palette_safety.y;
			}

			GUI2.push_quad_texture(
				state,
				pos = screen_p2 - V2f.{ 24, 24 } + indicator_dt,
				size = V2f.{ 48, 48 },
				tex_slot = indicator,
				color = .{ 1.0, 1.0, 1.0 },
				z = 19
			);

			GUI2.push_quad_texture(
				state,
				pos = screen_p2 - V2f.{ 20, 20 },
				size = V2f.{ 40, 40 },
				tex_slot = model_id_to_slot(xx it.server.model_id),
				color = .{ 0.3, 0.3, 0.3 },
				z = 20
			);
		}
	}
}

push_action_palette :: (state: *GUI2.GUI_State, scene: Scene.Scene, store: *Store) {
	palette_h := 196.0;
	palette_y := state.controls.window_size.y - palette_h;
	push_felt_panel(state, store, .{ 0, palette_y }, .{ 196, 196 }, 1);
	GUI2.push_quad_screen(state, .{ 14, palette_y + 14 }, .{ 168, 168 }, v3(GUI2.LOBBY_TABLE_BACKGROUND), 1.1, a = 0.96);

	cell_y :: (y: int) -> float32 #expand {
		return palette_y + 14 + (3 - y) * 42.0;
	}

	render_square_at :: (x: int, y: int, key_code: int) #expand {
		color := GUI2.LOBBY_BUTTON_DARK;
		if state.controls.pressed[xx key_code]
			color = GUI2.LOBBY_ACTION_BLUE;
		GUI2.push_quad_screen(state, .{ x * 42.0 + 15, cell_y(y) + 1 }, .{ 41, 41 },
			v3(color), 2, a = color.w);
	}
	render_square_at(0, 0, xx Controls.action_to_platform(Controls.Action_Key.Square00, state.controls.layout));
	render_square_at(1, 0, xx Controls.action_to_platform(Controls.Action_Key.Square10, state.controls.layout));
	render_square_at(2, 0, xx Controls.action_to_platform(Controls.Action_Key.Square20, state.controls.layout));
	render_square_at(3, 0, xx Controls.action_to_platform(Controls.Action_Key.Square30, state.controls.layout));
	render_square_at(0, 1, xx Controls.action_to_platform(Controls.Action_Key.Square01, state.controls.layout));
	render_square_at(1, 1, xx Controls.action_to_platform(Controls.Action_Key.Square11, state.controls.layout));
	render_square_at(2, 1, xx Controls.action_to_platform(Controls.Action_Key.Square21, state.controls.layout));
	render_square_at(3, 1, xx Controls.action_to_platform(Controls.Action_Key.Square31, state.controls.layout));
	render_square_at(0, 2, xx Controls.action_to_platform(Controls.Action_Key.Square02, state.controls.layout));
	render_square_at(1, 2, xx Controls.action_to_platform(Controls.Action_Key.Square12, state.controls.layout));
	render_square_at(2, 2, xx Controls.action_to_platform(Controls.Action_Key.Square22, state.controls.layout));
	render_square_at(3, 2, xx Controls.action_to_platform(Controls.Action_Key.Square32, state.controls.layout));
	render_square_at(0, 3, xx Controls.action_to_platform(Controls.Action_Key.Square03, state.controls.layout));
	render_square_at(1, 3, xx Controls.action_to_platform(Controls.Action_Key.Square13, state.controls.layout));
	render_square_at(2, 3, xx Controls.action_to_platform(Controls.Action_Key.Square23, state.controls.layout));
	render_square_at(3, 3, xx Controls.action_to_platform(Controls.Action_Key.Square33, state.controls.layout));
	for 1..4 {
		GUI2.push_quad_screen(state, .{ (it * 42 + 14).(float32), palette_y + 14 }, .{ 1, 168 },
			v3(GUI2.LOBBY_SEPARATOR), 2.1, a = GUI2.LOBBY_SEPARATOR.w);
		GUI2.push_quad_screen(state, .{ 14, palette_y + 14 + it * 42 }, .{ 168, 1 },
			v3(GUI2.LOBBY_SEPARATOR), 2.1, a = GUI2.LOBBY_SEPARATOR.w);
	}

	render_texture_at :: (x: int, y: int, tex_slot: V2f, color := V3f.{ 1.0, 1.0, 1.0 }) #expand {
		GUI2.push_quad_texture(
			state,
			pos = .{ (x * 42 + 18).(float32), cell_y(y) + 4 },
			size = .{ 34, 34 },
			tex_slot = tex_slot,
			color = color,
			z = 3
		);
	}
	render_hint_at :: (x: int, y: int, tex_slot: V2f)  #expand {
		GUI2.push_quad_texture(
			state,
			pos = .{ (x * 42 + 56 - 18).(float32), cell_y(y) + 42 - 18 },
			size = .{ 18, 18 },
			tex_slot = tex_slot,
			color = .{ 1.0, 1.0, 1.0 },
			z = 5
		);
	}
	render_text_at :: (x: int, y: int, text: string, color := V3f.{ 1.0, 1.0, 1.0 }) #expand {
		GUI2.atom_label(
			state,
			text,
			.{ (x * 42 + 56 - 10).(float32), cell_y(y) + 42 - 10 },
			z = 5.0,
			align=.Center,
			height =16,
			color = v4(color, 1.0)
		);
	}

	if scene.params.mode == {
		case .Standard;
		render_texture_at(0, 1, GUI2.LEFT_SLOT);
		render_hint_at(0, 1, action_to_icon(Controls.Action_Key.Square01, state.controls.layout));

		render_texture_at(1, 1, GUI2.DOWN_SLOT);
		render_hint_at(1, 1, action_to_icon(Controls.Action_Key.Square11, state.controls.layout));

		render_texture_at(2, 1, GUI2.RIGHT_SLOT);
		render_hint_at(2, 1, action_to_icon(Controls.Action_Key.Square21, state.controls.layout));

		render_texture_at(1, 2, GUI2.UP_SLOT);
		render_hint_at(1, 2, action_to_icon(Controls.Action_Key.Square12, state.controls.layout));

		render_texture_at(2, 0, GUI2.COIN_SLOT);
		render_hint_at(2, 0, action_to_icon(Controls.Action_Key.Square20, state.controls.layout));

		render_texture_at(1, 0, GUI2.KLAXON_SLOT);
		render_hint_at(1, 0, action_to_icon(Controls.Action_Key.Square10, state.controls.layout));

		if scene.camera_locked
			render_texture_at(0, 0, GUI2.UNLOCKED_SLOT);
		else
			render_texture_at(0, 0, GUI2.LOCKED_SLOT);
		render_hint_at(0, 0, action_to_icon(Controls.Action_Key.Square00, state.controls.layout));

		player := Scene.find_by_player_id(scene, scene.controlled_player_id);
		if player {
			if Scene.find_bomb_by_holder_id(scene, player.id) {
				render_texture_at(3, 1, GUI2.DROP_SLOT);
				render_hint_at(3, 1, action_to_icon(Controls.Action_Key.Square31, state.controls.layout));
			}
			if player.server.has_safe_present {
				render_texture_at(2, 2, GUI2.SAFE_ZONE_SLOT, .{ 0.5, 1.0, 0.5 });
				render_hint_at(2, 2, action_to_icon(Controls.Action_Key.Square22, state.controls.layout));
			}
			if player.server.has_hook_present {
				render_texture_at(0, 2, GUI2.HOOK_SLOT, .{ 0.5, 1.0, 0.5 });
				render_hint_at(0, 2, action_to_icon(Controls.Action_Key.Square02, state.controls.layout));

				for 0..player.server.has_hook_present-1 {
					GUI2.push_quad_screen(
						state,
						pos = .{ (17 + it * 6).(float32), cell_y(2) + 3 },
						size = .{ 4, 4 },
						color = .{ 1.0, 1.0, 1.0 },
						z = 6
					);
				}
			}

			if player.server.dead {
				render_texture_at(3, 0, GUI2.RESURRECT_SLOT, .{ 0.5, 1.0, 0.5 });
				render_hint_at(3, 0, action_to_icon(Controls.Action_Key.Square30, state.controls.layout));

				dt := scene.client.clock - player.server.dead_time;
				t := clamp(dt / player.server.dead_cooldown, 0.0, 1.0).(float32);

				if t > 0 {
					GUI2.push_quad_screen(
						state,
						pos = .{ 3 * 42.0 + 15, cell_y(0) + 1 + 40 * t },
						size = .{ 40, 40 * (1 - t) },
						color = GUI2.COLOR_SOMBER_A,
						z = 3,
						a = 0.5
					);
				}
			}
		}


		render_texture_at(3, 2, GUI2.HAND_OPEN_SLOT, .{ 0.5, 1.0, 0.5 });
		render_hint_at(3, 2, action_to_icon(Controls.Action_Key.Square32, state.controls.layout));
		case .Bomberman;
		render_texture_at(1, 0, GUI2.KLAXON_SLOT);
		render_hint_at(1, 0, action_to_icon(Controls.Action_Key.Square10, state.controls.layout));

		render_texture_at(2, 2, GUI2.BOMB_SLOT);
		render_hint_at(2, 2, action_to_icon(Controls.Action_Key.Square22, state.controls.layout));

		player := Scene.find_by_player_id(scene, scene.controlled_player_id);
		if player {
			render_texture_at(0, 3, GUI2.CROSS_LENGTH_SLOT);
			render_text_at(0, 3, tprint("%", player.server.bomberman.cross_chain_power));
			render_texture_at(1, 3, GUI2.EXPLOSION_TIME_SLOT);
			render_text_at(1, 3, tprint("%", player.server.bomberman.explosion_speed_power));
			render_texture_at(2, 3, GUI2.SHIELD_SLOT);
			render_text_at(2, 3, tprint("%", player.server.bomberman.shield_power));
		}
	}



}

Escape_Menu_Args :: struct {
	sound_enabled := false;
	keyboard_layout: Layout = .AZERTY;

	// Render settings
	shadows_enabled := true;
	lighting_enabled := true;
	shadow_samples_index := 1; // 0=4, 1=9, 2=25
	aa_mode_index := 0; // 0=FXAA, 1=MSAA 2x, 2=MSAA 4x, 3=No AA
	particles_enabled := true;
	props_enabled := true;
	shadow_map_size_index := 1; // 0=1024, 1=2048, 2=4096
}

Escape_Menu_Ret :: struct {
	sound_checked := false;
	resume_clicked := false;
	editor_clicked := false;
	leave_instance_clicked := false;
	keyboard_layout: Layout;
	layout_changed := false;

	// Render settings
	lighting_enabled := true;
	lighting_changed := false;
	shadows_enabled := true;
	shadows_changed := false;
	shadow_samples_index := 1;
	shadow_samples_changed := false;
	aa_mode_index := 0;
	aa_mode_changed := false;
	particles_enabled := true;
	particles_changed := false;
	props_enabled := true;
	props_changed := false;
	shadow_map_size_index := 1;
	shadow_map_size_changed := false;
	slowdown_enabled := false;
	slowdown_changed := false;
}

push_escape_menu :: (state: *GUI2.GUI_State, args: Escape_Menu_Args, store: *Store = null) -> Escape_Menu_Ret {
	ret: Escape_Menu_Ret;
	GUI2.push_id(state, "escape_menu");
	defer GUI2.pop_id(state);

	GUI2.push_quad_screen(state, .{ 0, 0 }, state.controls.window_size, v3(GUI2.GRAY_00), z = 10, a = 0.5);
	state.controls.captured_mouse = true;
	state.controls.captured_keyboard = true;

	popup_size := V2f.{ 520, 560 };
	pos := (state.controls.window_size - popup_size) / 2;
	if store {
		push_felt_panel(state, store, pos, popup_size, z = 11.0);
	} else {
		GUI2.push_quad_screen(state, pos, popup_size, v3(GUI2.GRAY_10), z = 11);
		GUI2.push_quad_screen(state, pos + v2(1.0), popup_size - v2(2.0), v3(GUI2.GRAY_80), z = 11.1);
	}
	GUI2.atom_label(state, "Settings", .{ pos.x + popup_size.x / 2, pos.y + 28 },
		20, z = 12.1, align = .Center, color = GUI2.GOLD_ACCENT);
	GUI2.push_quad_screen(state, .{ pos.x + 24, pos.y + 48 },
		.{ popup_size.x - 48, 1 }, v3(GUI2.LOBBY_SEPARATOR), z = 12.0);

	GUI2.row(state, pos = pos + v2(32.0, 64.0), direction = .Right, z = 12, align = .Top_Left);
	if store {
		ret.resume_clicked, _ = themed_button(
			state, store, "Resume", "resume", .{ 215, 40 }, GUI2.LOBBY_ACTION_BLUE
		);
		GUI2.space(state, 16);
		ret.leave_instance_clicked, _ = themed_button(
			state, store, "Leave Instance", "leave", .{ 215, 40 }, GUI2.LOBBY_BUTTON_DARK
		);
	} else {
		ret.resume_clicked = GUI2.button(state, "Resume", id = "resume");
		GUI2.space(state, 16);
		ret.leave_instance_clicked = GUI2.button(state, "Leave Instance", id = "leave");
	}
	GUI2.end(state);

	control_skin := ifx store then compact_button_skin(store, GUI2.LOBBY_BUTTON_DARK) else .{};
	GUI2.column(state, pos = pos + v2(32.0, 124.0), direction = .Down, z = 12, align = .Top_Left);
	ret.sound_checked = GUI2.labeled_checkbox(state, "Sound", popup_size.x - 64, 24,
		id = "sound_checkbox", default = args.sound_enabled, label_color = GUI2.TEXT_NORMAL,
		skin = control_skin).value;
	GUI2.space(state, 8);
	layout_options :: string.[ "AZERTY", "QWERTY" ];
	layout_dropdown := GUI2.labeled_dropdown(state, "Keyboard", layout_options, popup_size.x - 64, 32,
		id = "keyboard_dropdown", default_index = cast(int) args.keyboard_layout,
		label_color = GUI2.TEXT_NORMAL, skin = control_skin);
	ret.keyboard_layout = cast(Layout) layout_dropdown.value;
	ret.layout_changed = layout_dropdown.changed;
	GUI2.space(state, 8);
	shadows_checkbox := GUI2.labeled_checkbox(state, "Shadows", popup_size.x - 64, 24,
		id = "shadows_checkbox", default = args.shadows_enabled, label_color = GUI2.TEXT_NORMAL,
		skin = control_skin);
	ret.shadows_enabled = shadows_checkbox.value;
	ret.shadows_changed = shadows_checkbox.changed;
	GUI2.space(state, 8);
	lighting_checkbox := GUI2.labeled_checkbox(state, "Lighting", popup_size.x - 64, 24,
		id = "lighting_checkbox", default = args.lighting_enabled, label_color = GUI2.TEXT_NORMAL,
		skin = control_skin);
	ret.lighting_enabled = lighting_checkbox.value;
	ret.lighting_changed = lighting_checkbox.changed;
	GUI2.space(state, 8);
	shadow_samples_options :: string.[ "4 samples", "9 samples", "25 samples" ];
	shadow_samples := GUI2.labeled_dropdown(state, "Shadow quality", shadow_samples_options,
		popup_size.x - 64, 32, id = "shadow_samples_dropdown",
		default_index = args.shadow_samples_index, label_color = GUI2.TEXT_NORMAL, skin = control_skin);
	ret.shadow_samples_index = shadow_samples.value;
	ret.shadow_samples_changed = shadow_samples.changed;
	GUI2.space(state, 8);
	aa_options :: string.[ "FXAA", "MSAA 2x", "MSAA 4x", "No AA" ];
	aa := GUI2.labeled_dropdown(state, "Anti-aliasing", aa_options, popup_size.x - 64, 32,
		id = "aa_mode_dropdown", default_index = args.aa_mode_index,
		label_color = GUI2.TEXT_NORMAL, skin = control_skin);
	ret.aa_mode_index = aa.value;
	ret.aa_mode_changed = aa.changed;
	GUI2.space(state, 8);
	shadow_map_options :: string.[ "1024", "2048", "4096" ];
	shadow_map := GUI2.labeled_dropdown(state, "Shadow map", shadow_map_options, popup_size.x - 64, 32,
		id = "shadow_map_dropdown", default_index = args.shadow_map_size_index,
		label_color = GUI2.TEXT_NORMAL, skin = control_skin);
	ret.shadow_map_size_index = shadow_map.value;
	ret.shadow_map_size_changed = shadow_map.changed;
	GUI2.space(state, 8);
	particles_checkbox := GUI2.labeled_checkbox(state, "Particles", popup_size.x - 64, 24,
		id = "particles_checkbox", default = args.particles_enabled, label_color = GUI2.TEXT_NORMAL,
		skin = control_skin);
	ret.particles_enabled = particles_checkbox.value;
	ret.particles_changed = particles_checkbox.changed;
	GUI2.space(state, 8);
	props_checkbox := GUI2.labeled_checkbox(state, "Props", popup_size.x - 64, 24,
		id = "props_checkbox", default = args.props_enabled, label_color = GUI2.TEXT_NORMAL,
		skin = control_skin);
	ret.props_enabled = props_checkbox.value;
	ret.props_changed = props_checkbox.changed;
	GUI2.end(state);

	return ret;
}
