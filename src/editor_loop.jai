#import "Reflect";
#import "Editor";

enter_editor :: (app_user: *App_User) {
	app_user.state.screen_state = .Editor;
	editor := *app_user.state.editor;

	// Initialize GUI state
	GUI.gui_state_init(*editor.gui_state, *app_user.store);

	// Initialize with empty terrain
	init_empty_terrain(editor, editor.terrain_width, editor.terrain_height);

	// Setup camera to view the terrain (same angle as game)
	center_x := cast(float32)(editor.terrain_width / 2);
	center_y := cast(float32)(editor.terrain_height / 2);
	editor.scene.camera.target = V3f.{ center_x, center_y, 0 };
	editor.scene.camera.position = editor.scene.camera.target + editor.camera_offset;
	editor.scene.camera.fov = 60;
	editor.scene.camera.near = 0.1;
	editor.scene.camera.far = 1000;

	editor.initialized = true;
}

init_empty_terrain :: (editor: *Editor, width: int, height: int) {
	editor.terrain_width = width;
	editor.terrain_height = height;

	// Free old terrain
	Scene.free(*editor.scene.terrain);

	// Create new terrain
	editor.scene.terrain.tiles_count = V2i.{ width, height };
	editor.scene.terrain.tile_size = V2f.{ 1.0, 1.0 };
	editor.scene.terrain.spawn_tile = V2i.{ width / 2, height / 2 };

	array_resize(*editor.scene.terrain.tiles, width * height);

	// Initialize all tiles to Ice by default
	for * editor.scene.terrain.tiles {
		it.kind = .Dirt;
	}
}

resize_terrain :: (editor: *Editor, new_width: int, new_height: int) {
	old_width := editor.terrain_width;
	old_height := editor.terrain_height;

	if new_width == old_width && new_height == old_height return;

	// Save old tiles
	old_tiles: [..] Scene.Tile;
	array_resize(*old_tiles, old_width * old_height);
	for i: 0..old_tiles.count - 1 {
		old_tiles[i] = editor.scene.terrain.tiles[i];
	}
	defer array_free(old_tiles);

	// Resize terrain
	editor.terrain_width = new_width;
	editor.terrain_height = new_height;
	editor.scene.terrain.tiles_count = V2i.{ new_width, new_height };
	array_resize(*editor.scene.terrain.tiles, new_width * new_height);

	// Copy old tiles and fill new areas
	for y: 0..new_height - 1 {
		for x: 0..new_width - 1 {
			new_idx := x + y * new_width;
			if x < old_width && y < old_height {
				old_idx := x + y * old_width;
				editor.scene.terrain.tiles[new_idx] = old_tiles[old_idx];
			} else {
				editor.scene.terrain.tiles[new_idx].kind = .Ice;
			}
		}
	}

	// Clamp spawn tile to new bounds
	if editor.scene.terrain.spawn_tile.x >= new_width {
		editor.scene.terrain.spawn_tile.x = new_width - 1;
	}
	if editor.scene.terrain.spawn_tile.y >= new_height {
		editor.scene.terrain.spawn_tile.y = new_height - 1;
	}
}

editor_loop :: (app_user: *App_User) -> bool {
	editor := *app_user.state.editor;
	gui := *editor.gui_state;
	info := app_user.allocated_frame_info;

	if !editor.initialized {
		enter_editor(app_user);
	}

	// Begin GUI frame
	controls: Controls.State;
	GUI.begin_frame(gui, info, *controls, app_user.state.keyboard_layout);

	// Draw UI panels
	draw_mode_picker(editor, gui);
	draw_editor_toolbar(editor, gui, *app_user.state);

	if editor.show_save_dialog {
		draw_save_dialog(editor, gui);
	}

	if !gui.controls.captured_mouse && !gui.controls.captured_keyboard {
		// Handle keyboard shortcuts
		if gui.controls.just_pressed[Key.Escape] {
			app_user.state.screen_state = .Menu;
			editor.initialized = false;
			return false;
		}

		// F5 key to save
		if gui.controls.just_pressed[Key.F5] {
			editor.show_save_dialog = true;
		}

		// Handle camera controls (right mouse drag to pan)
		handle_editor_camera_controls(editor, gui);

		// Handle input based on mode
		if editor.mode == .Tiles {
			handle_tile_painting(editor, gui);
		} else {
			if !handle_entity_picking(editor, gui)
				handle_entity_placing(editor, gui);
		}
	}

	// Render the editor
	editor_render(app_user);

	return false;
}

handle_editor_camera_controls :: (editor: *Editor, gui: *GUI.GUI_State) {
	// Right mouse drag to pan camera
	if gui.controls.just_pressed[Key.MouseRight] {
		editor.is_dragging_camera = true;
		editor.camera_drag_start = gui.controls.mouse_pos;
	}

	if gui.controls.just_released[Key.MouseRight] {
		editor.is_dragging_camera = false;
	}

	if editor.is_dragging_camera {
		delta := gui.controls.mouse_pos - editor.camera_drag_start;
		editor.camera_drag_start = gui.controls.mouse_pos;

		// Pan the camera (move target, position follows)
		pan_speed := 0.03;
		editor.scene.camera.target.x -= delta.x * pan_speed;
		editor.scene.camera.target.y -= delta.y * pan_speed;
		editor.scene.camera.position = editor.scene.camera.target + editor.camera_offset;
	}

	// Mouse wheel to zoom (scale the camera offset)
	if gui.controls.mouse_wheel != 0 {
		// Scroll up (positive) = zoom in = smaller offset
		// Scroll down (negative) = zoom out = larger offset
		zoom_factor: float32 = 1.0 - cast(float32)gui.controls.mouse_wheel * 0.1;
		zoom_factor = clamp(zoom_factor, 0.8, 1.2);

		editor.camera_offset *= zoom_factor;

		// Clamp zoom limits
		offset_length := norm(editor.camera_offset);
		if offset_length < 3.0 {
			editor.camera_offset *= 3.0 / offset_length;
		} else if offset_length > 50.0 {
			editor.camera_offset *= 50.0 / offset_length;
		}

		editor.scene.camera.position = editor.scene.camera.target + editor.camera_offset;
	}
}

handle_tile_painting :: (editor: *Editor, gui: *GUI.GUI_State) {
	// Don't paint if GUI captured the mouse
	if gui.controls.captured_mouse {
		return;
	}

	// Left mouse to paint
	if gui.controls.pressed[Key.MouseLeft] {
		// Convert screen position to world position
		world_pos := screen_to_world(editor, gui.controls.mouse_pos, gui.controls.window_size);

		// Convert world position to tile coordinates
		tile_x := cast(int) floor(world_pos.x / editor.scene.terrain.tile_size.x);
		tile_y := cast(int) floor(world_pos.y / editor.scene.terrain.tile_size.y);

		// Check bounds
		if tile_x >= 0 && tile_x < editor.scene.terrain.tiles_count.x &&
		   tile_y >= 0 && tile_y < editor.scene.terrain.tiles_count.y {
			tile_idx := tile_x + tile_y * editor.scene.terrain.tiles_count.x;

			if editor.paint_mode == .Set {
				editor.scene.terrain.tiles[tile_idx].kind = editor.selected_tile_kind;
			} else {
				editor.scene.terrain.tiles[tile_idx].kind = .None;
			}
		}
	}
}

handle_entity_placing :: (editor: *Editor, gui: *GUI.GUI_State) {
	if editor.selected_entity_type_index < 0
		return;
	// Don't paint if GUI captured the mouse
	if gui.controls.captured_mouse {
		return;
	}

	// Left mouse to paint
	if gui.controls.just_pressed[Key.MouseLeft] {
		// Convert screen position to world position
		world_pos := screen_to_world(editor, gui.controls.mouse_pos, gui.controls.window_size);

		placing_type := editable_entities_type[editor.selected_entity_type_index].(*Type_Info);

		#insert -> string {
			sb: String_Builder;

			for entity: get_scene_placeable_entities() {
				print_to_builder(
					*sb,
					#string FORMAT
					if type_info(Scene.%) == xx placing_type {
						new_entity: Scene.%;
						new_entity.id = editor.scene.%.count;
						new_entity.position = world_pos;
						array_add(*editor.scene.%, new_entity);
					}
					FORMAT,
					entity.type.name,
					entity.type.name,
					entity.name,
					entity.name
				);
			}

			scene_info := type_info(Scene.Scene);
			for member: scene_info.members {
				if member.type.type != .ARRAY
					continue;

				member_array := member.type.(*Type_Info_Array);
				if member_array.array_type == .RESIZABLE {
					if member_array.element_type.type == .STRUCT {
						element_type := member_array.element_type.(*Type_Info_Struct);
						if !has_field(element_type, "position")
							continue;
						if !has_field(element_type, "id")
							continue;
					}
				}
			}
			return builder_to_string(*sb);
		}
	}
}
handle_entity_picking :: (editor: *Editor, gui: *GUI.GUI_State) -> bool {
	if gui.controls.captured_mouse {
		return false;
	}

	// Left mouse to paint
	if gui.controls.just_pressed[Key.MouseLeft] {
		// Convert screen position to world position
		world_pos := screen_to_world(editor, gui.controls.mouse_pos, gui.controls.window_size);

		entities := get_scene_placeable_entities();
		for entity: entities {
			for 0..get_count(*editor.scene, entity)-1 {
				pos := get_position(*editor.scene, entity, it);

				r := norm(pos - world_pos);
				if r < 0.2 {
					editor.selected_entity_ptr = get_pointer(*editor.scene, entity, it);
					editor.selected_entity_type = entity.type;
					return true;
				}
			}
		}
	}
	return false;
}

draw_mode_picker :: (editor: *Editor, gui: *GUI.GUI_State) {
	// Draw panel background
	panel_width := 150.0;
	panel_height := ifx editor.mode == .Tiles then 320.0 else 200.0;
	panel_x := 10.0;
	panel_y := gui.controls.window_size.y - 64 - panel_height;

	GUI.push_quad_screen(gui, V2f.{ panel_x, panel_y }, V2f.{ panel_width, panel_height }, V3f.{ 0.2, 0.2, 0.2 }, z = 50);
	GUI.push_quad_screen(gui, V2f.{ panel_x + 2, panel_y + 2 }, V2f.{ panel_width - 4, panel_height - 4 }, V3f.{ 0.1, 0.1, 0.1 }, z = 51);

	// Mode tabs at top
	tab_y := panel_y + panel_height - 30;
	tab_width := (panel_width - 20) / 2;

	// Tiles tab
	tiles_selected := editor.mode == .Tiles;
	tiles_color := ifx tiles_selected then V3f.{ 0.3, 0.5, 0.7 } else V3f.{ 0.25, 0.25, 0.25 };
	tiles_pos := V2f.{ panel_x + 5, tab_y };
	GUI.push_quad_screen(gui, tiles_pos, V2f.{ tab_width, 25 }, tiles_color, z = 52);
	GUI.atom_label(gui, "Tiles", tiles_pos + V2f.{ 15, 6 }, scale = 14, z = 53, color = V4f.{ 1, 1, 1, 1 });
	if point_aabb(gui.controls.mouse_pos, tiles_pos, tiles_pos + V2f.{ tab_width, 25 }) {
		if gui.controls.just_pressed[Key.MouseLeft] {
			editor.mode = .Tiles;
			gui.controls.captured_mouse = true;
		}
	}

	// Entities tab
	entities_selected := editor.mode == .Entities;
	entities_color := ifx entities_selected then V3f.{ 0.3, 0.5, 0.7 } else V3f.{ 0.25, 0.25, 0.25 };
	entities_pos := V2f.{ panel_x + 5 + tab_width + 5, tab_y };
	GUI.push_quad_screen(gui, entities_pos, V2f.{ tab_width, 25 }, entities_color, z = 52);
	GUI.atom_label(gui, "Entities", entities_pos + V2f.{ 8, 6 }, scale = 14, z = 53, color = V4f.{ 1, 1, 1, 1 });
	if point_aabb(gui.controls.mouse_pos, entities_pos, entities_pos + V2f.{ tab_width, 25 }) {
		if gui.controls.just_pressed[Key.MouseLeft] {
			editor.mode = .Entities;
			gui.controls.captured_mouse = true;
		}
	}

	// Content based on mode
	if editor.mode == .Tiles {
		draw_tile_picker_content(editor, gui, panel_x, panel_y, panel_width, panel_height);
	} else {
		draw_entity_picker_content(editor, gui, panel_x, panel_y, panel_width, panel_height);
		draw_entity_type_content(
			editor,
			gui,
			pos_size(
				gui.controls.window_size.x - 256 - 64 - 4,
				4,
				256 + 64,
				512
			)
		);
	}

	// Capture mouse on panel
	if point_aabb(gui.controls.mouse_pos, V2f.{ panel_x, panel_y }, V2f.{ panel_x + panel_width, panel_y + panel_height }) {
		gui.controls.captured_mouse = true;
	}

	// Paint mode toggle at bottom
	mode_y := panel_y + 15;
	mode_label := ifx editor.paint_mode == .Set then "Mode: Place" else "Mode: Erase";
	GUI.atom_label(gui, mode_label, V2f.{ panel_x + 10, mode_y }, scale = 12, z = 52, color = V4f.{ 0.8, 0.8, 0.8, 1 });
}

draw_tile_picker_content :: (editor: *Editor, gui: *GUI.GUI_State, panel_x: float, panel_y: float, panel_width: float, panel_height: float) {
	// Tile type buttons
	tile_kinds :: Scene.Tile.Kind.[
		.None, .Ice, .Grass, .Slippy_Ice, .Dirt, .Funny_Ice
	];
	tile_names :: string.[
		"None (X)", "Ice (I)", "Grass (G)", "Slippy (i)", "Dirt", "Funny (R)"
	];
	tile_colors :: V3f.[
		.{ 0.3, 0.2, 0.1 },   // None/Dirt
		.{ 0.7, 0.9, 1.0 },   // Ice
		.{ 0.3, 0.7, 0.3 },   // Grass
		.{ 0.5, 0.8, 1.0 },   // Slippy Ice
		.{ 0.4, 0.3, 0.2 },   // Dirt
		.{ 0.9, 0.7, 1.0 }    // Funny Ice
	];

	button_y := panel_y + panel_height - 65;
	for i: 0..tile_kinds.count - 1 {
		button_pos := V2f.{ panel_x + 10, button_y - i * 35 };
		button_size := V2f.{ panel_width - 20, 30 };

		// Highlight selected
		is_selected := editor.selected_tile_kind == tile_kinds[i];
		bg_color := ifx is_selected then V3f.{ 0.4, 0.6, 0.8 } else V3f.{ 0.3, 0.3, 0.3 };

		GUI.push_quad_screen(gui, button_pos, button_size, bg_color, z = 52);

		// Color preview
		GUI.push_quad_screen(gui, button_pos + V2f.{ 5, 5 }, V2f.{ 20, 20 }, tile_colors[i], z = 53);

		// Label
		GUI.atom_label(gui, tile_names[i], button_pos + V2f.{ 30, 8 }, scale = 14, z = 53, color = V4f.{ 1, 1, 1, 1 });

		// Check for click
		if point_aabb(gui.controls.mouse_pos, button_pos, button_pos + button_size) {
			if gui.controls.just_pressed[Key.MouseLeft] {
				editor.selected_tile_kind = tile_kinds[i];
				gui.controls.captured_mouse = true;
			}
		}
	}
}

draw_entity_picker_content :: (editor: *Editor, gui: *GUI.GUI_State, panel_x: float, panel_y: float, panel_width: float, panel_height: float) {
	// Tile type buttons
	button_y := panel_y + panel_height - 65;
	for i: 0..editable_entities_type.count - 1 {
		T := editable_entities_type[i];
		info := T.(*Type_Info_Struct);
		
		button_pos := V2f.{ panel_x + 10, button_y - i * 35 };
		button_size := V2f.{ panel_width - 20, 30 };

		// Highlight selected
		is_selected := editor.selected_entity_type_index == i;
		bg_color := ifx is_selected then V3f.{ 0.4, 0.6, 0.8 } else V3f.{ 0.3, 0.3, 0.3 };

		GUI.push_quad_screen(gui, button_pos, button_size, bg_color, z = 52);

		// Label
		GUI.atom_label(
			gui, info.name, button_pos + V2f.{ 30, 8 }, scale = 14, z = 53, color = V4f.{ 1, 1, 1, 1 });

		// Check for click
		if point_aabb(gui.controls.mouse_pos, button_pos, button_pos + button_size) {
			if gui.controls.just_pressed[Key.MouseLeft] {
				editor.selected_entity_type_index = i;
				gui.controls.captured_mouse = true;
			}
		}
	}
}

draw_entity_type_content :: (editor: *Editor, gui: *GUI.GUI_State, panel_aabb: AABBf) {
	if editor.selected_entity_ptr == null
		return;

	GUI.push_quad_screen(gui, panel_aabb, V3f.{ 0.15, 0.15, 0.15 }, z = 50);

	cursor := panel_aabb.min + v2(8.0);
	GUI.atom_label(gui, editor.selected_entity_type.name, cursor, scale = 16, z = 51, id = 1);
	cursor.x += GUI.widget_width(gui, 1) + 8;
	GUI.text_button(gui, "Remove", cursor, z = 51, id = "remove_button");
}

draw_editor_toolbar :: (editor: *Editor, gui: *GUI.GUI_State, state: *State) {
	// Top toolbar
	toolbar_height := 40.0;
	toolbar_y := gui.controls.window_size.y - toolbar_height;

	GUI.push_quad_screen(gui, V2f.{ 0, toolbar_y }, V2f.{ gui.controls.window_size.x, toolbar_height }, V3f.{ 0.15, 0.15, 0.15 }, z = 50);

	// Save button
	play_clicked, _, _ := GUI.text_button(gui, "Play", V2f.{ 64, toolbar_y + 10 }, z = 51, id = "play_btn");
	if play_clicked {
	}

	// Save button
	save_clicked, _, _ := GUI.text_button(gui, "Save", V2f.{ 180, toolbar_y + 10 }, z = 51, id = "save_btn");
	if save_clicked {
		editor.show_save_dialog = true;
	}

	// Clear button
	clear_clicked, _, _ := GUI.text_button(gui, "Clear", V2f.{ 250, toolbar_y + 10 }, z = 51, id = "clear_btn");
	if clear_clicked {
		init_empty_terrain(editor, editor.terrain_width, editor.terrain_height);
		Scene.clear_scene(*editor.scene);
	}

	// Back button
	back_clicked, _, _ := GUI.text_button(gui, "Back to Menu", V2f.{ 350, toolbar_y + 10 }, z = 51, id = "back_btn");
	if back_clicked {
		state.screen_state = .Menu;
		editor.initialized = false;
	}

	// Toggle paint/erase mode
	mode_label := ifx editor.paint_mode == .Set then "Erase Mode" else "Paint Mode";
	mode_clicked, _, _ := GUI.text_button(gui, mode_label, V2f.{ 500, toolbar_y + 10 }, z = 51, id = "mode_btn");
	if mode_clicked {
		if editor.paint_mode == .Set {
			editor.paint_mode = .Erase;
		} else {
			editor.paint_mode = .Set;
		}
	}

	// Terrain size controls
	size_x := 620.0;

	// Width controls
	GUI.atom_label(gui, "W:", V2f.{ size_x, toolbar_y + 12 }, scale = 14, z = 51, color = V4f.{ 0.8, 0.8, 0.8, 1 });
	w_minus_clicked, _, _ := GUI.text_button(gui, "-", V2f.{ size_x + 25, toolbar_y + 10 }, z = 51, id = "w_minus");
	if w_minus_clicked && editor.terrain_width > 10 {
		resize_terrain(editor, editor.terrain_width - 5, editor.terrain_height);
	}
	GUI.atom_label(gui, tprint("%", editor.terrain_width), V2f.{ size_x + 50, toolbar_y + 12 }, scale = 14, z = 51, color = V4f.{ 1, 1, 1, 1 });
	w_plus_clicked, _, _ := GUI.text_button(gui, "+", V2f.{ size_x + 80, toolbar_y + 10 }, z = 51, id = "w_plus");
	if w_plus_clicked && editor.terrain_width < 200 {
		resize_terrain(editor, editor.terrain_width + 5, editor.terrain_height);
	}

	// Height controls
	GUI.atom_label(gui, "H:", V2f.{ size_x + 120, toolbar_y + 12 }, scale = 14, z = 51, color = V4f.{ 0.8, 0.8, 0.8, 1 });
	h_minus_clicked, _, _ := GUI.text_button(gui, "-", V2f.{ size_x + 145, toolbar_y + 10 }, z = 51, id = "h_minus");
	if h_minus_clicked && editor.terrain_height > 10 {
		resize_terrain(editor, editor.terrain_width, editor.terrain_height - 5);
	}
	GUI.atom_label(gui, tprint("%", editor.terrain_height), V2f.{ size_x + 170, toolbar_y + 12 }, scale = 14, z = 51, color = V4f.{ 1, 1, 1, 1 });
	h_plus_clicked, _, _ := GUI.text_button(gui, "+", V2f.{ size_x + 200, toolbar_y + 10 }, z = 51, id = "h_plus");
	if h_plus_clicked && editor.terrain_height < 200 {
		resize_terrain(editor, editor.terrain_width, editor.terrain_height + 5);
	}

	// Current terrain info
	snap_clicked, _, _ := GUI.text_button(
		gui,
		tprint("Snap %", editor.grid_snapping),
		V2f.{ gui.controls.window_size.x - 150, toolbar_y + 12 },
		z = 51,
		id = "snap_btn"
	);
	if snap_clicked {
		if editor.grid_snapping == 0.05 {
			editor.grid_snapping = 0.25;
		} else if editor.grid_snapping == 0.25 {
			editor.grid_snapping = 0.5;
		} else if editor.grid_snapping == 0.5 {
			editor.grid_snapping = 0.05;
		}
	}

	// Capture mouse on toolbar
	if point_aabb(gui.controls.mouse_pos, V2f.{ 0, toolbar_y }, V2f.{ gui.controls.window_size.x, toolbar_y + toolbar_height }) {
		gui.controls.captured_mouse = true;
	}
}

draw_save_dialog :: (editor: *Editor, gui: *GUI.GUI_State) {
	// Dialog background
	dialog_width := 400.0;
	dialog_height := 150.0;
	dialog_x := (gui.controls.window_size.x - dialog_width) / 2;
	dialog_y := (gui.controls.window_size.y - dialog_height) / 2;

	// Darken background
	GUI.push_quad_screen(gui, V2f.{ 0, 0 }, gui.controls.window_size, V3f.{ 0, 0, 0 }, z = 98, a = 0.5);

	// Dialog box
	GUI.push_quad_screen(gui, V2f.{ dialog_x, dialog_y }, V2f.{ dialog_width, dialog_height }, V3f.{ 0.2, 0.2, 0.2 }, z = 99);
	GUI.push_quad_screen(gui, V2f.{ dialog_x + 2, dialog_y + 2 }, V2f.{ dialog_width - 4, dialog_height - 4 }, V3f.{ 0.1, 0.1, 0.1 }, z = 100);

	// Title
	GUI.atom_label(gui, "Save Terrain", V2f.{ dialog_x + 20, dialog_y + dialog_height - 30 }, scale = 18, z = 101, color = V4f.{ 1, 1, 1, 1 });

	// Filename input area
	input_x := dialog_x + 20;
	input_y := dialog_y + dialog_height - 80;
	input_width := dialog_width - 40;
	input_height := 30.0;

	GUI.push_quad_screen(gui, V2f.{ input_x, input_y }, V2f.{ input_width, input_height }, V3f.{ 0.3, 0.3, 0.3 }, z = 101);

	// Show current filename
	filename_str: string;
	filename_str.data = editor.save_filename.data;
	filename_str.count = editor.save_filename_cursor;
	if filename_str.count == 0 {
		filename_str = "my_level";
	}
	GUI.atom_input_text(
		gui,
		pos_size(V2f.{ input_x, input_y }, V2f.{ input_width, input_height }),
		14,
		filename_str,
		z = 102
	);

	// Hint
	GUI.atom_label(gui, "(saves to assets/Terrain/<name>.terrain)", V2f.{ dialog_x + 20, input_y - 20 }, scale = 12, z = 101, color = V4f.{ 0.6, 0.6, 0.6, 1 });

	// Save button
	save_clicked, _, _ := GUI.text_button(gui, "Save", V2f.{ dialog_x + dialog_width - 140, dialog_y + 20 }, z = 101, id = "dialog_save");
	if save_clicked {
		save_terrain_to_file(editor, filename_str);
		editor.show_save_dialog = false;
	}

	// Cancel button
	cancel_clicked, _, _ := GUI.text_button(gui, "Cancel", V2f.{ dialog_x + dialog_width - 70, dialog_y + 20 }, z = 101, id = "dialog_cancel");
	if cancel_clicked || gui.controls.just_pressed[Key.Escape] {
		editor.show_save_dialog = false;
	}

	// Capture mouse clicks on dialog
	gui.controls.captured_mouse = true;
}

save_terrain_to_file :: (editor: *Editor, filename: string) {
	content := Scene.serialize(editor.scene,, temp);

	// Build full path
	full_path := tprint("assets/Terrain/%.terrain", filename);

	// Print the content to console for now
	// (File writing requires #import "File" in main_game.jai)
	print("=== TERRAIN FILE: % ===\n", full_path);
	print("%\n", content);
	print("=== END TERRAIN FILE ===\n");
	print("Copy the content above and save it to: %\n", full_path);
}

editor_render :: (app_user: *App_User) {
	editor := *app_user.state.editor;
	framegraph := *app_user.framegraph;
	store := *app_user.store;

	frame := WRender.begin_frame(framegraph, app_user.state.current_time);

	// Render the scene (terrain)
	WRender.render_scene(frame, framegraph, editor.scene, store);
	WRender.render_editor(frame, framegraph, editor, store);

	// Render the GUI
	WRender.render_gui(frame, framegraph, editor.gui_state, store);

	WRender.end_frame(framegraph, frame);
}
