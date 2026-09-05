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
#import "Common";
#import "Hash_Table";
#import "Profile";
#import "Big_Asset";
#import "Remap_Context"(false);
RNG :: #import "Rand";
Controls :: #import "Controls";
WRender :: #import "WRender";
PNG :: #import "PNG";
Scene :: #import "Scene";
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
#placeholder version_string;

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

	counter := 0;
}

#program_export "app_update_loop" app_update_loop :: (app: *App) {
	app_user := app.user_data.(*App_User);
	start_time := app.platform.get_current_time();
	app_user.state.history_app_update_loop_dt[app_user.state.history_app_update_cursor] =
		to_float64_seconds(start_time - app_user.state.update_loop_timestamp).(float32);
	defer {
		app_user.state.update_loop_timestamp = start_time;
		app_user.state.history_app_update_cursor += 1;
		app_user.state.history_app_update_cursor %= app_user.state.history_app_update_loop_dt.count;
	}
	Remap_Context();
	auto_release_temp();
	app_user.app = app;
	app_user.state.platform = app.platform;
	app_user.graphics.gpu = app.platform.gpu;
	app_user.state.is_communication_established = app.platform.is_server_connected();
	app_user.state.is_connected &= app_user.state.is_communication_established;


	app.platform.get_frame_info(*app_user.allocated_frame_info);
	defer app.platform.end_frame();
	app_user.state.current_time = app_user.allocated_frame_info.time;
	if app_user.allocated_frame_info.quit
		return;

	if app_user.state.is_communication_established {
		if !app_user.state.is_connected {
			since_last_try := to_float64_seconds(
				app_user.state.current_time - app_user.state.last_connect_try
			);
			if since_last_try > 1.0 {
				app_user.state.last_connect_try = app_user.state.current_time;
				connect: Command.Connect;
				connect.token = app.platform.get_token();
				send_web_message(app.platform, app_user.state.current_time, make_command(connect));
			}
		}
	} else {
		if app.platform.is_released() {
			since_last_try := to_float64_seconds(
				app_user.state.current_time - app_user.state.last_establish_try
			);
			if since_last_try > 5.0 {
				app_user.state.last_establish_try = app_user.state.current_time;
				connection:, app_user.state.is_communication_established = app.platform.connect_server(
					"tackwin.fr", 443, "wss"
				);
			}
		}
	}

	GUI.begin_frame(*app_user.gui_state, app_user.allocated_frame_info, *app_user.controls, app_user.state.keyboard_layout);
	handle_debug_local_server(app_user);

	commands := parse_web_message(*app_user.state, app_user.allocated_frame_info);
	for command: commands {

		processed := process_main(app_user, command);

		while !processed {
			before_screen_state := app_user.state.screen_state;

			if app_user.state.screen_state == {
				case .Editor;
					if process_editor(app_user, command)
						continue command;
				case .Menu;
					if process_menu(app_user, command)
						continue command;
				case .Game;
					if process_game(
						app_user, command, app_user.controls, *app_user.process_response
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
			quit = menu_loop(app);
		case .Game;
			quit = game_loop(app_user);
		case .Editor;
			quit = editor_loop(app_user);
	}

	handle_sending_assets(app_user);
}

handle_sending_assets :: (app_user: *App_User) {
	state := *app_user.state;

	// pull the editor page's big assets
	for state.editor_page.big_assets_sending {
		array_add(*state.big_assets_sending, it);
	}
	state.editor_page.big_assets_sending.count = 0;
	for state.menu.big_assets_sending {
		array_add(*state.big_assets_sending, it);
	}
	state.menu.big_assets_sending.count = 0;

	for * state.big_assets_sending {
		if it.written < it.buffer.count {
			send := min(1024, it.buffer.count - it.written);
			command: Command.Asset_Chunk;
			command.asset.id = it.id;
			command.offset = it.written;
			command.data = NewArray(send, u8, false,, temp);
			memcpy(command.data.data, it.buffer.data + it.written, command.data.count);
			send_web_message(
				app_user.app.platform, app_user.state.current_time, make_command(command)
			);
			it.written += command.data.count;
			it.last_written = app_user.state.current_time;
		} else {
			free(it.buffer.data);
			remove it;
		}
	}
}

handle_end_asset :: (app_user: *App_User, asset: *Big_Asset) {
	state := *app_user.state;

	for * state.pending_thumbnails {
		if it.asset_id == asset.id {
		}
		it.* = .{};
	}

	free(asset.buffer.data);
	table_remove(*state.pending_big_assets, asset.id);
}

process_main :: (app_user: *App_User, command: Command) -> bool {
	state := *app_user.state;

	asset_chunk := isa(command.payload, Command.Asset_Chunk);
	if asset_chunk {
		asset := table_find_pointer(*state.pending_big_assets, asset_chunk.asset.id);
		if asset {
			memcpy(
				asset_chunk.data.data,
				asset.buffer.data + asset_chunk.offset,
				min(asset_chunk.data.count, asset.buffer.count - asset_chunk.offset)
			);
			asset.written += asset_chunk.data.count;
			if asset.written >= asset.buffer.count {
				handle_end_asset(app_user, asset);
			}
			asset.last_written = app_user.app.platform.get_current_time();
		}
	}

	return false;
}

#program_export "app_init" app_init :: (app: *App) {
	Remap_Context();

	app_user := New(App_User);
	app.user_data = app_user.(*void);
	app_user.app = app;
	app_user.state.platform = app.platform;
	app_user.graphics.gpu = app.platform.gpu;
	WRender.init_graphics(app.platform, *app_user.graphics);
	WRender.graphics = *app_user.graphics;
	init_store(app.platform, *app_user.store);
	GUI.gui_state_init(*app_user.gui_state, *app_user.store);
	menu := *app_user.state.menu;
	GUI.init(*menu.string_pool);
	menu.username = GUI.make(*menu.string_pool);
	menu.login_popup_password = GUI.make(*menu.string_pool);
	menu.scene_name_leadeboard = GUI.make(*menu.string_pool);
	menu.enter_instance_password = GUI.make(*menu.string_pool);
	menu.create_instance.filter = GUI.make(*menu.string_pool);
	menu.create_instance.name = GUI.make(*menu.string_pool);
	menu.create_instance.password = GUI.make(*menu.string_pool);
	menu.create_bomberman.name = GUI.make(*menu.string_pool);
	menu.create_bomberman.password = GUI.make(*menu.string_pool);
	GUI.init(*app_user.state.editor_page.string_pool);
	app_user.state.editor_page.load_filter = GUI.make(*app_user.state.editor_page.string_pool);
	app_user.state.editor_page.save_dialog_input = GUI.make(*app_user.state.editor_page.string_pool);
	WRender.init_framegraph(*app_user.framegraph, *app_user.store);

	Scene.make(*app_user.state.scene);
	app_user.state.scene.client.store = *app_user.store;
	Scene.init_camera(*app_user.state.scene);

	launch_music(app_user, app.platform);
}

#program_export "app_reload_before" app_reload_before :: (_app: *App) {
	Remap_Context();
	reset_temporary_storage();
}
#program_export "app_reload" app_reload :: (_app: *App) {
	Remap_Context();
	app_user := _app.user_data.(*App_User);
	app_user.app = _app;
	app_user.state.platform = _app.platform;
	app_user.graphics.gpu = _app.platform.gpu;
	WRender.graphics = *app_user.graphics;
	GUI.gui_state_init(*app_user.gui_state, *app_user.store);
	GUI.rebind(*app_user.state.menu.string_pool);
	GUI.rebind(*app_user.state.editor_page.string_pool);

	scene: Scene.Scene;
	Scene.reload(*scene);
}

#program_export "app_loop" app_loop :: (_app: *App) -> bool {
	app_user := _app.user_data.(*App_User);

	start_time := _app.platform.get_current_time();
	app_user.state.history_app_render_loop_dt[app_user.state.history_app_render_cursor] =
		to_float64_seconds(start_time - app_user.state.render_loop_timestamp).(float32);
	defer {
		app_user.state.render_loop_timestamp = start_time;
		app_user.state.history_app_render_cursor += 1;
		app_user.state.history_app_render_cursor %= app_user.state.history_app_render_loop_dt.count;
	}

	app_user.app = _app;
	app_user.state.platform = _app.platform;
	app_user.graphics.gpu = _app.platform.gpu;
	Remap_Context();
	auto_release_temp();

	
	app_user.framegraph.settings.light_enabled = app_user.state.light_enabled;
	app_user.framegraph.settings.render_shadows = app_user.state.shadows_enabled;
	app_user.framegraph.settings.render_props = app_user.state.props_enabled;
	app_user.framegraph.settings.render_particles = app_user.state.particles_enabled;
	if app_user.state.game.rebuild_pipelines {
		app_user.framegraph.settings.multisamples = 4;
		if app_user.state.aa_mode == .No_AA
			app_user.framegraph.settings.multisamples = 1;
		app_user.framegraph.settings.shadow_size = 4096;
		if app_user.state.shadow_map_size == ._2048
			app_user.framegraph.settings.shadow_size = 2048;
		if app_user.state.shadow_map_size == ._1024
			app_user.framegraph.settings.shadow_size = 1024;
		WRender.init_framegraph(*app_user.framegraph, *app_user.store);
	}

	if app_user.store.texture_queues.count > 0 {
		while true if (compare_and_swap(*app_user.framegraph.frame_lock, 0, 1)) break;
		defer compare_and_swap(*app_user.framegraph.frame_lock, 1, 0);

		for app_user.store.texture_queues {
			if it.texture.gpu == null {
				WRender.WTexture.make_blank("", it.texture);
			}
			WRender.WTexture.upload(it.buffer, 0, it.texture);
			free(it.buffer.data);
		}
		app_user.store.texture_queues.count = 0;
	}

	app_user.framegraph.capture_requested = app_user.allocated_frame_info.capture_frame;
	to_present := WRender.present_frame(*app_user.framegraph, *app_user.store);
	if app_user.framegraph.take_screenshot {
		WRender.screenshot_frame(*app_user.framegraph, *app_user.store, _app.platform);
		app_user.framegraph.take_screenshot = false;
	}
	if app_user.allocated_frame_info.capture_frame {
		write_capture_png(app_user, _app.platform);
	}
	if to_present
		_app.platform.gpu.surfacePresent(app_user.graphics.surface);

	return true;
}

handle_debug_local_server :: (app_user: *App_User) {
	if !app_user.gui_state.controls.just_pressed[Key.F9] return;
	platform := app_user.app.platform;
	ref := app_user.state.local_server;
	if query_process_status(platform, ref) == .Running {
		close_process(platform, ref);
		app_user.state.local_server = 0;
		return;
	}
	if ref != 0 close_process(platform, ref);
	app_user.state.local_server = create_process(platform, LOCAL_SERVER_PROCESS);
}

write_capture_png :: (app_user: *App_User, platform: *Platform) {
	rgb := app_user.framegraph.capture_rgb;
	width := app_user.framegraph.capture_width.(int);
	height := app_user.framegraph.capture_height.(int);
	if width <= 0 || height <= 0 return;
	if rgb.count < width * height * 3 return;
	encoded: [..] u8;
	encoded.allocator = temp;
	if !PNG.write_rgb(rgb, width, height, *encoded) return;
	path := tprint("captures/frame_%.png", app_user.allocated_frame_info.capture_serial);
	platform.write_file(path, encoded);
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

	big_assets_sending: [..] Big_Asset;

	pending_big_assets: Table(int, Big_Asset);
	pending_thumbnails: Table(int, Thumbnail_Pending);

	menu: Menu;
	game: Game_Page;
	editor: Editor;
	editor_page: Editor_Page;

	Playing :: struct {
		escape_menu_open: bool = false;
	}
	playing: Playing;

	platform: *Platform;
	scene: Scene.Scene;

	is_connected := false;
	is_communication_established := false;
	local_server: Platform.extern_ref = 0;

	ntp_period: Period(0.15);
	NTP_Result :: struct {
		offset: float64 = 0;
		ping: float64 = 0;
		time: float64 = 0;
	}

	ntp_history: [64] NTP_Result;
	ntp_history_cursor := 0;

	received_command_history: [..] Command.payload.Kind;

	history_app_update_loop_dt: [300] float;
	history_app_update_cursor := 0;
	update_loop_timestamp: Apollo_Time;

	history_app_render_loop_dt: [300] float;
	history_app_render_cursor := 0;
	render_loop_timestamp: Apollo_Time;
	
	render_fps := false;
	render_command_debug := false;
	filter_command_debug: [#run enum_highest_value(Command.payload.Kind) + 1] bool;

	last_connect_try: Apollo_Time;
	last_establish_try: Apollo_Time;

	render_throttle := false;

	volume_on := true;
	keyboard_layout: Layout = .AZERTY;

	// Render settings
	light_enabled := true;
	shadows_enabled := true;
	shadow_samples: enum { _4 :: 0; _9 :: 1; _25 :: 2; } = ._9;
	aa_mode: enum { FXAA :: 0; MSAA_2x :: 1; MSAA_4x :: 2; No_AA :: 3; } = .FXAA;
	particles_enabled := true;
	props_enabled := true;
	shadow_map_size: enum { _1024 :: 0; _2048 :: 1; _4096 :: 2; } = ._2048;

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