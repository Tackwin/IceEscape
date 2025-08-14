#import "Scene";
#import "Basic";
#import "String";
#import "Algebra";
#import "Tagged_Union";

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
	Move :: struct {
		player_id: int;
		ground_target: V2f;
	}
	Spawn :: struct {
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
		t0: float64;
		t1: float64;
		t2: float64;
		t3: float64;
	}

	payload: Sum_Type(
		Move, Spawn, New_Terrain, Sync_Player, Sync_Skull, Sync_Moving_Frame,
		Quit, Die, Respawn, Spawn_Coin, Despawn_Coin, Sync_Key, Sync_Gate, NTP
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

		assert(found);
	}

	s.kind = #insert #run -> string { return sprint(".%;", T); };
	(cast(*T) *s.bytes).* = value;
}

make_command :: (cmd: $T) -> Command {
	made: Command;
	set(*made.payload, cmd);
	return made;
}
