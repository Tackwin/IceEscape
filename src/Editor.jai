#scope_file
Scene :: #import "Scene";
GUI :: #import "GUI";
#import "Reflect";
#import "Algebra";
#import "Basic";
#import "Math";

#scope_export
Editor_Mode :: enum {
	Tiles;
	Entities;
}

// A Array of every types that can be placed in the editor.
editable_entities_type :: Type.[
	Scene.Gate,
	Scene.Trap,
	Scene.Trophy,
	Scene.Flag
];

Editor :: struct {
	scene: Scene.Scene;
	gui_state: GUI.GUI_State;

	// Editor mode
	mode: Editor_Mode = .Tiles;

	selected_tile_kind: Scene.Tile.Kind = .Ice;
	selected_entity_type_index := -1;

	selected_entity_ptr: *void = null;
	selected_entity_type: Type_Info_Struct;

	// Camera control
	camera_drag_start: V2f;
	is_dragging_camera := false;
	camera_offset: V3f = .{ 0, -4, 8 };  // Same as game camera

	// Painting state
	is_painting := false;
	paint_mode: enum { Set; Erase; } = .Set;

	// Terrain size
	terrain_width := 40;
	terrain_height := 30;

	// UI state
	show_save_dialog := false;
	save_filename: [256] u8;
	save_filename_cursor := 0;

	initialized := false;

	grid_snapping := 0.05;
}


screen_to_world :: (editor: *Editor, screen_pos: V2f, window_size: V2f) -> V3f {
	// Create view and projection matrices
	V := Scene.look_at(editor.scene.camera.position, editor.scene.camera.target, V3f.{ 0, 0, 1 });
	P := Scene.perspective(editor.scene.camera);

	// Convert screen coordinates to normalized device coordinates
	ndc: V2f;
	ndc.x = (screen_pos.x / window_size.x) * 2.0 - 1.0;
	ndc.y = (screen_pos.y / window_size.y) * 2.0 - 1.0;

	// Create ray from camera through the screen point
	inv_P := inverse(P);
	inv_V := inverse(V);

	// Near and far points in clip space
	near_clip := V4f.{ ndc.x, ndc.y, -1.0, 1.0 };
	far_clip := V4f.{ ndc.x, ndc.y, 1.0, 1.0 };

	// Transform to view space
	near_view := inv_P * near_clip;
	far_view := inv_P * far_clip;
	near_view /= near_view.w;
	far_view /= far_view.w;

	// Transform to world space
	near_world := inv_V * near_view;
	far_world := inv_V * far_view;

	// Ray direction
	ray_origin := V3f.{ near_world.x, near_world.y, near_world.z };
	ray_dir := normalize(V3f.{
		far_world.x - near_world.x,
		far_world.y - near_world.y,
		far_world.z - near_world.z
	});

	// Intersect with z=0 plane
	if abs(ray_dir.z) > 0.0001 {
		t := -ray_origin.z / ray_dir.z;

		hit := ray_origin + ray_dir * t;
		hit.x = floor(0.5 + hit.x / editor.grid_snapping) * editor.grid_snapping;
		hit.y = floor(0.5 + hit.y / editor.grid_snapping) * editor.grid_snapping;
		hit.z = floor(0.5 + hit.z / editor.grid_snapping) * editor.grid_snapping;
		return hit;
	}

	return V3f.{ 0, 0, 0 };
}
