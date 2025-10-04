#import "Algebra";
#import "Math";
#import "Basic";
#import "String";
#import "Tagged_Union";
#import "Communication";
#import "Pool";
#import "Hash_Table";
#import "Terrain";
Platform :: #import "Platform";
Controls :: #import "Controls";
Rand :: #import "Rand";
GUI :: #import "GUI";

#scope_export

Sound_Trigger :: struct {
	position: V3f;
	kind: enum {
		Footstep_Snow :: 0;
		Footstep_Ice :: 1;
		Car_Klaxon :: 2;
		Explosion :: 3;
	};
}

Scene :: struct {
	State :: enum {
		Normal :: 0;
		Wipe_Fade_In :: 1;
		Wipe_Fade_Out :: 2;
	}
	state: State;

	id := 1;
	next_id := -1;

	is_server := false;
	camera: Camera;

	// >TODO put all allocation relating to the map in the same pool.
	players: [..] Player;
	controlled_player_id := 0;

	tombstones: [..] Tombstone;
	skulls: [..] Skull;
	coins: [..] Coin;
	keys: [..] Key;
	gates: [..] Gate;
	moving_frames: [..] Moving_Frame;
	shurikens: [..] Shuriken;
	stand_in: [..] Stand_In;
	trigger_zones: [..] Trigger_Zone;
	within_zones: [..] Within_Zone;
	flags: [..] Flag;
	props: [..] Prop;
	particles: [..] Particle;
	trophies: [..] Trophy;
	robots: [..] Robot;
	explosions: [..] Explosion;
	antiairs: [..] AntiAir;
	traps: [..] Trap;
	terrain: Terrain;

	camera_min: V2f;
	camera_max: V2f;

	coin_generation := 0;

	mark_clicked_time: Apollo_Time;
	mark_clicked_pos: V3f;

	Fade_Screen :: struct {
		color: V3f;
		start: Apollo_Time;
		period := 1.0;
	}

	fade_screen: Fade_Screen;
	fading := false;

	trigger_activated: Table(int, bool);

	succeed := false;
	end_scene_countdown_time: Apollo_Time;
	end_scene_countdown := 10.0;
	end_scene_countdown_started := false;

	client_rng: Rand.State;
	server_rng: Rand.State;

	sound_triggers: [..] Sound_Trigger;
}
clear :: (scene: *Scene) {
	scene.tombstones.count = 0;
	scene.skulls.count = 0;
	scene.coins.count = 0;
	scene.keys.count = 0;
	scene.gates.count = 0;
	scene.moving_frames.count = 0;
	scene.shurikens.count = 0;
	scene.stand_in.count = 0;
	scene.trigger_zones.count = 0;
	scene.within_zones.count = 0;
	scene.flags.count = 0;
	scene.props.count = 0;
	scene.robots.count = 0;
	scene.particles.count = 0;
	scene.explosions.count = 0;
	scene.trophies.count = 0;
	scene.antiairs.count = 0;
	scene.traps.count = 0;
	scene.sound_triggers.count = 0;
	table_reset(*scene.trigger_activated);
}

make_sync :: (scene: *Scene) -> Command.Sync_Scene {
	sync_scene: Command.Sync_Scene;
	sync_scene.id = scene.id;
	sync_scene.terrain = scene.terrain.text;
	sync_scene.players = NewArray(scene.players.count, Command.Sync_Player, false,, temp);
	sync_scene.skulls = NewArray(scene.skulls.count, Command.Sync_Skull, false,, temp);
	sync_scene.moving_frames = NewArray(scene.moving_frames.count, Command.Sync_Moving_Frame, false,, temp);
	sync_scene.robots = NewArray(scene.robots.count, Command.Sync_Robot, false,, temp);
	sync_scene.antiairs = NewArray(scene.antiairs.count, Command.Sync_AntiAir, false,, temp);
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
	return sync_player;
}

make_sync :: (skull: *Skull) -> Command.Sync_Skull {
	sync_skull: Command.Sync_Skull;
	sync_skull.skull_id = skull.id;
	sync_skull.t = skull.server.t;
	sync_skull.speed = skull.server.speed;
	sync_skull.offset = skull.server.offset;
	return sync_skull;
}

make_sync :: (moving_frame: *Moving_Frame) -> Command.Sync_Moving_Frame {
	sync_moving_frame: Command.Sync_Moving_Frame;
	sync_moving_frame.frame_id = moving_frame.id;
	sync_moving_frame.t = moving_frame.server.t;
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
	sync_antiair.position = antiair.server.position;
	sync_antiair.target = antiair.server.target;
	sync_antiair.cooldown = antiair.server.cooldown;
	sync_antiair.target_size = antiair.server.target_size;
	sync_antiair.next_target = antiair.server.next_target;
	sync_antiair.t = antiair.server.t;
	return sync_antiair;
}

Frame_Result :: struct {
	died: [..] Command.Die;
	respawn: [..] Command.Respawn;
	sync_gate: [..] Command.Sync_Gate;
	move_to_player_world: [..] Command.Move_To_Play_World;
	wipe_scene: [..] Command.Wipe_Scene;
	end_level: [..] Command.End_Level;
	explode: [..] Command.Explode;
	antiair_shoot: [..] Command.AntiAir_Shoot;
	spawn_coin: [..] Command.Spawn_Coin;
	move: [..] Command.Move;
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
}
clear :: (frame_result: *Frame_Result) {
	frame_result.died.count = 0;
	frame_result.respawn.count = 0;
	frame_result.sync_gate.count = 0;
	frame_result.move_to_player_world.count = 0;
	frame_result.wipe_scene.count = 0;
	frame_result.end_level.count = 0;
	frame_result.explode.count = 0;
	frame_result.antiair_shoot.count = 0;
	frame_result.spawn_coin.count = 0;
	frame_result.move.count = 0;
}

AntiAir :: struct {
	id: int;
	server: struct {
		position: V3f;
		target: V3f;
		target_size: V2f = .{ 0.25, 0.25 };
		cooldown: float = 2.0;
		radius := 1.0;
		t := 0.0;
		just_shooted := false;

		next_target: V2f = .{ FLOAT32_MAX, FLOAT32_MAX };
		curr_target: V2f = .{ FLOAT32_MAX, FLOAT32_MAX };
	}
	client: struct {
		t := 0.0;
		next_target: V2f = .{ FLOAT32_MAX, FLOAT32_MAX };
	}
}

Trap :: struct {
	id: int;
	position: V3f;
	radius_hitbox := 0.5;
}

Prop :: struct {
	id: int;
	M: M4f;
}

Trophy :: struct {
	id: int;
	position: V3f;
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

	position: V3f;
	start_target_aabb: V2f;
	end_target_aabb: V2f;

	axes: [5] float;

	player_targeted_id := -1;

	max_rotation_speed := 3.141592 * 0.5; // radians per second

	charging_time := 1.0;
	effectshoot_time := 0.5;
	shooting_cd := 5.0;
	shooting_time := 0.0;

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
		command: Command;
	}

	entries: [..] Entry;
	audios: [..] Platform.Audio;
}
free :: (process_response: *Process_Response) {
	array_free(process_response.entries);
}
clear :: (response: *Process_Response) {
	response.entries.count = 0;
}
add :: (process_response: *Process_Response, scene_id: int, command: $T) {
	entry: Process_Response.Entry;
	entry.scene_id = scene_id;
	entry.command = make_command(command);
	array_add(*process_response.entries, entry);
}

Camera :: struct {
	position: V3f;
	target:   V3f;
	target_target: V3f;
	wanted_target_to_position: V3f;

	max_distance := 0.0;


	locked_to := -1;
	locked := false;

	fov  := 65.0;
	near := 0.1;
	far  := 1000.0;
	aspect := 1280/720.0;

	speed := 25;
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

Flag :: struct {
	id: int;
	position: V3f;
	radius: float = 0.75;

	count_changed_juice_t := 0.0;
	activated_juice_t := 0.0;

	index := 0;
	activated := false;

	n_present := 0;

	last_player_count := 0;
}

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
}

Moving_Frame :: struct {
	id: int;

	Key :: struct {
		pos: V3f;
		theta: float;
		period: float;
	}

	keys: [..] Key;

	server: struct {
		t: float = 0;
		speed: float = 1.0;
	}

	client: struct {
		t: float = 0;
	}
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
	};
	client: struct {
		position: V3f;
		theta: float;
	}
}

Key :: struct {
	id: int;
	holder: int;
	server: struct {
		position: V3f;
		radius_hitbox := 0.25;
	}
	client: struct {
		position: V3f;
	}
}

Skull :: struct {
	id: int;
	path_id: int;

	server: struct {
		t: float;
		speed: float = 1.0;
		offset: float = 0.0;
	}
	client: struct {
		t: float;
		direction: V3f = .{ 1, 0, 0 };
	}
}

Path :: struct {
	checkpoints: [32] V3f;
	checkpoints_count := 0;
}

Tombstone :: struct {
	player_id: int;
	position: V3f;
}

Gate :: struct {
	id: int;
	position: V3f;
	direction: V3f;
	is_closed := true;
	wait_for_key_id := -1;
	wait_for_trigger_id := -1;
	is_end := false;
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

		radius_hitbox_tombstone := 0.75;
		radius_hurtbox_skull := 0.5;
		radius_hurtbox_shuriken := 0.25;
		radius_hitbox_key := 0.55;
		radius_hitbox_confirmed := 0.15;

		confirmed_tile := Tile.Kind.Grass;

		model_id := 0;
	};

	// This is the stuff that gets optimistically updated by the client. For rendering
	client: struct {
		position  := V3f.{ 0, 0, 0 };
		direction := V3f.{ 1, 0, 0 };
	};
}

find_by_robot_id :: (scene: Scene, id: int) -> *Robot {
	for * scene.robots {
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

find_by_player_id :: (scene: Scene, id: int) -> *Player {
	for * scene.players {
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
find_tombstone_by_player_id :: (scene: Scene, id: int) -> *Tombstone {
	for * scene.tombstones {
		if it.player_id == id
			return it;
	}
	return null;
}

interpolate_to_server :: (player: *Player, dt: float) {
	player.client.direction = damp(player.client.direction, player.server.direction, 50.0, dt);
	player.client.direction = normalize(player.client.direction);
	player.client.position = damp(player.client.position, player.server.position, 50.0, dt);
}

interpolate_to_server :: (skull: *Skull) {
	if abs(skull.client.t - skull.server.t) > 10 {
		skull.client.t = skull.server.t;
		return;
	}

	skull.client.t = damp(skull.client.t, skull.server.t, 10.0, 0.1);
}

interpolate_to_server :: (key: *Key, dt: float32) {
	key.client.position = damp(key.client.position, key.server.position, 10.0, dt);
}

restart :: (scene: *Scene) {
	parse_terrain(scene.terrain.text, scene);
	for * player: scene.players {
		spawn_into(player, scene);
	}
	scene.end_scene_countdown_started = false;
	scene.succeed = false;
}

add_snow :: (scene: *Scene, dt: float32) {
	// Add snow particles
	n_snow :=
		dt * (scene.camera_max.x - scene.camera_min.x) * (scene.camera_max.y - scene.camera_min.y);
	n_snow *= 0.5;
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
		p.size = Rand.random_uniform(*scene.client_rng, 0.04, 0.10);
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

input :: (scene: *Scene, controls: *Controls.State, dt: float32, result: *Process_Response) {
	any_camera_move := false;
	dt := V3f.{ 0, 0, 0 };
	if controls.frame_info.mouse_wheel > 0 {
		scene.camera.wanted_target_to_position *= 0.9;
	}
	if controls.frame_info.mouse_wheel < 0 {
		scene.camera.wanted_target_to_position *= (1.0 / 0.9);
		l := norm(scene.camera.wanted_target_to_position);
		if l > scene.camera.max_distance {
			l = scene.camera.max_distance;
		}
		scene.camera.wanted_target_to_position =
			l * normalize(scene.camera.wanted_target_to_position);
	}
	if controls.pressed[Platform.Key.Q] {
		dt.x -= scene.camera.speed * controls.frame_info.delta_time;
		any_camera_move = true;
	}
	if controls.pressed[Platform.Key.D] {
		dt.x += scene.camera.speed * controls.frame_info.delta_time;
		any_camera_move = true;
	}
	if controls.pressed[Platform.Key.S] {
		dt.y -= scene.camera.speed * controls.frame_info.delta_time;
		any_camera_move = true;
	}
	if controls.pressed[Platform.Key.Z] {
		dt.y += scene.camera.speed * controls.frame_info.delta_time;
		any_camera_move = true;
	}
	scene.camera.locked = controls.pressed[Platform.Key.Space];
	scene.camera.target_target += dt;
	if scene.camera.locked {
		scene.camera.target += dt;
	}

	if !any_camera_move {
		scene.camera.target_target = scene.camera.target;
	}

	if controls.just_pressed[Platform.Key.MouseLeft] {
		V := look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
		P := perspective(scene.camera);
		r := unproject_ndc(
			.{
				controls.frame_info.mouse_position.x / controls.frame_info.window_size.x * 2 - 1,
				controls.frame_info.mouse_position.y / controls.frame_info.window_size.y * 2 - 1
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
			scene.mark_clicked_time = current_time_monotonic();
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
	
	if controls.just_pressed[Platform.Key.C] {
		player := find_by_player_id(scene, scene.controlled_player_id);
		if player && !player.server.dead {
			command: Command.Spawn_Coin;
			command.sender = player.id;
			add(result, scene.id, command);
		}
	}

	if controls.just_pressed[Platform.Key.X] {
		sound: Sound_Trigger;
		player := find_by_player_id(scene, scene.controlled_player_id);
		if player && !player.server.dead {
			command: Command.Klaxon;
			command.player_id = player.id;
			add(result, scene.id, command);
		}
	}
}

update :: (scene: *Scene, dt: float32, result: *Frame_Result) {
	if #complete scene.state == {
		case .Normal;
			update_normal(scene, dt, result);
		case .Wipe_Fade_In;
			t := to_float64_seconds(current_time_monotonic() - scene.fade_screen.start).(float32);
			if t < scene.fade_screen.period {
				alpha := ease_quad(t / scene.fade_screen.period);
				color := V4f.{
					scene.fade_screen.color.x,
					scene.fade_screen.color.y,
					scene.fade_screen.color.z,
					clamp(alpha, 0.0, 1.0)
				};

				GUI.push_late_quad_screen(
					.{ 0, 0 },
					GUI.IM.display_size,
					color,
					-1.0
				);
			} else {
				scene.state = .Wipe_Fade_Out;
				restart(scene);
			}
		case .Wipe_Fade_Out;
			t := to_float64_seconds(current_time_monotonic() - scene.fade_screen.start).(float32);
			if t >= 2 * scene.fade_screen.period {
				scene.state = .Normal;
				return;
			} else {
				alpha := ease_out_quad(2.0 - t / scene.fade_screen.period);
				color := V4f.{
					scene.fade_screen.color.x,
					scene.fade_screen.color.y,
					scene.fade_screen.color.z,
					clamp(alpha, 0.0, 1.0)
				};

				GUI.push_late_quad_screen(
					.{ 0, 0 },
					GUI.IM.display_size,
					color,
					-1.0
				);
			}
	}
}

update_client :: (scene: *Scene, dt: float32, result: *Frame_Result) {
	add_snow(scene, dt);
}

update_normal :: (scene: *Scene, dt: float32, result: *Frame_Result) {
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

	for * scene.coins {
		update(scene, it, dt);
	}

	for * scene.moving_frames {
		update(scene, it, dt);
	}

	for * scene.shurikens {
		update(scene, it, dt);
	}

	for * scene.flags {
		update(scene, it, dt);
	}

	for * scene.within_zones {
		update(scene, it, dt);
	}

	for * scene.robots {
		update(scene, it, dt);
	}

	for * scene.antiairs {
		update(scene, it, dt);
	}

	update_explosions(scene, dt);

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
				it.holder = -1;
				continue;
			}

			it.server.position = player.server.position;
		}
	}

	update_particles(scene, dt);

	if scene.is_server && result {
		// >RULE Player die on contact with trap
		for * scene.traps {
			p := it.position;

			for * player: scene.players {
				if !player.server.dead {
					q := player.server.position;

					d := max(abs((p - q).x), abs((p - q).y));
					if d < it.radius_hitbox {
						server_die(scene, player, result);
						continue;
					}
				}
			}
		}

		// >RULE Trigger zone check
		for * scene.trigger_zones {
			tpos := it.pos;

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
						array_add(*result.move_to_player_world, move);
					}
				}
			}
		}

		// >RULE Coin revive dead player on tombstone collision
		for * scene.coins {
			pos := it.server.position;

			for * tombstone: scene.tombstones {
				// You can't revive yourself
				if it.sender != tombstone.player_id {
					dt := norm(pos - tombstone.position);

					if dt < it.server.radius_hitbox {
						respawn: Command.Respawn;
						respawn.player_id = tombstone.player_id;
						respawn.coin_id = it.id;

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

		// >RULE Player die when not under any tile or under a dirt tile
		for * scene.players {
			if !it.server.dead {
				tile, ok := tile_under(scene, it.server.position);
				if !ok || tile.kind == .Dirt {
					server_die(scene, it, result);
					continue;
				}
			}
		}

		// >RULE Player revivde dead player on tombstone collision
		for * scene.players {
			if !it.server.dead {
				for tomb: scene.tombstones {
					dt := norm(it.server.position - tomb.position);

					if dt < it.server.radius_hitbox_tombstone {
						respawn: Command.Respawn;
						respawn.player_id = tomb.player_id;

						array_add(*result.respawn, respawn);

						player_to_respawn := find_by_player_id(scene, tomb.player_id);
						if player_to_respawn {
							spawn_into(player_to_respawn, scene);
						}

						remove tomb;
						continue;
					}
				}
			}
		}

		// >RULE Player dies on contact with a skull
		for * scene.players {
			if !it.server.dead {
				for skull: scene.skulls {
					skull_pos := compute_skull_pos(scene, skull);

					dt := norm(it.server.position - skull_pos);
					if dt < it.server.radius_hurtbox_skull {
						server_die(scene, it, result);
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
				ok, triggered := table_find_new(*scene.trigger_activated, gate.wait_for_trigger_id);
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

		// >RULE Player die on contact with an explosion
		for *expl: scene.explosions {
			p := expl.position;
			t := ease_out_quad(clamp(expl.age / expl.lifetime, 0.0, 1.0));
			dt := t * expl.max_size / 2;

			for * player: scene.players {
				if !player.server.dead {
					q := player.server.position;

					d := norm(p - q);
					if d < dt {
						server_die(scene, player, result);
						continue;
					}
				}
			}
		}

		// >RULE Player die on contact with a shuriken
		for * scene.shurikens {
			p := compute_shuriken_server_world_pos(scene, it);

			for * player: scene.players {
				if !player.server.dead {
					q := player.server.position;

					d := norm(p - q);
					if d < (it.server.radius_hitbox + player.server.radius_hurtbox_shuriken) {
						server_die(scene, player, result);
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
					winner: Command.End_Level;
					winner.winner_id = player.id;
					winner.next_level_scheduled_in_seconds = 6;
					winner.next_scene_id = scene.next_id;
					array_add(*result.end_level, winner);

					win_level(scene, player.id);
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
					explosion.max_size = 1.5;

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
			if antiair.server.just_shooted {
				explosion: Explosion;
				explosion.position = v3(antiair.server.curr_target, 0.0);
				explosion.lifetime = 1.0;
				explosion.max_size = antiair.server.radius;

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
			antiair.server.just_shooted = false;
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

win_level :: (scene: *Scene, player_id: int) {
	scene.end_scene_countdown_started = true;
	scene.end_scene_countdown_time = current_time_monotonic();
	scene.end_scene_countdown = 6;
}

server_die :: (scene: *Scene, player: *Player, result: *Frame_Result) {
	died: Command.Die;
	died.player_id = player.id;
	died.position = player.server.position;
	array_add(*result.died, died);
	player.server.dead = true;
	tombstone: Tombstone;
	tombstone.player_id = died.player_id;
	tombstone.position = died.position;

	array_add(*scene.tombstones, tombstone);

	keys := find_key_by_holder_id(scene, player.id);

	for keys {
		it.holder = -1;
	}

	any_alive := false;
	for scene.players {
		if !it.server.dead {
			any_alive = true;
			break;
		}
	}

	if !any_alive {
		array_add(*result.wipe_scene, .{});
		restart(scene);
	}
}

update :: (scene: Scene, antiair: *AntiAir, dt: float32) {
	antiair.client.t += dt;
	if 0.1 < antiair.client.t && antiair.client.t + 1 < antiair.server.cooldown
		antiair.client.next_target = antiair.server.next_target;
	if antiair.client.t > antiair.server.cooldown {
		antiair.client.t = 0.0;
	}

	if scene.is_server {
		antiair.server.t += dt;
		
		if antiair.server.t > antiair.server.cooldown {
			antiair.server.t = 0.0;
			antiair.server.just_shooted = true;
			antiair.server.curr_target = antiair.server.next_target;
			antiair.server.next_target = .{ FLOAT32_MAX, FLOAT32_MAX };
		}
	}

	if antiair.server.next_target.x == FLOAT32_MAX {
		x := Rand.random_uniform(*scene.server_rng, -0.5, +0.5);
		y := Rand.random_uniform(*scene.server_rng, -0.5, +0.5);
		x *= antiair.server.target_size.x;
		y *= antiair.server.target_size.y;
		x += antiair.server.target.x;
		y += antiair.server.target.y;
		antiair.server.next_target = .{ x, y };
	}
}

// https://rodolphe-vaillant.fr/entry/114/cyclic-coordonate-descent-inverse-kynematic-ccd-ik
update :: (scene: Scene, robot: *Robot, dt: float32) {

	player := find_by_player_id(scene, robot.player_targeted_id);
	if !player {
		robot.player_targeted_id = -1;
	} else {
		p := v2(player.server.position);
		if p.x < robot.start_target_aabb.x
		|| p.x > robot.end_target_aabb.x
		|| p.y < robot.start_target_aabb.y
		|| p.y > robot.end_target_aabb.y {
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
			if p.x >= robot.start_target_aabb.x
			&& p.x <= robot.end_target_aabb.x
			&& p.y >= robot.start_target_aabb.y
			&& p.y <= robot.end_target_aabb.y {
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
		t := to_float64_seconds(current_time_monotonic()).(float32);
		robot.axes[0] += sin(t * 0.5) * 0.2 * dt;
		robot.axes[1] += sin(t * 0.7) * 0.3 * dt;
		robot.axes[2] += sin(t * 0.9) * 0.4 * dt;
		robot.axes[3] += sin(t * 1.1) * 0.5 * dt;
		robot.axes[4] += sin(t * 1.3) * 0.6 * dt;
		robot.player_targeted_id = -1;
		robot.shooting_time = 0;
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
	target.z = 2.0;

	target.x = clamp(target.x, robot.position.x - 2.0, robot.position.x + 2.0);
	target.y = clamp(target.y, robot.position.y - 2.0, robot.position.y + 2.0);
	
	T := target;

	N :: 10;
	for 1..1 {
		for #v2 < 1..5 {
			E := robot_pivot(robot, 6);
			Oi := robot_pivot(robot, it);
			ti := normalize(T - Oi);
			if it > 3 {
				ti = normalize(player.server.position - Oi);
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

update :: (scene: Scene, flag: *Flag, dt: float32) {
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
	frame.client.t = damp(frame.client.t, frame.server.t, 10.0, dt);
	frame.server.t += frame.server.speed * dt;
	sum := 0.0;
	for 1..frame.keys.count-1 {
		sum += frame.keys[it - 1].period;
	}
	frame.server.t = fmod_cycling(frame.server.t, sum);
}

update :: (scene: Scene, camera: *Camera, dt: float32) {
	player_locked := find_by_player_id(scene, camera.locked_to);
	if player_locked && camera.locked {
		center := camera.target;
		low := camera.target - V3f.{ 0.5, 0.25, 0.0 };
		high := camera.target + V3f.{ 0.5, 0.5, 0.0 };

		within_aabb := closest_aabb(player_locked.client.position, low, high);
		dt := player_locked.client.position - within_aabb;
		camera.target_target += dt;
	}

	camera.target = damp(camera.target, camera.target_target, 20.0, dt);
	target_to_position := camera.position - camera.target;
	target_to_position += (camera.wanted_target_to_position - target_to_position) * 1.0;
	camera.position = camera.target + target_to_position;

	restricted_target: V3f = camera.target;
	restricted_target.x = clamp(camera.target.x, scene.camera_min.x, scene.camera_max.x);
	restricted_target.y = clamp(camera.target.y, scene.camera_min.y, scene.camera_max.y);

	restricted_position: V3f = camera.position;
	restricted_position.x = clamp(
		camera.position.x,
		scene.camera_min.x + camera.wanted_target_to_position.x + 0.2,
		scene.camera_max.x + camera.wanted_target_to_position.x - 0.2
	);
	restricted_position.y = clamp(
		camera.position.y,
		scene.camera_min.y + camera.wanted_target_to_position.y + 0.75,
		scene.camera_max.y + camera.wanted_target_to_position.y - 0.75
	);

	sig :: (x: float) -> float {
		return 2.0 / (1.0 + exp(-x)) - 1.0;
	}
	camera.target.x = restricted_target.x + sig((camera.target.x - restricted_target.x) * 5.0) * 0.2;
	camera.target.y = restricted_target.y + sig((camera.target.y - restricted_target.y) * 5.0) * 0.2;
	camera.position.x = restricted_position.x + sig((camera.position.x - restricted_position.x) * 5.0) * 0.2;
	camera.position.y = restricted_position.y + sig((camera.position.y - restricted_position.y) * 5.0) * 0.2;
	// camera.target = damp(restricted_target, camera.target, 10.0, 0.1);
	// camera.position = damp(restricted_position, camera.position, 10.0, 0.1);
}

update :: (scene: Scene, skull: *Skull, dt: float32) {
	if !scene.is_server
		interpolate_to_server(skull);

	skull.server.t += skull.server.speed * dt;
	if scene.is_server
		skull.client.t = skull.server.t;

	path: *Path = *scene.terrain.paths[skull.path_id];
	if path.checkpoints_count > 0 {
		dir := compute_skull_dir(scene, skull);
		skull.client.direction = damp_angle_between(skull.client.direction, dir, 20.0, dt);
	}
}

update :: (scene: Scene, coin: *Coin, dt: float32) {
	coin.server.position += coin.server.speed * coin.server.direction * dt;
	coin.client.position += coin.server.speed * coin.server.direction * dt;
	coin.client.theta += xx (3.1415926 * 2.0 * dt);
}

update :: (scene: Scene, player: *Player, dt: float32) {
	if !scene.is_server
		interpolate_to_server(player, dt);

	if player.server.dead
		return;

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
			case .Ice;
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
	return true;
}

process_server_only :: (scene: *Scene, command: Command, response: *Process_Response) -> bool {
	if !scene.is_server
		return false;

	klaxon: *Command.Klaxon = isa(command.payload, Command.Klaxon);
	if klaxon {
		print("Klaxon %\n", klaxon.*);
		add(response, scene.id, klaxon.*);
		return true;
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
			if player.server.slipping
				coin.server.direction = player.server.direction;
			array_add(*scene.coins, coin);

			cmd: Command.Spawn_Coin;
			cmd.id = coin.id;
			cmd.sender = coin.sender;
			cmd.position = coin.server.position;
			cmd.direction = coin.server.direction;
			add(response, scene.id, cmd);

			scene.coin_generation += 1;
			return true;
		}
	}

	return false;
}

process_client_only :: (scene: *Scene, command: Command, response: *Process_Response) -> bool {
	wipe_scene: *Command.Wipe_Scene = isa(command.payload, Command.Wipe_Scene);
	if wipe_scene {
		scene.fade_screen.start = current_time_monotonic();
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
		array_add(*scene.coins, coin);
		return true;
	}
	died: *Command.Die = isa(command.payload, Command.Die);
	if died {
		player := find_by_player_id(scene, died.player_id);
		if player
		{
			player.server.dead = true;
			tombstone: Tombstone;
			tombstone.player_id = died.player_id;
			tombstone.position = died.position;

			array_add(*scene.tombstones, tombstone);
			return true;
		}
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
			antiair.server.cooldown = sync_antiair.cooldown;
			antiair.server.position = sync_antiair.position;
			antiair.server.target = sync_antiair.target;
			antiair.server.target_size = sync_antiair.target_size;
			antiair.server.next_target = sync_antiair.next_target;
			return true;
		}
	}

	anitiar_shoot: *Command.AntiAir_Shoot = isa(command.payload, Command.AntiAir_Shoot);
	if anitiar_shoot {
		antiair := find_by_antiair_id(scene, anitiar_shoot.antiair_id);
		if antiair {
			antiair.server.curr_target = antiair.server.next_target;
			antiair.server.next_target = anitiar_shoot.next_target;
			return true;
		}
	}

	sync_moving_frame: *Command.Sync_Moving_Frame = isa(command.payload, Command.Sync_Moving_Frame);
	if sync_moving_frame {
		frame := find_by_frame_id(scene, sync_moving_frame.frame_id);
		if frame {
			frame.server.t = sync_moving_frame.t;
			return true;
		}
	}

	end_level: *Command.End_Level = isa(command.payload, Command.End_Level);
	if end_level {
		scene.end_scene_countdown_time = current_time_monotonic();
		scene.end_scene_countdown = end_level.next_level_scheduled_in_seconds;
		scene.end_scene_countdown_started = true;
		scene.next_id = end_level.next_scene_id;
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

	return false;
}

process :: (scene: *Scene, command: Command, response: *Process_Response) -> bool {
	if scene.is_server && process_server_only(scene, command, response)
		return true;

	if !scene.is_server && process_client_only(scene, command, response)
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

		for * scene.tombstones {
			if it.player_id == respawn.player_id {

				player := find_by_player_id(scene, it.player_id);
				if player {
					spawn_into(player, scene);
				}
				remove it;
			}
		}

		coin := find_by_coin_id(scene, respawn.coin_id);
		if coin {
			for * scene.coins {
				if it.id == coin.id
					remove it;
			}
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
			skull.server.t = sync.t;
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
	}

	kind: Kind;
}

Terrain :: struct {
	text: string;

	tiles_count: V2i;
	spawn_tile: V2i;
	tile_size: V2f = V2f.{ 3.0 / 3.0, 3.0 / 3.0 };

	tiles: [..] Tile;
	paths: [..] Path;
}
free :: (terrain: *Terrain) {
	array_free(terrain.tiles);
	array_free(terrain.paths);
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

			d := dist_aabb(spot, tile_position, tile_position + V3f.{ 1.0, 1.0, 0 });
			if d < radius && tile.kind == kind {
				return true;
			}
		}
	}

	return false;
}
compute_skull_matrix :: (scene: Scene, skull: Skull) -> M4f {
	if skull.path_id >= scene.terrain.paths.count
		return M4f.identity();

	path: *Path = *scene.terrain.paths[skull.path_id];
	if path.checkpoints_count == 0
		return M4f.identity();

	total_t := 0.0;
	for 1..path.checkpoints_count - 1 {
		a := path.checkpoints[it - 1];
		b := path.checkpoints[it + 0];
		d := norm(b - a);
		total_t += d;
	}

	t := fmod_cycling(skull.client.t + skull.server.offset * total_t, total_t);

	for 1..path.checkpoints_count - 1 {
		a := path.checkpoints[it - 1];
		b := path.checkpoints[it + 0];
		d := norm(b - a);
		if t <= d {
			dir := normalize(b - a);
			pos := a + (b - a) * (t / d);
			M := M4f.translate(pos) * to_rotation_matrix(
				from_unit_vectors(V3f.{ 1, 0, 0 }, dir)
			);
			return M;
		}
		t -= d;
	}
	return M4f.identity();
}

compute_skull_dir :: (scene: Scene, skull: Skull) -> V3f {
	if skull.path_id >= scene.terrain.paths.count
		return V3f.{ 1, 0, 0 };

	path: *Path = *scene.terrain.paths[skull.path_id];
	if path.checkpoints_count == 0
		return V3f.{ 1, 0, 0 };

	total_t := 0.0;
	for 1..path.checkpoints_count - 1 {
		a := path.checkpoints[it - 1];
		b := path.checkpoints[it + 0];
		d := norm(b - a);
		total_t += d;
	}

	t := fmod_cycling(skull.client.t + skull.server.offset * total_t, total_t);

	for 1..path.checkpoints_count - 1 {
		a := path.checkpoints[it - 1];
		b := path.checkpoints[it + 0];
		d := norm(b - a);
		if t <= d {
			dir := normalize(b - a);
			return dir;
		}
		t -= d;
	}
	return V3f.{ 1, 0, 0 };
}

compute_skull_pos :: (scene: Scene, skull: Skull) -> V3f {
	if skull.path_id >= scene.terrain.paths.count
		return V3f.{ 0, 0, 0 };

	path: *Path = *scene.terrain.paths[skull.path_id];
	if path.checkpoints_count == 0
		return V3f.{ 0, 0, 0 };

	total_t := 0.0;
	for 1..path.checkpoints_count - 1 {
		a := path.checkpoints[it - 1];
		b := path.checkpoints[it + 0];
		d := norm(b - a);
		total_t += d;
	}

	t := fmod_cycling(skull.client.t + skull.server.offset * total_t, total_t);

	for 1..path.checkpoints_count - 1 {
		a := path.checkpoints[it - 1];
		b := path.checkpoints[it + 0];
		d := norm(b - a);
		if t <= d {
			pos := a + (b - a) * (t / d);
			return pos;
		}
		t -= d;
	}
	return V3f.{ 0, 0, 0 };
}

compute_moving_frame_server_world_matrix :: (scene: Scene, frame: Moving_Frame) -> M4f {
	if frame.keys.count == 0 {
		return M4f.identity();
	}
	if frame.keys.count <= 1 {
		return M4f.translate(frame.keys[0].pos) * to_rotation_matrix(
			axis_angle(V3f.{ 0, 0, 1 }, frame.keys[0].theta)
		);
	}

	t_left := frame.server.t;

	before_idx := 0;
	for i: 0..frame.keys.count - 1 {
		if t_left < frame.keys[i].period {
			before_idx = i;
			break;
		}
		t_left -= frame.keys[i].period;
	}

	if (before_idx + 1) >= frame.keys.count {
		before_idx = frame.keys.count - 2;
	}

	curr := frame.keys[before_idx + 0];
	next := frame.keys[before_idx + 1];

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
		player.server.position = tile_center(scene, scene.terrain.spawn_tile);
	}

	player.server.walking_toward = false;
	player.server.slipping = false;
	player.server.dead = false;
}

terrain_size :: (scene: Scene) -> V2f {
	return V2f.{
		xx scene.terrain.tiles_count.x * scene.terrain.tile_size.x,
		xx scene.terrain.tiles_count.y * scene.terrain.tile_size.y
	};
}

tile_center :: (scene: Scene, tile: V2i) -> V3f {
	return V3f.{
		xx (tile.x + 0.5) * scene.terrain.tile_size.x - scene.camera_min.x,
		xx (tile.y + 0.5) * scene.terrain.tile_size.y - scene.camera_min.y,
		0
	};
}
tile_bottom_left :: (scene: Scene, tile: V2i) -> V3f {
	return V3f.{
		xx (tile.x + 0.0) * scene.terrain.tile_size.x - scene.camera_min.x,
		xx (tile.y + 0.0) * scene.terrain.tile_size.y - scene.camera_min.y,
		0
	};
}
position_to_tile :: (scene: Scene, pos: V3f) -> V2i {
	return V2i.{
		cast(int) floor((pos.x + scene.camera_min.x) / scene.terrain.tile_size.x),
		cast(int) floor((pos.y + scene.camera_min.y) / scene.terrain.tile_size.y)
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