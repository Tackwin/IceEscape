#load "imgui_sdl_gl.jai";
#import "Scene";

show_inspector := false;    // Wish we could declare static variables inside functions.

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

	f :float = 0.0;

	// Main loop
	done := false;
	while !done {
		event: SDL_Event;
		while SDL_PollEvent(*event) {
			ImGui_ImplSdl_ProcessEvent(*event);
			if event.type == SDL_QUIT
				done = true;
			if event.type == SDL_WINDOWEVENT
			&& event.window.event == SDL_WINDOWEVENT_CLOSE
			&& event.window.windowID == SDL_GetWindowID(window)
				done = true;
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

		// Rendering
		ImGui.Render();

		glViewport(0, 0, xx io.DisplaySize.x, xx io.DisplaySize.y);
		glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
		glClear(GL_COLOR_BUFFER_BIT);



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

