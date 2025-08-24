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
Render :: #import "Render";
Scene :: #import "Scene";
Assets :: #import "Assets";
GUI :: #import "GUI";

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
			is_over = false;
			send_back = true;
		} else if reply.t2 == FLOAT64_MAX {
			reply.t2 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		} else if reply.t3 == FLOAT64_MAX {
			reply.t3 = to_float64_seconds(current_time_monotonic());
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

	sync_scene: *Command.Sync_Scene = isa(command.payload, Command.Sync_Scene);
	if sync_scene {
		Terrain.parse_terrain(sync_scene.terrain, *state.scene);
		state.scene.id = sync_scene.id;
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
	}
}

#add_context _platform: Platform;

main :: () {
	context.allocator = .{ wallocator_proc, null };
	context.temporary_storage.overflow_allocator = context.allocator;
	platform := init_platform();
	context._platform = platform;
	rhi := platform.rhi;

	store: Store;
	init_store(platform, *store);
	Render.im_init(*store);

	clear_color := V4f.{0.45, 0.55, 0.60, 1.00};

	state: State;
	state.platform = *platform;
	scene := *state.scene;
	scene.store = *store;
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

	scene.tile_kind_to_shader[xx Scene.Tile.Kind.None] = null;
	scene.tile_kind_to_shader[xx Scene.Tile.Kind.Ice] = *store.ice_texture;
	scene.tile_kind_to_shader[xx Scene.Tile.Kind.Grass] = *store.grass_texture;
	scene.tile_kind_to_shader[xx Scene.Tile.Kind.Slippy_Ice] = *store.slippy_ice_texture;
	scene.tile_kind_to_shader[xx Scene.Tile.Kind.Dirt] = *store.dirt_texture;

	just_pressed := NewArray(Key_COUNT, bool);
	just_released := NewArray(Key_COUNT, bool);
	pressed := NewArray(Key_COUNT, bool);
	defer {
		array_free(just_pressed);
		array_free(just_released);
		array_free(pressed);
	};

	T := 0;

	history_dt: [100] float;
	history_cursor := 0;
	render_fps := false;
	render_command_debug := false;
	filter_command_debug: [#run enum_highest_value(Command.payload.Kind) + 1] bool;
	for * filter_command_debug
		it.* = true;
	filter_command_debug[xx Command.payload.Kind.Sync_Player] = false;
	filter_command_debug[xx Command.payload.Kind.NTP] = false;

	footstep_trigger_index := 0;
	process_response: Scene.Process_Response;
	{
		store.snowflakes_and_lights_ogg.repeating = true;
		store.snowflakes_and_lights_ogg.volume = 0.15;
		platform.play_audio(*store.snowflakes_and_lights_ogg);
	}

	frame_info := New(Frame_Info);
	defer free(frame_info);

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
		defer {
			history_cursor += 1;
			history_cursor %= history_dt.count;
		}
		history_dt[history_cursor] = frame_info.delta_time;
		Render.IM.display_size = frame_info.framebuffer_size;

		if frame_info.quit
			done = true;
		for * just_pressed {
			if frame_info.key_pressed[it_index] && !pressed[it_index]
				it.* = true;
			else
				it.* = false;
		}
		for * just_released {
			if !frame_info.key_pressed[it_index] && pressed[it_index]
				it.* = true;
			else
				it.* = false;
		}
		for * pressed {
			it.* = frame_info.key_pressed[it_index];
		}
		Render.handle_frame_info(frame_info);

		V := Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
		P := Scene.perspective(scene.camera);

		any_camera_move := false;
		dt := V3f.{ 0, 0, 0 };
		if frame_info.mouse_wheel > 0 {
			scene.camera.wanted_target_to_position *= 0.9;
		}
		if frame_info.mouse_wheel < 0 {
			scene.camera.wanted_target_to_position *= (1.0 / 0.9);
		}
		if pressed[Key.Q] {
			dt.x -= scene.camera.speed * frame_info.delta_time;
			any_camera_move = true;
		}
		if pressed[Key.D] {
			dt.x += scene.camera.speed * frame_info.delta_time;
			any_camera_move = true;
		}
		if pressed[Key.S] {
			dt.y -= scene.camera.speed * frame_info.delta_time;
			any_camera_move = true;
		}
		if pressed[Key.Z] {
			dt.y += scene.camera.speed * frame_info.delta_time;
			any_camera_move = true;
		}
		scene.camera.locked = pressed[Key.Space];
		scene.camera.target_target += dt;
		if scene.camera.locked {
			scene.camera.target += dt;
		}

		if !any_camera_move {
			scene.camera.target_target = scene.camera.target;
		}

		if just_pressed[Key.H] {
			render_fps = !render_fps;
		}
		if just_pressed[Key.P] {
			render_command_debug = !render_command_debug;
		}
		if scene.end_scene_countdown_started {
			dt := to_float64_seconds(current_time_monotonic() - scene.end_scene_countdown_time);
			text := tprint("you have % seconds left to go through the gate !", dt.(s64));

			Render.push_text("Level cleared !", .{ 781, 955 }, 48);
			Render.push_text(text, .{ 398, 850 }, 48);
		}

		T += 1;

		if just_pressed[Key.MouseLeft] {
			r := Scene.unproject_ndc(
				.{
					frame_info.mouse_position.x / frame_info.window_size.x * 2 - 1,
					frame_info.mouse_position.y / frame_info.window_size.y * 2 - 1
				},
				V,
				P
			);

			target, ok := ray_plane(scene.camera.position, r, .{ 0, 0, 1 });
			if ok && scene.state == .Normal {
				if true {
					footstep_trigger_index *= 3;
					footstep_trigger_index += 17;
					index := footstep_trigger_index % 5;
					footstep_trigger_index %= 5 * 1024 * 1024;
					footstep_sound := get_footstep_sound(store, index);
					footstep_sound.volume = (random_get_zero_to_one_new() * 0.2 + 0.1).(float);
					platform.play_audio(footstep_sound);
				}
				command: Command.Move;
				command.ground_target = v2(target);
				command.player_id = scene.controlled_player_id;
				send_web_message(platform, make_command(command));
				scene.mark_clicked_time = current_time_monotonic();
				scene.mark_clicked_pos = target;
			}
		}
		
		if just_pressed[Key.C] {
			player := Scene.find_by_player_id(scene, scene.controlled_player_id);
			if player && !player.server.dead {
				command: Command.Spawn_Coin;
				command.sender = player.id;
				send_web_message(platform, make_command(command));
			}
		}

		#if OS == .WINDOWS {
			changes: [] string;
			changes.data = frame_info.file_change.data;
			changes.count = frame_info.file_change_count;
			check_change(*store, changes);
		}

		Scene.clear(*process_response);
		commands := parse_web_message(*state, frame_info);
		for commands {
			if process(*state, it, *process_response)
				continue;
			if Scene.process(scene, it, *process_response)
				continue;
		}
		if check(*state.ntp_period) {
			ntp: Command.NTP;
			ntp.player_id = scene.controlled_player_id;
			ntp.t0 = to_float64_seconds(current_time_monotonic());
			ntp.t1 = FLOAT64_MAX;
			ntp.t2 = FLOAT64_MAX;
			ntp.t3 = FLOAT64_MAX;
			Scene.add(*process_response, scene.id, ntp);
		}
		respond(platform, process_response);
		Scene.update(scene, frame_info.delta_time, null);

		rhi.glViewport(0, 0, xx frame_info.framebuffer_size.x, xx frame_info.framebuffer_size.y);
		rhi.glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
		rhi.glEnable(GL_BLEND);
		rhi.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		rhi.glEnable(GL_DEPTH_TEST);
		rhi.glEnable(GL_CULL_FACE);
		rhi.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		Scene.render(scene);
		GUI.render_action_palette(frame_info);
		GUI.render_settings(*state.volume_on, frame_info);
		if state.volume_on {
			state.platform.volume_audio(1.0);
		} else {
			state.platform.volume_audio(0.0);
		}

		if render_command_debug {
			n := min(100, state.received_command_history.count);
			y := 0;
			cursor := 0;
			while y < n && cursor < state.received_command_history.count {
				kind := state.received_command_history[
					state.received_command_history.count - 1 - cursor
				];
				cursor += 1;
				kind_idx := kind.(int);
				if !filter_command_debug[kind_idx]
					continue;

				Render.push_text(tprint("%", kind), V2f.{ 500.0, 10.0 + y * 20.0 }, 18);
				y += 1;
			}

			for * filter_command_debug {
				Render.push_text(
					tprint("%", it_index.(Command.payload.Kind)),
					V2f.{ 310.0, 10.0 + it_index * 20.0 },
					18
				);
				if Render.push_checkbox(
					V2f.{ 475, 20.0 + it_index * 20.0 }, 18, filter_command_debug[it_index]
				)
					filter_command_debug[it_index] = !filter_command_debug[it_index];
			}
		}

		if render_fps {
			GUI.render_fps_histogram(.{ 10, 10 }, .{ 300, 150 }, history_dt, history_cursor);

			history_ping := NewArray(state.ntp_history.count, float32, false,, temp);
			for * history_ping {
				it.* = xx state.ntp_history[it_index].ping;
			}
			ping_cursor := (state.ntp_history_cursor + history_ping.count - 1) % history_ping.count;
			GUI.render_ping_histogram(.{ 10, 170 }, .{ 300, 150 }, history_ping, ping_cursor);

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
					color := ifx (bit_array[B] & (1 << b)) != 0 then V3f.{ 0.0, 1.0, 0.0 } else V3f.{ 1.0, 0.0, 0.0 };
					Render.push_quad_screen(
						V2f.{ xx x, xx y },
						V2f.{ xx 3, xx 3 },
						color,
						-0.2
					);
				}
			}
		}
		Render.render_im();

		platform.end_frame();
	}
	exit_platform(platform);
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

	volume_on := false;
}