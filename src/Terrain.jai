#import "Scene";
#import "Basic";
#import "Algebra";
Assets :: #import "Assets";
#import "String";
#import "Hash_Table";

#scope_export

// Typical camera need a center surronded by
//     8
// 9 Center 9
//     3

Config :: struct {
	antiair_offset_std := 0.0;
}

parse_terrain_name :: (text: string) -> string {
	name: string;
	lines := split(text, "\n",, temp);
	for lines {
		if starts_with(it, "- name: ") {
			name.data = it.data + 8;
			name.count = it.count - 8;
			return name;
		}
	}
	return "Unnamed terrain";
}

parse_terrain :: (text: string, scene: *Scene, generate_props: bool = true) {
	rng := Rand.seed(123456789);

	ascii_tiles: string;
	// Look for the first empty line, above would be the ascii tiles, and the rest is the entities.

	lines := split(text, "\n",, temp);

	config_stack: [..] Config;
	push_stack :: () #expand {
		if config_stack.count == 0
			array_add(*config_stack, .{});
		else
			array_add(*config_stack, config_stack[config_stack.count - 1]);
	}
	pop_stack :: () #expand {
		if config_stack.count > 0
			config_stack.count -= 1;
		else
			print("Warning: pop_stack on empty stack\n");
	}
	current_config :: () -> *Config #expand {
		if config_stack.count == 0
			return null;
		return *config_stack[config_stack.count - 1];
	}
	push_stack();

	cursor := 0;
	for lines {
		if it.count == 0 {
			ascii_tiles.data = text.data;
			ascii_tiles.count = xx (it.data - text.data);
			cursor = it_index;
			break;
		}
	}
	if ascii_tiles.count > 0 && ascii_tiles[ascii_tiles.count - 1] == #char "\n"
		ascii_tiles.count -= 1;

	scene.camera_min = v2(0.0);
	scene.camera_max = v2(0.0);

	new_terrain := load_terrain_from_ascii(ascii_tiles);
	new_terrain.text = alloc_string(text.count);
	memcpy(new_terrain.text.data, text.data, text.count);
	free(*scene.terrain);
	scene.terrain = new_terrain;
	spawn_set := false;
	scene.night = false;
	scene.spawn.size = .{ 0.05, 0.05 };

	while cursor < lines.count {
		defer cursor += 1;
		line := lines[cursor];

		if line.count == 0
			continue;
		if starts_with(line, "//")
			continue;

		if scan2(line, "- autorevive") {
			scene.auto_revive = true;
			continue;
		}

		if scan2(line, "- night") {
			scene.night = true;
			continue;
		}

		if starts_with(line, "- name: ") {
			name: string;
			name.data = line.data + 8;
			name.count = line.count - 8;
			for * scene.info.name {
				if it_index < name.count
					it.* = name[it_index];
				else
					it.* = 0;
			}
		}

		if scan2(line, "push") {
			push_stack();
			config := current_config();

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				if scan2(line, "- antiair_offset_std: %", *config.antiair_offset_std)
					continue;

				print("Error reading config, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "pop") {
			pop_stack();
			continue;
		}

		if scan2(line, "present") {
			present: Present;
			present.id = scene.presents.count + 1;
			defer array_add(*scene.presents, present);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *present.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				if scan2(line, "- kind: %", *present.kind)
					continue;

				if scan2(line, "- refresh_cooldown: %", *present.server.refresh_cooldown)
					continue;

				if scan2(line, "- depends_on_flag_id: %", *present.server.depends_on_flag_id)
					continue;

				print("Error reading present, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "antiair") {
			antiair: AntiAir;
			antiair.id = scene.antiairs.count + 1;
			antiair.server.t = 0.0;
			defer array_add(*scene.antiairs, antiair);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *antiair.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;
				target_pos_v3: V3f;
				if scan2(line, "- target: % % %", *target_pos_v3.x, *target_pos_v3.y, *target_pos_v3.z) {
					dtx := antiair.target_aabb.max.x - antiair.target_aabb.min.x;
					dty := antiair.target_aabb.max.y - antiair.target_aabb.min.y;
					antiair.target_aabb.min.x = target_pos_v3.x;
					antiair.target_aabb.min.y = target_pos_v3.y;
					antiair.target_aabb.max.x = target_pos_v3.x + dtx;
					antiair.target_aabb.max.y = target_pos_v3.y + dty;
					continue;
				}
				target_pos_v2: V2f;
				if scan2(line, "- target: % %", *target_pos_v2.x, *target_pos_v2.y) {
					dtx := antiair.target_aabb.max.x - antiair.target_aabb.min.x;
					dty := antiair.target_aabb.max.y - antiair.target_aabb.min.y;
					antiair.target_aabb.min.x = target_pos_v2.x;
					antiair.target_aabb.min.y = target_pos_v2.y;
					antiair.target_aabb.max.x = target_pos_v2.x + dtx;
					antiair.target_aabb.max.y = target_pos_v2.y + dty;
					continue;
				}
				target_size: V2f;
				if scan2(line, "- target_size: % %", *target_size.x, *target_size.y) {
					antiair.target_aabb.max.x = antiair.target_aabb.min.x + target_size.x;
					antiair.target_aabb.max.y = antiair.target_aabb.min.y + target_size.y;
					continue;
				}
				aabb: AABBf;
				if scan2(line, "- target_aabb: % % % %", *aabb.min.x, *aabb.min.y, *aabb.max.x, *aabb.max.y) {
					continue;
				}
				if scan2(line, "- cooldown: %", *antiair.cooldown)
					continue;
				if scan2(line, "- radius: %", *antiair.radius)
					continue;
				if scan2(line, "- offset_time: %", *antiair.server.t)
					continue;

				print("Error reading antiair, unrecognized line: % (L%)\n", line, cursor);
			}

			antiair.server.t += Rand.random_uniform(*rng, 0.0, current_config().antiair_offset_std);
			antiair.client.t = antiair.server.t;

			cursor -= 1;
		}

		if scan2(line, "turn_table") {
			turn_table := add_turn_table(scene, .{});
			turn_table.id = scene.turn_tables.count;

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *turn_table.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				if scan2(line, "- turning_speed: %", *turn_table.turning_speed)
					continue;

				period: float = 0.0;
				if scan2(line, "- turning_period: %", *period) {
					turn_table.turning_speed = 1.0 / period;
					continue;
				}

				if scan2(line, "- turning_offset: %", *turn_table.turning_offset)
					continue;
				
				print("Error reading turning table, unrecognized line: % (L%)\n", line, cursor);
			}
			cursor -= 1;
		}

		if scan2(line, "trophy") {
			trophy: Trophy;
			trophy.id = scene.trophies.count + 1;
			defer array_add(*scene.trophies, trophy);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *trophy.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				print("Error reading trophy, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "block_rock") {
			block_rock: Block_Rock;
			block_rock.id = scene.block_rocks.count + 1;
			defer array_add(*scene.block_rocks, block_rock);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *block_rock.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				print("Error reading block_rock, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "robot") {
			robot: Robot;
			robot.id = scene.robots.count + 1;
			defer array_add(*scene.robots, robot);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *robot.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				if scan2(line, "- max_rotation_speed: %", *robot.max_rotation_speed) {
					robot.max_rotation_speed *= 2 * 3.141592;
					continue;
				}

				if scan2(
					line,
					"- start_target_aabb: % %",
					*robot.target_aabb.min.x,
					*robot.target_aabb.min.y
				)
					continue;

				if scan2(
					line,
					"- end_target_aabb: % %",
					*robot.target_aabb.max.x,
					*robot.target_aabb.max.y
				)
					continue;

				size_aabb := v2(0.0);
				if scan2(
					line,
					"- size_target_aabb: % %",
					*size_aabb.x,
					*size_aabb.y
				) {
					robot.target_aabb.max.x = robot.target_aabb.min.x + size_aabb.x;
					robot.target_aabb.max.y = robot.target_aabb.min.y + size_aabb.y;
					continue;
				}
				if scan2(line, "- charging_time: %", *robot.charging_time)
					continue;

				if scan2(line, "- effectshoot_time: %", *robot.effectshoot_time)
					continue;
					
				if scan2(line, "- predict: %", *robot.predict)
					continue;

				if scan2(line, "- shooting_cd: %", *robot.shooting_cd)
					continue;

				if scan2(line, "- shooting_time: %", *robot.shooting_time)
					continue;

				if scan2(line, "- shooting_offset: %", *robot.shooting_offset)
					continue;

				print("Error reading robot, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "frame") {
			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				if scan2(line, "- position: % %", *scene.camera_min.x, *scene.camera_min.y) {
					scene.origin_tile_space = scene.camera_min;
					continue;
				}

				if scan2(line, "- size: % %", *scene.camera_max.x, *scene.camera_max.y) {
					scene.camera_max += scene.camera_min;
					continue;
				}

				if scan2(line, "- origin: % %", *scene.origin_tile_space.x, *scene.origin_tile_space.y) {
					continue;
				}

				print("Error reading frame, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "flag") {
			flag: Flag;
			flag.id = scene.flags.count + 1;
			flag.index = flag.id - 1;
			defer array_add(*scene.flags, flag);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				if scan2(
					line, "- position: % % %", *flag.position.x, *flag.position.y, *flag.position.z
				) {
					continue;
				}
				if scan2(line, "- index: %", *flag.index)
					continue;

				print("Error reading flag, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "shuriken") {
			shuriken: Shuriken;
			shuriken.id = scene.shurikens.count + 1;
			defer array_add(*scene.shurikens, shuriken);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				if scan2(line, "- frame_id: %", *shuriken.frame_id)
					continue;

				pos := *shuriken.server.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				print("Error reading shuriken, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "moving_frame") {
			frame: Moving_Frame;
			frame.id = scene.moving_frames.count + 1;
			frame.keys.index = scene.moving_frame_keys.count;
			frame.keys.count = 0;
			defer {
				frame.keys.count = scene.moving_frame_keys.count - frame.keys.index;
				array_add(*scene.moving_frames, frame);
			}

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				if scan2(line, "- key") {
					key: Moving_Frame.Key;
					defer array_add(*scene.moving_frame_keys, key);

					cursor += 1;
					while cursor < lines.count {
						defer cursor += 1;
						line := lines[cursor];

						if line.count == 0
							continue;
						if starts_with(line, "//")
							continue;
						if !starts_with(line, "-- ") {
							cursor -= 1;
							break;
						}

						if scan2(line, "-- position: % % %", *key.pos.x, *key.pos.y, *key.pos.z)
							continue;

						if scan2(line, "-- theta: %", *key.theta) {
							key.theta *= 2 * 3.141592;
							continue;
						}

						if scan2(line, "-- period: %", *key.period)
							continue;

						print("Error reading moving frame key, unrecognized line: % (L%)\n", line, cursor);
						cursor -= 1;
					}

					cursor -= 1;
					continue;
				}

				if scan2(line, "- speed: %", *frame.server.speed)
					continue;

				if scan2(line, "- offset: %", *frame.server.offset)
					continue;

				print("Error reading moving frame, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "key") {
			key: Key;
			key.id = scene.keys.count + 1;
			defer array_add(*scene.keys, key);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *key.server.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				print("Error reading key, unrecognized line: % (L%)\n", line, cursor);
			}

			key.server.home = key.server.position;
			cursor -= 1;
		}

		if scan2(line, "skull") {
			skull: Skull;
			skull.id = scene.skulls.count + 1;
			defer array_add(*scene.skulls, skull);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				if scan2(line, "- path_id: %", *skull.path_id)
					continue;

				if scan2(line, "- speed: %", *skull.server.speed)
					continue;

				if scan2(line, "- offset: %", *skull.server.offset)
					continue;

				print("Error reading skull, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "jukebox") {
			jukebox: Jukebox;
			jukebox.id = scene.jukeboxes.count + 1;
			defer array_add(*scene.jukeboxes, jukebox);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *jukebox.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				print("Error reading jukebox, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "pressbutton") {
			pressbutton: PressButton;
			pressbutton.id = scene.pressbuttons.count + 1;
			defer array_add(*scene.pressbuttons, pressbutton);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *pressbutton.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				if compare(line, "- radio") == 0 {
					pressbutton.is_radio = true;
					continue;
				}

				print("Error reading pressbutton, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "spawn") {
			spawn: Spawn;
			defer {
				scene.spawn = spawn;
			}
			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *spawn.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z) {
					spawn_set = true;
					continue;
				}
				size := *spawn.size;
				if scan2(line, "- size: % %", *size.x, *size.y)
					continue;

				print("Error reading spawn, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "bomb_spawner") {
			bomb_spawner: Bomb_Spawner;
			bomb_spawner.id = scene.bomb_spawners.count + 1;
			defer array_add(*scene.bomb_spawners, bomb_spawner);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *bomb_spawner.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				if scan2(line, "- explosion_time: %", *bomb_spawner.explosion_time)
					continue;
				if scan2(line, "- explosion_radius: %", *bomb_spawner.explosion_radius)
					continue;


				print("Error reading bomb spawner, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "lantern") {
			lantern: Lantern;
			lantern.id = scene.lanterns.count + 1;
			defer {
				array_add(*scene.lanterns, lantern);
			}

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *lantern.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				box := *lantern.light_aabb;
				if scan2(
					line, "- light_aabb: % % % %", *box.min.x, *box.min.y, *box.max.x, *box.max.y
				)
					continue;

				if scan2(line, "- intensity: %", *lantern.intensity)
					continue;
				id: int;
				if scan2(line, "- button_id: %", *id) {
					lantern.button_id = id;
					continue;
				}

				print("Error reading lantern, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "gate") {
			gate: Gate;
			gate.id = scene.gates.count + 1;
			gate.pressbutton_ids.index = scene.indices.count;
			defer {
				gate.pressbutton_ids.count = scene.indices.count - gate.pressbutton_ids.index;
				array_add(*scene.gates, gate);
			}

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *gate.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				dir := *gate.direction;
				if scan2(line, "- direction: % % %", *dir.x, *dir.y, *dir.z)
					continue;

				if scan2(line, "- is_closed: %", *gate.is_closed)
					continue;

				if scan2(line, "- wait_for_key_id: %", *gate.wait_for_key_id)
					continue;

				id: int;
				if scan2(line, "- wait_for_pressbutton_id: %", *id) {
					array_add(*scene.indices, id);
					continue;
				}

				if scan2(line, "- wait_for_trigger_id: %", *gate.wait_for_trigger_id)
					continue;

				if scan2(line, "- is_end: %", *gate.is_end)
					continue;

				print("Error reading gate, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "path") {
			path: Path;
			path.id = scene.paths.count;
			defer {
				array_add(*scene.paths, path);
			}

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				if compare(line, "- closed") == 0 {
					path.closed = true;
					continue;
				}
				if compare(line, "- theta_dir") == 0 {
					path.theta_dir = true;
					continue;
				}
				pos: V3f;
				if scan2(line, "- checkpoint: % % %", *pos.x, *pos.y, *pos.z) {
					checkpoint: Checkpoint;
					checkpoint.position = pos;
					add_checkpoint_to_path(scene, *path, checkpoint);
					continue;
				}
				theta: float;
				if scan2(line, "- checkpoint: % % % theta %", *pos.x, *pos.y, *pos.z, *theta) {
					checkpoint: Checkpoint;
					checkpoint.position = pos;
					checkpoint.theta = theta;
					add_checkpoint_to_path(scene, *path, checkpoint);
					continue;
				}
				speed: float;
				if scan2(line, "- checkpoint: % % % speed %", *pos.x, *pos.y, *pos.z, *speed) {
					checkpoint: Checkpoint;
					checkpoint.position = pos;
					checkpoint.speed = speed;
					add_checkpoint_to_path(scene, *path, checkpoint);
					continue;
				}
				if scan2(
					line,
					"- checkpoint: % % % theta % speed %",
					*pos.x,
					*pos.y,
					*pos.z,
					*theta,
					*speed
				) {
					checkpoint: Checkpoint;
					checkpoint.position = pos;
					checkpoint.theta = theta;
					checkpoint.speed = speed;
					add_checkpoint_to_path(scene, *path, checkpoint);
					continue;
				}
				if scene.checkpoints.count > 0 && scan2(
					line,
					"- checkpoint: theta % speed %",
					*theta,
					*speed
				) {
					checkpoint: Checkpoint;
					checkpoint.position = scene.checkpoints[scene.checkpoints.count - 1].position;
					checkpoint.theta = theta;
					checkpoint.speed = speed;
					add_checkpoint_to_path(scene, *path, checkpoint);
					continue;
				}

				print("Error reading path, unrecognized line: % (L%)\n", line, cursor);
			}
			cursor -= 1;
		}

		if scan2(line, "camera_rail") {
			rail: Camera_Rail;
			rail.id = scene.camera_rails.count;
			rail.waypoints.index = scene.camera_rail_waypoints.count;
			rail.waypoints.count = 0;
			defer {
				rail.waypoints.count = scene.camera_rail_waypoints.count - rail.waypoints.index;
				array_add(*scene.camera_rails, rail);
			}

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos: V3f;
				if scan2(line, "- waypoint: % % %", *pos.x, *pos.y, *pos.z) {
					array_add(*scene.camera_rail_waypoints, pos);
					continue;
				}

				print("Error reading camera_rail, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "camera_poi") {
			poi: Camera_POI;
			poi.id = scene.camera_pois.count;
			defer array_add(*scene.camera_pois, poi);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *poi.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				if scan2(line, "- zoom_out_factor: %", *poi.zoom_out_factor)
					continue;

				print("Error reading camera_poi, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2(line, "standin") {
			standin: Stand_In;
			standin.id = scene.stand_in.count + 1;
			defer array_add(*scene.stand_in, standin);
			
			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				if scan2(line, "- model_id: %", *standin.model_id)
					continue;

				pos := *standin.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				dir: V3f;
				if scan2(line, "- orientation_dir: % % %", *dir.x, *dir.y, *dir.z) {
					standin.orientation = from_unit_vectors(V3f.{ 1, 0, 0 }, dir);
					continue;
				}

				print("Error reading standin, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}
		if (scan2("trigger_zone", line)) {
			trigger: Trigger_Zone;
			trigger.id = scene.trigger_zones.count + 1;
			defer array_add(*scene.trigger_zones, trigger);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				if scan2(line, "- accept_player_id: %", *trigger.accept_player_id)
					continue;

				if scan2(line, "- trigger: %", *trigger.trigger)
					continue;

				if scan2(line, "- position: % % %", *trigger.pos.x, *trigger.pos.y, *trigger.pos.z)
					continue;

				if scan2(line, "- radius: %", *trigger.radius)
					continue;

				if scan2(line, "- model_id: %", *trigger.model_id)
					continue;

				print("Error reading trigger zone, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}
		if scan2("within_zone", line) {
			zone: Within_Zone;
			zone.id = scene.within_zones.count + 1;
			defer array_add(*scene.within_zones, zone);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				if scan2(line, "- position: % %", *zone.pos.x, *zone.pos.y)
					continue;

				if scan2(line, "- size: % %", *zone.size.x, *zone.size.y)
					continue;

				if scan2(line, "- min_player_percent: %", *zone.min_player_percent)
					continue;
				
				if scan2(line, "- time_to_stay: %", *zone.time_to_stay)
					continue;

				if scan2(line, "- trigger_id: %", *zone.trigger_id)
					continue;

				print("Error reading within zone, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}

		if scan2("trap", line) {
			trap: Trap;
			trap.id = scene.traps.count + 1;
			defer array_add(*scene.traps, trap);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ") {
					cursor -= 1;
					break;
				}

				pos := *trap.position;
				if scan2(line, "- position: % % %", *pos.x, *pos.y, *pos.z)
					continue;

				if scan2(line, "- radius_hitbox: %", *trap.radius_hitbox)
					continue;

				if scan2(line, "- stay_activated_time: %", *trap.stay_activated_time)
					continue;

				if line == "- activable" {
					trap.activable = true;
					continue;
				}
				

				print("Error reading trap, unrecognized line: % (L%)\n", line, cursor);
			}

			cursor -= 1;
		}
	}

	if !spawn_set {
		scene.spawn.position = tile_center(scene, scene.terrain.spawn_tile_);
	}

	get_probability :: (id: Assets.Prop_Id) -> float {
		if #complete id == {
			case .TERRAIN_TREE_SNOW_A;
				return 0.45;
			case .TERRAIN_TREE_SNOW_B;
				return 0.35;
			case .TERRAIN_TREE_SNOW_C;
				return 0.2;
			case .TERRAIN_SNOWMAN;
				return 0.04;
			case .TERRAIN_SNOWMAN_HAT;
				return 0.01;
			case .TERRAIN_SNOW_FLAT;
				return 0.075;
			case .TERRAIN_SNOW_FLAT_LARGE;
				return 0.05;
			case .TERRAIN_SNOW_PILE;
				return 0.015;
			case .TERRAIN_SNOWFLAKE_A;
			case .TERRAIN_SNOWFLAKE_B;
			case .TERRAIN_SNOWFLAKE_C;
			case .ROCK_SMALL;
				return 0.15;
			case .ROCK_MEDIUM;
				return 0.075;
			case .ROCK_LARGE;
				return 0.025;
		}
		return 0.0;
	}
	// Populate props
	for id: 0..16 {
		if generate_props for y: 0..scene.terrain.tiles_count.y-1 {
			for x: 0..scene.terrain.tiles_count.x-1 {
				tile : Tile = scene.terrain.tiles[x + y * scene.terrain.tiles_count.x];
				if tile.kind == .Dirt {
					r := Rand.random_uniform(*rng);
					if r < get_probability(xx id) * 1.25 {
						prop: Prop;
						prop.id = xx id;

						offx := Rand.random_uniform(*rng, -0.4, 0.4);
						offy := Rand.random_uniform(*rng, -0.4, 0.4);
						offtheta := Rand.random_uniform(*rng, 0, 2 * 3.141592);

						tilt := V3f.{ 0, 0, 2 };
						tilt.x = Rand.random_uniform(*rng, -0.1, 0.1);
						tilt.y = Rand.random_uniform(*rng, -0.1, 0.1);
						tilt = normalize(tilt);


						center := tile_center(scene, .{ x, y });

						prop.M = M4f.translate(center + V3f.{ offx, offy, 0 });
						scale := Rand.random_uniform(*rng, 0.9, 1.1);
						prop.M = prop.M * scale_matrix(V3f.{ scale, scale, scale });
						prop.M = prop.M * to_rotation_matrix(axis_angle(V3f.{ 0, 0, 1 }, offtheta));
						prop.M = prop.M * to_rotation_matrix(
							from_unit_vectors(V3f.{ 0, 0, 1 }, tilt)
						);

						array_add(*scene.props, prop);
					}
				}
			}
		}
	}

	scene.client_rng = Rand.seed(123456789);
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
				case #char "R";
					terrain.tiles[x + y * terrain.tiles_count.x].kind = .Funny_Ice;
				case #char "S";
					terrain.tiles[x + y * terrain.tiles_count.x].kind = .Grass;
					terrain.spawn_tile_ = .{ x, y };
			}
		}
	}

	return terrain;
}