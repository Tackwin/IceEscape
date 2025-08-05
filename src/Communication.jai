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
	}

	payload: Sum_Type(Move, Spawn, New_Terrain, Sync_Player, Quit);
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
