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
	array_add(*paths, "./modules/");
	array_add(*paths, ..opts.import_path);
	opts.additional_linker_arguments = NewArray(9, string);
	opts.additional_linker_arguments[0] = "Userenv.lib";
	opts.additional_linker_arguments[1] = "Ntdll.lib";
	opts.additional_linker_arguments[2] = "Propsys.lib";
	opts.additional_linker_arguments[3] = "OpenGL32.lib";
	opts.additional_linker_arguments[4] = "Ole32.lib";
	opts.additional_linker_arguments[5] = "Gdi32.lib";
	opts.additional_linker_arguments[6] = "OleAut32.lib";
	opts.additional_linker_arguments[7] = "d3dcompiler.lib";
	opts.additional_linker_arguments[8] = "RuntimeObject.lib";
	opts.additional_linker_arguments.count = 9;
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
	opts.additional_linker_arguments[3] = "Opengl32.lib";
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
	opts.additional_linker_arguments = NewArray(1, string);
	if os == .WINDOWS {
		opts.output_executable_name = "Win32Server";
		opts.additional_linker_arguments[0] = "src/c/wsserver.lib";
	}
	else if os == .LINUX {
		opts.output_executable_name = "LinuxServer";
		opts.additional_linker_arguments[0] = "src/c/wsserver.o";
	}
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
	if linux {
		array_add(*wss, linux_server);

		run_command(
			"clang",
			"-O3",
			"-g",
			"-fdeclspec",
			"-fPIC",
			"-c",
			"./src/c/wsserver.c",
			"-o",
			"./bin/wsserver.dll"
		);

	}
	if wasm
		array_add(*wss, wasm_client);
	if launcher {
		array_add(*wss, win32_client);
		array_add(*wss, win32_server);

		run_command(
			"clang",
			"-O3",
			"-g",
			"-shared",
			"./src/c/wsserver.c",
			"-o",
			"./bin/wsserver.dll"
		);
	}

	mains: [..] string;
	array_add(*mains, "src/main_game.jai");
	array_add(*mains, "src/main_server.jai");

	if linux
		array_add(*mains, "src/entry/mg_server.jai");

	if wasm
		array_add(*mains, "src/entry/wasm.jai");

	if launcher {
		array_add(*mains, "src/entry/win32.jai");
		array_add(*mains, "src/entry/mg_server.jai");
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

build_game_dll_2 :: () {
	w := compiler_create_workspace("Game DLL");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;
	opts.intermediate_path = ".build_game_dll";
	opts.text_output_flags = xx 0;
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
	compiler_begin_intercept(w);
	add_build_file("src/main_game.jai", w);
	while true {
		message := compiler_wait_for_message();

		if message.kind == {
			case .COMPLETE;
				break;
		}
	}
	compiler_end_intercept(w);
}
build_server_dll_2 :: () {
	w := compiler_create_workspace("Server DLL");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;
	opts.text_output_flags = xx 0;
	opts.intermediate_path = ".build_server_dll";
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
	compiler_begin_intercept(w);
	add_build_file("src/main_server.jai", w);
	while true {
		message := compiler_wait_for_message();

		if message.kind == {
			case .COMPLETE;
				break;
		}
	}
	compiler_end_intercept(w);
}

build_game_win32_2 :: () {
	w := compiler_create_workspace("Game Win32");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;
	opts.text_output_flags = xx 0;
	opts.intermediate_path = ".build_game_win32";
	opts.output_type = .EXECUTABLE;
	opts.output_path = "./bin/";
	opts.output_executable_name = "Win32";

	paths: [..] string;
	paths.allocator = temp;
	array_add(*paths, "./src/");
	array_add(*paths, "./lib/");
	array_add(*paths, "./modules/");
	array_add(*paths, ..opts.import_path);
	opts.additional_linker_arguments = NewArray(9, string);
	opts.additional_linker_arguments[0] = "Userenv.lib";
	opts.additional_linker_arguments[1] = "Ntdll.lib";
	opts.additional_linker_arguments[2] = "Propsys.lib";
	opts.additional_linker_arguments[3] = "OpenGL32.lib";
	opts.additional_linker_arguments[4] = "Ole32.lib";
	opts.additional_linker_arguments[5] = "Gdi32.lib";
	opts.additional_linker_arguments[6] = "OleAut32.lib";
	opts.additional_linker_arguments[7] = "d3dcompiler.lib";
	opts.additional_linker_arguments[8] = "RuntimeObject.lib";
	opts.additional_linker_arguments.count = 9;
	opts.import_path = paths;

	#if #exists(JAILS_DIAGNOSTICS_BUILD) {
		options.output_type = .NO_OUTPUT;
	}

	set_build_options(opts, w);
	compiler_begin_intercept(w);
	add_build_file("src/entry/win32.jai", w);
	while true {
		message := compiler_wait_for_message();

		if message.kind == {
			case .COMPLETE;
				break;
		}
	}
	compiler_end_intercept(w);
}

build_server_platform_2 :: (os: Operating_System_Tag) {
	w := compiler_create_workspace("Platform Server");

	seed := get_build_options();
	opts := get_build_options(w);

	opts.Commonly_Propagated = seed.Commonly_Propagated;
	opts.text_output_flags = xx 0;
	opts.output_path = "./bin/";
	opts.additional_linker_arguments = NewArray(1, string);
	if os == .WINDOWS {
		opts.output_type = .EXECUTABLE;
		opts.intermediate_path = ".build_server_win";
		opts.output_executable_name = "Win32Server";
		opts.additional_linker_arguments[0] = "src/c/wsserver.lib";
	}
	else if os == .LINUX {
		opts.output_type = .EXECUTABLE;
		opts.intermediate_path = ".build_server_linux";
		opts.output_executable_name = "LinuxServer";
		opts.additional_linker_arguments[0] = "src/c/wsserver.o";
		opts.use_custom_link_command = true;
	}
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
	compiler_begin_intercept(w);
	add_build_file("src/entry/mg_server.jai", w);
	while true {
		message := compiler_wait_for_message();

		if message.kind == {
			case .COMPLETE;
				break;

			case .PHASE;
				msg : *Message_Phase;
				msg = message.(*Message_Phase);
				if msg.phase == .READY_FOR_CUSTOM_LINK_COMMAND {
					args: [..] string;

					array_add(*args, "zig");
					array_add(*args, "cc");
					array_add(*args, "-target");
					array_add(*args, "x86_64-linux-gnu");
					array_add(*args, "src/c/wsserver.linux");
					for msg.compiler_generated_object_files
						array_add(*args, it);
					for msg.support_object_files
						array_add(*args, it);
					for msg.user_libraries
						array_add(*args, it);
					array_add(*args, "-o");
					array_add(*args, tprint("bin/%.exe", msg.executable_name));

					// print("Running linker %\n", join(..args, " "));
					run_command(..args);
					compiler_custom_link_command_is_complete(w);
				}
		}
	}
	compiler_end_intercept(w);
}

build_wasm_2 :: () {
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
	opts.additional_linker_arguments = .[
		"--stack-first", "-z", tprint("stack-size=%", STACK_SIZE), walloc_object_file_path
	];

	// Replace the default allocator with Walloc (https://github.com/wingo/walloc).
	remap_import(w, "*", "Default_Allocator", "Walloc");

	set_build_options(opts, w);
	compiler_begin_intercept(w);
	add_build_file("src/entry/wasm.jai", w);
	while true {
		message := compiler_wait_for_message();

		if message.kind == {
			case .COMPLETE;
				break;
		}
	}
	compiler_end_intercept(w);

	args := string.[
		"./tools/wasm-opt.exe",
		"-O2",
		"-g",
		"--asyncify",
		"./web/IceEscape.wasm",
		"-o",
		"./web/IceEscape.wasm"
	];
	print("Running wasm opt: %\n", join(..args, " "));
	run_command(..args);
}
build_c_lib :: () {
	run_command(
		"wsl",
		"clang",
		"-O3",
		"-g",
		"-fdeclspec",
		"-fPIC",
		"-c",
		"./src/c/wsserver.c",
		"-o",
		"./src/c/wsserver.linux"
	);
	run_command(
		"clang",
		"-O3",
		"-g",
		"-shared",
		"./src/c/wsserver.c",
		"-o",
		"./src/c/wsserver.dll"
	);
	run_command(
		"clang",
		"-Oz",
		"--target=wasm64",
		"-nostdlib",
		"-c",
		"-o",
		"./src/c/walloc.o",
		"./src/c/walloc.c"
	);
}

build_2 :: () {
	set_build_options_dc(.{ do_output = false });

	args := get_build_options().compile_time_command_line;

	clib := false;
	game := false;
	server := false;
	wasm := false;
	win32 := false;
	linux := false;
	publish := false;
	for args {
		clib |= compare(it, "clib") == 0;
		game |= compare(it, "game") == 0;
		server |= compare(it, "server") == 0;
		win32 |= compare(it, "win32") == 0;
		wasm |= compare(it, "wasm") == 0;
		linux |= compare(it, "linux") == 0;
		publish |= compare(it, "publish") == 0;
	}
	game |= !clib && !server && !wasm && !win32 && !linux && !publish;

	if clib
		build_c_lib();
	if game
		build_game_dll_2();
	if server
		build_server_dll_2();
	if win32 {
		build_game_win32_2();
		build_server_platform_2(.WINDOWS);
	}
	if linux
		build_server_platform_2(.LINUX);
	if wasm
		build_wasm_2();
	if publish {
		print("Stopping service\n");
		res, stdout, stderr := run_command(
			"sexec",
			"-profile=tools/ssh.tlp",
			"-cmd=sudo systemctl stop linuxserver.service"
		);
		run_command(
			"sftpc",
			"-profile=tools/ssh.tlp",
			"put",
			"-o",
			"./bin/LinuxServer.exe",
			"bin/LinuxServer"
		);
		run_command(
			"sftpc",
			"-profile=tools/ssh.tlp",
			"put",
			"-o",
			"./web/*",
			"www/tackwin"
		);
		run_command(
			"sftpc",
			"-profile=tools/ssh.tlp",
			"put",
			"-o",
			"./assets/terrain/*.terrain",
			"assets/terrain"
		);
		print("Starting service.\n");
		run_command(
			"sexec",
			"-profile=tools/ssh.tlp",
			"-cmd=sudo systemctl start linuxserver.service"
		);
	}
}

#run build_2();