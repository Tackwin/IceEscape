#import "Compiler";
#import "Process";
#import "Basic";
#import "String";

build_win32 :: () -> Workspace {
	w := compiler_create_workspace("Win32");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;
	opts.output_type = .EXECUTABLE;
	opts.output_path = "./bin/";
	opts.output_executable_name = "IceEscape";

	paths: [..] string;
	paths.allocator = temp;
	array_add(*paths, ..opts.import_path);
	array_add(*paths, "./src/");
	opts.import_path = paths;

	#if #exists(JAILS_DIAGNOSTICS_BUILD) {
		options.output_type = .NO_OUTPUT;
	}

	set_build_options(opts, w);
	return w;
}

build_wasm :: () {
	process: Process;
	ok := create_process(
		*process,
		"jai",
		"src/main_game.jai",
		"-release",
		"-import_dir", ".",
		"-output_path", "../web/",
		"+Toolchains/Web/Progressive_Web_App", "-inect_call_to_pwa_assets_update"
	);

	while true {
		ok, result := get_process_result(*process);
		if !ok
			break;
		if #complete result.type == {
			case .STILL_RUNNING;
				continue;
			case .EXITED;
				break;
			case .FAILED_TO_LAUNCH; #through;
			case .UNSTARTED; #through;
			case .SIGNALED;
				break;
		}
		sleep_milliseconds(250);
	}
}

build :: () {
	win32_game := build_win32();

	wss : [..] Workspace;
	array_add(*wss, win32_game);

	for wss
		compiler_begin_intercept(it);

	for wss
		add_build_file("src/main_game.jai", it);

	completed := 0;
	while true {
		message := compiler_wait_for_message();

		if message.kind == {
			case .COMPLETE;
				completed += 1;
		}

		if completed >= wss.count
			break;
	}

	for wss
		compiler_end_intercept(it);

	set_build_options_dc(.{ do_output = false });

	args := get_build_options().compile_time_command_line;
	found := false;
	for args {
		if compare(it, "wasm") == 0 {
			found = true;
			break;
		}
	}
	if found
		build_wasm();
}

#run build();