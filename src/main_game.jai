#if OS == .WINDOWS {
	#import "imgui_sdl_gl";
}
#import "Math";
#import "Basic";
#import "Algebra";
#import "Platform";
#import "Communication";
Scene :: #import "Scene";
Render :: #import "Render";
Assets :: #import "Assets";

show_inspector := false;    // Wish we could declare static variables inside functions.

STARTER_TERRAIN_ASCII :: #string TERRAIN
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGSGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
GGGGGGGGGGGGGGGGIIIIIIIIIIIIIIIIIIIIIIIIIIIiiiiiIIIIIIIIIIIIIIGGG
TERRAIN

send_web_message :: (platform: Platform, command: Command) {
	payload := NewArray(size_of(Command), u8, false,, temp);
	memcpy(payload.data, cast(*void)*command, size_of(Command));
	platform.send_web_message(payload);
}

// 				Scene.process(scene, *scene.player, Scene.make_player_command(command));

parse_web_message :: (frame_info: Frame_Info) -> [] Command {
	commands := NewArray(frame_info.message_received_count, Command, false,, temp);

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
	platform := init_platform();
	rhi := platform.rhi;

	#if OS == .WINDOWS {
		imgui_context := ImGui.CreateContext();
		ImGui.StyleColorsClassic();
	}

	clear_color := V4f.{0.45, 0.55, 0.60, 1.00};

	scene: Scene.Scene;

	scene.camera.position = .{ 0, -9, 18 };
	scene.camera.target = .{ 0, 0, 0 };
	scene.camera.fov = 55;
	scene.texture_shader = Render.Shader.make(
		context.allocator, Assets.PLAIN_VERTEX, Assets.TEXTURE_FRAGMENT
	);
	scene.ice_texture = Render.Texture.make_from_image(Assets.ICE_TEXTURE);
	scene.grass_texture = Render.Texture.make_from_image(Assets.GRASS_TEXTURE);
	scene.tile_geometry = Render.Geometry.make_square(
		context.allocator, .{ 0, 0, 0 }, .{ 1, 0, 0 },  .{ 1, 1, 0 },  .{ 0, 1, 0 }
	);

	shader := Render.Shader.make(context.allocator, Assets.PLAIN_VERTEX, Assets.PLAIN_FRAGMENT);
	geometry := Render.Geometry.make_from_obj(context.allocator, Assets.CAR_OBJ);

	just_pressed: [Key_COUNT] bool;
	just_released: [Key_COUNT] bool;
	pressed: [Key_COUNT] bool;

	T := 0;

	terrain := Scene.load_terrain_from_ascii(STARTER_TERRAIN_ASCII);
	scene.current_terrain = *terrain;

	// Main loop
	done := false;
	while !done {

		frame_info := platform.get_frame_info();
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

		if pressed[Key.Q] {
			scene.camera.position.x -= 0.1;
			scene.camera.target.x -= 0.1;
		}
		if pressed[Key.D] {
			scene.camera.position.x += 0.1;
			scene.camera.target.x += 0.1;
		}
		if pressed[Key.S] {
			scene.camera.position.y -= 0.1;
			scene.camera.target.y -= 0.1;
		}
		if pressed[Key.Z] {
			scene.camera.position.y += 0.1;
			scene.camera.target.y += 0.1;
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
				send_web_message(platform, make_command(command));
			}
		}

		commands := parse_web_message(frame_info);
		for commands {
			Scene.process(*scene, it);
		}

		for * scene.players {
			Scene.update(scene, it, frame_info.delta_time);
		}

		rhi.glViewport(0, 0, xx frame_info.framebuffer_size.x, xx frame_info.framebuffer_size.y);
		rhi.glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
		rhi.glEnable(GL_BLEND);
		rhi.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		rhi.glEnable(GL_DEPTH_TEST);
		rhi.glEnable(GL_CULL_FACE);
		rhi.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		Render.set_uniform(shader, "V", V);
		Render.set_uniform(shader, "P", P);
		for * scene.players {
			M := M4f.identity();

			q := from_unit_vectors(V3f.{ 1, 0, 0 }, it.direction);
			M = to_rotation_matrix(q);

			M = M4f.translate(it.position) * M;

			Render.set_uniform(shader, "M", M);
			Render.render(geometry, shader);
		}


		Scene.render(scene, terrain);
		//Render.set_uniform(texture_shader, "V", V);
		//Render.set_uniform(texture_shader, "P", P);
		//Render.set_uniform(texture_shader, "texture_sampler", texture, 0);
//
		//for x: -20..20 {
		//	for y: -20..20 {
		//		M := M4f.translate(.{ cast(float32) x, cast(float32) y, 0 });
		//		Render.set_uniform(texture_shader, "M", M);
//
		//		Render.render(tile, texture_shader);
		//	}
		//}

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

