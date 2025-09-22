#scope_file
WRender :: #import "WRender";
Assets :: #import "Assets";
Platform :: #import "Platform";
Scene :: #import "Scene";
#import "String";
#import "Basic";
#import "Algebra";

#scope_export

Colormaps_Rect :: struct {
	prop    :: V4f.{ 0 / 4.0, 0 / 4.0, 1 / 4.0, 1 / 4.0 };
	vehicle :: V4f.{ 1 / 4.0, 0 / 4.0, 1 / 4.0, 1 / 4.0 };
	pirate  :: V4f.{ 0 / 4.0, 1 / 4.0, 1 / 4.0, 1 / 4.0 };
}

Model_Id :: enum {
	Racer :: 1;
	SUV :: 2;
	Speedster :: 3;
	Drag_Racer :: 4;
	Monster_Truck :: 5;
	Vintage_Racer :: 6;
	Boat_Row :: 7;
	Boat_Fishing :: 8;
	Taxi :: 9;
	Police :: 10;
	Ambulance :: 11;
	Spaceship :: 12;
	Tombstone :: 13;
	Tile :: 14;
	Skull :: 15;
	Coin :: 16;
	Key :: 17;
	Mark :: 18;
	Gate :: 19;
	Gate_Close :: 20;
	Shuriken :: 21;
	Spirit :: 22;
}
Model_Id_Count :: #run enum_highest_value(Model_Id) + 1;

Texture_Id :: enum {
	Ice :: 0;
	Coin :: 1;
	Slippy_Ice :: 2;
	Grass :: 3;
	Dirt :: 4;
	Mark :: 5;
	Vehicle_Colormap :: 6;
}

Particle_Texture_Id :: enum {
	None :: 0;
}

Shader_Id :: enum {
	Font :: 0;
	Model :: 1;
	Texture :: 2;
	Instance :: 3;
	Tile :: 4;
}

Store :: struct {
	quad_shader: WRender.WShader;
	present_shader: WRender.WShader;
	geometry_shader: WRender.WShader;
	geometry_shadow_shader: WRender.WShader;

	terrain_tree_snow_a: WRender.Model;
	terrain_tree_snow_b: WRender.Model;
	terrain_tree_snow_c: WRender.Model;
	terrain_snowman: WRender.Model;
	terrain_snowman_hat: WRender.Model;
	terrain_snow_flat: WRender.Model;
	terrain_snow_flat_large: WRender.Model;
	terrain_snow_pile: WRender.Model;
	terrain_snowflake_a: WRender.Model;
	terrain_snowflake_b: WRender.Model;
	terrain_snowflake_c: WRender.Model;
	rock_small: WRender.Model;
	rock_medium: WRender.Model;
	rock_large: WRender.Model;
	tile_model: WRender.Model;

	racer_model: WRender.Model;
	suv_model: WRender.Model;
	speedster_model: WRender.Model;
	drag_racer_model: WRender.Model;
	monster_truck_model: WRender.Model;
	vintage_racer_model: WRender.Model;
	boat_row_model: WRender.Model;
	boat_fishing_model: WRender.Model;
	taxi_model: WRender.Model;
	police_model: WRender.Model;
	ambulance_model: WRender.Model;
	spaceship_model: WRender.Model;
	tombstone_model: WRender.Model;
	skull_model: WRender.Model;
	pirateship_model: WRender.Model;
	coin_model: WRender.Model;
	key_model: WRender.Model;
	mark_model: WRender.Model;
	gate_model: WRender.Model;
	gate_close_model: WRender.Model;
	gate_finish_model: WRender.Model;
	gate_finish_close_model: WRender.Model;
	shuriken_model: WRender.Model;
	spirit_model: WRender.Model;
	flag_model: WRender.Model;
	flag_down_model: WRender.Model;
	trophy_model: WRender.Model;

	antiair_camion_model: WRender.Model;
	antiair_canon_model: WRender.Model;
	missile_model: WRender.Model;

	robot_a0_model: WRender.Model;
	robot_a1_model: WRender.Model;
	robot_a2_model: WRender.Model;
	robot_a3_model: WRender.Model;
	robot_a4_model: WRender.Model;
	robot_a5_model: WRender.Model;

	number_0_model: WRender.Model;
	number_1_model: WRender.Model;
	number_2_model: WRender.Model;
	number_3_model: WRender.Model;
	number_4_model: WRender.Model;
	number_5_model: WRender.Model;
	number_6_model: WRender.Model;
	number_7_model: WRender.Model;
	number_8_model: WRender.Model;
	number_9_model: WRender.Model;

	unit_cylinder_model: WRender.Model;
	unit_sphere_model: WRender.Model;
	indicator_outline_model: WRender.Model;
	indicator_stroke_model: WRender.Model;

	colormaps: WRender.WTexture;
	terrain_tile_albedo: WRender.WTexture;
	terrain_tile_normal: WRender.WTexture;
	particle_texture: WRender.WTexture;
	ui_atlas: WRender.WTexture;
	font_atlas: WRender.WTexture;

	// particle_texture_png: Assets.Image;

	// tile_snow_albedo_png: Assets.Image;
	// tile_snow_normal_png: Assets.Image;
	// tile_snow_height_png: Assets.Image;

	// tile_cliff_albedo_png: Assets.Image;
	// tile_cliff_normal_png: Assets.Image;
	// tile_cliff_height_png: Assets.Image;

	// tile_grass_albedo_png: Assets.Image;
	// tile_grass_normal_png: Assets.Image;
	// tile_grass_height_png: Assets.Image;

	// tile_slippy_albedo_png: Assets.Image;
	// tile_slippy_normal_png: Assets.Image;
	// tile_slippy_height_png: Assets.Image;

	// ui_atlas_png: Assets.Image;
	// tile_atlas_png: Assets.Image;

	// skybox_ski_png: Assets.Image;
	// skybox_ski: Render.Texture;

	// tile_snow_albedo: Render.Texture;
	// tile_snow_normal: Render.Texture;
	// tile_snow_height: Render.Texture;

	// tile_cliff_albedo: Render.Texture;
	// tile_cliff_normal: Render.Texture;
	// tile_cliff_height: Render.Texture;

	// tile_grass_albedo: Render.Texture;
	// tile_grass_normal: Render.Texture;
	// tile_grass_height: Render.Texture;

	// tile_slippy_albedo: Render.Texture;
	// tile_slippy_normal: Render.Texture;
	// tile_slippy_height: Render.Texture;


	loser_ogg: Platform.Audio;
	footstep_0_ogg: Platform.Audio;
	footstep_1_ogg: Platform.Audio;
	footstep_2_ogg: Platform.Audio;
	footstep_3_ogg: Platform.Audio;
	footstep_4_ogg: Platform.Audio;
	click_wav: Platform.Audio;
	snowflakes_and_lights_ogg: Platform.Audio;

	// font_shader: Render.Shader;
	// model_shader: Render.Shader;
	// texture_shader: Render.Shader;
	// instance_shader: Render.Shader;
	// tile_shader: Render.Shader;
	// quad_texture_shader: Render.Shader;
	// postpro_shader: Render.Shader;
	// instanced_texture_shader: Render.Shader;
	// shadow_shader: Render.Shader;
	// shadow_instanced_shader: Render.Shader;
	// shadow_instanced_texture_shader: Render.Shader;
	// skybox_shader: Render.Shader;
	// particle_shader: Render.Shader;

	// ice_texture: Render.Texture;
	// coin_texture: Render.Texture;
	// slippy_ice_texture: Render.Texture;
	// grass_texture: Render.Texture;
	// dirt_texture: Render.Texture;
	// mark_texture: Render.Texture;
	// vehicle_colormap: Render.Texture;
	// tile_atlas: Render.Texture;

	// z_facing_unit_square_geometry: Render.Geometry;
	// flag_geometry: Render.Geometry;
	// flag_down_geometry: Render.Geometry;
	// player_geometry: Render.Geometry;
	// drag_racer_geometry: Render.Geometry;
	// vintage_racer_geometry: Render.Geometry;
	// monster_truck_geometry: Render.Geometry;
	// boat_row_geometry: Render.Geometry;
	// boat_fishing_geometry: Render.Geometry;
	// taxi_geometry: Render.Geometry;
	// police_geometry: Render.Geometry;
	// ambulance_geometry: Render.Geometry;
	// spaceship_geometry: Render.Geometry;
	// speedster_geometry: Render.Geometry;
	// tombstone_geometry: Render.Geometry;
	// skull_geometry: Render.Geometry;
	// coin_geometry: Render.Geometry;
	// key_geometry: Render.Geometry;
	// mark_geometry: Render.Geometry;
	// gate_geometry: Render.Geometry;
	// gate_close_geometry: Render.Geometry;
	// gate_finish_geometry: Render.Geometry;
	// gate_finish_close_geometry: Render.Geometry;
	// shuriken_geometry: Render.Geometry;
	// spirit_geometry: Render.Geometry;
	// skybox_geometry: Render.Geometry;
	// indicator_outline_geometry: Render.Geometry;
	// indicator_stroke_geometry: Render.Geometry;

	// unit_cylinder_geometry: Render.Geometry;
	// unit_sphere_geometry: Render.Geometry;

	// number_0_geometry: Render.Geometry;
	// number_1_geometry: Render.Geometry;
	// number_2_geometry: Render.Geometry;
	// number_3_geometry: Render.Geometry;
	// number_4_geometry: Render.Geometry;
	// number_5_geometry: Render.Geometry;
	// number_6_geometry: Render.Geometry;
	// number_7_geometry: Render.Geometry;
	// number_8_geometry: Render.Geometry;
	// number_9_geometry: Render.Geometry;

	// robot_a0_geometry: Render.Geometry;
	// robot_a1_geometry: Render.Geometry;
	// robot_a2_geometry: Render.Geometry;
	// robot_a3_geometry: Render.Geometry;
	// robot_a4_geometry: Render.Geometry;
	// robot_a5_geometry: Render.Geometry;
}

get_number_model ::  (store: Store, digit: int) -> *WRender.Model {
	if digit == 0 {
		return *store.number_0_model;
	} else if digit == 1 {
		return *store.number_1_model;
	} else if digit == 2 {
		return *store.number_2_model;
	} else if digit == 3 {
		return *store.number_3_model;
	} else if digit == 4 {
		return *store.number_4_model;
	} else if digit == 5 {
		return *store.number_5_model;
	} else if digit == 6 {
		return *store.number_6_model;
	} else if digit == 7 {
		return *store.number_7_model;
	} else if digit == 8 {
		return *store.number_8_model;
	} else if digit == 9 {
		return *store.number_9_model;
	}
	return null;
}
// get_number_geometry :: (store: Store, digit: int) -> *Render.Geometry {
// 	if digit == 0 {
// 		return *store.number_0_geometry;
// 	} else if digit == 1 {
// 		return *store.number_1_geometry;
// 	} else if digit == 2 {
// 		return *store.number_2_geometry;
// 	} else if digit == 3 {
// 		return *store.number_3_geometry;
// 	} else if digit == 4 {
// 		return *store.number_4_geometry;
// 	} else if digit == 5 {
// 		return *store.number_5_geometry;
// 	} else if digit == 6 {
// 		return *store.number_6_geometry;
// 	} else if digit == 7 {
// 		return *store.number_7_geometry;
// 	} else if digit == 8 {
// 		return *store.number_8_geometry;
// 	} else if digit == 9 {
// 		return *store.number_9_geometry;
// 	}
// 	return null;
// }
// get_geometry :: (store: Store, id: int) -> *Render.Geometry {
// 	return get_geometry(store, id.(Model_Id));
// }

get_model :: (store: Store, id: Model_Id) -> *WRender.Model {
	if #complete id == {
		case .Racer; return *store.racer_model;
		case .SUV; return *store.suv_model;
		case .Tile; return *store.tile_model;
		case .Speedster; return *store.speedster_model;
		case .Tombstone; return *store.tombstone_model;
		case .Skull; return *store.pirateship_model;
		case .Coin; return *store.coin_model;
		case .Key; return *store.key_model;
		case .Mark; return *store.mark_model;
		case .Gate; return *store.gate_model;
		case .Gate_Close; return *store.gate_close_model;
		case .Shuriken; return *store.shuriken_model;
		case .Spirit; return *store.spirit_model;
		case .Drag_Racer; return *store.drag_racer_model;
		case .Monster_Truck; return *store.monster_truck_model;
		case .Vintage_Racer; return *store.vintage_racer_model;
		case .Boat_Row; return *store.boat_row_model;
		case .Boat_Fishing; return *store.boat_fishing_model;
		case .Taxi; return *store.taxi_model;
		case .Police; return *store.police_model;
		case .Ambulance; return *store.ambulance_model;
		case .Spaceship; return *store.spaceship_model;
	}
}
// get_geometry :: (store: Store, id: Model_Id) -> *Render.Geometry {
// 	return null;
// }
get_axes_model :: (store: Store, i: int) -> *WRender.Model {
	if i == 0 {
		return *store.robot_a0_model;
	} else if i == 1 {
		return *store.robot_a1_model;
	} else if i == 2 {
		return *store.robot_a2_model;
	} else if i == 3 {
		return *store.robot_a3_model;
	} else if i == 4 {
		return *store.robot_a4_model;
	} else if i == 5 {
		return *store.robot_a5_model;
	}
	return null;
}

get_tile_rect :: (id: Scene.Tile.Kind) -> V4f {
	rect: V4f;
	if #complete id == {
		case .None;
			rect = V4f.{ 0.0, 0.0, 0.0, 0.0 } / 4.0;
		case .Ice;
			rect = V4f.{ 1.0, 3.0, 1.0, 1.0 } / 4.0;
		case .Slippy_Ice;
			rect = V4f.{ 0.0, 2.0, 1.0, 1.0 } / 4.0;
		case .Grass;
			rect = V4f.{ 0.0, 3.0, 1.0, 1.0 } / 4.0;
		case .Dirt;
			rect = V4f.{ 1.0, 1.0, 1.0, 1.0 } / 4.0;
	}
	rect.x += 0.5 / 512.0;
	rect.y += 0.5 / 512.0;
	rect.z -= 1.0 / 512.0;
	rect.w -= 1.0 / 512.0;
	return rect;
}

// get_albedo :: (store: Store, id: Scene.Tile.Kind) -> *Render.Texture {
// 	if #complete id == {
// 		case .None;
// 			return null;
// 		case .Ice;
// 			return *store.ice_texture;
// 		case .Slippy_Ice;
// 			return *store.tile_slippy_albedo;
// 		case .Grass;
// 			return *store.tile_grass_albedo;
// 		case .Dirt;
// 			return *store.dirt_texture;
// 	}
// 	return null;
// }

// get_height :: (store: Store, id: Scene.Tile.Kind) -> *Render.Texture {
// 	if #complete id == {
// 		case .None;
// 			return null;
// 		case .Ice;
// 			return *store.tile_snow_height;
// 		case .Slippy_Ice;
// 			return *store.tile_slippy_height;
// 		case .Grass;
// 			return *store.tile_grass_height;
// 		case .Dirt;
// 			return *store.tile_cliff_height;
// 	}
// 	return null;
// }

// get_normal :: (store: Store, id: Scene.Tile.Kind) -> *Render.Texture {
// 	if #complete id == {
// 		case .None;
// 			return null;
// 		case .Ice;
// 			return *store.ice_texture;
// 		case .Slippy_Ice;
// 			return *store.tile_slippy_normal;
// 		case .Grass;
// 			return *store.tile_grass_normal;
// 		case .Dirt;
// 			return *store.dirt_texture;
// 	}
// 	return null;
// }

// get_texture :: (store: Store, id: Texture_Id) -> *Render.Texture {
// 	if #complete id == {
// 		case .Ice; return *store.ice_texture;
// 		case .Coin; return *store.coin_texture;
// 		case .Slippy_Ice; return *store.slippy_ice_texture;
// 		case .Grass; return *store.grass_texture;
// 		case .Dirt; return *store.dirt_texture;
// 		case .Mark; return *store.mark_texture;
// 		case .Vehicle_Colormap; return *store.vehicle_colormap;
// 	}
// 	return null;
// }

// get_shader :: (store: Store, id: Shader_Id) -> *Render.Shader {
// 	if #complete id == {
// 		case .Font; return *store.font_shader;
// 		case .Model; return *store.model_shader;
// 		case .Texture; return *store.texture_shader;
// 		case .Instance; return *store.instance_shader;
// 		case .Tile; return *store.tile_shader;
// 	}
// 	return null;
// }

get_footstep_sound :: (store: Store, index: int) -> *Platform.Audio {
	if index == 0 {
		return *store.footstep_0_ogg;
	} else if index == 1 {
		return *store.footstep_1_ogg;
	} else if index == 2 {
		return *store.footstep_2_ogg;
	} else if index == 3 {
		return *store.footstep_3_ogg;
	} else if index == 4 {
		return *store.footstep_4_ogg;
	}
	return null;
}

get_wprop :: (store: Store, id: Assets.Prop_Id) -> *WRender.Model {
	if #complete id == {
		case .TERRAIN_TREE_SNOW_A;
			return *store.terrain_tree_snow_a;
		case .TERRAIN_TREE_SNOW_B;
			return *store.terrain_tree_snow_b;
		case .TERRAIN_TREE_SNOW_C;
			return *store.terrain_tree_snow_c;
		case .TERRAIN_SNOWMAN;
			return *store.terrain_snowman;
		case .TERRAIN_SNOWMAN_HAT;
			return *store.terrain_snowman_hat;
		case .TERRAIN_SNOW_FLAT;
			return *store.terrain_snow_flat;
		case .TERRAIN_SNOW_FLAT_LARGE;
			return *store.terrain_snow_flat_large;
		case .TERRAIN_SNOW_PILE;
			return *store.terrain_snow_pile;
		case .TERRAIN_SNOWFLAKE_A;
			return *store.terrain_snowflake_a;
		case .TERRAIN_SNOWFLAKE_B;
			return *store.terrain_snowflake_b;
		case .TERRAIN_SNOWFLAKE_C;
			return *store.terrain_snowflake_c;
		case .ROCK_SMALL;
			return *store.rock_small;
		case .ROCK_MEDIUM;
			return *store.rock_medium;
		case .ROCK_LARGE;
			return *store.rock_large;
	}
	return null;
}

// get_prop :: (store: Store, id: Assets.Prop_Id) -> *Render.Geometry {
// 	return null;
// }

init_store :: (platform: Platform.Platform, store: *Store) {
	if Assets.RUNTIME {
		Assets.load_everything();
	}

	store.geometry_shader.code = xx Assets.GEOMETRY_WGSL;
	store.geometry_shader.input = type_info(WRender.WFramegraph.Vertex);

	store.geometry_shadow_shader.code = xx Assets.GEOMETRY_SHADOW_WGSL;
	store.geometry_shadow_shader.input = type_info(WRender.WFramegraph.Vertex);

	store.present_shader.code = xx Assets.PRESENT_WGSL;
	store.present_shader.input = .{};

	store.quad_shader.code = xx Assets.QUAD_WGSL;
	store.quad_shader.input = .{};

	store.terrain_tree_snow_a =
		WRender.Model.make_from_obj(Assets.TERRAIN_TREE_SNOW_A, "terrain_tree_snow_a.obj");
	store.terrain_tree_snow_b =
		WRender.Model.make_from_obj(Assets.TERRAIN_TREE_SNOW_B, "terrain_tree_snow_b.obj");
	store.terrain_tree_snow_c =
		WRender.Model.make_from_obj(Assets.TERRAIN_TREE_SNOW_C, "terrain_tree_snow_c.obj");
	store.terrain_snowman =
		WRender.Model.make_from_obj(Assets.TERRAIN_SNOWMAN, "terrain_snowman.obj");
	store.terrain_snowman_hat =
		WRender.Model.make_from_obj(Assets.TERRAIN_SNOWMAN_HAT, "terrain_snowman_hat.obj");
	store.terrain_snow_flat =
		WRender.Model.make_from_obj(Assets.TERRAIN_SNOW_FLAT, "terrain_snow_flat.obj");
	store.terrain_snow_flat_large =
		WRender.Model.make_from_obj(Assets.TERRAIN_SNOW_FLAT_LARGE, "terrain_snow_flat_large.obj");
	store.terrain_snow_pile =
		WRender.Model.make_from_obj(Assets.TERRAIN_SNOW_PILE, "terrain_snow_pile.obj");
	store.terrain_snowflake_a =
		WRender.Model.make_from_obj(Assets.TERRAIN_SNOWFLAKE_A, "terrain_snowflake_a.obj");
	store.terrain_snowflake_b =
		WRender.Model.make_from_obj(Assets.TERRAIN_SNOWFLAKE_B, "terrain_snowflake_b.obj");
	store.terrain_snowflake_c =
		WRender.Model.make_from_obj(Assets.TERRAIN_SNOWFLAKE_C, "terrain_snowflake_c.obj");
	store.rock_small = WRender.Model.make_from_obj(Assets.ROCK_SMALL, "rock_small.obj");
	store.rock_medium = WRender.Model.make_from_obj(Assets.ROCK_MEDIUM, "rock_medium.obj");
	store.rock_large = WRender.Model.make_from_obj(Assets.ROCK_LARGE, "rock_large.obj");
	store.tile_model = WRender.Model.make_from_obj(Assets.TILE_OBJ, "tile.obj");

	prop_colormap_png := Assets.Image.make_from_memory(Assets.COLORMAPS_PNG, 4);
	defer Assets.Image.free(*prop_colormap_png);
	store.colormaps = WRender.WTexture.make_from_image(prop_colormap_png, "colormaps");

	terrain_tile_albedo_png := Assets.Image.make_from_memory(Assets.TERRAIN_TILE_ALBEDO_PNG, 4);
	defer Assets.Image.free(*terrain_tile_albedo_png);
	store.terrain_tile_albedo =
		WRender.WTexture.make_from_image(terrain_tile_albedo_png, "terrain_tile_albedo");
	terrain_tile_normal_png := Assets.Image.make_from_memory(Assets.TERRAIN_TILE_NORMAL_PNG, 4);
	defer Assets.Image.free(*terrain_tile_normal_png);
	store.terrain_tile_normal =
		WRender.WTexture.make_from_image(terrain_tile_normal_png, "terrain_tile_normal");
		
	particle_texture_png := Assets.Image.make_from_memory(Assets.PARTICLE_TEXTURE_PNG, 4);
	store.particle_texture =
		WRender.WTexture.make_from_image(particle_texture_png, "particle_texture");
	defer Assets.Image.free(*particle_texture_png);

	ui_atlas_png := Assets.Image.make_from_memory(Assets.ui_atlas_png, 4);
	defer Assets.Image.free(*ui_atlas_png);
	store.ui_atlas = WRender.WTexture.make_from_image(ui_atlas_png, "ui_atlas");

	store.font_atlas = WRender.WTexture.make_from_image(Assets.MAIN_FONT.atlas, "font_atlas");

	store.racer_model = WRender.Model.make_from_obj(Assets.VEHICLE_RACER_OBJ);
	store.suv_model = WRender.Model.make_from_obj(Assets.VEHICLE_SUV_OBJ);
	store.speedster_model = WRender.Model.make_from_obj(Assets.VEHICLE_SPEEDSTER_OBJ);
	store.drag_racer_model = WRender.Model.make_from_obj(Assets.VEHICLE_DRAG_RACER_OBJ);
	store.monster_truck_model = WRender.Model.make_from_obj(Assets.VEHICLE_MONSTER_TRUCK_OBJ);
	store.vintage_racer_model = WRender.Model.make_from_obj(Assets.VEHICLE_VINTAGE_RACER_OBJ);
	store.boat_row_model = WRender.Model.make_from_obj(Assets.BOAT_ROW_OBJ);
	store.boat_fishing_model = WRender.Model.make_from_obj(Assets.BOAT_FISHING_OBJ);
	store.taxi_model = WRender.Model.make_from_obj(Assets.TAXI_OBJ);
	store.police_model = WRender.Model.make_from_obj(Assets.POLICE_OBJ);
	store.ambulance_model = WRender.Model.make_from_obj(Assets.AMBULANCE_OBJ);
	store.spaceship_model = WRender.Model.make_from_obj(Assets.SPACESHIP_OBJ);
	store.tombstone_model = WRender.Model.make_from_obj(Assets.TOMBSTONE_OBJ);
	store.skull_model = WRender.Model.make_from_obj(Assets.SKULL_OBJ);
	store.pirateship_model = WRender.Model.make_from_obj(Assets.PIRATE_SHIP_OBJ);
	store.coin_model = WRender.Model.make_from_obj(Assets.COIN_OBJ);
	store.key_model = WRender.Model.make_from_obj(Assets.KEY_OBJ);
	store.mark_model = WRender.Model.make_from_obj(Assets.MARK_OBJ);
	store.gate_model = WRender.Model.make_from_obj(Assets.GATE_OBJ);
	store.gate_close_model = WRender.Model.make_from_obj(Assets.GATE_CLOSE_OBJ);
	store.spirit_model = WRender.Model.make_from_obj(Assets.SPIRIT_OBJ);
	store.shuriken_model = WRender.Model.make_from_obj(Assets.SHURIKEN_OBJ);
	store.gate_finish_model = WRender.Model.make_from_obj(Assets.GATE_FINISH_OBJ);
	store.gate_finish_close_model = WRender.Model.make_from_obj(Assets.GATE_FINISH_CLOSE_OBJ);
	store.flag_model = WRender.Model.make_from_obj(Assets.FLAG_OBJ);
	store.flag_down_model = WRender.Model.make_from_obj(Assets.FLAG_DOWN_OBJ);
	store.trophy_model = WRender.Model.make_from_obj(Assets.TROPHY_OBJ);
	store.antiair_camion_model = WRender.Model.make_from_obj(Assets.ANTIAIR_CAMION_OBJ);
	store.antiair_canon_model = WRender.Model.make_from_obj(Assets.ANTIAIR_CANON_OBJ);
	store.missile_model = WRender.Model.make_from_obj(Assets.MISSILE_OBJ);
	store.robot_a0_model = WRender.Model.make_from_obj(Assets.ROBOT_A0_OBJ);
	store.robot_a1_model = WRender.Model.make_from_obj(Assets.ROBOT_A1_OBJ);
	store.robot_a2_model = WRender.Model.make_from_obj(Assets.ROBOT_A2_OBJ);
	store.robot_a3_model = WRender.Model.make_from_obj(Assets.ROBOT_A3_OBJ);
	store.robot_a4_model = WRender.Model.make_from_obj(Assets.ROBOT_A4_OBJ);
	store.robot_a5_model = WRender.Model.make_from_obj(Assets.ROBOT_A5_OBJ);
	store.number_0_model = WRender.Model.make_from_obj(Assets.NUMBER_0_OBJ);
	store.number_1_model = WRender.Model.make_from_obj(Assets.NUMBER_1_OBJ);
	store.number_2_model = WRender.Model.make_from_obj(Assets.NUMBER_2_OBJ);
	store.number_3_model = WRender.Model.make_from_obj(Assets.NUMBER_3_OBJ);
	store.number_4_model = WRender.Model.make_from_obj(Assets.NUMBER_4_OBJ);
	store.number_5_model = WRender.Model.make_from_obj(Assets.NUMBER_5_OBJ);
	store.number_6_model = WRender.Model.make_from_obj(Assets.NUMBER_6_OBJ);
	store.number_7_model = WRender.Model.make_from_obj(Assets.NUMBER_7_OBJ);
	store.number_8_model = WRender.Model.make_from_obj(Assets.NUMBER_8_OBJ);
	store.number_9_model = WRender.Model.make_from_obj(Assets.NUMBER_9_OBJ);

	store.unit_cylinder_model = WRender.Model.make_from_obj(Assets.UNIT_CYLINDER_OBJ);
	store.unit_sphere_model = WRender.Model.make_from_obj(Assets.UNIT_SPHERE_OBJ);

	store.indicator_outline_model = WRender.Model.make_from_obj(Assets.INDICATOR_OUTLINE_OBJ);
	store.indicator_stroke_model = WRender.Model.make_from_obj(Assets.INDICATOR_STROKE_OBJ);

	// store.tile_atlas_png = Assets.Image.make_from_memory(Assets.tile_atlas_png, 4);
	// store.tile_atlas = Render.Texture.make_from_image(store.tile_atlas_png);

	// store.tile_cliff_albedo_png = Assets.Image.make_from_memory(Assets.tile_cliff_albedo_png, 4);
	// store.tile_cliff_normal_png = Assets.Image.make_from_memory(Assets.tile_cliff_normal_png, 3);
	// store.tile_cliff_height_png = Assets.Image.make_from_memory(Assets.tile_cliff_height_png, 3);

	// store.tile_snow_albedo_png = Assets.Image.make_from_memory(Assets.tile_snow_albedo_png, 4);
	// store.tile_snow_normal_png = Assets.Image.make_from_memory(Assets.tile_snow_normal_png, 3);
	// store.tile_snow_height_png = Assets.Image.make_from_memory(Assets.tile_snow_height_png, 3);

	// store.tile_grass_albedo_png = Assets.Image.make_from_memory(Assets.tile_grass_albedo_png, 4);
	// store.tile_grass_normal_png = Assets.Image.make_from_memory(Assets.tile_grass_normal_png, 3);
	// store.tile_grass_height_png = Assets.Image.make_from_memory(Assets.tile_grass_height_png, 3);

	// store.tile_slippy_albedo_png = Assets.Image.make_from_memory(Assets.tile_slippy_albedo_png, 4);
	// store.tile_slippy_normal_png = Assets.Image.make_from_memory(Assets.tile_slippy_normal_png, 3);
	// store.tile_slippy_height_png = Assets.Image.make_from_memory(Assets.tile_slippy_height_png, 3);

	// store.tile_cliff_albedo = Render.Texture.make_from_image(store.tile_cliff_albedo_png);
	// store.tile_cliff_normal = Render.Texture.make_from_image(store.tile_cliff_normal_png);
	// store.tile_cliff_height = Render.Texture.make_from_image(store.tile_cliff_height_png);

	// store.tile_snow_albedo = Render.Texture.make_from_image(store.tile_snow_albedo_png);
	// store.tile_snow_normal = Render.Texture.make_from_image(store.tile_snow_normal_png);
	// store.tile_snow_height = Render.Texture.make_from_image(store.tile_snow_height_png);

	// store.tile_grass_albedo = Render.Texture.make_from_image(store.tile_grass_albedo_png);
	// store.tile_grass_normal = Render.Texture.make_from_image(store.tile_grass_normal_png);
	// store.tile_grass_height = Render.Texture.make_from_image(store.tile_grass_height_png);

	// store.tile_slippy_albedo = Render.Texture.make_from_image(store.tile_slippy_albedo_png);
	// store.tile_slippy_normal = Render.Texture.make_from_image(store.tile_slippy_normal_png);
	// store.tile_slippy_height = Render.Texture.make_from_image(store.tile_slippy_height_png);

	// store.skybox_ski_png = Assets.Image.make_from_memory(Assets.SKYBOX_SKI_PNG, 4);
	// store.skybox_ski = Render.Texture.make_from_image(store.skybox_ski_png);

	// store.loser_ogg = platform.load_audio(xx Assets.LOSER_OGG);
	// store.footstep_0_ogg = platform.load_audio(xx Assets.FOOTSTEP_SNOW_0_OGG);
	// store.footstep_1_ogg = platform.load_audio(xx Assets.FOOTSTEP_SNOW_1_OGG);
	// store.footstep_2_ogg = platform.load_audio(xx Assets.FOOTSTEP_SNOW_2_OGG);
	// store.footstep_3_ogg = platform.load_audio(xx Assets.FOOTSTEP_SNOW_3_OGG);
	// store.footstep_4_ogg = platform.load_audio(xx Assets.FOOTSTEP_SNOW_4_OGG);
	// store.click_wav = platform.load_audio(xx Assets.CLICK_WAV);
	// store.snowflakes_and_lights_ogg = platform.load_audio(xx Assets.SNOWFLAKES_AND_LIGHTS_OGG);

	// store.particle_texture_png = Assets.Image.make_from_memory(Assets.PARTICLE_TEXTURE_PNG, 4);
	// store.particle_texture = Render.Texture.make_from_image(store.particle_texture_png);

	// store.skybox_shader = Render.Shader.make(
	// 	xx Assets.SKYBOX_VERTEX, xx Assets.SKYBOX_FRAGMENT
	// );
	// store.particle_shader = Render.Shader.make(
	// 	xx Assets.PARTICLE_VERTEX, xx Assets.PARTICLE_FRAGMENT
	// );
	// store.model_shader = Render.Shader.make(
	// 	xx Assets.PLAIN_VERTEX, xx Assets.PLAIN_FRAGMENT
	// );
	// store.texture_shader = Render.Shader.make(
	// 	xx Assets.PLAIN_VERTEX, xx Assets.TEXTURE_FRAGMENT
	// );
	// store.font_shader = Render.Shader.make(
	// 	xx Assets.FONT_VERTEX, xx Assets.FONT_FRAGMENT
	// );
	// store.instance_shader = Render.Shader.make(
	// 	xx Assets.INSTANCE_VERTEX, xx Assets.INSTANCE_FRAGMENT
	// );
	// store.tile_shader = Render.Shader.make(
	// 	xx Assets.TILE_VERTEX, xx Assets.TILE_FRAGMENT
	// );
	// store.quad_texture_shader = Render.Shader.make(
	// 	xx Assets.QUAD_TEXTURE_VERTEX, xx Assets.QUAD_TEXTURE_FRAGMENT
	// );
	// store.postpro_shader = Render.Shader.make(
	// 	xx Assets.POSTPROCESS_VERTEX, xx Assets.POSTPROCESS_FRAGMENT
	// );
	// store.shadow_shader = Render.Shader.make(
	// 	xx Assets.SHADOW_VERTEX, xx Assets.SHADOW_FRAGMENT
	// );
	// store.shadow_instanced_shader = Render.Shader.make(
	// 	xx Assets.SHADOW_INSTANCED_VERTEX, xx Assets.SHADOW_INSTANCED_FRAGMENT
	// );
	// store.instanced_texture_shader = Render.Shader.make(
	// 	xx Assets.INSTANCED_TEXTURE_VERTEX, xx Assets.INSTANCED_TEXTURE_FRAGMENT
	// );
	// store.shadow_instanced_texture_shader = Render.Shader.make(
	// 	xx Assets.SHADOW_INSTANCED_TEXTURE_VERTEX, xx Assets.SHADOW_INSTANCED_TEXTURE_FRAGMENT
	// );

	// store.ice_texture = Render.Texture.make_from_image(Assets.ICE_TEXTURE);
	// store.coin_texture = Render.Texture.make_from_image(Assets.COIN_TEXTURE);
	// store.dirt_texture = Render.Texture.make_from_image(Assets.DIRT_TEXTURE);
	// store.grass_texture = Render.Texture.make_from_image(Assets.GRASS_TEXTURE);
	// store.slippy_ice_texture = Render.Texture.make_from_image(Assets.SLIPPY_ICE_TEXTURE);
	// store.mark_texture = Render.Texture.make_from_image(Assets.MARK_TEXTURE);
	// store.vehicle_colormap = Render.Texture.make_from_image(Assets.VEHICLE_COLORMAP_TEXTURE);
	// Render.set_clamp(store.mark_texture, .T);

	// // store.tile_geometry = Render.Geometry.make_square(
	// // 	.{ 0, 0, 0 }, .{ 1, 0, 0 },  .{ 1, 1, 0 },  .{ 0, 1, 0 }
	// // );
	// store.z_facing_unit_square_geometry = Render.Geometry.make_square(
	// 	.{ 0, 0, 0 }, .{ 1, 0, 0 },  .{ 1, 1, 0 },  .{ 0, 1, 0 }
	// );
	// store.tile_geometry = Render.Geometry.make_from_obj(Assets.TILE_OBJ);
	// store.flag_geometry = Render.Geometry.make_from_obj(Assets.FLAG_OBJ);
	// store.flag_down_geometry = Render.Geometry.make_from_obj(Assets.FLAG_DOWN_OBJ);
	// store.player_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_RACER_OBJ);
	// store.racer_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_RACER_OBJ);
	// store.suv_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_SUV_OBJ);
	// store.drag_racer_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_DRAG_RACER_OBJ);
	// store.vintage_racer_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_VINTAGE_RACER_OBJ);
	// store.monster_truck_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_MONSTER_TRUCK_OBJ);
	// store.speedster_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_SPEEDSTER_OBJ);
	// store.tombstone_geometry = Render.Geometry.make_from_obj(Assets.TOMBSTONE_OBJ);
	// store.coin_geometry = Render.Geometry.make_from_obj(Assets.COIN_OBJ);
	// store.skull_geometry = Render.Geometry.make_from_obj(Assets.SKULL_OBJ);
	// store.key_geometry = Render.Geometry.make_from_obj(Assets.KEY_OBJ);
	// store.mark_geometry = Render.Geometry.make_from_obj(Assets.MARK_OBJ);
	// store.gate_geometry = Render.Geometry.make_from_obj(Assets.GATE_OBJ);
	// store.gate_close_geometry = Render.Geometry.make_from_obj(Assets.GATE_CLOSE_OBJ);
	// store.gate_finish_geometry = Render.Geometry.make_from_obj(Assets.GATE_FINISH_OBJ);
	// store.gate_finish_close_geometry = Render.Geometry.make_from_obj(Assets.GATE_FINISH_CLOSE_OBJ);
	// store.shuriken_geometry = Render.Geometry.make_from_obj(Assets.SHURIKEN_OBJ);
	// store.spirit_geometry = Render.Geometry.make_from_obj(Assets.SPIRIT_OBJ);
	// store.terrain_tree_snow_a = Render.Geometry.make_from_obj(Assets.TERRAIN_TREE_SNOW_A);
	// store.terrain_tree_snow_b = Render.Geometry.make_from_obj(Assets.TERRAIN_TREE_SNOW_B);
	// store.terrain_tree_snow_c = Render.Geometry.make_from_obj(Assets.TERRAIN_TREE_SNOW_C);
	// store.terrain_snowman = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOWMAN);
	// store.terrain_snowman_hat = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOWMAN_HAT);
	// store.terrain_snow_flat = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOW_FLAT);
	// store.terrain_snow_flat_large = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOW_FLAT_LARGE);
	// store.terrain_snow_pile = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOW_PILE);
	// store.terrain_snowflake_a = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOWFLAKE_A);
	// store.terrain_snowflake_b = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOWFLAKE_B);
	// store.terrain_snowflake_c = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOWFLAKE_C);
	// store.rock_small = Render.Geometry.make_from_obj(Assets.ROCK_SMALL);
	// store.rock_medium = Render.Geometry.make_from_obj(Assets.ROCK_MEDIUM);
	// store.rock_large = Render.Geometry.make_from_obj(Assets.ROCK_LARGE);
	// store.skybox_geometry = Render.Geometry.make_from_obj(Assets.SKYBOX_OBJ);
	// store.indicator_outline_geometry = Render.Geometry.make_from_obj(Assets.INDICATOR_OUTLINE_OBJ);
	// store.indicator_stroke_geometry = Render.Geometry.make_from_obj(Assets.INDICATOR_STROKE_OBJ);
	// store.boat_row_geometry = Render.Geometry.make_from_obj(Assets.BOAT_ROW_OBJ);
	// store.boat_fishing_geometry = Render.Geometry.make_from_obj(Assets.BOAT_FISHING_OBJ);
	// store.taxi_geometry = Render.Geometry.make_from_obj(Assets.TAXI_OBJ);
	// store.police_geometry = Render.Geometry.make_from_obj(Assets.POLICE_OBJ);
	// store.ambulance_geometry = Render.Geometry.make_from_obj(Assets.AMBULANCE_OBJ);
	// store.spaceship_geometry = Render.Geometry.make_from_obj(Assets.SPACESHIP_OBJ);

	// store.number_0_geometry = Render.Geometry.make_from_obj(Assets.NUMBER_0_OBJ);
	// store.number_1_geometry = Render.Geometry.make_from_obj(Assets.NUMBER_1_OBJ);
	// store.number_2_geometry = Render.Geometry.make_from_obj(Assets.NUMBER_2_OBJ);
	// store.number_3_geometry = Render.Geometry.make_from_obj(Assets.NUMBER_3_OBJ);
	// store.number_4_geometry = Render.Geometry.make_from_obj(Assets.NUMBER_4_OBJ);
	// store.number_5_geometry = Render.Geometry.make_from_obj(Assets.NUMBER_5_OBJ);
	// store.number_6_geometry = Render.Geometry.make_from_obj(Assets.NUMBER_6_OBJ);
	// store.number_7_geometry = Render.Geometry.make_from_obj(Assets.NUMBER_7_OBJ);
	// store.number_8_geometry = Render.Geometry.make_from_obj(Assets.NUMBER_8_OBJ);
	// store.number_9_geometry = Render.Geometry.make_from_obj(Assets.NUMBER_9_OBJ);

	// store.robot_a0_geometry = Render.Geometry.make_from_obj(Assets.ROBOT_A0_OBJ);
	// store.robot_a1_geometry = Render.Geometry.make_from_obj(Assets.ROBOT_A1_OBJ);
	// store.robot_a2_geometry = Render.Geometry.make_from_obj(Assets.ROBOT_A2_OBJ);
	// store.robot_a3_geometry = Render.Geometry.make_from_obj(Assets.ROBOT_A3_OBJ);
	// store.robot_a4_geometry = Render.Geometry.make_from_obj(Assets.ROBOT_A4_OBJ);
	// store.robot_a5_geometry = Render.Geometry.make_from_obj(Assets.ROBOT_A5_OBJ);

	// store.unit_cylinder_geometry = Render.Geometry.make_from_obj(Assets.UNIT_CYLINDER_OBJ);
	// store.unit_sphere_geometry = Render.Geometry.make_from_obj(Assets.UNIT_SPHERE_OBJ);
}

#if Assets.RUNTIME {
	#import "File";
}

check_change :: (store: *Store, paths: [] string) {
	#if Assets.RUNTIME {

		// handle_shader :: (change: string, name: string, shader: *Render.Shader) #expand {
		// 	if ends_with(change, tprint("%.vert", name))
		// 	|| ends_with(change, tprint("%.frag", name))
		// 	{
		// 		print("Recompiling % shader\n", name);

		// 		vertex_code, ok := read_entire_file(
		// 			tprint("%/../assets/Shader/%.vert", #filepath, name),, temp
		// 		);
		// 		if ok {
		// 			fragment_code:, ok = read_entire_file(
		// 				tprint("%/../assets/Shader/%.frag", #filepath, name),, temp
		// 			);
		// 			if ok {
		// 				Render.release(shader);
		// 				shader.* = Render.Shader.make(vertex_code, fragment_code);
		// 			}
		// 		}
		// 	}
		// }

		handle_wshader :: (change: string, name: string, wshader: *WRender.WShader) #expand {
			if ends_with(change, tprint("%.wgsl", name)) {
				print("Recompiling % WShader\n", name);

				code, ok := read_entire_file(
					tprint("%/../assets/Shader/%.wgsl", #filepath, name),, temp
				);
				if ok {
					wshader.code = code;
					wshader.dirty = true;
				}
			}
		}

		for paths {
			// handle_shader(it, "tile", *store.tile_shader);
			// handle_shader(it, "instance", *store.instance_shader);
			// handle_shader(it, "plain", *store.model_shader);
			// handle_shader(it, "postpro", *store.postpro_shader);
			// handle_shader(it, "shadow", *store.shadow_shader);
			// handle_shader(it, "shadow_instanced", *store.shadow_instanced_shader);
			// handle_shader(it, "instance_texture", *store.instanced_texture_shader);
			// handle_shader(it, "shadow_instance_texture", *store.shadow_instanced_texture_shader);
			// handle_shader(it, "skybox", *store.skybox_shader);
			// handle_shader(it, "particles", *store.particle_shader);
		}
	}
}
