#import "Scene";
#import "Basic";

#scope_export

roundabout: Terrain;

init_roundabout :: (scene: *Scene) {
ASCII :: #string TERRAIN
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
TERRAIN



	str := ASCII;
	str.count -= 1;

	roundabout = load_terrain_from_ascii(str);
	scene.current_terrain = *roundabout;

	{
		path: Path;
		path.checkpoints[0] = .{ 18 + 10.5, 7.5, 0.0 };
		path.checkpoints[1] = .{ 18 + 11.5, 10.5, 0.0 };
		path.checkpoints[2] = .{ 18 + 14.5, 11.5, 0.0 };
		path.checkpoints[3] = .{ 18 + 17.5, 10.5, 0.0 };
		path.checkpoints[4] = .{ 18 + 18.5, 7.5, 0.0 };
		path.checkpoints[5] = .{ 18 + 17.5, 4.5, 0.0 };
		path.checkpoints[6] = .{ 18 + 14.5, 3.5, 0.0 };
		path.checkpoints[7] = .{ 18 + 11.5, 4.5, 0.0 };
		path.checkpoints[8] = .{ 18 + 10.5, 7.5, 0.0 };
		path.checkpoints_count = 9;
		array_add(*roundabout.paths, path);
	}

	{
		path: Path;
		path.checkpoints[0] = .{ 18 + 12 + 10.5, 7.5, 0.0 };
		path.checkpoints[1] = .{ 18 + 12 + 11.5, 10.5, 0.0 };
		path.checkpoints[2] = .{ 18 + 12 + 14.5, 11.5, 0.0 };
		path.checkpoints[3] = .{ 18 + 12 + 17.5, 10.5, 0.0 };
		path.checkpoints[4] = .{ 18 + 12 + 18.5, 7.5, 0.0 };
		path.checkpoints[5] = .{ 18 + 12 + 17.5, 4.5, 0.0 };
		path.checkpoints[6] = .{ 18 + 12 + 14.5, 3.5, 0.0 };
		path.checkpoints[7] = .{ 18 + 12 + 11.5, 4.5, 0.0 };
		path.checkpoints[8] = .{ 18 + 12 + 10.5, 7.5, 0.0 };
		path.checkpoints_count = 9;
		array_add(*roundabout.paths, path);
	}

	{
		path: Path;
		path.checkpoints[0] = .{ 8.5, 2.5, 0.0 };
		path.checkpoints[1] = .{ 8.5, 11.5, 0.0 };
		path.checkpoints_count = 2;
		array_add(*roundabout.paths, path);
	}

	{
		path: Path;
		path.checkpoints[0] = .{ 17.5, 8.5, 0.0 };
		path.checkpoints[1] = .{ 14.5, 10.5, 0.0 };
		path.checkpoints[2] = .{ 17.5, 8.5, 0.0 };
		path.checkpoints_count = 3;
		array_add(*roundabout.paths, path);
	}

	scene.gates.count = 0;
	{
		gate: Gate;
		gate.id = 1;
		gate.position = .{ 12.5, 26.5, 0.0 };
		gate.direction = .{ 1, 0, 0 };
		gate.is_closed = true;
		gate.wait_for_key_id = 2;
		gate.is_end = true;
		array_add(*scene.gates, gate);
	}
	{
		gate: Gate;
		gate.id = 2;
		gate.position = .{ 13.5, 17.5, 0.0 };
		gate.direction = .{ 1, 0, 0 };
		gate.is_closed = true;
		gate.wait_for_key_id = 1;
		array_add(*scene.gates, gate);
	}

	scene.skulls.count = 0;
	for 0..3 {
		skull: Skull;
		skull.path_id = 0;
		skull.server.speed = 1.1;
		skull.id = scene.skulls.count;
		skull.server.t = it * 2.0;
		skull.client.t = skull.server.t;
		array_add(*scene.skulls, skull);
	}
	for 0..3 {
		skull: Skull;
		skull.path_id = 1;
		skull.server.speed = 1.1;
		skull.id = scene.skulls.count;
		skull.server.t = it * 2.0 + 1.0;
		skull.client.t = skull.server.t;
		array_add(*scene.skulls, skull);
	}

	{
		skull: Skull;
		skull.path_id = 2;
		skull.server.speed = 0.75;
		skull.id = scene.skulls.count;
		skull.server.t = 0;
		skull.client.t = 0;
		array_add(*scene.skulls, skull);
	}

	{
		skull: Skull;
		skull.path_id = 3;
		skull.server.speed = 0.5;
		skull.id = scene.skulls.count;
		skull.server.t = 0;
		skull.client.t = 0;
		array_add(*scene.skulls, skull);
	}

	scene.keys.count = 0;
	{
		key: Key;
		key.id = 1;
		key.server.position = .{ 48, 4, 0 };
		array_add(*scene.keys, key);
	}
	{
		key: Key;
		key.id = 2;
		key.server.position = .{ 47, 17, 0 };
		array_add(*scene.keys, key);
	}

	scene.moving_frames.count = 0;
	{
		frame: Moving_Frame;
		array_add(*frame.keys, Moving_Frame.Key.{
			pos = .{ 21.5, 22.5, 0 },
			theta = 0,
			period = 7
		});
		array_add(*frame.keys, Moving_Frame.Key.{
			pos = .{ 21.5 + 18, 22.5, 0 },
			theta = xx (3.1415926 * 2 * 1.5),
			period = 7
		});
		array_add(*frame.keys, Moving_Frame.Key.{
			pos = .{ 21.5, 22.5, 0 },
			theta = xx (3.1415926 * 2 * 3),
			period = 0.0
		});
		frame.id = 1;
		frame.server.t = 0.0;
		frame.server.speed = 0.8;
		array_add(*scene.moving_frames, frame);
	}

	scene.shurikens.count = 0;
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ 0, 0, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ 1.75, 0, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ -1.75, 0, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ 3.5, 0, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ -3.5, 0, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ 0, 1.75, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ 0, -1.75, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ 0, 3.5, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ 0, -3.5, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ 0, 7, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ 0, -7, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ 7, 0, 0 };
		array_add(*scene.shurikens, shuriken);
	}
	{
		shuriken: Shuriken;
		shuriken.frame_id = 1;
		shuriken.server.position = .{ -7, 0, 0 };
		array_add(*scene.shurikens, shuriken);
	}
}