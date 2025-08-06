#import "Algebra";
#import "Math";
#import "Basic";
#import "String";
Render :: #import "Render";
#import "Tagged_Union";
#import "Communication";

#scope_export


Scene :: struct {
	is_server := false;

	texture_shader: Render.Shader;
	ice_texture: Render.Texture;
	grass_texture: Render.Texture;

	tile_geometry: Render.Geometry;

	camera: Camera;

	players: [..] Player;
	controlled_player_id := 0;

	tombstones: [..] Tombstone;

	current_terrain: *Terrain;
}

Frame_Result :: struct {
	died: [..] Command.Die;
	respawn: [..] Command.Respawn;
}
free :: (frame_result: *Frame_Result) {
	array_free(frame_result.died);
	array_free(frame_result.respawn);
}
clear :: (frame_result: *Frame_Result) {
	frame_result.died.count = 0;
	frame_result.respawn.count = 0;
}

Process_Response :: struct {
	move: [..] Command.Move;
}
free :: (process_response: *Process_Response) {
	array_free(process_response.move);
}
clear :: (response: *Process_Response) {
	response.move.count = 0;
}

Camera :: struct {
	position: V3f;
	target:   V3f;

	fov  := 65.0;
	near := 0.1;
	far  := 1000.0;
	aspect := 1280/720.0;
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

Tombstone :: struct {
	player_id: int;
	position: V3f;
}

Player :: struct {
	id := 0;

	// This is the stuff that gets overwritten as soon as we get information from the server.
	server: struct {
		position: V3f;
		direction: V3f;
		target_direction := V3f.{ 1, 0, 0 };
		walking_toward_position := V3f.{ 0, 0, 0 };
		walking_toward := false;
		slipping := false;
		speed := 10.0;
		turning_speed := 360 * 2.5;
		dead := false;
	};

	// This is the stuff that gets optimistically updated by the client. For rendering
	client: struct {
		position  := V3f.{ 0, 0, 0 };
		direction := V3f.{ 1, 0, 0 };
	};
}

find_by_player_id :: (scene: Scene, id: int) -> *Player {
	for * scene.players {
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

interpolate_to_server :: (player: *Player) {
	player.client.direction += 0.2 * (player.server.direction - player.client.direction);
	player.client.direction = normalize(player.client.direction);
	player.client.position += 0.2 * (player.server.position - player.client.position);
}

update :: (scene: *Scene, dt: float32, result: *Frame_Result) {
	for * scene.players {
		update(scene, it, dt);

	}
	if scene.is_server {
		for * scene.players {
			if !it.server.dead {
				tile, ok := tile_under(scene.current_terrain, it.server.position);
				if !ok && result {
					died: Command.Die;
					died.player_id = it.id;
					died.position = it.server.position;
					array_add(*result.died, died);
					it.server.dead = true;
					tombstone: Tombstone;
					tombstone.player_id = died.player_id;
					tombstone.position = died.position;

					array_add(*scene.tombstones, tombstone);
					continue;
				}

				for tomb: scene.tombstones {
					dt := norm(it.server.position - tomb.position);

					if dt < 3 {
						respawn: Command.Respawn;
						respawn.player_id = tomb.player_id;

						array_add(*result.respawn, respawn);

						player_to_respawn := find_by_player_id(scene, tomb.player_id);
						if player_to_respawn {
							player_to_respawn.server.dead = false;
							spawn_into(player_to_respawn, scene.current_terrain);
						}

						remove tomb;
					}
				}
			}
		}
	}
}

update :: (scene: Scene, player: *Player, dt: float32) {
	if !scene.is_server
		interpolate_to_server(player);

	if player.server.dead
		return;

	tile, ok := tile_under(scene.current_terrain, player.server.position);
	if !ok {
		return;
	}

	if #complete tile.kind == {
		case .Ice; #through;
		case .Slippy_Ice;
			player.server.slipping = true;
		case .Grass;
			player.server.slipping = false;
		case .None;
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

		player.server.position += player.server.direction * player.server.speed * dt;
	} else {
		player.server.direction = player.server.target_direction;

		if player.server.walking_toward {
			dt_pos := player.server.walking_toward_position - player.server.position;
			dist := norm(dt_pos);
			dt_pos = normalize(dt_pos);

			dist = min(dist, player.server.speed * dt);
			player.server.position += dt_pos * dist;
			player.server.target_direction = dt_pos;

			if norm(player.server.position - player.server.walking_toward_position) < 0.1 {
				player.server.walking_toward = false;
				player.server.walking_toward_position = player.server.position;
			}
		}
	}
}

process :: (scene: *Scene, command: Command, response: *Process_Response) -> bool {
	spawn: *Command.Spawn = isa(command.payload, Command.Spawn);
	if spawn {
		print("Process spawn %\n", spawn.*);
		player: Player;
		player.id = spawn.player_id;

		if spawn.its_you {
			scene.controlled_player_id = spawn.player_id;
		}
		
		spawn_into(*player, scene.current_terrain);

		array_add(*scene.players, player);
		return true;
	}

	quit: *Command.Quit = isa(command.payload, Command.Quit);
	if quit {
		print("Process quit %\n", quit.*);
		remove_player_from_scene(quit.player_id, scene);
		return true;
	}

	died: *Command.Die = isa(command.payload, Command.Die);
	if died {
		print("Process die %\n", died.*);
		player := find_by_player_id(scene, died.player_id);
		if player
		{
			player.server.dead = true;
			tombstone: Tombstone;
			tombstone.player_id = died.player_id;
			tombstone.position = died.position;

			array_add(*scene.tombstones, tombstone);
		}
	}

	respawn: *Command.Respawn = isa(command.payload, Command.Respawn);
	if respawn {
		print("Process respawn %\n", respawn.*);

		for * scene.tombstones {
			if it.player_id == respawn.player_id {

				player := find_by_player_id(scene, it.player_id);
				player.server.dead = false;
				spawn_into(player, scene.current_terrain);

				remove it;
			}
		}
	}

	for * scene.players {
		if process(scene, it, command, response)
			return true;
	}
	return false;
}

process :: (scene: Scene, player: *Player, command: Command, response: *Process_Response) -> bool {
	move : *Command.Move = isa(command.payload, Command.Move);
	if move && move.player_id == player.id {
		print("Process move %\n", move.*);
		tile, ok := tile_under(scene.current_terrain, player.server.position);
		if ok {
			if #complete tile.kind == {
				case .Ice; #through;
				case .Slippy_Ice;
					player.server.target_direction = normalize(
						v3(move.ground_target - v2(player.server.position))
					);
					player.server.walking_toward = false;
				case .Grass;
					player.server.walking_toward = true;
					player.server.walking_toward_position = v3(move.ground_target);
				case .None;
			}
		}

		if response {
			reply: Command.Move;
			reply.player_id = player.id;
			reply.ground_target = move.ground_target;
			array_add(*response.move, reply);
		}

		return true;
	}

	sync: *Command.Sync_Player = isa(command.payload, Command.Sync_Player);
	if sync {
		print("Process sync %\n", sync.*);
		for * scene.players if it.id == sync.player_id {

			it.server.direction = sync.direction;
			it.server.position = sync.position;
			it.server.dead = sync.dead;
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
	}

	kind: Kind;
}

Terrain :: struct {
	tiles_count: V2i;
	spawn_tile: V2i;

	tiles: [..] Tile;
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

render :: (scene: Scene, terrain: Terrain) {
	V := look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	P := perspective(scene.camera);

	Render.set_uniform(scene.texture_shader, "V", V);
	Render.set_uniform(scene.texture_shader, "P", P);
	Render.set_uniform(scene.texture_shader, "tint", V3f.{ 1.0, 1.0, 1.0 });
	Render.set_uniform(scene.texture_shader, "texture_sampler", scene.ice_texture, 0);

	used_texture := *scene.ice_texture;

	for y: 0..terrain.tiles_count.y - 1 {
		for x: 0..terrain.tiles_count.x - 1 {
			tile := terrain.tiles[x + y * terrain.tiles_count.x];

			wanted_texture := *scene.ice_texture;
			if tile.kind == {
				case .Ice;
					wanted_texture = *scene.ice_texture;
				case .Grass;
					wanted_texture = *scene.grass_texture;
			}

			if wanted_texture != used_texture {
				Render.set_uniform(scene.texture_shader, "texture_sampler", wanted_texture.*, 0);
				used_texture = wanted_texture;
			}

			M := M4f.translate(.{ cast(float32) x, cast(float32) y, 0 });
			Render.set_uniform(scene.texture_shader, "M", M);
			Render.render(scene.tile_geometry, scene.texture_shader);
		}
	}
}
spawn_into :: (player: *Player, terrain: Terrain) {
	player.server.position.x = xx terrain.spawn_tile.x + 0.0;
	player.server.position.y = xx terrain.spawn_tile.y + 0.0;
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