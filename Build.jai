#import "Compiler";
#import "Process";
#import "Basic";
#import "String";
#import "Bindings_Generator";

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
	array_add(*paths, "./lib/");
	opts.additional_linker_arguments = NewArray(8, string);
	opts.additional_linker_arguments[0] = "Userenv.lib";
	opts.additional_linker_arguments[1] = "Ntdll.lib";
	opts.additional_linker_arguments[2] = "Propsys.lib";
	opts.additional_linker_arguments[3] = "Ole32.lib";
	opts.additional_linker_arguments[4] = "Gdi32.lib";
	opts.additional_linker_arguments[5] = "OleAut32.lib";
	opts.additional_linker_arguments[6] = "d3dcompiler.lib";
	opts.additional_linker_arguments[7] = "RuntimeObject.lib";
	opts.additional_linker_arguments.count = 8;
	opts.import_path = paths;

	#if #exists(JAILS_DIAGNOSTICS_BUILD) {
		options.output_type = .NO_OUTPUT;
	}

	set_build_options(opts, w);
	return w;
}

build_server :: (os: Operating_System_Tag) -> Workspace {
	w := compiler_create_workspace("Server");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;
	opts.output_type = .EXECUTABLE;
	opts.output_path = "./bin/server/";
	opts.output_executable_name = "IceEscape_Server";
	opts.os_target = os;

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
		"+Toolchains/Web/Progressive_Web_App"
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
	args := get_build_options().compile_time_command_line;
	linux := false;
	server := false;
	wasm := false;
	bindings := false;
	for args {
		linux |= compare(it, "linux") == 0;
		server |= compare(it, "server") == 0;
		wasm |= compare(it, "wasm") == 0;
		bindings |= compare(it, "bindings") == 0;
	}

	if bindings {
		opts: Generate_Bindings_Options;
		opts.log_stripped_declarations = false;
		array_add(*opts.source_files, "./src/c/webgpu/webgpu.h");
		array_add(*opts.source_files, "./src/c/webgpu/wgpu.h");
		generate_bindings(opts, "./src/webgpu_type.jai");
		opts.log_stripped_declarations = true;
		array_add(*opts.libnames, "wgpu_native.dll");
		array_add(*opts.libpaths, "./lib");
		generate_bindings(opts, "./src/webgpu_win32.jai");
	}

	win32_game := build_win32();
	win32_server := build_server(.WINDOWS);
	linux_server := build_server(.LINUX);

	wss : [..] Workspace;
	if linux {
		array_add(*wss, linux_server);
	} else {
		if server
			array_add(*wss, win32_server);
		array_add(*wss, win32_game);
	}

	mains: [..] string;
	if linux {
		array_add(*mains, "src/main_server.jai");
	} else {
		if server
			array_add(*mains, "src/main_server.jai");
		array_add(*mains, "src/main_game.jai");
	}


	for wss
	{
		compiler_begin_intercept(it);
		add_build_file(mains[it_index], it);
		while true {
			message := compiler_wait_for_message();

			if message.kind == {
				case .COMPLETE;
					break;
			}
		}
		compiler_end_intercept(it);
	}

	set_build_options_dc(.{ do_output = false });

	if wasm
		build_wasm();
}

#run build();