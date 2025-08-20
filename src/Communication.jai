#import "Scene";
#import "Basic";
#import "String";
#import "Algebra";
#import "Math";
#import "Tagged_Union";

#scope_export
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
	}
	Move :: struct {
		player_id: int;
		ground_target: V2f;
	}
	Spawn :: struct {
		scene_id: int;
		player_id: int;
		its_you: bool;
	}
	Spawn_Coin :: struct {
		id: int;
		sender: int;
		position: V3f;
		direction: V3f;
	}
	Despawn_Coin :: struct {
		id: int;
	}
	Respawn :: struct {
		player_id := -1;
		spawn_position: V3f;
		spawn_direction: V3f;
		coin_id := -1;
	}
	Die :: struct {
		player_id: int;
		position: V3f;
	}
	Quit :: struct {
		player_id: int;
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
	}
	Sync_Skull :: struct {
		skull_id: int;
		t: float;
	}
	Sync_Key :: struct {
		key_id: int;
		position: V3f;
		holder: int;
	}
	Sync_Gate :: struct {
		gate_id: int;
		is_closed: bool;
	}
	Sync_Moving_Frame :: struct {
		frame_id: int;
		t: float;
	}
	NTP :: struct {
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
	}
	Sync_Scene :: struct {
		terrain: string;
		players: [] Sync_Player; // Would usually point to a temporary buffer.
		skulls: [] Sync_Skull;
		moving_frames: [] Sync_Moving_Frame;
	}

	payload: Sum_Type(
		Move, Spawn, New_Terrain, Sync_Player, Sync_Skull, Sync_Moving_Frame, Move_To_Play_World,
		Quit, Die, Respawn, Spawn_Coin, Despawn_Coin, Sync_Key, Sync_Gate, NTP, Sync_Scene, Connect
	);
	sent_timestamp: float64;
}

isa :: (s: Sum_Type, $T: Type) -> *T {
	if s.All_Types[s.kind] == T
		return cast(*T) *s.bytes;
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

serialize :: (cmd: Command, buffer: *[..] u8) {
	// Serialize the command into the buffer
	dry_size := size_of(type_of(cmd)) + 8;
	array_reserve(buffer, dry_size);
	memcpy(buffer.data + 8, *cmd, size_of(type_of(cmd)));
	buffer.count = dry_size;
	defer {
		buffer.data.(*s64).* = buffer.count;
	}

	for label: 0.. 0 if #complete cmd.payload.kind == {
		case .Move; #through;
		case .Spawn; #through;
		case .Connect; #through;
		case .Spawn_Coin; #through;
		case .Despawn_Coin; #through;
		case .Respawn; #through;
		case .Die; #through;
		case .Quit; #through;
		case .New_Terrain; #through;
		case .Sync_Player; #through;
		case .Sync_Skull; #through;
		case .Sync_Key; #through;
		case .Sync_Gate; #through;
		case .Sync_Moving_Frame; #through;
		case .NTP; #through;
		case .Move_To_Play_World;
			// Nothing
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

	if #complete cmd.payload.kind == {
		case .Move; #through;
		case .Spawn; #through;
		case .Connect; #through;
		case .Spawn_Coin; #through;
		case .Despawn_Coin; #through;
		case .Respawn; #through;
		case .Die; #through;
		case .Quit; #through;
		case .New_Terrain; #through;
		case .Sync_Player; #through;
		case .Sync_Skull; #through;
		case .Sync_Key; #through;
		case .Sync_Gate; #through;
		case .Sync_Moving_Frame; #through;
		case .NTP; #through;
		case .Move_To_Play_World;
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
			return cmd, true;
	}
	return cmd, true;
}
