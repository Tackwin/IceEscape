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
	prop       :: V4f.{ 0 / 4.0, 0 / 4.0, 1 / 4.0, 1 / 4.0 };
	vehicle    :: V4f.{ 1 / 4.0, 0 / 4.0, 1 / 4.0, 1 / 4.0 };
	pirate     :: V4f.{ 0 / 4.0, 1 / 4.0, 1 / 4.0, 1 / 4.0 };
	conveyor   :: V4f.{ 1 / 4.0, 1 / 4.0, 1 / 4.0, 1 / 4.0 };
	car        :: V4f.{ 2 / 4.0, 0 / 4.0, 1 / 4.0, 1 / 4.0 };
	watercraft :: V4f.{ 2 / 4.0, 1 / 4.0, 1 / 4.0, 1 / 4.0 };
	down_arrow :: V4f.{ 3 / 4.0, 0 / 4.0, 1 / 4.0, 1 / 4.0 };
	safe_zone  :: V4f.{ 3 / 4.0, 1 / 4.0, 1 / 4.0, 1 / 4.0 };
}


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
	block_rock: WRender.Model;
	no_block_rock: WRender.Model;
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
	boat_sail_model: WRender.Model;
	boat_fishing_model: WRender.Model;
	taxi_model: WRender.Model;
	police_model: WRender.Model;
	tractor_model: WRender.Model;
	ambulance_model: WRender.Model;
	spaceship_model: WRender.Model;
	tombstone_model: WRender.Model;
	skull_model: WRender.Model;
	pirateship_model: WRender.Model;
	coin_model: WRender.Model;
	key_model: WRender.Model;
	bomb_model: WRender.Model;
	crate_model: WRender.Model;
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
	drone_model: WRender.Model;
	drone_blade_model: WRender.Model;
	trap_spike_model: WRender.Model;
	end_hook_model: WRender.Model;
	pressbutton_pressed: WRender.Model;
	pressbutton_unpressed: WRender.Model;
	pressbutton_pressed_radio: WRender.Model;
	pressbutton_unpressed_radio: WRender.Model;

	antiair_camion_model: WRender.Model;
	antiair_canon_model: WRender.Model;
	missile_model: WRender.Model;

	robot_a0_model: WRender.Model;
	robot_a1_model: WRender.Model;
	robot_a2_model: WRender.Model;
	robot_a3_model: WRender.Model;
	robot_a4_model: WRender.Model;
	robot_a5_model: WRender.Model;

	present_a_model: WRender.Model;
	present_b_model: WRender.Model;

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

	jukebox_model: WRender.Model;

	unit_cylinder_model: WRender.Model;
	unit_sphere_model: WRender.Model;
	zone_wall_model: WRender.Model;
	indicator_outline_model: WRender.Model;
	indicator_stroke_model: WRender.Model;

	turn_table_turn_model: WRender.Model;
	turn_table_base_model: WRender.Model;

	colormaps: WRender.WTexture;
	terrain_tile_albedo: WRender.WTexture;
	terrain_tile_normal: WRender.WTexture;
	particle_texture: WRender.WTexture;
	ui_atlas: WRender.WTexture;
	font_atlas: WRender.WTexture;

	loser_mp3: Platform.Audio;
	click_wav: Platform.Audio;
	snowflakes_and_lights_mp3: Platform.Audio;

	footstep_snow_0_mp3: Platform.Audio;
	footstep_snow_1_mp3: Platform.Audio;
	footstep_snow_2_mp3: Platform.Audio;
	footstep_snow_3_mp3: Platform.Audio;
	footstep_snow_4_mp3: Platform.Audio;

	footstep_ice_0_mp3: Platform.Audio;
	footstep_ice_1_mp3: Platform.Audio;
	footstep_ice_2_mp3: Platform.Audio;
	footstep_ice_3_mp3: Platform.Audio;
	footstep_ice_4_mp3: Platform.Audio;

	horn_car_0_mp3: Platform.Audio;
	horn_car_1_mp3: Platform.Audio;
	horn_car_2_mp3: Platform.Audio;
	horn_car_3_mp3: Platform.Audio;
	horn_car_4_mp3: Platform.Audio;
	horn_car_5_mp3: Platform.Audio;
	horn_car_6_mp3: Platform.Audio;
	horn_car_7_mp3: Platform.Audio;
	horn_car_8_mp3: Platform.Audio;

	boat_sailing_0_wav: Platform.Audio;
	boat_sailing_1_wav: Platform.Audio;
	boat_sailing_2_wav: Platform.Audio;

	drone_buzzing_0_wav: Platform.Audio;

	note_wav: Platform.Audio;

	explosion_0_mp3: Platform.Audio;
	explosion_1_mp3: Platform.Audio;
	explosion_2_mp3: Platform.Audio;
	explosion_3_mp3: Platform.Audio;
	explosion_4_mp3: Platform.Audio;
	explosion_5_mp3: Platform.Audio;
	explosion_6_mp3: Platform.Audio;
	explosion_7_mp3: Platform.Audio;
	explosion_8_mp3: Platform.Audio;

	drift_0_mp3: Platform.Audio;
	drift_1_mp3: Platform.Audio;

	checkpoint_ok_mp3: Platform.Audio;

	res_mp3: Platform.Audio;
	coin_launch_mp3: Platform.Audio;

	point_up_mp3: Platform.Audio;

	verdana_atlas: WRender.WTexture;
	verdana: Platform.Font;
}

get_horn_car :: (store: Store, idx: int) -> *Platform.Audio {
	if idx == 0 {
		return *store.horn_car_0_mp3;
	} else if idx == 1 {
		return *store.horn_car_1_mp3;
	} else if idx == 2 {
		return *store.horn_car_2_mp3;
	} else if idx == 3 {
		return *store.horn_car_3_mp3;
	} else if idx == 4 {
		return *store.horn_car_4_mp3;
	} else if idx == 5 {
		return *store.horn_car_5_mp3;
	} else if idx == 6 {
		return *store.horn_car_6_mp3;
	} else if idx == 7 {
		return *store.horn_car_7_mp3;
	} else if idx == 8 {
		return *store.horn_car_8_mp3;
	}
	return null;
}

get_boat_sailing :: (store: Store, idx: int) -> *Platform.Audio {
	if idx == 0 {
		return *store.boat_sailing_0_wav;
	} else if idx == 1 {
		return *store.boat_sailing_1_wav;
	} else if idx == 2 {
		return *store.boat_sailing_2_wav;
	}
	return null;
}

get_drone_buzzing :: (store: Store, idx: int) -> *Platform.Audio {
	if idx == 0 {
		return *store.drone_buzzing_0_wav;
	}
	return null;
}

get_explosion_sound :: (store: Store, idx: int) -> *Platform.Audio {
	if idx == 0 {
		return *store.explosion_0_mp3;
	} else if idx == 1 {
		return *store.explosion_1_mp3;
	} else if idx == 2 {
		return *store.explosion_2_mp3;
	} else if idx == 3 {
		return *store.explosion_3_mp3;
	} else if idx == 4 {
		return *store.explosion_4_mp3;
	} else if idx == 5 {
		return *store.explosion_5_mp3;
	} else if idx == 6 {
		return *store.explosion_6_mp3;
	} else if idx == 7 {
		return *store.explosion_7_mp3;
	} else if idx == 8 {
		return *store.explosion_8_mp3;
	}
	return null;
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

get_rect :: (id: Scene.Model_Id) -> V4f {
	if #complete id == {
		case .Racer; return Colormaps_Rect.vehicle;
		case .SUV; return Colormaps_Rect.vehicle;
		case .Tile; return .{ 0, 0, 1, 1 };
		case .Speedster; return Colormaps_Rect.vehicle;
		case .Tombstone; return Colormaps_Rect.vehicle;
		case .Skull; return Colormaps_Rect.pirate;
		case .Coin; return Colormaps_Rect.vehicle;
		case .Key; return Colormaps_Rect.vehicle;
		case .Mark; return .{ 0, 0, 1, 1 };
		case .Gate; return Colormaps_Rect.vehicle;
		case .Gate_Close; return Colormaps_Rect.vehicle;
		case .Shuriken; return Colormaps_Rect.vehicle;
		case .Spirit; return Colormaps_Rect.vehicle;
		case .Drag_Racer; return Colormaps_Rect.vehicle;
		case .Monster_Truck; return Colormaps_Rect.vehicle;
		case .Vintage_Racer; return Colormaps_Rect.vehicle;
		case .Boat_Row; return Colormaps_Rect.watercraft;
		case .Boat_Fishing; return Colormaps_Rect.watercraft;
		case .Taxi; return Colormaps_Rect.car;
		case .Police; return Colormaps_Rect.car;
		case .Ambulance; return Colormaps_Rect.car;
		case .Spaceship; return Colormaps_Rect.vehicle;
		case .Boat_Sail; return Colormaps_Rect.watercraft;
		case .Tractor; return Colormaps_Rect.car;
	}

	return Colormaps_Rect.vehicle;
}
get_model :: (store: Store, id: Scene.Model_Id) -> *WRender.Model {
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
		case .Boat_Sail; return *store.boat_sail_model;
		case .Tractor; return *store.tractor_model;
	}
	return null;
}
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
		case .Funny_Ice;
			rect = V4f.{ 1.0, 2.0, 1.0, 1.0 } / 4.0;
	}
	rect.x += 0.5 / 512.0;
	rect.y += 0.5 / 512.0;
	rect.z -= 1.0 / 512.0;
	rect.w -= 1.0 / 512.0;
	return rect;
}
get_tile_idx :: (id: Scene.Tile.Kind) -> int {
	if #complete id == {
		case .None;
			return 0;
		case .Ice;
			return 13;
		case .Slippy_Ice;
			return 8;
		case .Grass;
			return 12;
		case .Dirt;
			return 5;
		case .Funny_Ice;
			return 9;
	}
}

get_footstep_snow_sound :: (store: Store, index: int) -> *Platform.Audio {
	if index == 0 {
		return *store.footstep_snow_0_mp3;
	} else if index == 1 {
		return *store.footstep_snow_1_mp3;
	} else if index == 2 {
		return *store.footstep_snow_2_mp3;
	} else if index == 3 {
		return *store.footstep_snow_3_mp3;
	} else if index == 4 {
		return *store.footstep_snow_4_mp3;
	}
	return null;
}

get_footstep_ice_sound :: (store: Store, index: int) -> *Platform.Audio {
	if index == 0 {
		return *store.footstep_ice_0_mp3;
	} else if index == 1 {
		return *store.footstep_ice_1_mp3;
	} else if index == 2 {
		return *store.footstep_ice_2_mp3;
	} else if index == 3 {
		return *store.footstep_ice_3_mp3;
	} else if index == 4 {
		return *store.footstep_ice_4_mp3;
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

init_store :: (platform: Platform.Platform, store: *Store) {
	if Assets.RUNTIME {
		Assets.load_everything(platform);
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
	store.block_rock = WRender.Model.make_from_obj(Assets.BLOCK_ROCK_OBJ, "block_rock");
	store.no_block_rock = WRender.Model.make_from_obj(Assets.NO_BLOCK_ROCK_OBJ, "no_block_rock");
	store.rock_small = WRender.Model.make_from_obj(Assets.ROCK_SMALL, "rock_small.obj");
	store.rock_medium = WRender.Model.make_from_obj(Assets.ROCK_MEDIUM, "rock_medium.obj");
	store.rock_large = WRender.Model.make_from_obj(Assets.ROCK_LARGE, "rock_large.obj");
	store.tile_model = WRender.Model.make_from_obj(Assets.TILE_OBJ, "tile.obj");

	prop_colormap_png := Assets.load_qoi(Assets.COLORMAPS_PNG,, temp);
	store.colormaps = WRender.WTexture.make_from_image(prop_colormap_png, "colormaps");

	terrain_tile_albedo_png := Assets.load_qoi(Assets.TERRAIN_TILE_ALBEDO_PNG,, temp);
	store.terrain_tile_albedo =
		WRender.WTexture.make_from_image(terrain_tile_albedo_png, "terrain_tile_albedo", .{ 4, 4 });

	terrain_tile_normal_png := Assets.load_qoi(Assets.TERRAIN_TILE_NORMAL_PNG,, temp);
	store.terrain_tile_normal =
		WRender.WTexture.make_from_image(terrain_tile_normal_png, "terrain_tile_normal", .{ 4, 4 });
		
	particle_texture_png := Assets.load_qoi(Assets.PARTICLE_TEXTURE_PNG,, temp);
	store.particle_texture =
		WRender.WTexture.make_from_image(particle_texture_png, "particle_texture");

	ui_atlas_png := Assets.load_qoi(Assets.ui_atlas_png,, temp);
	store.ui_atlas = WRender.WTexture.make_from_image(ui_atlas_png, "ui_atlas");

	verdana_atlas_png := Assets.load_qoi(Assets.verdana_png,, temp);
	store.verdana_atlas = WRender.WTexture.make_from_image(verdana_atlas_png, "verdana_atlas");
	store.verdana = Assets.load_font(xx Assets.verdana_csv);

	store.racer_model = WRender.Model.make_from_obj(Assets.VEHICLE_RACER_OBJ, "racer");
	store.suv_model = WRender.Model.make_from_obj(Assets.VEHICLE_SUV_OBJ, "suv");
	store.speedster_model = WRender.Model.make_from_obj(Assets.VEHICLE_SPEEDSTER_OBJ, "speedster");
	store.drag_racer_model = WRender.Model.make_from_obj(Assets.VEHICLE_DRAG_RACER_OBJ, "drag_racer");
	store.monster_truck_model = WRender.Model.make_from_obj(Assets.VEHICLE_MONSTER_TRUCK_OBJ, "monster_truck");
	store.vintage_racer_model = WRender.Model.make_from_obj(Assets.VEHICLE_VINTAGE_RACER_OBJ, "vintage_racer");
	store.boat_row_model = WRender.Model.make_from_obj(Assets.BOAT_ROW_OBJ, "boat_row");
	store.boat_sail_model = WRender.Model.make_from_obj(Assets.BOAT_SAIL_OBJ, "boat_sail");
	store.boat_fishing_model = WRender.Model.make_from_obj(Assets.BOAT_FISHING_OBJ, "boat_fishing");
	store.taxi_model = WRender.Model.make_from_obj(Assets.TAXI_OBJ, "taxi");
	store.police_model = WRender.Model.make_from_obj(Assets.POLICE_OBJ, "police");
	store.tractor_model = WRender.Model.make_from_obj(Assets.TRACTOR_OBJ, "tractor");
	store.ambulance_model = WRender.Model.make_from_obj(Assets.AMBULANCE_OBJ, "ambulance");
	store.spaceship_model = WRender.Model.make_from_obj(Assets.SPACESHIP_OBJ, "spaceship");
	store.tombstone_model = WRender.Model.make_from_obj(Assets.TOMBSTONE_OBJ, "tombstone");
	store.skull_model = WRender.Model.make_from_obj(Assets.SKULL_OBJ, "skull");
	store.end_hook_model = WRender.Model.make_from_obj(Assets.END_HOOK_OBJ, "end_hook");
	store.pressbutton_pressed = WRender.Model.make_from_obj(Assets.PRESSBUTTON_PRESSED_OBJ, "pressbutton_pressed");
	store.pressbutton_unpressed = WRender.Model.make_from_obj(Assets.PRESSBUTTON_UNPRESSED_OBJ, "pressbutton_unpressed");
	store.pressbutton_pressed_radio = WRender.Model.make_from_obj(Assets.PRESSBUTTON_PRESSED_RADIO_OBJ, "pressbutton_pressed_radio");
	store.pressbutton_unpressed_radio = WRender.Model.make_from_obj(Assets.PRESSBUTTON_UNPRESSED_RADIO_OBJ, "pressbutton_unpressed_radio");
	store.pirateship_model = WRender.Model.make_from_obj(Assets.PIRATE_SHIP_OBJ, "pirateship");
	store.coin_model = WRender.Model.make_from_obj(Assets.COIN_OBJ, "coin");
	store.key_model = WRender.Model.make_from_obj(Assets.KEY_OBJ, "key");
	store.bomb_model = WRender.Model.make_from_obj(Assets.BOMB_OBJ, "bomb");
	store.crate_model = WRender.Model.make_from_obj(Assets.CRATE_OBJ, "crate");
	store.mark_model = WRender.Model.make_from_obj(Assets.MARK_OBJ, "mark");
	store.gate_model = WRender.Model.make_from_obj(Assets.GATE_OBJ, "gate");
	store.gate_close_model = WRender.Model.make_from_obj(Assets.GATE_CLOSE_OBJ, "gate_close");
	store.spirit_model = WRender.Model.make_from_obj(Assets.SPIRIT_OBJ, "spirit");
	store.shuriken_model = WRender.Model.make_from_obj(Assets.SHURIKEN_OBJ, "shuriken");
	store.gate_finish_model = WRender.Model.make_from_obj(Assets.GATE_FINISH_OBJ, "gate_finish");
	store.gate_finish_close_model = WRender.Model.make_from_obj(Assets.GATE_FINISH_CLOSE_OBJ, "gate_finish_close");
	store.flag_model = WRender.Model.make_from_obj(Assets.FLAG_OBJ, "flag");
	store.flag_down_model = WRender.Model.make_from_obj(Assets.FLAG_DOWN_OBJ, "flag_down");
	store.trophy_model = WRender.Model.make_from_obj(Assets.TROPHY_OBJ, "trophy");
	store.drone_model = WRender.Model.make_from_obj(Assets.DRONE_OBJ, "drone");
	store.drone_blade_model = WRender.Model.make_from_obj(Assets.DRONE_BLADE_OBJ, "drone_blade");
	store.trap_spike_model = WRender.Model.make_from_obj(Assets.TRAP_SPIKE_OBJ, "trap_spike");
	store.antiair_camion_model = WRender.Model.make_from_obj(Assets.ANTIAIR_CAMION_OBJ, "antiair_camion");
	store.antiair_canon_model = WRender.Model.make_from_obj(Assets.ANTIAIR_CANON_OBJ, "antiair_canon");
	store.missile_model = WRender.Model.make_from_obj(Assets.MISSILE_OBJ, "missile");
	store.robot_a0_model = WRender.Model.make_from_obj(Assets.ROBOT_A0_OBJ, "robot_a0");
	store.robot_a1_model = WRender.Model.make_from_obj(Assets.ROBOT_A1_OBJ, "robot_a1");
	store.robot_a2_model = WRender.Model.make_from_obj(Assets.ROBOT_A2_OBJ, "robot_a2");
	store.robot_a3_model = WRender.Model.make_from_obj(Assets.ROBOT_A3_OBJ, "robot_a3");
	store.robot_a4_model = WRender.Model.make_from_obj(Assets.ROBOT_A4_OBJ, "robot_a4");
	store.robot_a5_model = WRender.Model.make_from_obj(Assets.ROBOT_A5_OBJ, "robot_a5");
	store.number_0_model = WRender.Model.make_from_obj(Assets.NUMBER_0_OBJ, "number_0");
	store.number_1_model = WRender.Model.make_from_obj(Assets.NUMBER_1_OBJ, "number_1");
	store.number_2_model = WRender.Model.make_from_obj(Assets.NUMBER_2_OBJ, "number_2");
	store.number_3_model = WRender.Model.make_from_obj(Assets.NUMBER_3_OBJ, "number_3");
	store.number_4_model = WRender.Model.make_from_obj(Assets.NUMBER_4_OBJ, "number_4");
	store.number_5_model = WRender.Model.make_from_obj(Assets.NUMBER_5_OBJ, "number_5");
	store.number_6_model = WRender.Model.make_from_obj(Assets.NUMBER_6_OBJ, "number_6");
	store.number_7_model = WRender.Model.make_from_obj(Assets.NUMBER_7_OBJ, "number_7");
	store.number_8_model = WRender.Model.make_from_obj(Assets.NUMBER_8_OBJ, "number_8");
	store.number_9_model = WRender.Model.make_from_obj(Assets.NUMBER_9_OBJ, "number_9");
	store.present_a_model = WRender.Model.make_from_obj(Assets.PRESENT_A_OBJ, "present_a");
	store.present_b_model = WRender.Model.make_from_obj(Assets.PRESENT_B_OBJ, "present_b");
	store.jukebox_model = WRender.Model.make_from_obj(Assets.JUKEBOX_OBJ, "juukebox");

	store.unit_cylinder_model = WRender.Model.make_from_obj(Assets.UNIT_CYLINDER_OBJ, "unit_cylinder");
	store.unit_sphere_model = WRender.Model.make_from_obj(Assets.UNIT_SPHERE_OBJ, "unit_sphere");
	store.zone_wall_model = WRender.Model.make_from_obj(Assets.ZONE_WALL_OBJ, "zone_wall");

	store.indicator_outline_model = WRender.Model.make_from_obj(Assets.INDICATOR_OUTLINE_OBJ, "indicator_outline");
	store.indicator_stroke_model = WRender.Model.make_from_obj(Assets.INDICATOR_STROKE_OBJ, "indicator_stroke");
	store.snowflakes_and_lights_mp3 = platform.load_audio(
		xx Assets.SNOWFLAKES_AND_LIGHTS_MP3, true
	);

	store.turn_table_turn_model = WRender.Model.make_from_obj(
		Assets.TURN_TABLE_TURN_OBJ, "turn_table_turn"
	);
	store.turn_table_base_model = WRender.Model.make_from_obj(
		Assets.TURN_TABLE_BASE_OBJ, "turn_table_base"
	);

	store.footstep_snow_0_mp3 = platform.load_audio(xx Assets.FOOTSTEP_SNOW_0_MP3, true);
	store.footstep_snow_1_mp3 = platform.load_audio(xx Assets.FOOTSTEP_SNOW_1_MP3, true);
	store.footstep_snow_2_mp3 = platform.load_audio(xx Assets.FOOTSTEP_SNOW_2_MP3, true);
	store.footstep_snow_3_mp3 = platform.load_audio(xx Assets.FOOTSTEP_SNOW_3_MP3, true);
	store.footstep_snow_4_mp3 = platform.load_audio(xx Assets.FOOTSTEP_SNOW_4_MP3, true);

	store.footstep_ice_0_mp3 = platform.load_audio(xx Assets.FOOTSTEP_ICE_0_MP3, true);
	store.footstep_ice_1_mp3 = platform.load_audio(xx Assets.FOOTSTEP_ICE_1_MP3, true);
	store.footstep_ice_2_mp3 = platform.load_audio(xx Assets.FOOTSTEP_ICE_2_MP3, true);
	store.footstep_ice_3_mp3 = platform.load_audio(xx Assets.FOOTSTEP_ICE_3_MP3, true);
	store.footstep_ice_4_mp3 = platform.load_audio(xx Assets.FOOTSTEP_ICE_4_MP3, true);

	store.horn_car_0_mp3 = platform.load_audio(xx Assets.HORN_CAR_0_MP3, true);
	store.horn_car_1_mp3 = platform.load_audio(xx Assets.HORN_CAR_1_MP3, true);
	store.horn_car_2_mp3 = platform.load_audio(xx Assets.HORN_CAR_2_MP3, true);
	store.horn_car_3_mp3 = platform.load_audio(xx Assets.HORN_CAR_3_MP3, true);
	store.horn_car_4_mp3 = platform.load_audio(xx Assets.HORN_CAR_4_MP3, true);
	store.horn_car_5_mp3 = platform.load_audio(xx Assets.HORN_CAR_5_MP3, true);
	store.horn_car_6_mp3 = platform.load_audio(xx Assets.HORN_CAR_6_MP3, true);
	store.horn_car_7_mp3 = platform.load_audio(xx Assets.HORN_CAR_7_MP3, true);
	store.horn_car_8_mp3 = platform.load_audio(xx Assets.HORN_CAR_8_MP3, true);

	store.boat_sailing_0_wav = platform.load_audio(xx Assets.BOAT_SAILING_0_WAV, true);
	store.boat_sailing_1_wav = platform.load_audio(xx Assets.BOAT_SAILING_1_WAV, false);
	store.boat_sailing_2_wav = platform.load_audio(xx Assets.BOAT_SAILING_2_WAV, false);

	store.drone_buzzing_0_wav = platform.load_audio(xx Assets.DRONE_BUZZING_0_WAV, true);

	store.note_wav = platform.load_audio(xx Assets.NOTE_WAV, true);

	store.explosion_0_mp3 = platform.load_audio(xx Assets.EXPLOSION_0_MP3, false);
	store.explosion_1_mp3 = platform.load_audio(xx Assets.EXPLOSION_1_MP3, false);
	store.explosion_2_mp3 = platform.load_audio(xx Assets.EXPLOSION_2_MP3, false);
	store.explosion_3_mp3 = platform.load_audio(xx Assets.EXPLOSION_3_MP3, false);
	store.explosion_4_mp3 = platform.load_audio(xx Assets.EXPLOSION_4_MP3, false);
	store.explosion_5_mp3 = platform.load_audio(xx Assets.EXPLOSION_5_MP3, false);
	store.explosion_6_mp3 = platform.load_audio(xx Assets.EXPLOSION_6_MP3, false);
	store.explosion_7_mp3 = platform.load_audio(xx Assets.EXPLOSION_7_MP3, false);
	store.explosion_8_mp3 = platform.load_audio(xx Assets.EXPLOSION_8_MP3, false);

	store.drift_0_mp3 = platform.load_audio(xx Assets.DRIFT_0_MP3, true);
	store.drift_1_mp3 = platform.load_audio(xx Assets.DRIFT_1_MP3, true);

	store.checkpoint_ok_mp3 = platform.load_audio(xx Assets.CHECKPOINT_OK_MP3, false);
	store.res_mp3 = platform.load_audio(xx Assets.RES_MP3, false);
	store.coin_launch_mp3 = platform.load_audio(xx Assets.COIN_LAUNCH_MP3, false);

	store.loser_mp3 = platform.load_audio(xx Assets.LOSER_MP3, true);

	store.point_up_mp3 = platform.load_audio(xx Assets.POINT_UP_MP3, false);
}

#if Assets.RUNTIME {
	#import "File";
}

