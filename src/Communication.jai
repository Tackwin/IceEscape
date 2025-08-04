#import "Scene";
#import "Basic";
#import "String";
#import "Algebra";
#import "Tagged_Union";

Command :: struct {
	Move :: struct {
		player_id: int;
		ground_target: V2f;
	}
	Spawn :: struct {
		player_id: int;
		its_you: bool;
	}
	New_Terrain :: struct {
		ascii: [] u8;
	}

	payload: Tagged_Union(Move, Spawn);
}

make_command :: (cmd: Command.Move) -> Command {
	made: Command;
	set(*made.payload, cmd);
	return made;
}