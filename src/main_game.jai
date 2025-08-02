#load "imgui_sdl_gl.jai";
Scene :: #import "Scene";
Render :: #import "Render";
CT_File :: #import "File";
#import "Algebra";

show_inspector := false;    // Wish we could declare static variables inside functions.

Key :: enum u32 {
	Z :: 0;
	Q;
	S;
	D;
	Up;
	Left;
	Down;
	Right;
}

// Just a plain vertex shader for opengl es 3.3
PLAIN_VERTEX :: #string VERTEX
#version 330 core
#extension GL_ARB_separate_shader_objects : enable
layout(location = 0) in vec3 vmodel_pos;
layout(location = 1) in vec3 vmodel_nor;

layout(location = 0) out vec3 fworld_pos;
layout(location = 1) out vec3 fworld_nor;

uniform mat4 M;
uniform mat4 V;
uniform mat4 P;

void main() {
	gl_Position = P * V * M * vec4(vmodel_pos, 1.0);
	fworld_pos = (M * vec4(vmodel_pos, 1.0)).xyz;
	fworld_nor = normalize((M * vec4(vmodel_nor, 0.0)).xyz);
}
VERTEX;

PLAIN_FRAGMENT :: #string FRAGMENT
#version 330 core
#extension GL_ARB_separate_shader_objects : enable

layout(location = 0) in vec3 fworld_pos;
layout(location = 1) in vec3 fworld_nor;

out vec4 outColor;

void main() {
	float d = dot(fworld_nor, vec3(0.0, 0.0, 1.0)) * 0.5 + 0.5;

	outColor = vec4(d, d, d, 1.0); // Color base
}
FRAGMENT;

CAR_OBJ :: #run CT_File.read_entire_file("assets/car.obj");

main :: () {

	SDL_Init(SDL_INIT_VIDEO);

	window := SDL_CreateWindow(
		"Ice Escape",
		SDL_WINDOWPOS_CENTERED,
		SDL_WINDOWPOS_CENTERED,
		1360,
		728,
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
	camera.position = .{ 0, -10, 10 };
	camera.target = .{ 0, 0, 0 };

	shader := Render.Shader.make(context.allocator, PLAIN_VERTEX, PLAIN_FRAGMENT);
	geometry := Render.Geometry.make_from_obj(context.allocator, CAR_OBJ);

	pressed: [#run enum_values_as_s64(Key).count] bool;
	just_pressed: [#run enum_values_as_s64(Key).count] bool;
	just_released: [#run enum_values_as_s64(Key).count] bool;

	// Main loop
	done := false;
	while !done {
		for * just_pressed
			it.* = false;
		for * just_released
			it.* = false;

		event: SDL_Event;
		while SDL_PollEvent(*event) {
			ImGui_ImplSdl_ProcessEvent(*event);
			if event.type == SDL_QUIT
				done = true;
			if event.type == SDL_WINDOWEVENT
			&& event.window.event == SDL_WINDOWEVENT_CLOSE
			&& event.window.windowID == SDL_GetWindowID(window)
				done = true;

			handle_key :: (event: SDL_Event, mykey: Key, sdlkey: SDL_Keycode) #expand {
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

			handle_key(event, Key.Z, SDLK_z);
			handle_key(event, Key.Q, SDLK_q);
			handle_key(event, Key.S, SDLK_s);
			handle_key(event, Key.D, SDLK_d);
		}
		ImGui_ImplSdl_NewFrame(window);
		ImGui.NewFrame();

		using ImGui.MouseCursor;
		if ImGui.GetMouseCursor() == {
			case Arrow;         SDL_SetCursor(cursor_arrow);
			case TextInput;     SDL_SetCursor(cursor_text_input);
			case Hand;          SDL_SetCursor(cursor_move);
			case ResizeNS;      SDL_SetCursor(cursor_resize_ns);
			case ResizeEW;      SDL_SetCursor(cursor_resize_ew);
			case ResizeNESW;    SDL_SetCursor(cursor_resize_nesw);
			case ResizeNWSE;    SDL_SetCursor(cursor_resize_nwse);
		}

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

		M := M4f.identity();
		V := Scene.look_at(camera.position, camera.target, .{ 0, 0, 1 });
		P := Scene.perspective(camera);

		Render.set_uniform(shader, "M", M);
		Render.set_uniform(shader, "V", V);
		Render.set_uniform(shader, "P", P);

		Render.render(geometry, shader);

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

