Game_Page :: struct {
	sound_enabled := false;

	Stats :: struct {
		win_count := 0;
		death_count := 0;
		revive_count := 0;
	}
	player_stats: Table(int, Stats);
}

process_game :: (
	state: *State, command: Command, controls: Controls.State, response: *Scene.Process_Response
) ->  bool {
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

	sync_stats: *Command.Sync_Stats = isa(command.payload, Command.Sync_Stats);
	if sync_stats {
		stats := table_find_pointer(*state.game.player_stats, sync_stats.player_id);
		if !stats {
			stats = table_add(*state.game.player_stats, sync_stats.player_id, .{});
		}

		stats.win_count = sync_stats.wins;
		stats.death_count = sync_stats.death;
		stats.revive_count = sync_stats.revive;
		return true;
	}

	note_played: *Command.Note_Played = isa(command.payload, Command.Note_Played);
	if note_played {
		jukebox := Scene.find_by_jukebox_id(state.scene, note_played.jukebox_id);
		if jukebox {
			pitches :: float.[ 67, 66, 63, 57, 56, 64, 68, 72 ];

			trigger: Scene.Sound_Trigger;
			trigger.kind = .Note;
			trigger.pitch = xx (pitches[note_played.pitch % pitches.count] - 56);
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
		Scene.clear_scene_run(*state.scene);
		Terrain.parse_terrain(sync_scene.terrain, *state.scene);
		state.scene.id = sync_scene.id;
		state.scene.end_scene_countdown_started = false;
		state.scene.params = sync_scene.params;
		state.scene.auto_revive |= sync_scene.params.auto_revive;
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

		state.scene.server_rng = sync_scene.rng;
		return true;
	}

	return Scene.process(*state.scene, command, controls.time, response);
}

gui_game_loop :: (app_user: *App_User, scene: Scene.Scene) {
	using app_user;

	defer {
		state.history_cursor += 1;
		state.history_cursor %= state.history_dt.count;
	}
	state.history_dt[state.history_cursor] = controls.delta_time;

	GUI.push_action_palette(*gui_state, scene);
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
		GUI.push_quad_screen(
			*app_user.gui_state, .{ label.aabb_min, label.aabb_max }, GUI.COLOR_SOMBER_A, 0, a = 0.45
		);

		player := Scene.find_by_player_id(state.scene, state.scene.controlled_player_id);
		if player {
			GUI.push_point_ui(*app_user.gui_state, player);
		}
	}
	{
		time := state.scene.client.clock;
		minutes := floor(time / 60);
		seconds := fmod_cycling(time, 60);
		milliseconds := frac(time) * 1000;
		label := GUI.atom_label(
			*app_user.gui_state,
			tprint(
				"%:%s %ms",
				formatInt(minutes.(int), minimum_digits = 3, padding = #char "_"),
				formatInt(seconds.(int), minimum_digits = 2, padding = #char "_"),
				formatInt(milliseconds.(int), minimum_digits = 3, padding = #char "_")
			),
			app_user.gui_state.controls.window_size,
			scale=18,
			z=1,
			align = .Top_Right,
			outline = true
		);
		GUI.push_quad_screen(
			*app_user.gui_state,
			.{ label.aabb_min, label.aabb_max },
			GUI.COLOR_SOMBER_A,
			0,
			a = 0.45
		);
	}

	if state.scene.end_scene_countdown_started {
		GUI.push_end_screen(*app_user.gui_state, state.scene);
	}

	GUI.push_breaking_news(*app_user.gui_state, state.news);
	if controls.pressed[Key.Tab] {
		GUI.push_score_tab(*app_user.gui_state, state.scene, *state.game.player_stats);
	}
	GUI.push_death_indicator(*app_user.gui_state, state.scene);

	if state.playing.escape_menu_open {
		escape_args: GUI.Escape_Menu_Args;
		escape_args.sound_enabled = state.volume_on;
		ret := GUI.push_escape_menu(*app_user.gui_state, escape_args);
		state.volume_on = ret.sound_checked;
		if ret.resume_clicked {
			state.playing.escape_menu_open = false;
		}
		if ret.leave_instance_clicked {
			command: Command.Leave_Instance;
			send_web_message(app.platform, controls.time, make_command(command));
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
		command: Command.Request_Stats;
		cursor := 0;
		for * state.scene.players {
			if cursor < command.player_ids.count {
				command.player_ids[cursor] = it.id;
				cursor += 1;
			}
		}
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
	if !app_user.gui_state.handled_mouse {
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
	Scene.update(*state.scene, controls.time, controls.delta_time, null);
	update_news(*state.scene, controls.time, *state.news);

	if state.scene.fade_in_screen_t > 0 {
		GUI.push_quad_screen(
			*gui_state,
			AABBf.{ V2f.{ 0, 0 }, controls.window_size },
			.{ 0, 0, 0 },
			z = 100.0,
			state.scene.fade_in_screen_t
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

	// Rendering
	frame := WRender.begin_frame(*framegraph, controls.time);
	WRender.render_scene(*frame, *framegraph, state.scene, store);
	WRender.render_gui(*frame, *framegraph, app_user.gui_state, store);
	WRender.end_frame(*frame);

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
		ok, sound := table_find(*state.shurikens_id_to_sound, it.id);
		if !ok {
			audio := get_drone_buzzing(store, 0);
			if !audio
				continue;
			audio.kind = .Sound;
			audio.exponent = 2.5;
			audio.volume = 0.010;
			sound = platform.play_audio(audio, .{});
			sound.volume = audio.volume;
			sound.loop = true;
			platform.set_sound(sound);
			table_set(*state.shurikens_id_to_sound, it.id, sound);
		}
		frame := Scene.find_by_frame_id(scene, it.frame_id);
		if !frame
			continue;
		M := Scene.compute_moving_frame_server_world_matrix(scene, frame);
		pos := M * v4(it.server.position, 1);
		sound.position = v3(pos);
		platform.set_sound(sound);
		table_set(*shurikens_seen, it.id, true);
	}

	for value, key: state.skull_id_to_sound {
		if !table_contains(*skull_seen, key) {
			value.playing = false;
			platform.set_sound(value);
			table_remove(*state.skull_id_to_sound, key);
		}
	}

	for value, key: state.shurikens_id_to_sound {
		if !table_contains(*shurikens_seen, key) {
			value.playing = false;
			platform.set_sound(value);
			table_remove(*state.shurikens_id_to_sound, key);
		}
	}

	listener: Listener;
	listener.position = scene.camera.position;
	listener.direction = scene.camera.target - scene.camera.position;
	listener.position += listener.direction * 0.65;
	listener.direction = normalize(listener.direction);
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
					audio = store.note_wav;
					audio.pitch = it.pitch;
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

	if state.volume_on {
		platform.volume_audio(1.0);
	} else {
		platform.volume_audio(0.0);
	}
}
