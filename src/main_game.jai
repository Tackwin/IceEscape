Terrain :: #import "Terrain";
#import "Math";
#import "Basic";
#import "Store";
#import "Random";
#import "String";
#import "Algebra";
#import "Platform";
#import "Communication";
#import "Utils";
#import "Hash_Table";
#import "Remap_Context"(false);
RNG :: #import "Rand";
Controls :: #import "Controls";
WRender :: #import "WRender";
Scene :: #import "Scene";
Assets :: #import "Assets";
GUI :: #import "GUI";

process_complete_ntp :: (state: *State, ntp: Command.NTP) {
	result: State.NTP_Result;
	result.offset = (ntp.t1 + ntp.t2) / 2 - (ntp.t0 + ntp.t3) / 2;
	result.ping = (ntp.t3 - ntp.t0) - (ntp.t2 - ntp.t1);
	result.time = to_float64_seconds(state.current_time);
	state.ntp_history[state.ntp_history_cursor] = result;
	state.ntp_history_cursor += 1;
	state.ntp_history_cursor %= state.ntp_history.count;
}

send_web_message :: (platform: Platform, time: Apollo_Time, _command: Command) {
	command := _command;
	command.sent_timestamp = to_float64_seconds(time);
	buffer: [..] u8;
	buffer.allocator = temp;
	serialize(command, *buffer);
	platform.send_web_message(buffer, 0);
}

parse_web_message :: (state: *State, frame_info: Frame_Info) -> [] Command {
	commands := NewArray(frame_info.message_received_count, Command, false,, temp);

	cursor := 0;
	for 0..frame_info.message_received_count - 1 {
		cmd, ok := deserialize(frame_info.message_received[it].data);
		if ok {
			array_add(*state.received_command_history, cmd.payload.kind);
			commands[cursor] = cmd;
			cursor += 1;
		} else {
			print("Failed to deserialize message\n");
		}
	}

	commands.count = cursor;
	return commands;
}

#scope_export
App_User :: struct {
	app: *App;
	store: Store;
	state: State;
	allocated_frame_info: Frame_Info;
	framegraph: WRender.WFramegraph;
	process_response: Scene.Process_Response;
	controls: Controls.State;
	graphics: WRender.Graphics;
	app_context: *#Context;
	gui_state: GUI.GUI_State;
}

#program_export "app_init" app_init :: (app: *App) {
	Remap_Context();

	app_user := New(App_User);
	app_user.app = app;
	app.user_data = app_user.(*void);
	app_user.state.platform = app.platform;
	app_user.graphics.gpu = app.platform.gpu;
	
	WRender.init_graphics(app.platform, *app_user.graphics);
	WRender.graphics = *app_user.graphics;
	init_store(app.platform, *app_user.store);
	GUI.gui_state_init(*app_user.gui_state, *app_user.store);
	WRender.init_framegraph(*app_user.framegraph, *app_user.store);

	Scene.make(*app_user.state.scene);
	Scene.init_camera(*app_user.state.scene);

	launch_music(app_user, app.platform);
}

#program_export "app_reload" app_reload :: (_app: *App) {
	app_user := _app.user_data.(*App_User);

	scene: Scene.Scene;
	Scene.reload(*scene);
}

#program_export "app_loop" app_loop :: (_app: *App) -> bool {
	app_user := _app.user_data.(*App_User);
	Remap_Context();
	reset_temporary_storage();

	app_user.state.is_communication_established = _app.platform.is_server_connected();
	app_user.state.is_connected &= app_user.state.is_communication_established;

	_app.platform.get_frame_info(*app_user.allocated_frame_info);
	app_user.state.current_time = app_user.allocated_frame_info.time;

	if app_user.allocated_frame_info.quit
		return false;

	GUI.begin_frame(*app_user.gui_state, app_user.allocated_frame_info, *app_user.controls);

	commands := parse_web_message(*app_user.state, app_user.allocated_frame_info);
	for command: commands {

		while true {
			before_screen_state := app_user.state.screen_state;

			if app_user.state.screen_state == {
				case .Menu;
					if process_menu(*app_user.state, command)
						continue command;
				case .Game;
					if process_game(
						*app_user.state, command, app_user.controls, *app_user.process_response
					)
						continue command;
			}

			if app_user.state.screen_state == before_screen_state
				break;
		}
	}

	quit := false;
	if app_user.state.screen_state == {
		case .Menu;
			quit = menu_loop(_app);
		case .Game;
			quit = game_loop(app_user);
		case .Editor;
			quit = editor_loop(app_user);
	}


	_app.platform.gpu.surfacePresent(app_user.graphics.surface);
	_app.platform.end_frame();

	return quit;
}
#load "menu_loop.jai";
#load "game_loop.jai";
#load "editor_loop.jai";

#program_export "app_quit" app_quit :: (_app: *App) {
}

launch_music :: (app_user: *App_User, platform: *Platform) {
	app_user.store.snowflakes_and_lights_mp3.kind = .Music;
	app_user.store.snowflakes_and_lights_mp3.repeating = true;
	app_user.store.snowflakes_and_lights_mp3.volume = 0.05;
	platform.play_audio(app_user.store.snowflakes_and_lights_mp3, .{});
}

State :: struct {
	current_time: Apollo_Time;

	coommands_received: [..] Command;

	menu: Menu;
	game: Game_Page;
	editor: Editor_Page;

	Playing :: struct {
		escape_menu_open: bool = false;
	}
	playing: Playing;

	platform: *Platform;
	scene: Scene.Scene;

	is_connected := false;
	is_communication_established := false;

	ntp_period: Period(0.15);
	NTP_Result :: struct {
		offset: float64 = 0;
		ping: float64 = 0;
		time: float64 = 0;
	}

	ntp_history: [64] NTP_Result;
	ntp_history_cursor := 0;

	received_command_history: [..] Command.payload.Kind;
	
	history_dt: [100] float;
	history_cursor := 0;
	render_fps := false;
	render_command_debug := false;
	filter_command_debug: [#run enum_highest_value(Command.payload.Kind) + 1] bool;

	volume_on := true;

	skull_id_to_sound: Table(int, Sound);
	shurikens_id_to_sound: Table(int, Sound);

	news: [..] Scene.Breaking_News;

	screen_state: enum {
		Menu :: 0;
		Game :: 1;
		Editor :: 2;
	} = .Menu;

	to_send: [..] Command;
}