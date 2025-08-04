#import "Algebra";
#import "Math";
#import "Basic";
#import "String";
Render :: #import "Render";
#import "Tagged_Union";
#import "Communication";

#scope_export


Scene :: struct {
	texture_shader: Render.Shader;
	ice_texture: Render.Texture;
	grass_texture: Render.Texture;

	tile_geometry: Render.Geometry;

	camera: Camera;

	players: [..] Player;
	controlled_player_id := 0;

	current_terrain: *Terrain;
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


Player :: struct {
	id := 0;

	position  := V3f.{ 0, 0, 0 };
	direction := V3f.{ 1, 0, 0 };
	target_direction := V3f.{ 1, 0, 0 };

	walking_toward_position := V3f.{ 0, 0, 0 };
	walking_toward := false;

	slipping := false;

	speed := 10.0;
	turning_speed := 360 * 2.5;
}

update :: (scene: Scene, player: *Player, dt: float32) {
	tile, ok := tile_under(scene.current_terrain, player.position);
	if !ok {
		return;
	}
	if #complete tile.kind == {
		case .Ice; #through;
		case .Slippy_Ice;
			player.slipping = true;
		case .Grass;
			player.slipping = false;
		case .None;
	}

	if player.slipping {
		dt_angle := angle_between(player.direction, player.target_direction, V3f.{ 0, 0, 1 });
		turn_angle := 0.0;
		if dt_angle < 0
			turn_angle = -min(player.turning_speed * dt * DEG_RAD, -dt_angle);
		else
			turn_angle = min(player.turning_speed * dt * DEG_RAD, dt_angle);

		q := axis_angle(V3f.{ 0, 0, 1 }, turn_angle);
		player.direction = q * player.direction;
		player.direction = normalize(player.direction);

		player.position += player.direction * player.speed * dt;
	} else {
		player.direction = player.target_direction;

		if player.walking_toward {
			dt_pos := player.walking_toward_position - player.position;
			dist := norm(dt_pos);
			dt_pos = normalize(dt_pos);

			dist = min(dist, player.speed * dt);
			player.position += dt_pos * dist;
			player.target_direction = dt_pos;

			if norm(player.position - player.walking_toward_position) < 0.1 {
				player.walking_toward = false;
				player.walking_toward_position = player.position; // Reset to current position
			}
		}
	}
}

process :: (scene: *Scene, command: Command) -> bool {
	print("Processing %\n", command);

	spawn: *Command.Spawn = isa(command.payload, Command.Spawn);
	if spawn {
		player: Player;
		player.id = spawn.player_id;

		if spawn.its_you {
			scene.controlled_player_id = spawn.player_id;
		}
		
		spawn_into(*player, scene.current_terrain);

		array_add(*scene.players, player);
		return true;
	}
	for * scene.players {
		if process(scene, it, command)
			return true;
	}
	return false;
}

process :: (scene: Scene, player: *Player, command: Command) -> bool {
	move : *Command.Move = isa(command.payload, Command.Move);
	if move && move.player_id == player.id {
		tile, ok := tile_under(scene.current_terrain, player.position);
		if ok {
			if #complete tile.kind == {
				case .Ice; #through;
				case .Slippy_Ice;
					player.target_direction = normalize(
						v3(move.ground_target - v2(player.position))
					);
					player.walking_toward = false;
				case .Grass;
					player.walking_toward = true;
					player.walking_toward_position = v3(move.ground_target);
				case .None;
			}
		}

		return true;
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
	player.position.x = xx terrain.spawn_tile.x + 0.0;
	player.position.y = xx terrain.spawn_tile.y + 0.0;
}