#if OS == .WINDOWS {
	#import "imgui_sdl_gl";
}
Terrain :: #import "Terrain";
#import "Math";
#import "Basic";
#import "Algebra";
#import "Platform";
#import "Default_Allocator";
#import "Communication";
#import "WAllocator";
#import "Utils";
Scene :: #import "Scene";
Render :: #import "Render";
Assets :: #import "Assets";

show_inspector := false;    // Wish we could declare static variables inside functions.

State :: struct {
	scene: Scene.Scene;

	ntp_period: Period(0.5);
}

send_web_message :: (platform: Platform, _command: Command) {
	command := _command;
	command.sent_timestamp = to_float64_seconds(current_time_monotonic());
	payload := NewArray(size_of(Command) + 8, u8, false);
	defer {
		array_free(payload);
	}
	(cast(*u64)payload.data).* = size_of(Command);
	memcpy(payload.data + 8, cast(*void)*command, size_of(Command));
	platform.send_web_message(payload);
}

// 				Scene.process(scene, *scene.player, Scene.make_player_command(command));

parse_web_message :: (frame_info: Frame_Info) -> [] Command {
	commands := NewArray(frame_info.message_received_count, Command, false);

	cursor := 0;
	for 0..frame_info.message_received_count - 1 {
		if frame_info.message_received[it].count != size_of(Command)
			continue;

		command: Command;
		memcpy(
			cast(*void)*command,
			frame_info.message_received[it].data,
			size_of(Command)
		);

		commands[cursor] = command;
		cursor += 1;
	}

	commands.count = cursor;
	return commands;
}

main :: () {
	context.allocator = .{ wallocator_proc, null };
	context.temporary_storage.overflow_allocator = context.allocator;
	platform := init_platform();
	rhi := platform.rhi;

	#if OS == .WINDOWS {
		imgui_context := ImGui.CreateContext();
		ImGui.StyleColorsClassic();
	}

	clear_color := V4f.{0.45, 0.55, 0.60, 1.00};

	state: State;
	scene := *state.scene;

	scene.camera.position = .{ 0, -4, 8 };
	scene.camera.target = .{ 0, 0, 0 };
	scene.camera.target_target = scene.camera.target;
	scene.camera.wanted_target_to_position = scene.camera.position - scene.camera.target;
	scene.camera.fov = 55;
	scene.model_shader = Render.Shader.make(
		Assets.PLAIN_VERTEX, Assets.PLAIN_FRAGMENT
	);
	scene.texture_shader = Render.Shader.make(
		Assets.PLAIN_VERTEX, Assets.TEXTURE_FRAGMENT
	);
	scene.font_shader = Render.Shader.make(
		Assets.FONT_VERTEX, Assets.FONT_FRAGMENT
	);
	scene.instance_shader = Render.Shader.make(
		Assets.INSTANCED_VERTEX, Assets.TEXTURE_FRAGMENT
	);
	scene.tile_shader = Render.Shader.make(
		Assets.TILE_VERTEX, Assets.TILE_FRAGMENT
	);
	scene.ice_texture = Render.Texture.make_from_image(Assets.ICE_TEXTURE);
	scene.coin_texture = Render.Texture.make_from_image(Assets.COIN_TEXTURE);
	scene.dirt_texture = Render.Texture.make_from_image(Assets.DIRT_TEXTURE);
	scene.grass_texture = Render.Texture.make_from_image(Assets.GRASS_TEXTURE);
	scene.slippy_ice_texture = Render.Texture.make_from_image(Assets.SLIPPY_ICE_TEXTURE);
	scene.tile_geometry = Render.Geometry.make_square(
		.{ 0, 0, 0 }, .{ 1, 0, 0 },  .{ 1, 1, 0 },  .{ 0, 1, 0 }
	);
	scene.mark_texture = Render.Texture.make_from_image(Assets.MARK_TEXTURE);
	Render.set_parameter(scene.mark_texture, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	scene.player_geometry = Render.Geometry.make_from_obj(Assets.CAR_OBJ);
	scene.tombstone_geometry = Render.Geometry.make_from_obj(Assets.TOMBSTONE_OBJ);
	scene.coin_geometry = Render.Geometry.make_from_obj(Assets.COIN_OBJ);
	scene.skull_geometry = Render.Geometry.make_from_obj(Assets.SKULL_OBJ);
	scene.key_geometry = Render.Geometry.make_from_obj(Assets.KEY_OBJ);
	scene.mark_geometry = Render.Geometry.make_from_obj(Assets.MARK_OBJ);
	scene.gate_geometry = Render.Geometry.make_from_obj(Assets.GATE_OBJ);
	scene.gate_close_geometry = Render.Geometry.make_from_obj(Assets.GATE_CLOSE_OBJ);
	scene.shuriken_geometry = Render.Geometry.make_from_obj(Assets.SHURIKEN_OBJ);

	scene.tile_kind_to_shader[xx Scene.Tile.Kind.None] = null;
	scene.tile_kind_to_shader[xx Scene.Tile.Kind.Ice] = *scene.ice_texture;
	scene.tile_kind_to_shader[xx Scene.Tile.Kind.Grass] = *scene.grass_texture;
	scene.tile_kind_to_shader[xx Scene.Tile.Kind.Slippy_Ice] = *scene.slippy_ice_texture;
	scene.tile_kind_to_shader[xx Scene.Tile.Kind.Dirt] = *scene.dirt_texture;

	just_pressed: [Key_COUNT] bool;
	just_released: [Key_COUNT] bool;
	pressed: [Key_COUNT] bool;

	T := 0;

	// terrain := Scene.load_terrain_from_ascii(STARTER_TERRAIN_ASCII);
	// scene.current_terrain = *terrain;
	Terrain.init_roundabout(scene);


	history_dt: [100] float;
	history_cursor := 0;
	render_fps := false;

	yes: [..] V2f;
	last_yes: Apollo_Time;

	// Main loop
	done := false;
	while !done {
		auto_release_temp();

		t00 := current_time_monotonic();
		frame_info := platform.get_frame_info();
		history_dt[history_cursor % history_dt.count] = frame_info.delta_time;
		history_cursor += 1;
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

		V := Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
		P := Scene.perspective(scene.camera);

		#if OS == .WINDOWS {
			ImGui_Impl_NewFrame(frame_info, platform);
			ImGui.NewFrame();
		}

		any_camera_move := false;
		dt := V3f.{ 0, 0, 0 };
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

		if scene.succeed && to_float64_seconds(current_time_monotonic() - last_yes) > 0.175 {
			p := V2f.{ 0, 0 };
			if yes.count > 0 {
				p = yes[yes.count - 1];
			}

			p.x += 123456;
			p.y += 456789;
			p.x = fmod_cycling(p.x, frame_info.framebuffer_size.x);
			p.y = fmod_cycling(p.y, frame_info.framebuffer_size.y);

			array_add(*yes, p);
			last_yes = current_time_monotonic();
		}

		T += 1;

		if just_pressed[Key.MouseLeft] {
			r := Scene.unproject_ndc(
				.{
					frame_info.mouse_position.x / frame_info.window_size.x * 2 - 1,
					1 - frame_info.mouse_position.y / frame_info.window_size.y * 2
				},
				V,
				P
			);

			target, ok := ray_plane(scene.camera.position, r, .{ 0, 0, 1 });
			if ok {
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

		commands := parse_web_message(frame_info);
		defer {
			array_free(commands);
		}
		for commands {
			Scene.process(scene, it, null);
		}
		Scene.update(scene, frame_info.delta_time, null);

		rhi.glViewport(0, 0, xx frame_info.framebuffer_size.x, xx frame_info.framebuffer_size.y);
		rhi.glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
		rhi.glEnable(GL_BLEND);
		rhi.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		rhi.glEnable(GL_DEPTH_TEST);
		rhi.glEnable(GL_CULL_FACE);
		rhi.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		Scene.render(scene, scene.current_terrain);

		for yes {
			Render.push_text("GG, you won !", it, 24);
		}

		if render_fps {
			fps_text := tprint("FPS: %", 1.0 / frame_info.delta_time);
			Render.push_text(fps_text, .{ 10, frame_info.framebuffer_size.y - 100 }, 32);

			for 0..10 {
				Render.push_text(
					"Portez ce vieux whisky au juge blond qui fume", .{ 500, 200 + it * 50.0 }, 16.0 + it * 4
				);
			}

			Render.push_quad(.{
				pos = .{ -0.95, -0.95 },
				size = .{ 0.75, 0.4 },
				color = .{ 0.0, 0.0, 0.0 },
				z = 0.0
			});
			n := history_dt.count;
			for history_dt {
				fps := 1.0 / it;

				h := min(fps, 300);
				h /= 300;

				Render.push_quad(.{
					pos = .{ -0.95 + it_index * 0.75 / n, -0.94 },
					size = .{ 0.73 / n, 0.38 * h },
					color = .{ 1.0, 1.0, 1.0 },
					z = -0.1
				});
			}
			Render.push_quad(.{
				pos = .{ -0.95, -0.94 + 0.38 * (60.0 / 300) },
				size = .{ 0.75, 0.002 },
				color = .{ 0.0, 1.0, 0.0 },
				z = -0.2
			});

			#if OS == .WASM {
				header := get_header();
				bit_array := cast(*u8)(header + 1);
				for 0..header.total_number_of_pages_allocated-1 {
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

		#if OS == .WINDOWS {
			ImGui.Render();
			ImGui_ImplSdl_RenderDrawLists(platform.rhi, ImGui.GetDrawData());
		}
		platform.end_frame();
	}
	#if OS == .WINDOWS {
		ImGui_Impl_Shutdown(platform);
		ImGui.DestroyContext(imgui_context);
	}
	exit_platform(platform);
}

