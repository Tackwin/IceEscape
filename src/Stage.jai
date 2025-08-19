#import "Basic";
#import "Hash_Table";

Scene :: #import "Scene";
Platform :: #import "Platform";

#scope_export

Pick_Stage :: struct {
	model_id_to_geometry_idx: Hash_Table(int, int);

	geometries: [..] Render.Geometry;

	camera: Scene.Camera;

	Player :: struct {
		id: int;
		pos: V3f;
	};

	players: [..] Player;

	just_pressed: [Key_COUNT] bool;
	just_released: [Key_COUNT] bool;
	pressed: [Key_COUNT] bool;

	terrain: Scene.Terrain;
}

enter :: (state: *Pick_Stage) {
	state.camera = .{};
	state.camera.target = .{ 0, 0, 0 };
	state.camera.target_target = state.camera.target;
	state.camera.position = .{ 0, -4, 8 };
	scene.camera.wanted_target_to_position = scene.camera.position - scene.camera.target;
	scene.camera.fov = 55;

}

update :: (state: *Pick_Stage, frame_info: Platform.Frame_Info) {
	for * state.just_pressed {
		if frame_info.key_pressed[it_index] && !state.pressed[it_index]
			it.* = true;
		else
			it.* = false;
	}
	for * state.just_released {
		if !frame_info.key_pressed[it_index] && state.pressed[it_index]
			it.* = true;
		else
			it.* = false;
	}
	for * state.pressed {
		it.* = frame_info.key_pressed[it_index];
	}

	if state.just_pressed[Key.MouseLeft] {
		r := Scene.unproject_ndc(
			.{
				frame_info.mouse_position.x / frame_info.window_size.x * 2 - 1,
				1 - frame_info.mouse_position.y / frame_info.window_size.y * 2
			},
			V,
			P
		);

		target, ok := ray_plane(scene.camera.position, r, .{ 0, 0, 1 });
		if ok {
			command: Command.Move;
			command.ground_target = v2(target);
			command.player_id = scene.controlled_player_id;
			send_web_message(platform, make_command(command));
			scene.mark_clicked_time = current_time_monotonic();
			scene.mark_clicked_pos = target;
		}
	}
}
