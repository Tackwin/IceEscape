#import "Basic";
#import "Platform";
Win32 :: #import "win32_platform";

#import "GL";

main :: () {

	query: Window_Query;
	query.kind = query.Kind.Create;
	query.width = 1280;
	query.height = 720;
	query.title = "Ice Escape";
	Win32.query(*query);
	query.kind = .Context;
	Win32.query(*query);

	gl_load(*gl);
	gl_enable_debug_output(false);

	while true {
		query = .{};
		query.kind = .Update;
		Win32.query(*query);
		if query.ask_quit
			break;

		gl.glClearColor(0.1, 0.2, 0.3, 1.0);
		gl.glClear(GL_COLOR_BUFFER_BIT);
	}
}