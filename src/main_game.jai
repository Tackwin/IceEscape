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
	result.time = to_float64_seconds(current_time_monotonic());
	state.ntp_history[state.ntp_history_cursor] = result;
	state.ntp_history_cursor += 1;
	state.ntp_history_cursor %= state.ntp_history.count;
}

process_menu :: (state: *State, command: Command) -> bool {
	connect := isa(command.payload, Command.Connect);
	if connect {
		state.is_connected = true;
		state.platform.set_token(connect.token);
		return true;
	}

	ans_instance_list := isa(command.payload, Command.Ans_Instance_List);
	if ans_instance_list {
		array_resize(*state.menu.instances_list, ans_instance_list.instances.count);
		for ans_instance_list.instances
			state.menu.instances_list[it_index] = it;
		return true;
	}

	ans_enter_instance := isa(command.payload, Command.Ans_Enter_Instance);
	if ans_enter_instance {

		return true;
	}

	sync_scene := isa(command.payload, Command.Sync_Scene);
	if sync_scene {
		print("Entering game scene %\n", sync_scene.id);
		state.screen_state = .Game;
		return false;
	}

	return false;
}

process_game :: (state: *State, command: Command, response: *Scene.Process_Response) ->  bool {
	ntp: *Command.NTP = isa(command.payload, Command.NTP);
	if ntp {
		is_over := false;
		send_back := false;
		reply := ntp.*;
		if reply.t0 == FLOAT64_MAX {
			reply.t0 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		} else if reply.t1 == FLOAT64_MAX {
			reply.t1 = to_float64_seconds(current_time_monotonic());
			reply.t2 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		} else if reply.t2 == FLOAT64_MAX {
			reply.t2 = to_float64_seconds(current_time_monotonic());
			is_over = false;
			send_back = true;
		} else if reply.t3 == FLOAT64_MAX {
			reply.t3 = to_float64_seconds(current_time_monotonic());
			reply.t4 = to_float64_seconds(current_time_monotonic());
			is_over = true;
			send_back = true;
		} else if reply.t4 == FLOAT64_MAX {
			reply.t4 = to_float64_seconds(current_time_monotonic());
			is_over = true;
			send_back = true; // We still send back one last time to optimize the number of packets.
		} else {
			// Should never happen, the server's last send back was when t3 == FLOAT64_MAX
			is_over = false;
			send_back = false;
		}

		if send_back && response {
			Scene.add(response, state.scene.id, reply);
		}

		if is_over
			process_complete_ntp(state, reply);

		return true;
	}

	give_control: *Command.Give_Control = isa(command.payload, Command.Give_Control);
	if give_control {
		state.scene.controlled_player_id = give_control.player_id;
		return true;
	}

	sync_scene: *Command.Sync_Scene = isa(command.payload, Command.Sync_Scene);
	if sync_scene {
		Terrain.parse_terrain(sync_scene.terrain, *state.scene);
		state.scene.id = sync_scene.id;
		state.scene.end_scene_countdown_started = false;
		state.scene.params = sync_scene.params;
		state.scene.auto_revive |= sync_scene.params.auto_revive;
		// Remove all players not present in the sync.
		for * state.scene.players {
			found := false;
			for s: sync_scene.players {
				if it.id == s.player_id {
					found = true;
					break;
				}
			}

			if !found
				remove it;
		}

		// Remove all presents, they are going to be synced from scratch.
		state.scene.presents.count = 0;

		// Add all new players.
		for sync_scene.players {
			player := Scene.find_by_player_id(state.scene, it.player_id);

			if !player {
				player: Scene.Player;
				player.id = it.player_id;
				array_add(*state.scene.players, player);
			}

			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.robots {
			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.antiairs {
			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.tombstones {
			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.presents {
			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.safe_zones {
			Scene.process(*state.scene, make_command(it), response);
		}

		for sync_scene.standins {
			Scene.process(*state.scene, make_command(it), response);
		}

		state.scene.server_rng = sync_scene.rng;
		return true;
	}

	return Scene.process(*state.scene, command, response);
}

send_web_message :: (platform: Platform, _command: Command) {
	command := _command;
	command.sent_timestamp = to_float64_seconds(current_time_monotonic());
	buffer: [..] u8;
	buffer.allocator = temp;
	serialize(command, *buffer);
	platform.send_web_message(buffer, 0);
}

// 				Scene.process(scene, *scene.player, Scene.make_player_command(command));

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

respond :: (platform: Platform, response: Scene.Process_Response) {
	for * response.entries {
		if isa(it.command.payload, Command.NTP)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Move)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Spawn_Coin)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Klaxon)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Active_Item)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Buy_Ask)
			send_web_message(platform, it.command);
		if isa(it.command.payload, Command.Ask_Respawn)
			send_web_message(platform, it.command);
	}
}

update_news :: (scene: *Scene.Scene, news: *[..] Scene.Breaking_News) {
	current_time := current_time_monotonic();
	cursor := 0;
	for * news.* {
		if to_float64_seconds(current_time - it.time) < 5.0 {
			news.data[cursor] = it;
			cursor += 1;
		} else {
			// News expired
			free(it.text);
		}
	}

	array_resize(news, cursor + scene.news.count);
	for 0..scene.news.count-1 {
		news.data[it + cursor].text = scene.news[it];
		news.data[it + cursor].time = current_time;
	}
	scene.news.count = 0;
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

	Scene.init_camera(*app_user.state.scene);

	launch_music(app_user, app.platform);
}

#program_export "app_reload" app_reload :: (_app: *App) {
	app_user := _app.user_data.(*App_User);
}

#program_export "app_loop" app_loop :: (_app: *App) -> bool {
	app_user := _app.user_data.(*App_User);
	Remap_Context();
	reset_temporary_storage();

	app_user.state.is_communication_established = _app.platform.is_server_connected();
	app_user.state.is_connected &= app_user.state.is_communication_established;

	_app.platform.get_frame_info(*app_user.allocated_frame_info);

	if app_user.allocated_frame_info.quit
		return false;

	GUI.begin_frame(*app_user.gui_state, *app_user.allocated_frame_info, *app_user.controls);

	commands := parse_web_message(*app_user.state, app_user.allocated_frame_info);
	for command: commands {

		while true {
			before_screen_state := app_user.state.screen_state;

			if app_user.state.screen_state == {
				case .Menu;
					if process_menu(*app_user.state, command)
						continue command;
				case .Game;
					if process_game(*app_user.state, command, *app_user.process_response)
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
	}


	_app.platform.gpu.surfacePresent(app_user.graphics.surface);
	_app.platform.end_frame();

	return quit;
}
#load "menu_loop.jai";
#load "game_loop.jai";

#program_export "app_quit" app_quit :: (_app: *App) {
}

launch_music :: (app_user: *App_User, platform: *Platform) {
	app_user.store.snowflakes_and_lights_mp3.kind = .Music;
	app_user.store.snowflakes_and_lights_mp3.repeating = true;
	app_user.store.snowflakes_and_lights_mp3.volume = 0.05;
	platform.play_audio(*app_user.store.snowflakes_and_lights_mp3, .{});
}

sounding :: (
	state: *State, scene: *Scene.Scene, store: Store, platform: *Platform
) {
	return;
	skull_seen: Table(int, bool);
	skull_seen.allocator = temp;

	shurikens_seen: Table(int, bool);
	shurikens_seen.allocator = temp;

	for * scene.skulls {
		ok, sound := table_find_new(*state.skull_id_to_sound, it.id);
		if !ok {
			audio := get_boat_sailing(store, 0);
			if !audio
				continue;
			audio.kind = .Sound;
			audio.exponent = 2.5;
			audio.volume = 0.04;
			sound = platform.play_audio(audio, .{});
			sound.volume = audio.volume;
			sound.loop = true;
			platform.set_sound(sound);
			table_set(*state.skull_id_to_sound, it.id, sound);
		}
		sound.position = Scene.compute_skull_pos(scene, it.*);
		platform.set_sound(sound);
		table_set(*skull_seen, it.id, true);
	}

	for * scene.shurikens {
		ok, sound := table_find_new(*state.shurikens_id_to_sound, it.id);
		if !ok {
			audio := get_drone_buzzing(store, 0);
			if !audio
				continue;
			audio.kind = .Sound;
			audio.exponent = 2.5;
			audio.volume = 0.010;
			sound = platform.play_audio(audio, .{});
			sound.volume = audio.volume;
			sound.loop = true;
			platform.set_sound(sound);
			table_set(*state.shurikens_id_to_sound, it.id, sound);
		}
		frame := Scene.find_by_frame_id(scene, it.frame_id);
		if !frame
			continue;
		M := Scene.compute_moving_frame_server_world_matrix(scene, frame);
		pos := M * v4(it.server.position, 1);
		sound.position = v3(pos);
		platform.set_sound(sound);
		table_set(*shurikens_seen, it.id, true);
	}

	for value, key: state.skull_id_to_sound {
		if !table_contains(*skull_seen, key) {
			value.playing = false;
			platform.set_sound(value);
			table_remove(*state.skull_id_to_sound, key);
		}
	}

	for value, key: state.shurikens_id_to_sound {
		if !table_contains(*shurikens_seen, key) {
			value.playing = false;
			platform.set_sound(value);
			table_remove(*state.shurikens_id_to_sound, key);
		}
	}

	listener: Listener;
	listener.position = scene.camera.position;
	listener.direction = scene.camera.target - scene.camera.position;
	listener.position += listener.direction * 0.65;
	listener.direction = normalize(listener.direction);
	platform.set_listener_info(listener);
	for scene.sound_triggers {
		for counter: 1..it.count {
			audio: Audio;
			audio.id = -1;
			if it.kind == {
				case .Footstep_Snow;
					idx := RNG.random_uniform(*scene.client_rng, 0, 5);
					audio_ptr := get_footstep_snow_sound(store, idx);
					if audio_ptr
						audio = audio_ptr.*;
					audio.volume = RNG.random_uniform(*scene.client_rng, 0.2, 0.4);
					audio.exponent = 1.0;
				case .Footstep_Ice;
					idx := RNG.random_uniform(*scene.client_rng, 0, 5);
					audio_ptr := get_footstep_ice_sound(store, idx);
					if audio_ptr
						audio = audio_ptr.*;
					audio.volume = RNG.random_uniform(*scene.client_rng, 0.75, 1.00);
					audio.exponent = 1.0;
				case .Car_Klaxon;
					idx := RNG.random_uniform(*scene.client_rng, 0, 3);
					audio_ptr := get_horn_car(store, idx);
					if audio_ptr
						audio = audio_ptr.*;
					audio.volume = RNG.random_uniform(*scene.client_rng, 0.65, 0.75);
					audio.exponent = 1.0;
				case .Explosion;
					idx := RNG.random_uniform(*scene.client_rng, 0, 9);
					audio_ptr := get_explosion_sound(store, idx);
					if audio_ptr
						audio = audio_ptr.*;
					audio.volume = RNG.random_uniform(*scene.client_rng, 1.0, 1.3);
					audio.exponent = 2.0;
				case .Loser;
					audio = store.loser_mp3;
					audio.volume = 2.0;
					audio.exponent = 1.0;
				case .Checkpoint_Ok;
					audio = store.checkpoint_ok_mp3;
					audio.volume = 2.0;
					audio.exponent = 2.0;
				case .Res;
					audio = store.res_mp3;
					audio.volume = 1.0;
					audio.exponent = 2.0;
				case .Coin_Launch;
					audio = store.coin_launch_mp3;
					audio.volume = 3.5;
					audio.exponent = 2.5;
				case .Point_Up;
					audio = store.point_up_mp3;
					audio.volume = 0.5;
			}
			if audio.id == -1
				continue;
			if it.inhead
				audio.exponent = 0.0;

			audio.pitch = RNG.random_uniform(*scene.client_rng, 0.8, 1.2);
			audio.kind = .Sound;
			audio.repeating = false;
			audio.delay = counter * 50; // Stagger sounds to avoid audio clutter.
			platform.play_audio(*audio, it.position);
		}
	}

	if state.volume_on {
		platform.volume_audio(1.0);
	} else {
		platform.volume_audio(0.0);
	}
}


State :: struct {
	coommands_received: [..] Command;

	Menu :: struct {
		create_instance_popup_open: bool = false;
		instances_list: [..] Command.Ans_Instance_List.Instance_Info;
	}
	menu: Menu;

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
	} = .Menu;

	to_send: [..] Command;
}