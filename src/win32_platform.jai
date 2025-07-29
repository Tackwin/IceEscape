#import "Platform";
#import "Window_Creation";
#import "Input";
#import "Basic";
#import "GL";

windows: [..] Window_Type;

#scope_export

query :: (req: *Window_Query) {

	if req.kind == {
		case Window_Query.Kind.Create;
			window := create_window(req.width, req.height, req.title);

			req.id = windows.count;
			array_add(*windows, window);
		case Window_Query.Kind.Update;
			update_window_events();
			for events_this_frame {
				if it.type == .QUIT
					req.ask_quit = true;
			}
		case Window_Query.Kind.Context;
			wgl_create_context(windows[req.id], null, 3, 3, true, true, 4);
	}
}