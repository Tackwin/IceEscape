Menu :: struct {
	create_instance_popup_open: bool = false;
	create_instance_name: string = "";
	create_instance_password: string = "";

	enter_instance_password: string = "";

	instances_list: [..] Command.Ans_Instance_List.Instance_Info;
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
		state.screen_state = .Game;
		return false;
	}

	return false;
}

menu_loop :: (_app: *App) -> bool {
	app_user := _app.user_data.(*App_User);
	using app_user;

	app_user.graphics.gpu = _app.platform.gpu;
	WRender.graphics = *app_user.graphics;

	GUI.push_quad_screen(
		*app_user.gui_state,
		V2f.{ 0, 0 },
		V2f.{ controls.window_size.x, controls.window_size.y },
		V3f.{ 0.1, 0.1, 0.1 },
		0,
	);
	if !state.is_connected {
		no_connection_ret := GUI.push_no_connection(*app_user.gui_state);

		if no_connection_ret.retry_clicked {
			if !state.is_communication_established {
				connection:, state.is_communication_established = _app.platform.connect_server(
					"game.tackwin.fr", 443, "wss"
				);
			}

			if state.is_communication_established {
				connect: Command.Connect;
				connect.token = _app.platform.get_token();
				send_web_message(_app.platform, controls.time, make_command(connect));
			}
		}
		if no_connection_ret.retry_localhost_clicked {
			if !state.is_communication_established {
				connection:, state.is_communication_established = _app.platform.connect_server(
					"localhost", 2356, "ws"
				);
			}

			if state.is_communication_established {
				print("Launching localhost connect\n");
				connect: Command.Connect;
				connect.token = _app.platform.get_token();
				send_web_message(_app.platform, controls.time, make_command(connect));
			}
		}
	} else {
		main_menu_args: GUI.Main_Menu_Args;
		main_menu_args.instances = NewArray(
			state.menu.instances_list.count, GUI.Instance_Info,, temp
		);
		main_menu_args.create_instance_popup_open = state.menu.create_instance_popup_open;
		main_menu_args.create_instance_name = state.menu.create_instance_name;
		main_menu_args.create_instance_password = state.menu.create_instance_password;
		main_menu_args.enter_instance_password = state.menu.enter_instance_password;
		for state.menu.instances_list {
			gui_instance := *main_menu_args.instances[it_index];
			gui_instance.name.data = it.name.data;
			gui_instance.name.count = it.name.count;
			for gui_instance.name if it == 0 { gui_instance.name.count = it_index; break; }
			gui_instance.player_count = it.current_players;
			gui_instance.player_capacity = it.max_players;
			gui_instance.level_name.data = it.level_name.data;
			gui_instance.level_name.count = it.level_name.count;
			for gui_instance.level_name if it == 0 {
				gui_instance.level_name.count = it_index;
				break;
			}
			gui_instance.private = it.private;
			gui_instance.auto_revive = it.auto_revive;
			gui_instance.instance_id = it.instance_id;
		}
		main_menu_ret := GUI.push_main_menu(*app_user.gui_state, main_menu_args);
	
		if state.menu.create_instance_name.count > 0 &&  state.menu.create_instance_name.data
			free(state.menu.create_instance_name);
		state.menu.create_instance_name = sprint("%", main_menu_ret.temp_create_instance_name);

		if state.menu.create_instance_password.count > 0 &&  state.menu.create_instance_password.data
			free(state.menu.create_instance_password);
		state.menu.create_instance_password = sprint("%", main_menu_ret.temp_create_instance_password);

		if state.menu.enter_instance_password.count > 0 &&  state.menu.enter_instance_password.data
			free(state.menu.enter_instance_password);
		state.menu.enter_instance_password = sprint("%", main_menu_ret.temp_enter_instance_password);

		if main_menu_ret.create_instance_cancel_clicked {
			state.menu.create_instance_popup_open = false;
		}

		if main_menu_ret.create_instance_create_clicked {
			command: Command.Create_Instance;
			string_to_array(state.menu.create_instance_name, command.name);
			string_to_array(state.menu.create_instance_password, command.password);
			command.auto_revive = main_menu_ret.create_instance_auto_revive;
			command.private = main_menu_ret.create_instance_private;
			send_web_message(_app.platform, controls.time, make_command(command));
			state.menu.create_instance_popup_open = false;
		}

		if main_menu_ret.reload_instances_clicked {
			command: Command.Ask_Instance_List;
			send_web_message(_app.platform, controls.time, make_command(command));
		}

		if main_menu_ret.enter_instance_clicked && main_menu_ret.selected_instance_id >= 0 {
			command: Command.Ask_Enter_Instance;
			command.instance_id = main_menu_ret.selected_instance_id;
			string_to_array(state.menu.enter_instance_password, command.password);
			send_web_message(_app.platform, controls.time, make_command(command));
		}

		if main_menu_ret.create_instance_clicked {
			state.menu.create_instance_popup_open = !state.menu.create_instance_popup_open;
		}
	}

	frame := WRender.begin_frame(*framegraph, controls.time);
	WRender.render_gui(*frame, *framegraph, app_user.gui_state, store);
	WRender.end_frame(*frame);

	return true;
}
