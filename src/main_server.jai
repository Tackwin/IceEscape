#scope_file
#import "Xar";
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
#import "Common";
#import "Communication";
Scene :: #import "Scene";
#import "Database";

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

	tick_period: Period(0.005);

	Queue :: struct(N: int) {
		commands  : [N] Command;
		connection: [N] Connection;
		count     := 0;
	};

	queue: Queue(128);

	file_watcher: File_Watcher(Server);
	changes: [..] string;

	db: DB_query.Handle;

	pending_big_assets: Table(int, Big_Asset);
	Big_Asset_Sending :: struct {
		user_asset_id: int;
		destination: Connection;
		asset: Big_Asset;
	}
	pending_big_assets_sending: [..] Big_Asset_Sending;

	pending_thumbnails: [1024] Thumbnail_Pending;
	pending_thumbnails_count := 0;
}

find_user_by_id :: (server: *Server, id: int) -> *User {
	for * server.users {
		if it.id == id
			return it;
	}
	return null;
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

handle_end_asset :: (server: *Server, asset: *Big_Asset, platform: *Platform) {
	for * server.pending_thumbnails {
		if it.asset_id == asset.id {
			ascii, has_ascii := sql_load(
				platform,
				server.db,
				sql(
					"SELECT * FROM terrain_asciis WHERE id = ? ORDER BY created_ms DESC LIMIT 1",
					it.terrain_id
				),
				DB_Terrain_Ascii
			);

			if has_ascii {
				sql_store(
					platform,
					server.db,
					DB_Terrain_Thumbnail.{
						ascii_id = ascii.ascii_id,
						thumbnail = asset.buffer,
					}
				);
			}
		}
		it.* = .{};
	}

	free(asset.buffer.data);
	table_remove(*server.pending_big_assets, asset.id);
}

process :: (server: *Server, cmd: Command, sender: Connection, platform: *Platform) -> bool {
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
		if !user {
			token_row, has_token := sql_load(
				platform,
				server.db,
				sql("SELECT * FROM profile_tokens WHERE token = ?", connect.token),
				DB_Profile_Token
			);

			if has_token {
				old_user: User;
				old_user.id = sender;
				old_user.token = connect.token;
				old_user.connection = sender;
				old_user.instance_id = -1;
				old_user.profile_id = token_row.id;
				server.users[server.user_count] = old_user;
				user = *server.users[server.user_count];
				server.user_count += 1;
			}
		}

		if user {
			reply: Command.Connect;
			reply.token = connect.token;
			reply.profile_id = user.profile_id;
			reply.passcode = 0xFFFFFFFFFFFFFFFF;
			pass_row, has_pass := sql_load(
				platform,
				server.db,
				sql("SELECT * FROM profile_passcodes WHERE id = ?", user.profile_id),
				DB_Profile_Passcode
			);
			if has_pass
				reply.passcode = pass_row.passcode;

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
			user.profile_id = -1;
			server.user_count += 1;

			// Let's create a profile id for them
			new_id: DB_Profile_Id;
			new_id.id = Rand.random_positive_int(*server.rng);
			user.profile_id = new_id.id;
			sql_store(platform, server.db, new_id);

			// And a passcode
			new_passcode: DB_Profile_Passcode;
			new_passcode.id = user.profile_id;
			new_passcode.passcode = Rand.random_u64(*server.rng);
			sql_store(platform, server.db, new_passcode);

			new_token: DB_Profile_Token;
			new_token.id = user.profile_id;
			new_token.token = connect.token.(u64);
			sql_store(platform, server.db, new_token);

			reply: Command.Connect;
			reply.token = user.token;
			reply.profile_id = user.profile_id;
			reply.passcode = new_passcode.passcode;
			append_queue(server, reply, sender);
		}
		return true;
	}

	login := isa(cmd.payload, Command.Login);
	if login {
		user := find_user_by_connection(server, sender);
		if user {
			pass_row, has_pass := sql_load(
				platform,
				server.db,
				sql("SELECT * FROM profile_passcodes WHERE passcode = ?", login.passcode),
				DB_Profile_Passcode
			);

			if !has_pass {
				command: Command.Login;
				command.feedback = .Rejected;
				append_queue(server, command, sender);
			} else {
				if pass_row.passcode == login.passcode {
					user.profile_id = pass_row.id;
					user.token = login.token;

					sql_store(
						platform,
						server.db,
						DB_Profile_Token.{
							id = user.profile_id,
							token = login.token.(u64),
						}
					);

					command: Command.Login;
					command.feedback = .Accepted;
					append_queue(server, command, sender);
				} else {
					command: Command.Login;
					command.feedback = .Wrong_Password;
					append_queue(server, command, sender);
				}
			}

			return true;
		}
	}

	load_terrain := isa(cmd.payload, Command.Load_Terrain);
	if load_terrain {
		user := find_user_by_connection(server, sender);
		if user {
			terrain_ascii, has_ascii := sql_load(
				platform,
				server.db,
				sql(
					"SELECT * FROM terrain_asciis WHERE id = ? ORDER BY created_ms DESC LIMIT 1",
					load_terrain.terrain_id
				),
				DB_Terrain_Ascii
			);

			terrain_info, has_info := sql_load(
				platform,
				server.db,
				sql("SELECT * FROM terrain_infos WHERE id = ?", load_terrain.terrain_id),
				DB_Terrain_Infos
			);

			if has_ascii && has_info {
				reply: Command.Load_Terrain;
				reply.terrain_id = load_terrain.terrain_id;
				reply.ascii = terrain_ascii.ascii;
				reply.info = Scene.Scene_Info.{};
				reply.info.id = terrain_info.id;
				reply.info.author_profile_id = terrain_info.author_profile_id;
				memcpy(
					reply.info.name.data,
					terrain_info.name.data,
					min(terrain_info.name.count, reply.info.name.count)
				);
				append_queue(server, reply, sender);
			}
		}

		return true;
	}

	get_instance_tab_stats: *Command.Get_Instance_Tab_Stats = isa(
		cmd.payload, Command.Get_Instance_Tab_Stats
	);
	if get_instance_tab_stats {
		user := find_user_by_connection(server, sender);
		if user {
			instance := find_instance_by_id(server, user.instance_id);
			if instance {
				person := find_person_by_user_id(instance, user.id);
				if person {
					scene := find_scene_of_player_id(instance, person.player_id);
					if scene {
						reply: Command.Get_Instance_Tab_Stats;
						time_entry := get_wr_info(platform, server.db, scene.info.id);
						reply.wr_time_ms = time_entry.time_ms;
						reply.wr_player_name = get_profile_name(
							platform, server.db, time_entry.profile_id
						);
						if scene.next_id >= 0 && scene.next_id < instance.scenes.count {
							next_terrain_id := instance.scenes[scene.next_id].info.id;
							reply.next_terrain_name = get_terrain_info(
								platform, server.db, next_terrain_id
							).name;
						}
						reply.players_stats = NewArray(
							instance.persons.count,
							Command.Get_Instance_Tab_Stats_Player_Stats_Entry,,
							temp
						);
						for instance.persons {
							reply.players_stats[it_index].player_id = it.player_id;
							reply.players_stats[it_index].death = it.run_stats.death_count;
							reply.players_stats[it_index].revive = it.run_stats.revive_count;
							reply.players_stats[it_index].wins = it.run_stats.win_count;
						}

						queue_send(instance, make_command(reply), user.id);
						return true;
					}
				}
			}
		}
	}

	get_terrain_leaderboard := isa(cmd.payload, Command.Get_Terrain_Leaderboard);
	if get_terrain_leaderboard {
		terrain_id := get_terrain_leaderboard.terrain_id;
		info: DB_Terrain_Infos;
		found: bool;
		if terrain_id < 0 && get_terrain_leaderboard.scene_name.count > 0 {
			info, found = sql_load(
				platform,
				server.db,
				sql("SELECT * FROM terrain_infos WHERE name = ?", get_terrain_leaderboard.scene_name),
				DB_Terrain_Infos
			);
			if found
				terrain_id = info.id;
		} else {
			info, found = sql_load(
				platform,
				server.db,
				sql("SELECT * FROM terrain_infos WHERE id = ?", terrain_id),
				DB_Terrain_Infos
			);
		}
		if terrain_id < 0
			return true;

		time_entries: [..] DB_Time_Entry;
		time_entries.allocator = temp;
		for sql_loads(
			platform,
			server.db,
			sql("SELECT * FROM time_entries WHERE terrain_id = ?", terrain_id),
			DB_Time_Entry
		) {
			array_add(*time_entries, it);
		}

		reply: Command.Get_Terrain_Leaderboard;
		reply.terrain_id = terrain_id;
		reply.scene_name = tprint("%", info.name);
		reply.wr_time_ms = -1;
		if time_entries.count > 0 {

			min_idx := 0;
			for 1..time_entries.count - 1 {
				if time_entries[it].time_ms < time_entries[min_idx].time_ms {
					min_idx = it;
				}
			}

			reply.wr_time_ms = time_entries[min_idx].time_ms;

			reply.wr_username = "Unknown";
			wr_user, has_wr_user := sql_load(
				platform,
				server.db,
				sql("SELECT * FROM profile_usernames WHERE id = ?", time_entries[min_idx].profile_id),
				DB_Profile_Username
			);
			if has_wr_user
				reply.wr_username = wr_user.username;

			reply.entries = NewArray(
				time_entries.count, Command.Get_Terrain_Leaderboard_Entry,, temp
			);
			for entry_i: 0..time_entries.count - 1 {
				reply.entries[entry_i].time_ms = time_entries[entry_i].time_ms;
				reply.entries[entry_i].timestamp_ms = time_entries[entry_i].timestamp_ms;
				reply.entries[entry_i].username = "Unknown";
				entry_user, has_entry_user := sql_load(
					platform,
					server.db,
					sql("SELECT * FROM profile_usernames WHERE id = ?", time_entries[entry_i].profile_id),
					DB_Profile_Username
				);
				if has_entry_user
					reply.entries[entry_i].username = entry_user.username;
			}
		}
		
		append_queue(server, reply, sender);
		return true;
	}

	save_terrain := isa(cmd.payload, Command.Save_Terrain);
	if save_terrain {
		user := find_user_by_connection(server, sender);
		if user {
			if user.profile_id >= 0 {

				// First if the user has a terrain with the same name
				Loaded :: struct {
					id: int;
				}

				name: string;
				name.data = save_terrain.info.name.data;
				name.count = 0;
				for 0..save_terrain.info.name.count - 1 {
					name.count = it;
					if save_terrain.info.name.data[it] == 0
						break;
				}
				loaded, has_loaded := sql_load(
					platform,
					server.db,
					sql(
						"SELECT id FROM terrain_infos WHERE name = ? AND author_profile_id = ?",
						name,
						user.profile_id
					),
					Loaded
				);

				if has_loaded {
					// New ascii version for the same terrain id.
					sql_store(
						platform,
						server.db,
						DB_Terrain_Ascii.{
							id = loaded.id,
							ascii = save_terrain.ascii,
							created_ms = to_milliseconds(current_time_consensus()),
						}
					);
					return true;
				}
			}


			// Otherwise we create a new terrain with a new id,
			// and store the ascii and the info with this id
			new_id := Rand.random_positive_int(*server.rng);

			sql_store(platform, server.db, DB_Terrain_Id.{ id = new_id });

			new_info: DB_Terrain_Infos;
			new_info.id = new_id;
			new_info.author_profile_id = user.profile_id;
			new_info.name.data = save_terrain.info.name.data;
			new_info.created_ms = to_milliseconds(current_time_consensus());
			for char_i: 0..save_terrain.info.name.count - 1 {
				new_info.name.count = char_i;
				if save_terrain.info.name.data[char_i] == 0
					break;
			}
			sql_store(platform, server.db, new_info);

			sql_store(
				platform,
				server.db,
				DB_Terrain_Ascii.{
					id = new_id,
					ascii = save_terrain.ascii,
					created_ms = to_milliseconds(current_time_consensus()),
				}
			);
			return true;
		}
	}

	get_username := isa(cmd.payload, Command.Get_Username);
	if get_username {
		user := find_user_by_connection(server, sender);
		if user {
			reply: Command.Get_Username;
			reply.username = "";
			username_row, has_username := sql_load(
				platform,
				server.db,
				sql("SELECT * FROM profile_usernames WHERE id = ?", user.profile_id),
				DB_Profile_Username
			);
			if has_username
				reply.username = tprint("%", username_row.username);
			append_queue(server, reply, sender);
		}
		return true;
	}

	set_username := isa(cmd.payload, Command.Set_Username);
	if set_username {
		user := find_user_by_connection(server, sender);
		if user {
			sql_store(
				platform,
				server.db,
				DB_Profile_Username.{
					id = user.profile_id,
					username = set_username.username,
				}
			);
		}
		return true;
	}

	get_profile_stats := isa(cmd.payload, Command.Get_Profile_Stats);
	if get_profile_stats {
		user := find_user_by_connection(server, sender);
		if user {
			reply: Command.Get_Profile_Stats;
			reply.stats.win_count = 0;
			reply.stats.death_count = 0;
			reply.stats.revive_count = 0;
			stats_row, has_stats := sql_load(
				platform,
				server.db,
				sql("SELECT * FROM profile_stats WHERE id = ?", user.profile_id),
				DB_Profile_Stats
			);
			if has_stats {
				reply.stats.win_count = stats_row.win_count;
				reply.stats.death_count = stats_row.death_count;
				reply.stats.revive_count = stats_row.revive_count;
			}
			append_queue(server, reply, sender);
		}
		return true;
	}

	ask_terrain_list := isa(cmd.payload, Command.Ask_List_Terrain);
	if ask_terrain_list {
		Info :: struct {
			id: int;
			name: string;
			author_name: string;
			created_ms: int;
		};
		filter_pattern := "%";
		if ask_terrain_list.filter.count > 0 {
			filter_pattern = tprint("%\%", ask_terrain_list.filter);
		}
		entries: [..] Info;
		entries.allocator = temp;
		for sql_loads(
			platform,
			server.db,
			sql(#string SELECT_QUERY
SELECT
	ti.id,
	ti.name,
	u.username AS author_name,
	ti.created_ms
FROM terrain_infos ti
LEFT JOIN profile_usernames u ON ti.author_profile_id = u.id
WHERE ti.name LIKE ?
SELECT_QUERY, filter_pattern),
			Info
		) {
			array_add(*entries, it);
		}

		reply: Command.Ans_List_Terrain;
		reply.terrains_id = NewArray(entries.count, int,, temp);
		reply.terrains_name = NewArray(entries.count, string,, temp);
		reply.authors_name = NewArray(entries.count, string,, temp);
		reply.creation_time_ms = NewArray(entries.count, s64,, temp);
		reply.correlation_id = ask_terrain_list.correlation_id;
	
		for 0..entries.count - 1 {
			reply.terrains_id[it] = entries[it].id;
			reply.terrains_name[it] = tprint("%", entries[it].name);
			reply.authors_name[it] = tprint("%", entries[it].author_name);
			reply.creation_time_ms[it] = entries[it].created_ms;
		}
		append_queue(server, reply, sender);
		return true;
	}

	ask_instance_list := isa(cmd.payload, Command.Ask_Instance_List);
	if ask_instance_list {
		reply: Command.Ans_Instance_List;
		reply.instances = NewArray(
			server.instance_count, Command.Ans_Instance_List.Instance_Info,, temp
		);

		cursor := 0;
		for index: 0..server.instance_count - 1 {
			instance := *server.instances[index];
			if instance.hidden
				continue;
			it := *reply.instances[cursor];
			cursor += 1;

			it.instance_id = instance.id;
			memcpy(
				it.name.data,
				instance.name.data,
				min(instance.name.count, it.name.count)
			);
			it.current_players = instance.persons.count;
			it.max_players = 64; // Hardcoded for now
			it.auto_revive = instance.scene_parameters.auto_revive;
			it.private = instance.private;
			level_name := get_current_level_name(instance);
			memcpy(
				it.level_name.data,
				level_name.data,
				min(level_name.count, it.level_name.count)
			);
		}
		reply.instances.count = cursor;

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
			if user.instance_id == instance.id {
				// If the user is already in the instance, we just resend the current state to them
				ans_enter_instance: Command.Ans_Enter_Instance;
				ans_enter_instance.reason = .Already_In;
				append_queue(server, ans_enter_instance, sender);

				resync_old_person(instance, user.id);
			}
			if add_new_person(instance, user.id) {
				user.instance_id = instance.id;

				ans_enter_instance: Command.Ans_Enter_Instance;
				ans_enter_instance.reason = .Accepted;
				append_queue(server, ans_enter_instance, sender);
			}
		}

		return true;
	}

	asset_chunk := isa(cmd.payload, Command.Asset_Chunk);
	if asset_chunk {
		user := find_user_by_connection(server, sender);
		if user {
			asset_id := get_hash(int.[asset_chunk.asset.id, user.profile_id]);
			asset := table_find_pointer(*server.pending_big_assets, asset_id);
			if asset {
				memcpy(
					asset.buffer.data + asset_chunk.offset,
					asset_chunk.data.data,
					min(asset_chunk.data.count, asset.buffer.count - asset_chunk.offset)
				);
				asset.written += asset_chunk.data.count;
				if asset.written >= asset.buffer.count {
					handle_end_asset(server, asset, platform);
				}
				asset.last_written = current_time_monotonic();
			}
			return true;
		}
	}

	set_thumbnail := isa(cmd.payload, Command.Set_Thumbnail);
	if set_thumbnail {
		user := find_user_by_connection(server, sender);
		if user {
			print("Received request to set thumbnail for terrain id %\n", set_thumbnail.terrain_id);
			asset_id := get_hash(int.[set_thumbnail.asset.id, user.profile_id]);

			pending: Thumbnail_Pending;
			pending.terrain_id = set_thumbnail.terrain_id;
			pending.asset_id = asset_id;
			server.pending_thumbnails[server.pending_thumbnails_count] = pending;
			server.pending_thumbnails_count += 1;
			server.pending_thumbnails_count %= server.pending_thumbnails.count;

			asset: Big_Asset;
			asset.id = asset_id;
			array_resize(*asset.buffer, set_thumbnail.asset.size);
			asset.written = 0;
			asset.last_written = current_time_monotonic();
			table_add(*server.pending_big_assets, asset.id, asset);
			return true;
		}
	}

	get_thumbnail := isa(cmd.payload, Command.Get_Thumbnail);
	if get_thumbnail {
		user := find_user_by_connection(server, sender);
		if user {
			ascii_row, has_ascii := sql_load(
				platform,
				server.db,
				sql(
					"SELECT ascii_id FROM terrain_asciis WHERE id = ? ORDER BY created_ms DESC LIMIT 1",
					get_thumbnail.terrain_id
				),
				DB_Terrain_Ascii
			);
			if has_ascii {
				ascii_id := ascii_row.ascii_id;
				thumb, has_thumb := sql_load(
					platform,
					server.db,
					sql("SELECT thumbnail FROM terrain_thumbnails WHERE ascii_id = ?", ascii_id),
					DB_Terrain_Thumbnail
				);
				if has_thumb {
					reply: Command.Get_Thumbnail;
					reply.terrain_id = get_thumbnail.terrain_id;
					reply.asset.size = thumb.thumbnail.count;
					reply.asset.id = get_thumbnail.asset.id;

					asset_id := get_hash(int.[ascii_id, user.profile_id]);

					sending: Server.Big_Asset_Sending;
					sending.user_asset_id = get_thumbnail.asset.id;
					sending.destination = sender;
					sending.asset.id = asset_id;
					sending.asset.buffer = NewArray(thumb.thumbnail.count, u8);
					memcpy(
						sending.asset.buffer.data,
						thumb.thumbnail.data,
						sending.asset.buffer.count
					);
					array_add(*server.pending_big_assets_sending, sending);

					append_queue(server, reply, sender);
				}
			}

			return true;
		}
	}

	ask_enter_quick_instance := isa(cmd.payload, Command.Ask_Enter_Quick_Instance);
	if ask_enter_quick_instance {
		user := find_user_by_connection(server, sender);
		if user {
			if server.instance_count >= server.instances.count {
				ans_create_instance: Command.Ans_Create_Instance;
				ans_create_instance.reason = .Server_Full;
				append_queue(server, ans_create_instance, sender);
				return true;
			}

			params: Scene.Scene_Parameters;
			params.auto_revive = false;

			created := init_quick_instance(
				server,
				server.instances.data + server.instance_count,
				ask_enter_quick_instance.terrain_id,
				platform
			);
			if !created {
				ans_create_instance: Command.Ans_Create_Instance;
				ans_create_instance.reason = .Bugged;
				append_queue(server, ans_create_instance, sender);
				return true;
			}
			server.instances[server.instance_count].scene_parameters = params;
			server.instances[server.instance_count].id = server.instance_generation;
			server.instances[server.instance_count].hidden = true;
			server.instances[server.instance_count].private = true;
			server.instances[server.instance_count].user_created = true;
			server.instance_count += 1;
			server.instance_generation += 1;

			if !add_new_person(*server.instances[server.instance_count - 1], user.id) {
				command: Command.Ans_Enter_Custom_Instance;
				command.reason = .Rejected;
				append_queue(server, command, sender);
				return true;
			}

			user.instance_id = server.instances[server.instance_count - 1].id;
			ans_enter_custom_instance: Command.Ans_Enter_Custom_Instance;
			ans_enter_custom_instance.reason = .Accepted;
			ans_enter_custom_instance.instance_id = server.instances[server.instance_count - 1].id;
			append_queue(server, ans_enter_custom_instance, sender);
			return true;
		}
	}

	ask_enter_custom_instance := isa(cmd.payload, Command.Ask_Enter_Custom_Instance);
	if ask_enter_custom_instance {
		user := find_user_by_connection(server, sender);
		if !user {
			command: Command.Ans_Enter_Custom_Instance;
			command.reason = .Rejected;
			append_queue(server, command, sender);
			return true;
		}
		if server.instance_count >= server.instances.count {
			command: Command.Ans_Enter_Custom_Instance;
			command.reason = .Server_Full;
			append_queue(server, command, sender);
			return true;
		}

		params: Scene.Scene_Parameters;
		params.auto_revive = true;
		
		init_instance_with_custom_terrain(
			*server.instances[server.instance_count], ask_enter_custom_instance.terrain
		);
		server.instances[server.instance_count].scene_parameters = params;
		server.instances[server.instance_count].id = server.instance_generation;
		server.instances[server.instance_count].private = true;
		server.instances[server.instance_count].user_created = true;
		server.instance_count += 1;
		server.instance_generation += 1;

		if !add_new_person(*server.instances[server.instance_count - 1], user.id) {
			command: Command.Ans_Enter_Custom_Instance;
			command.reason = .Rejected;
			append_queue(server, command, sender);
			return true;
		}
		user.instance_id = server.instances[server.instance_count - 1].id;

		ans_enter_custom_instance: Command.Ans_Enter_Custom_Instance;
		ans_enter_custom_instance.reason = .Accepted;
		ans_enter_custom_instance.instance_id = server.instances[server.instance_count - 1].id;
		append_queue(server, ans_enter_custom_instance, sender);
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

	create_bomberman := isa(cmd.payload, Command.Create_Bomberman);
	if create_bomberman {
		user := find_user_by_connection(server, sender);
		if user {
			if server.instance_count >= server.instances.count {
				ans_create_instance: Command.Ans_Create_Bomberman;
				ans_create_instance.reason = .Server_Full;
				append_queue(server, ans_create_instance, sender);
				return true;
			}

			instance := server.instances.data + server.instance_count;
			created := init_instance_bomberman(
				server, instance, create_bomberman.max_players, platform
			);
			instance.private = create_bomberman.private;
			instance.user_created = true;
			ans_create_bomberman: Command.Ans_Create_Bomberman;
			ans_create_bomberman.reason = .Created;
			ans_create_bomberman.created_id = instance.id;
			append_queue(server, ans_create_bomberman, sender);
			return true;
		}
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
			instance := server.instances.data + server.instance_count;
			
			created: bool;
			if create_inst.roster.count == 0 {
				created = init_instance_with_roster(server, instance, 2, platform);
			} else {
				created = init_instance_with_terrain_ids(
					server, instance, create_inst.roster, platform
				);
			}
			if !created {
				ans_create_instance: Command.Ans_Create_Instance;
				ans_create_instance.reason = .Bugged;
				append_queue(server, ans_create_instance, sender);
				return true;
			}

			instance.scene_parameters = params;
			instance.id = server.instance_generation;
			memcpy(
				instance.name.data,
				create_inst.name.data,
				min(create_inst.name.count, instance.name.count)
			);
			memcpy(
				instance.password.data,
				create_inst.password.data,
				min(create_inst.password.count, instance.password.count)
			);
			instance.private = create_inst.private;
			instance.user_created = true;

			ans_create_instance: Command.Ans_Create_Instance;
			ans_create_instance.reason = .Created;
			ans_create_instance.created_id = instance.id;
			append_queue(server, ans_create_instance, sender);
			return true;
		}
	}

	return false;
}

init_quick_instance :: (
	server: *Server, instance: *Instance, terrain_id: int, platform: *Platform
) -> bool {
	terrain_ascii, has_ascii := sql_load(
		platform,
		server.db,
		sql(
			"SELECT * FROM terrain_asciis WHERE id = ? ORDER BY created_ms DESC LIMIT 1",
			terrain_id
		),
		DB_Terrain_Ascii
	);

	if !has_ascii
		return false;

	terrain_info, has_info := sql_load(
		platform,
		server.db,
		sql("SELECT * FROM terrain_infos WHERE id = ?", terrain_id),
		DB_Terrain_Infos
	);

	if !has_info
		return false;

	info: Scene.Scene_Info;
	info.id = terrain_info.id;
	info.author_profile_id = terrain_info.author_profile_id;
	string_to_arr(terrain_info.name, info.name);

	add_scene(instance, terrain_ascii.ascii, info);
	if instance.scenes.count > 0 {
		instance.pick_scene_id = instance.scenes[0].id;
		for 0..instance.scenes.count-2 {
			instance.scenes[it].next_id = instance.scenes[it+1].id;
		}
		instance.playing_scene_id = instance.scenes[0].next_id;
	}
	return true;
}

init_instance_bomberman :: (
	server: *Server, instance: *Instance, max_player_count: int, platform: *Platform
) -> bool {
	instance.* = .{};
	instance.id = server.instance_generation;
	server.instance_generation += 1;
	instance.mode = .Bomberman;
	instance.last_activity_time = current_time_monotonic();

	entries: [..] int;
	entries.allocator = temp;
	for sql_loads(
		platform,
		server.db,
		sql("SELECT terrain_id FROM terrain_bomberman_entry WHERE max_players >= ?", max_player_count),
		DB_Terrain_Bomberman_Entry
	) {
		array_add(*entries, it.terrain_id);
	}

	if entries.count == 0
		return false;

	pick_id := 100;
	terrain_ascii, has_ascii := sql_load(
		platform,
		server.db,
		sql(
			"SELECT * FROM terrain_asciis WHERE id = ? ORDER BY created_ms DESC LIMIT 1",
			pick_id
		),
		DB_Terrain_Ascii
	);
	if !has_ascii
		return false;
	terrain_info, has_info := sql_load(
		platform,
		server.db,
		sql("SELECT * FROM terrain_infos WHERE id = ?", pick_id),
		DB_Terrain_Infos
	);
	if !has_info
		return false;

	info: Scene.Scene_Info;
	info.id = terrain_info.id;
	info.author_profile_id = terrain_info.author_profile_id;
	string_to_arr(terrain_info.name, info.name);

	pick_scene_id := add_scene(instance, terrain_ascii.ascii, info); // Pick up scene
	id := entries[0];
	terrain_ascii, has_ascii = sql_load(
		platform,
		server.db,
		sql("SELECT * FROM terrain_asciis WHERE id = ? ORDER BY created_ms DESC LIMIT 1", id),
		DB_Terrain_Ascii
	);
	if !has_ascii
		return false;

	terrain_info, has_info = sql_load(
		platform,
		server.db,
		sql("SELECT * FROM terrain_infos WHERE id = ?", id),
		DB_Terrain_Infos
	);

	if !has_info
		return false;

	info = .{};
	info.id = terrain_info.id;
	info.author_profile_id = terrain_info.author_profile_id;
	string_to_arr(terrain_info.name, info.name);

	playing_scene_id := set_bomberman_scene(instance, terrain_ascii.ascii, info);
	instance.pick_scene_id = pick_scene_id;
	instance.playing_scene_id = playing_scene_id;
	server.instance_count += 1;
	return true;
}

init_instance_with_roster :: (
	server: *Server, instance: *Instance, roster_id: int, platform: *Platform
) -> bool {
	roster, has_roster := sql_load(
		platform, server.db, sql("SELECT * FROM terrain_rosters WHERE id = ?", roster_id), DB_Terrain_Roster
	);
	if !has_roster {
		return false;
	}

	return init_instance_with_terrain_ids(server, instance, roster.terrain_ids, platform);
}

init_instance_with_terrain_ids :: (
	server: *Server, instance: *Instance, terrain_ids: [] int, platform: *Platform
) -> bool {
	instance.last_activity_time = current_time_monotonic();

	ids := NewArray(terrain_ids.count + 1, int,, temp);
	ids[0] = 100; // The pick up terrain
	for terrain_ids {
		ids[1 + it_index] = it;
	}

	for ids {
		if it_index > 0 && it == 100
			continue;

		terrain_id := it;
		terrain_ascii, has_ascii := sql_load(
			platform,
			server.db,
			sql(
				"SELECT * FROM terrain_asciis WHERE id = ? ORDER BY created_ms DESC LIMIT 1",
				terrain_id
			),
			DB_Terrain_Ascii
		);

		if !has_ascii
			continue;

		terrain_info, has_info := sql_load(
			platform,
			server.db,
			sql("SELECT * FROM terrain_infos WHERE id = ?", terrain_id),
			DB_Terrain_Infos
		);

		if !has_info
			continue;

		info: Scene.Scene_Info;
		info.id = terrain_info.id;
		info.author_profile_id = terrain_info.author_profile_id;
		string_to_arr(terrain_info.name, info.name);

		add_scene(instance, terrain_ascii.ascii, info);
	}
	if instance.scenes.count > 0 {
		instance.pick_scene_id = instance.scenes[0].id;
		for 0..instance.scenes.count-2 {
			instance.scenes[it].next_id = instance.scenes[it+1].id;
		}
		instance.playing_scene_id = instance.scenes[0].next_id;
	}
	instance.id = server.instance_generation;
	server.instance_generation += 1;
	server.instance_count += 1;
	return true;
}

handle_instance_events :: (server: *Server, instance: *Instance, platform: *Platform) {
	for event: instance.end_scene_events {
		user := find_user_by_id(server, event.user_id);
		if !user
			continue;

		stats_entry, has_stats := sql_load(
			platform,
			server.db,
			sql("SELECT * FROM profile_stats WHERE id = ?", user.profile_id),
			DB_Profile_Stats
		);
		if !has_stats {
			stats_entry.id = user.profile_id;
			stats_entry.win_count = 0;
			stats_entry.death_count = 0;
			stats_entry.revive_count = 0;
		}

		stats_entry.death_count += event.death_count;
		stats_entry.revive_count += event.revive_count;
		stats_entry.win_count += ifx event.winner then 1 else 0;

		sql_store(platform, server.db, stats_entry);

		if event.winner {
			sql_store(
				platform,
				server.db,
				DB_Time_Entry.{
					id = Rand.random_positive_int(*server.rng),
					profile_id = user.profile_id,
					terrain_id = event.scene_id,
					time_ms = event.time_ms,
					timestamp_ms = to_microseconds(current_time_monotonic()),
				}
			);
		}
	}
	instance.end_scene_events.count = 0;
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

		processed := process(server, cmd, msg.sender, platform);
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

	// also handle the big assets that are pending to be sent
	// but we have a maximum number of packet sent per tick to avoid flooding the network
	cursor := 0;
	sent := 0;
	for 0..server.pending_big_assets_sending.count - 1 {
		sending := *server.pending_big_assets_sending[it];
		if sent >= 4 {
			server.pending_big_assets_sending[cursor] = sending;
			cursor += 1;
			continue;
		}

		if sending.asset.buffer.count > 0 {
			command: Command.Asset_Chunk;
			command.asset.id = sending.user_asset_id;
			command.asset.size = sending.asset.buffer.count;
			command.data.data = sending.asset.buffer.data + sending.asset.written;
			command.data.count = min(
				1024, sending.asset.buffer.count - sending.asset.written
			);
			command.offset = sending.asset.written;
			send(platform, sending.destination, make_command(command));
			sending.asset.written += command.data.count;
			server.pending_big_assets_sending[cursor] = sending;
			if sending.asset.written < sending.asset.buffer.count {
				cursor += 1;
			} else {
				free(sending.asset.buffer.data);
			}
			sent += 1;
		}
	}
	server.pending_big_assets_sending.count = cursor;

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

prefill_fixed_instances :: (server: *Server, platform: *Platform) {
	init_instance_with_roster(server, *server.instances[0], 2, platform);
	string_to_array("Hades", server.instances[0].name);

	init_instance_with_roster(server, *server.instances[1], 2, platform);
	server.instances[1].scene_parameters.auto_revive = true;
	string_to_array("Olympus", server.instances[1].name);
	
	init_instance_bomberman(server, *server.instances[2], 64, platform);
	server.instances[2].scene_parameters.mode = .Bomberman;
	string_to_array("Bomberman", server.instances[2].name);
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
			continue;
		}

		if cursor != it {
			server.instances[cursor] = server.instances[it];
		}
		cursor += 1;
	}
	server.instance_count = cursor;
}

#load "embeded_database.jai";

ensure_database :: (app: *App) {
	app_user := app.user_data.(*App_User);
	app_user.server.db = open_database(app.platform, GAME_SERVER_DB);
	sql_exec(app.platform, app_user.server.db, sql("PRAGMA journal_mode=WAL;"));
	sql_exec(app.platform, app_user.server.db, sql("PRAGMA synchronous=NORMAL;"));

	ensure_database_schema(app.platform, app_user.server.db);

	embed_database_default_terrains(app);
	embed_database_default_rosters(app);
	embed_database_default_terrain_bomberman_entry(app);
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

	ok := app.platform.open_server(LOCAL_SERVER_PORT);
	if !ok {
		print("Failed to open server on port %\n", LOCAL_SERVER_PORT);
		return;
	}

	app_user.server.tick_period.last = current_time_monotonic();
	ensure_database(app);
	prefill_fixed_instances(*app_user.server, app.platform);

	app_user.server.rng = Rand.seed(to_microseconds(app_user.server.tick_period.last));

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

			for 0..app_user.server.instance_count-1 {
				update_instance(*app_user.server.instances[it], app_user.server.tick_period.period);
				handle_instance_events(
					*app_user.server, *app_user.server.instances[it], app.platform
				);
			}

			server_send_tick(app.platform, *app_user.server);

			gc_instances(*app_user.server);
			dt -= app_user.server.tick_period.period;
		}

		app_user.tick_error += dt;
	}
}

#program_export "app_quit" app_quit :: (app: *App) {
	quit_database(app.platform, app.user_data.(*App_User).server.db);
}

