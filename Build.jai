#import "Compiler";

build :: () {
	w := compiler_create_workspace("Game");

	opts := get_build_options(w);
}