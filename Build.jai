#import "Compiler";
#import "Process";
#import "Basic";
#import "String";
#import "Bindings_Generator";
#import "File";
#import "File_Utilities";

build_game :: () -> Workspace {
	w := compiler_create_workspace("Game");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;
	opts.output_type = .DYNAMIC_LIBRARY;
	opts.output_path = "./bin/";
	opts.output_executable_name = "IceEscape";

	paths: [..] string;
	paths.allocator = temp;
	array_add(*paths, ..opts.import_path);
	array_add(*paths, "./src/");
	array_add(*paths, "./lib/");
	opts.import_path = paths;
	opts.dead_code_elimination = .ALL;

	#if #exists(JAILS_DIAGNOSTICS_BUILD) {
		options.output_type = .NO_OUTPUT;
	}

	set_build_options(opts, w);
	return w;
}
build_server :: () -> Workspace {
	w := compiler_create_workspace("Server");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;
	opts.output_type = .DYNAMIC_LIBRARY;
	opts.output_path = "./bin/";
	opts.output_executable_name = "IceEscapeServer";

	paths: [..] string;
	paths.allocator = temp;
	array_add(*paths, ..opts.import_path);
	array_add(*paths, "./src/");
	array_add(*paths, "./lib/");
	opts.import_path = paths;
	opts.dead_code_elimination = .ALL;

	#if #exists(JAILS_DIAGNOSTICS_BUILD) {
		options.output_type = .NO_OUTPUT;
	}

	set_build_options(opts, w);
	return w;
}

build_win32_client :: () -> Workspace {
	w := compiler_create_workspace("Win32_Client");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;
	opts.output_type = .EXECUTABLE;
	opts.output_path = "./bin/";
	opts.output_executable_name = "Win32";

	paths: [..] string;
	paths.allocator = temp;
	array_add(*paths, "./src/");
	array_add(*paths, "./lib/");
	array_add(*paths, ..opts.import_path);
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
	array_add(*paths, "./src/");
	array_add(*paths, "./lib/");
	array_add(*paths, ..opts.import_path);
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

build_platform_server :: (os: Operating_System_Tag) -> Workspace {
	w := compiler_create_workspace("Platform Server");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;
	opts.output_type = .EXECUTABLE;
	opts.output_path = "./bin/";
	if os == .WINDOWS
		opts.output_executable_name = "Win32Server";
	else if os == .LINUX
		opts.output_executable_name = "LinuxServer";
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

build_wasm :: () -> Workspace {

	w := compiler_create_workspace("Wasm");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;

	opts.output_type                         = .EXECUTABLE;
	opts.backend                             = .LLVM; // WASM only works with the LLVM backend, obviously.
	opts.os_target                           = .WASM;
	opts.cpu_target                          = .CUSTOM;
	opts.emit_debug_info                     = .DWARF;
	opts.backtrace_on_crash                  = .OFF; // Runtime_Support_Crash_Handler doesn’t support WASM (yet?)
	opts.output_path                         = "web/";
	opts.output_executable_name              = "IceEscape";
	opts.llvm_options.target_system_features = "+bulk-memory"; // "This options is needed so that "memcpy" and "memset" are mapped to "memory.copy" and "memory.fill" instructions in WASM.
	opts.llvm_options.enable_split_modules   = false;
	opts.llvm_options.function_sections      = true; // To get around "LLVM ERROR: section already has a defining function: .text"

	paths: [..] string;
	paths.allocator = temp;
	array_add(*paths, "./src/");
	array_add(*paths, ..opts.import_path);
	opts.import_path = paths;

	// This was compiled from src/c/walloc.c via "clang -Oz --target=wasm64 -nostdlib -c -o walloc.o walloc.c".
	walloc_object_file_path := "src/c/walloc.o";

	STACK_SIZE :: 1024 * 1024;
	opts.additional_linker_arguments = .["--stack-first", "-z", tprint("stack-size=%", STACK_SIZE), walloc_object_file_path];

	set_build_options(opts, w);

	// Replace the default allocator with Walloc (https://github.com/wingo/walloc).
	remap_import(w, "*", "Default_Allocator", "Walloc");

	return w;

	// process: Process;
	// ok := create_process(
	// 	*process,
	// 	"jai",
	// 	"src/entry/wasm.jai",
	// 	"-release",
	// 	"-import_dir", "..",
	// 	"-output_path", "../../web/",
	// 	"+Toolchains/Web/Progressive_Web_App"
	// );
	// while true {
	// 	ok, result := get_process_result(*process);
	// 	if !ok
	// 		break;
	// 	if #complete result.type == {
	// 		case .STILL_RUNNING;
	// 			continue;
	// 		case .EXITED;
	// 			break;
	// 		case .FAILED_TO_LAUNCH; #through;
	// 		case .UNSTARTED; #through;
	// 		case .SIGNALED;
	// 			break;
	// 	}
	// 	sleep_milliseconds(250);
	// }

	// runtime:, ok = read_entire_file("web/runtime.js");
	// if !ok {
	// 	return;
	// }
	// webgpu:, ok = read_entire_file("src/webgpu.js");
	// if !ok {
	// 	return;
	// }
	// io:, ok = read_entire_file("src/io.js");
	// if !ok {
	// 	return;
	// }
	// sound:, ok = read_entire_file("src/sound.js");
	// if !ok {
	// 	return;
	// }

	// write_entire_file(
	// 	"./web/runtime.js",
	// 	tprint(
	// 		"%\n\n\n//WEBGPU\n%\n\n\n//IO\n%\n\n\n//SOUND\n%\n", runtime, webgpu, io, sound
	// 	)
	// );
}

build :: () {
	args := get_build_options().compile_time_command_line;
	linux := false;
	server_ := false;
	wasm := false;
	bindings := false;
	launcher := false;
	publish := false;
	for args {
		linux |= compare(it, "linux") == 0;
		server_ |= compare(it, "server") == 0;
		wasm |= compare(it, "wasm") == 0;
		bindings |= compare(it, "bindings") == 0;
		launcher |= compare(it, "launcher") == 0;
		publish |= compare(it, "publish") == 0;
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

	game := build_game();
	server := build_server();
	wasm_client := build_wasm();
	win32_client := build_win32_client();
	win32_server := build_platform_server(.WINDOWS);
	linux_server: Workspace;
	if linux
		linux_server = build_platform_server(.LINUX);

	wss : [..] Workspace;
	array_add(*wss, game);
	array_add(*wss, server);
	if linux
		array_add(*wss, linux_server);
	if wasm
		array_add(*wss, wasm_client);
	if launcher {
		array_add(*wss, win32_client);
		array_add(*wss, win32_server);
	}

	mains: [..] string;
	array_add(*mains, "src/main_game.jai");
	array_add(*mains, "src/main_server.jai");

	if linux
		array_add(*mains, "src/entry/fix_server.jai");

	if wasm
		array_add(*mains, "src/entry/wasm.jai");

	if launcher {
		array_add(*mains, "src/entry/win32.jai");
		array_add(*mains, "src/entry/server.jai");
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

	if wasm {
		run_command(
			"./tools/wasm-opt.exe",
			"-O",
			"-g",
			"--asyncify",
			"./web/IceEscape.wasm",
			"-o",
			"./web/IceEscape.wasm"
		);
	}

	set_build_options_dc(.{ do_output = false });

	if publish {

	}

}

#run build();