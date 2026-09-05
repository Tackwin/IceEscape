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
Big_Asset :: struct {
	id: int;
	buffer: [] u8;

	written := 0;
	last_written: Apollo_Time;

	kind: enum {
		Sending;
		Receiving;
	};
}

Asset_Info :: struct {
	id: int;
	size: int;
}

Thumbnail_Pending :: struct {
	terrain_id: int;
	asset_id: int;
}

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
		explode_source: V3f;
		explode_strength: float;
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
		chain_bomb: bool;
		cross_length: int;

		position: V3f;
		time: float;

		bomberman_bomb: bool;
		holdable: bool;
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
		target_aabb: AABBf;
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
		trigger_bombs: bool;
		delay: float;
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
			Already_In;
		}
	}

	Ask_Enter_Custom_Instance :: struct {
		terrain: string;
	}
	
	Ask_Enter_Quick_Instance :: struct {
		terrain_id: int;
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
		correlation_id: int;
		filter: string;
	}
	Ans_List_Terrain :: struct {
		correlation_id: int;
		terrains_id: [] int;
		terrains_name: [] string;
		authors_name: [] string;
		creation_time_ms: [] s64;
	}

	Create_Instance :: struct {
		name: [] u8;
		password: [] u8;
		auto_revive: bool;
		private: bool;

		roster: [] int;
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

	Create_Bomberman :: struct {
		name: [] u8;
		password: [] u8;
		private: bool;
		max_players: int;
	}
	Ans_Create_Bomberman :: struct {
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
	Get_Terrain_Leaderboard_Entry :: struct {
		username: string;
		time_ms: int;
		timestamp_ms: int;
	}
	Get_Terrain_Leaderboard :: struct {
		terrain_id: int;
		scene_name: string;

		wr_time_ms: int;
		wr_username: string;

		entries: [] Get_Terrain_Leaderboard_Entry;
	}
	Get_Instance_Tab_Stats_Player_Stats_Entry :: struct {
		player_id: int;
		death: int;
		revive: int;
		wins: int;
	}
	Get_Instance_Tab_Stats :: struct {
		wr_time_ms: int;
		wr_player_name: string;

		next_terrain_name: string;

		players_stats: [] Get_Instance_Tab_Stats_Player_Stats_Entry;
	}
	Signal_Pick :: struct {
		pos: V3f;
	}
	Set_Thumbnail :: struct {
		terrain_id: int;
		asset: Asset_Info;
	}
	Get_Thumbnail :: struct {
		terrain_id: int;
		asset: Asset_Info;

		reason: enum {
			Accepted;
			Not_Found;
			Rejected;
		}
	}
	Asset_Chunk :: struct {
		data: [] u8;
		offset: int;

		asset: Asset_Info;
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
		Get_Username, Get_Terrain_Leaderboard, Signal_Pick, Get_Instance_Tab_Stats,
		Ask_Enter_Quick_Instance, Set_Thumbnail, Get_Thumbnail, Asset_Chunk, Create_Bomberman,
		Ans_Create_Bomberman
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
	is_fixed_array :: #run -> bool {
		ti := type_info(T);
		if ti.type != .ARRAY return false;
		return ti.(*Type_Info_Array).array_type == .FIXED;
	};
	fixed_element_is_pod :: #run -> bool {
		ti := type_info(T);
		if ti.type != .ARRAY return false;
		el := ti.(*Type_Info_Array).element_type.type;
		return el == .INTEGER || el == .FLOAT || el == .BOOL || el == .ENUM;
	};
	fixed_array_count :: #run -> s64 {
		ti := type_info(T);
		if ti.type != .ARRAY return 0;
		return ti.(*Type_Info_Array).array_count;
	};
	if !payload {
		return 0;
	}
	if data.data == null {
		// Compute size needed to serialize

		#if info.type == .STRING {
			return payload.count + 8;
		} else #if info.type == .STRUCT {
			size := 0;

			#insert #run -> string {
				sb: String_Builder;
				for info.members {
					if it.offset_into_constant_storage >= 0
						continue;
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
			#if is_fixed_array {
				#if fixed_element_is_pod {
					return info.runtime_size;
				} else {
					size := 0;
					for 0..fixed_array_count - 1 {
						size += serialize_generic(payload.data + it, .[]);
					}
					return size;
				}
			} else {
				size := 8; // The count
				for 0..payload.count - 1 {
					size += serialize_generic(payload.data + it, .[]);
				}
				return size;
			}
		} else #if info.type == .INTEGER {
			return info.runtime_size;
		} else #if info.type == .FLOAT {
			return info.runtime_size;
		} else #if info.type == .BOOL {
			return info.runtime_size;
		} else #if info.type == .ENUM {
			return info.runtime_size;
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
	subdata :: (data: [] u8, cursor: int) -> [] u8 {
		out: [] u8;
		out.data = data.data + cursor;
		out.count = data.count - cursor;
		return out;
	}
	#if info.type == .STRING {
		memcpy(data.data + 0, *payload.count, 8);
		memcpy(data.data + 8, payload.data, payload.count);
		cursor += payload.count + 8;
	}
	#if info.type == .VARIANT {
		varT :: #run -> Type {
			return get_type(type_info(T).variant_of);
		};
		variant: *varT = xx payload;
		cursor += serialize_generic(variant, data);
	}
	#if info.type == .INTEGER {
		memcpy(data.data, payload, info.runtime_size);
		cursor += info.runtime_size;
	}
	#if info.type == .FLOAT {
		memcpy(data.data, payload, info.runtime_size);
		cursor += info.runtime_size;
	}
	#if info.type == .BOOL {
		memcpy(data.data, payload, info.runtime_size);
		cursor += info.runtime_size;
	}
	#if info.type == .ENUM {
		memcpy(data.data, payload, info.runtime_size);
		cursor += info.runtime_size;
	}
	#if info.type == .STRUCT {
		#insert #run -> string {
			sb: String_Builder;
			for info.members {
				if it.offset_into_constant_storage >= 0
					continue;
				print_to_builder(
					*sb,
					"cursor += serialize_generic(*payload.%, subdata(data, cursor));\n",
					it.name
				);
			}
			return builder_to_string(*sb);
		};
	}
	#if info.type == .ARRAY {
		#if is_fixed_array {
			#if fixed_element_is_pod {
				memcpy(data.data, payload, info.runtime_size);
				cursor += info.runtime_size;
			} else {
				for 0..fixed_array_count - 1 {
					sub := subdata(data, cursor);
					cursor += serialize_generic(payload.data + it, sub);
				}
			}
		} else {
			memcpy(data.data + cursor, *payload.count, 8);
			cursor += 8;
			element := info.element_type.type;
			if element == .INTEGER || element == .FLOAT || element == .BOOL || element == .ENUM {
				memcpy(
					data.data + cursor, payload.data, payload.count * info.element_type.runtime_size
				);
				cursor += payload.count * info.element_type.runtime_size;
			} else {
				for 0..payload.count - 1 {
					sub := subdata(data, cursor);
					cursor += serialize_generic(payload.data + it, sub);
				}
			}
		}
	}
	return cursor;
}

deserialize_generic :: (data: [] u8, out: *$T) -> int {
	info :: type_info(T);
	is_fixed_array :: #run -> bool {
		ti := type_info(T);
		if ti.type != .ARRAY return false;
		return ti.(*Type_Info_Array).array_type == .FIXED;
	};
	fixed_element_is_pod :: #run -> bool {
		ti := type_info(T);
		if ti.type != .ARRAY return false;
		el := ti.(*Type_Info_Array).element_type.type;
		return el == .INTEGER || el == .FLOAT || el == .BOOL || el == .ENUM;
	};
	fixed_array_count :: #run -> s64 {
		ti := type_info(T);
		if ti.type != .ARRAY return 0;
		return ti.(*Type_Info_Array).array_count;
	};
	cursor := 0;
	subdata :: (data: [] u8, cursor: int) -> [] u8 {
		out: [] u8;
		out.data = data.data + cursor;
		out.count = data.count - cursor;
		return out;
	}
	#if info.type == .STRING {
		out.count = data.data.(*s64).*;
		out.data  = data.data + 8;
		cursor += out.count + 8;
	}
	#if info.type == .INTEGER {
		memcpy(out, data.data, info.runtime_size);
		cursor += info.runtime_size;
	}
	#if info.type == .FLOAT {
		memcpy(out, data.data, info.runtime_size);
		cursor += info.runtime_size;
	}
	#if info.type == .BOOL {
		memcpy(out, data.data, info.runtime_size);
		cursor += info.runtime_size;
	}
	#if info.type == .ENUM {
		memcpy(out, data.data, info.runtime_size);
		cursor += info.runtime_size;
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
				if it.offset_into_constant_storage >= 0
					continue;
				print_to_builder(
					*sb,
					"sub_%1 := subdata(data, cursor);\ncursor += deserialize_generic(sub_%1, *out.%1);\n",
					it.name
				);
			}
			return builder_to_string(*sb);
		};
	}
	#if info.type == .ARRAY {
		#if is_fixed_array {
			#if fixed_element_is_pod {
				memcpy(out, data.data, info.runtime_size);
				cursor += info.runtime_size;
			} else {
				for 0..fixed_array_count - 1 {
					sub := subdata(data, cursor);
					cursor += deserialize_generic(sub, out.data + it);
				}
			}
		} else {
			memcpy(*out.count, data.data + cursor, 8);
			cursor += 8;
			out.data = talloc(out.count * info.element_type.runtime_size);
			element := info.element_type.type;
			if element == .INTEGER || element == .FLOAT || element == .BOOL || element == .ENUM {
				memcpy(out.data, data.data + cursor, out.count * info.element_type.runtime_size);
				cursor += out.count * info.element_type.runtime_size;
			} else {
				for 0..out.count - 1 {
					sub := subdata(data, cursor);
					cursor += deserialize_generic(sub, out.data + it);
				}
			}
		}
	}
	return cursor;
}

COMMAND_HEADER_SIZE :: 8 + 8 + size_of(Command.Payload_t.Kind);

serialize_payload :: (cmd: Command, data: [] u8) -> int {
	#insert #run -> string {
		sb: String_Builder;
		print(*sb, "if #complete cmd.payload.kind == {\n");
		for Command.Payload_t.All_Types {
			print(*sb, "    case .%;\n", it);
			print(*sb, "        typed := isa(cmd.payload, Command.%);\n", it);
			print(*sb, "        return serialize_generic(typed, data);\n");
		}
		print(*sb, "}\n");
		return builder_to_string(*sb);
	};
	return 0;
}

serialize :: (cmd: Command, buffer: *[..] u8) {
	extra := serialize_payload(cmd, .[]);
	total := COMMAND_HEADER_SIZE + extra;
	array_reserve(buffer, total);
	buffer.count = total;
	buffer.data.(*s64).* = total;
	memcpy(buffer.data + 8, *cmd.sent_timestamp, 8);
	memcpy(buffer.data + 16, *cmd.payload.kind, size_of(Command.Payload_t.Kind));
	subdata: [] u8;
	subdata.data = buffer.data + COMMAND_HEADER_SIZE;
	subdata.count = extra;
	serialize_payload(cmd, subdata);
}

deserialize :: (buffer: [] u8) -> Command, bool {
	if buffer.count < 8 {
		print("Buffer too small\n");
		return .{}, false;
	}

	expected_size := buffer.data.(*s64).*;
	if buffer.count < expected_size || expected_size < COMMAND_HEADER_SIZE {
		print("Buffer too small\n");
		return .{}, false;
	}

	cmd: Command;
	memcpy(*cmd.sent_timestamp, buffer.data + 8, 8);
	kind: Command.Payload_t.Kind;
	memcpy(*kind, buffer.data + 16, size_of(Command.Payload_t.Kind));

	remaining: [] u8;
	remaining.data = buffer.data + COMMAND_HEADER_SIZE;
	remaining.count = expected_size - COMMAND_HEADER_SIZE;

	#insert #run -> string {
		sb: String_Builder;
		print(*sb, "if #complete kind == {\n");
		for Command.Payload_t.All_Types {
			print(*sb, "    case .%;\n", it);
			print(*sb, "        set(*cmd.payload, Command.%.{});\n", it);
			print(*sb, "        typed := isa(cmd.payload, Command.%);\n", it);
			print(*sb, "        deserialize_generic(remaining, typed);\n");
		}
		print(*sb, "}\n");
		return builder_to_string(*sb);
	};

	return cmd, true;
}
