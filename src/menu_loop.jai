
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
				send_web_message(_app.platform, make_command(connect));
			}
		}
		if no_connection_ret.retry_localhost_clicked {
			if !state.is_communication_established {
				connection:, state.is_communication_established = _app.platform.connect_server(
					"localhost", 2356, "ws"
				);
			}

			if state.is_communication_established {
				connect: Command.Connect;
				connect.token = _app.platform.get_token();
				send_web_message(_app.platform, make_command(connect));
			}
		}
	} else {
		main_menu_args: GUI.Main_Menu_Args;
		main_menu_args.instances = NewArray(
			state.menu.instances_list.count, GUI.Instance_Info,, temp
		);
		main_menu_args.create_instance_popup_open = state.menu.create_instance_popup_open;
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
			gui_instance.auto_revive = it.auto_revive;
			gui_instance.instance_id = it.instance_id;
		}
		main_menu_ret := GUI.push_main_menu(*app_user.gui_state, main_menu_args);

		if main_menu_ret.reload_instances_clicked {
			command: Command.Ask_Instance_List;
			send_web_message(_app.platform, make_command(command));
		}

		if main_menu_ret.enter_instance_clicked && main_menu_ret.selected_instance_id >= 0 {
			command: Command.Ask_Enter_Instance;
			command.instance_id = main_menu_ret.selected_instance_id;
			send_web_message(_app.platform, make_command(command));
		}

		if main_menu_ret.create_instance_clicked {
			state.menu.create_instance_popup_open = !state.menu.create_instance_popup_open;
		}
	}

	frame := WRender.begin_frame(*framegraph);
	WRender.render_gui(*frame, *framegraph, app_user.gui_state, store);
	WRender.end_frame(*frame);

	return true;
}
