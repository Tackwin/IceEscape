#import "Reflect";
#import "Editor";
#import "Pool";
#import "Terrain";

Editor_Mode :: enum {
	Tiles;
	Entities;
	Scene;
}

Editor_Page :: struct {
	show_load_dialog := false;
	load_filter: string;
	load_result_page := 0;

	Terrain_Entry :: struct {
		name: string;
		author: string;
		created_ms: s64;
		id: int;
	}
	terrain_list: [..] Terrain_Entry;
	terrain_list_pool: Pool;

	show_save_dialog := false;
	save_dialog_input: string;

	mode: Editor_Mode = .Tiles;

	rectangle_dragging_start: V2f;
	rectangle_dragging := false;
	was_rectangle_dragging := false;

	Selection :: struct {
		ptr: *void;
		type: Type_Info_Struct;
	}
	selected: [..] Selection;
	placing_entity_type: *Type_Info_Struct = null;

	multiple_posititon_offset: V3f;
}

process_editor :: (app_user: *App_User, command: Command) -> bool {
	editor := *app_user.state.editor;
	page := *app_user.state.editor_page;

	ans_enter_custom_instance := isa(command.payload, Command.Ans_Enter_Custom_Instance);
	if ans_enter_custom_instance {
		return false;
	}

	sync_scene := isa(command.payload, Command.Sync_Scene);
	if sync_scene {
		app_user.state.screen_state = .Game;
		return false;
	}

	load_terrain := isa(command.payload, Command.Load_Terrain);
	if load_terrain {
		if load_terrain.terrain_id < 0 {
			print("Failed to load terrain: invalid ID %\n", load_terrain.terrain_id);
		} else {
			reset_entity_selection(editor, page);
			Scene.clear_scene_run(*editor.scene);
			parse_terrain(load_terrain.ascii, *editor.scene, generate_props = false);

			new_save_dialog_input: string;
			new_save_dialog_input.data = load_terrain.info.name.data;
			new_save_dialog_input.count = 0;
			for i: 0..load_terrain.info.name.count - 1 {
				if load_terrain.info.name.data[i] == 0 {
					break;
				}
				new_save_dialog_input.count += 1;
			}

			free(page.save_dialog_input);
			page.save_dialog_input = sprint("%", new_save_dialog_input);
		}
		return true;
	}
	ans_list_terrain := isa(command.payload, Command.Ans_List_Terrain);

	if ans_list_terrain {
		for page.terrain_list
			free(it.name.data,, page.terrain_list.allocator);
		page.terrain_list.allocator = .{ pool_allocator_proc, *page.terrain_list_pool };
		array_resize(*page.terrain_list, ans_list_terrain.terrains_id.count);
		for * page.terrain_list {
			it.id = ans_list_terrain.terrains_id[it_index];
			it.name = sprint(
				ans_list_terrain.terrains_name[it_index],, page.terrain_list.allocator
			);
			it.author = sprint(
				ans_list_terrain.authors_name[it_index],, page.terrain_list.allocator
			);
			it.created_ms = ans_list_terrain.creation_time_ms[it_index];
		}
		return true;
	}

	return false;
}

enter_editor :: (app_user: *App_User) {
	app_user.state.screen_state = .Editor;
	editor := *app_user.state.editor;

	set_allocators(*app_user.state.editor_page.terrain_list_pool);
	if !editor.initialized {
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
}

init_empty_terrain :: (editor: *Editor, width: int, height: int) {
	editor.terrain_width = width;
	editor.terrain_height = height;

	// Free old terrain
	Scene.free(*editor.scene.terrain);

	// Create new terrain
	editor.scene.terrain.tiles_count = V2i.{ width, height };
	editor.scene.terrain.tile_size = V2f.{ 1.0, 1.0 };
	editor.scene.spawn.position = v3(width / 2.0, height / 2.0, 0.0);
	editor.scene.camera_min = V2f.{ 0.0, 0.0 };
	editor.scene.camera_max = V2f.{ cast(float32)(width), cast(float32)(height) };

	array_resize(*editor.scene.terrain.tiles, width * height);

	// Initialize all tiles to Ice by default
	for * editor.scene.terrain.tiles {
		it.kind = .Dirt;
	}
}

reset_entity_selection :: (editor: *Editor, page: *Editor_Page) {
	page.placing_entity_type = null;
	page.selected.count = 0;
}

resize_terrain :: (editor: *Editor, new_width: int, new_height: int) {
	old_width := editor.terrain_width;
	old_height := editor.terrain_height;

	if new_width == old_width && new_height == old_height return;

	// Save old tiles
	old_tiles: [..] Scene.Tile;
	array_resize(*old_tiles, old_width * old_height);
	for i: 0..min(old_tiles.count, editor.scene.terrain.tiles.count) - 1 {
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
				editor.scene.terrain.tiles[new_idx].kind = .Dirt;
			}
		}
	}
}

editor_loop :: (app_user: *App_User) -> bool {
	editor := *app_user.state.editor;
	editor_page := *app_user.state.editor_page;
	gui := *editor.gui_state;
	info := app_user.allocated_frame_info;

	if !editor.initialized {
		enter_editor(app_user);
	}

	update(editor);

	// Begin GUI frame
	controls: Controls.State;
	GUI.begin_frame(gui, info, *controls, app_user.state.keyboard_layout);

	if editor_page.rectangle_dragging {
		// Draw selection rectangle
		GUI.push_quad_screen(
			gui,
			vmin(editor_page.rectangle_dragging_start, gui.controls.mouse_pos),
			abs(gui.controls.mouse_pos - editor_page.rectangle_dragging_start),
			V3f.{ 1.0, 191/255.0, 0.0 },
			z = 3,
			a = 0.3
		);
	}

	// Draw UI panels
	draw_mode_picker(editor, editor_page, gui);
	draw_editor_toolbar(editor, editor_page, gui, *app_user.state);

	if editor_page.show_save_dialog {
		draw_save_dialog(editor, editor_page, gui, app_user.app.platform);
	}

	if editor_page.show_load_dialog {
		draw_load_dialog(editor, editor_page, gui, app_user.app.platform);
	}

	if !gui.controls.captured_mouse && !gui.controls.captured_keyboard {
		editor_page.was_rectangle_dragging = editor_page.rectangle_dragging;
		// Handle keyboard shortcuts
		if gui.controls.just_pressed[Key.Escape] {
			app_user.state.screen_state = .Menu;
			return false;
		}

		// F5 key to save
		if gui.controls.just_pressed[Key.F5] {
			editor_page.show_save_dialog = true;
		}

		// Handle camera controls (right mouse drag to pan)
		handle_editor_camera_controls(editor, gui);

		// Handle input based on mode
		if editor_page.mode == .Tiles {
			handle_tile_painting(editor, gui);
		} else {
			if !handle_entity_picking(editor, editor_page, gui)
				handle_entity_placing(editor, editor_page, gui);
		}
	}
	if gui.controls.just_released[Key.MouseLeft] {
		editor_page.rectangle_dragging = false;
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

		tile := Scene.position_to_tile(editor.scene, world_pos);

		// Convert world position to tile coordinates
		tile_x := tile.x;
		tile_y := tile.y;

		// Check bounds
		if tile_x >= 0 && tile_x < editor.scene.terrain.tiles_count.x &&
		   tile_y >= 0 && tile_y < editor.scene.terrain.tiles_count.y {
			tile_idx := tile_x + tile_y * editor.scene.terrain.tiles_count.x;

			editor.scene.terrain.tiles[tile_idx].kind = editor.selected_tile_kind;
		}
	}
}

handle_entity_placing :: (editor: *Editor, page: *Editor_Page, gui: *GUI.GUI_State) {
	if !page.placing_entity_type
		return;
	// Don't paint if GUI captured the mouse
	if gui.controls.captured_mouse {
		print("Mouse captured by GUI, not placing entity\n");
		return;
	}

	// Left mouse to paint
	if gui.controls.just_released[Key.MouseLeft] && !page.was_rectangle_dragging {
		// Convert screen position to world position
		world_pos := screen_to_world(editor, gui.controls.mouse_pos, gui.controls.window_size);

		placing_type := page.placing_entity_type;

		if placing_type == type_info(Scene.Spawn) {
			editor.scene.spawn.position = world_pos;
		}

		if placing_type == type_info(Scene.Path) {
			a_path_is_already_selected := false;
			if page.selected.count == 1 {
				if page.selected[0].type.name == type_info(Scene.Path).name {
					a_path_is_already_selected = true;
				}
			}
			if a_path_is_already_selected {
				path := page.selected[0].ptr.(*Scene.Path);
				checkpoint: Scene.Checkpoint;
				checkpoint.position = world_pos;
				
				Scene.add_checkpoint_to_path(*editor.scene, path, checkpoint);
			} else {
				checkpoint: Scene.Checkpoint;
				checkpoint.position = world_pos;
				
				path: Scene.Path;
				path.id = editor.scene.paths.count;
				array_add(*editor.scene.paths, path);

				Scene.add_checkpoint_to_path(
					*editor.scene, *editor.scene.paths[editor.scene.paths.count - 1], checkpoint
				);
			}
		}

		if placing_type == type_info(Scene.Skull) {
			path := find_closest_path(editor, world_pos);
			if path != null {
				skull: Scene.Skull;
				skull.id = editor.scene.skulls.count;
				skull.path_id = path.id;
				array_add(*editor.scene.skulls, skull);
			}
		}

		#insert -> string {
			sb: String_Builder;

			for entity: get_scene_placeable_entities() {
				client_position_sync := "";
				if has_field_path(entity.type, "client.position") {
					client_position_sync =
						"new_entity.client.position = new_entity.server.position;";
				}

				print_to_builder(
					*sb,
					#string FORMAT
					if type_info(Scene.%1) == xx placing_type {
						new_entity: Scene.%2;
						new_entity.id = editor.scene.%3.count;
						new_entity.%4 = world_pos;
						%5
						array_add(*editor.scene.%6, new_entity);
					}
					FORMAT,
					entity.type.name,
					entity.type.name,
					entity.name,
					entity.position_path,
					client_position_sync,
					entity.name
				);
			}
			return builder_to_string(*sb);
		}
	}
}
handle_entity_picking :: (editor: *Editor, page: *Editor_Page, gui: *GUI.GUI_State) -> bool {
	if gui.controls.captured_mouse {
		return false;
	}
	if gui.controls.just_pressed[Key.MouseLeft] {
		page.rectangle_dragging = false;
		page.rectangle_dragging_start = gui.controls.mouse_pos;
	}

	current_pos := gui.controls.mouse_pos;
	if gui.controls.pressed[Key.MouseLeft] && norm(current_pos - page.rectangle_dragging_start) > 5.0 {
		page.rectangle_dragging = true;
	}

	if gui.controls.just_released[Key.MouseLeft] {
		page.selected.count = 0;
		page.multiple_posititon_offset = V3f.{ 0, 0, 0 };
		page.rectangle_dragging = false;

		// Convert screen position to world position
		a3 := screen_to_world(editor, page.rectangle_dragging_start, gui.controls.window_size);
		a3 -= V3f.{ 0.1, 0.1, 0 };
		b3 := screen_to_world(editor, gui.controls.mouse_pos, gui.controls.window_size);
		b3 += V3f.{ 0.1, 0.1, 0 };

		aabb := AABBf.{ v2(vmin(a3, b3)), v2(vmax(a3, b3)) };

		entities := get_scene_placeable_entities();
		for entity: entities {
			for 0..get_count(*editor.scene, entity)-1 {
				pos := get_position(*editor.scene, entity, it);

				if in(aabb, v2(pos)) {
					array_add(
						*page.selected, .{ get_pointer(*editor.scene, entity, it), entity.type }
					);
				}
			}
		}

		// Handle paths
		for * path: editor.scene.paths {
			idx := path.checkpoint_head;
			while idx >= 0 {
				a := editor.scene.checkpoints[idx];
				pos := a.position;
				if in(aabb, v2(pos)) {
					array_add(*page.selected, .{ path, type_info(Scene.Path) });
					break;
				}
				idx = a.next;
			}
		}

		for * skull: editor.scene.skulls {
			pos := Scene.compute_skull_pos(editor.scene, skull);
			if in(aabb, v2(pos)) {
				array_add(*page.selected, .{ skull, type_info(Scene.Skull) });
			}
		}

		if page.selected.count > 0 {
			gui.controls.captured_mouse = true;
			return true;
		}
	}
	return false;
}

draw_mode_picker :: (editor: *Editor, page: *Editor_Page, gui: *GUI.GUI_State) {
	// Draw panel background
	panel_width := ifx page.mode == .Scene then 300.0 else 180.0;
	panel_height := ifx page.mode == .Tiles then 320.0 else 500.0;
	panel_x := 10.0;
	panel_y := gui.controls.window_size.y - 64 - panel_height;

	GUI.push_quad_screen(gui, V2f.{ panel_x, panel_y }, V2f.{ panel_width, panel_height }, V3f.{ 0.2, 0.2, 0.2 }, z = 50);
	GUI.push_quad_screen(gui, V2f.{ panel_x + 2, panel_y + 2 }, V2f.{ panel_width - 4, panel_height - 4 }, V3f.{ 0.1, 0.1, 0.1 }, z = 51);

	// Mode tabs at top
	tab_y := panel_y + panel_height - 30;
	tab_width := (panel_width - 20) / 3;

	// Tiles tab
	tiles_selected := page.mode == .Tiles;
	tiles_color := ifx tiles_selected then V3f.{ 0.3, 0.5, 0.7 } else V3f.{ 0.25, 0.25, 0.25 };
	tiles_pos := V2f.{ panel_x + 5, tab_y };
	GUI.push_quad_screen(gui, tiles_pos, V2f.{ tab_width, 25 }, tiles_color, z = 52);
	GUI.atom_label(gui, "Tiles", tiles_pos + V2f.{ 7, 6 }, scale = 14, z = 53, color = V4f.{ 1, 1, 1, 1 });
	if point_aabb(gui.controls.mouse_pos, tiles_pos, tiles_pos + V2f.{ tab_width, 25 }) {
		if gui.controls.just_pressed[Key.MouseLeft] {
			page.mode = .Tiles;
			gui.controls.captured_mouse = true;
		}
	}

	// Entities tab
	entities_selected := page.mode == .Entities;
	entities_color := ifx entities_selected then V3f.{ 0.3, 0.5, 0.7 } else V3f.{ 0.25, 0.25, 0.25 };
	entities_pos := V2f.{ panel_x + 5 + tab_width + 5, tab_y };
	GUI.push_quad_screen(gui, entities_pos, V2f.{ tab_width, 25 }, entities_color, z = 52);
	GUI.atom_label(gui, "Entities", entities_pos + V2f.{ 2, 6 }, scale = 14, z = 53, color = V4f.{ 1, 1, 1, 1 });
	if point_aabb(gui.controls.mouse_pos, entities_pos, entities_pos + V2f.{ tab_width, 25 }) {
		if gui.controls.just_pressed[Key.MouseLeft] {
			page.mode = .Entities;
			gui.controls.captured_mouse = true;
		}
	}

	// Scene tab
	scene_selected := page.mode == .Scene;
	scene_color := ifx scene_selected then V3f.{ 0.3, 0.5, 0.7 } else V3f.{ 0.25, 0.25, 0.25 };
	scene_pos := V2f.{ panel_x + 5 + (tab_width + 5) * 2, tab_y };
	GUI.push_quad_screen(gui, scene_pos, V2f.{ tab_width, 25 }, scene_color, z = 52);
	GUI.atom_label(gui, "Scene", scene_pos + V2f.{ 2, 6 }, scale = 14, z = 53, color = V4f.{ 1, 1, 1, 1 });
	if point_aabb(gui.controls.mouse_pos, scene_pos, scene_pos + V2f.{ tab_width, 25 }) {
		if gui.controls.just_pressed[Key.MouseLeft] {
			page.mode = .Scene;
			gui.controls.captured_mouse = true;
		}
	}

	// Content based on mode
	if page.mode == .Tiles {
		draw_tile_picker_content(editor, gui, panel_x, panel_y, panel_width, panel_height);
	} else if page.mode == .Entities {
		draw_entity_picker_content(editor, page, gui, panel_x, panel_y, panel_width, panel_height);
		draw_entity_type_content(
			editor,
			page,
			gui,
			pos_size(
				gui.controls.window_size.x - 256 - 64 - 4,
				4,
				256 + 64,
				512
			)
		);
	} else if page.mode == .Scene {
		draw_scene_edit_content(
			editor, page, gui, pos_size(panel_x, panel_y, panel_width, panel_height)
		);
	}

	// Capture mouse on panel
	if point_aabb(gui.controls.mouse_pos, V2f.{ panel_x, panel_y }, V2f.{ panel_x + panel_width, panel_y + panel_height }) {
		gui.controls.captured_mouse = true;
	}
}

draw_tile_picker_content :: (editor: *Editor, gui: *GUI.GUI_State, panel_x: float, panel_y: float, panel_width: float, panel_height: float) {
	// Tile type buttons
	tile_kinds :: Scene.Tile.Kind.[
		.Ice, .Grass, .Slippy_Ice, .Dirt, .Funny_Ice
	];
	tile_names :: string.[
		"Ice", "Grass", "Slippy", "Snow", "Funny"
	];
	tile_colors :: V3f.[
		.{ 0.5, 0.7, 1.0 },   // Ice
		.{ 0.3, 0.7, 0.3 },   // Grass
		.{ 0.2, 0.5, 0.7 },   // Slippy Ice
		.{ 0.9, 0.9, 0.9 },   // Dirt
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

draw_scene_edit_content :: (
	editor: *Editor, page: *Editor_Page, gui: *GUI.GUI_State, content_aabb: AABBf
) {
	GUI.default_params(gui).direction = .Down;
	GUI.default_params(gui).cursor.x = content_aabb.min.x + 8.0;
	GUI.default_params(gui).cursor.y = content_aabb.max.y - 24.0;
	GUI.default_params(gui).align = .Top_Left;
	GUI.default_params(gui).z = 52;


	v2_result := GUI.labeled_v2_input(
		gui,
		"Camera",
		width(content_aabb) - 16.0,
		24,
		value = editor.scene.camera_min,
		drag_speed = editor.grid_snapping,
		precision = 2,
		id = "camera_min",
		label_color = GUI.GRAY_80
	);
	if v2_result.changed {
		editor.scene.camera_min = v2_result.value;
		editor.scene.camera_max.x = max(editor.scene.camera_max.x, editor.scene.camera_min.x + 1.0);
		editor.scene.camera_max.y = max(editor.scene.camera_max.y, editor.scene.camera_min.y + 1.0);
	}

	v2_result = GUI.labeled_v2_input(
		gui,
		"Camera Max",
		width(content_aabb) - 16.0,
		24,
		value = editor.scene.camera_max,
		drag_speed = editor.grid_snapping,
		precision = 2,
		id = "camera_max",
		label_color = GUI.GRAY_80
	);
	if v2_result.changed {
		editor.scene.camera_max = v2_result.value;
		editor.scene.camera_min.x = min(editor.scene.camera_min.x, editor.scene.camera_max.x - 1.0);
		editor.scene.camera_min.y = min(editor.scene.camera_min.y, editor.scene.camera_max.y - 1.0);
	}

	v2_result = GUI.labeled_v2_input(
		gui,
		"Origin",
		width(content_aabb) - 16.0,
		24,
		value = v2(editor.scene.origin_tile_space),
		drag_speed = editor.grid_snapping,
		precision = 2,
		id = "origin",
		label_color = GUI.GRAY_80
	);
	if v2_result.changed {
		editor.scene.origin_tile_space = v2_result.value;
	}

	v2_result = GUI.labeled_v2_input(
		gui,
		"Spawn point",
		width(content_aabb) - 16.0,
		24,
		value = v2(editor.scene.spawn.position),
		drag_speed = 0.1,
		precision = 2,
		id = "spawn_point",
		label_color = GUI.GRAY_80
	);
	if v2_result.changed {
		editor.scene.spawn.position = v3(v2_result.value, editor.scene.spawn.position.z);
	}

	checked := GUI._labeled_checkbox(
		gui,
		"Night",
		width(content_aabb) - 16.0,
		24,
		id = "night_checkbox",
		label_color = GUI.GRAY_80
	);
	if checked.just_checked {
		editor.scene.night = checked.checked;
	}

	GUI.move_cursor(gui, 8);

	{
		GUI.push_default_params(gui, GUI.default_params(gui));
		defer GUI.pop_default_params(gui);

		GUI.default_params(gui).direction = .Right;
		GUI.default_params(gui).align = .Center_Left;

		GUI._atom_label(gui, "Grow", id = "resize_label");
		clicked := GUI._text_button(gui, "left", id = "grow_left");
		if clicked {
			resize_terrain(editor, editor.terrain_width + 1, editor.terrain_height);
			for y: 0..editor.terrain_height - 1 {
				for < x: editor.terrain_width - 1..1 {
					editor.scene.terrain.tiles[x + y * editor.terrain_width] =
						editor.scene.terrain.tiles[(x - 1) + y * editor.terrain_width];
				}
			}
			editor.scene.origin_tile_space.x += 1.0;
		}
		clicked = GUI._text_button(gui, "right", id = "grow_right");
		if clicked {
			resize_terrain(editor, editor.terrain_width + 1, editor.terrain_height);
		}
		clicked = GUI._text_button(gui, "up", id = "grow_up");
		if clicked {
			resize_terrain(editor, editor.terrain_width, editor.terrain_height + 1);
			for x: 0..editor.terrain_width - 1 {
				for < y: editor.terrain_height - 1..1 {
					editor.scene.terrain.tiles[x + y * editor.terrain_width] =
						editor.scene.terrain.tiles[x + (y - 1) * editor.terrain_width];
				}
			}
		}
		clicked = GUI._text_button(gui, "down", id = "grow_down");
		if clicked {
			resize_terrain(editor, editor.terrain_width, editor.terrain_height + 1);
			editor.scene.origin_tile_space.y += 1.0;
		}

	}

}

draw_entity_picker_content :: (editor: *Editor, page: *Editor_Page, gui: *GUI.GUI_State, panel_x: float, panel_y: float, panel_width: float, panel_height: float) {
	// Tile type buttons
	button_y := panel_y + panel_height - 65;
	for i: 0..editable_entities_type.count - 1 {
		T := editable_entities_type[i];
		info := T.(*Type_Info_Struct);
		
		button_pos := V2f.{ panel_x + 10, button_y - i * 25 };
		button_size := V2f.{ panel_width - 20, 20 };

		// Highlight selected
		is_selected := page.placing_entity_type == info;
		bg_color := ifx is_selected then V3f.{ 0.4, 0.6, 0.8 } else V3f.{ 0.3, 0.3, 0.3 };

		GUI.push_quad_screen(gui, button_pos, button_size, bg_color, z = 52);

		// Label
		GUI.atom_label(
			gui, info.name, button_pos + V2f.{ 30, 4 }, scale = 14, z = 53, color = V4f.{ 1, 1, 1, 1 }
		);

		// Check for click
		if point_aabb(gui.controls.mouse_pos, button_pos, button_pos + button_size) {
			if gui.controls.just_pressed[Key.MouseLeft] {
				page.placing_entity_type = info;
				gui.controls.captured_mouse = true;
			}
		}
	}
}

get_intersection_name :: (page: *Editor_Page) -> string {
	if page.selected.count == 0
		return "None";
	else if page.selected.count == 1
		return page.selected[0].type.name;
	else
		return "Multiple";
}

entity_is_selected :: (page: *Editor_Page, ptr: *void) -> bool {
	for selection: page.selected {
		if selection.ptr == ptr {
			return true;
		}
	}
	return false;
}
remove_from_selection :: (page: *Editor_Page, ptr: *void) {
	for i: 0..page.selected.count - 1 {
		if page.selected[i].ptr == ptr {
			page.selected[i] = page.selected[page.selected.count - 1];
			page.selected.count -= 1;
			return;
		}
	}
}
#import "Basic";
draw_entity_type_content :: (editor: *Editor, page: *Editor_Page, gui: *GUI.GUI_State, panel_aabb: AABBf) {
	if page.selected.count == 0
		return;

	GUI.push_quad_screen(gui, panel_aabb, V3f.{ 0.15, 0.15, 0.15 }, z = 50);

	panel_width := panel_aabb.max.x - panel_aabb.min.x;
	cursor := panel_aabb.min + v2(8.0, panel_aabb.max.y - panel_aabb.min.y - 24);

	// Entity type name
	GUI.atom_label(gui, get_intersection_name(page), cursor, scale = 16, z = 51, id = 1);
	cursor.x += GUI.widget_width(gui, 1) + 8;

	// Remove button
	remove_clicked, _, _ := GUI.text_button(gui, "Remove", cursor, z = 51, id = "remove_button");
	if remove_clicked {
		// Find and remove the entity from its array
		entities := get_scene_placeable_entities();
		for entity: entities {
			count := get_count(*editor.scene, entity);
			for < i: 0..count-1 {
				ptr := get_pointer(*editor.scene, entity, i);
				if entity_is_selected(page, ptr) {
					remove_entity_at(*editor.scene, entity, i);
					remove_from_selection(page, ptr);
				}
			}
		}
		return;
	}

	// Position editing
	cursor.x = panel_aabb.min.x + 8;
	cursor.y -= 32;

	GUI.default_params(gui).direction = .Down;
	GUI.default_params(gui).cursor = cursor;
	GUI.default_params(gui).align = .Center_Left;
	GUI.default_params(gui).z = 52;

	field_collecteds: Table(string, [..] Edit_Field);
	field_collecteds.allocator = temp;

	field_count: Table(string, int);
	field_count.allocator = temp;

	for selected: page.selected {
		selected_entity_ptr := selected.ptr;
		selected_entity_type := selected.type;
		edit_fields := get_edit_fields(*selected_entity_type);
		for field: edit_fields {
			if table_find_pointer(*field_count, field.display_name) == null {
				table_set(*field_count, field.display_name, 1);
			} else {
				table_find_pointer(*field_count, field.display_name).* += 1;
			}

			collected := table_find_pointer(*field_collecteds, field.display_name);
			if !collected {
				arr: [..] Edit_Field;
				arr.allocator = temp;
				array_add(*arr, field);
				table_add(*field_collecteds, field.display_name, arr);
			} else {
				array_add(collected, field);
			}
		}
	}

	// for count, path: field_count {
	// 	print("Field % appears in % entities\n", path, count);
	// }
	// print("\n");
	// sleep_milliseconds(1000);

	content_width := panel_width - GUI.default_params(gui).cursor.x + panel_aabb.min.x;
	if page.selected.count == 1 {
		selected_entity_ptr := page.selected[0].ptr;
		selected_entity_type := page.selected[0].type;

		// Generic
		edit_fields := get_edit_fields(*selected_entity_type);
		for field: edit_fields {
			if field.type.type == .FLOAT {
				current_value := member_pointer(
					selected_entity_type, selected_entity_ptr, field.path, float
				);

				float_result := GUI.labeled_float_input(
					gui,
					tprint("%:", field.path),
					content_width,
					24,
					value = current_value.*,
					drag_speed = 0.1,
					precision = 2,
					id = tprint("entity_field_%", field.path),
				);
				if float_result.changed {
					current_value.* = float_result.value;
				}
			}
			if field.type.type == .INTEGER {
				current_value := member_pointer(
					selected_entity_type, selected_entity_ptr, field.path, int
				);

				int_result := GUI.labeled_int_input(
					gui,
					tprint("%:", field.path),
					content_width,
					24,
					value = current_value.*,
					min_value = 0,
					id = tprint("entity_field_%", field.path),
				);
				if int_result.changed {
					current_value.* = int_result.value;
				}
			}
			if field.type.type == .ENUM {
				enum_info := field.type.(*Type_Info_Enum);
				
				dropdown := GUI._labeled_dropdown(
					gui,
					tprint("%:", field.path),
					enum_info.names,
					content_width,
					24,
					id = tprint("entity_field_%", field.path),
					label_color = GUI.GRAY_80
				);
				if dropdown.changed {
					current_value := member_pointer(
						selected_entity_type, selected_entity_ptr, field.path, int
					);
					current_value.* = enum_info.values[dropdown.selected_index];
				}
			}
			if field.type.type == .STRUCT {
				struct_info := field.type.(*Type_Info_Struct);
				if struct_info.name == "V3" {
					current_value := member_pointer(
						selected_entity_type, selected_entity_ptr, field.path, V3f
					);

					v3_result := GUI.labeled_v3_input(
						gui,
						tprint("%:", field.path),
						content_width,
						24,
						value = current_value.*,
						drag_speed = 0.1,
						precision = 2,
						id = tprint("entity_field_%", field.path),
					);
					if v3_result.changed {
						current_value.* = v3_result.value;
						if has_note(field.member, "normalize") {
							current_value.* = normalize(current_value.*);
						}
					}
				}
				if struct_info.name == "AABB" {
					pos := member_pointer(
						selected_entity_type, selected_entity_ptr, tprint("%.min", field.path), V3f
					);
					size := member_pointer(
						selected_entity_type, selected_entity_ptr, tprint("%.max", field.path), V3f
					);

					pos_result := GUI.labeled_v2_input(
						gui,
						tprint("%: Position", field.path),
						content_width,
						24,
						value = v2(pos.*),
						drag_speed = editor.grid_snapping,
						precision = 2,
						id = tprint("entity_field_%_pos", field.path),
						label_color = GUI.GRAY_80
					);
					if pos_result.changed {
						sized := size.* - pos.*;
						pos.* = v3(pos_result.value, pos.*.z);
						size.* = pos.* + sized;
					}

					size_result := GUI.labeled_v2_input(
						gui,
						tprint("%: Size", field.path),
						content_width,
						24,
						value = v2(size.*) - v2(pos.*),
						drag_speed = editor.grid_snapping,
						precision = 2,
						id = tprint("entity_field_%_size", field.path),
						label_color = GUI.GRAY_80
					);
					if size_result.changed {
						size.* = v3(
							pos.*.x + size_result.value.x, pos.*.y + size_result.value.y, size.*.z
						);
					}
				}
			}
			if field.type.type == .BOOL {
				current_value := member_pointer(
					selected_entity_type, selected_entity_ptr, field.path, bool
				);

				checkbox := GUI._labeled_checkbox(
					gui,
					tprint("%:", field.path),
					content_width,
					24,
					id = tprint("entity_field_%", field.path),
					label_color = GUI.GRAY_80
				);
				if checkbox.just_checked {
					current_value.* = checkbox.checked;
				}
			}
		}

		// Path
		if compare(selected_entity_type.name, "Path") == 0 {
			path := selected_entity_ptr.(*Scene.Path);
			closed_checkbox := GUI._labeled_checkbox(
				gui,
				"Closed Path",
				content_width,
				24,
				id = "path_closed_checkbox",
				label_color = GUI.GRAY_80
			);
			if closed_checkbox.just_checked {
				closed := member_pointer(
					selected_entity_type, selected_entity_ptr, "closed", bool
				);
				closed.* = closed_checkbox.checked;
			}

			add_checkpoint_clicked, _, _ := GUI.labeled_text_button(
				gui, "Checkpoints", "Add", content_width, 24, id = "add_checkpoint_button"
			);
			if add_checkpoint_clicked {
				// Add new checkpoint at the end
				checkpoint: Scene.Checkpoint;
				checkpoint.position = V3f.{ 0, 0, 0 };
				idx := path.checkpoint_head;
				while idx >= 0 {
					checkpoint.position = editor.scene.checkpoints[idx].position + V3f.{ 1, 0, 0 };
					idx = editor.scene.checkpoints[idx].next;
				}
				Scene.add_checkpoint_to_path(*editor.scene, path, checkpoint);
			}
			add_skull_clicked, _, _ := GUI.labeled_text_button(
				gui, "Skulls", "Add", content_width, 24, id = "add_skull_button"
			);
			if add_skull_clicked {
				skull: Scene.Skull;
				skull.id = editor.scene.skulls.count;
				skull.path_id = member_pointer(
					selected_entity_type, selected_entity_ptr, "id", int
				).*;
				array_add(*editor.scene.skulls, skull);
			}

			idx := path.checkpoint_head;
			while idx >= 0 {
				checkpoint := *editor.scene.checkpoints[idx];

				cursor.y += 32;

				pos_result := GUI.labeled_v3_input(
					gui,
					tprint("Checkpoint %:", idx),
					content_width,
					24,
					value = checkpoint.position,
					drag_speed = editor.grid_snapping,
					precision = 2,
					id = tprint("checkpoint_position_%", idx),
				);
				if pos_result.changed {
					checkpoint.position = pos_result.value;
				}
				idx = checkpoint.next;
			}
		}
	} else {

		for count, display_name: field_count {
			if count != page.selected.count {
				continue; // Only show fields that are common to all selected entities
			}
			selected_entity_ptr := page.selected[0].ptr;
			selected_entity_type := page.selected[0].type;

			edits := table_find_pointer(*field_collecteds, display_name);
			if edits {
				field := edits.*[0]; // All edits in the array have the same path and type, so we can just look at the first one
				if field.type.type == .FLOAT {
					current_value := member_pointer(
						selected_entity_type, selected_entity_ptr, field.path, float
					);

					float_result := GUI.labeled_float_input(
						gui,
						tprint("%:", field.display_name),
						content_width,
						24,
						value = current_value.*,
						drag_speed = 0.1,
						precision = 2,
						id = tprint("entity_field_%", field.display_name),
					);
					if float_result.changed {
						dt := float_result.value - current_value.*;
						// Apply the same delta to all selected entities
						for selection: page.selected {
							current_value := member_pointer(
								selection.type, selection.ptr, edits.*[it_index].path, float
							);
							current_value.* += dt;
						}
					}
				}
				if field.type.type == .INTEGER {
					current_value := member_pointer(
						selected_entity_type, selected_entity_ptr, field.path, int
					);

					int_result := GUI.labeled_int_input(
						gui,
						tprint("%:", field.display_name),
						content_width,
						24,
						value = current_value.*,
						min_value = 0,
						id = tprint("entity_field_%", field.display_name),
					);
					if int_result.changed {
						dt := int_result.value - current_value.*;
						// Apply the same delta to all selected entities
						for selection: page.selected {
							current_value := member_pointer(
								selection.type, selection.ptr, edits.*[it_index].path, int
							);
							current_value.* += dt;
						}
					}
				}
				if field.type.type == .ENUM {
					enum_info := field.type.(*Type_Info_Enum);
					
					dropdown := GUI._labeled_dropdown(
						gui,
						tprint("%:", field.display_name),
						enum_info.names,
						content_width,
						24,
						id = tprint("entity_field_%", field.display_name),
						label_color = GUI.GRAY_80
					);
					if dropdown.changed {
						for selection: page.selected {
							current_value := member_pointer(
								selection.type, selection.ptr, edits.*[it_index].path, int
							);
							current_value.* = enum_info.values[dropdown.selected_index];
						}
					}
				}
				if field.type.type == .STRUCT {
					struct_info := field.type.(*Type_Info_Struct);
					if struct_info.name == "V3" {
						current_value := member_pointer(
							selected_entity_type, selected_entity_ptr, field.path, V3f
						);

						v3_result := GUI.labeled_v3_input(
							gui,
							tprint("%:", field.display_name),
							content_width,
							24,
							value = current_value.*,
							drag_speed = 0.1,
							precision = 2,
							id = tprint("entity_field_%", field.display_name),
						);
						if v3_result.changed {
							dt := v3_result.value - current_value.*;
							// Apply the same delta to all selected entities
							for selection: page.selected {
								current_value := member_pointer(
									selection.type, selection.ptr, edits.*[it_index].path, V3f
								);
								current_value.* += dt;
								if has_note(edits.*[it_index].member, "normalize") {
									current_value.* = normalize(current_value.*);
								}
							}
						}
					}
					if struct_info.name == "AABB" {
						pos := member_pointer(
							selected_entity_type, selected_entity_ptr, tprint("%.min", field.path), V3f
						);
						size := member_pointer(
							selected_entity_type, selected_entity_ptr, tprint("%.max", field.path), V3f
						);

						pos_result := GUI.labeled_v2_input(
							gui,
							tprint("%: Position", field.display_name),
							content_width,
							24,
							value = v2(pos.*),
							drag_speed = editor.grid_snapping,
							precision = 2,
							id = tprint("entity_field_%_pos", field.display_name),
							label_color = GUI.GRAY_80
						);
						if pos_result.changed {
							sized := size.* - pos.*;
							dt_pos := v2(pos_result.value) - v2(pos.*);
							// Apply the same delta to all selected entities
							for selection: page.selected {
								pos := member_pointer(
									selection.type, selection.ptr, tprint("%.min", edits.*[it_index].path), V3f
								);
								size := member_pointer(
									selection.type, selection.ptr, tprint("%.max", edits.*[it_index].path), V3f
								);
								pos.* += v3(dt_pos, 0);
								size.* += v3(dt_pos, 0);
							}
						}

						size_result := GUI.labeled_v2_input(
							gui,
							tprint("%: Size", field.display_name),
							content_width,
							24,
							value = v2(size.*) - v2(pos.*),
							drag_speed = editor.grid_snapping,
							precision = 2,
							id = tprint("entity_field_%_size", field.display_name),
							label_color = GUI.GRAY_80
						);
						if size_result.changed {
							// Apply the same delta to all selected entities
							for selection: page.selected {
								pos := member_pointer(
									selection.type, selection.ptr, tprint("%.min", edits.*[it_index].path), V3f
								);
								size := member_pointer(
									selection.type, selection.ptr, tprint("%.max", edits.*[it_index].path), V3f
								);
								dt_size := size_result.value - (v2(size.*) - v2(pos.*));
								size.* = v3(
									pos.*.x + size_result.value.x,
									pos.*.y + size_result.value.y,
									size.*.z
								) + v3(dt_size, 0);
							}
						}
					}
				}
				if field.type.type == .BOOL {
					current_value := member_pointer(
						selected_entity_type, selected_entity_ptr, field.path, bool
					);

					checkbox := GUI._labeled_checkbox(
						gui,
						tprint("%:", field.display_name),
						content_width,
						24,
						id = tprint("entity_field_%", field.display_name),
						label_color = GUI.GRAY_80
					);
					if checkbox.just_checked {
						for selection: page.selected {
							current_value := member_pointer(
								selection.type, selection.ptr, edits.*[it_index].path, bool
							);
							current_value.* = checkbox.checked;
						}
					}
				}
			}
		}
	}
}

remove_entity_at :: (scene: *Scene.Scene, entity: Scene_Placeable_Entity, index: int) {
	// Get the array info - offset to the count and data pointer
	count_ptr := (scene.(int) + entity.array_offset).(*int);
	data_ptr_ptr := (scene.(int) + entity.array_offset + 8).(**u8);

	count := count_ptr.*;
	data_ptr := data_ptr_ptr.*;
	element_size := entity.type.runtime_size.(int);

	if index < 0 || index >= count
		return;

	// Shift elements after the removed one
	for i: index..count - 2 {
		src := data_ptr + (i + 1) * element_size;
		dst := data_ptr + i * element_size;
		memcpy(dst, src, element_size);
	}

	// Decrease count
	count_ptr.* = count - 1;
}

draw_editor_toolbar :: (editor: *Editor, page: *Editor_Page, gui: *GUI.GUI_State, state: *State) {
	// Top toolbar
	toolbar_height := 40.0;
	toolbar_y := gui.controls.window_size.y - toolbar_height;

	GUI.push_quad_screen(gui, V2f.{ 0, toolbar_y }, V2f.{ gui.controls.window_size.x, toolbar_height }, V3f.{ 0.15, 0.15, 0.15 }, z = 50);

	GUI.default_params(gui).cursor = V2f.{ 8, toolbar_y + toolbar_height / 2 };
	GUI.default_params(gui).z = 51;
	GUI.default_params(gui).align = .Center_Left;
	GUI.default_params(gui).direction = .Right;

	// Save button
	play_clicked, _, _ := GUI._text_button(gui, "Play", id = "play_btn");
	if play_clicked {
		ask_enter_custom_instance: Command.Ask_Enter_Custom_Instance;
		content := Scene.serialize(editor.scene,, temp);
		ask_enter_custom_instance.terrain = content;
		send_web_message(
			state.platform, gui.controls.time, make_command(ask_enter_custom_instance)
		);
	}

	// Save button
	save_clicked, _, _ := GUI._text_button(gui, "Save", id = "save_btn");
	if save_clicked {
		page.show_save_dialog = true;
	}
	load_clicked, _, _ := GUI._text_button(gui, "Load", id = "load_btn");
	if load_clicked {
		// Refresh file list
		ask_list_terrain: Command.Ask_List_Terrain;
		ask_list_terrain.filter = page.load_filter;
		send_web_message(state.platform, gui.controls.time, make_command(ask_list_terrain));
		page.show_load_dialog = true;
	}

	clear_clicked, _, _ := GUI._text_button(gui, "Clear", id = "clear_btn");
	if clear_clicked {
		init_empty_terrain(editor, editor.terrain_width, editor.terrain_height);
		Scene.clear_scene(*editor.scene);
	}
	reset_camera_clicked, _, _ := GUI._text_button(gui, "Reset Camera", id = "reset_camera_btn");
	if reset_camera_clicked {
		editor.camera_offset = v3(0.0, -4, 8);
		Scene.reset_camera_zoom(*editor.scene.camera);
	}

	// Back button
	back_clicked, _, _ := GUI._text_button(gui, "Back to Menu", id = "back_btn");
	if back_clicked {
		state.screen_state = .Menu;
	}

	// Terrain size controls
	size_x := 620.0;

	// Width controls
	GUI.atom_label(gui, "W:", V2f.{ size_x, toolbar_y + 12 }, scale = 14, z = 51, color = V4f.{ 0.8, 0.8, 0.8, 1 });
	w_minus_clicked, _, _ := GUI._text_button(gui, tprint("W: %-", editor.terrain_width), id = "w_minus");
	if w_minus_clicked && editor.terrain_width > 10 {
		resize_terrain(editor, editor.terrain_width - 5, editor.terrain_height);
	}
	GUI.atom_label(gui, tprint("%", editor.terrain_width), V2f.{ size_x + 50, toolbar_y + 12 }, scale = 14, z = 51, color = V4f.{ 1, 1, 1, 1 });
	w_plus_clicked, _, _ := GUI._text_button(gui, tprint("W: %+", editor.terrain_width), id = "w_plus");
	if w_plus_clicked && editor.terrain_width < 200 {
		resize_terrain(editor, editor.terrain_width + 5, editor.terrain_height);
	}

	// Height controls
	h_minus_clicked, _, _ := GUI._text_button(gui, tprint("H: %-", editor.terrain_height), id = "h_minus");
	if h_minus_clicked && editor.terrain_height > 10 {
		resize_terrain(editor, editor.terrain_width, editor.terrain_height - 5);
	}
	h_plus_clicked, _, _ := GUI._text_button(gui, tprint("H: %+", editor.terrain_height), id = "h_plus");
	if h_plus_clicked && editor.terrain_height < 200 {
		resize_terrain(editor, editor.terrain_width, editor.terrain_height + 5);
	}

	// Current terrain info
	snap_clicked, _, _ := GUI._text_button(
		gui,
		tprint("Snap %", editor.grid_snapping),
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
	
	clock_clicked, _, _ := GUI._text_button(
		gui,
		tprint("Clock %", editor.clock_running),
		id = "clock_btn"
	);
	if clock_clicked {
		editor.clock_running = !editor.clock_running;
	}

	// Capture mouse on toolbar
	if point_aabb(gui.controls.mouse_pos, V2f.{ 0, toolbar_y }, V2f.{ gui.controls.window_size.x, toolbar_y + toolbar_height }) {
		gui.controls.captured_mouse = true;
	}
}

draw_load_dialog :: (editor: *Editor, page: *Editor_Page, gui: *GUI.GUI_State, platform: *Platform) {
	dialog_width := 500.0;
	dialog_height := 400.0;
	dialog_x := (gui.controls.window_size.x - dialog_width) / 2;
	dialog_y := (gui.controls.window_size.y - dialog_height) / 2;

	GUI.push_quad_screen(
		gui, V2f.{ 0, 0 }, gui.controls.window_size, V3f.{ 0, 0, 0 }, z = 98, a = 0.5
	);
	// Dialog box
	GUI.push_quad_screen(
		gui, v2(dialog_x, dialog_y), v2(dialog_width, dialog_height), V3f.{ 0.2, 0.2, 0.2 }, z = 99
	);
	GUI.push_quad_screen(
		gui, v2(dialog_x + 2, dialog_y + 2), v2(dialog_width - 4, dialog_height - 4), V3f.{ 0.1, 0.1, 0.1 }, z = 100
	);

	GUI.default_params(gui).cursor = v2(dialog_x + 8, dialog_y + dialog_height - 8);
	GUI.default_params(gui).direction = .Down;
	GUI.default_params(gui).align = .Top_Left;
	GUI.default_params(gui).z = 101;

	GUI._atom_label(gui, "Load Terrain", scale = 18, color = V4f.{ 1, 1, 1, 1 });

	// Input for filter
	new_load_filter := GUI.labeled_input_text(
		gui, "Filter", page.load_filter, dialog_width - 16, 24, label_color = GUI.GRAY_80, placeholder = "<filter>"
	);
	if new_load_filter != page.load_filter {
		free(page.load_filter.data);
		page.load_filter = sprint("%", new_load_filter);

		// Refresh file list
		ask_list_terrain: Command.Ask_List_Terrain;
		ask_list_terrain.filter = page.load_filter;
		send_web_message(platform, gui.controls.time, make_command(ask_list_terrain));
	}

	// List of files

	PAGE_SIZE := 10;
	page_count := max((page.terrain_list.count + PAGE_SIZE - 1) / PAGE_SIZE, 1);
	page.load_result_page = clamp(
		page.load_result_page,
		0,
		max((page.terrain_list.count + PAGE_SIZE - 1) / PAGE_SIZE - 1, 0)
	);

	beg := page.load_result_page * PAGE_SIZE;
	end := beg + PAGE_SIZE;
	end = min(end, page.terrain_list.count);
	terrain_list_view: []Editor_Page.Terrain_Entry;
	terrain_list_view.count = end - beg;
	terrain_list_view.data = page.terrain_list.data + beg;

	List_Row :: struct {
		name: string; @name("Name") @size(160)
		author: string; @name("Author") @size(130) @align(Right)
		date: string; @name("Created") @align(Right) @size(115)
		load: string; @name("Load") @button  @size(55) @align(Center)
	}
	rows := NewArray(terrain_list_view.count, List_Row,, temp);
	for terrain_list_view {
		rows[it_index].name = it.name;
		rows[it_index].author = it.author;
		if rows[it_index].author == "" {
			rows[it_index].author = "Anonymous";
		}
		if it.created_ms > 0 {
			cal := platform.to_calendar(milliseconds_to_apollo(it.created_ms));
			rows[it_index].date = tprint(
				"%/% %:%",
				cal.day_of_month_starting_at_0 + 1,
				cal.month_starting_at_0 + 1,
				cal.hour,
				cal.minute
			);
		} else {
			rows[it_index].date = "Immemorial";
		}
		rows[it_index].load = "Load";
	}

	table := GUI.table(
		gui, rows, v2(dialog_width - 20, 24 * 12 - 2), id = "terrain_list_table", _z = 101
	);
	if table.clicked_row_index != -1 {
		load_terrain_cmd: Command.Load_Terrain;
		load_terrain_cmd.terrain_id = terrain_list_view[table.clicked_row_index].id;
		send_web_message(
			platform, gui.controls.time, make_command(load_terrain_cmd)
		);
		page.show_load_dialog = false;
	}

	// for terrain_list_view {
	// 	GUI.push_id(gui, it_index);
	// 	defer GUI.pop_id(gui);

	// 	// GUI.move_cursor(gui, v2(4.0, 0.0));
	// 	// file_clicked, _, _ := GUI.labeled_text_button(
	// 	// 	gui,
	// 	// 	tprint("File: %", it.name),
	// 	// 	"Load",
	// 	// 	dialog_width - 16,
	// 	// 	24,
	// 	// 	id = "load_file",
	// 	// 	_z = 103,
	// 	// );

	// 	// if file_clicked {
	// 	// 	load_terrain_cmd: Command.Load_Terrain;
	// 	// 	load_terrain_cmd.terrain_id = it.id;
	// 	// 	send_web_message(
	// 	// 		platform, gui.controls.time, make_command(load_terrain_cmd)
	// 	// 	);
	// 	// 	page.show_load_dialog = false;
	// 	// }
	// }

	GUI.default_params(gui).cursor = v2(dialog_x + dialog_width - 14, dialog_y + 12);
	GUI.default_params(gui).direction = .Left;
	GUI.default_params(gui).align = .Bottom_Right;

	clicked := GUI._text_button(gui, "Cancel", id = "load_dialog_cancel");
	if clicked {
		page.show_load_dialog = false;
	}

	clicked = GUI._text_button(gui, ">", id = "load_dialog_next_page");
	if clicked {
		page.load_result_page = (page.load_result_page + 1) % page_count;
	}
	clicked = GUI._text_button(gui, "<", id = "load_dialog_prev_page");
	if clicked {
		page.load_result_page = (page.load_result_page + page_count - 1) % page_count;
	}
}
draw_save_dialog :: (editor: *Editor, page: *Editor_Page, gui: *GUI.GUI_State, platform: *Platform) {
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
	GUI.atom_label(
		gui,
		"Save Terrain",
		V2f.{ dialog_x + 20, dialog_y + dialog_height - 30 },
		scale = 18,
		z = 101,
		color = V4f.{ 1, 1, 1, 1 }
	);

	// Filename input area
	input_x := dialog_x + 20;
	input_y := dialog_y + dialog_height - 80;
	input_width := dialog_width - 40;
	input_height := 30.0;

	GUI.push_quad_screen(gui, V2f.{ input_x, input_y }, V2f.{ input_width, input_height }, V3f.{ 0.3, 0.3, 0.3 }, z = 101);

	// Show current filename
	new_save_dialog_input := GUI.atom_input_text(
		gui,
		page.save_dialog_input,
		input_height,
		input_width,
		_z = 102,
		_pos = .{ input_x, input_y },
		_align = .Bottom_Left,
		id = GUI.string_id("save_dialog_input")
	);
	if new_save_dialog_input != page.save_dialog_input {
		free(page.save_dialog_input);
		page.save_dialog_input = sprint("%", new_save_dialog_input);
	}

	// Save button
	save_clicked, _, _ := GUI.text_button(gui, "Save", V2f.{ dialog_x + dialog_width - 140, dialog_y + 20 }, z = 101, id = "dialog_save");
	if save_clicked {
		content := Scene.serialize(editor.scene,, temp);

		save: Command.Save_Terrain;
		save.ascii = content;
		memset(save.info.name.data, 0, save.info.name.count);
		memcpy(save.info.name.data, page.save_dialog_input.data, page.save_dialog_input.count);
		send_web_message(
			platform, gui.controls.time, make_command(save)
		);
		save_terrain_to_file(editor, page.save_dialog_input);
		page.show_save_dialog = false;
	}

	// Cancel button
	cancel_clicked, _, _ := GUI.text_button(gui, "Cancel", V2f.{ dialog_x + dialog_width - 70, dialog_y + 20 }, z = 101, id = "dialog_cancel");
	if cancel_clicked || gui.controls.just_pressed[Key.Escape] {
		page.show_save_dialog = false;
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
	WRender.render_scene(frame, framegraph, editor.scene, store, in_editor = true);
	WRender.render_editor(frame, framegraph, editor, store);

	// Render the GUI
	WRender.render_gui(frame, framegraph, editor.gui_state, store);

	WRender.end_frame(framegraph, frame);
}
