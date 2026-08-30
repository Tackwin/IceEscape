Game_Page :: struct {
	rebuild_pipelines := false;
	sound_enabled := false;

	Stats :: struct {
		win_count := 0;
		death_count := 0;
		revive_count := 0;
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
		state.scene.info = sync_scene.info;
		state.scene.end_scene_countdown_started = false;
		state.scene.params = sync_scene.params;
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

		state.scene.server_rng = sync_scene.rng;
		return true;
	}

	return Scene.process(*state.scene, command, controls.time, response);
}

gui_game_loop :: (app_user: *App_User, scene: Scene.Scene) {
	using app_user;

	GUI.push_action_palette(*gui_state, scene);
	GUI.push_buy_prompt(*gui_state, *scene);

	{
		name: string;
		name.data = state.scene.info.name.data;
		name.count = state.scene.info.name.count;
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
		push_score_tab(state.scene, *state.game, *app_user.gui_state);
	}
	GUI.push_death_indicator(*app_user.gui_state, state.scene);

	if state.playing.escape_menu_open {
		escape_args: GUI.Escape_Menu_Args;
		escape_args.sound_enabled = state.volume_on;
		escape_args.keyboard_layout = state.keyboard_layout;
		escape_args.shadows_enabled = state.shadows_enabled;
		escape_args.lighting_enabled = state.light_enabled;
		escape_args.shadow_samples_index = cast(int) state.shadow_samples;
		escape_args.aa_mode_index = cast(int) state.aa_mode;
		escape_args.particles_enabled = state.particles_enabled;
		escape_args.props_enabled = state.props_enabled;
		escape_args.shadow_map_size_index = cast(int) state.shadow_map_size;
		ret := GUI.push_escape_menu(*app_user.gui_state, escape_args);

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
		// gui_demo_page(*gui_state, .{ 200, 500 }, 1024 );
		GUI.push_ms_histogram(
			*gui_state,
			.{ 10, 10 },
			.{ 600, 150 },
			state.history_app_render_loop_dt,
			state.history_app_render_cursor,
			"Render"
		);
		GUI.push_ms_histogram(
			*gui_state,
			.{ 10, 170 },
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
		GUI.push_ping_histogram(*gui_state, .{ 10, 330 }, .{ 300, 150 }, history_ping, ping_cursor);
	}
}

input_game_loop :: (app_user: *App_User) {
	using app_user;
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
	state.scene.client.render_particles = app_user.state.particles_enabled;
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

	// Flush the command buffer
	for * state.scene.client_to_server {
		send_web_message(app.platform, controls.time, it);
	}
	state.scene.client_to_server.count = 0;

	// Rendering
	frame := WRender.begin_frame(*framegraph, controls.time);
	WRender.render_scene(frame, *framegraph, state.scene, store);
	WRender.render_gui(frame, *framegraph, app_user.gui_state, *store);
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
}


push_score_tab :: (scene: Scene.Scene, page: *Game_Page, state: *GUI.GUI_State) {
	scoreboard_center := state.controls.window_size / 2;
	scoreboard_center.y += state.controls.window_size.y / 12;
	scoreboard_size := V2f.{ 600, 400 };
	header_height := 32.0;

	cursor := V2f.{
		scoreboard_center.x - scoreboard_size.x / 2,
		scoreboard_center.y - scoreboard_size.y / 2
	};

	GUI.push_quad_screen(
		state,
		pos = cursor,
		size = scoreboard_size,
		color = GUI.COLOR_BACK_A,
		z = 5
	);

	GUI._atom_label(
		state,
		string_from_arr(scene.info.name),
		_pos = .{ cursor.x + scoreboard_size.x / 2, cursor.y + scoreboard_size.y - header_height / 2 },
		_z = 10,
		_align = .Center
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

		GUI._atom_label(
			state,
			wr_string,
			_pos = .{ cursor.x + 16, cursor.y - header_height / 2 + 1 },
			_z = 100,
			_align = .Center_Left
		);
	}

	GUI._atom_label(
		state,
		tprint("Next up: %", page.next_terrain_name),
		_pos = .{ cursor.x + scoreboard_size.x - 16, cursor.y - header_height / 2 + 1 },
		_z = 100,
		_align = .Center_Right
	);

	cursor += V2f.{ 0, scoreboard_size.y };
	GUI.push_quad_screen(
		state,
		pos = .{ cursor.x, cursor.y - header_height },
		size = .{ scoreboard_size.x, header_height },
		color = GUI.COLOR_SOMBER_A,
		z = 6
	);
	GUI.push_quad_screen(
		state,
		pos = .{ cursor.x, cursor.y - scoreboard_size.y - header_height },
		size = .{ scoreboard_size.x, header_height },
		color = GUI.COLOR_SOMBER_A,
		z = 6
	);
	GUI.push_quad_screen(
		state,
		pos = .{ cursor.x, cursor.y - scoreboard_size.y },
		size = .{ scoreboard_size.x, 1 },
		color = .{ 1.0, 1.0, 1.0 },
		z = 7
	);

	cursor -= V2f.{ 0, header_height };
	GUI.push_quad_screen(
		state,
		pos = .{ cursor.x, cursor.y - 1 },
		size = .{ scoreboard_size.x, 1 },
		color = .{ 1.0, 1.0, 1.0 },
		z = 7
	);

	scoreline_size := V2f.{ scoreboard_size.x / 2, 48 };

	push_scoreline :: (x: float, y: float, player: Scene.Player) #expand {
		stat := table_find_pointer(*page.player_stats, player.id);
		if !stat
			return;
		
		cursor := scoreboard_center;
		cursor.x -= scoreboard_size.x / 2;
		cursor.y += scoreboard_size.y / 2;
		cursor.y -= header_height + 1;
		cursor.x += x * scoreline_size.x;
		cursor.y -= (y + 1) * scoreline_size.y;

		model_size :: V2f.{ 48, 48 };
		icon_size :: V2f.{ 24, 24 };

		GUI.push_quad_screen(
			state,
			pos = cursor,
			size = scoreline_size,
			color = GUI.COLOR_HIGHLIGHT_A,
			z = 10
		);
		GUI.push_quad_screen(
			state,
			pos = .{ cursor.x + 1, cursor.y + 1 },
			size = .{ scoreline_size.x - 2, scoreline_size.y - 2 },
			color = GUI.COLOR_BACK_A,
			z = 11
		);

		GUI.push_quad_texture(
			state,
			pos = .{ cursor.x + 4, cursor.y + (scoreline_size.y - model_size.y) / 2 },
			size = model_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = GUI.model_id_to_slot(xx player.server.model_id),
			z = 12
		);

		cursor.x += 16;

		GUI.push_quad_texture(
			state,
			pos = .{
				cursor.x + 4 + model_size.x + 4,
				cursor.y + (scoreline_size.y - icon_size.y) / 2
			},
			size = icon_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = GUI.AWARD_SLOT,
			z = 12
		);
		GUI.atom_label(
			state,
			tprint("%", stat.win_count),
			.{ cursor.x + 4 + model_size.x + 32, cursor.y + scoreline_size.y / 2 },
			scale = 18,
			z = 12,
			align = GUI.Align.Center_Left,
			outline = true,
			id = 0
		);

		GUI.push_quad_texture(
			state,
			pos = .{
				cursor.x + model_size.x + 4 + 32 + icon_size.x + 4,
				cursor.y + (scoreline_size.y - icon_size.y) / 2
			},
			size = icon_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = GUI.REVIVE_SLOT,
			z = 12
		);
		GUI.atom_label(
			state,
			tprint("%", stat.revive_count),
			.{
				cursor.x + 4 + model_size.x + 32 + icon_size.x + 32,
				cursor.y + scoreline_size.y / 2
			},
			scale = 18,
			z = 12,
			align = GUI.Align.Center_Left,
			outline = true,
			id = 1
		);

		GUI.push_quad_texture(
			state,
			pos = .{
				cursor.x + model_size.x + 4 + 32 + icon_size.x + 4 + 32 + icon_size.x + 4,
				cursor.y + (scoreline_size.y - icon_size.y) / 2
			},
			size = icon_size,
			color = .{ 1.0, 1.0, 1.0 },
			tex_slot = GUI.DEATH_SLOT,
			z = 12
		);
		GUI.atom_label(
			state,
			tprint("%", stat.death_count),
			.{
				cursor.x + 4 + model_size.x + 32 + icon_size.x + 32 + icon_size.x + 32,
				cursor.y + scoreline_size.y / 2
			},
			scale = 18,
			z = 12,
			align = GUI.Align.Center_Left,
			outline = true,
			id = 2
		);
	}

	for scene.players {
		x := it_index / 8;
		y := it_index % 8;
		push_scoreline(x.(float32), y.(float32), it);
	}
}