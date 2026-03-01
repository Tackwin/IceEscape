#import "Scene";
#import "Basic";
#import "String";
#import "Algebra";
#import "Profile";
#import "Compiler";
#import "Math";
#import "Tagged_Union";
Rand :: #import "Rand";

#scope_export
string_to_array :: (in: string, out: [] u8) {
	for 0..min(in.count, out.count)-1
		out[it] = in[it];
}
array_to_string :: (in: [] u8, out: string) {
	out.count = in.count;
	for in if it == 0 {
		out.count = it_index;
		break;
	}
	for 0..out.count
		out[it] = in[it];
}

Sum_Type :: struct(types: ..Type) {
	#insert #run -> string {
		sb: String_Builder;
		print(*sb, "All_Types :: Type.[\n");
		for types {
			print(*sb, "    Command.%,\n", it);
		}
		print(*sb, "];\n");
		print(*sb, "Kind :: enum u32 {\n");
		for types {
			print(*sb, "    % :: %;\n", it, it_index);
		}
		print(*sb, "};\n");
		print(*sb, "kind: Kind;\n");

		print(*sb, "union {\n");
		for types {
			print(*sb, "    _%: Command.%;\n", it, it);
		}
		print(*sb, "bytes: u8;\n");
		print(*sb, "}\n");
		return builder_to_string(*sb);
	};
}

Command :: struct {
	Connect :: struct {
		token: int;
		profile_id: int;
		passcode: u64;
	}
	Login :: struct {
		passcode: u64;
		token: int;

		feedback: enum {
			Accepted;
			Wrong_Password;
			Rejected;
		}
	}
	Set_Passcode :: struct {
		passcode: u64;
	}
	Move :: struct {
		player_id: int;
		ground_target: V2f;
	}
	Get_Profile_Stats :: struct {
		stats: Statistics;
	}
	Spawn :: struct {
		scene_id: int;
		player_id: int;
		model_id := -1;
		its_you: bool;
	}
	Spawn_Coin :: struct {
		id: int;
		sender: int;
		position: V3f;
		direction: V3f;
		birthtime: float32;
	}
	Klaxon :: struct {
		player_id: int;
	}
	Drop :: struct {
		player_id: int;
	}
	Despawn_Coin :: struct {
		id: int;
	}
	Respawn :: struct {
		player_id := -1;
		spawn_position: V3f;
		spawn_direction: V3f;
		coin_id := -1;
		cause_player_id := -1;
	}
	Die :: struct {
		player_id: int;
		position: V3f;
	}
	Quit :: struct {
		player_id: int;
	}
	List_Terrain :: struct {
		filter: string;
		results: [] string;
	}
	New_Terrain :: struct {
		ascii: [] u8;
	}
	Sync_Player :: struct {
		player_id: int;
		model_id: int;
		position: V3f;
		direction: V3f;
		dead: bool;
		has_safe_present: bool;
		has_hook_present: int;
	}
	Give_Control :: struct {
		player_id: int;
	}
	Request_Stats :: struct {
		player_ids: [16] int;
	}
	Sync_Stats :: struct {
		player_id: int;
		death: int;
		revive: int;
		wins: int;
	}
	Sync_Skull :: struct {
		skull_id: int;
		offset: float;
		speed: float;
	}
	Sync_Key :: struct {
		key_id: int;
		position: V3f;
		holder: int;
	}
	Sync_Hook :: struct {
		hook_id: int;
		last_anchor_position: V3f;
		direction: V3f;
		hooker_id: int;
		hooked_id: int;
		length: float;
	}
	Sync_Gate :: struct {
		gate_id: int;
		is_closed: bool;
	}
	Sync_Moving_Frame :: struct {
		frame_id: int;
	}
	NTP :: struct {
		client_origin := false;
		player_id: int = -1;
		t0: float64 = FLOAT64_MAX;
		t1: float64 = FLOAT64_MAX;
		t2: float64 = FLOAT64_MAX;
		t3: float64 = FLOAT64_MAX;
		t4: float64 = FLOAT64_MAX;
	}
	Move_To_Play_World :: struct {
		player_id: int;
		model_id: int;
		play_world_id: int;
		standin_id: int = -1;
	}
	End_Level :: struct {
		winner_id: int;
		next_scene_id: int;
		next_level_scheduled_in_seconds := 60.0;

		most_death_id: int = -1;
		most_revive_id: int = -1;

		best_scores_id: [5] int = .[-1, -1, -1, -1, -1];

		time := 0.0;
	}
	Sync_Clock :: struct {
		t: float64;
	}
	Sync_Bomb_Spawner :: struct {
		bomb_spawner_id: int;
		bomb_spawned_id: int;
	}
	Sync_Bomb :: struct {
		bomb_id: int;
		bomb_spawner_id: int;
		holder_id: int;
		last_holder_id: int;

		position: V3f;
		time: float;
	}
	Sync_Robot :: struct {
		robot_id: int;
		position: V3f;
		shooting_time: float;
		shooting_cd: float;
	}
	Sync_AntiAir :: struct {
		id: int;
		position: V3f;
		target: V3f;
		target_size: V2f;
		cooldown: float;
		next_target: V2f;
		t: float; // Time since spawn
	}
	AntiAir_Shoot :: struct {
		antiair_id: int;
		next_target: V2f;
	}
	Sync_Score :: struct {
		player_id: int;
		souls: int;
	}
	Sync_Scene :: struct {
		id: int;
		info: Scene_Info;
		params: Scene_Parameters;
		terrain: string;
		rng: Rand.State;
		clock : float64;
		players: [] Sync_Player; // Would usually point to a temporary buffer.
		skulls: [] Sync_Skull;
		moving_frames: [] Sync_Moving_Frame;
		robots: [] Sync_Robot;
		antiairs: [] Sync_AntiAir;
		tombstones: [] Sync_Tombstone;
		presents: [] Sync_Present;
		safe_zones: [] Sync_Safe_Zone;
		standins: [] Sync_Stand_In;
	}
	Sync_Stand_In :: struct {
		standin_id: int;
		retired: bool;
	}
	Sync_Tombstone :: struct {
		player_id: int;
		position: V3f;
	}
	Sync_Present :: struct {
		present_id: int;
		position: V3f;
		kind: int;
		available: bool;
	}
	Explode :: struct {
		id: int;
		position: V3f;
		max_size: float;
		lifetime: float;
	}
	Wipe_Scene :: struct {
	}
	Retire :: struct {
		standin_id: int;
		trigger_id: int;
	}
	Sync_Safe_Zone :: struct {
		id: int;
		position: V3f;
		radius: float;
		expire: int;
	}
	Active_Item :: struct {
		player_id: int;
		safe_zone: bool;
		hook: bool;
	}
	Hooked_Player :: struct {
		hooker_id: int;
		hooked_id: int;
	}

	Cheat_Action :: struct {
		kind: enum {
			Next_Level;
			Reset_Level;
			Reset_Progression;
			Kick;
		}
		player_id: int;
	}

	Buy_Ask :: struct {
		present_id: int;
		player_id: int;
		item_kind: Present.Kind;
	}

	Buy_Response :: struct {
		present_id: int;
		player_id: int;
		item_kind: Present.Kind;
		success: bool;

		Why :: enum {
			Not_Enough_Points;
			Already_Have_Item;
			Too_Far;
		}

		why: Why;
	}

	Ask_Respawn :: struct {
		player_id: int;
	}

	Ask_Instance_List :: struct {
	}

	Ans_Instance_List :: struct {
		Instance_Info :: struct {
			instance_id: int;

			name: [64] u8;
			level_name: [64] u8;

			max_players: int;
			current_players: int;

			auto_revive: bool;
			private: bool;
		}
		
		instances: [] Instance_Info;
	}

	Ask_Enter_Instance :: struct {
		instance_id: int;
		password: [64] u8;
	}

	Ans_Enter_Instance :: struct {
		reason: enum {
			Accepted;
			Return;
			Wrong_Password;
			Instance_Not_Found;
			Instance_Full;
			Rejected;
			Kicked;
		}
	}

	Ask_Enter_Custom_Instance :: struct {
		terrain: string;
	}

	Ans_Enter_Custom_Instance :: struct {
		reason: enum {
			Accepted;
			Rejected;
			Server_Full;
		}

		instance_id: int;
		terrain: string;
	}

	Save_Terrain :: struct {
		info: Scene_Info;
		ascii: string;
	}
	Load_Terrain :: struct {
		terrain_id: int;
		info: Scene_Info;
		ascii: string;
	}
	Ask_List_Terrain :: struct {
		filter: string;
	}
	Ans_List_Terrain :: struct {
		terrains_id: [] int;
		terrains_name: [] string;
		authors_name: [] string;
		creation_time_ms: [] s64;
	}

	Create_Instance :: struct {
		name: [64] u8;
		password: [64] u8;
		auto_revive: bool;
		private: bool;
	}
	Ans_Create_Instance :: struct {
		reason: enum {
			Created;
			Server_Full;
			Rejected;
			Bugged;
		}
		created_id: int;
	}

	Set_Username :: struct {
		profile_id: int;
		username: string;
	}
	Get_Username :: struct {
		username: string;
	}

	Leave_Instance :: struct {
	}

	Version_Info :: struct {
		server_version: int;
		build_day: int;
		build_second: int;
	}

	Note_Played :: struct {
		pitch: int;
		jukebox_id: int;

		from_coin_id: int;
	}

	Get_Terrain_Leaderboard :: struct {
		terrain_id: int;

		wr_time_ms: int;
		wr_username: string;
	}

	Payload_t :: Sum_Type(
		Move, Spawn, New_Terrain, Sync_Player, Sync_Skull, Sync_Moving_Frame, Move_To_Play_World,
		Quit, Die, Respawn, Spawn_Coin, Despawn_Coin, Sync_Key, Sync_Gate, NTP, Sync_Scene, Connect,
		Wipe_Scene, End_Level, Sync_Robot, Explode, Sync_AntiAir, AntiAir_Shoot, Klaxon, Drop,
		Give_Control, Request_Stats, Sync_Tombstone, Retire, Sync_Present,
		Sync_Safe_Zone, Active_Item, Hooked_Player, Sync_Hook, Cheat_Action, Buy_Ask, Buy_Response,
		Sync_Stand_In, Ask_Respawn, Ask_Instance_List, Ans_Instance_List, Ask_Enter_Instance,
		Ans_Enter_Instance, Leave_Instance, Create_Instance, Ans_Create_Instance, Version_Info,
		Sync_Stats, Sync_Clock, Note_Played, Sync_Bomb_Spawner, Sync_Bomb, Sync_Score,
		Ask_Enter_Custom_Instance, Ans_Enter_Custom_Instance, Save_Terrain, Load_Terrain,
		Ask_List_Terrain, Ans_List_Terrain, Login, Set_Passcode, Get_Profile_Stats, Set_Username,
		Get_Username, Get_Terrain_Leaderboard
	);
	payload: Payload_t;
	sent_timestamp: float64;
}

isa :: (s: Sum_Type, $T: Type) -> *T {
	if s.All_Types[s.kind] == T
		return cast(*T) *s.bytes;

	other: Command;
	set(*other.payload, T.{});
	if (other.payload.kind == s.kind)
		return (*s.bytes).(*T);
	return null;
}

set :: (s: *Sum_Type, value: $T) {
	#run {
		found := false;
		for s.All_Types {
			if it == T {
				found = true;
				break;
			}
		}

		assert(found, "Type % not found\n", T);
	}

	s.kind = #insert #run -> string { return sprint(".%;", T); };
	(cast(*T) *s.bytes).* = value;
}

make_command :: (cmd: $T) -> Command {
	made: Command;
	set(*made.payload, cmd);
	return made;
}

serialize_generic :: (payload: *$T, data: [] u8) -> int {
	info :: type_info(T);
	if !payload {
		return 0;
	}
	if data.data == null {
		// Compute size needed to serialize

		#if info.type == .STRING {
			return payload.count;
		} else #if info.type == .STRUCT {
			size := 0;

			#insert #run -> string {
				sb: String_Builder;
				for info.members {
					print_to_builder(
						*sb,
						"size += serialize_generic(*payload.%, .[]);\n",
						it.name
					);
				}
				return builder_to_string(*sb);
			};

			return size;
		} else #if info.type == .ARRAY {
			if info.array_type == .FIXED
				return 0;
			if info.array_type == .VIEW
				return payload.count * serialize_generic(payload.data, .[]);
			assert(false, "Don't know how to serialize an array of type%\n", T);
		} else #if info.type == .INTEGER {
			return 0;
		} else #if info.type == .FLOAT {
			return 0;
		} else #if info.type == .BOOL {
			return 0;
		} else #if info.type == .ENUM {
			return 0;
		} else #if info.type == .VARIANT {
			varT :: #run -> Type {
				return get_type(type_info(T).variant_of);
			};
			variant: *varT = xx payload;
			return serialize_generic(variant, data);
		}
		else #if info.type == .POINTER {
			assert(false, "Don't know how to serialize a pointer of type%\n", T);
		}
		else {
			assert(false, "Don't know how to serialize type %\n", T);
		}
		return 0;
	}

	cursor := 0;
	subdata :: () -> [] u8 #expand {
		out: [] u8;
		out.data = data.data + cursor;
		out.count = data.count - cursor;
		return out;
	}
	#if info.type == .STRING {
		memcpy(data.data, payload.data, payload.count);
		cursor += payload.count;
	}
	#if info.type == .VARIANT {
		varT :: #run -> Type {
			return get_type(type_info(T).variant_of);
		};
		variant: *varT = xx payload;
		cursor += serialize_generic(variant, data);
	}
	#if info.type == .STRUCT {

		#insert #run -> string {
			sb: String_Builder;
			for info.members
				print_to_builder(
					*sb, "cursor += serialize_generic(*payload.%, subdata());\n", it.name
				);
			return builder_to_string(*sb);
		};
	}
	#if info.type == .ARRAY {
		if info.array_type == .VIEW {
			for 0..payload.count - 1 {
				cursor += serialize_generic(payload.data + it, subdata());
			}
		}
	}
	return cursor;
}

deserialize_generic :: (data: [] u8, out: *$T) -> int {
	info :: type_info(T);
	cursor := 0;
	subdata :: () -> [] u8 #expand {
		out: [] u8;
		out.data = data.data + cursor;
		out.count = data.count - cursor;
		return out;
	}
	#if info.type == .STRING {
		out.data = data.data;
		cursor += out.count;
	}
	#if info.type == .VARIANT {
		varT :: #run -> Type {
			return get_type(type_info(T).variant_of);
		};
		variant: *varT = xx out;
		cursor += deserialize_generic(data, variant);
	}
	#if info.type == .STRUCT {
		#insert #run -> string {
			sb: String_Builder;
			for info.members {
				print_to_builder(
					*sb,
					"cursor += deserialize_generic(subdata(), *out.%);\n",
					it.name
				);
			}
			return builder_to_string(*sb);
		};
	}
	#if info.type == .ARRAY {
		if info.array_type == .VIEW {
			for 0..out.count - 1 {
				sub := subdata();
				cursor += deserialize_generic(sub, out.data + it);
			}
		}
	}
	return cursor;
}

serialize :: (cmd: Command, buffer: *[..] u8) {
	// Serialize the command into the buffer
	dry_size := size_of(type_of(cmd)) + 8;
	array_reserve(buffer, dry_size);
	memcpy(buffer.data + 8, *cmd, size_of(type_of(cmd)));
	buffer.count = dry_size;
	defer {
		buffer.data.(*s64).* = buffer.count;
	}

	generic_case :: (T: $Type) #expand {
		typed := isa(cmd.payload, T);
		if !typed {
			print("Weirdge\n");
			break `label;
		}

		additional_data_size := serialize_generic(typed, .[]);
		array_reserve(buffer, dry_size + additional_data_size);
		cursor := dry_size;
		subdata: [] u8;
		subdata.data = buffer.data + cursor;
		subdata.count = additional_data_size;
		cursor += serialize_generic(typed, subdata);
		buffer.count = cursor;
	}

	for label: 0.. 0 if #complete cmd.payload.kind == {
		case .Wipe_Scene; #through;
		case .End_Level; #through;
		case .Move; #through;
		case .Spawn; #through;
		case .Connect; #through;
		case .Spawn_Coin; #through;
		case .Despawn_Coin; #through;
		case .Respawn; #through;
		case .Die; #through;
		case .Quit; #through;
		case .Buy_Ask; #through;
		case .Buy_Response; #through;
		case .Give_Control; #through;
		case .Request_Stats; #through;
		case .Login; #through;
		case .Get_Profile_Stats; #through;
		case .Set_Passcode; #through;
		case .Retire; #through;
		case .Ask_Respawn; #through;
		case .Sync_Tombstone; #through;
		case .New_Terrain; #through;
		case .Cheat_Action; #through;
		case .Sync_Player; #through;
		case .Sync_Safe_Zone; #through;
		case .Sync_Skull; #through;
		case .Sync_Score; #through;
		case .Sync_Key; #through;
		case .Sync_Gate; #through;
		case .Leave_Instance; #through;
		case .Create_Instance; #through;
		case .Ans_Create_Instance; #through;
		case .Version_Info; #through;
		case .Sync_Stats; #through;
		case .Sync_Clock; #through;
		case .AntiAir_Shoot; #through;
		case .Sync_Robot; #through;
		case .Sync_Present; #through;
		case .Sync_Hook; #through;
		case .Active_Item; #through;
		case .Sync_AntiAir; #through;
		case .Klaxon; #through;
		case .Drop; #through;
		case .Sync_Moving_Frame; #through;
		case .Note_Played; #through;
		case .Sync_Bomb; #through;
		case .Sync_Bomb_Spawner; #through;
		case .NTP; #through;
		case .Sync_Stand_In; #through;
		case .Hooked_Player; #through;
		case .Explode; #through;
		case .Ask_Instance_List; #through;
		case .Ans_Enter_Instance; #through;
		case .Ask_Enter_Instance; #through;
		case .Move_To_Play_World;
			// Nothing
		case .Get_Terrain_Leaderboard;
			generic_case(Command.Get_Terrain_Leaderboard);
		case .Set_Username;
			generic_case(Command.Set_Username);
		case .Get_Username;
			get_username := isa(cmd.payload, Command.Get_Username);
			if !get_username {
				print("Weirdge\n");
				break label;
			}

			additional_data_size := serialize_generic(get_username, .[]);
			array_reserve(buffer, dry_size + additional_data_size);
			cursor := dry_size;
			subdata: [] u8;
			subdata.data = buffer.data + cursor;
			subdata.count = additional_data_size;
			cursor += serialize_generic(get_username, subdata);
			buffer.count = cursor;
		case .Load_Terrain;
			load_terrain := isa(cmd.payload, Command.Load_Terrain);
			if !load_terrain {
				print("Weirdge\n");
				break label;
			}

			additional_data_size := load_terrain.ascii.count;
			array_reserve(buffer, dry_size + additional_data_size);

			cursor := dry_size;
			memcpy(
				buffer.data + cursor,
				load_terrain.ascii.data,
				load_terrain.ascii.count
			);
			cursor += load_terrain.ascii.count;
			buffer.count = cursor;
		case .Save_Terrain;
			save_terrain := isa(cmd.payload, Command.Save_Terrain);
			if !save_terrain {
				print("Weirdge\n");
				break label;
			}

			additional_data_size := save_terrain.ascii.count;
			array_reserve(buffer, dry_size + additional_data_size);

			cursor := dry_size;
			memcpy(
				buffer.data + cursor,
				save_terrain.ascii.data,
				save_terrain.ascii.count
			);
			cursor += save_terrain.ascii.count;
			buffer.count = cursor;
		case .Ask_List_Terrain;
			ask_list_terrain := isa(cmd.payload, Command.Ask_List_Terrain);
			if !ask_list_terrain {
				print("Weirdge\n");
				break label;
			}

			additional_data_size := ask_list_terrain.filter.count;
			array_reserve(buffer, dry_size + additional_data_size);

			cursor := dry_size;
			memcpy(
				buffer.data + cursor, ask_list_terrain.filter.data, ask_list_terrain.filter.count
			);
			cursor += ask_list_terrain.filter.count;
			buffer.count = cursor;
		case .Ans_List_Terrain;
			ans_list_terrain := isa(cmd.payload, Command.Ans_List_Terrain);
			if !ans_list_terrain {
				print("Weirdge\n");
				break label;
			}

			additional_data_size := 0;
			additional_data_size += ans_list_terrain.terrains_id.count * size_of(int);
			additional_data_size += ans_list_terrain.creation_time_ms.count * size_of(int);
			for ans_list_terrain.terrains_name {
				additional_data_size += size_of(u64); // Size prefix
				additional_data_size += it.count;
			}
			for ans_list_terrain.authors_name {
				additional_data_size += size_of(u64); // Size prefix
				additional_data_size += it.count;
			}
			array_reserve(buffer, dry_size + additional_data_size);

			cursor := dry_size;
			memcpy(
				buffer.data + cursor,
				ans_list_terrain.terrains_id.data,
				ans_list_terrain.terrains_id.count * size_of(int)
			);
			cursor += ans_list_terrain.terrains_id.count * size_of(int);
			memcpy(
				buffer.data + cursor,
				ans_list_terrain.creation_time_ms.data,
				ans_list_terrain.creation_time_ms.count * size_of(int)
			);
			cursor += ans_list_terrain.creation_time_ms.count * size_of(int);
			for ans_list_terrain.terrains_name {
				// Write size prefix
				size_prefix := it.count.(u64);
				memcpy(buffer.data + cursor, *size_prefix, size_of(u64));
				cursor += size_of(u64);

				// Write data
				memcpy(buffer.data + cursor, it.data, it.count);
				cursor += it.count;
			}
			for ans_list_terrain.authors_name {
				// Write size prefix
				size_prefix := it.count.(u64);
				memcpy(buffer.data + cursor, *size_prefix, size_of(u64));
				cursor += size_of(u64);

				// Write data
				memcpy(buffer.data + cursor, it.data, it.count);
				cursor += it.count;
			}
			buffer.count = cursor;
		case .Ans_Enter_Custom_Instance;
			ans_enter_custom_instance := isa(cmd.payload, Command.Ans_Enter_Custom_Instance);
			if !ans_enter_custom_instance {
				print("Weirdge\n");
				break label;
			}

			additional_data_size := ans_enter_custom_instance.terrain.count;
			array_reserve(buffer, dry_size + additional_data_size);

			cursor := dry_size;
			memcpy(
				buffer.data + cursor,
				ans_enter_custom_instance.terrain.data,
				ans_enter_custom_instance.terrain.count
			);
			cursor += ans_enter_custom_instance.terrain.count;
			buffer.count = cursor;
		case .Ask_Enter_Custom_Instance;
			ask_enter_custom_instance := isa(cmd.payload, Command.Ask_Enter_Custom_Instance);
			if !ask_enter_custom_instance {
				print("Weirdge\n");
				break label;
			}

			additional_data_size := ask_enter_custom_instance.terrain.count;
			array_reserve(buffer, dry_size + additional_data_size);

			cursor := dry_size;
			memcpy(
				buffer.data + cursor,
				ask_enter_custom_instance.terrain.data,
				ask_enter_custom_instance.terrain.count
			);
			cursor += ask_enter_custom_instance.terrain.count;
			buffer.count = cursor;
		case .Ans_Instance_List;
			ans_instance_list := isa(cmd.payload, Command.Ans_Instance_List);
			if !ans_instance_list {
				print("Weirdge\n");
				break label;
			}

			additional_data_size := 0;
			size := size_of(type_of(ans_instance_list.instances.data.*));
			additional_data_size += size * ans_instance_list.instances.count;
			array_reserve(buffer, dry_size + additional_data_size);

			cursor := dry_size;
			memcpy(
				buffer.data + cursor,
				ans_instance_list.instances.data,
				size * ans_instance_list.instances.count
			);
			cursor += size * ans_instance_list.instances.count;
			buffer.count = cursor;

		case .Sync_Scene;
			sync_scene := isa(cmd.payload, Command.Sync_Scene);
			if !sync_scene {
				print("Weirdge\n");
				break label;
			}
			additional_data_size := 0;
			additional_data_size += sync_scene.terrain.count;
			additional_data_size +=
				size_of(type_of(sync_scene.players.data.*)) * sync_scene.players.count;
			additional_data_size +=
				size_of(type_of(sync_scene.skulls.data.*)) * sync_scene.skulls.count;
			additional_data_size +=
				size_of(type_of(sync_scene.moving_frames.data.*)) * sync_scene.moving_frames.count;
			additional_data_size +=
				size_of(type_of(sync_scene.robots.data.*)) * sync_scene.robots.count;
			additional_data_size +=
				size_of(type_of(sync_scene.antiairs.data.*)) * sync_scene.antiairs.count;
			additional_data_size +=
				size_of(type_of(sync_scene.tombstones.data.*)) * sync_scene.tombstones.count;
			additional_data_size +=
				size_of(type_of(sync_scene.presents.data.*)) * sync_scene.presents.count;
			additional_data_size +=
				size_of(type_of(sync_scene.safe_zones.data.*)) * sync_scene.safe_zones.count;
			additional_data_size +=
				size_of(type_of(sync_scene.standins.data.*)) * sync_scene.standins.count;

			array_reserve(buffer, dry_size + additional_data_size);

			cursor := dry_size;
			memcpy(
				buffer.data + cursor,
				sync_scene.terrain.data,
				sync_scene.terrain.count
			);
			cursor += sync_scene.terrain.count;
			memcpy(
				buffer.data + cursor,
				sync_scene.players.data,
				size_of(type_of(sync_scene.players.data.*)) * sync_scene.players.count
			);
			cursor += size_of(type_of(sync_scene.players.data.*)) * sync_scene.players.count;
			memcpy(
				buffer.data + cursor,
				sync_scene.skulls.data,
				size_of(type_of(sync_scene.skulls.data.*)) * sync_scene.skulls.count
			);
			cursor += size_of(type_of(sync_scene.skulls.data.*)) * sync_scene.skulls.count;
			memcpy(
				buffer.data + cursor,
				sync_scene.moving_frames.data,
				size_of(type_of(sync_scene.moving_frames.data.*)) * sync_scene.moving_frames.count
			);
			cursor +=
				size_of(type_of(sync_scene.moving_frames.data.*)) * sync_scene.moving_frames.count;
			memcpy(
				buffer.data + cursor,
				sync_scene.robots.data,
				size_of(type_of(sync_scene.robots.data.*)) * sync_scene.robots.count
			);
			cursor += size_of(type_of(sync_scene.robots.data.*)) * sync_scene.robots.count;
			memcpy(
				buffer.data + cursor,
				sync_scene.antiairs.data,
				size_of(type_of(sync_scene.antiairs.data.*)) * sync_scene.antiairs.count
			);
			cursor += size_of(type_of(sync_scene.antiairs.data.*)) * sync_scene.antiairs.count;
			memcpy(
				buffer.data + cursor,
				sync_scene.tombstones.data,
				size_of(type_of(sync_scene.tombstones.data.*)) * sync_scene.tombstones.count
			);
			cursor += size_of(type_of(sync_scene.tombstones.data.*)) * sync_scene.tombstones.count;
			memcpy(
				buffer.data + cursor,
				sync_scene.presents.data,
				size_of(type_of(sync_scene.presents.data.*)) * sync_scene.presents.count
			);
			cursor += size_of(type_of(sync_scene.presents.data.*)) * sync_scene.presents.count;
			memcpy(
				buffer.data + cursor,
				sync_scene.safe_zones.data,
				size_of(type_of(sync_scene.safe_zones.data.*)) * sync_scene.safe_zones.count
			);
			cursor += size_of(type_of(sync_scene.safe_zones.data.*)) * sync_scene.safe_zones.count;
			memcpy(
				buffer.data + cursor,
				sync_scene.standins.data,
				size_of(type_of(sync_scene.standins.data.*)) * sync_scene.standins.count
			);
			cursor += size_of(type_of(sync_scene.standins.data.*)) * sync_scene.standins.count;
			buffer.count = cursor;
	}
}

deserialize :: (buffer: [] u8) -> Command, bool {
	expected_size := buffer.data.(*s64).*;
	if buffer.count < expected_size {
		print("Buffer too small\n");
		return .{}, false;
	}

	cmd := Command.{};
	memcpy(*cmd, buffer.data + 8, size_of(type_of(cmd)));
	cursor := 8 + size_of(type_of(cmd));

	generic_case :: (T: $Type) #expand {
		typed := isa(cmd.payload, T);
		if !typed {
			print("Weirdge\n");
			break `label;
		}

		remaining_size := expected_size - cursor;
		subdata: [] u8;
		subdata.data = buffer.data + cursor;
		subdata.count = remaining_size;

		cursor += deserialize_generic(subdata, typed);
	}

	for label: 0..0 if #complete cmd.payload.kind == {
		case .Active_Item; #through;
		case .Wipe_Scene; #through;
		case .Move; #through;
		case .End_Level; #through;
		case .Spawn; #through;
		case .Connect; #through;
		case .Sync_Score; #through;
		case .Spawn_Coin; #through;
		case .Despawn_Coin; #through;
		case .Cheat_Action; #through;
		case .Respawn; #through;
		case .Leave_Instance; #through;
		case .Create_Instance; #through;
		case .Ans_Create_Instance; #through;
		case .Version_Info; #through;
		case .Sync_Stats; #through;
		case .Sync_Clock; #through;
		case .Request_Stats; #through;
		case .Get_Profile_Stats; #through;
		case .Login; #through;
		case .Set_Passcode; #through;
		case .Die; #through;
		case .Give_Control; #through;
		case .Hooked_Player; #through;
		case .Quit; #through;
		case .Buy_Ask; #through;
		case .Buy_Response; #through;
		case .Klaxon; #through;
		case .Drop; #through;
		case .New_Terrain; #through;
		case .Sync_Player; #through;
		case .Ask_Respawn; #through;
		case .Sync_Stand_In; #through;
		case .Sync_Skull; #through;
		case .Sync_Key; #through;
		case .Sync_Gate; #through;
		case .Sync_Hook; #through;
		case .Note_Played; #through;
		case .Sync_Bomb; #through;
		case .Sync_Bomb_Spawner; #through;
		case .Sync_Tombstone; #through;
		case .Retire; #through;
		case .AntiAir_Shoot; #through;
		case .Sync_Robot; #through;
		case .Sync_Moving_Frame; #through;
		case .Sync_AntiAir; #through;
		case .NTP; #through;
		case .Sync_Present; #through;
		case .Explode; #through;
		case .Sync_Safe_Zone; #through;
		case .Ask_Enter_Instance; #through;
		case .Ans_Enter_Instance; #through;
		case .Ask_Instance_List; #through;
		case .Move_To_Play_World;
			return cmd, true;
		case .Get_Terrain_Leaderboard;
			generic_case(Command.Get_Terrain_Leaderboard);
			return cmd, true;
		case .Set_Username;
			generic_case(Command.Set_Username);
			return cmd, true;
		case .Get_Username;
			generic_case(Command.Get_Username);
			return cmd, true;
		case .Ask_List_Terrain;
			ask_list_terrain := isa(cmd.payload, Command.Ask_List_Terrain);
			if !ask_list_terrain {
				print("Weirdge\n");
				return cmd, false;
			}

			remaining_size := expected_size - cursor;
			ask_list_terrain.filter.data = (buffer.data + cursor).(*u8);
			ask_list_terrain.filter.count = remaining_size;
			cursor += remaining_size;

			return cmd, true;
		case .Ans_List_Terrain;
			ans_list_terrain := isa(cmd.payload, Command.Ans_List_Terrain);
			if !ans_list_terrain {
				print("Weirdge\n");
				return cmd, false;
			}

			ans_list_terrain.terrains_id.data = (buffer.data + cursor).(*int);
			cursor += size_of(int) * ans_list_terrain.terrains_id.count;
			ans_list_terrain.creation_time_ms.data = (buffer.data + cursor).(*int);
			cursor += size_of(int) * ans_list_terrain.creation_time_ms.count;

			terrains_name: [..] string;
			terrains_name.allocator = temp;
			for 0..ans_list_terrain.terrains_id.count-1 {
				size_prefix: u64;
				memcpy(*size_prefix, buffer.data + cursor, size_of(u64));
				cursor += size_of(u64);

				new_terrain: string;
				new_terrain.count = size_prefix.(int);
				new_terrain.data = (buffer.data + cursor).(*u8);
				cursor += new_terrain.count;

				array_add(*terrains_name, new_terrain);
			}
			ans_list_terrain.terrains_name = terrains_name;

			authors_name: [..] string;
			authors_name.allocator = temp;
			for 0..ans_list_terrain.terrains_id.count-1 {
				size_prefix: u64;
				memcpy(*size_prefix, buffer.data + cursor, size_of(u64));
				cursor += size_of(u64);

				new_author: string;
				new_author.count = size_prefix.(int);
				new_author.data = (buffer.data + cursor).(*u8);
				cursor += new_author.count;

				array_add(*authors_name, new_author);
			}
			ans_list_terrain.authors_name = authors_name;

			return cmd, true;
		case .Load_Terrain;
			load_terrain := isa(cmd.payload, Command.Load_Terrain);
			if !load_terrain {
				print("Weirdge\n");
				return cmd, false;
			}

			remaining_size := expected_size - cursor;
			load_terrain.ascii.data = (buffer.data + cursor).(*u8);
			load_terrain.ascii.count = remaining_size;
			cursor += remaining_size;

			return cmd, true;
		case .Save_Terrain;
			save_terrain := isa(cmd.payload, Command.Save_Terrain);
			if !save_terrain {
				print("Weirdge\n");
				return cmd, false;
			}

			remaining_size := expected_size - cursor;
			save_terrain.ascii.data = (buffer.data + cursor).(*u8);
			save_terrain.ascii.count = remaining_size;
			cursor += remaining_size;

			return cmd, true;
		case .Ans_Enter_Custom_Instance;
			ans_enter_custom_instance := isa(cmd.payload, Command.Ans_Enter_Custom_Instance);
			if !ans_enter_custom_instance {
				print("Weirdge\n");
				return cmd, false;
			}

			remaining_size := expected_size - cursor;
			ans_enter_custom_instance.terrain.data = (buffer.data + cursor).(*u8);
			ans_enter_custom_instance.terrain.count = remaining_size;
			cursor += remaining_size;
		case .Ask_Enter_Custom_Instance;
			ask_enter_custom_instance := isa(cmd.payload, Command.Ask_Enter_Custom_Instance);
			if !ask_enter_custom_instance {
				print("Weirdge\n");
				return cmd, false;
			}

			remaining_size := expected_size - cursor;
			ask_enter_custom_instance.terrain.data = (buffer.data + cursor).(*u8);
			ask_enter_custom_instance.terrain.count = remaining_size;
			cursor += remaining_size;

			return cmd, true;
		case .Ans_Instance_List;
			list := isa(cmd.payload, Command.Ans_Instance_List);
			if !list {
				print("Weirdge\n");
				return cmd, false;
			}

			list.instances.data = (buffer.data + cursor).(*Command.Ans_Instance_List.Instance_Info);
			cursor += size_of(type_of(list.instances.data.*)) * list.instances.count;

			return cmd, true;
		case .Sync_Scene;
			sync_scene := isa(cmd.payload, Command.Sync_Scene);
			if !sync_scene {
				print("Weirdge\n");
				return cmd, false;
			}

			sync_scene.terrain.data = (buffer.data + cursor).(*u8);
			cursor += size_of(type_of(sync_scene.terrain.data.*)) * sync_scene.terrain.count;
			sync_scene.players.data = (buffer.data + cursor).(*Command.Sync_Player);
			cursor += size_of(type_of(sync_scene.players.data.*)) * sync_scene.players.count;
			sync_scene.skulls.data = (buffer.data + cursor).(*Command.Sync_Skull);
			cursor += size_of(type_of(sync_scene.skulls.data.*)) * sync_scene.skulls.count;
			sync_scene.moving_frames.data = (buffer.data + cursor).(*Command.Sync_Moving_Frame);
			cursor +=
				size_of(type_of(sync_scene.moving_frames.data.*)) * sync_scene.moving_frames.count;
			sync_scene.robots.data = (buffer.data + cursor).(*Command.Sync_Robot);
			cursor += size_of(type_of(sync_scene.robots.data.*)) * sync_scene.robots.count;
			sync_scene.antiairs.data = (buffer.data + cursor).(*Command.Sync_AntiAir);
			cursor += size_of(type_of(sync_scene.antiairs.data.*)) * sync_scene.antiairs.count;
			sync_scene.tombstones.data = (buffer.data + cursor).(*Command.Sync_Tombstone);
			cursor += size_of(type_of(sync_scene.tombstones.data.*)) * sync_scene.tombstones.count;
			sync_scene.presents.data = (buffer.data + cursor).(*Command.Sync_Present);
			cursor += size_of(type_of(sync_scene.presents.data.*)) * sync_scene.presents.count;
			sync_scene.safe_zones.data = (buffer.data + cursor).(*Command.Sync_Safe_Zone);
			cursor += size_of(type_of(sync_scene.safe_zones.data.*)) * sync_scene.safe_zones.count;
			sync_scene.standins.data = (buffer.data + cursor).(*Command.Sync_Stand_In);
			cursor += size_of(type_of(sync_scene.standins.data.*)) * sync_scene.standins.count;

			return cmd, true;
	}
	return cmd, true;
}
