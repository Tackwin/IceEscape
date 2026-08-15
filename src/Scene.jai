#import "Algebra";
#import "Math";
#import "Basic";
#import "String";
#import "Tagged_Union";
#import "Communication";
#import "Pool";
#import "Xar";
#import "Common";
#import "Hash_Table";
#import "Terrain";
#import "Store";
Platform :: #import "Platform";
Controls :: #import "Controls";
Rand :: #import "Rand";
GUI :: #import "GUI";
XPBD :: #import "XPBD";

#scope_export

OPEN_GATE_SCORE :: 5;
ACTIVATE_FLAG_SCORE :: 4;
PICKUP_KEY_SCORE :: 3;

Breaking_News :: struct {
	text: string;
	time: Apollo_Time;
}

Model_Id :: enum {
	Racer :: 1;
	SUV :: 2;
	Speedster :: 3;
	Drag_Racer :: 4;
	Monster_Truck :: 5;
	Vintage_Racer :: 6;
	Boat_Row :: 7;
	Boat_Fishing :: 8;
	Taxi :: 9;
	Police :: 10;
	Ambulance :: 11;
	Spaceship :: 12;
	Tombstone :: 13;
	Tile :: 14;
	Skull :: 15;
	Coin :: 16;
	Key :: 17;
	Mark :: 18;
	Gate :: 19;
	Gate_Close :: 20;
	Shuriken :: 21;
	Spirit :: 22;
	Boat_Sail :: 23;
	Tractor :: 24;
}
Model_Id_Count :: #run enum_highest_value(Model_Id) + 1;

Sound_Trigger :: struct {
	inhead := false;
	position: V3f;
	kind: enum {
		Footstep_Snow :: 0;
		Footstep_Ice :: 1;
		Car_Klaxon :: 2;
		Explosion :: 3;
		Loser :: 4;
		Checkpoint_Ok :: 5;
		Res :: 6;
		Coin_Launch :: 7;
		Point_Up :: 8;
		Note :: 9;
	};

	count := 1;
	pitch := 0.0;
}

Scene_Parameters :: struct {
	auto_revive := false;
}

Scene_Info :: struct {
	id: int;
	name: [128] u8;
	author_profile_id: int = -1;
}

ISpan :: struct(T: Type) {
	count: s64;
	index: s64;
}

ISpan_Iterator :: struct(T: Type) {
	span: ISpan(T);
	array: [] T;
}

iterator :: (span: ISpan($T), array: [] T) -> ISpan_Iterator(T) {
	return .{ span, array };
}

for_expansion :: (iterator: ISpan_Iterator, body: Code, flags: For_Flags) #expand {
	assert(flags == xx 0);
	end := min(iterator.span.count + iterator.span.index, iterator.array.count);
	for index: iterator.span.index..end - 1 {
		`it := iterator.array[index];
		`it_index := index.(s64) - iterator.span.index;
		#insert body;
	}
}

get :: (span: ISpan($T), array: [] T, index: s64) -> *T {
	if index >= span.count
		return null;
	if span.index + index > xx array.count
		return null;

	return *array[span.index + index];
}

Entity :: struct {
	id: int;
	position: V3f;
}

Debris :: struct {
	model_id: int;
	part_idx: int;

	origin: V3f;
	half_size: V3f;

	position: V3f;
	velocity: V3f;
	w: V3f;
	q: Qf;

	birthtime: float;
}

Gravestone :: struct {
	player_id: int;
	position: V3f;
}

Scene :: struct {
	State :: enum {
		Normal :: 0;
		Wipe_Fade_In :: 1;
		Wipe_Fade_Out :: 2;
	}
	state: State;

	info: Scene_Info;
	params: Scene_Parameters;

	server: struct {
		clock: float64 = 0.0;
		clock_sync_cd := 0.0;
	}
	client: struct {
		store: *Store;

		clock: float64 = 0.0;
		end_level: Command.End_Level;
		render_particles := false;

		leaderboard: Command.Get_Terrain_Leaderboard;
		leaderboard_run_counter := 0;
	}

	id := 1;
	next_id := -1;

	is_server := false;
	camera: Camera;
	controlled_player_id := 0;

	night := false; @edit

	// >TODO put all allocation relating to the map in the same pool.
	players: [..] Player; @allocate("lifetime")
	checkpoints: [..] Checkpoint; @allocate("lifetime") @clear("run")
	tombstones: [..] Tombstone; @allocate("lifetime") @clear("run")
	skulls: [..] Skull; @allocate("lifetime") @clear("run")
	coins: [..] Coin; @allocate("lifetime") @clear("run")
	paths: [..] Path; @allocate("lifetime") @clear("run")
	keys: [..] Key; @allocate("lifetime") @clear("run")
	gates: [..] Gate; @allocate("lifetime") @clear("run")
	moving_frames: [..] Moving_Frame; @allocate("lifetime") @clear("run")
	moving_frame_keys: [..] Moving_Frame.Key; @allocate("lifetime") @clear("run")
	shurikens: [..] Shuriken; @allocate("lifetime") @clear("run")
	camera_rails: [..] Camera_Rail; @allocate("lifetime") @clear("run")
	camera_rail_waypoints: [..] V3f; @allocate("lifetime") @clear("run")
	camera_pois: [..] Camera_POI; @allocate("lifetime") @clear("run")
	stand_in: [..] Stand_In; @allocate("lifetime") @clear("run")
	trigger_zones: [..] Trigger_Zone; @allocate("lifetime") @clear("run")
	within_zones: [..] Within_Zone; @allocate("lifetime") @clear("run")
	lanterns: [..] Lantern; @allocate("lifetime") @clear("run")
	flags: [..] Flag; @allocate("lifetime") @clear("run")
	props: [..] Prop; @allocate("lifetime") @clear("run")
	bombs: [..] Bomb; @allocate("lifetime") @clear("run");
	bomb_spawners: [..] Bomb_Spawner; @allocate("lifetime") @clear("run");
	particles: [..] Particle; @allocate("lifetime") @clear("run")
	trophies: [..] Trophy; @allocate("lifetime") @clear("run")
	robots: [..] Robot; @allocate("lifetime") @clear("run")
	explosions: [..] Explosion; @allocate("lifetime") @clear("run")
	antiairs: [..] AntiAir; @allocate("lifetime") @clear("run")
	traps: [..] Trap; @allocate("lifetime") @clear("run")
	presents: [..] Present; @allocate("lifetime") @clear("run")
	safe_zones: [..] Safe_Zone; @allocate("lifetime") @clear("run")
	hooks: [..] Hook; @allocate("lifetime") @clear("run")
	turn_tables: [..] Turn_Table; @allocate("lifetime") @clear("run")
	pressbuttons: [..] PressButton; @allocate("lifetime") @clear("run")
	block_rocks: [..] Block_Rock; @allocate("lifetime") @clear("run")
	news: [..] string; @allocate("lifetime") @clear("run")
	sound_triggers: [..] Sound_Trigger; @allocate("lifetime") @clear("run")
	jukeboxes: [..] Jukebox; @allocate("lifetime") @clear("run")
	debris: [..] Debris; @allocate("lifetime") @clear("run")
	gravestones: [..] Gravestone; @allocate("lifetime") @clear("run")
	indices: [..] int; @allocate("lifetime") @clear("run")
	trigger_activated: Table(int, bool); @allocate("lifetime") @clear("run")

	client_to_server: [..] Command; @allocate("lifetime")

	terrain: Terrain;
	spawn: Spawn;

	camera_min: V2f;
	camera_max: V2f;
	origin_tile_space: V2f;

	coin_generation := 0;
	generation := 0;

	mark_clicked_time: Apollo_Time;
	mark_clicked_pos: V3f;

	fade_in_screen_t := 0.0;

	Fade_Screen :: struct {
		color: V3f;
		start: Apollo_Time;
		period := 1.0;
	}

	fade_screen: Fade_Screen;
	fading := false;


	succeed := false;
	end_scene_countdown_time: Apollo_Time;
	end_scene_countdown := 30.0;
	end_scene_countdown_started := false;

	client_rng: Rand.State;
	server_rng: Rand.State;

	auto_revive := false;
	camera_locked := true;

	Pick :: struct {
		pos: V3f;
		birthtime: float;
		lifetime :: 0.25;
	}
	signal_picks: [..] Pick; @allocate("lifetime") @clear("run")

	lifetime_pool: Pool;
	frame_pool: Pool;
	run_pool: Pool; @clear("run")
	run_generation := 0; @increment("run")
}

clear_string :: (info: Type_Info_Struct) -> string {
	sb: String_Builder;

	categories: Table(string, [..] string);
	increments: Table(string, [..] string);
	for member: info.members {
		clears: [..] string;
		clears.allocator = temp;

		for note: member.notes {
			clear: string;
			increment: string;
			if scan2(note, "clear(%)", *clear) {
				array_add(*clears, clear);
			}
			if scan2(note, "increment(%)", *increment) {
				fields := table_find_pointer(*increments, increment);
				if !fields {
					empty: [..] string;
					empty.allocator = temp;
					fields = table_add(*increments, increment, empty);
				}
				array_add(fields, member.name);
			}
		}

		for clear: clears {
			fields := table_find_pointer(*categories, clear);
			if !fields {
				empty: [..] string;
				empty.allocator = temp;
				fields = table_add(*categories, clear, empty);
			}
			array_add(fields, member.name);
		}
	}

	snake_case_type := to_lower_copy(info.name,, temp);
	for fields, clear: categories {
		increment := table_find_pointer(*increments, clear);

		print_to_builder(*sb, "clear_%_% :: (object: *%) {\n", snake_case_type, clear, info.name);

		for field: fields {
			print_to_builder(*sb, "\treset(*object.%);\n", field);
		}

		if increment {
			for field: increment.* {
				print_to_builder(*sb, "\tobject.% += 1;\n", field);
			}
		}

		print_to_builder(*sb, "}\n");
	}

	str := builder_to_string(*sb);
	return str;
}
#insert -> string {
	str := clear_string(type_info(Scene));
	// print("clear string: %\n", str);
	return str;
}

clear_scene :: (scene: *Scene) {
	clear_scene_run(scene);
	scene.night = false;
	scene.players.count = 0;
	scene.camera_min.x = 0.0;
	scene.camera_min.y = 0.0;
	scene.camera_max.x = 0.0;
	scene.camera_max.y = 0.0;
}

rellocate_string :: (value_info: Type_Info_Struct, parent_info: Type_Info_Struct) -> string {
	sb: String_Builder;
	snake_case_type := to_lower_copy(value_info.name,, temp);
	print_to_builder(
		*sb,
		"rellocate_% :: (value_name: *%, parent_name: *%, copy_from : *% = null) {\n",
		snake_case_type,
		value_info.name,
		parent_info.name,
		value_info.name
	);
	for member: value_info.members {
		if member.type.type == .ARRAY && (*member).(*Type_Info_Array).array_type == .RESIZABLE {
			pool: string;
			pool_parent: string;
			for note: member.notes {
				if scan2(note, "allocate(%)", *pool) {
					break;
				}
				if scan2(note, "allocate(parent, %)", *pool_parent) {
					break;
				}
			}

			
			print_to_builder(*sb, "\tif copy_from {\n");
			print_to_builder(*sb, "\t\tvalue_name.%.data = 0;\n", member.name);
			print_to_builder(*sb, "\t\tvalue_name.%.count = 0;\n", member.name);
			print_to_builder(*sb, "\t\tvalue_name.%.allocated = 0;\n", member.name);
			print_to_builder(*sb, "\t\tarray_copy(*value_name.%1, copy_from.%1);\n", member.name);
			print_to_builder(*sb, "\t}\n");

			if pool.count > 0 {
				if pool_parent.count > 0
					print(
						"Warning ! %.% has a allocate AND a allocate(parent, )\n",
						value_info.name,
						member.name
					);
				print_to_builder(
					*sb, "\tvalue_name.%.allocator.data = *value_name.%_pool;\n", member.name, pool
				);
				print_to_builder(
					*sb, "\tvalue_name.%.allocator.proc = pool_allocator_proc;\n", member.name
				);
			}
			else if pool_parent.count > 0 {
				print_to_builder(
					*sb,
					"\tvalue_name.%.allocator.data = *parent_name.%_pool;\n",
					member.name,
					pool_parent
				);
				print_to_builder(
					*sb, "\tvalue_name.%.allocator.proc = pool_allocator_proc;\n", member.name
				);
			}
		}
	}
	print_to_builder(*sb, "}\n");

	str := builder_to_string(*sb);
	return str;
}
Void :: struct {
}
#insert -> string {
	str := rellocate_string(type_info(Scene), type_info(Void));
	return str;
}
make :: (scene: *Scene) {
	reload(scene);
}
reload :: (scene: *Scene) {
	scene.lifetime_pool.block_allocator = context.allocator;
	scene.frame_pool.block_allocator = context.allocator;
	scene.run_pool.block_allocator = context.allocator;
	rellocate_scene(scene, null);
}

copy :: (dst: *Scene, src: Scene) {
	aux := dst.*;
	memcpy(dst, *src, size_of(Scene)); // For the static data.

	dst.lifetime_pool = aux.lifetime_pool;
	dst.frame_pool = aux.frame_pool;
	dst.run_pool = aux.run_pool;

	rellocate_scene(scene, null, *src);
}

reset :: (arr: *[..] $T) {
	arr.count = 0;
}
reset :: (x: *Pool) {
	release(x);
}
reset :: (table: *Table) {
	table.count = 0;
}
reset :: (x: *bool) {
	x.* = false;
}

free :: (scene: *Scene) {
	release(*scene.lifetime_pool);
	release(*scene.frame_pool);
	release(*scene.run_pool);
}


make_sync :: (scene: *Scene, params: Scene_Parameters) -> Command.Sync_Scene {
	sync_scene: Command.Sync_Scene;
	sync_scene.id = scene.id;
	sync_scene.info = scene.info;
	sync_scene.clock = scene.server.clock;
	sync_scene.params = params;
	sync_scene.terrain = scene.terrain.text;
	sync_scene.players = NewArray(scene.players.count, Command.Sync_Player, false,, temp);
	sync_scene.skulls = NewArray(scene.skulls.count, Command.Sync_Skull, false,, temp);
	sync_scene.moving_frames = NewArray(scene.moving_frames.count, Command.Sync_Moving_Frame, false,, temp);
	sync_scene.robots = NewArray(scene.robots.count, Command.Sync_Robot, false,, temp);
	sync_scene.antiairs = NewArray(scene.antiairs.count, Command.Sync_AntiAir, false,, temp);
	sync_scene.tombstones = NewArray(scene.tombstones.count, Command.Sync_Tombstone, false,, temp);
	sync_scene.presents = NewArray(scene.presents.count, Command.Sync_Present, false,, temp);
	sync_scene.safe_zones = NewArray(scene.safe_zones.count, Command.Sync_Safe_Zone, false,, temp);
	sync_scene.standins = NewArray(scene.stand_in.count, Command.Sync_Stand_In, false,, temp);
	for * sync_scene.players {
		it.* = make_sync(*scene.players[it_index]);
	}
	for * sync_scene.skulls {
		it.* = make_sync(*scene.skulls[it_index]);
	}
	for * sync_scene.moving_frames {
		it.* = make_sync(*scene.moving_frames[it_index]);
	}
	for * sync_scene.robots {
		it.* = make_sync(*scene.robots[it_index]);
	}
	for * sync_scene.antiairs {
		it.* = make_sync(*scene.antiairs[it_index]);
	}
	for * sync_scene.tombstones {
		it.* = make_sync(*scene.tombstones[it_index]);
	}
	for * sync_scene.presents {
		if scene.presents[it_index].server.available
			it.* = make_sync(*scene.presents[it_index]);
	}
	for * sync_scene.safe_zones {
		it.* = make_sync(*scene.safe_zones[it_index]);
	}
	for * sync_scene.standins {
		it.* = make_sync(*scene.stand_in[it_index]);
	}
	sync_scene.rng = scene.server_rng;
	return sync_scene;
}

make_sync :: (player: *Player) -> Command.Sync_Player {
	sync_player: Command.Sync_Player;
	sync_player.player_id = player.id;
	sync_player.position = player.server.position;
	sync_player.direction = player.server.direction;
	sync_player.dead = player.server.dead;
	sync_player.model_id = player.server.model_id;
	sync_player.has_safe_present = player.server.has_safe_present;
	sync_player.has_hook_present = player.server.has_hook_present;
	return sync_player;
}

make_sync :: (standin: *Stand_In) -> Command.Sync_Stand_In {
	sync_standin: Command.Sync_Stand_In;
	sync_standin.standin_id = standin.id;
	sync_standin.retired = standin.retired;
	return sync_standin;
}

make_sync :: (bomb: *Bomb) -> Command.Sync_Bomb {
	sync: Command.Sync_Bomb;
	sync.bomb_id = bomb.id;
	sync.bomb_spawner_id = bomb.spawner_id;
	sync.holder_id = bomb.holder;
	sync.last_holder_id = bomb.last_holder;
	sync.position = bomb.server.position;
	sync.time = bomb.server.time;
	return sync;
}

make_sync :: (spawner: *Bomb_Spawner) -> Command.Sync_Bomb_Spawner {
	sync: Command.Sync_Bomb_Spawner;
	sync.bomb_spawner_id = spawner.id;
	sync.bomb_spawned_id = spawner.spawned_id;
	return sync;
}

make_sync :: (skull: *Skull) -> Command.Sync_Skull {
	sync_skull: Command.Sync_Skull;
	sync_skull.skull_id = skull.id;
	sync_skull.speed = skull.server.speed;
	sync_skull.offset = skull.server.offset;
	return sync_skull;
}

make_sync :: (hook: *Hook) -> Command.Sync_Hook {
	sync_hook: Command.Sync_Hook;
	sync_hook.hook_id = hook.id;
	sync_hook.last_anchor_position = hook.server.last_anchor_position;
	sync_hook.direction = hook.server.direction;
	sync_hook.length = hook.server.length;
	sync_hook.hooker_id = hook.hooker_id;
	sync_hook.hooked_id = hook.hooked_id;
	return sync_hook;
}

make_sync :: (tombstone: *Tombstone) -> Command.Sync_Tombstone {
	sync_tombstone: Command.Sync_Tombstone;
	sync_tombstone.player_id = tombstone.player_id;
	sync_tombstone.position = tombstone.position;
	return sync_tombstone;
}

make_sync :: (moving_frame: *Moving_Frame) -> Command.Sync_Moving_Frame {
	sync_moving_frame: Command.Sync_Moving_Frame;
	sync_moving_frame.frame_id = moving_frame.id;
	return sync_moving_frame;
}

make_sync :: (robot: *Robot) -> Command.Sync_Robot {
	sync_robot: Command.Sync_Robot;
	sync_robot.robot_id = robot.id;
	sync_robot.position = robot.position;
	sync_robot.shooting_time = robot.shooting_time;
	sync_robot.shooting_cd = robot.shooting_cd;
	return sync_robot;
}

make_sync :: (antiair: *AntiAir) -> Command.Sync_AntiAir {
	sync_antiair: Command.Sync_AntiAir;
	sync_antiair.id = antiair.id;
	sync_antiair.position = antiair.position;
	sync_antiair.target_aabb = antiair.target_aabb;
	sync_antiair.cooldown = antiair.cooldown;
	sync_antiair.next_target = antiair.server.next_target;
	sync_antiair.t = antiair.server.t;
	return sync_antiair;
}

make_sync :: (present: *Present) -> Command.Sync_Present {
	sync_present: Command.Sync_Present;
	sync_present.present_id = present.id;
	sync_present.position = present.position;
	sync_present.kind = xx present.kind;
	sync_present.available = present.server.available;
	return sync_present;
}

make_sync :: (safe_zone: *Safe_Zone) -> Command.Sync_Safe_Zone {
	sync_safe_zone: Command.Sync_Safe_Zone;
	sync_safe_zone.id = safe_zone.id;
	sync_safe_zone.position = safe_zone.position;
	sync_safe_zone.radius = safe_zone.radius;
	sync_safe_zone.expire = safe_zone.expire;
	return sync_safe_zone;
}

Frame_Result :: struct {
	broadcast: [..] Command; @allocate("lifetime") @clear("frame")
	win_player_id: [..] int; @allocate("lifetime") @clear("frame")
	died_player_id: [..] int; @allocate("lifetime") @clear("frame")
	revived_someone_player_id: [..] int; @allocate("lifetime") @clear("frame")

	to_server: [..] Command; @allocate("lifetime") @clear("frame")
	died: [..] Command.Die; @clear("frame")
	respawn: [..] Command.Respawn; @clear("frame")
	sync_gate: [..] Command.Sync_Gate; @clear("frame")
	move_to_player_world: [..] Command.Move_To_Play_World; @clear("frame")
	wipe_scene: [..] Command.Wipe_Scene; @clear("frame")
	end_level: [..] Command.End_Level; @clear("frame")
	explode: [..] Command.Explode; @clear("frame")
	antiair_shoot: [..] Command.AntiAir_Shoot; @clear("frame")
	spawn_coin: [..] Command.Spawn_Coin; @clear("frame")
	move: [..] Command.Move; @clear("frame")
	sync_present: [..] Command.Sync_Present; @clear("frame")
	sync_safe_zone: [..] Command.Sync_Safe_Zone; @clear("frame")
	sync_player: [..] Command.Sync_Player; @clear("frame")
	restarted := false; @clear("frame")

	lifetime_pool: Pool;

	made := false;
}

#insert -> string {
	str := clear_string(type_info(Frame_Result));
	// print("clear string: %\n", str);
	return str;
}

#insert -> string { return rellocate_string(type_info(Frame_Result), type_info(Void)); };
make :: (result: *Frame_Result) {
	set_allocators(*result.lifetime_pool);
	rellocate_frame_result(result, null);
	result.made = true;
}

free :: (frame_result: *Frame_Result) {
	array_free(frame_result.died);
	array_free(frame_result.respawn);
	array_free(frame_result.sync_gate);
	array_free(frame_result.move_to_player_world);
	array_free(frame_result.wipe_scene);
	array_free(frame_result.end_level);
	array_free(frame_result.explode);
	array_free(frame_result.antiair_shoot);
	array_free(frame_result.spawn_coin);
	array_free(frame_result.move);
	array_free(frame_result.add_scores);
	array_free(frame_result.sync_present);
	array_free(frame_result.sync_safe_zone);
	array_free(frame_result.sync_player);
	release(*frame_result.lifetime);
}

Safe_Zone :: struct {
	id: int;
	position: V3f;
	radius: float;
	expire: int;

	server: struct {
		expire_started := false;
		expire_start: Apollo_Time;
		expire_duration: float;
	}

	client: struct {
		time := 0.0;
	}
}

Spawn :: struct {
	position: V3f;
	size: V2f;
}

AntiAir :: struct {
	id: int;
	position: V3f; @edit @picking
	target_aabb: AABBf; @edit @picking
	cooldown: float = 2.0; @edit
	radius := 1.0; @edit
	just_shooted := false;

	server: struct {
		t := 0.0;
		next_target: V2f = .{ FLOAT32_MAX, FLOAT32_MAX };
		curr_target: V2f = .{ FLOAT32_MAX, FLOAT32_MAX };
	}
	client: struct {
		t := 0.0;
		next_target: V2f = .{ FLOAT32_MAX, FLOAT32_MAX };
	}
}

Bomb_Spawner :: struct {
	id: int;

	position: V3f; @edit @picking

	spawned_id := -1;
	explosion_time := 10.0; @edit
	explosion_radius := 0.5; @edit
}

Bomb :: struct {
	id: int;

	spawner_id: int = -1;
	holder: int = -1;
	last_holder: int = -1;

	server: struct {
		position: V3f;
		radius_hitbox := 0.25;
		time := 0.0;
		lifetime := 0.0;

		dropped_clock := 0.0;

		explosion_time := 10.0;
		explosion_radius := 0.5;
	}

	client: struct {
		position: V3f;
		time := 0.0;
		lifetime := 0.0;
	}
}

Block_Rock :: struct {
	EDIT_PICK_RADIUS :: 0.5;

	id: int;
	exploded := false;
	position: V3f; @edit @picking
}

PressButton :: struct {
	id: int;
	position: V3f; @edit @picking

	is_radio := false; @edit
	
	count_changed_juice_t := 0.0;
	activated_juice_t := 0.0;

	index := 0; @edit
	activated := false;

	n_present := 0;

	last_player_count := 0;
}

Turn_Table :: struct {
	id: int;

	position: V3f; @edit @picking
	turning_speed := 1.0; @edit
	turning_offset := 0.0; @edit

	Mark :: struct {
		player_id: int;
		clock: float64;
	}
}
#insert -> string { return rellocate_string(type_info(Turn_Table), type_info(Scene)); };

Trap :: struct {
	id: int;
	position: V3f; @edit @picking
	radius_hitbox := 0.5;

	activable := false; @edit
	stay_activated_time := 1.0; @edit

	activated := false;
	activated_clock := 0.0;
	activator_id := -1;
} @editable

Present :: struct {
	id: int;
	position: V3f; @edit @picking

	Kind :: enum {
		A :: 0;
		B :: 1;
	};
	kind: Kind; @edit

	server: struct {
		refresh_cooldown: float = 10.0; @edit
		time_since_taken := 0.0;
		available := false;
		depends_on_flag_id := -1; @edit
	};
}

Jukebox :: struct {
	id: int;
	last_coin_clock := 0.0;
	position: V3f;
	coin_count := 0;
}

Prop :: struct {
	id: int;
	M: M4f;
}

Trophy :: struct {
	id: int;
	position: V3f; @edit @picking
}

Particle :: struct {
	position: V3f;
	velocity: V3f;
	gravity: float = 1.0;
	drag: float = 0.0;
	color: V4f = V4f.{ 1, 1, 1, 1 };
	texture_rec: V4f = V4f.{ 0, 0, 0, 0 };
	size: float = 0.2;
	lifetime: float = 1.0;
	age: float = 0.0;
	rotation: float = 0.0;
	rotation_speed: float = 0.0;
	fade_out_time: float = 0.0;
	floor_bounce := 0.4;
}

Explosion :: struct {
	position: V3f;
	age: float = 0.0;
	lifetime: float = 1.0;
	max_size: float = 1.0;
}

Robot :: struct {
	id: int;

	position: V3f; @edit @picking
	target_aabb: AABBf; @edit @picking

	axes: [5] float;

	player_targeted_id := -1;

	max_rotation_speed := 3.141592 * 0.5; @edit // radians per second

	charging_time := 1.0; @edit
	effectshoot_time := 0.5; @edit
	shooting_cd := 5.0; @edit
	shooting_time := 0.0;
	shooting_offset := 0.0; @edit
	explosion_radius := 0.4; @edit

	predict := 0.0; @edit

	shooted := false;
	just_shooted := false;
}

robot_matrix_local :: (n: int, a: float) -> M4f {
	if n == 0
		return M4f.identity();
	if n == 1
	|| n == 3
	|| n == 5
		return to_rotation_matrix(axis_angle(V3f.{ 1, 0, 0 }, a));
	if n == 2
	|| n == 4
		return to_rotation_matrix(axis_angle(V3f.{ 0, 0, 1 }, a));
	return M4f.identity();
}

robot_matrix_local_to_joint :: (robot: Robot, n: int) -> M4f {
	if n == 0 {
		return M4f.translate(robot.position);
	}

	if n == 1 {
		M := robot_matrix_local_to_joint(robot, 0);
		M = M * robot_matrix_to_next(n, robot.axes[0]);
		return M;
	}

	if n == 2 {
		M := robot_matrix_local_to_joint(robot, 1);
		M = M * robot_matrix_to_next(n, robot.axes[1]);
		return M;
	}

	if n == 3 {
		M := robot_matrix_local_to_joint(robot, 2);
		M = M * robot_matrix_to_next(n, robot.axes[2]);
		return M;
	}

	if n == 4 {
		M := robot_matrix_local_to_joint(robot, 3);
		M = M * robot_matrix_to_next(n, robot.axes[3]);
		return M;
	}

	if n == 5 {
		M := robot_matrix_local_to_joint(robot, 4);
		M = M * robot_matrix_to_next(n, robot.axes[4]);
		return M;
	}

	if n == 6 {
		M := robot_matrix_local_to_joint(robot, 5);
		M = M * M4f.translate(V3f.{ 0, 0, 0.55 * 0.7 });
		return M;
	}

	return M4f.identity();
}

robot_pivot :: (robot: Robot, n: int) -> V3f {
	return v3(robot_matrix_local_to_joint(robot, n) * V4f.{ 0, 0, 0, 1 });
	// if n == 0 {
	// 	return robot.position;
	// }

	// if n == 1 {
	// 	parent := robot_pivot(robot, 0);
	// 	return parent + V3f.{ 0, 0, 0.55 * 0.7 };
	// }

	// if n == 2 {
	// 	parent := robot_pivot(robot, 1);
	// 	parent += v3(robot_matrix_local(1, robot.axes[0]) * V4f.{ 0, 0, 0.55 * 0.7, 1 });
	// 	return parent;
	// }

	// if n == 3 {
	// 	parent := robot_pivot(robot, 2);
	// 	parent += v3(robot_matrix_local(2, robot.axes[1]) * V4f.{ 0, 0, 0.35 * 0.7, 1 });
	// 	return parent;
	// }

	// if n == 4 {
	// 	parent := robot_pivot(robot, 3);
	// 	parent += v3(robot_matrix_local(3, robot.axes[2]) * V4f.{ 0, 0, 0.55 * 0.7, 1 });
	// 	return parent;
	// }

	// if n == 5 {
	// 	parent := robot_pivot(robot, 4);
	// 	parent += v3(robot_matrix_local(4, robot.axes[3]) * V4f.{ 0, 0, 0.35 * 0.7, 1 });
	// 	return parent;
	// }

	// if n == 6 {
	// 	parent := robot_pivot(robot, 5);
	// 	parent += v3(robot_matrix_local(5, robot.axes[4]) * V4f.{ 0, 0, 0.2 * 0.7, 1 });
	// 	return parent;
	// }

	// return robot.position;
}

robot_joint_axis :: (n: int) -> V3f {
	if n == 0
		return V3f.{ 0, 0, 1 };
	if n == 1
	|| n == 3
	|| n == 5
		return V3f.{ 1, 0, 0 };
	if n == 2
	|| n == 4
		return V3f.{ 0, 0, 1 };
	return V3f.{ 0, 0, 1 };
}

robot_matrix_to_next :: (n: int, a: float) -> M4f {
	if n == 0 {
		return M4f.translate(V3f.{ 0, 0, 0.0 });
	}
	if n == 1 {
		return M4f.translate(V3f.{ 0, 0, 0.55 * 0.7 }) * robot_matrix_local(n, a);
	}
	if n == 2 {
		return M4f.translate(V3f.{ 0, 0, 0.55 * 0.7 }) * robot_matrix_local(n, a);
	}
	if n == 3 {
		return M4f.translate(V3f.{ 0, 0, 0.35 * 0.7 }) * robot_matrix_local(n, a);
	}
	if n == 4 {
		return M4f.translate(V3f.{ 0, 0, 0.55 * 0.7 }) * robot_matrix_local(n, a);
	}
	if n == 5 {
		return M4f.translate(V3f.{ 0, 0, 0.35 * 0.7 }) * robot_matrix_local(n, a);
	}

	return M4f.identity();
}

robot_to_axis :: (robot: Robot, n: int) -> M4f {
	M : M4f = M4f.translate(robot.position);
	M = M * robot_matrix_to_next(0, robot.axes[0]);
	for 1..n {
		M = M * robot_matrix_to_next(it, robot.axes[it - 1]);
	}
	return M;
}

robot_forward :: (robot: Robot) -> M4f {
	M : M4f = M4f.translate(robot.position);
	M = M * robot_matrix_local(0, robot.axes[0]);
	for 1..5 {
		M = M * robot_matrix_to_next(it, robot.axes[it - 1]);
	}
	return M;
}

Process_Response :: struct {
	Entry :: struct {
		scene_id: int;
		player_id: int;
		command: Command;
	}

	entries: [..] Entry;
	audios: [..] Platform.Audio;
}
free :: (process_response: *Process_Response) {
	array_free(process_response.entries);
	array_free(process_response.audios);
}
clear :: (response: *Process_Response) {
	response.entries.count = 0;
	response.audios.count = 0;
}
add :: (process_response: *Process_Response, scene_id: int, command: $T) {
	entry: Process_Response.Entry;
	entry.scene_id = scene_id;
	entry.player_id = -1;
	entry.command = make_command(command);
	array_add(*process_response.entries, entry);
}
add_single_reply :: (process_response: *Process_Response, player_id: int, command: $T) {
	entry: Process_Response.Entry;
	entry.scene_id = -1;
	entry.player_id = player_id;
	entry.command = make_command(command);
	array_add(*process_response.entries, entry);
}

Camera :: struct {
	position: V3f;
	target:   V3f;
	delta_unit: V3f;

	target_target: V3f;
	distance_target := 0.0;

	nominal_distance := 8.0;
	locked_nominal_distance := 8.0;

	max_distance := 0.0;

	locked_to := -1;
	locked := false;

	fov  := 65.0;
	near := 0.1;
	far  := 1000.0;
	aspect := 1280/720.0;

	speed := 25;
}

init_camera :: (scene: *Scene) {
	scene.camera.position = .{ 0, -4, 8 };
	scene.camera.target = .{ 0, 0, 0 };
	scene.camera.target_target = scene.camera.target;
	scene.camera.delta_unit = normalize(scene.camera.position - scene.camera.target);
	scene.camera.nominal_distance = norm(scene.camera.position - scene.camera.target);
	scene.camera.distance_target = scene.camera.nominal_distance;
	scene.camera.locked_nominal_distance = scene.camera.nominal_distance * 1.05;
	scene.camera.fov = 55;
	scene.camera.max_distance = scene.camera.locked_nominal_distance;
}

reset_camera_zoom :: (camera: *Camera) {
	pos := camera.target;
	camera.position = pos - V3f.{ 0, -4, 8 };
	camera.target_target = pos;
	camera.delta_unit = normalize(camera.position - camera.target);
	camera.nominal_distance = norm(camera.position - camera.target);
	camera.locked_nominal_distance = camera.nominal_distance * 1.05;
	camera.max_distance = camera.locked_nominal_distance;
	camera.fov = 55;
}

perspective :: (camera: Camera) -> M4f {
	f := 1.0 / tan(camera.fov * DEG_RAD / 2);
	M: M4f = ---;
	M.data[0 + 0 * 4] = f / camera.aspect;
	M.data[1 + 0 * 4] = 0;
	M.data[2 + 0 * 4] = 0;
	M.data[3 + 0 * 4] = 0;
	M.data[0 + 1 * 4] = 0;
	M.data[1 + 1 * 4] = f;
	M.data[2 + 1 * 4] = 0;
	M.data[3 + 1 * 4] = 0;
	M.data[0 + 2 * 4] = 0;
	M.data[1 + 2 * 4] = 0;
	M.data[2 + 2 * 4] = -(camera.far + camera.near) / (camera.far - camera.near);
	M.data[3 + 2 * 4] = -1;
	M.data[0 + 3 * 4] = 0;
	M.data[1 + 3 * 4] = 0;
	M.data[2 + 3 * 4] = -2 * (camera.far * camera.near) / (camera.far - camera.near);
	M.data[3 + 3 * 4] = 0;
	return M;
}

orthographic :: (
	left: float, right: float, bottom: float, top: float, near: float, far: float
) -> M4f {
	M: M4f = ---;
	M.data[0 + 0 * 4] = 2 / (right - left);
	M.data[1 + 0 * 4] = 0;
	M.data[2 + 0 * 4] = 0;
	M.data[3 + 0 * 4] = 0;
	M.data[0 + 1 * 4] = 0;
	M.data[1 + 1 * 4] = 2 / (top - bottom);
	M.data[2 + 1 * 4] = 0;
	M.data[3 + 1 * 4] = 0;
	M.data[0 + 2 * 4] = 0;
	M.data[1 + 2 * 4] = 0;
	M.data[2 + 2 * 4] = -1 / (far - near);
	M.data[3 + 2 * 4] = 0;
	M.data[0 + 3 * 4] = -(right + left) / (right - left);
	M.data[1 + 3 * 4] = -(top + bottom) / (top - bottom);
	M.data[2 + 3 * 4] = -(near) / (far - near);
	M.data[3 + 3 * 4] = 1;
	return M;
}
orthographic_inverse :: (
	left: float, right: float, bottom: float, top: float, near: float, far: float
) -> M4f {
	M: M4f = ---;
	M.data[0 + 0 * 4] = (right - left) / 2;
	M.data[1 + 0 * 4] = 0;
	M.data[2 + 0 * 4] = 0;
	M.data[3 + 0 * 4] = 0;
	M.data[0 + 1 * 4] = 0;
	M.data[1 + 1 * 4] = (top - bottom) / 2;
	M.data[2 + 1 * 4] = 0;
	M.data[3 + 1 * 4] = 0;
	M.data[0 + 2 * 4] = 0;
	M.data[1 + 2 * 4] = 0;
	M.data[2 + 2 * 4] = -(far - near);
	M.data[3 + 2 * 4] = 0;
	M.data[0 + 3 * 4] = (right + left) / 2;
	M.data[1 + 3 * 4] = (top + bottom) / 2;
	M.data[2 + 3 * 4] = -near;
	M.data[3 + 3 * 4] = 1;
	return M;
}

look_at :: (eye: V3f, target: V3f, up: V3f) -> M4f {
	M: M4f = ---;
	z := normalize(eye - target);
	x := normalize(cross(up, z));
	y := cross(z, x);
	M.data[0 ]  = x.x;
	M.data[1 ]  = y.x;
	M.data[2 ]  = z.x;
	M.data[3 ]  = 0;
	M.data[4 ]  = x.y;
	M.data[5 ]  = y.y;
	M.data[6 ]  = z.y;
	M.data[7 ]  = 0;
	M.data[8 ]  = x.z;
	M.data[9 ]  = y.z;
	M.data[10] = z.z;
	M.data[11] = 0;
	M.data[12] = -dot(eye, x);
	M.data[13] = -dot(eye, y);
	M.data[14] = -dot(eye, z);
	M.data[15] = 1.0;
	return M;
}

look_at_inverse :: (eye: V3f, target: V3f, up: V3f) -> M4f {
	M: M4f = ---;
	z := normalize(eye - target);
	x := normalize(cross(up, z));
	y := cross(z, x);
	// Inverse of look_at: transpose the rotation part, use eye directly for translation
	M.data[0 ]  = x.x;
	M.data[1 ]  = x.y;
	M.data[2 ]  = x.z;
	M.data[3 ]  = 0;
	M.data[4 ]  = y.x;
	M.data[5 ]  = y.y;
	M.data[6 ]  = y.z;
	M.data[7 ]  = 0;
	M.data[8 ]  = z.x;
	M.data[9 ]  = z.y;
	M.data[10] = z.z;
	M.data[11] = 0;
	M.data[12] = eye.x;
	M.data[13] = eye.y;
	M.data[14] = eye.z;
	M.data[15] = 1.0;
	return M;
}

unproject_ndc :: (ndc: V2f, V: M4f, P: M4f) -> V3f {
	iP := inverse(P);
	ray_eye := iP * V4f.{ ndc.x, ndc.y, -1.0, 1.0 };
	ray_eye.z = -1.0;
	ray_eye.w = 0.0;

	ray_world := v3(inverse(V) * ray_eye);
	return normalize(ray_world);
}

Trigger :: enum {
	Move_To_Play_World :: 0;
}

Lantern :: struct {
	id: int;
	position: V3f; @edit @picking
	light_aabb: AABBf; @edit @picking @display_name(aabb)
	turned_on := false;
	button_id: int; @edit
	intensity := 1.0; @edit
}

Flag :: struct {
	id: int;
	position: V3f; @edit @picking
	radius: float = 0.75;

	count_changed_juice_t := 0.0;
	activated_juice_t := 0.0;

	index := 0; @edit
	activated := false;

	n_present := 0;

	last_player_count := 0;
} @editable

Trigger_Zone :: struct {
	id: int;
	accept_player_id := -1; // -1 means accept all players
	trigger: Trigger;

	pos: V3f;
	radius: float;

	model_id := -1;
}

Within_Zone :: struct {
	id: int;

	pos: V2f;
	size: V2f;

	min_player_percent := 0.5;
	time_to_stay := 5.0;
	last_player_count := 0;
	count_changed_juice_t := 0.0;

	time_stayed := 0.0;

	trigger_id := -1;
}

Stand_In :: struct {
	id: int;
	model_id: int;
	position: V3f;
	orientation: Qf;
	retired := false;
}

Moving_Frame :: struct {
	id: int;

	Key :: struct {
		pos: V3f;
		theta: float;
		period: float;
	}

	keys: ISpan(Key);

	server: struct {
		speed: float = 1.0;
		offset: float = 0.0;
	}

	client: struct {
	}

	sum_period := 0.0;
}

Shuriken :: struct {
	id: int;
	frame_id := -1;

	server: struct {
		position: V3f;

		radius_hitbox := 0.2;
	}

	client: struct {
		theta: float = 0;

		theta_speed : float = xx (-3.1415926 * 2.0 * 3.0);
	}
}

Coin :: struct {
	id: int;
	sender: int;
	server: struct {
		position: V3f;
		direction: V3f;
		speed := 5.0;
		radius_hitbox := 0.25;
		birthtime: float64;
	};
	client: struct {
		position: V3f;
		theta: float;
	}
}

Key :: struct {
	id: int;
	holder: int = -1;
	server: struct {
		home: V3f;
		position: V3f; @edit @picking @display_name(position)
		radius_hitbox := 0.25;
		last_hold_clock : float64 = 0.0;
	}
	client: struct {
		position: V3f;
	}
}

Skull :: struct {
	id: int;
	path_id: int; @edit

	server: struct {
		speed: float = 1.0; @edit
		offset: float = 0.0; @edit
	}
	client: struct {
		direction: V3f = .{ 1, 0, 0 };
	}
}

Path :: struct {
	id: int;
	closed := false; @edit
	theta_dir := false;

	checkpoint_head: int = -1;
}

Checkpoint :: struct {
	position: V3f;
	theta: float = 0;
	speed: float = 1.0;

	next: int = -1;
}

Camera_Rail :: struct {
	id: int;
	waypoints: ISpan(V3f);
}

Camera_POI :: struct {
	id: int;
	position: V3f;
	zoom_out_factor := 1.0;
}

Tombstone :: struct {
	id: int;
	player_id: int;
	position: V3f;
}

Gate :: struct {
	id: int;
	position: V3f; @edit @picking
	direction: V3f; @edit @normalize
	is_closed := true;

	pressbutton_ids: ISpan(int);

	wait_for_key_id := -1; @edit
	wait_for_trigger_id := -1; @edit

	is_end := false; @edit
} @editable

Hook :: struct {
	id: int;
	hooker_id: int;
	hooked_id: int;

	server: struct {
		direction: V3f;
		length: float;
		max_length: float = 40.0;

		speed: float = 20.0;

		radius: float = 0.25;

		last_anchor_position: V3f;
	}
}

Player :: struct {
	Model :: enum {
		Racer :: 0;
		SUV :: 1;
		Speedster :: 2;
	}

	id := 0;

	// This is the stuff that gets overwritten as soon as we get information from the server.
	server: struct {
		position: V3f;
		direction: V3f;
		target_direction := V3f.{ 1, 0, 0 };
		walking_toward_position := V3f.{ 0, 0, 0 };
		walking_toward := false;
		slipping := false;
		speed := 3.5;
		turning_speed := 360 * 1.1;
		dead := false;
		dead_time: float;
		dead_cooldown := 90;

		radius_hitbox_tombstone := 0.75;
		radius_hurtbox_skull := 0.5;
		radius_hurtbox_shuriken := 0.25;
		radius_hitbox_key := 0.55;
		radius_hitbox_confirmed := 0.15;

		confirmed_tile := Tile.Kind.Grass;

		model_id := 0;

		souls := 0;
		death_count := 0;
		revive_count := 0;

		has_safe_present := false;
		has_hook_present := 0;
		
		need_respawn := false;
	};

	// This is the stuff that gets optimistically updated by the client. For rendering
	client: struct {
		position  := V3f.{ 0, 0, 0 };
		direction := V3f.{ 1, 0, 0 };
		delta_frame_position := V3f.{ 0, 0, 0 };
	};
}

find_tombstone_by_player_id :: (scene: Scene, id: int) -> *Tombstone {
	for * scene.tombstones {
		if it.player_id == id
			return it;
	}
	return null;
}

find_by_hook_id :: (scene: Scene, id: int) -> *Hook {
	for * scene.hooks {
		if it.id == id
			return it;
	}
	return null;
}

find_by_safe_zone_id :: (scene: Scene, id: int) -> *Safe_Zone {
	for * scene.safe_zones {
		if it.id == id
			return it;
	}
	return null;
}

find_by_robot_id :: (scene: Scene, id: int) -> *Robot {
	for * scene.robots {
		if it.id == id
			return it;
	}
	return null;
}

find_by_standin_id :: (scene: Scene, id: int) -> *Stand_In {
	for * scene.stand_in {
		if it.id == id
			return it;
	}
	return null;
}

find_by_present_id :: (scene: Scene, id: int) -> *Present {
	for * scene.presents {
		if it.id == id
			return it;
	}
	return null;
}

find_by_antiair_id :: (scene: Scene, id: int) -> *AntiAir {
	for * scene.antiairs {
		if it.id == id
			return it;
	}
	return null;
}

find_by_frame_id :: (scene: Scene, id: int) -> *Moving_Frame {
	for * scene.moving_frames {
		if it.id == id
			return it;
	}
	return null;
}
find_by_path_id :: (scene: Scene, id: int) -> *Path {
	for * scene.paths {
		if it.id == id
			return it;
	}
	return null;
}
find_by_player_id :: (scene: Scene, id: int) -> *Player, int {
	for * scene.players {
		if it.id == id
			return it, it_index;
	}
	return null, -1;
}
find_by_jukebox_id :: (scene: Scene, id: int) -> *Jukebox {
	for * scene.jukeboxes {
		if it.id == id
			return it;
	}
	return null;
}
find_by_pressbutton_id :: (scene: Scene, id: int) -> *PressButton {
	for * scene.pressbuttons {
		if it.id == id
			return it;
	}
	return null;
}
find_by_coin_id :: (scene: Scene, id: int) -> *Coin {
	for * scene.coins {
		if it.id == id
			return it;
	}
	return null;
}
find_by_flag_id :: (scene: Scene, id: int) -> *Flag {
	for * scene.flags {
		if it.id == id
			return it;
	}
	return null;
}
find_key_by_holder_id :: (scene: Scene, id: int) -> [..] *Key {
	keys: [..] *Key;
	keys.allocator = temp;

	for * scene.keys {
		if it.holder == id
			array_add(*keys, it);
	}

	return keys;
}
find_by_key_id :: (scene: Scene, id: int) -> *Key {
	for * scene.keys {
		if it.id == id
			return it;
	}

	return null;
}
find_bomb_by_holder_id :: (scene: Scene, id: int) -> *Bomb {
	for * scene.bombs {
		if it.holder == id
			return it;
	}

	return null;
}
find_by_bomb_id :: (scene: Scene, id: int) -> *Bomb {
	for * scene.bombs {
		if it.id == id
			return it;
	}

	return null;
}
find_by_bomb_spawner_id :: (scene: Scene, id: int) -> *Bomb_Spawner {
	for * scene.bomb_spawners {
		if it.id == id
			return it;
	}

	return null;
}
find_by_turn_table_id :: (scene: Scene, id: int) -> *Turn_Table {
	for * scene.turn_tables {
		if it.id == id
			return it;
	}
	return null;
}

get_pointing_angle :: (scene: Scene, turn_table: Turn_Table) -> float {
	offset := turn_table.turning_offset;
	speed := turn_table.turning_speed;
	if scene.is_server
		return xx (fmod_cycling(offset + speed * scene.server.clock, 1) * 2 * 3.1415926);
	else
		return xx (fmod_cycling(offset + speed * scene.client.clock, 1) * 2 * 3.1415926);
}

interpolate_all_to_server :: (scene: *Scene, dt: float) {
	for * scene.players {
		interpolate_to_server(it, dt);
	}
	for * scene.skulls {
		interpolate_to_server(it);
	}
	for * scene.keys {
		interpolate_to_server(it, dt);
	}
	for * scene.bombs {
		interpolate_to_server(it, dt);
	}
}

interpolate_to_server :: (player: *Player, dt: float) {
	player.client.direction = damp(player.client.direction, player.server.direction, 25.0, dt);
	player.client.direction = normalize(player.client.direction);
	player.client.position = damp(player.client.position, player.server.position, 25.0, dt);
}

interpolate_to_server :: (skull: *Skull) {
}

interpolate_to_server :: (key: *Key, dt: float32) {
	key.client.position = damp(key.client.position, key.server.position, 10.0, dt);
}
interpolate_to_server :: (bomb: *Bomb, dt: float32) {
	bomb.client.time = damp(bomb.client.time, bomb.server.time, 10.0, dt);
	bomb.client.position = damp(bomb.client.position, bomb.server.position, 10.0, dt);
}

restart :: (scene: *Scene, params: Scene_Parameters) {
	clear_scene_run(scene);
	parse_terrain(scene.terrain.text, scene);
	scene.params = params;
	scene.server.clock = 0.0;
	scene.client.clock = 0.0;
	scene.auto_revive |= params.auto_revive;
	for * player: scene.players {
		player.server.souls = 0;
		spawn_into(player, scene);
	}
	scene.end_scene_countdown_started = false;
	scene.succeed = false;
}

add_checkpoint_to_path :: (scene: *Scene, path: *Path, checkpoint: Checkpoint) {
	if path.checkpoint_head == -1 {
		array_add(*scene.checkpoints, checkpoint);
		path.checkpoint_head = scene.checkpoints.count - 1;
		return;
	}

	idx := path.checkpoint_head;
	while scene.checkpoints[idx].next != -1 {
		idx = scene.checkpoints[idx].next;
	}

	array_add(*scene.checkpoints, checkpoint);
	scene.checkpoints[idx].next = scene.checkpoints.count - 1;
}

add_dirt_particles :: (scene: *Scene, dt: float32) {
	player := find_by_player_id(scene, scene.controlled_player_id);
	if !player || player.server.dead
		return;

	tile, ok := tile_under(scene, player.client.position);
	if !ok
		return;
	
	n := dt * 6000.0 * norm(player.client.delta_frame_position);
	if n > 20
		n = 20;
	while n > 0.0 {
		r := Rand.random_uniform(*scene.client_rng, 0.0, 1.0);
		if r > n
			break;
		p: Particle;
		p.position = player.client.position;
		p.velocity = normalize(player.client.delta_frame_position);
		p.velocity = p.velocity * Rand.random_uniform(*scene.client_rng, -0.25, -0.125);
		side := cross(p.velocity, V3f.{ 0, 0, 1 });
		side = normalize(side);
		p.position = p.position + player.client.delta_frame_position * 0.5;
		if Rand.random_u64(*scene.client_rng) % 2 == 0
			p.position = p.position + side * 0.15;
		else
			p.position = p.position - side * 0.15;
		if Rand.random_u64(*scene.client_rng) % 2 == 0
			p.position = p.position + player.client.delta_frame_position * 0.85;
		else
			p.position = p.position - player.client.delta_frame_position * 0.85;

		p.velocity = p.velocity + side * Rand.random_uniform(*scene.client_rng, -0.3, 0.3);
		p.velocity.z = Rand.random_uniform(*scene.client_rng, 0.5, 1.0);
		p.size = Rand.random_uniform(*scene.client_rng, 0.1, 0.2);
		p.rotation_speed = Rand.random_uniform(*scene.client_rng, -5.0, 5.0);
		p.lifetime = Rand.random_uniform(*scene.client_rng, 0.35, 0.6);
		p.fade_out_time = Rand.random_uniform(*scene.client_rng, 0.1, 0.25);
		p.floor_bounce = Rand.random_uniform(*scene.client_rng, 0.2, 0.5);
		p.drag = Rand.random_uniform(*scene.client_rng, 0.7, 0.9);
		
		if tile.kind == .Grass {
			p.color = V4f.{ 0.5, 0.2, 0.0, 1 };
			texture_idx := Rand.random_uniform(*scene.client_rng, 1, 3);
			p.texture_rec = V4f.{ texture_idx / 4.0, 2 / 4.0, 1 / 4.0, 1 / 4.0 };
		}
		else {
			p.color = V4f.{ 0.8, 0.8, 1.0, 1 };
			p.size *= 1.5;
			texture_idx := Rand.random_uniform(*scene.client_rng, 1, 4);
			p.texture_rec = V4f.{ texture_idx / 4.0, 3 / 4.0, 1 / 4.0, 1 / 4.0 };
		}
		array_add(*scene.particles, p);
		n -= 1.0;
	}
}

add_snow :: (scene: *Scene, dt: float32) {
	// Add snow particles
	n_snow :=
		dt * (scene.camera_max.x - scene.camera_min.x) * (scene.camera_max.y - scene.camera_min.y);
	n_snow *= 0.45;
	while n_snow > 0.0 {
		r := Rand.random_uniform(*scene.client_rng, 0.0, 1.0);
		if r > n_snow
			break;

		p: Particle;
		p.position = V3f.{
			Rand.random_uniform(*scene.client_rng, scene.camera_min.x - 5, scene.camera_max.x + 5),
			Rand.random_uniform(*scene.client_rng, scene.camera_min.y - 5, scene.camera_max.y + 5),
			10.0,
		};
		p.velocity = V3f.{
			Rand.random_uniform(*scene.client_rng, -1.0, 0.5),
			Rand.random_uniform(*scene.client_rng, -0.5, 0.8),
			Rand.random_uniform(*scene.client_rng, 0.5, 1.5)
		};

		texture_idx := Rand.random_uniform(*scene.client_rng, 1, 4);
		p.texture_rec = V4f.{ texture_idx / 4.0, 3 / 4.0, 1 / 4.0, 1 / 4.0 };
		p.velocity = normalize(p.velocity) * Rand.random_uniform(*scene.client_rng, 0.09, 0.11);
		p.size = Rand.random_uniform(*scene.client_rng, 0.06, 0.15);
		p.rotation_speed = Rand.random_uniform(*scene.client_rng, -2.0, 2.0);
		p.lifetime = Rand.random_uniform(*scene.client_rng, 5.0, 10.0);
		p.fade_out_time = Rand.random_uniform(*scene.client_rng, 0.1, 1.0);
		p.color = V4f.{ 1, 1, 1, 1 };
		p.floor_bounce = Rand.random_uniform(*scene.client_rng, 0.1, 0.3);
		p.drag = Rand.random_uniform(*scene.client_rng, 0.6, 0.85);
		array_add(*scene.particles, p);
		n_snow -= 1.0;
	}
}

add_turn_table :: (scene: *Scene, turn_table: Turn_Table) -> *Turn_Table {
	array_add(*scene.turn_tables, turn_table);
	rellocate_turn_table(*scene.turn_tables[scene.turn_tables.count - 1], scene);
	return *scene.turn_tables[scene.turn_tables.count - 1];
}

input :: (scene: *Scene, controls: *Controls.State, result: *Process_Response) {
	any_camera_move := false;
	dt := V3f.{ 0, 0, 0 };
	if controls.mouse_wheel > 0 {
		scene.camera.distance_target *= 0.9;
	}
	if controls.mouse_wheel < 0 {
		scene.camera.distance_target *= (1.0 / 0.9);
	}
	if Controls.is_action_pressed(controls, GUI.Action_Key.Move_Left) {
		dt.x -= scene.camera.speed * controls.delta_time;
		any_camera_move = true;
	}
	if Controls.is_action_pressed(controls, GUI.Action_Key.Move_Right) {
		dt.x += scene.camera.speed * controls.delta_time;
		any_camera_move = true;
	}
	if Controls.is_action_pressed(controls, GUI.Action_Key.Move_Down) {
		dt.y -= scene.camera.speed * controls.delta_time;
		any_camera_move = true;
	}
	if Controls.is_action_pressed(controls, GUI.Action_Key.Move_Up) {
		dt.y += scene.camera.speed * controls.delta_time;
		any_camera_move = true;
	}
	if Controls.is_action_just_pressed(controls, GUI.Action_Key.Buy_Ask) {
		buy_ask(scene, scene.controlled_player_id, result);
	}
	if controls.just_pressed[Platform.Key.V] {
		// player := find_by_player_id(scene, scene.controlled_player_id);
		// if player && player.server.dead {
		// 	dt := to_float64_seconds(current_time_monotonic() - player.server.dead_time).(float32);
		// 	if dt >= player.server.dead_cooldown.(float32) {
		// 		command: Command.Ask_Respawn;
		// 		command.player_id = player.id;
		// 		add(result, scene.id, command);
		// 	}
		// }
	}

	if Controls.is_action_just_pressed(controls, GUI.Action_Key.Camera_Locked) {
		scene.camera_locked = !scene.camera_locked;
	}

	if scene.camera_locked {
		scene.camera.locked = !controls.pressed[Platform.Key.Space];
	} else {
		scene.camera.locked =  controls.pressed[Platform.Key.Space];
	}
	scene.camera.target_target += dt;
	if scene.camera.locked {
		scene.camera.target += dt;
	}

	// if !any_camera_move {
	// 	scene.camera.target_target = scene.camera.target;
	// }


	if !controls.captured_mouse {
		if controls.just_pressed[Platform.Key.MouseLeft] {
			V := look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
			P := perspective(scene.camera);
			r := unproject_ndc(
				.{
					controls.mouse_pos.x / controls.window_size.x * 2 - 1,
					controls.mouse_pos.y / controls.window_size.y * 2 - 1
				},
				V,
				P
			);

			target, ok := ray_plane(scene.camera.position, r, .{ 0, 0, 1 });
			if ok && scene.state == .Normal {
				command: Command.Move;
				command.ground_target = v2(target);
				command.player_id = scene.controlled_player_id;
				add(result, scene.id, command);
				scene.mark_clicked_time = controls.time;
				scene.mark_clicked_pos = target;

				sound: Sound_Trigger;
				sound.position = target;
				sound.kind = .Footstep_Snow;
				tile, ok := tile_under(scene, target);
				if ok && (tile.kind == .Ice || tile.kind == .Slippy_Ice) {
					sound.kind = .Footstep_Ice;
				}

				array_add(*scene.sound_triggers, sound);
			}
		}

		if controls.just_pressed[Platform.Key.MouseRight] {
			V := look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
			P := perspective(scene.camera);
			r := unproject_ndc(
				.{
					controls.mouse_pos.x / controls.window_size.x * 2 - 1,
					controls.mouse_pos.y / controls.window_size.y * 2 - 1
				},
				V,
				P
			);

			target, ok := ray_plane(scene.camera.position, r, .{ 0, 0, 1 });
			if ok && scene.state == .Normal {
				command: Command.Signal_Pick;
				command.pos = target;
				add(result, scene.id, command);
			}
		}
	}
	if Controls.is_action_just_pressed(controls, GUI.Action_Key.Coin) {
		player := find_by_player_id(scene, scene.controlled_player_id);
		if player && !player.server.dead {
			command: Command.Spawn_Coin;
			command.sender = player.id;
			add(result, scene.id, command);
		}
	}

	if Controls.is_action_just_pressed(controls, GUI.Action_Key.Klaxon) {
		player := find_by_player_id(scene, scene.controlled_player_id);
		if player && !player.server.dead {
			command: Command.Klaxon;
			command.player_id = player.id;
			add(result, scene.id, command);
		}
	}
	if Controls.is_action_just_pressed(controls, GUI.Action_Key.Drop) {
		player := find_by_player_id(scene, scene.controlled_player_id);
		if player && !player.server.dead {
			command: Command.Drop;
			command.player_id = player.id;
			add(result, scene.id, command);
		}
	}

	if Controls.is_action_just_pressed(controls, GUI.Action_Key.Safe) {
		player := find_by_player_id(scene, scene.controlled_player_id);
		if player && !player.server.dead {
			if player.server.has_safe_present {
				command: Command.Active_Item;
				command.player_id = player.id;
				command.safe_zone = true;
				command.hook = false;
				add(result, scene.id, command);
			}
		}
	}

	if Controls.is_action_just_pressed(controls, GUI.Action_Key.Hook)  {
		player := find_by_player_id(scene, scene.controlled_player_id);
		if player && !player.server.dead {
			if player.server.has_hook_present > 0 {
				command: Command.Active_Item;
				command.player_id = player.id;
				command.safe_zone = false;
				command.hook = true;
				add(result, scene.id, command);
			}
		}
	}
}

update :: (scene: *Scene, time: Apollo_Time, dt: float32, result: *Frame_Result) {
	scene.fade_in_screen_t = 0.0;
	scene.client.clock += dt;
	scene.server.clock += dt;
	scene.client.clock = damp_snap(scene.client.clock, scene.server.clock, 10.0, dt, 1.0);
	if #complete scene.state == {
		case .Normal;
			update_normal(scene, time, dt, result);
		case .Wipe_Fade_In;
			t := to_float64_seconds(time - scene.fade_screen.start).(float32);
			if t < scene.fade_screen.period {
				scene.fade_in_screen_t = ease_quad(clamp(t / scene.fade_screen.period, 0.0, 1.0));
			} else {
				restart(scene, scene.params);
				scene.state = .Wipe_Fade_Out;
				if result {
					result.restarted = true;
				}
			}
		case .Wipe_Fade_Out;
			t := to_float64_seconds(time - scene.fade_screen.start).(float32);
			if t >= 2 * scene.fade_screen.period {
				scene.state = .Normal;
				return;
			} else {
				scene.fade_in_screen_t = ease_out_quad(
					clamp(2.0 - t / scene.fade_screen.period, 0.0, 1.0)
				);
			}
	}
}

update :: (scene: *Scene, lantern: *Lantern, dt: float32) {
	lantern.turned_on = false;
	button := find_by_pressbutton_id(scene, lantern.button_id);
	if button && button.activated {
		lantern.turned_on = true;
		return;
	}
	if !button && lantern.intensity > 0 {
		lantern.turned_on = true;
		return;
	}
}

update_client :: (scene: *Scene, dt: float32, result: *Frame_Result) {
	if scene.client.render_particles {
		add_snow(scene, dt);
		add_dirt_particles(scene, dt);
	}

	{
		pick_cursor := 0;
		for scene.signal_picks {
			if scene.client.clock > it.birthtime + it.lifetime {
				continue;
			}
			scene.signal_picks[pick_cursor] = it;
			pick_cursor += 1;
		}
		scene.signal_picks.count = pick_cursor;
	}

	for * scene.safe_zones {
		it.client.time += dt;
	}

	for * scene.presents {
		before := it.server.available;

		it.server.available = true;
		if it.server.depends_on_flag_id != -1 {
			flag := find_by_flag_id(scene, it.server.depends_on_flag_id);
			if flag && !flag.activated {
				it.server.available = false;
			}
		}
	}

	// Springs the trap, only for visuals
	for * scene.traps if it.activable && !it.activated {
		for * player, player_idx: scene.players {
			if player.server.dead
				continue;

			p := player.server.position;
			q := it.position;

			d := norm(p - q);
			if d < it.radius_hitbox {
				it.activated_clock = xx scene.client.clock;
				it.activated = true;
				break;
			}
		}
	}
	// Unspring the trap, only for visuals
	for * scene.traps if it.activable && it.activated {
		if scene.client.clock >= it.activated_clock + it.stay_activated_time {
			it.activated = false;
		}
	}
}

update :: (scene: *Scene, hook: *Hook, dt: float32, result: *Frame_Result) {
	hooker := find_by_player_id(scene, hook.hooker_id);
	if hooker {
		hook.server.last_anchor_position = hooker.server.position;
	}

	if hook.hooked_id < 0 {
		hook.server.length += hook.server.speed * dt;
		if hook.server.length > hook.server.max_length
			hook.server.length = hook.server.max_length;

		for * scene.players {
			if it.id == hook.hooker_id
				continue;

			p := it.server.position;
			hooker := find_by_player_id(scene, hook.hooker_id);
			if !hooker
				continue;

			q := hooker.server.position + hook.server.direction * hook.server.length;

			d := norm(p - q);
			if d < hook.server.radius {
				hook.hooked_id = it.id;
				hook.server.length = norm(p - hooker.server.position);
				break;
			}
		}
	} else {
		hooked := find_by_player_id(scene, hook.hooked_id);


		hook.server.length -= hook.server.speed * dt;
		if hook.server.length < 0.0
			hook.server.length = 0.0;

		if hooked {
			dt := normalize(hooked.server.position - hook.server.last_anchor_position);
			hooked.server.position = hook.server.last_anchor_position + dt * hook.server.length;
		}
	}
}

update_normal :: (scene: *Scene, time: Apollo_Time, dt: float32, result: *Frame_Result) {
	if !scene.is_server
		update_client(scene, dt, result);

	update(scene, *scene.camera, dt);

	for * scene.players {
		update(scene, it, dt);
	}
	{
		player := find_by_player_id(scene, scene.controlled_player_id);
		if player {
			p := player.server.position;

			for * scene.gates {
				if it.is_end {
					q := it.position;

					d := norm(p - q);
					if d < 0.5 {
						scene.succeed = true;
						continue;
					}
				}
			}
		}
	}

	for * scene.skulls {
		update(scene, it, dt);
	}

	{
		coin_cursor := 0;
		for * scene.coins {
			if scene.server.clock > it.server.birthtime + 5 {
				continue;
			}
			update(scene, it, dt);
			scene.coins[coin_cursor] = it;
			coin_cursor += 1;
		}
		scene.coins.count = coin_cursor;
	}

	for * scene.moving_frames {
		update(scene, it, dt);
	}

	for * scene.shurikens {
		update(scene, it, dt);
	}

	for * scene.flags {
		update(scene, it, dt, result);
	}

	for * scene.pressbuttons {
		update(scene, it, dt, result);
	}

	for * scene.within_zones {
		update(scene, it, dt);
	}

	for * scene.robots {
		update(scene, it, time, dt);
	}

	for * scene.antiairs {
		update(scene, it, dt);
	}

	for * scene.hooks {
		update(scene, it, dt, result);

		if it.hooked_id >= 0 && it.server.length <= 0.0 {
			remove it;
			continue it;
		}
		if it.hooked_id < 0 && it.server.length >= it.server.max_length {
			remove it;
			continue it;
		}
	}

	for * scene.bombs {
		it.server.time += dt;
		it.client.time += dt;
	}

	for * scene.turn_tables {
		update(scene, it, dt);
	}

	update_explosions(scene, dt);

	for * scene.block_rocks {
		if it.exploded
			continue;

		p := it.position;
		for * explosion: scene.explosions {
			q := explosion.position;

			d := norm(p - q);
			if d < explosion.max_size / 2 + 0.5 {
				it.exploded = true;
			}
		}
	}

	for * scene.lanterns {
		update(scene, it, dt);
	}

	for * scene.keys {
		interpolate_to_server(it, dt);

		if it.holder < 0 {
			p := it.server.position;

			for * player: scene.players {
				if !player.server.dead {
					q := player.server.position;

					d := norm(p - q);
					if d < player.server.radius_hitbox_key {
						it.holder = player.id;
						continue it;
					}
				}
			}
		}
	}

	for * scene.keys {
		if it.holder >= 0 {
			player := find_by_player_id(scene, it.holder);
			if !player {
				it.server.last_hold_clock = scene.server.clock;
				it.holder = -1;
				continue;
			}

			it.server.position = player.server.position;
		}
		if it.holder < 0 {
			elapsed := scene.client.clock - it.server.last_hold_clock;
			if elapsed > 20 {
				dir := normalize(it.server.position - it.server.home);
				D := norm(it.server.position - it.server.home);
				to_travel := dt * 0.4;
				to_travel = min(to_travel, D);

				it.server.position -= dir * to_travel;
			}
		}
	}

	if scene.client.render_particles {
		update_debris(scene, dt);
		update_particles(scene, dt);
	}

	if scene.is_server
		update_server(scene, time, dt, result);

	for * scene.bombs {
		if it.server.time > it.server.explosion_time {
			remove it;
			break;
		}
		player := find_by_player_id(scene, it.holder);
		if player
			it.server.position = player.server.position;

		interpolate_to_server(it, dt);
	}

}

update_server :: (scene: *Scene, time: Apollo_Time, dt: float32, result: *Frame_Result) {
	scene.server.clock_sync_cd -= dt;
	if scene.server.clock_sync_cd < 0 {
		scene.server.clock_sync_cd = 1.0;

		cmd: Command.Sync_Clock;
		cmd.t = scene.server.clock;
		array_add(*result.broadcast, make_command(cmd));
	}

	Should_Die :: struct {
		hard_die: bool = false;
		soft_die: bool = false;
	}
	should_die := NewArray(scene.players.count, Should_Die,, temp);
	should_die_source: V3f = v3(FLOAT32_MAX, FLOAT32_MAX, FLOAT32_MAX);
	should_die_strength := 0.0;

	// // >RULE Presents respawn.
	// for * scene.presents {
	// 	if !it.server.available {
	// 		can_countdown := false;
	// 		if it.server.depends_on_flag_id == -1 {
	// 			can_countdown = true;
	// 		} else {
	// 			flag := find_by_flag_id(scene, it.server.depends_on_flag_id);
	// 			if flag && flag.activated {
	// 				can_countdown = true;
	// 			}
	// 		}

	// 		if can_countdown {
	// 			it.server.time_since_taken += dt;
	// 			if it.server.time_since_taken >= it.server.refresh_cooldown {
	// 				it.server.available = true;
	// 				it.server.time_since_taken = 0.0;

	// 				array_add(*result.sync_present, make_sync(it));
	// 			}
	// 		}
	// 	}
	// }

	// >RULE presents is available dependings on flags
	for * scene.presents {
		before := it.server.available;

		it.server.available = true;
		if it.server.depends_on_flag_id != -1 {
			flag := find_by_flag_id(scene, it.server.depends_on_flag_id);
			if flag && !flag.activated {
				it.server.available = false;
			}
		}

		if before != it.server.available {
			array_add(*result.sync_present, make_sync(it));
		}
	}

	// // >RULE Player pickup present
	// for * scene.players {
	// 	if it.server.dead
	// 		continue;
		
	// 	p := it.server.position;

	// 	for * present: scene.presents {
	// 		if !present.server.available
	// 			continue;

	// 		q := present.position;

	// 		d := norm(p - q);
	// 		if d < 0.5 {
	// 			if #complete present.kind == {
	// 				case .A;
	// 					it.server.has_safe_present = true;
	// 				case .B;
	// 					it.server.has_hook_present = 3;
	// 			}
	// 			array_add(*result.sync_player, make_sync(it));
	// 			continue;
	// 		}
	// 	}
	// }

	// >RULE Trap unspring after a short while, allowing players to step on it again
	for * scene.traps if it.activable && it.activated {
		if scene.server.clock > it.activated_clock + it.stay_activated_time {
			it.activated = false;
		}
	}

	// >RULE Player die on contact with trap
	for * scene.traps {
		p := it.position;

		// unconditionnaly if the traps are not of the activatable kind
		if !it.activable for * player, player_idx: scene.players {
			if !player.server.dead {
				q := player.server.position;

				d := max(abs((p - q).x), abs((p - q).y));
				if d < it.radius_hitbox {
					should_die[player_idx].soft_die = true;
					should_die_source = p;
					should_die_strength = 1.0;
					continue;
				}
			}
		}

		// Otherwise we need to check if the trap is already activated or not
		// and if the player is the one who activated it or not.
		if it.activable for * player, player_idx: scene.players if !player.server.dead {
			q := player.server.position;

			d := max(abs((p - q).x), abs((p - q).y));
			if d < it.radius_hitbox {
				if it.activated {
					if it.activator_id == player.id {
						if scene.server.clock > it.activated_clock + 0.5 {
							should_die[player_idx].soft_die = true;
							should_die_source = p;
							should_die_strength = 1.0;
							continue;
						}
					} else {
						should_die[player_idx].soft_die = true;
						should_die_source = p;
						should_die_strength = 1.0;
						continue;
					}
				} else {
					it.activated = true;
					it.activator_id = player.id;
					it.activated_clock = xx scene.server.clock;
				}
			}
		}
	}

	// >RULE Player picks up bomb laying on the ground
	for * player: scene.players {
		p := player.server.position;

		for * bomb: scene.bombs {
			if bomb.holder != -1
				continue;

			q := bomb.server.position;

			d := norm(p - q);
			if d < 0.25 {
				can_pickup := true;
				if bomb.last_holder != player.id {
					bomb.server.time = 0;
					bomb.client.time = 0;
				} else {
					treshold := bomb.server.dropped_clock + bomb.server.explosion_time * 0.6;
					if treshold >= scene.server.clock {
						can_pickup = false;
					}
				}
				if can_pickup {
					bomb.holder = player.id;
					bomb.last_holder = bomb.holder;
					bomb.server.position = player.server.position;
					bomb.client.position = player.client.position;
				}
			}
		}
	}

	// >RULE Bombs spawner always has a bomb ready or in play
	for * spawner: scene.bomb_spawners {
		bomb := find_by_bomb_id(scene, spawner.spawned_id);
		if !bomb
			spawner.spawned_id = -1;
	}

	// >RULE Player picks up bomb available form spawner
	for * player: scene.players {
		p := player.server.position;
		// If the player already has a bomb we do nothing.
		if find_bomb_by_holder_id(scene, player.id)
			continue;

		for * spawner: scene.bomb_spawners {
			if spawner.spawned_id >= 0
				continue;
			
			q := spawner.position;

			d := norm(p - q);
			if d < 0.5 {
				bomb: Bomb;
				bomb.id = scene.bombs.count + 1;
				bomb.spawner_id = spawner.id;
				bomb.holder = player.id;
				bomb.last_holder = player.id;
				bomb.server.time = 0;
				bomb.client.time = 0;
				bomb.server.position = player.server.position;
				bomb.client.position = player.client.position;
				array_add(*scene.bombs, bomb);
				spawner.spawned_id = bomb.id;
			}
		}
	}

	// >RULE bombs explode on time, killing their holder
	for * bomb: scene.bombs {
		if bomb.server.time > bomb.server.explosion_time {

			player, player_idx := find_by_player_id(scene, bomb.holder);
			if player {
				should_die[player_idx].soft_die = true;
			}

			explosion: Explosion;
			explosion.position = bomb.server.position;
			explosion.lifetime = 0.75;
			explosion.max_size = bomb.server.explosion_radius * 2;
			array_add(*scene.explosions, explosion);

			cmd: Command.Explode;
			cmd.id = scene.explosions.count;
			cmd.lifetime = explosion.lifetime;
			cmd.max_size = explosion.max_size;
			cmd.position = explosion.position;
			array_add(*result.explode, cmd);
			remove bomb;
		}
	}

	// >RULE Trigger zone check
	for * scene.trigger_zones {
		tpos := it.pos;

		standin: *Stand_In = null;
		for * s: scene.stand_in {
			if s.model_id == it.model_id {
				standin = s;
				break;
			}
		}

		if !standin
			continue;

		if standin.retired
			continue;

		for * player: scene.players {
			if player.server.dead
				continue;

			if it.accept_player_id != -1 && it.accept_player_id != player.id
				continue;

			d := norm(tpos - player.server.position);

			if d < it.radius {
				if #complete it.trigger == {
				case .Move_To_Play_World;
					move: Command.Move_To_Play_World;
					move.player_id = player.id;
					move.model_id = it.model_id;
					move.play_world_id = 0;
					move.standin_id = standin.id;
					array_add(*result.move_to_player_world, move);
					standin.retired = true;
				}
			}
		}
	}

	// >RULE When all standins are retired, reload them
	if scene.stand_in.count > 0 {
		all := true;
		for * scene.stand_in {
			if !it.retired {
				all = false;
				break;
			}
		}
		if all {
			for * scene.stand_in {
				it.retired = false;
			}
		}
	}

	// >RULE Player auto revive if the scene has ended
	if scene.end_scene_countdown_started {
		for * scene.players {
			if it.server.dead {
				respawn: Command.Respawn;
				respawn.player_id = it.id;
				array_add(*result.respawn, respawn);
				spawn_into(it, scene);

				for * scene.tombstones {
					if it.player_id == respawn.player_id {
						remove it;
					}
				}
			}
		}
	}

	// >RULE player revive when user asked for it after dying cooldown
	for * scene.players {
		if it.server.dead && it.server.need_respawn {
			respawn: Command.Respawn;
			respawn.player_id = it.id;
			array_add(*result.respawn, respawn);
			spawn_into(it, scene);

			for * scene.tombstones {
				if it.player_id == respawn.player_id {
					remove it;
				}
			}
		}
		it.server.need_respawn = false;
	}

	// >RULE Coin revive dead player on tombstone collision
	for * scene.coins {
		pos := it.server.position;

		for * tombstone: scene.tombstones {
			// You can't revive yourself
			if it.sender != tombstone.player_id {
				dt := norm(pos - tombstone.position);

				if dt < (it.server.radius_hitbox + 0.25) {
					player_has_revived_other_player(scene, it.sender, tombstone.player_id, result);

					respawn: Command.Respawn;
					respawn.player_id = tombstone.player_id;
					respawn.coin_id = it.id;
					respawn.cause_player_id = it.sender;

					array_add(*result.respawn, respawn);

					player_to_respawn := find_by_player_id(scene, tombstone.player_id);
					if player_to_respawn {
						spawn_into(player_to_respawn, scene);
					}

					remove it;
					remove tombstone;
					continue it;
				}
			}
		}
	}

	// >RULE Coin trigger a note on jukebox collision
	for * scene.coins {
		pos := it.server.position;

		for * jukebox: scene.jukeboxes {
			dt := norm(jukebox.position - pos);
			if dt < 0.5 {
				cmd: Command.Note_Played;
				cmd.pitch = jukebox.coin_count;
				cmd.jukebox_id = jukebox.id;
				cmd.from_coin_id = it.id;

				array_add(*result.broadcast, make_command(cmd));

				jukebox.coin_count += 1;
				jukebox.last_coin_clock = xx scene.server.clock;
				remove it;
				continue;
			}
		}
	}

	// >RULE Player die when not under any tile or under a dirt tile
	for * player, player_idx: scene.players {
		if !player.server.dead {
			tile, ok := tile_under(scene, player.server.position);
			if !ok || tile.kind == .Dirt {
				should_die[player_idx].hard_die = true;
				continue;
			}
		}
	}

	// >RULE Player revive dead player on tombstone collision
	for * scene.players {
		if !it.server.dead {
			for tomb: scene.tombstones {
				dt := norm(it.server.position - tomb.position);

				if dt < it.server.radius_hitbox_tombstone {
					respawn: Command.Respawn;
					respawn.player_id = tomb.player_id;
					respawn.cause_player_id = it.id;

					array_add(*result.respawn, respawn);

					player_to_respawn := find_by_player_id(scene, tomb.player_id);
					if player_to_respawn {
						spawn_into(player_to_respawn, scene);
					}

					player_has_revived_other_player(scene, it.id, tomb.player_id, result);
					remove tomb;
					continue;
				}
			}
		}
	}

	// >RULE Player dies on contact with a skull
	for * player, player_idx: scene.players {
		if !player.server.dead {
			for skull: scene.skulls {
				skull_pos := compute_skull_pos(scene, skull);

				dt := norm(player.server.position - skull_pos);
				if dt < player.server.radius_hurtbox_skull {
					should_die[player_idx].soft_die = true;
					should_die_source = skull_pos;
					should_die_strength = 1.0;
					continue;
				}
			}
		}
	}

	// >RULE Key open gate
	for * scene.keys {
		p := it.server.position;

		for * gate: scene.gates {
			if gate.is_closed && gate.wait_for_key_id == it.id {
				q := gate.position;

				d := norm(p - q);
				if d < 0.5 {
					holder := it.holder;

					gate.is_closed = false;
					gate.wait_for_key_id = -1;

					it.holder = -1;
					it.server.position = .{ 100000, 100000, 100000 };

					sync: Command.Sync_Gate;
					sync.gate_id = gate.id;
					sync.is_closed = gate.is_closed;
					array_add(*result.sync_gate, sync);
				}
			}
		}
	}

	// >RULE Gate open on trigger
	for *gate: scene.gates {
		if gate.is_closed && gate.wait_for_trigger_id != -1 {
			ok, triggered := table_find(*scene.trigger_activated, gate.wait_for_trigger_id);
			if triggered {
				gate.is_closed = false;
				gate.wait_for_trigger_id = -1;
				sync: Command.Sync_Gate;
				sync.gate_id = gate.id;
				sync.is_closed = gate.is_closed;
				array_add(*result.sync_gate, sync);
			}
		}
	}

	// >RULE Gate open on pressbutton pressed
	for *gate: scene.gates {
		if gate.is_closed && gate.pressbutton_ids.count > 0 {
			any_unpressed := false;
			for iterator(gate.pressbutton_ids, scene.indices) {
				pressbutton := find_by_pressbutton_id(scene, it);
				if pressbutton
					any_unpressed |= !pressbutton.activated;
			}
			
			if !any_unpressed {
				gate.is_closed = false;
				gate.wait_for_trigger_id = -1;
				sync: Command.Sync_Gate;
				sync.gate_id = gate.id;
				sync.is_closed = gate.is_closed;
				array_add(*result.sync_gate, sync);
			}
		}
	}

	// >RULE Player die on contact with an explosion
	for *expl: scene.explosions {
		p := expl.position;
		t := ease_out_quad(clamp(expl.age / expl.lifetime, 0.0, 1.0));
		dt := t * expl.max_size / 2;

		for * player, player_idx: scene.players {
			if !player.server.dead {
				q := player.server.position;

				d := norm(p - q);
				if d < dt {
					should_die[player_idx].soft_die = true;
					should_die_source = p;
					should_die_strength = 3.0;
					continue;
				}
			}
		}
	}

	// >RULE Player die on contact with a shuriken
	for * scene.shurikens {
		p := compute_shuriken_server_world_pos(scene, it);

		for * player, player_idx: scene.players {
			if !player.server.dead {
				q := player.server.position;

				d := norm(p - q);
				if d < (it.server.radius_hitbox + player.server.radius_hurtbox_shuriken) {
					should_die[player_idx].soft_die = true;
					should_die_source = p;
					should_die_strength = 1.0;
					continue;
				}
			}
		}
	}

	// >RULE First player to reach a trophy wins.
	if !scene.end_scene_countdown_started for * scene.trophies {
		p := v2(it.position);

		for * player: scene.players {
			if player.server.dead
				continue;

			q := v2(player.server.position);
			d := norm(p - q);
			if d < 0.25 {
				win_level(scene, player.id, time, result);
				break it;
			}
		}
	}

	// >RULE Robots shoots explosions
	for * robot: scene.robots {
		if robot.just_shooted {
			explosion: Explosion;
			M := robot_matrix_local_to_joint(robot, 6);
			ray_origin := v3(M * V4f.{ 0, 0, 0, 1 });
			ray_direction := normalize(v3(M * V4f.{ 0, 0, 1, 0 }));

			target, hit := ray_plane(ray_origin, ray_direction, V3f.{ 0, 0, 1 });
			if hit {
				explosion.position = target;
				explosion.lifetime = 0.75;
				explosion.max_size = robot.explosion_radius * 2;

				array_add(*scene.explosions, explosion);
				
				cmd: Command.Explode;
				cmd.id = 0;
				cmd.lifetime = explosion.lifetime;
				cmd.max_size = explosion.max_size;
				cmd.position = explosion.position;
				array_add(*result.explode, cmd);
			}
		}
		robot.just_shooted = false;
	}

	for * antiair: scene.antiairs {
		if antiair.just_shooted {
			explosion: Explosion;
			explosion.position = v3(antiair.server.curr_target, 0.0);
			explosion.lifetime = 1.0;
			explosion.max_size = antiair.radius;

			array_add(*scene.explosions, explosion);

			{
				cmd: Command.Explode;
				cmd.id = 0;
				cmd.lifetime = explosion.lifetime;
				cmd.max_size = explosion.max_size;
				cmd.position = explosion.position;
				array_add(*result.explode, cmd);
			}

			{
				cmd: Command.AntiAir_Shoot;
				cmd.antiair_id = antiair.id;
				cmd.next_target = antiair.server.next_target;
				array_add(*result.antiair_shoot, cmd);
			}
		}
		antiair.just_shooted = false;
	}

	// >RULE Apply deaths
	// >RULE safe_zone prevents soft deaths
	// >RULE hooked players are immune to death
	for should_die {
		is_hooked := false;
		for *hook, hook_idx: scene.hooks {
			if hook.hooked_id == scene.players[it_index].id {
				is_hooked = true;
				break;
			}
		}

		if is_hooked {
			continue;
		}

		if it.hard_die {
			server_die(
				scene,
				*scene.players[it_index],
				time,
				result,
				should_die_source,
				should_die_strength
			);
		} else if it.soft_die {
			player := *scene.players[it_index];
			in_safe_zone := false;
			for * safe_zone: scene.safe_zones {
				d := norm(player.server.position - safe_zone.position);
				if d < safe_zone.radius {
					in_safe_zone = true;
					safe_zone.expire -= 1;
					break;
				}
			}
			if !in_safe_zone {
				server_die(scene, player, time, result, should_die_source, should_die_strength);
			}
		}
	}

	// >RULE Safe zone with 0 expire will start expiration
	for * scene.safe_zones {
		if !it.server.expire_started && it.expire <= 0 {
			it.server.expire_started = true;
			it.server.expire_start = time;
			it.server.expire_duration = 1.0;
		}
	}

	// >RULE remove expired safe zone
	for * scene.safe_zones {
		if it.server.expire_started {
			dt := to_float64_seconds(time - it.server.expire_start);
			if dt < it.server.expire_duration
				continue;

			array_add(*result.sync_safe_zone, make_sync(it));
			remove it;
		}
	}
}

update_explosions :: (scene: *Scene, dt: float32) {
	for * scene.explosions {
		it.age += dt;
		if it.age > it.lifetime {
			remove it;
		}
	}
}

update_debris :: (scene: *Scene, dt: float32) {

	world: XPBD.World;
	world.iterations = 1;
	world.substeps = 3;
	world.bodies = NewArray(scene.debris.count, XPBD.Rigid_Body,, temp);

	body_cursor := 0;
	for * scene.debris {
		if it.part_idx == -1
			continue;
		dt := scene.client.clock - it.birthtime;
		scale := 1.0 - smoothstep(dt.(float32), 5, 7) * 0.7;
		can_stop := false;
		
		body: XPBD.Rigid_Body;
		tile, ok := tile_under(scene, it.position);
		if ok {
			if #complete tile.kind == {
				case .Dirt;
					body.mu_d = 0.9;
					can_stop = true;
				case .Grass;
					body.mu_d = 0.7;
					can_stop = true;
				case .Ice;
					body.mu_d = 0.001;
				case .Slippy_Ice;
					body.mu_d = 0.00;
				case .Funny_Ice;
					body.mu_d = 0.1;
				case .None;
					body.mu_d = 0.5;
			}
		}
		if dt > 10 && can_stop
			continue;
		if norm(it.velocity) < 0.01
			continue;


		model := get_model(scene.client.store, xx it.model_id);
		if model {
			part := model.parts[it.part_idx];
			body.p = it.position;
			body.v = it.velocity;
			body.w = it.w;
			body.q = it.q;
			body.I = part.I;
			body.Ii = part.Iinv;
			body.m = part.M;
			if scene.client.clock > it.birthtime + 1 {
				body.collide = true;
				body.collide_factor = smoothstep(
					scene.client.clock.(float32), it.birthtime + 1, it.birthtime + 2
				);
			}

			body.half_size = it.half_size * scale;
			body.user_idx = it_index;
			world.bodies[body_cursor] = body;
			body_cursor += 1;
		}
	}
	world.bodies.count = body_cursor;

	XPBD.step(*world, dt);

	for world.bodies {
		if it.user_idx < 0
			continue;

		debri := *scene.debris[it.user_idx];
		debri.position = it.p;
		debri.velocity = it.v;
		debri.q = it.q;
		debri.w = it.w;
	}
}

update_particles :: (scene: *Scene, dt: float32) {
	for * scene.particles {
		it.position += it.velocity * dt;
		it.velocity.z -= 1.81 * it.gravity * dt;
		it.velocity *= (1.0 - clamp(it.drag * dt, 0.0, 1.0));
		if it.floor_bounce >= 0 {
			if it.position.z < 0.05 {
				it.position.z = 0.05;
				if it.velocity.z < 0 {
					it.velocity.z = -it.velocity.z;
					it.velocity *= it.floor_bounce;
				}
			}
		}
		it.age += dt;

		it.rotation += it.rotation_speed * dt;

		if it.age > it.lifetime {
			remove it;
		}
	}
}

activate_trigger :: (scene: *Scene, trigger_id: int) {
	table_set(*scene.trigger_activated, trigger_id, true);
}

win_level :: (scene: *Scene, player_id: int, time: Apollo_Time, result: *Frame_Result) {
	// for top: 0..winner.best_scores_id.count-1 {
	// 	best_score := -9999;
	// 	best_player_id := -1;
	// 	for scene.players {
	// 		already_in := false;
	// 		for idx: winner.best_scores_id {
	// 			if idx == it.id {
	// 				already_in = true;
	// 				break;
	// 			}
	// 		}
	// 		if already_in
	// 			continue;

	// 		if it.server.score.score > best_score {
	// 			best_score = it.server.score.score;
	// 			best_player_id = it.id;
	// 		}
	// 	}

	// 	if best_player_id >= 0 {
	// 		winner.best_scores_id[top] = best_player_id;
	// 	} else {
	// 		break;
	// 	}
	// }

	if result {
		winner: Command.End_Level;
		winner.winner_id = player_id;
		winner.next_level_scheduled_in_seconds = 6;
		winner.next_scene_id = scene.next_id;
		winner.time = scene.server.clock.(float32);

		best_death := -1;
		best_revive := -1;
		for scene.players {
			if winner.most_death_id < 0 || it.server.death_count > best_death {
				best_death = it.server.death_count;
				winner.most_death_id = it.id;
			}
			if winner.most_revive_id < 0 || it.server.revive_count > best_revive {
				best_revive = it.server.revive_count;
				winner.most_revive_id = it.id;
			}
		}

		scene.client.end_level = winner;
		array_add(*result.end_level, winner);
	}

	scene.end_scene_countdown_started = true;
	scene.end_scene_countdown_time = time;
	scene.end_scene_countdown = 6;

	for * scene.players {
		if it.server.dead {
			spawn_into(it, scene);

			for tomb: scene.tombstones {
				if tomb.player_id == it.id {
					remove tomb;
				}
			}
		}
	}

	if result
		array_add(*result.win_player_id, player_id);
}

player_has_revived_other_player :: (
	scene: *Scene, reviver: int, revived: int, result: *Frame_Result
) {
	player := find_by_player_id(scene, reviver);
	if player {
		player.server.souls += 1;
	}

	if result
		array_add(*result.revived_someone_player_id, reviver);
	
}

drop_keys :: (scene: *Scene, player: *Player) {
	for * scene.keys {
		if it.holder == player.id {
			it.holder = -1;
			it.server.last_hold_clock = scene.server.clock;
		}
	}
}

drop_bomb :: (scene: *Scene, bomb: *Bomb) {
	bomb.holder = -1;
	bomb.server.time = 0;
	bomb.client.time = 0;
	bomb.server.dropped_clock = xx scene.server.clock;
}
drop_bombs :: (scene: *Scene, player: *Player) {
	for * scene.bombs {
		if it.holder == player.id
			drop_bomb(scene, it);
	}
}

client_die :: (scene: *Scene, player: *Player, at: V3f, die_source: V3f, die_strength: float32) {
	player.server.dead = true;
	player.server.dead_time = xx scene.server.clock;
	player.server.has_safe_present = false;
	player.server.has_hook_present = 0;
	tombstone: Tombstone;
	tombstone.player_id = player.id;
	tombstone.position = at;

	if player.id == scene.controlled_player_id {
		trigger: Sound_Trigger;
		trigger.kind = .Loser;
		trigger.position = at;
		array_add(*scene.sound_triggers, trigger);
	}

	gravestone: Gravestone;
	gravestone.player_id = player.id;
	gravestone.position = at;
	array_add(*scene.gravestones, gravestone);

	array_add(*scene.tombstones, tombstone);
	drop_debris(scene, player, die_source, die_strength);
}

drop_debris :: (scene: *Scene, player: *Player, die_source: V3f, die_strength: float32) {
	model := get_model(scene.client.store, xx player.server.model_id);
	if model {
		for model.parts {
			debris: Debris;
			debris.part_idx = it_index;
			debris.model_id = player.server.model_id;
			debris.velocity = v3(
				Rand.random_uniform(*scene.client_rng, -1.0, 1.0),
				Rand.random_uniform(*scene.client_rng, -1.0, 1.0),
				Rand.random_uniform(*scene.client_rng, 1.0, 2.0),
			);
			debris.velocity = normalize(debris.velocity);
			debris.velocity += normalize(player.client.delta_frame_position) * 2;
			debris.position = player.client.position + debris.origin;
			debris.position.z += 0.5;

			if die_source.x != FLOAT32_MAX {
				debris.velocity += normalize(debris.position - die_source) * die_strength;
			}

			debris.half_size = (it.max - it.min) / 2;
			debris.origin = (it.max + it.min) / 2;
			debris.birthtime = xx scene.client.clock;
			debris.q = from_unit_vectors(
				normalize(v3(1.0, 0.0, Rand.random_uniform(*scene.client_rng, 0.0, 1.0))),
				player.client.direction
			);
			array_add(*scene.debris, debris);
		}
	}
}

server_die :: (
	scene: *Scene,
	player: *Player,
	time: Apollo_Time,
	result: *Frame_Result,
	should_die_source: V3f,
	should_die_strength: float32
) {
	player.server.has_safe_present = false;
	player.server.has_hook_present = 0;

	drop_keys(scene, player);
	drop_bombs(scene, player);

	if scene.auto_revive {
		respawn: Command.Respawn;
		respawn.player_id = player.id;
		array_add(*result.respawn, respawn);
		spawn_into(player, scene);
	} else {
		died: Command.Die;
		died.player_id = player.id;
		died.position = player.server.position;
		died.explode_source = should_die_source;
		died.explode_strength = should_die_strength;
		array_add(*result.died, died);
		player.server.dead = true;
		player.server.dead_time = xx scene.server.clock;
		player.server.souls = 0;

		if result {
			array_add(*result.died_player_id, player.id);
		}

		tombstone: Tombstone;
		tombstone.player_id = died.player_id;
		tombstone.position = died.position;

		array_add(*scene.tombstones, tombstone);
	}

	any_alive := false;
	for scene.players {
		if !it.server.dead {
			any_alive = true;
			break;
		}
	}

	if result {
		if !any_alive {
			array_add(*result.wipe_scene, .{});
			result.restarted = true;
			restart(scene, scene.params);
		}
	}
}

update :: (scene: Scene, turn_table: *Turn_Table, dt: float32) {
	angle := get_pointing_angle(scene, turn_table);
	p := turn_table.position;
	for * scene.players {
		q := it.server.position;

		d := norm(p - q);
		if d < 0.5 {
			// angle = 4.0;
			direction: V3f;
			direction.x = cos(angle);
			direction.y = sin(angle);
			direction.z = 0;

			if it.server.slipping {
				it.server.target_direction = direction;
			}
		}
	}
}

update :: (scene: Scene, antiair: *AntiAir, dt: float32) {
	antiair.server.t += dt;
	antiair.client.t += dt;
	antiair.client.t = damp(antiair.client.t, antiair.server.t, 10.0, dt);
	if 0.1 < antiair.client.t && antiair.client.t + 1 < antiair.cooldown
		antiair.client.next_target = antiair.server.next_target;
	if antiair.client.t > antiair.cooldown {
		antiair.client.t = 0.0;
	}

	if scene.is_server {
		if antiair.server.t > antiair.cooldown {
			antiair.server.t = 0.0;
			antiair.just_shooted = true;
			antiair.server.curr_target = antiair.server.next_target;
			antiair.server.next_target = .{ FLOAT32_MAX, FLOAT32_MAX };
		}
	}

	if antiair.server.next_target.x == FLOAT32_MAX {
		x := Rand.random_uniform(*scene.server_rng, -0.5, +0.5);
		y := Rand.random_uniform(*scene.server_rng, -0.5, +0.5);
		x *= width(antiair.target_aabb);
		y *= height(antiair.target_aabb);
		x += antiair.target_aabb.min.x;
		y += antiair.target_aabb.min.y;
		antiair.server.next_target = .{ x, y };
	}
}

// https://rodolphe-vaillant.fr/entry/114/cyclic-coordonate-descent-inverse-kynematic-ccd-ik
update :: (scene: Scene, robot: *Robot, time: Apollo_Time, dt: float32) {

	player := find_by_player_id(scene, robot.player_targeted_id);
	if !player {
		robot.player_targeted_id = -1;
	} else {
		p := v2(player.server.position);
		if !in(robot.target_aabb, p) {
			robot.player_targeted_id = -1;
		}
	}

	if robot.player_targeted_id < 0 {
		elligibles := NewArray(scene.players.count, int, false,, temp);
		elligibles.count = 0;
		for scene.players {
			if it.server.dead
				continue;

			p := v2(it.server.position);
			if in(robot.target_aabb, p) {
				elligibles.count += 1;
				elligibles[elligibles.count - 1] = it.id;
			}
		}

		if elligibles.count > 0 {
			idx := Rand.random_uniform(*scene.server_rng, 0, elligibles.count);
			robot.player_targeted_id = elligibles[idx];
		}
	}

	player = find_by_player_id(scene, robot.player_targeted_id);
	if !player {
		t := to_float64_seconds(time).(float32);
		robot.axes[0] += sin(t * 0.5) * 0.2 * dt;
		robot.axes[1] += sin(t * 0.7) * 0.3 * dt;
		robot.axes[2] += sin(t * 0.9) * 0.4 * dt;
		robot.axes[3] += sin(t * 1.1) * 0.5 * dt;
		robot.axes[4] += sin(t * 1.3) * 0.6 * dt;
		robot.player_targeted_id = -1;
		robot.shooting_time = robot.shooting_offset;
		return;
	}
	robot.shooting_time += dt;
	if robot.shooting_time > robot.shooting_cd {
		if robot.shooting_time > (robot.shooting_cd + robot.charging_time + robot.effectshoot_time)
		{
			robot.shooted = false;
			robot.shooting_time = 0.0;
		}
		else if robot.shooting_time > (robot.shooting_cd + robot.charging_time) {

			if !robot.shooted {
				robot.shooted = true;
				robot.just_shooted = true;
				robot.player_targeted_id = -1;
			}
		}
		// Stay in place if we are just after shooting
		return;
	}

	target := player.server.position;
	target += player.server.direction * player.server.speed * robot.predict;

	og_target := target;
	target.z = 2.0;
	
	T := target;

	N :: 10;
	for 1..N {
		for < 1..5 {
			E := robot_pivot(robot, 6);
			Oi := robot_pivot(robot, it);
			ti := normalize(T - Oi);
			if it > 1 {
				ti = normalize(og_target - Oi);
			}
			ei := normalize(E - Oi);

			rotate_effector_to_target := from_unit_vectors(ei, ti);

			hinge_axis := robot_joint_axis(it);
			Mi := robot_to_axis(robot, it);
			hinge_axis = v3(Mi * V4f.{ hinge_axis.x, hinge_axis.y, hinge_axis.z, 0 });

			unconstrained_hinge_axis := rotate_effector_to_target * hinge_axis;
			constraint := from_unit_vectors(unconstrained_hinge_axis, hinge_axis);

			constrained_rotation := constraint * rotate_effector_to_target;

			a, r := to_axis_angle(constrained_rotation);
			if dot(a, hinge_axis) < 0 {
				r = -r;
			}

			r = clamp(r, -robot.max_rotation_speed * dt, robot.max_rotation_speed * dt);
			robot.axes[it - 1] += r;

			robot.axes[it - 1] = clamp(robot.axes[it - 1], -1.5, +1.5);
		}

	}

}

update :: (scene: Scene, button: *PressButton, dt: float32, result: *Frame_Result) {
	if !button.activated {
		p := v2(button.position);

		count := 0;
		for scene.players {
			if it.server.dead
				continue;

			q := v2(it.server.position);
			if p.x - 0.5 <= q.x && q.x <= p.x + 0.5
			if p.y - 0.5 <= q.y && q.y <= p.y + 0.5 {
				count += 1;
			}
		}

		if (count * 1.5).(s64) >= scene.players.count && scene.players.count > 0 {
			button.activated = true;
			button.activated_juice_t = 1.0;
			
			sound: Sound_Trigger;
			sound.position = button.position;
			sound.kind = .Checkpoint_Ok;
			array_add(*scene.sound_triggers, sound);

		}

		if button.last_player_count != count {
			button.count_changed_juice_t = 1.0;
		}
		button.last_player_count = count;
	}

	if button.is_radio {
		p := v2(button.position);

		count := 0;
		for scene.players {
			if it.server.dead
				continue;

			q := v2(it.server.position);
			if p.x - 0.5 <= q.x && q.x <= p.x + 0.5
			if p.y - 0.5 <= q.y && q.y <= p.y + 0.5 {
				count += 1;
				break;
			}
		}

		if count > 0 {
			if !button.activated {
				button.activated = true;
				button.activated_juice_t = 1.0;
				
				sound: Sound_Trigger;
				sound.position = button.position;
				sound.kind = .Checkpoint_Ok;
				array_add(*scene.sound_triggers, sound);
			}
		} else {
			button.activated = false;
		}
	}

}

update :: (scene: Scene, flag: *Flag, dt: float32, result: *Frame_Result) {
	if !flag.activated {
		p := v2(flag.position);

		count := 0;
		for scene.players {
			if it.server.dead
				continue;

			q := v2(it.server.position);
			d := norm(p - q);

			if d < flag.radius {
				count += 1;
			}
		}

		if (count * 1.5).(s64) >= scene.players.count && scene.players.count > 0 {
			flag.activated = true;
			flag.activated_juice_t = 1.0;
			
			sound: Sound_Trigger;
			sound.position = flag.position;
			sound.kind = .Checkpoint_Ok;
			array_add(*scene.sound_triggers, sound);

		}

		if flag.last_player_count != count {
			flag.count_changed_juice_t = 1.0;
		}
		flag.last_player_count = count;
	}

	if flag.activated_juice_t > 0 {
		flag.activated_juice_t -= dt;
	}
	if flag.count_changed_juice_t > 0 {
		flag.count_changed_juice_t -= dt;
	}
}

update :: (scene: *Scene, within: *Within_Zone, dt: float32) {
	n_players := 0;
	for scene.players {
		if it.server.dead
			continue;

		p := v2(it.server.position);
		if p.x >= within.pos.x
		&& p.x <= within.pos.x + within.size.x
		&& p.y >= within.pos.y
		&& p.y <= within.pos.y + within.size.y {
			n_players += 1;
		}
	}

	if within.last_player_count != n_players {
		within.count_changed_juice_t = 1.0;
	}
	within.last_player_count = n_players;

	required := ceil(scene.players.count * within.min_player_percent).(int);
	if n_players >= required && required > 0 {
		within.time_stayed += dt;
	} else if within.time_stayed < within.time_to_stay {
		within.time_stayed -= dt * 2.0;
		if within.time_stayed < 0.0
			within.time_stayed = 0.0;
	}

	if within.count_changed_juice_t > 0 {
		within.count_changed_juice_t -= dt;
	}

	if within.time_stayed >= within.time_to_stay && within.trigger_id != -1 {
		activate_trigger(scene, within.trigger_id);
		within.trigger_id = -1;
	}
}

update :: (scene: Scene, shuriken: *Shuriken, dt: float32) {
	shuriken.client.theta += shuriken.client.theta_speed * dt;
}

update :: (scene: Scene, frame: *Moving_Frame, dt: float32) {
	frame.sum_period = 0.0;
	for 1..frame.keys.count - 1 {
		frame.sum_period += scene.moving_frame_keys[it + frame.keys.index - 1].period;
	}
}

find_closest_point_on_rail :: (scene: Scene, rail: Camera_Rail, position: V3f) -> V3f, int, float {
	// Find the closest point on the rail to the given position
	// Returns: closest point, segment index, progress [0, 1] along that segment

	waypoints := iterator(rail.waypoints, scene.camera_rail_waypoints);

	closest_point: V3f;
	closest_distance := FLOAT32_MAX;
	best_segment := 0;
	best_progress := 0.0;

	prev_waypoint: V3f;
	first := true;
	segment_idx := 0;

	for waypoint: waypoints {
		if !first {
			// Project position onto line segment between prev_waypoint and waypoint
			segment_dir := waypoint - prev_waypoint;
			segment_length := norm(segment_dir);

			if segment_length > 0.001 {
				segment_dir_norm := segment_dir / segment_length;
				to_pos := position - prev_waypoint;
				projection := dot(to_pos, segment_dir_norm);

				// Clamp to segment
				t := clamp(projection / segment_length, 0.0, 1.0);
				point_on_segment := prev_waypoint + segment_dir * t;

				dist := norm(position - point_on_segment);
				if dist < closest_distance {
					closest_distance = dist;
					closest_point = point_on_segment;
					best_segment = segment_idx;
					best_progress = t;
				}
			}

			segment_idx += 1;
		}
		first = false;
		prev_waypoint = waypoint;
	}

	return closest_point, best_segment, best_progress;
}

find_closest_poi :: (scene: Scene, position: V3f, max_distance: float = 3.0) -> *Camera_POI, float {
	// Find the closest POI within max_distance
	closest_poi: *Camera_POI = null;
	closest_distance := max_distance;

	for * scene.camera_pois {
		dist := norm(position - it.position);
		if dist < closest_distance {
			closest_distance = dist;
			closest_poi = it;
		}
	}

	return closest_poi, closest_distance;
}

update_camera_locked :: (scene: Scene, camera: *Camera, player_locked: *Player, dt: float32) {
	camera.target_target = player_locked.client.position;
	camera.distance_target = camera.locked_nominal_distance;
}

update :: (scene: Scene, camera: *Camera, dt: float32) {
	player_locked := find_by_player_id(scene, camera.locked_to);
	curr_distance := norm(camera.position - camera.target);

	if player_locked && camera.locked && !player_locked.server.dead {
		update_camera_locked(scene, camera, player_locked, dt);
	}

	// Restrict target target
	camera.target_target.x = clamp(
		camera.target_target.x,
		scene.camera_min.x - 0.2,
		scene.camera_max.x + 0.2
	);
	camera.target_target.y = clamp(
		camera.target_target.y,
		scene.camera_min.y - 0.2,
		scene.camera_max.y + 0.2
	);
	camera.distance_target = clamp(
		camera.distance_target,
		camera.locked_nominal_distance * 0.25,
		camera.max_distance
	);

	distance := damp(curr_distance, camera.distance_target, 10.0, dt);
	camera.target = damp(camera.target, camera.target_target, 50.0, dt);
	camera.position = camera.target + camera.delta_unit * distance;

	camera.position.x = clamp(
		camera.position.x,
		scene.camera_min.x + camera.delta_unit.x * distance / 1.05,
		scene.camera_max.x + camera.delta_unit.x * distance / 1.05
	);
	camera.position.y = clamp(
		camera.position.y,
		scene.camera_min.y + camera.delta_unit.y * distance / 1.05,
		scene.camera_max.y + camera.delta_unit.y * distance / 1.05
	);

	// Renormalize the distance to the target after clamping
	{
		dt := camera.position - camera.target;
		dt = normalize(dt) * distance;
		camera.position = camera.target + dt;
	}
}

update :: (scene: Scene, skull: *Skull, dt: float32) {
	if !scene.is_server
		interpolate_to_server(skull);

	dir := compute_skull_dir(scene, skull);
	skull.client.direction = damp_angle_between(skull.client.direction, dir, 20.0, dt);
}

update :: (scene: Scene, coin: *Coin, dt: float32) {
	coin.server.position += coin.server.speed * coin.server.direction * dt;
	coin.client.position += coin.server.speed * coin.server.direction * dt;
	coin.client.theta += xx (3.1415926 * 2.0 * dt);
}

update :: (scene: Scene, player: *Player, dt: float32) {
	og_pos := player.client.position;
	defer {
		player.client.delta_frame_position = player.client.position - og_pos;
	}

	if !scene.is_server
		interpolate_to_server(player, dt);

	if player.server.dead
		return;

	// If we are hooked, there is no movement update to do.
	for scene.hooks {
		if it.hooked_id == player.id {
			return;
		}
	}

	tile, ok := tile_under(scene, player.server.position);
	if !ok {
		return;
	}

	// Let's see if we are still on a tile of the same kind of our confirmed tile.
	is_still_on := touch_a_tile(
		scene,
		player.server.position,
		player.server.radius_hitbox_confirmed,
		player.server.confirmed_tile
	);

	// If we aren't then we switch to the tile we are currently on.
	if !is_still_on {
		if #complete tile.kind == {
			case .Ice; #through;
			case .Funny_Ice;
				player.server.slipping = true;
				player.server.walking_toward = false;
			case .Slippy_Ice;
				player.server.slipping = true;
				player.server.walking_toward = false;
				player.server.target_direction = player.server.direction;
			case .Dirt; #through;
			case .Grass;
				player.server.slipping = false;
			case .None;
		}
		player.server.confirmed_tile = tile.kind;
	}

	if player.server.slipping {
		dt_angle := angle_between(
			player.server.direction, player.server.target_direction, V3f.{ 0, 0, 1 }
		);
		turn_angle := 0.0;
		if dt_angle < 0
			turn_angle = -min(player.server.turning_speed * dt * DEG_RAD, -dt_angle);
		else
			turn_angle = min(player.server.turning_speed * dt * DEG_RAD, dt_angle);

		q := axis_angle(V3f.{ 0, 0, 1 }, turn_angle);
		player.server.direction = q * player.server.direction;
		player.server.direction = normalize(player.server.direction);

		wanted_position :=
			player.server.position + player.server.direction * player.server.speed * dt;

		if can_execute_player_motion(scene, player.server.position, wanted_position, player)
			player.server.position = wanted_position;
	} else {
		player.server.direction = player.server.target_direction;

		if player.server.walking_toward {
			dt_pos := player.server.walking_toward_position - player.server.position;
			dist := norm(dt_pos);
			dt_pos = normalize(dt_pos);

			dist = min(dist, player.server.speed * dt);
			wanted_position := player.server.position + dt_pos * dist;
			if can_execute_player_motion(scene, player.server.position, wanted_position, player)
				player.server.position = wanted_position;
			player.server.target_direction = dt_pos;

			if norm(player.server.position - player.server.walking_toward_position) < 0.01 {
				player.server.walking_toward = false;
				player.server.walking_toward_position = player.server.position;
			}
		}
	}
}

buy_ask :: (scene: *Scene, player_id: int, result: *Process_Response) {
	player := find_by_player_id(scene, player_id);
	if !player
		return;

	if player.server.dead
		return;

	closest_present: *Present = null;
	closest_d := FLOAT32_MAX;
	for * scene.presents {
		if !it.server.available
			continue;
		
		d := norm(player.server.position - it.position);
		if d < closest_d {
			closest_d = d;
			closest_present = it;
		}
	}

	if closest_present {
		if closest_d < player.server.radius_hitbox_key {
			command: Command.Buy_Ask;
			command.player_id = player.id;
			command.present_id = closest_present.id;
			command.item_kind = closest_present.kind;
			add(result, scene.id, command);
			
			// if player.server.score.points >= closest_present.server.cost {
			// 	player.server.score.points -= closest_present.server.cost;

			// 	if closest_present.server.kind == .Safe_Zone_Present {
			// 		player.server.has_safe_present = true;
			// 	} else if closest_present.server.kind == .Hook_Present {
			// 		player.server.has_hook_present += 1;
			// 	}

			// 	closest_present.server.available = false;

			// 	add(result, scene.id, make_sync(player));
			// 	add(result, scene.id, make_sync(*closest_present));
			// }
		}
	}
}

can_execute_player_motion :: (scene: Scene, a: V3f, b: V3f, player: *Player) -> bool {
	for * scene.gates {
		if it.is_closed {
			d := norm(b - it.position);

			if d < 1.0 {
				if it.wait_for_key_id >= 0 {
					key := find_by_key_id(scene, it.wait_for_key_id);
					if key && key.holder == player.id {
						return true;
					}
				} else {
					return false;
				}

				return false;
			}
		}
	}
	for * scene.block_rocks {
		if it.exploded
			continue;
		d := norm(b - it.position);

		if d < 0.6 {
			return false;
		}
	}
	return true;
}

process_server_only :: (
	scene: *Scene, command: Command, time: Apollo_Time, response: *Process_Response
) -> bool {
	if !scene.is_server
		return false;

	buy_ask: *Command.Buy_Ask = isa(command.payload, Command.Buy_Ask);
	if buy_ask {
		player := find_by_player_id(scene, buy_ask.player_id);
		present := find_by_present_id(scene, buy_ask.present_id);

		if player && present {
			if !player.server.dead && present.server.available {
				if present.kind == .A && player.server.has_safe_present {
					buy_response: Command.Buy_Response;
					buy_response.player_id = player.id;
					buy_response.present_id = present.id;
					buy_response.item_kind = present.kind;
					buy_response.success = false;
					buy_response.why = .Already_Have_Item;
					add_single_reply(response, player.id, buy_response);
				}
				else if present.kind == .B && player.server.has_hook_present > 2 {
					buy_response: Command.Buy_Response;
					buy_response.player_id = player.id;
					buy_response.present_id = present.id;
					buy_response.item_kind = present.kind;
					buy_response.success = false;
					buy_response.why = .Already_Have_Item;
					add_single_reply(response, player.id, buy_response);
				}
				else {
					cost := 1;
					if present.kind == .A {
						cost = 1;
					} else if present.kind == .B {
						cost = 2;
					}

					if player.server.souls >= cost {
						player.server.souls -= cost;

						if present.kind == .A {
							player.server.has_safe_present = true;
						} else if present.kind == .B {
							player.server.has_hook_present += 1;
						}

						sync_score: Command.Sync_Score;
						sync_score.player_id = player.id;
						sync_score.souls = player.server.souls;
						add_single_reply(response, player.id, sync_score);

						add_single_reply(response, player.id, make_sync(player));
					} else {
						buy_response: Command.Buy_Response;
						buy_response.player_id = player.id;
						buy_response.present_id = present.id;
						buy_response.item_kind = present.kind;
						buy_response.success = false;
						buy_response.why = .Not_Enough_Points;
						add_single_reply(response, player.id, buy_response);
					}
				}
			}
			return true;
		}
	}

	signal_pick: *Command.Signal_Pick = isa(command.payload, Command.Signal_Pick);
	if signal_pick {
		cmd: Command.Signal_Pick;
		cmd.pos = signal_pick.pos;
		add(response, scene.id, cmd);
		return true;
	}

	ask_respawn: *Command.Ask_Respawn = isa(command.payload, Command.Ask_Respawn);
	if ask_respawn {
		player := find_by_player_id(scene, ask_respawn.player_id);
		if player {
			if player.server.dead {
				dt := scene.server.clock - player.server.dead_time;
				if dt.(float32) >= player.server.dead_cooldown.(float32) {
					player.server.need_respawn = true;
				}
			}
			return true;
		}
	}

	klaxon: *Command.Klaxon = isa(command.payload, Command.Klaxon);
	if klaxon {
		player := find_by_player_id(scene, klaxon.player_id);
		if player {
			add(response, scene.id, klaxon.*);
			return true;
		}
	}

	drop: *Command.Drop = isa(command.payload, Command.Drop);
	if drop {
		bomb := find_bomb_by_holder_id(scene, drop.player_id);
		if bomb {
			drop_bomb(scene, bomb);
			add(response, scene.id, drop.*);
			return true;
		}
	}

	spawn_coin: *Command.Spawn_Coin = isa(command.payload, Command.Spawn_Coin);
	if spawn_coin {
		player := find_by_player_id(scene, spawn_coin.sender);
		if player {
			coin: Coin;
			coin.id = scene.coin_generation;
			coin.sender = player.id;
			coin.server.position = player.server.position;
			coin.server.direction = V3f.{ 0, 0, 0 };
			coin.server.birthtime = scene.server.clock;
			if player.server.slipping
				coin.server.direction = player.server.direction;
			array_add(*scene.coins, coin);

			cmd: Command.Spawn_Coin;
			cmd.id = coin.id;
			cmd.sender = coin.sender;
			cmd.position = coin.server.position;
			cmd.direction = coin.server.direction;
			cmd.birthtime = coin.server.birthtime.(float32);
			add(response, scene.id, cmd);

			scene.coin_generation += 1;
			return true;
		}
	}

	active_item: *Command.Active_Item = isa(command.payload, Command.Active_Item);
	if active_item {
		player := find_by_player_id(scene, active_item.player_id);
		if player {
			if active_item.safe_zone {
				if !player.server.dead && player.server.has_safe_present {
					sz: Safe_Zone;
					sz.id = scene.generation;
					scene.generation += 1;
					tile := position_to_tile(scene, player.server.position);
					sz.position = tile_center(scene, tile);
					sz.radius = sqrt(2) / 2;
					sz.expire = 3;
					array_add(*scene.safe_zones, sz);

					player.server.has_safe_present = false;
					add(response, scene.id, make_sync(player));
					add(response, scene.id, make_sync(*sz));
				}
				return true;
			}
			if active_item.hook {
				if !player.server.dead && player.server.has_hook_present > 0 {
					hook: Hook;
					hook.id = scene.generation;
					scene.generation += 1;
					hook.hooker_id = player.id;
					hook.hooked_id = -1;
					hook.server.direction = player.server.direction;
					hook.server.last_anchor_position = player.server.position;
					hook.server.length = 0.0;
					array_add(*scene.hooks, hook);

					player.server.has_hook_present -= 1;
					add(response, scene.id, make_sync(player));
					add(response, scene.id, make_sync(*hook));
				}
			}
		}
	}

	return false;
}

process_client_only :: (
	scene: *Scene, command: Command, time: Apollo_Time, response: *Process_Response
) -> bool {
	clock_sync: *Command.Sync_Clock = isa(command.payload, Command.Sync_Clock);
	if clock_sync {
		scene.server.clock = clock_sync.t;
		return true;
	}

	buy_response: *Command.Buy_Response = isa(command.payload, Command.Buy_Response);
	if buy_response {
		if buy_response.player_id == scene.controlled_player_id {
			if !buy_response.success {
				if #complete buy_response.why == {
					case .Already_Have_Item;
						array_add(*scene.news, sprint("You already have this item."));
					case .Not_Enough_Points;
						array_add(*scene.news, sprint("Not enough souls to buy item."));
					case .Too_Far;
						array_add(*scene.news, sprint("You are too far away."));
				}
			}
		}
		return true;
	}
	
	signal_pick: *Command.Signal_Pick = isa(command.payload, Command.Signal_Pick);
	if signal_pick {
		new: Scene.Pick;
		new.pos = signal_pick.pos;
		new.birthtime = xx scene.client.clock;
		array_add(*scene.signal_picks, new);
	}

	get_terrain_leaderboard := isa(command.payload, Command.Get_Terrain_Leaderboard);
	if get_terrain_leaderboard {
		scene.client.leaderboard = get_terrain_leaderboard.*;
		scene.client.leaderboard.wr_username = sprint(
			"%",
			scene.client.leaderboard.wr_username,,
			Allocator.{ pool_allocator_proc, *scene.run_pool }
		);
		scene.client.leaderboard_run_counter = scene.run_generation;
		return true;
	}

	wipe_scene: *Command.Wipe_Scene = isa(command.payload, Command.Wipe_Scene);
	if wipe_scene {
		scene.fade_screen.start = time;
		scene.state = .Wipe_Fade_In;
		return true;
	}
	spawn_coin: *Command.Spawn_Coin = isa(command.payload, Command.Spawn_Coin);
	if spawn_coin {
		coin: Coin;
		coin.id = spawn_coin.id;
		coin.sender = spawn_coin.sender;
		coin.server.position = spawn_coin.position;
		coin.server.direction = spawn_coin.direction;
		coin.client.position = spawn_coin.position;
		coin.server.birthtime = spawn_coin.birthtime;
		array_add(*scene.coins, coin);

		trigger: Sound_Trigger;
		trigger.kind = .Coin_Launch;
		trigger.position = spawn_coin.position;
		array_add(*scene.sound_triggers, trigger);
		return true;
	}
	died: *Command.Die = isa(command.payload, Command.Die);
	if died {
		player := find_by_player_id(scene, died.player_id);
		if player
		{
			client_die(scene, player, died.position, died.explode_source, died.explode_strength);
			return true;
		}
	}

	sync_tombstone: *Command.Sync_Tombstone = isa(command.payload, Command.Sync_Tombstone);
	if sync_tombstone {
		tombstone := find_tombstone_by_player_id(scene, sync_tombstone.player_id);
		if tombstone {
			tombstone.position = sync_tombstone.position;
			return true;
		}
		else {
			tombstone: Tombstone;
			tombstone.player_id = sync_tombstone.player_id;
			tombstone.position = sync_tombstone.position;
			array_add(*scene.tombstones, tombstone);
			return true;
		}
	}

	sync_hook: *Command.Sync_Hook = isa(command.payload, Command.Sync_Hook);
	if sync_hook {
		hook := find_by_hook_id(scene, sync_hook.hook_id);
		if hook {
			hook.server.last_anchor_position = sync_hook.last_anchor_position;
			hook.server.direction = sync_hook.direction;
			hook.hooker_id = sync_hook.hooker_id;
			hook.hooked_id = sync_hook.hooked_id;
			hook.server.length = sync_hook.length;
		} else {
			hook: Hook;
			hook.id = sync_hook.hook_id;
			hook.hooker_id = sync_hook.hooker_id;
			hook.hooked_id = sync_hook.hooked_id;
			hook.server.last_anchor_position = sync_hook.last_anchor_position;
			hook.server.direction = sync_hook.direction;
			hook.server.length = sync_hook.length;
			array_add(*scene.hooks, hook);
		}
		return true;
	}

	sync_safe_zone: *Command.Sync_Safe_Zone = isa(command.payload, Command.Sync_Safe_Zone);
	if sync_safe_zone {
		sz := find_by_safe_zone_id(scene, sync_safe_zone.id);
		if sz {
			sz.position = sync_safe_zone.position;
			sz.radius = sync_safe_zone.radius;
			sz.expire = sync_safe_zone.expire;
			if sz.expire {
				for * scene.safe_zones {
					if it == sz {
						remove it;
						break;
					}
				}
			}
			return true;
		}
		else {
			sz: Safe_Zone;
			sz.id = sync_safe_zone.id;
			sz.position = sync_safe_zone.position;
			sz.radius = sync_safe_zone.radius;
			sz.expire = sync_safe_zone.expire;
			array_add(*scene.safe_zones, sz);
			return true;
		}
	}

	sync_score: *Command.Sync_Score = isa(command.payload, Command.Sync_Score);
	if sync_score {
		player := find_by_player_id(scene, sync_score.player_id);
		if player {
			player.server.souls = sync_score.souls;
		}
		return true;
	}

	sync_standin: *Command.Sync_Stand_In = isa(command.payload, Command.Sync_Stand_In);
	if sync_standin {
		standin := find_by_standin_id(scene, sync_standin.standin_id);
		if standin {
			standin.retired = sync_standin.retired;
		}
		return true;
	}

	sync_gate: *Command.Sync_Gate = isa(command.payload, Command.Sync_Gate);
	if sync_gate {
		for * scene.gates {
			if it.id == sync_gate.gate_id {
				it.is_closed = sync_gate.is_closed;
				return true;
			}
		}
	}

	sync_robot: *Command.Sync_Robot = isa(command.payload, Command.Sync_Robot);
	if sync_robot {
		robot := find_by_robot_id(scene, sync_robot.robot_id);
		if robot {
			robot.shooting_time = sync_robot.shooting_time;
			robot.position = sync_robot.position;
			robot.shooting_cd = sync_robot.shooting_cd;
			return true;
		}
	}

	sync_antiair: *Command.Sync_AntiAir = isa(command.payload, Command.Sync_AntiAir);
	if sync_antiair {
		antiair := find_by_antiair_id(scene, sync_antiair.id);
		if antiair {
			antiair.server.t = sync_antiair.t;
			antiair.client.t = antiair.server.t;
			antiair.cooldown = sync_antiair.cooldown;
			antiair.position = sync_antiair.position;
			antiair.target_aabb = sync_antiair.target_aabb;
			antiair.server.next_target = sync_antiair.next_target;
			return true;
		}
	}

	sync_present: *Command.Sync_Present = isa(command.payload, Command.Sync_Present);
	if sync_present {
		present := find_by_present_id(scene, sync_present.present_id);
		if present {
			present.position = sync_present.position;
			present.kind = xx sync_present.kind;
			present.server.available = sync_present.available;
			return true;
		}
		else {
			new_present: Present;
			new_present.id = sync_present.present_id;
			new_present.position = sync_present.position;
			new_present.kind = xx sync_present.kind;
			new_present.server.available = sync_present.available;
			array_add(*scene.presents, new_present);
			return true;
		}
	}

	sync_bomb: *Command.Sync_Bomb = isa(command.payload, Command.Sync_Bomb);
	if sync_bomb {
		bomb := find_by_bomb_id(scene, sync_bomb.bomb_id);
		if bomb {
			bomb.server.position = sync_bomb.position;
			bomb.server.time = sync_bomb.time;
			bomb.holder = sync_bomb.holder_id;
			bomb.last_holder = sync_bomb.last_holder_id;
			return true;
		} else {
			new_bomb: Bomb;
			new_bomb.id = sync_bomb.bomb_id;
			new_bomb.spawner_id = sync_bomb.bomb_spawner_id;
			new_bomb.holder = sync_bomb.holder_id;
			new_bomb.last_holder = sync_bomb.last_holder_id;
			new_bomb.server.position = sync_bomb.position;
			new_bomb.client.position = sync_bomb.position;
			new_bomb.server.time = sync_bomb.time;
			new_bomb.client.time = sync_bomb.time;
			array_add(*scene.bombs, new_bomb);
			return true;
		}
	}

	sync_bomb_spawner: *Command.Sync_Bomb_Spawner = isa(command.payload, Command.Sync_Bomb_Spawner);
	if sync_bomb_spawner {
		spawner := find_by_bomb_spawner_id(scene, sync_bomb_spawner.bomb_spawner_id);
		if spawner {
			spawner.spawned_id = sync_bomb_spawner.bomb_spawned_id;
			return true;
		}
	}

	anitiar_shoot: *Command.AntiAir_Shoot = isa(command.payload, Command.AntiAir_Shoot);
	if anitiar_shoot {
		antiair := find_by_antiair_id(scene, anitiar_shoot.antiair_id);
		if antiair {
			antiair.server.curr_target = antiair.server.next_target;
			antiair.server.next_target = anitiar_shoot.next_target;
			antiair.server.t = 0;
			antiair.client.t = 0;
			return true;
		}
	}

	end_level: *Command.End_Level = isa(command.payload, Command.End_Level);
	if end_level {
		scene.end_scene_countdown_time = time;
		scene.end_scene_countdown = end_level.next_level_scheduled_in_seconds;
		scene.end_scene_countdown_started = true;
		scene.next_id = end_level.next_scene_id;
		scene.client.end_level = end_level;

		get_leaderboard: Command.Get_Terrain_Leaderboard;
		get_leaderboard.terrain_id = scene.info.id;
		array_add(*scene.client_to_server, make_command(get_leaderboard));

		return true;
	}

	explode: *Command.Explode = isa(command.payload, Command.Explode);
	if explode {
		explosion: Explosion;
		explosion.position = explode.position;
		explosion.lifetime = explode.lifetime;
		explosion.max_size = explode.max_size;
		array_add(*scene.explosions, explosion);

		sound_trigger: Sound_Trigger;
		sound_trigger.kind = .Explosion;
		sound_trigger.position = explode.position;
		array_add(*scene.sound_triggers, sound_trigger);
		return true;
	}

	klaxon: *Command.Klaxon = isa(command.payload, Command.Klaxon);
	if klaxon {
		player := find_by_player_id(scene, klaxon.player_id);
		if player {
			sound_trigger: Sound_Trigger;
			sound_trigger.kind = .Car_Klaxon;
			sound_trigger.position = player.client.position;
			array_add(*scene.sound_triggers, sound_trigger);
		}
		return true;
	}

	drop: *Command.Drop = isa(command.payload, Command.Drop);
	if drop {
		bomb := find_bomb_by_holder_id(scene, drop.player_id);
		if bomb {
			drop_bomb(scene, bomb);
			return true;
		}
	}
	return false;
}

spawn_player :: (scene: *Scene, player_id: int, model_id: int) {
	player := find_by_player_id(scene, player_id);
	if !player {
		new_player: Player;
		new_player.id = player_id;
		array_add(*scene.players, new_player);
		player = *scene.players[scene.players.count - 1];
	}
	player.server.model_id = model_id;
	spawn_into(player, scene);
}

process :: (scene: *Scene, command: Command, time: Apollo_Time, response: *Process_Response) -> bool
{
	if scene.is_server && process_server_only(scene, command, time, response)
		return true;

	if !scene.is_server && process_client_only(scene, command, time, response)
		return true;

	spawn: *Command.Spawn = isa(command.payload, Command.Spawn);
	if spawn {
		if spawn.scene_id == scene.id {
			player := find_by_player_id(scene, spawn.player_id);

			if !player {
				new_player: Player;
				new_player.id = spawn.player_id;
				if spawn.model_id >= 0
					new_player.server.model_id = spawn.model_id;
				array_add(*scene.players, new_player);
				player = *scene.players[scene.players.count - 1];
				spawn_into(player, scene);
			}

			if spawn.its_you {
				scene.controlled_player_id = spawn.player_id;
				dt := scene.camera.position - scene.camera.target;
				scene.camera.target = player.server.position;
				scene.camera.position = scene.camera.target + dt;
				scene.camera.locked_to = scene.controlled_player_id;
			}

			return true;
		}
	}

	quit: *Command.Quit = isa(command.payload, Command.Quit);
	if quit {
		remove_player_from_scene(quit.player_id, scene);
		return true;
	}

	respawn: *Command.Respawn = isa(command.payload, Command.Respawn);
	if respawn {
		player := find_by_player_id(scene, respawn.player_id);
		if respawn.cause_player_id < 0
			drop_debris(scene, player, v3(FLOAT32_MAX, FLOAT32_MAX, FLOAT32_MAX), 0);

		pos := V3f.{ 0, 0, 0 };
		for * scene.tombstones {
			if it.player_id == respawn.player_id {
				pos = it.position;
				if player {
					spawn_into(player, scene);
				}
				remove it;
				break;
			}
		}

		coin := find_by_coin_id(scene, respawn.coin_id);
		if coin {
			for * scene.coins {
				if it.id == coin.id {
					remove it;
					break;
				}
			}
		}

		if respawn.cause_player_id >= 0 && !scene.is_server {
			trigger: Sound_Trigger;
			trigger.kind = .Res;
			trigger.position = pos;
			trigger.inhead = scene.controlled_player_id == respawn.cause_player_id;
			array_add(*scene.sound_triggers, trigger);
		}
	}

	for * scene.players {
		if process(scene, it, command, response)
			return true;
	}

	for * scene.skulls {
		if process(scene, it, command, response)
			return true;
	}

	for * scene.keys {
		if process(scene, it, command, response)
			return true;
	}
	return false;
}

process :: (scene: Scene, key: *Key, command: Command, response: *Process_Response) -> bool {
	sync: *Command.Sync_Key = isa(command.payload, Command.Sync_Key);
	if sync {
		if key.id == sync.key_id {
			key.server.position = sync.position;
			key.holder = sync.holder;
			return true;
		}
	}
	return false;
}

process :: (scene: Scene, skull: *Skull, command: Command, response: *Process_Response) -> bool {
	sync : *Command.Sync_Skull = isa(command.payload, Command.Sync_Skull);
	if sync {

		if skull.id == sync.skull_id {
			skull.server.offset = sync.offset;
			skull.server.speed = sync.speed;
			return true;
		}
	}
	return false;
}

process :: (scene: Scene, player: *Player, command: Command, response: *Process_Response) -> bool {
	move : *Command.Move = isa(command.payload, Command.Move);
	if move && move.player_id == player.id {
		if #complete player.server.confirmed_tile == {
			case .Ice;
				player.server.target_direction = normalize(
					v3(move.ground_target - v2(player.server.position))
				);
				player.server.walking_toward = false;
			case .Slippy_Ice;
			case .Grass;
				player.server.walking_toward = true;
				player.server.walking_toward_position = v3(move.ground_target);
			case .None;
			case .Dirt;
			case .Funny_Ice;
				player.server.target_direction = normalize(
					v3(v2(player.server.position) - move.ground_target)
				);
				player.server.walking_toward = false;

		}

		if scene.is_server && response {
			reply: Command.Move;
			reply.player_id = player.id;
			reply.ground_target = move.ground_target;
			add(response, scene.id, reply);
		}

		return true;
	}

	sync: *Command.Sync_Player = isa(command.payload, Command.Sync_Player);
	if sync {
		for * scene.players if it.id == sync.player_id {
			it.server.direction = sync.direction;
			it.server.position = sync.position;
			it.server.dead = sync.dead;
			it.server.has_safe_present = sync.has_safe_present;
			it.server.has_hook_present = sync.has_hook_present;
			if sync.model_id >= 0
				it.server.model_id = sync.model_id;
		}
	}

	return false;
}


Tile :: struct {
	Kind :: enum {
		None       :: 0;
		Ice        :: 1;
		Grass      :: 2;
		Slippy_Ice :: 3;
		Dirt       :: 4;
		Funny_Ice  :: 5;
	}

	kind: Kind;
}

Terrain :: struct {
	text: string;

	tiles_count: V2i;
	tile_size: V2f = V2f.{ 3.0 / 3.0, 3.0 / 3.0 };
	spawn_tile_: V2i;

	tiles: [..] Tile;
}
free :: (terrain: *Terrain) {
	array_free(terrain.tiles);
	free(terrain.text);
}

tile_under :: (scene: Scene, spot: V3f) -> Tile, bool {
	terrain := *scene.terrain;

	tile_idx := position_to_tile(scene, spot);
	xi := tile_idx.x;
	yi := tile_idx.y;

	if xi < 0 || xi >= terrain.tiles_count.x || yi < 0 || yi >= terrain.tiles_count.y {
		return Tile.{}, false; // Out of bounds
	}

	tile_index := xi + yi * terrain.tiles_count.x;
	if tile_index < 0 || tile_index >= terrain.tiles.count {
		return Tile.{}, false; // Out of bounds
	}

	return terrain.tiles[tile_index], true; // Return the tile and true to indicate it exists
}

touch_a_tile :: (scene: Scene, spot: V3f, radius: float, kind: Tile.Kind) -> bool {
	terrain := *scene.terrain;

	low_tile_idx := position_to_tile(scene, spot - V3f.{ radius, radius, 0.0 });
	high_tile_idx := position_to_tile(scene, spot + V3f.{ radius, radius, 0.0 });

	lo_x := low_tile_idx.x;
	lo_y := low_tile_idx.y;
	hi_x := high_tile_idx.x;
	hi_y := high_tile_idx.y;

	for x: lo_x..hi_x {
		if x < 0 || x >= terrain.tiles_count.x
			continue;

		for y: lo_y..hi_y {
			if y < 0 || y >= terrain.tiles_count.y
				continue;

			tile_index := x + y * terrain.tiles_count.x;
			if tile_index < 0 || tile_index >= terrain.tiles.count
				continue;

			tile := terrain.tiles[tile_index];
			tile_position := tile_center(scene, .{ x, y });

			d := dist_aabb(
				spot, tile_position - V3f.{ 0.5, 0.5, 0 }, tile_position + V3f.{ 0.5, 0.5, 0 }
			);
			if d < radius && tile.kind == kind {
				return true;
			}
		}
	}

	return false;
}

compute_path_matrix :: (scene: Scene, path: Path, t: float, offset := 0.0) -> M4f {
	if path.checkpoint_head < 0
		return M4f.identity();

	total_t := 0.0;
	prev := path.checkpoint_head;
	if scene.checkpoints[prev].next >= 0 {
		idx := scene.checkpoints[prev].next;
		while idx >= 0 {
			a := scene.checkpoints[prev];
			b := scene.checkpoints[idx];
			d := norm(b.position - a.position) / b.speed;
			total_t += d;

			if idx == path.checkpoint_head {
				break;
			}
			prev = idx;
			idx = scene.checkpoints[idx].next;
			if idx < 0 && path.closed {
				idx = path.checkpoint_head;
			}
		}
	}

	t += offset * total_t;

	t = fmod_cycling(t, total_t);

	theta_sum := 0.0;
	prev = path.checkpoint_head;
	if scene.checkpoints[prev].next >= 0 {
		idx := scene.checkpoints[prev].next;
		while idx >= 0 {
			a := scene.checkpoints[prev];
			b := scene.checkpoints[idx];
			d := norm(b.position - a.position) / b.speed;
			if t <= d {
				pos := a.position + (b.position - a.position) * (t / d);
				M := M4f.translate(pos);

				if path.theta_dir {
					theta := theta_sum + b.theta * (t / d);
					M = M * to_rotation_matrix(axis_angle(V3f.{ 0, 0, 1 }, theta));
				} else {
					dir := normalize(b.position - a.position);
					M = M * to_rotation_matrix(
						from_unit_vectors(V3f.{ 1, 0, 0 }, dir)
					);
				}
				return M;
			}
			theta_sum += a.theta;
			t -= d;

			if idx == path.checkpoint_head
				break;

			prev = idx;
			idx = scene.checkpoints[idx].next;
			if idx < 0 && path.closed {
				idx = path.checkpoint_head;
			}
		}
	}

	return M4f.identity();
}
compute_path_pos :: (scene: Scene, path: Path, t: float, offset := 0.0) -> V3f {
	M := compute_path_matrix(scene, path, t, offset);
	return v3(M * v4(0.0, 0.0, 0.0, 1.0));
}
compute_path_dir :: (scene: Scene, path: Path, t: float, offset := 0.0) -> V3f {
	M := compute_path_matrix(scene, path, t, offset);
	return v3(M * v4(1.0, 0.0, 0.0, 0.0));
}


compute_skull_matrix :: (scene: Scene, skull: Skull) -> M4f {
	path := find_by_path_id(scene, skull.path_id);
	if !path
		return M4f.identity();
	t := scene.server.clock * skull.server.speed;
	return compute_path_matrix(scene, path, xx t, skull.server.offset);
}
compute_skull_dir :: (scene: Scene, skull: Skull) -> V3f {
	path := find_by_path_id(scene, skull.path_id);
	if !path
		return V3f.{ 1, 0, 0 };
	t := scene.server.clock * skull.server.speed;
	return compute_path_dir(scene, path, xx t, skull.server.offset);
}
compute_skull_pos :: (scene: Scene, skull: Skull) -> V3f {
	path := find_by_path_id(scene, skull.path_id);
	if !path
		return V3f.{ 0, 0, 0 };
	t := scene.server.clock * skull.server.speed;
	return compute_path_pos(scene, path, xx t, skull.server.offset);
}


// compute_skull_matrix :: (scene: Scene, skull: Skull) -> M4f {
// 	if skull.path_id >= scene.terrain.paths.count
// 		return M4f.identity();

// 	path: *Path = *scene.terrain.paths[skull.path_id];
// 	if path.checkpoints_count == 0
// 		return M4f.identity();

// 	total_t := 0.0;
// 	for 1..path.checkpoints_count - 1 {
// 		a := path.checkpoints[it - 1];
// 		b := path.checkpoints[it + 0];
// 		d := norm(b - a);
// 		total_t += d;
// 	}

// 	t := fmod_cycling(
// 		scene.server.clock * skull.server.speed + skull.server.offset * total_t, total_t
// 	);

// 	for 1..path.checkpoints_count - 1 {
// 		a := path.checkpoints[it - 1];
// 		b := path.checkpoints[it + 0];
// 		d := norm(b - a);
// 		if t <= d {
// 			dir := normalize(b - a);
// 			pos := a + (b - a) * (t / d);
// 			M := M4f.translate(pos) * to_rotation_matrix(
// 				from_unit_vectors(V3f.{ 1, 0, 0 }, dir)
// 			);
// 			return M;
// 		}
// 		t -= d;
// 	}
// 	return M4f.identity();
// }

// compute_skull_dir :: (scene: Scene, skull: Skull) -> V3f {
// 	if skull.path_id >= scene.terrain.paths.count
// 		return V3f.{ 1, 0, 0 };

// 	path: *Path = *scene.terrain.paths[skull.path_id];
// 	if path.checkpoints_count == 0
// 		return V3f.{ 1, 0, 0 };

// 	total_t := 0.0;
// 	for 1..path.checkpoints_count - 1 {
// 		a := path.checkpoints[it - 1];
// 		b := path.checkpoints[it + 0];
// 		d := norm(b - a);
// 		total_t += d;
// 	}

// 	t := fmod_cycling(
// 		scene.server.clock * skull.server.speed + skull.server.offset * total_t, total_t
// 	);

// 	for 1..path.checkpoints_count - 1 {
// 		a := path.checkpoints[it - 1];
// 		b := path.checkpoints[it + 0];
// 		d := norm(b - a);
// 		if t <= d {
// 			dir := normalize(b - a);
// 			return dir;
// 		}
// 		t -= d;
// 	}
// 	return V3f.{ 1, 0, 0 };
// }

// compute_skull_pos :: (scene: Scene, skull: Skull) -> V3f {
// 	if skull.path_id >= scene.terrain.paths.count
// 		return V3f.{ 0, 0, 0 };

// 	path: *Path = *scene.terrain.paths[skull.path_id];
// 	if path.checkpoints_count == 0
// 		return V3f.{ 0, 0, 0 };

// 	total_t := 0.0;
// 	for 1..path.checkpoints_count - 1 {
// 		a := path.checkpoints[it - 1];
// 		b := path.checkpoints[it + 0];
// 		d := norm(b - a);
// 		total_t += d;
// 	}

// 	t := fmod_cycling(
// 		scene.server.clock * skull.server.speed + skull.server.offset * total_t, total_t
// 	);

// 	for 1..path.checkpoints_count - 1 {
// 		a := path.checkpoints[it - 1];
// 		b := path.checkpoints[it + 0];
// 		d := norm(b - a);
// 		if t <= d {
// 			pos := a + (b - a) * (t / d);
// 			return pos;
// 		}
// 		t -= d;
// 	}
// 	return V3f.{ 0, 0, 0 };
// }

compute_moving_frame_server_world_matrix :: (scene: Scene, frame: Moving_Frame) -> M4f {
	if frame.keys.count == 0 {
		return M4f.identity();
	}
	if frame.sum_period == 0 || frame.keys.count <= 1 {
		key := get(frame.keys, scene.moving_frame_keys, 0);
		return M4f.translate(key.pos) * to_rotation_matrix(axis_angle(V3f.{ 0, 0, 1 }, key.theta));
	}

	t_left := fmod_cycling(scene.client.clock + frame.server.offset, frame.sum_period).(float32);
	before_idx := 0;
	for iterator(frame.keys, scene.moving_frame_keys) {
		if t_left < it.period {
			before_idx = it_index;
			break;
		}
		t_left -= it.period;
	}

	if (before_idx + 1) >= xx frame.keys.count {
		before_idx = frame.keys.count.(s64) - 2;
	}

	curr := get(frame.keys, scene.moving_frame_keys, before_idx + 0);
	next := get(frame.keys, scene.moving_frame_keys, before_idx + 1);

	t := t_left / curr.period;

	return M4f.translate(
		curr.pos + (next.pos - curr.pos) * t
	) * to_rotation_matrix(
		axis_angle(V3f.{ 0, 0, 1 }, curr.theta + (next.theta - curr.theta) * t)
	);
}

compute_shuriken_server_world_pos :: (scene: Scene, shuriken: Shuriken) -> V3f {
	frame := find_by_frame_id(scene, shuriken.frame_id);
	if !frame {
		return shuriken.server.position;
	}

	M := compute_moving_frame_server_world_matrix(scene, frame);
	return v3(M * v4(shuriken.server.position, 1.0));
}

spawn_into :: (player: *Player, scene: Scene) {
	// Look for the activated flag with the highest idx;
	best: *Flag = null;
	for * scene.flags {
		if !it.activated
			continue;

		if !best || it.index > best.index {
			best = it;
		}
	}

	if best {
		player.server.position.x = xx best.position.x;
		player.server.position.y = xx best.position.y;
	} else {
		player.server.position = scene.spawn.position;
	}

	player.server.walking_toward = false;
	player.server.slipping = false;
	player.server.dead = false;
	player.server.has_safe_present = false;
	player.server.has_hook_present = 0;
}

terrain_size :: (scene: Scene) -> V2f {
	return V2f.{
		xx scene.terrain.tiles_count.x * scene.terrain.tile_size.x,
		xx scene.terrain.tiles_count.y * scene.terrain.tile_size.y
	};
}

tile_center :: (scene: Scene, tile: V2i) -> V3f {
	return V3f.{
		xx (tile.x + 0.5) * scene.terrain.tile_size.x - scene.origin_tile_space.x,
		xx (tile.y + 0.5) * scene.terrain.tile_size.y - scene.origin_tile_space.y,
		0
	};
}
tile_bottom_left :: (scene: Scene, tile: V2i) -> V3f {
	return V3f.{
		xx (tile.x + 0.0) * scene.terrain.tile_size.x - scene.origin_tile_space.x,
		xx (tile.y + 0.0) * scene.terrain.tile_size.y - scene.origin_tile_space.y,
		0
	};
}
position_to_tile :: (scene: Scene, pos: V3f) -> V2i {
	return V2i.{
		cast(int) floor((pos.x + scene.origin_tile_space.x) / scene.terrain.tile_size.x),
		cast(int) floor((pos.y + scene.origin_tile_space.y) / scene.terrain.tile_size.y)
	};
}

remove_player_from_scene :: (player_id: int, scene: *Scene) {
	for * scene.players {
		if it.id == player_id {
			remove it;
			break;
		}
	}
}


serialize :: (scene: Scene) -> string {
	sb: String_Builder;

	terrain := *scene.terrain;

	// Write ASCII representation (bottom to top in file = top to bottom visually)
	for y_inv: 0..terrain.tiles_count.y - 1 {
		y := terrain.tiles_count.y - 1 - y_inv;
		for x: 0..terrain.tiles_count.x - 1 {
			tile_idx := x + y * terrain.tiles_count.x;
			tile := terrain.tiles[tile_idx];

			char: u8;
			if tile.kind == {
				case .None;       char = #char "X";
				case .Ice;        char = #char "I";
				case .Grass;      char = #char "G";
				case .Slippy_Ice; char = #char "i";
				case .Dirt;       char = #char "X";
				case .Funny_Ice;  char = #char "R";
			}
			append(*sb, char);
		}
		append(*sb, "\n");
	}

	// Add empty line separator
	append(*sb, "\n");

	print_to_builder(*sb, "- name: %\n", string_from_arr(scene.info.name));

	if scene.night {
		print_to_builder(*sb, "- night\n");
	}

	for scene.paths {
		print_to_builder(*sb, "path\n");

		checkpoint_idx := it.checkpoint_head;
		while checkpoint_idx >= 0 {
			checkpoint := scene.checkpoints[checkpoint_idx];
			print_to_builder(
				*sb,
				"- checkpoint: % % %\n",
				checkpoint.position.x, checkpoint.position.y, checkpoint.position.z
			);
			checkpoint_idx = checkpoint.next;
		}
		if it.closed {
			print_to_builder(*sb, "- closed\n");
		}
	}

	print_to_builder(
		*sb,
		#string SPAWN
spawn
- position: % % %
- size: % %
		SPAWN,
		scene.spawn.position.x, scene.spawn.position.y, scene.spawn.position.z,
		scene.spawn.size.x, scene.spawn.size.y
	);

	print_to_builder(
		*sb,
		#string TROPHY
frame
- position: % %
- size: % %
- origin: % %
		TROPHY,
		scene.camera_min.x, scene.camera_min.y,
		scene.camera_max.x - scene.camera_min.x, scene.camera_max.y - scene.camera_min.y,
		scene.origin_tile_space.x, scene.origin_tile_space.y
	);
	
	for * scene.flags {
		print_to_builder(
			*sb,
			#string FLAG
flag
- position: % % %
- index: %
			FLAG,
			it.position.x, it.position.y, it.position.z,
			it.index
		);
	}
	
	for * scene.presents {
		print_to_builder(
			*sb,
			#string PRESENT
present
- position: % % %
- kind: %
- refresh_cooldown: %
- depends_on_flag_id: %
			PRESENT,
			it.position.x, it.position.y, it.position.z,
			it.kind,
			it.server.refresh_cooldown,
			it.server.depends_on_flag_id
		);
	}

	for * scene.traps {
		print_to_builder(
			*sb,
			#string TRAP
trap
- position: % % %
- radius_hitbox: %
- stay_activated_time: %
%
			TRAP,
			it.position.x, it.position.y, it.position.z,
			it.radius_hitbox,
			it.stay_activated_time,
			ifx it.activable then "- activable" else ""
		);
	}

	for * scene.trophies {
		print_to_builder(
			*sb,
			#string TROPHY
trophy
- position: % % %
			TROPHY,
			it.position.x, it.position.y, it.position.z
		);
	}

	for * scene.block_rocks {
		print_to_builder(
			*sb,
			#string BLOCK_ROCK
block_rock
- position: % % %
BLOCK_ROCK,
			it.position.x, it.position.y, it.position.z
		);
	}

	for * scene.bomb_spawners {
		print_to_builder(
			*sb,
			#string BOMB_SPAWNER
bomb_spawner
- position: % % %
- explosion_time: %
- explosion_radius: %
BOMB_SPAWNER,
			it.position.x, it.position.y, it.position.z,
			it.explosion_time,
			it.explosion_radius
		);
	}

	for * scene.skulls {
		print_to_builder(
			*sb,
			#string SKULL
skull
- path_id: %
- speed: %
- offset: %
SKULL,
			it.path_id,
			it.server.speed,
			it.server.offset
		);
	}

	for * scene.gates {
		print_to_builder(
			*sb,
			#string GATE
gate
- position: % % %
- direction: % % %
- is_closed: %
- wait_for_key_id: %
- wait_for_trigger_id: %
			GATE,
			it.position.x, it.position.y, it.position.z,
			it.direction.x, it.direction.y, it.direction.z,
			it.is_closed,
			it.wait_for_key_id,
			it.wait_for_trigger_id,
		);
		for idx: 0..it.pressbutton_ids.count - 1 {
			id := scene.indices[idx + it.pressbutton_ids.index];
			print_to_builder(*sb, "- wait_for_pressbutton_id: %\n", id);
		}
	}

	for * scene.keys {
		print_to_builder(
			*sb,
			#string KEY
key
- position: % % %
KEY,
			it.server.position.x, it.server.position.y, it.server.position.z
		);
	}

	for * scene.lanterns {
		print_to_builder(
			*sb,
			#string LANTERN
lantern
- position: % % %
- light_aabb: % % % %
- button_id: %
- intensity: %
LANTERN,
			it.position.x, it.position.y, it.position.z,
			it.light_aabb.min.x, it.light_aabb.min.y, it.light_aabb.max.x, it.light_aabb.max.y,
			it.button_id,
			it.intensity
		);
	}

	for * scene.pressbuttons {
		print_to_builder(
			*sb,
			#string PRESSBUTTON
pressbutton
- position: % % %
PRESSBUTTON,
			it.position.x, it.position.y, it.position.z
		);
		if it.is_radio {
			print_to_builder(*sb, "- radio\n");
		}
	}

	for * scene.turn_tables {
		print_to_builder(
			*sb,
			#string TURN_TABLE
turn_table
- position: % % %
- turning_speed: %
- turning_offset: %
TURN_TABLE,
			it.position.x, it.position.y, it.position.z,
			it.turning_speed,
			it.turning_offset
		);
	}

	for * scene.antiairs {
		print_to_builder(
			*sb,
			#string ANTI_AIR
antiair
- position: % % %
- target: % % % %
- cooldown: %
- radius: %
- offset_time: %
ANTI_AIR,
			it.position.x, it.position.y, it.position.z,
			it.target_aabb.min.x, it.target_aabb.min.y, it.target_aabb.max.x, it.target_aabb.max.y,
			it.cooldown,
			it.radius,
			it.server.t
		);
	}

	for * scene.robots {
		print_to_builder(
			*sb,
			#string ROBOT
robot
- position: % % %
- max_rotation_speed: %
- start_target_aabb: % %
- end_target_aabb: % %
- charging_time: %
- effectshoot_time: %
- predict: %
- shooting_cd: %
- shooting_time: %
- shooting_offset: %
ROBOT,
			it.position.x, it.position.y, it.position.z,
			it.max_rotation_speed,
			it.target_aabb.min.x, it.target_aabb.min.y,
			it.target_aabb.max.x, it.target_aabb.max.y,
			it.charging_time,
			it.effectshoot_time,
			it.predict,
			it.shooting_cd,
			it.shooting_time,
			it.shooting_offset
		);
	}
	
	return builder_to_string(*sb);
}