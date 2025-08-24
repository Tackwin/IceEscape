#import "Scene";
#import "Basic";
#import "Algebra";
#import "Store";
#import "String";
#import "Hash_Table";

#scope_export

PICK_STRING :: #string TERRAIN
XXXXXXXXXXXXXXXXXXXXX
XXXXXIGIIGIIGIIXXXXXX
XXXGIIGIIGIIGIIIGXXXX
XXIIIIIIIIIIIIIIIIXXX
XGGIIIIIIIIIIIIIIGGXX
XIIIIIIIiiiIIIIIIIIXX
XGGIIIIIiiiIIIIIIGGXX
XIIIIIIIIIIIIIIIIIIXX
XXIGIIIIXGXIIIIIGIXXX
XXIGIIGIXGXIGIIIGIXXX
XXXXXIGIXGXIGIIXXXXXX
XXXXXXXXXSXXXXXXXXXXX

standin
- model_id: 1
- position: 9.5 10.5 0.0
- orientation_dir: 0 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 9.5 10.5 0.0
- radius: 1.0
- model_id: 1

standin
- model_id: 2
- position: 6.5 10.5 0.0
- orientation_dir: 0 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 6.5 10.5 0.0
- radius: 1.0
- model_id: 2

standin
- model_id: 3
- position: 12.5 10.5 0.0
- orientation_dir: 0 -1 0

trigger_zone
- accept_player_id: -1
- trigger: Move_To_Play_World
- position: 12.5 10.5 0.0
- radius: 1.0
- model_id: 3

TERRAIN;

ROUNDABOUT_STRING :: #string TERRAIN
XXXXXXXXXGGGGGGGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXGGGGGGGIIIIIXIIIIIIIXIIIIIIIXIIIIIIIIIXXXX
XXXXXXXXXGGGGGGGIIIIIXIIIIIIIXIIIIIIIXIIIIIIIIIXXXX
XXXXXXXXXGGGGGGGIIIIIXIIIIIIIXIIIIIIIXIIIIIIIIIIIXX
XXXXXXXXXGGGGGGGXXXIIXIIIXIIIXIIIXIIIXIIIIIIIIIIIXX
XXXXXXXXXXXXXXXXXXXIIXIIIXIIIXIIIXIIIXIIIXXXIIIIIXX
XXXXXXXXXXXXXXXXXXXIIXIIIXIIIXIIIXIIIXIIIXXXIIIIIXX
XXXXXXXXXXXXXXXIIIIIIXIIIXIIIXIIIXIIIXIIIXXXXXIIIXX
XXXXXXXXXXXXXXXIIIIIIXIIIXIIIXIIIXIIIXIIIXIIIIIIIXX
XXXXXXXXXXXXXXXIIIIIIXIIIXIIIXIIIXIIIXIIIXIIIIIIIXX
XXXXXXXXXXXXXXXIIIIIIIIIIXIIIIIIIXIIIIIIIXIIIIIIIXX
XXXXXXXXXXXGGGGIIIIIIIIIIXIIIIIIIXIIIIIIIXXXXXGGXXX
XXXXXXXXXXXIXXXIIIIIIIIIIXIIIIIIIXIIIIIIIXXXXXGGXXX
XXXXXXXXXXXIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXIXXXXXXXXXXXXXIIIIIIIIIIIIXXXIIIIIIIIIXX
XIGGIIIIIIXIXGIIIIIIIXXXiiiiiiiiiiiiiiiiiiiiiiiiiiX
XIGGIIIIIIXIXGIXXXXXIXXXiiiiiiiiGiiiiiiiiiiiGiiiiiX
XIIIIIIIIIXIXXIIXXXXIXXXiiiiiGiiiiiGiiiiiGiiiiiGiiX
XIIIIIIIIIXIXXIIIIXXIXXXiiiiiiiiXiiiiiiiiiiiXiiiiiX
XIIIIIIIIIXIXXIIIIXXIXXXiiiiiiiiXiiiiiiiiiiiXiiiiiX
XIIIIIIIIIXIXXXXXIXXGGGGGiiiGiXXXXXiGiiiGiXXXXXiGiX
XIIIIIIIIXXIIXXXIIXXGXXXiiiiiiiiXiiiiiiiiiiiXiiiiiX
XIIIIIIIIGGIIIIIIIXXGXXXiiiiiiiiXiiiiiiiiiiiXiiiiiX
XIIIIIIIIXXXXXXXXXXXGXXXiiiiiGiiiiiGiiiiiGiiiiiGGiX
XIGGIIIIIIIIIIIIGGXGGGXXiiiiiiiiGiiiiiiiiiiiGiiGGiX
XIGGIIIIIIIIIIIIGGXGSGXXiiiiiiiiiiiiiiiiiiiiiiiiiiX
XIIIIIIIIIIIIIIIGGXGGGXXXIIIIIIIIIIIIXXXIIIIIIIIIXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

path
- checkpoint: 28.5 7.5 0.0
- checkpoint: 29.5 10.5 0.0
- checkpoint: 32.5 11.5 0.0
- checkpoint: 35.5 10.5 0.0
- checkpoint: 36.5 7.5 0.0
- checkpoint: 35.5 4.5 0.0
- checkpoint: 32.5 3.5 0.0
- checkpoint: 29.5 4.5 0.0
- checkpoint: 28.5 7.5 0.0

path
- checkpoint: 40.5 7.5 0.0
- checkpoint: 41.5 10.5 0.0
- checkpoint: 44.5 11.5 0.0
- checkpoint: 47.5 10.5 0.0
- checkpoint: 48.5 7.5 0.0
- checkpoint: 47.5 4.5 0.0
- checkpoint: 44.5 3.5 0.0
- checkpoint: 41.5 4.5 0.0
- checkpoint: 40.5 7.5 0.0

path
- checkpoint: 8.5 2.5 0.0
- checkpoint: 8.5 11.5 0.0

path
- checkpoint: 17.5 8.5 0.0
- checkpoint: 14.5 10.5 0.0
- checkpoint: 17.5 8.5 0.0

gate
- position: 12.5 26.5 0.0
- direction: 1 0 0
- is_closed: true
- wait_for_key_id: 2
- is_end: true

gate
- position: 12.5 17.5 0.0
- direction: 1 0 0
- is_closed: true
- wait_for_key_id: 1

flag
- position: 14 17.5 0
- index: 0

skull
- path_id: 0
- speed: 1.1
- t: 0

skull
- path_id: 0
- speed: 1.1
- t: 2

skull
- path_id: 0
- speed: 1.1
- t: 4

skull
- path_id: 0
- speed: 1.1
- t: 6

skull
- path_id: 1
- speed: 1.1
- t: 0

skull
- path_id: 1
- speed: 1.1
- t: 2

skull
- path_id: 1
- speed: 1.1

skull
- path_id: 1
- speed: 1.1
- t: 6

skull
- path_id: 2
- speed: 0.75

skull
- path_id: 3
- speed: 0.5

key
- position: 48 4 0

key
- position: 47 17 0

// theta is in turn
moving_frame
- key
-- position: 21.5 22.5 0.0
-- theta: 0
-- period: 7
- key
-- position: 39.5 22.5 0.0
-- theta: 1.5
-- period: 7
- key
-- position: 21.5 22.5 0.0
-- theta: 3
-- period: 0
- speed: 0.8
- t: 0

shuriken
- frame_id: 1
- position: 0 0 0

shuriken
- frame_id: 1
- position: 1.75 0 0

shuriken
- frame_id: 1
- position: -1.75 0 0

shuriken
- frame_id: 1
- position: 3.5 0 0

shuriken
- frame_id: 1
- position: -3.5 0 0

shuriken
- frame_id: 1
- position: 7 0 0

shuriken
- frame_id: 1
- position: -7 0 0

shuriken
- frame_id: 1
- position: 0 1.75 0

shuriken
- frame_id: 1
- position: 0 -1.75 0

shuriken
- frame_id: 1
- position: 0 3.5 0

shuriken
- frame_id: 1
- position: 0 -3.5 0


shuriken
- frame_id: 1
- position: 0 7 0

shuriken
- frame_id: 1
- position: 0 -7 0

TERRAIN

parse_terrain :: (text: string, scene: *Scene) {
	clear(scene);

	ascii_tiles: string;
	// Look for the first empty line, above would be the ascii tiles, and the rest is the entities.

	lines := split(text, "\n",, temp);

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

	new_terrain := load_terrain_from_ascii(ascii_tiles);
	new_terrain.text = alloc_string(text.count);
	memcpy(new_terrain.text.data, text.data, text.count);
	free(*scene.terrain);
	scene.terrain = new_terrain;

	while cursor < lines.count {
		defer cursor += 1;
		line := lines[cursor];

		if line.count == 0
			continue;
		if starts_with(line, "//")
			continue;

		if scan2(line, "flag") {
			flag: Flag;
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
				)
					continue;
				if scan2(line, "- index: %", *flag.index)
					continue;

				print("Error reading flag, unrecognized line: % (L%)\n", line, cursor);
				cursor -= 1;
			}

			cursor -= 1;
		}

		if scan2(line, "shuriken") {
			shuriken: Shuriken;
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
				cursor -= 1;
			}

			cursor -= 1;
		}

		if scan2(line, "moving_frame") {
			frame: Moving_Frame;
			frame.id = scene.moving_frames.count + 1;
			defer array_add(*scene.moving_frames, frame);

			cursor += 1;
			while cursor < lines.count {
				defer cursor += 1;
				line := lines[cursor];

				if line.count == 0
					continue;
				if starts_with(line, "//")
					continue;
				if !starts_with(line, "- ")
					break;

				if scan2(line, "- key") {
					key: Moving_Frame.Key;
					defer array_add(*frame.keys, key);

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

				if scan2(line, "- t: %", *frame.server.t)
					continue;

				print("Error reading moving frame, unrecognized line: % (L%)\n", line, cursor);
				cursor -= 1;
			}

			frame.client.t = frame.server.t;
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
				cursor -= 1;
			}

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

				if scan2(line, "- t: %", *skull.server.t)
					continue;

				print("Error reading skull, unrecognized line: % (L%)\n", line, cursor);
				cursor -= 1;
			}
			skull.client.t = skull.server.t;

			cursor -= 1;
		}

		if scan2(line, "gate") {
			gate: Gate;
			gate.id = scene.gates.count + 1;
			defer array_add(*scene.gates, gate);

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

				if scan2(line, "- is_end: %", *gate.is_end)
					continue;

				print("Error reading gate, unrecognized line: % (L%)\n", line, cursor);
				cursor -= 1;
			}

			cursor -= 1;
		}

		if scan2(line, "path") {
			path: Path;
			defer array_add(*scene.terrain.paths, path);

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
				if scan2(line, "- checkpoint: % % %", *pos.x, *pos.y, *pos.z) {
					path.checkpoints[path.checkpoints_count] = pos;
					path.checkpoints_count += 1;
					continue;
				}

				print("Error reading path, unrecognized line: % (L%)\n", line, cursor);
				cursor -= 1;
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
				cursor -= 1;
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
				cursor -= 1;
			}

			cursor -= 1;
		}
	}
}
