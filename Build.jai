#import "Compiler";
#import "Basic";

build_game :: () -> Workspace {
	w := compiler_create_workspace("Game");

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

build :: () {
	w_game := build_game();
	compiler_begin_intercept(w_game);

	add_build_file("src/main_game.jai", w_game);

	while true {
		message := compiler_wait_for_message();

		if message.kind == {
			case .COMPLETE;
				break;
		}
	}

	compiler_end_intercept(w_game);

	set_build_options_dc(.{ do_output = false });
}

#run build();