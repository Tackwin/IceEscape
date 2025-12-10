gui_game_loop :: (app_user: *App_User, scene: Scene.Scene) {
	using app_user;

	defer {
		state.history_cursor += 1;
		state.history_cursor %= state.history_dt.count;
	}
	state.history_dt[state.history_cursor] = controls.delta_time;

	GUI.push_action_palette(*gui_state, scene);
	GUI.push_settings(*gui_state, *state.volume_on);
	GUI.push_buy_prompt(*gui_state, *scene);

	{
		name: string;
		name.data = state.scene.name.data;
		name.count = 64;
		for name if it == 0 { name.count = it_index; break; }
		label := GUI.atom_label(
			*app_user.gui_state,
			name,
			V2f.{ 4, controls.window_size.y - 4 },
			24,
			1,
			align = .Top_Left,
			outline = true
		);

		player := Scene.find_by_player_id(state.scene, state.scene.controlled_player_id);
		if player {
			GUI.push_point_ui(*app_user.gui_state, player);
		}
	}

	if state.scene.end_scene_countdown_started {
		GUI.push_end_screen(*app_user.gui_state, state.scene);
	}

	GUI.push_breaking_news(*app_user.gui_state, state.news);
	if controls.pressed[Key.Tab] {
		GUI.push_score_tab(*app_user.gui_state, state.scene);
	}
	GUI.push_death_indicator(*app_user.gui_state, state.scene);

	if state.playing.escape_menu_open {
		ret := GUI.push_escape_menu(*app_user.gui_state);
		if ret.resume_clicked {
			state.playing.escape_menu_open = false;
		}
		if ret.leave_instance_clicked {
			command: Command.Leave_Instance;
			send_web_message(app.platform, make_command(command));
			state.screen_state = .Menu;
			state.playing.escape_menu_open = false;
		}
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

			GUI.atom_label(*gui_state, tprint("%", kind), V2f.{ 500, 10 + y * 20.0 }, 18);
			y += 1;
		}

		for * state.filter_command_debug {
			if GUI.checkbox(
				*gui_state,
				V2f.{ 400, 10.0 + it_index * 20.0 },
				18,
				id = tprint("Filter %", it_index.(Command.payload.Kind))
			).just_checked
				state.filter_command_debug[it_index] = !state.filter_command_debug[it_index];
			GUI.atom_label(
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
					gui_state.controls.mouse_pos.y / gui_state.controls.window_size.y * 2 - 1
				},
				V,
				P
			);
			target, ok := ray_plane(scene.camera.position, r, .{ 0, 0, 1 });
			if ok {
				GUI.atom_label(
					*gui_state,
					tprint("Mouse under square % %", target.x.(int), target.y.(int)),
					pos = V2f.{ 4, gui_state.controls.window_size.y - 4 },
					scale = 14,
					z = 5,
					GUI.Align.Top_Left,
					outline = true
				);
			}
		}
	}

	if state.render_fps {
		GUI.push_fps_histogram(
			*gui_state, .{ 10, 10 }, .{ 300, 150 }, state.history_dt, state.history_cursor
		);

		history_ping := NewArray(state.ntp_history.count, float32, false,, temp);
		for * history_ping {
			it.* = xx state.ntp_history[it_index].ping;
		}
		ping_cursor := (state.ntp_history_cursor + history_ping.count - 1) % history_ping.count;
		GUI.push_ping_histogram(*gui_state, .{ 10, 170 }, .{ 300, 150 }, history_ping, ping_cursor);
	}
}

input_game_loop :: (app_user: *App_User) {
	using app_user;
	if controls.just_pressed[Key.Escape] {
		app_user.state.playing.escape_menu_open = !app_user.state.playing.escape_menu_open;
	}
	if controls.just_pressed[Key.Tab] {
		command: Command.Request_Score;
		cursor := 0;
		for * state.scene.players {
			if cursor < command.player_ids.count {
				command.player_ids[cursor] = it.id;
				cursor += 1;
			}
		}
		send_web_message(app.platform, make_command(command));
	}
	if controls.pressed[Key.N] && controls.pressed[Key.P] {
		if controls.just_pressed[Key.K] {
			command: Command.Cheat_Action;
			command.kind = .Next_Level;
			send_web_message(app.platform, make_command(command));
		}
		if controls.just_pressed[Key.L] {
			command: Command.Cheat_Action;
			command.kind = .Reset_Level;
			send_web_message(app.platform, make_command(command));
		}
		if controls.just_pressed[Key.M] {
			command: Command.Cheat_Action;
			command.kind = .Reset_Progression;
			send_web_message(app.platform, make_command(command));
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
					controls.mouse_pos.y / controls.window_size.y * 2 - 1
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
				send_web_message(app.platform, make_command(command));
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
	if !app_user.gui_state.handled_mouse {
		Scene.input(*state.scene, *controls, controls.delta_time, *process_response);
	}
}

update_game_loop :: (app_user: *App_User) {
	using app_user;

	if check(*state.ntp_period) {
		ntp: Command.NTP;
		ntp.client_origin = true;
		ntp.player_id = state.scene.controlled_player_id;
		ntp.t0 = to_float64_seconds(current_time_monotonic());
		ntp.t1 = FLOAT64_MAX;
		ntp.t2 = FLOAT64_MAX;
		ntp.t3 = FLOAT64_MAX;
		Scene.add(*process_response, state.scene.id, ntp);
	}
	Scene.update(*state.scene, controls.delta_time, null);
	update_news(*state.scene, *state.news);
}

game_loop :: (app_user: *App_User) -> bool {
	using app_user;

	app_user.graphics.gpu = app.platform.gpu;
	WRender.graphics = *graphics;

	gui_game_loop(app_user, state.scene);
	input_game_loop(app_user);
	update_game_loop(app_user);
	sounding(*state, *state.scene, store, app.platform);

	// Rendering
	frame := WRender.begin_frame(*framegraph);
	WRender.render_scene(*frame, *framegraph, state.scene, store);
	WRender.render_gui(*frame, *framegraph, app_user.gui_state, store);
	WRender.end_frame(*frame);

	respond(app.platform, process_response);

	return true;
}