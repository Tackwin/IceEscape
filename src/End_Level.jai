End_Level_Preview :: struct {
	active := false;
	result: Play_Session.Result;
	presentation: Play_Session.Presentation;
}

capture_end_level_result :: (app_user: *App_User, event: Command.End_Level) {
	// End_Level starts the countdown, but only a requested snapshot replaces
	// the client's live session. The event contains wire data, not owned state.
	app_user.state.play_session.client.end_level_round_id = event.result.round_id;
	request_play_session(app_user, event.instance_id, event.session_id, event.session_revision);
}

refresh_end_level_presentation :: (app_user: *App_User) {
	session := *app_user.state.play_session;
	result := Play_Session.latest_result(session);
	if !result return;
	push_allocator(session.allocator);
	scene := *app_user.state.scene;
	if !result.next_level_name.count result.next_level_name = copy_string(app_user.state.game.next_terrain_name);
	if result.level_id == scene.info.id && scene.client.leaderboard_run_counter == scene.run_generation {
		free(result.record.holder);
		result.record.holder = copy_string(scene.client.leaderboard.wr_username);
		result.record.time_ms = scene.client.leaderboard.wr_time_ms;
		result.record.status = ifx result.record.time_ms > 0 then .Available else .Missing;
	}
}

update_end_level_record :: (app_user: *App_User, record: Command.Get_Terrain_Leaderboard) {
	session := *app_user.state.play_session;
	result := Play_Session.latest_result(session);
	if !result || result.level_id != record.terrain_id return;
	push_allocator(session.allocator);
	free(result.record.holder);
	result.record.holder = copy_string(record.wr_username);
	result.record.time_ms = record.wr_time_ms;
	result.record.status = ifx record.wr_time_ms > 0 then .Available else .Missing;
}

set_end_level_preview :: (app_user: *App_User, action: End_Level_Preview_Action) {
	preview := *app_user.end_level_preview;
	if action == .Hide {
		preview.active = false;
		Play_Session.clear_result(*preview.result);
		return;
	}
	if action != .Show return;

	players := Play_Session.Player_Result.[
		.{ player_id = 11, display_name = "Racer", icon_id = xx Scene.Model_Id.Racer, death_count = 15, revive_count = 5, win_count = 1 },
		.{ player_id = 23, display_name = "Ambulance", icon_id = xx Scene.Model_Id.Ambulance, death_count = 4, revive_count = 13 },
		.{ player_id = 37, display_name = "Police", icon_id = xx Scene.Model_Id.Police, death_count = 3, revive_count = 5 },
		.{ player_id = 49, display_name = "Taxi", icon_id = xx Scene.Model_Id.Taxi, death_count = 1, revive_count = 2 },
		.{ player_id = 61, display_name = "Speedster", icon_id = xx Scene.Model_Id.Speedster, death_count = 1, revive_count = 0 },
		.{ player_id = 73, display_name = "SUV", icon_id = xx Scene.Model_Id.SUV, death_count = 1, revive_count = 0 }
	];
	// Includes direct shares, indirect shares, and a winner/rescuer cycle.
	revives := int.[
		0, 3, 1, 1, 0, 0,
		12, 0, 1, 0, 0, 0,
		3, 1, 0, 0, 1, 0,
		0, 0, 1, 0, 0, 1,
		0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0
	];
	result: Play_Session.Result;
	result.level_id = 1;
	result.level_name = "Big Turn";
	result.next_level_name = "Big Ship";
	result.duration_ms = 83427;
	result.winner_id = 11;
	result.most_death_id = 37;
	result.most_revive_id = 23;
	result.players = players;
	result.revives = revives;
	result.has_player_statistics = true;
	result.record.status = .Available;
	result.record.time_ms = 79215;
	result.record.holder = "SnowRunner";
	result.personal_share_weight = Play_Session.PERSONAL_SHARE_WEIGHT;
	Play_Session.calculate(*result, temp);
	Play_Session.copy_result(result, *preview.result);
	preview.presentation = .{ clock = 0, countdown_remaining = 6 };
	preview.active = true;
}

handle_end_level_preview :: (app_user: *App_User) {
	action := app_user.allocated_frame_info.end_level_preview_action;
	if app_user.console.end_level_preview_action != .None {
		action = app_user.console.end_level_preview_action;
		app_user.console.end_level_preview_action = .None;
	}
	set_end_level_preview(app_user, action);
	if app_user.end_level_preview.active {
		app_user.end_level_preview.presentation.clock += max(0.0, app_user.controls.delta_time);
		app_user.end_level_preview.presentation.countdown_remaining = max(cast(float64) 0, 6.0 - app_user.end_level_preview.presentation.clock);
	}
}

push_end_level_preview :: (app_user: *App_User) {
	preview := *app_user.end_level_preview;
	if !preview.active return;
	GUI.push_end_screen(*app_user.gui_state, preview.result, preview.presentation, *app_user.store);
}
