#load "imgui_sdl_gl.jai";
#import "Algebra";
Scene :: #import "Scene";
Render :: #import "Render";
Assets :: #import "Assets";

show_inspector := false;    // Wish we could declare static variables inside functions.

main :: () {

	SDL_Init(SDL_INIT_VIDEO);

	window := SDL_CreateWindow(
		"Ice Escape",
		SDL_WINDOWPOS_CENTERED,
		SDL_WINDOWPOS_CENTERED,
		1366,
		768,
		SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE
	);

	if window == null {
		return;
	}

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

	gl_context := SDL_GL_CreateContext(window);
	if !gl_context {
		return;
	}

	gl_load(*gl, SDL_GL_GetProcAddress);

	imgui_context := ImGui.CreateContext();
	// Setup ImGui binding
	ImGui_ImplSdl_Init(window);

	// Setup style
	ImGui.StyleColorsClassic();

	io := ImGui.GetIO();

	clear_color := rgba(0.45, 0.55, 0.60, 1.00);

	camera: Scene.Camera;
	camera.position = .{ 0, -9, 18 };
	camera.target = .{ 0, 0, 0 };
	camera.fov = 55;

	player: Scene.Player;
	player.controlled = true;

	shader := Render.Shader.make(context.allocator, Assets.PLAIN_VERTEX, Assets.PLAIN_FRAGMENT);
	texture_shader := Render.Shader.make(
		context.allocator, Assets.PLAIN_VERTEX, Assets.TEXTURE_FRAGMENT
	);
	geometry := Render.Geometry.make_from_obj(context.allocator, Assets.CAR_OBJ);
	texture := Render.Texture.make_from_image(Assets.ICE_TEXTURE);
	tile := Render.Geometry.make_square(
		context.allocator, .{ 0, 0, 0 }, .{ 1, 0, 0 },  .{ 1, 1, 0 },  .{ 0, 1, 0 }
	);

	pressed: [#run enum_values_as_s64(Key).count] bool;
	just_pressed: [#run enum_values_as_s64(Key).count] bool;
	just_released: [#run enum_values_as_s64(Key).count] bool;
	mouse_position: V2f = .{ 0, 0 };
	window_size: V2f = .{ 0, 0 };

	// Main loop
	done := false;
	while !done {
		for * just_pressed
			it.* = false;
		for * just_released
			it.* = false;

		// >PLATFORM
		event: SDL_Event;
		while SDL_PollEvent(*event) {
			ImGui_ImplSdl_ProcessEvent(*event);
			if event.type == SDL_QUIT
				done = true;
			if event.type == SDL_WINDOWEVENT
			&& event.window.event == SDL_WINDOWEVENT_CLOSE
			&& event.window.windowID == SDL_GetWindowID(window)
				done = true;

			handle_key :: (mykey: Key, sdlkey: SDL_Keycode) #expand {
				if event.type == SDL_KEYDOWN {
					if event.key.keysym.sym == sdlkey {
						if !pressed[mykey]
							just_pressed[mykey] = true;
						pressed[mykey] = true;
					}
				}
				if event.type == SDL_KEYUP {
					if event.key.keysym.sym == sdlkey {
						just_released[mykey] = true;
						pressed[mykey] = false;
					}
				}
			}

			handle_mouse :: (mykey: Key, sdlmouse: int) #expand {
				if event.type == SDL_MOUSEBUTTONDOWN {
					if event.button.button == sdlmouse {
						if !pressed[mykey]
							just_pressed[mykey] = true;
						pressed[mykey] = true;
					}
				}
				if event.type == SDL_MOUSEBUTTONUP {
					if event.button.button == sdlmouse {
						just_released[mykey] = true;
						pressed[mykey] = false;
					}
				}
			}

			handle_key(Key.Z, SDLK_z);
			handle_key(Key.Q, SDLK_q);
			handle_key(Key.S, SDLK_s);
			handle_key(Key.D, SDLK_d);
			handle_mouse(Key.M_Left, SDL_BUTTON_LEFT);
			handle_mouse(Key.M_Right, SDL_BUTTON_RIGHT);
			handle_mouse(Key.M_Middle, SDL_BUTTON_MIDDLE);
		}
		{
			mx, my: s32;
			SDL_GetMouseState(*mx, *my);
			mouse_position.x = cast(float32) mx;
			mouse_position.y = cast(float32) my;

			w, h: s32;
			SDL_GetWindowSize(window, *w, *h);
			window_size = .{xx w, xx h};
		}

		V := Scene.look_at(camera.position, camera.target, .{ 0, 0, 1 });
		P := Scene.perspective(camera);

		ImGui_ImplSdl_NewFrame(window);
		ImGui.NewFrame();

		if pressed[Key.Q] {
			camera.position.x -= 0.1;
			camera.target.x -= 0.1;
		}
		if pressed[Key.D] {
			camera.position.x += 0.1;
			camera.target.x += 0.1;
		}
		if pressed[Key.S] {
			camera.position.y -= 0.1;
			camera.target.y -= 0.1;
		}
		if pressed[Key.Z] {
			camera.position.y += 0.1;
			camera.target.y += 0.1;
		}

		if just_pressed[Key.M_Left] {
			r := Scene.unproject_ndc(
				.{
					mouse_position.x / window_size.x * 2 - 1,
					1 - mouse_position.y / window_size.y * 2
				},
				V,
				P
			);

			target, ok := ray_plane(camera.position, r, .{ 0, 0, 1 });
			if ok {
				player.moving = true;
				player.direction = normalize(target - player.position);
			}
		}

		if player.moving {
			player.position += player.direction * player.speed;
		}


		// Rendering
		ImGui.Render();

		glViewport(0, 0, xx io.DisplaySize.x, xx io.DisplaySize.y);
		glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
		gl.glEnable(GL_BLEND);
		gl.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		gl.glEnable(GL_DEPTH_TEST);
		gl.glDepthFunc(GL_LESS);
		gl.glEnable(GL_CULL_FACE);
		gl.glCullFace(GL_BACK);
		gl.glFrontFace(GL_CCW);
		gl.glClearDepth(1.0);
		gl.glColorMaski(0, true, true, true, true);
		gl.glDrawBuffer(GL_BACK);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		{
			M := M4f.identity();

			q := from_unit_vectors(V3f.{ 1, 0, 0 }, player.direction);
			M = to_rotation_matrix(q);
			M = M4f.translate(player.position) * M;

			Render.set_uniform(shader, "M", M);
			Render.set_uniform(shader, "V", V);
			Render.set_uniform(shader, "P", P);

			Render.render(geometry, shader);
		}

		Render.set_uniform(texture_shader, "V", V);
		Render.set_uniform(texture_shader, "P", P);
		Render.set_uniform(texture_shader, "texture_sampler", texture, 0);

		for x: -20..20 {
			for y: -20..20 {
				M := M4f.translate(.{ cast(float32) x, cast(float32) y, 0 });
				Render.set_uniform(texture_shader, "M", M);

				Render.render(tile, texture_shader);
			}
		}

		ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
		SDL_GL_SwapWindow(window);
	}

	// Cleanup
	ImGui_ImplSdl_Shutdown();
	ImGui.DestroyContext(imgui_context);
	SDL_GL_DeleteContext(gl_context);
	SDL_DestroyWindow(window);
	SDL_Quit();
}

