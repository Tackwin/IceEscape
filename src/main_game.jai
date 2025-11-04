Terrain :: #import "Terrain";
#import "Math";
#import "Basic";
#import "WAllocator";
#import "Store";
#import "Random";
#import "String";
#import "Algebra";
#import "Platform";
#import "Default_Allocator";
#import "Communication";
#import "Utils";
#import "Hash_Table";
RNG :: #import "Rand";
Controls :: #import "Controls";
WRender :: #import "WRender";
Scene :: #import "Scene";
Assets :: #import "Assets";
GUI :: #import "GUI";
Graphics :: #import "Graphics";
Instance :: #import "Instance";

show_inspector := false;    // Wish we could declare static variables inside functions.

process_complete_ntp :: (state: *State, ntp: Command.NTP) {
	result: State.NTP_Result;
	result.offset = (ntp.t1 + ntp.t2) / 2 - (ntp.t0 + ntp.t3) / 2;
	result.ping = (ntp.t3 - ntp.t0) - (ntp.t2 - ntp.t1);
	result.time = to_float64_seconds(current_time_monotonic());
	state.ntp_history[state.ntp_history_cursor] = result;
	state.ntp_history_cursor += 1;
	state.ntp_history_cursor %= state.ntp_history.count;
}

process :: (state: *State, command: Command, response: *Scene.Process_Response) ->  bool {
	ntp: *Command.NTP = isa(command.payload, Command.NTP);
	if ntp {
		is_over := false;
		send_back := false;
		reply := ntp.*;
		if reply.t0 == FLOAT64_MAX {
			reply.t0 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		} else if reply.t1 == FLOAT64_MAX {
			reply.t1 = to_float64_seconds(current_time_monotonic());
			reply.t2 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		} else if reply.t2 == FLOAT64_MAX {
			reply.t2 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		} else if reply.t3 == FLOAT64_MAX {
			reply.t3 = to_float64_seconds(current_time_monotonic());
			reply.t4 = to_float64_seconds(current_time_monotonic());
			is_over = true;
			send_back = true;
		} else if reply.t4 == FLOAT64_MAX {
			reply.t4 = to_float64_seconds(current_time_monotonic());
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

	sync_scene: *Command.Sync_Scene = isa(command.payload, Command.Sync_Scene);
	if sync_scene {
		Terrain.parse_terrain(sync_scene.terrain, *state.scene);
		state.scene.id = sync_scene.id;
		state.scene.end_scene_countdown_started = false;
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

			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.robots {
			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.antiairs {
			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.tombstones {
			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.presents {
			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.safe_zones {
			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.standins {
			Scene.process(*state.scene, make_command(it), response);
		}

		state.scene.server_rng = sync_scene.rng;
		return true;
	}

	connect: *Command.Connect = isa(command.payload, Command.Connect);
	if connect {
		state.is_connected = true;
		state.platform.set_token(connect.token);
		return true;
	}

	return false;
}

send_web_message :: (platform: Platform, _command: Command) {
	command := _command;
	command.sent_timestamp = to_float64_seconds(current_time_monotonic());
	buffer: [..] u8;
	buffer.allocator = temp;
	serialize(command, *buffer);
	platform.send_web_message(buffer);
}

// 				Scene.process(scene, *scene.player, Scene.make_player_command(command));

parse_web_message :: (state: *State, frame_info: Frame_Info) -> [] Command {
	commands := NewArray(frame_info.message_received_count, Command, false,, temp);

	cursor := 0;
	for 0..frame_info.message_received_count - 1 {
		cmd, ok := deserialize(frame_info.message_received[it]);
		if ok {
			array_add(*state.received_command_history, cmd.payload.kind);
			commands[cursor] = cmd;
			cursor += 1;
		} else {
			print("Failed to deserialize message\n");
		}
	}

	commands.count = cursor;
	return commands;
}

respond :: (platform: Platform, response: Scene.Process_Response) {
	for * response.entries {
		if isa(it.command.payload, Command.NTP)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Move)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Spawn_Coin)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Klaxon)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Active_Item)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Buy_Ask)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Ask_Respawn)
			send_web_message(platform, it.command);
	}
}

#add_context _platform: Platform;


handle_gui :: (frame_info: *Frame_Info, state: *State, scene: Scene.Scene) {
	GUI.handle_frame_info(frame_info);
	defer {
		state.history_cursor += 1;
		state.history_cursor %= state.history_dt.count;
	}
	state.history_dt[state.history_cursor] = frame_info.delta_time;

	GUI.push_action_palette(scene, frame_info);
	GUI.push_settings(*state.volume_on, frame_info);
	GUI.push_buy_prompt(*scene);
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

			GUI.push_text(tprint("%", kind), V2f.{ 500.0, 10.0 + y * 20.0 }, 18);
			y += 1;
		}

		for * state.filter_command_debug {
			GUI.push_text(
				tprint("%", it_index.(Command.payload.Kind)),
				V2f.{ 310.0, 10.0 + it_index * 20.0 },
				18,
				-0.5
			);
			if GUI.push_checkbox(
				V2f.{ 475, 20.0 + it_index * 20.0 }, 18, state.filter_command_debug[it_index]
			)
				state.filter_command_debug[it_index] = !state.filter_command_debug[it_index];
		}

		{
			V := Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
			P := Scene.perspective(scene.camera);
			
			r := Scene.unproject_ndc(
				.{
					frame_info.mouse_position.x / frame_info.window_size.x * 2 - 1,
					frame_info.mouse_position.y / frame_info.window_size.y * 2 - 1
				},
				V,
				P
			);
			target, ok := ray_plane(scene.camera.position, r, .{ 0, 0, 1 });
			if ok {
				GUI.push_text(
					tprint("Mouse under square % %", target.x.(int), target.y.(int)),
					pos = V2f.{ 20, frame_info.window_size.y - 20 },
					height = 18,
					z = 5,
					GUI.Text_Align.Top_Left
				);
			}
		}
	}

	if state.render_fps {
		GUI.push_fps_histogram(.{ 10, 10 }, .{ 300, 150 }, state.history_dt, state.history_cursor);

		history_ping := NewArray(state.ntp_history.count, float32, false,, temp);
		for * history_ping {
			it.* = xx state.ntp_history[it_index].ping;
		}
		ping_cursor := (state.ntp_history_cursor + history_ping.count - 1) % history_ping.count;
		GUI.push_ping_histogram(.{ 10, 170 }, .{ 300, 150 }, history_ping, ping_cursor);

		#if OS == .WASM {
			header := get_header();
			bit_array := cast(*u8)(header + 1);
			n := header.total_number_of_pages_allocated;
			for 0..n-1 {
				x := it % 300;
				y := it / 300;

				B := it / 8;
				b := it % 8;

				x *= 4;
				y *= 4;
				x += 200;
				y += 200;
				color := ifx (bit_array[B] & (1 << b)) != 0
					then V3f.{ 0.0, 1.0, 0.0 }
					else V3f.{ 1.0, 0.0, 0.0 };
				GUI.push_quad_screen(V2f.{ xx x, xx y }, V2f.{ xx 3, xx 3 }, color, 100);
			}
		}
	}
}

update_news :: (scene: *Scene.Scene, news: *[..] Scene.Breaking_News) {
	current_time := current_time_monotonic();
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

main :: () {
	context.allocator = .{ wallocator_proc, null };
	context.temporary_storage.overflow_allocator = context.allocator;
	platform := init_platform();
	context._platform = platform;
	rhi := platform.rhi;
	context.gpu = platform.gpu;

	Graphics.init_graphics();
	store: Store;
	init_store(platform, *store);
	GUI.im_init();

	frame_info := New(Frame_Info);
	defer free(frame_info);

	framegraph: WRender.WFramegraph;
	WRender.init_framegraph(*framegraph, *store);

	state: State;
	state.platform = *platform;
	scene := *state.scene;
	{
		connect: Command.Connect;
		connect.token =  platform.get_token();
		send_web_message(platform, make_command(connect));
		state.connected_last_try = current_time_monotonic();
	}

	scene.camera.position = .{ 0, -4, 8 };
	scene.camera.target = .{ 0, 0, 0 };
	scene.camera.target_target = scene.camera.target;
	scene.camera.wanted_target_to_position = scene.camera.position - scene.camera.target;
	scene.camera.fov = 55;
	scene.camera.max_distance = norm(scene.camera.wanted_target_to_position);

	controls := New(Controls.State);

	for * state.filter_command_debug
		it.* = true;
	state.filter_command_debug[xx Command.payload.Kind.Sync_Player] = false;
	state.filter_command_debug[xx Command.payload.Kind.NTP] = false;

	process_response: Scene.Process_Response;
	{
		store.snowflakes_and_lights_mp3.kind = .Music;
		store.snowflakes_and_lights_mp3.repeating = true;
		store.snowflakes_and_lights_mp3.volume = 0.05;
		platform.play_audio(*store.snowflakes_and_lights_mp3, .{});
	}

	// Main loop
	done := false;
	while !done {
		reset_temporary_storage();
		t00 := current_time_monotonic();

		if !state.is_connected && to_float64_seconds(t00 - state.connected_last_try) > 0.5 {
			connect: Command.Connect;
			connect.token =  platform.get_token();
			send_web_message(platform, make_command(connect));
			state.connected_last_try = current_time_monotonic();
		}
		platform.get_frame_info(frame_info);
		handle_gui(frame_info, *state, scene);
		Controls.update(controls, frame_info);
		controls.maskoff = .{};
		controls.maskoff.mouse = GUI.IM.handled_mouse;

		if frame_info.quit
			done = true;

		if controls.just_pressed[Key.Tab] {
			command: Command.Request_Score;
			cursor := 0;
			for * scene.players {
				if cursor < command.player_ids.count {
					command.player_ids[cursor] = it.id;
					cursor += 1;
				}
			}
			send_web_message(platform, make_command(command));
		}
		if controls.pressed[Key.N] && controls.pressed[Key.P] {
			if controls.just_pressed[Key.K] {
				command: Command.Cheat_Action;
				command.kind = .Next_Level;
				send_web_message(platform, make_command(command));
			}
			if controls.just_pressed[Key.L] {
				command: Command.Cheat_Action;
				command.kind = .Reset_Level;
				send_web_message(platform, make_command(command));
			}
			if controls.just_pressed[Key.M] {
				command: Command.Cheat_Action;
				command.kind = .Reset_Progression;
				send_web_message(platform, make_command(command));
			}
			if controls.just_pressed[Key.U] {
				command: Command.Cheat_Action;
				command.kind = .Kick;
				V := Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
				P := Scene.perspective(scene.camera);
				r := Scene.unproject_ndc(
					.{
						controls.frame_info.mouse_position.x / controls.frame_info.window_size.x * 2 - 1,
						controls.frame_info.mouse_position.y / controls.frame_info.window_size.y * 2 - 1
					},
					V,
					P
				);
				target, ok := ray_plane(scene.camera.position, r, .{ 0, 0, 1 });
				if ok {
					closest_d := FLOAT32_MAX;
					closest_player_id := -1;
					for scene.players {
						p := it.client.position;
						d := norm(target - p);

						if d < closest_d {
							closest_d = d;
							closest_player_id = it.id;
						}
					}
					command.player_id = closest_player_id;
					send_web_message(platform, make_command(command));
				}

			}
		}

		if controls.just_pressed[Key.H] {
			state.render_fps = !state.render_fps;
		}
		if controls.just_pressed[Key.P] {
			state.render_command_debug = !state.render_command_debug;
		}
		{
			name: string;
			name.data = scene.name.data;
			name.count = 64;
			for name if it == 0 { name.count = it_index; break; }
			size := GUI.push_text(
				name,
				V2f.{ 12, frame_info.framebuffer_size.y - 32 },
				24,
				1,
				align = .Top_Left
			);
			GUI.push_quad_screen(
				V2f.{ 10, frame_info.framebuffer_size.y - size.y - 14 },
				V2f.{ size.x + 10, size.y + 6 },
				GUI.COLOR_BRIGHT_A,
				0,
			);
			cursor := V2f.{ 10, frame_info.framebuffer_size.y - size.y - 14 - 14 - 6 };

			player := Scene.find_by_player_id(scene, scene.controlled_player_id);
			if player {
				GUI.push_point_ui(player);
			}
		}

		if scene.end_scene_countdown_started {
			GUI.push_end_screen(scene);
		}

		#if OS == .WINDOWS {
			changes: [] string;
			changes.data = frame_info.file_change.data;
			changes.count = frame_info.file_change_count;
			check_change(*store, changes);
		}

		Scene.clear(*process_response);
		scene.sound_triggers.count = 0;
		if !GUI.IM.handled_mouse {
			Scene.input(scene, controls, frame_info.delta_time, *process_response);
		}
		commands := parse_web_message(*state, frame_info);
		for commands {
			if process(*state, it, *process_response)
				continue;
			if Scene.process(scene, it, *process_response)
				continue;
		}
		if check(*state.ntp_period) {
			ntp: Command.NTP;
			ntp.client_origin = true;
			ntp.player_id = scene.controlled_player_id;
			ntp.t0 = to_float64_seconds(current_time_monotonic());
			ntp.t1 = FLOAT64_MAX;
			ntp.t2 = FLOAT64_MAX;
			ntp.t3 = FLOAT64_MAX;
			Scene.add(*process_response, scene.id, ntp);
		}
		respond(platform, process_response);
		Scene.update(scene, frame_info.delta_time, null);
		update_news(scene, *state.news);

		GUI.push_breaking_news(state.news);
		if controls.pressed[Key.Tab] {
			GUI.push_score_tab(scene);
		}
		GUI.push_death_indicator(scene);
		sounding(*state, scene, store);
		WRender.render(*framegraph, scene, store);

		context.gpu.surfacePresent(context.graphics.surface);
		platform.end_frame();

		// while to_float64_seconds(current_time_monotonic() - t00) < 1.0 / 200.0 {
		// }
	}
}

sounding :: (state: *State, scene: *Scene.Scene, store: Store) {
	skull_seen: Table(int, bool);
	skull_seen.allocator = temp;

	shurikens_seen: Table(int, bool);
	shurikens_seen.allocator = temp;

	for * scene.skulls {
		ok, sound := table_find_new(*state.skull_id_to_sound, it.id);
		if !ok {
			audio := get_boat_sailing(store, 0);
			if !audio
				continue;
			audio.kind = .Sound;
			audio.exponent = 2.5;
			audio.volume = 0.04;
			sound = context._platform.play_audio(audio, .{});
			sound.volume = audio.volume;
			sound.loop = true;
			context._platform.set_sound(sound);
			table_set(*state.skull_id_to_sound, it.id, sound);
		}
		sound.position = Scene.compute_skull_pos(scene, it.*);
		context._platform.set_sound(sound);
		table_set(*skull_seen, it.id, true);
	}

	for * scene.shurikens {
		ok, sound := table_find_new(*state.shurikens_id_to_sound, it.id);
		if !ok {
			audio := get_drone_buzzing(store, 0);
			if !audio
				continue;
			audio.kind = .Sound;
			audio.exponent = 2.5;
			audio.volume = 0.010;
			sound = context._platform.play_audio(audio, .{});
			sound.volume = audio.volume;
			sound.loop = true;
			context._platform.set_sound(sound);
			table_set(*state.shurikens_id_to_sound, it.id, sound);
		}
		frame := Scene.find_by_frame_id(scene, it.frame_id);
		if !frame
			continue;
		M := Scene.compute_moving_frame_server_world_matrix(scene, frame);
		pos := M * v4(it.server.position, 1);
		sound.position = v3(pos);
		context._platform.set_sound(sound);
		table_set(*shurikens_seen, it.id, true);
	}

	for value, key: state.skull_id_to_sound {
		if !table_contains(*skull_seen, key) {
			value.playing = false;
			context._platform.set_sound(value);
			table_remove(*state.skull_id_to_sound, key);
		}
	}

	for value, key: state.shurikens_id_to_sound {
		if !table_contains(*shurikens_seen, key) {
			value.playing = false;
			context._platform.set_sound(value);
			table_remove(*state.shurikens_id_to_sound, key);
		}
	}

	listener: Listener;
	listener.position = scene.camera.position;
	listener.direction = scene.camera.target - scene.camera.position;
	listener.position += listener.direction * 0.65;
	listener.direction = normalize(listener.direction);
	context._platform.set_listener_info(listener);
	for scene.sound_triggers {
		for counter: 1..it.count {
			audio: Audio;
			audio.id = -1;
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
			}
			if audio.id == -1
				continue;
			if it.inhead
				audio.exponent = 0.0;

			audio.pitch = RNG.random_uniform(*scene.client_rng, 0.8, 1.2);
			audio.kind = .Sound;
			audio.repeating = false;
			audio.delay = counter * 50; // Stagger sounds to avoid audio clutter.
			context._platform.play_audio(*audio, it.position);
		}
	}

	if state.volume_on {
		context._platform.volume_audio(1.0);
	} else {
		context._platform.volume_audio(0.0);
	}
}


State :: struct {
	platform: *Platform;
	scene: Scene.Scene;

	is_connected := false;
	connected_last_try: Apollo_Time;

	ntp_period: Period(0.15);
	NTP_Result :: struct {
		offset: float64 = 0;
		ping: float64 = 0;
		time: float64 = 0;
	}

	ntp_history: [64] NTP_Result;
	ntp_history_cursor := 0;

	received_command_history: [..] Command.payload.Kind;
	
	history_dt: [100] float;
	history_cursor := 0;
	render_fps := false;
	render_command_debug := false;
	filter_command_debug: [#run enum_highest_value(Command.payload.Kind) + 1] bool;

	volume_on := true;

	skull_id_to_sound: Table(int, Sound);
	shurikens_id_to_sound: Table(int, Sound);

	news: [..] Scene.Breaking_News;
}