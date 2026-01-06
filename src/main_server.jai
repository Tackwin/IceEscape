#scope_file
#import "Rand";
#import "Utils";
#import "Basic";
#import "Remap_Context"(false);
#import "Thread";
#import "Profile";
#import "Instance";
#import "Platform";
#import "Hash_Table";
#import "File_Watcher";
#import "Communication";
Scene :: #import "Scene";

#scope_export

User :: struct {
	id: int = -1;
	token: int = -1;
	last_ping: Apollo_Time;
	connection: Connection;

	instance_id: int = -1;
	profile_id:  int = -1;
}

Server :: struct {
	rng: Rand.XORState;

	instance_generation := 1;
	users: [512] User;
	user_count := 0;

	instances: [512] Instance;
	instance_count := 0;

	profiles: [512] Profile;
	profile_count := 0;

	user_generation := 0;

	tick_period: Period(0.005);

	Queue :: struct(N: int) {
		commands  : [N] Command;
		connection: [N] Connection;
		count     := 0;
	};

	queue: Queue(128);

	file_watcher: File_Watcher(Server);
	changes: [..] string;
}

find_user_by_token :: (server: *Server, token: int) -> *User {
	for * server.users {
		if it.token == token
			return it;
	}
	return null;
}

find_user_by_connection :: (server: *Server, connection: Connection) -> *User {
	for * server.users {
		if it.connection == connection
			return it;
	}
	return null;
}
find_connection_by_user_id :: (server: *Server, user_id: int) -> Connection {
	for * server.users {
		if it.id == user_id
			return it.connection;
	}
	return -1;
}

find_instance_by_id :: (server: *Server, instance_id: int) -> *Instance {
	for * server.instances {
		if it.id == instance_id
			return it;
	}
	return null;
}

prepare_typed_message :: (_payload: $T) -> [] u8 {
	payload := _payload;

	buffer: [..] u8;
	buffer.allocator = temp;

	#if T == Command {
		payload.sent_timestamp = to_float64_seconds(current_time_monotonic());
		serialize(payload, *buffer);
	}

	return buffer;
}
parse_message :: (data: [] u8) -> Command, bool {
	if data.count < 8 {
		print("Message too short: %\n", data);
		return .{}, false;
	}

	size := (cast(*u64)data.data).*;
	if size > xx data.count {
		print("Message size mismatch: expected % but got %\n", size, data.count);
		return .{}, false;
	}

	cmd, ok := deserialize(data);

	if !ok {
		print("Failed to deserialize command\n");
		return .{}, false;
	}

	return cmd, true;
}

broadcast :: (platform: *Platform, server: *Server, data: $T) {
	message := prepare_typed_message(data);
	for server.users {
		platform.send_web_message(message, it.connection);
	}
}
broadcast_instance :: (platform: *Platform, server: *Server, instance: Instance, data: $T) -> bool {
	any := false;
	message := prepare_typed_message(data);
	for instance.persons {
		connection := find_connection_by_user_id(server, it.user_id);
		if connection >= 0 {
			platform.send_web_message(message, connection);
			any = true;
		}
	}
	return any;
}

send :: (platform: *Platform, connection: Connection, data: $T) {
	message := prepare_typed_message(data);
	platform.send_web_message(message, connection);
}

append_queue :: (server: *Server, cmd: $T, connection: Connection) {
	if server.queue.count >= server.queue.N {
		print("Queue overflow!\n");
		return;
	}

	server.queue.connection[server.queue.count] = connection;
	server.queue.commands[server.queue.count] = make_command(cmd);
	server.queue.count += 1;
}

process :: (server: *Server, cmd: Command, sender: Connection) -> bool {
	version_info := isa(cmd.payload, Command.Version_Info);
	if version_info {
		reply: Command.Version_Info;
		reply.server_version = 1;
		day, sec := #run, host -> int, int {
			#import "Basic";
			cal := to_calendar(current_time_consensus());
			return
				cal.year * 10000 + cal.month_starting_at_0 * 100 + cal.day_of_month_starting_at_0,
				cal.minute * 60 + cal.second;
		};
		reply.build_day = day;
		reply.build_second = sec;
		append_queue(server, reply, sender);
		return true;
	}

	connect := isa(cmd.payload, Command.Connect);
	if connect {
		user := find_user_by_token(server, connect.token);
		if user {
			reply: Command.Connect;
			reply.token = connect.token;
			user.connection = sender;
			append_queue(server, reply, user.connection);

			// If the user was in an instance, we send them back there
			instance := find_instance_by_id(server, user.instance_id);
			if instance {
				ans_enter_instance: Command.Ans_Enter_Instance;
				ans_enter_instance.reason = .Return;
				append_queue(server, ans_enter_instance, user.connection);

				resync_old_person(instance, user.id);
			}
			else {
				user.instance_id = -1;
			}
		} else {
			// new user
			user := *server.users[server.user_count];
			user.id = sender;
			user.token = connect.token;
			user.connection = user.id;
			user.instance_id = -1;
			server.user_generation += 1;
			server.user_count += 1;

			reply: Command.Connect;
			reply.token = user.token;
			append_queue(server, reply, sender);
		}
		return true;
	}

	ask_instance_list := isa(cmd.payload, Command.Ask_Instance_List);
	if ask_instance_list {
		reply: Command.Ans_Instance_List;
		reply.instances = NewArray(
			server.instance_count, Command.Ans_Instance_List.Instance_Info,, temp
		);

		for * reply.instances {
			it.instance_id = server.instances[it_index].id;
			memcpy(
				it.name.data,
				server.instances[it_index].name.data,
				min(server.instances[it_index].name.count, it.name.count)
			);
			it.current_players = server.instances[it_index].persons.count;
			it.max_players = 64; // Hardcoded for now
			it.auto_revive = server.instances[it_index].scene_parameters.auto_revive;
			it.private = server.instances[it_index].private;
			level_name := get_current_level_name(server.instances[it_index]);
			memcpy(
				it.level_name.data,
				level_name.data,
				min(level_name.count, it.level_name.count)
			);
		}

		append_queue(server, reply, sender);
		return true;
	}

	ask_enter_instance := isa(cmd.payload, Command.Ask_Enter_Instance);
	if ask_enter_instance {
		user := find_user_by_connection(server, sender);
		instance := find_instance_by_id(server, ask_enter_instance.instance_id);

		if !instance {
			ans_enter_instance: Command.Ans_Enter_Instance;
			ans_enter_instance.reason = .Instance_Not_Found;
			append_queue(server, ans_enter_instance, sender);
			return true;
		}

		if instance.private {
			match := true;
			for instance.password {
				if it == 0
					break;
				
				if it != ask_enter_instance.password[it_index] {
					match = false;
					break;
				}
			}

			if !match {
				ans_enter_instance: Command.Ans_Enter_Instance;
				ans_enter_instance.reason = .Wrong_Password;
				append_queue(server, ans_enter_instance, sender);
				return true;
			}
		}

		if user {
			if add_new_person(instance, user.id) {
				user.instance_id = instance.id;

				ans_enter_instance: Command.Ans_Enter_Instance;
				ans_enter_instance.reason = .Accepted;
				append_queue(server, ans_enter_instance, sender);
			}
		}

		return true;
	}

	leave_instance := isa(cmd.payload, Command.Leave_Instance);
	if leave_instance {
		user := find_user_by_connection(server, sender);
		if user {
			instance := find_instance_by_id(server, user.instance_id);
			if instance {
				remove_person(instance, user.id);
				user.instance_id = -1;
			}
		}
		return true;
	}

	create_inst := isa(cmd.payload, Command.Create_Instance);
	if create_inst {
		user := find_user_by_connection(server, sender);
		if user {
			if server.instance_count >= server.instances.count {
				ans_create_instance: Command.Ans_Create_Instance;
				ans_create_instance.reason = .Server_Full;
				append_queue(server, ans_create_instance, sender);
				return true;
			}

			params: Scene.Scene_Parameters;
			params.auto_revive = create_inst.auto_revive;

			init_instance(*server.instances[server.instance_count]);
			server.instances[server.instance_count].scene_parameters = params;
			server.instances[server.instance_count].id = server.instance_generation;
			memcpy(
				server.instances[server.instance_count].name.data,
				create_inst.name.data,
				min(create_inst.name.count, server.instances[server.instance_count].name.count)
			);
			memcpy(
				server.instances[server.instance_count].password.data,
				create_inst.password.data,
				min(
					create_inst.password.count,
					server.instances[server.instance_count].password.count
				)
			);
			server.instances[server.instance_count].private = create_inst.private;
			server.instances[server.instance_count].user_created = true;
			server.instance_count += 1;
			server.instance_generation += 1;

			ans_create_instance: Command.Ans_Create_Instance;
			ans_create_instance.reason = .Created;
			ans_create_instance.created_id = server.instances[server.instance_count].id;
			append_queue(server, ans_create_instance, sender);
			return true;
		}
	}

	return false;
}

print_messages :: false;
print_messages_send :: false;

server_receive_tick :: (platform: *Platform, server: *Server) {
	messages := platform.gather_web_messages();

	#if print_messages {
		if messages.count > 0
			print("Received % messages:\n", messages.count);
	}

	for msg: messages {
		cmd, parsed := parse_message(msg.data);
		if !parsed
			continue;

		#if print_messages {
			print("    % from %\n", cmd.payload.kind, msg.sender);
		}
		// The main thing we need to do here is route the command to the appropriate instance
		// Or handle it if it's a global command (like login)

		processed := process(server, cmd, msg.sender);
		if processed
			continue;

		// Route to instance
		user := find_user_by_connection(server, msg.sender);
		if user {
			instance := find_instance_by_id(server, user.instance_id);
			if instance {
				instance.received[instance.received_count].command = cmd;
				instance.received[instance.received_count].sender_user_id = user.id;
				instance.received_count += 1;
				instance.last_activity_time = current_time_monotonic();
			}
		}
	}
}

server_send_tick :: (platform: *Platform, server: *Server) {

	printed := false;
	#if print_messages && print_messages_send {
		if server.queue.count > 0 {
			print("Sending % messages from server\n", server.queue.count);
			printed = true;
		}
	}
	// Purge the send queue of the server and all the instances.

	// First the server queue
	for 0..server.queue.count - 1 {
		connection := server.queue.connection[it];
		cmd := server.queue.commands[it];

		#if print_messages && print_messages_send {
			print("    %\n", cmd.payload.kind);
		}

		if connection >= 0
			send(platform, connection, cmd);
		else
			broadcast(platform, server, cmd);
	}
	server.queue.count = 0;

	// Then the instances
	for 0..server.instance_count - 1 {
		instance := *server.instances[it];


		#if print_messages && print_messages_send {
			if instance.to_send_count > 0 {
				print("Instance % sending % messages\n", instance.id, instance.to_send_count);
				printed = true;
			}
		}

		for 0..instance.to_send_count - 1 {
			command := instance.to_send[it].command;
			target_user_id := instance.to_send[it].target_user_id;

			#if print_messages && print_messages_send {
				print("    %\n", command.payload.kind);
			}

			if target_user_id >= 0 {
				connection := find_connection_by_user_id(server, target_user_id);
				if connection >= 0 {
					send(platform, connection, command);
					instance.last_activity_time = current_time_monotonic();
				}
			}
			else {
				any := broadcast_instance(platform, server, instance, command);
				if any
					instance.last_activity_time = current_time_monotonic();
			}
		}
		instance.to_send_count = 0;
	}

	#if print_messages && print_messages_send {
		if printed
			print("\n");
	}
}

prefill_fixed_instances :: (server: *Server) {
	server.instance_count = 2;

	server.instances[0].id = server.instance_generation;
	string_to_array("Hades", server.instances[0].name);
	init_instance(*server.instances[0]);
	server.instance_generation += 1;

	server.instances[1].id = server.instance_generation;
	server.instances[1].scene_parameters.auto_revive = true;
	string_to_array("Olympus", server.instances[1].name);
	init_instance(*server.instances[1]);
	server.instance_generation += 1;
}

gc_instances :: (server: *Server) {
	cursor := 0;
	for 0..server.instance_count - 1 {
		instance := *server.instances[it];
		inactive_duration := to_float64_seconds(
			current_time_monotonic() - instance.last_activity_time
		);

		if instance.user_created && inactive_duration > instance.max_inactive_duration {
			print(
				"Garbage collecting instance % due to inactivity (seconds: %)\n",
				instance.id,
				inactive_duration
			);
			free(instance);
		}

		if cursor != it {
			server.instances[cursor] = server.instances[it];
		}
		cursor += 1;
	}
	server.instance_count = cursor;
}

App_User :: struct {
	app: *App;
	app_context: *#Context;
	server: Server;
	tick_error := 0.0;
}

WATCH_CHANGE :: true;

#program_export "app_init" app_init :: (app: *App) {
	Remap_Context();

	app_user := New(App_User);
	app.user_data = app_user;

	ok := app.platform.open_server(2356);
	if !ok {
		print("Failed to open server on port 2356\n");
		return;
	}

	app_user.server.tick_period.last = current_time_monotonic();
	prefill_fixed_instances(*app_user.server);

	#if WATCH_CHANGE {
		init(*app_user.server.file_watcher, null, *app_user.server, events_to_watch = .MODIFIED);
		add_directories(*app_user.server.file_watcher, "../assets/terrain");
	}
}

#program_export "app_reload" app_reload :: (app: *App) {
	Remap_Context();

	app_user := app.user_data.(*App_User);
	for 0..app_user.server.instance_count - 1 {
		instance := *app_user.server.instances[it];
		reload(instance);
	}
}

#program_export "app_loop" app_loop :: (app: *App) -> bool {
	Remap_Context();
	server_loop(app);
	return true;
}
server_loop :: (app: *App) {
	app_user := app.user_data.(*App_User);
	reset_temporary_storage();

	#if WATCH_CHANGE {
		changed := process_changes(*app_user.server.file_watcher);

		for change: app_user.server.file_watcher.changes {
			for 0..app_user.server.instance_count-1 {
				handle_file_change(*app_user.server.instances[it], change.full_path);
			}
		}
	}

	to_tick, dt := check(*app_user.server.tick_period, current_time_monotonic());
	if to_tick {
		while (dt + app_user.tick_error) > app_user.server.tick_period.period {
			server_receive_tick(app.platform, *app_user.server);

			for 0..app_user.server.instance_count-1
				update_instance(*app_user.server.instances[it], app_user.server.tick_period.period);

			server_send_tick(app.platform, *app_user.server);

			gc_instances(*app_user.server);
			dt -= app_user.server.tick_period.period;
		}

		app_user.tick_error += dt;
	}
}

#program_export "app_quit" app_quit :: (app: *App) {
}

