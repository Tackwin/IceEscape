#import "Algebra";
#import "Math";
#import "Basic";
#import "String";
#import "GL";
Render :: #import "Render";
#import "Tagged_Union";
#import "Communication";
#import "Pool";
#import "Hash_Table";
#import "Store";

#scope_export

Scene :: struct {
	id := 1;

	is_server := false;

	store: *Store;
	camera: Camera;
	tile_kind_to_shader: [64] *Render.Texture;

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
	terrain: Terrain;

	coin_generation := 0;

	mark_clicked_time: Apollo_Time;
	mark_clicked_pos: V3f;

	succeed := false;
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
}

make_sync :: (scene: *Scene) -> Command.Sync_Scene {
	sync_scene: Command.Sync_Scene;
	sync_scene.terrain = scene.terrain.text;
	sync_scene.players = NewArray(scene.players.count, Command.Sync_Player, false,, temp);
	sync_scene.skulls = NewArray(scene.skulls.count, Command.Sync_Skull, false,, temp);
	sync_scene.moving_frames = NewArray(scene.moving_frames.count, Command.Sync_Moving_Frame, false,, temp);
	for * sync_scene.players {
		it.* = make_sync(*scene.players[it_index]);
	}
	for * sync_scene.skulls {
		it.* = make_sync(*scene.skulls[it_index]);
	}
	for * sync_scene.moving_frames {
		it.* = make_sync(*scene.moving_frames[it_index]);
	}
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
	return sync_skull;
}

make_sync :: (moving_frame: *Moving_Frame) -> Command.Sync_Moving_Frame {
	sync_moving_frame: Command.Sync_Moving_Frame;
	sync_moving_frame.frame_id = moving_frame.id;
	sync_moving_frame.t = moving_frame.server.t;
	return sync_moving_frame;
}

Frame_Result :: struct {
	died: [..] Command.Die;
	respawn: [..] Command.Respawn;
	sync_gate: [..] Command.Sync_Gate;
	move_to_player_world: [..] Command.Move_To_Play_World;
}
free :: (frame_result: *Frame_Result) {
	array_free(frame_result.died);
	array_free(frame_result.respawn);
	array_free(frame_result.sync_gate);
	array_free(frame_result.move_to_player_world);
}
clear :: (frame_result: *Frame_Result) {
	frame_result.died.count = 0;
	frame_result.respawn.count = 0;
	frame_result.sync_gate.count = 0;
	frame_result.move_to_player_world.count = 0;
}

Process_Response :: struct {
	move: [..] Command.Move;
	coin_spawn: [..] Command.Spawn_Coin;
	ntp: [..] Command.NTP;
}
free :: (process_response: *Process_Response) {
	array_free(process_response.move);
	array_free(process_response.coin_spawn);
	array_free(process_response.ntp);
}
clear :: (response: *Process_Response) {
	response.move.count = 0;
	response.coin_spawn.count = 0;
	response.ntp.count = 0;
}

Camera :: struct {
	position: V3f;
	target:   V3f;
	target_target: V3f;
	wanted_target_to_position: V3f;

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

Trigger_Zone :: struct {
	id: int;
	accept_player_id := -1; // -1 means accept all players
	trigger: Trigger;

	pos: V3f;
	radius: float;

	model_id := -1;
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

update :: (scene: *Scene, dt: float32, result: *Frame_Result) {
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

	if scene.is_server && result {

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
							player_to_respawn.server.dead = false;
							spawn_into(player_to_respawn, scene.terrain);
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
				tile, ok := tile_under(scene.terrain, it.server.position);
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
							player_to_respawn.server.dead = false;
							spawn_into(player_to_respawn, scene.terrain);
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
	}
}

server_die :: (scene: Scene, player: *Player, result: *Frame_Result) {
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
}

update :: (scene: Scene, skull: *Skull, dt: float32) {
	if !scene.is_server
		interpolate_to_server(skull);

	skull.server.t += skull.server.speed * dt;

	path: *Path = *scene.terrain.paths[skull.path_id];
	if path.checkpoints_count > 0 {
		t := fmod_cycling(skull.client.t, path.checkpoints_count - 1.0);
		pos_before := path.checkpoints[cast(int) (floor(t) + 0)];
		pos_after  := path.checkpoints[cast(int) (floor(t) + 1)];

		dir := normalize(pos_after - pos_before);
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

	tile, ok := tile_under(scene.terrain, player.server.position);
	if !ok {
		return;
	}

	// Let's see if we are still on a tile of the same kind of our confirmed tile.
	is_still_on := touch_a_tile(
		scene.terrain,
		player.server.position,
		player.server.radius_hitbox_confirmed,
		player.server.confirmed_tile
	);

	// If we aren't then we switch to the tile we are currently on.
	if !is_still_on {
		if #complete tile.kind == {
			case .Ice; #through;
			case .Slippy_Ice;
				player.server.slipping = true;
				player.server.walking_toward = false;
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
			array_add(*response.coin_spawn, cmd);

			scene.coin_generation += 1;
			return true;
		}
	}

	return false;
}

process_client_only :: (scene: *Scene, command: Command, response: *Process_Response) -> bool {
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

	sync_moving_frame: *Command.Sync_Moving_Frame = isa(command.payload, Command.Sync_Moving_Frame);
	if sync_moving_frame {
		frame := find_by_frame_id(scene, sync_moving_frame.frame_id);
		if frame {
			frame.server.t = sync_moving_frame.t;
			return true;
		}
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
		player := find_by_player_id(scene, spawn.player_id);

		if !player {
			new_player: Player;
			new_player.id = spawn.player_id;
			array_add(*scene.players, new_player);
			player = *scene.players[scene.players.count - 1];
		}

		spawn_into(player, scene.terrain);
		if spawn.its_you {
			scene.controlled_player_id = spawn.player_id;
			dt := scene.camera.position - scene.camera.target;
			scene.camera.target = player.server.position;
			scene.camera.position = scene.camera.target + dt;
			scene.camera.locked_to = scene.controlled_player_id;
		}

		return true;
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
					player.server.dead = false;
					spawn_into(player, scene.terrain);
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
			array_add(*response.move, reply);
		}

		return true;
	}

	sync: *Command.Sync_Player = isa(command.payload, Command.Sync_Player);
	if sync {
		for * scene.players if it.id == sync.player_id {
			it.server.direction = sync.direction;
			it.server.position = sync.position;
			it.server.dead = sync.dead;
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

	tiles: [..] Tile;
	paths: [..] Path;
}
free :: (terrain: *Terrain) {
	array_free(terrain.tiles);
	array_free(terrain.paths);
	free(terrain.text);
}

load_terrain_from_ascii :: (ascii: string) -> Terrain {
	max_width := 1;
	height := 0;

	lines := split(ascii, "\n",, temp);
	height = lines.count;

	for lines
		max_width = max(max_width, it.count);
	max_width -= 1; // We remove the \n

	terrain: Terrain;
	terrain.tiles_count = .{ max_width, height };

	array_resize(*terrain.tiles, max_width * height);

	for * terrain.tiles {
		it.kind = .None;
	}

	for y: 0..height - 1 {
		line := lines[height - 1 - y];
		if line.count <= 1
			continue;

		width := line.count - 1;

		low_x := (max_width - width) / 2;
		hi_x := low_x + width;

		for x: low_x..hi_x-1 {
			if line[x] == {
				case #char "I";
					terrain.tiles[x + y * terrain.tiles_count.x].kind = .Ice;
				case #char "G";
					terrain.tiles[x + y * terrain.tiles_count.x].kind = .Grass;
				case #char "i";
					terrain.tiles[x + y * terrain.tiles_count.x].kind = .Slippy_Ice;
				case #char "X";
					terrain.tiles[x + y * terrain.tiles_count.x].kind = .Dirt;
				case #char "S";
					terrain.tiles[x + y * terrain.tiles_count.x].kind = .Grass;
					terrain.spawn_tile = .{ x, y };
			}
		}
	}

	return terrain;
}

tile_under :: (terrain: Terrain, spot: V3f) -> Tile, bool {
	xi := cast(int) floor(spot.x);
	yi := cast(int) floor(spot.y);

	if xi < 0 || xi >= terrain.tiles_count.x || yi < 0 || yi >= terrain.tiles_count.y {
		return Tile.{}, false; // Out of bounds
	}

	tile_index := xi + yi * terrain.tiles_count.x;
	if tile_index < 0 || tile_index >= terrain.tiles.count {
		return Tile.{}, false; // Out of bounds
	}

	return terrain.tiles[tile_index], true; // Return the tile and true to indicate it exists
}

touch_a_tile :: (terrain: Terrain, spot: V3f, radius: float, kind: Tile.Kind) -> bool {
	lo_x := cast(int) floor(spot.x - radius);
	hi_x := cast(int) ceil(spot.x + radius);
	lo_y := cast(int) floor(spot.y - radius);
	hi_y := cast(int) ceil(spot.y + radius);

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
			d := dist_aabb(spot, .{ xx x, xx  y, 0 }, .{ x + 1.0, y + 1.0, 0 });
			if d < radius && tile.kind == kind {
				return true;
			}
		}
	}

	return false;
}

render :: (scene: Scene) {
	store := scene.store;
	V := look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	P := perspective(scene.camera);

	Render.set_uniform(*store.model_shader, "V", V);
	Render.set_uniform(*store.model_shader, "P", P);
	Render.set_uniform(*store.texture_shader, "V", V);
	Render.set_uniform(*store.texture_shader, "P", P);
	Render.set_uniform(*store.tile_shader, "V", V);
	Render.set_uniform(*store.tile_shader, "P", P);

	Render.set_uniform(*store.texture_shader, "tint", V3f.{ 1.0, 1.0, 1.0 });
	Render.set_uniform(*store.texture_shader, "texture_sampler", store.ice_texture, 0);
	Render.set_uniform(*store.texture_shader, "texture_offset", V2f.{ 0, 0 });

	used_texture := *store.ice_texture;
	render_terrain(scene, *scene.terrain);

	Render.set_uniform(*store.texture_shader, "texture_sampler", store.coin_texture, 0);
	for * scene.coins {
		R := to_rotation_matrix(axis_angle(V3f.{ 0, 0, 1 }, it.client.theta));

		M := M4f.translate(it.client.position) * R;
		Render.set_uniform(*store.texture_shader, "M", M);
		Render.render(store.coin_geometry, store.texture_shader);
	}

	Render.set_uniform(*store.model_shader, "tint", V3f.{ 1.0, 1.0, 1.0 });
	for * scene.keys {
		p := it.client.position;
		if it.holder >= 0
			p.z += 1;

		M := M4f.translate(p);
		Render.set_uniform(*store.model_shader, "M", M);
		Render.render(store.key_geometry, store.model_shader);
	}

	render_standin(scene);
	render_players(scene);
	render_skulls(scene);
	render_shurikens(scene);

	for * scene.tombstones {
		M := M4f.translate(it.position);

		Render.set_uniform(*store.model_shader, "M", M);
		Render.render(store.tombstone_geometry, store.model_shader);
	}

	for * scene.gates {
		R := to_rotation_matrix(from_unit_vectors(V3f.{ 1, 0, 0 }, it.direction));

		M := M4f.translate(it.position) * R;
		Render.set_uniform(*store.model_shader, "M", M);
		Render.render(store.gate_geometry, store.model_shader);

		if it.is_closed {
			Render.render(store.gate_close_geometry, store.model_shader);
		}
	}

	if to_float64_seconds(current_time_monotonic() - scene.mark_clicked_time) < 0.8 {
		Render.set_uniform(*store.texture_shader, "texture_sampler", store.mark_texture, 0);
		M := M4f.translate(scene.mark_clicked_pos);
		Render.set_uniform(*store.texture_shader, "M", M);
		t := to_float64_seconds(current_time_monotonic() - scene.mark_clicked_time);
		t /= 0.8;
		t = 1 - ((1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t));
		offset := V2f.{ 0, xx -t };
		Render.set_uniform(*store.texture_shader, "texture_offset", offset);
		context.rhi.glDisable(GL_CULL_FACE);
		Render.render(store.mark_geometry, store.texture_shader);
		context.rhi.glEnable(GL_CULL_FACE);
	}
}

render_standin :: (scene: Scene) {
	store := scene.store;
	for * scene.stand_in {
		M := M4f.translate(it.position);
		M = M * to_rotation_matrix(it.orientation);
		Render.set_uniform(*store.texture_shader, "M", M);
		geometry := get_geometry(scene.store, it.model_id);
		if !geometry {
			geometry = *store.spirit_geometry;
		}
		Render.set_uniform(*store.texture_shader, "texture_sampler", store.vehicle_colormap, 0);
		Render.render(geometry.*, store.texture_shader);
	}
}

render_players :: (scene: Scene) {
	store := scene.store;
	colors :: V3f.[
		V3f.{ 1.0, 0.8, 0.8 },
		V3f.{ 0.8, 1.0, 0.8 },
		V3f.{ 0.8, 0.8, 1.0 },
		V3f.{ 1.0, 1.0, 0.8 },
		V3f.{ 1.0, 0.8, 1.0 },
		V3f.{ 0.8, 1.0, 1.0 },
		V3f.{ 1.0, 1.0, 1.0 }
	];
	Render.set_uniform(*store.texture_shader, "texture_offset", V2f.{ 0, 0 });
	for * scene.players {
		if !it.server.dead {
			M := M4f.identity();

			q := from_unit_vectors(V3f.{ 1, 0, 0 }, it.client.direction);
			M = to_rotation_matrix(q);

			M = M4f.translate(it.client.position) * M;

			Render.set_uniform(*store.texture_shader, "M", M);
			// Render.set_uniform(*scene.texture_shader, "tint", colors[it.id % colors.count]);
			Render.set_uniform(*store.texture_shader, "texture_sampler", store.vehicle_colormap, 0);

			geometry := get_geometry(scene.store, it.server.model_id);
			if !geometry {
				geometry = *store.spirit_geometry;
			}

			Render.render(geometry.*, store.texture_shader);
		}
	}
	// Render.set_uniform(*scene.model_shader, "tint", V3f.{ 1, 1, 1 });
}

render_shurikens :: (scene: Scene) {
	store := scene.store;
	instanced := NewArray(
		scene.shurikens.count, Render.Geometry.Instance_Data, initialized = false,, temp
	);

	for * scene.shurikens {
		M := compute_moving_frame_server_world_matrix(scene, find_by_frame_id(scene, it.frame_id));
		M *= M4f.translate(it.server.position) * to_rotation_matrix(
			axis_angle(V3f.{ 0, 0, 1 }, it.client.theta)
		);
		instance := *instanced[it_index];
		instance.kind = -1;
		instance.M = M;
	}

	Render.add_instance(*store.shuriken_geometry, .{
		data = xx instanced.data,
		count = instanced.count * size_of(Render.Geometry.Instance_Data)
	});

	Render.enable_instanced_attributes(3);
	Render.render_instanced(store.shuriken_geometry, store.tile_shader, instanced.count);
}

render_skulls :: (scene: Scene) {
	store := scene.store;
	instanced := NewArray(
		scene.skulls.count, Render.Geometry.Instance_Data, initialized = false,, temp
	);

	for * skull: scene.skulls {
		instance := *instanced[it_index];
		instance.kind = -1;
		instance.M = compute_skull_matrix(scene, skull);
	}

	Render.add_instance(*store.skull_geometry, .{
		data = xx instanced.data,
		count = instanced.count * size_of(Render.Geometry.Instance_Data)
	});

	Render.enable_instanced_attributes(3);
	Render.render_instanced(store.skull_geometry, store.tile_shader, instanced.count);
}

render_terrain :: (scene: Scene, terrain: *Terrain) {
	store := scene.store;
	if terrain.tiles_count.x <= 0 || terrain.tiles_count.y <= 0
		return;

	instanced := NewArray(
		terrain.tiles.count, Render.Geometry.Instance_Data, initialized = false,, temp
	);

	for 0..4 {
		if !scene.tile_kind_to_shader[it]
			continue;

		name := sprint("samplers[%]", it);
		Render.set_uniform(
			*store.tile_shader, name, scene.tile_kind_to_shader[it], it
		);
		free(name);
	}

	for * tile: terrain.tiles {
		x := it_index % terrain.tiles_count.x;
		y := it_index / terrain.tiles_count.x;

		instance := *instanced[it_index];
		instance.kind = xx tile.kind;
		instance.M = M4f.translate(.{ cast(float32) x, cast(float32) y, 0 });
	}

	Render.add_instance(*store.tile_geometry, .{
		data = xx instanced.data,
		count = terrain.tiles.count * size_of(Render.Geometry.Instance_Data)
	});

	Render.enable_instanced_attributes(3);
	Render.render_instanced(store.tile_geometry, store.tile_shader, terrain.tiles.count);
}

compute_skull_matrix :: (scene: Scene, skull: Skull) -> M4f {
	if skull.path_id >= scene.terrain.paths.count
		return M4f.identity();

	path: *Path = *scene.terrain.paths[skull.path_id];
	if path.checkpoints_count == 0
		return M4f.identity();

	t := fmod_cycling(skull.client.t, path.checkpoints_count - 1.0);
	pos_before := path.checkpoints[cast(int) (floor(t) + 0)];
	pos_after  := path.checkpoints[cast(int) (floor(t) + 1)];
	t -= floor(t);

	pos := pos_before + (pos_after - pos_before) * t;

	return M4f.translate(pos) * to_rotation_matrix(
		from_unit_vectors(V3f.{ 1, 0, 0 }, skull.client.direction)
	);
}

compute_skull_pos :: (scene: Scene, skull: Skull) -> V3f {
	if skull.path_id >= scene.terrain.paths.count
		return .{ 0, 0, 0 };

	path: *Path = *scene.terrain.paths[skull.path_id];
	if path.checkpoints_count == 0
		return .{ 0, 0, 0 };

	t := fmod_cycling(skull.server.t, path.checkpoints_count - 1.0);
	pos_before := path.checkpoints[cast(int) (floor(t) + 0)];
	pos_after  := path.checkpoints[cast(int) (floor(t) + 1)];
	t -= floor(t);

	return pos_before + (pos_after - pos_before) * t;
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

spawn_into :: (player: *Player, terrain: Terrain) {
	player.server.position.x = xx terrain.spawn_tile.x + 0.5;
	player.server.position.y = xx terrain.spawn_tile.y + 0.5;
	player.server.walking_toward = false;
	player.server.slipping = false;
	player.server.dead = false;
}

remove_player_from_scene :: (player_id: int, scene: *Scene) {
	for * scene.players {
		if it.id == player_id {
			remove it;
			break;
		}
	}
}