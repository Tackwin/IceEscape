#scope_file
#import "Rand";
#import "Utils";
#import "Basic";
#import "Remap_Context"(false);
#import "Thread";
#import "Instance";
#import "Platform";
#import "Hash_Table";
#import "File_Watcher";
#import "Communication";

#scope_export

User :: struct {
	id: int = -1;
	token: int = -1;
	last_ping: Apollo_Time;
	connection: Connection;

	instance_id: int = -1;
}

Server :: struct {
	rng: Rand.XORState;

	users: [1024] User;
	user_count: int;

	instances: [1024] Instance;
	instance_count: int;

	user_generation := 0;

	tick_period: Period(0.005);

	Queue :: struct(N: int) {
		commands  : [N] Command;
		connection: [N] Connection;
		count     := 0;
	};

	queue: Queue(128);
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
			user.id = server.user_generation;
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

		if user {
			if add_new_person(instance, user.id) {
				user.instance_id = instance.id;
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

	return false;
}

print_messages :: false;

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
			print("    %\n", cmd.payload.kind);
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
			}
		}
	}
}

server_send_tick :: (platform: *Platform, server: *Server) {

	printed := false;
	#if print_messages {
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

		#if print_messages {
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


		#if print_messages {
			if instance.to_send_count > 0 {
				print("Instance % sending % messages\n", instance.id, instance.to_send_count);
				printed = true;
			}
		}

		for 0..instance.to_send_count - 1 {
			command := instance.to_send[it].command;
			target_user_id := instance.to_send[it].target_user_id;

			#if print_messages {
				print("    %\n", command.payload.kind);
			}

			if target_user_id >= 0 {
				connection := find_connection_by_user_id(server, target_user_id);
				if connection >= 0
					send(platform, connection, command);
			}
			else
				broadcast(platform, server, command);
		}
		instance.to_send_count = 0;
	}

	#if print_messages {
		if printed
			print("\n");
	}
}

prefill_fixed_instances :: (server: *Server) {
	server.instance_count = 2;

	server.instances[0] = create_instance("Hades", .{}).*;
	server.instances[0].id = 1;

	server.instances[1] = create_instance("Olympus", .{ auto_revive = true }).*;
	server.instances[1].id = 2;
}

App_User :: struct {
	app: *App;
	app_context: *#Context;
	server: Server;
	tick_error := 0.0;
}

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
}

#program_export "app_reload" app_reload :: (app: *App) {
}

#program_export "app_loop" app_loop :: (app: *App) -> bool {
	Remap_Context();
	server_loop(app);
	return true;
}
server_loop :: (app: *App) {
	app_user := app.user_data.(*App_User);
	reset_temporary_storage();

	to_tick, dt := check(*app_user.server.tick_period);
	if to_tick {
		while (dt + app_user.tick_error) > app_user.server.tick_period.period {
			server_receive_tick(app.platform, *app_user.server);

			for 0..app_user.server.instance_count-1
				update_instance(*app_user.server.instances[it], app_user.server.tick_period.period);

			server_send_tick(app.platform, *app_user.server);

			dt -= app_user.server.tick_period.period;
		}

		app_user.tick_error += dt;
	}
}

#program_export "app_quit" app_quit :: (app: *App) {
}

