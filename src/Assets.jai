#import "Basic";
#import "String";
#import "Compiler";
#import "Platform";

#scope_export

RUNTIME :: true && OS != .WASM;

embed_data :: ($name: string, $path: string, $root: string) -> string {
	#if RUNTIME {
format_runtime_text :: #string FORMAT
%: [] u8;
%_PROC :: (platform: Platform) {
	full_path := "%/../assets/%";

	file_size := platform.read_entire_file(full_path, .[]);
	file := NewArray(file_size, u8,, platform.allocator);

	file.count = platform.read_entire_file(full_path, file);
	if file.count > 0 {
		% = xx file;
	} else {
		print("Couldn't load %\n");
	}
}
FORMAT;
		return sprint(format_runtime_text, name, name, root, path, name, name);
	}


format_text :: #string FORMAT
% ::  #run,host -> []u8 {
	#import "Compiler";
	#import "Basic";
	#import "File";

	get_data :: (path: string) -> [] u8 {
		CT_File :: #import "File";

		full_path := tprint("%/../assets/%", "%", path);
		file, ok := CT_File.read_entire_file(full_path);
		if !ok {
			print("Failed to load % (%)\n", path, full_path);
			return .[];
		}

		return xx file;
	}

	return add_global_data(get_data("%"), .READ_ONLY);
};
FORMAT;

	return sprint(format_text, name, "%", "%", root, "%", "%", path);
}

#insert #run embed_data("SKYBOX_VERTEX", "Shader/skybox.vert", #filepath);
#insert #run embed_data("SKYBOX_FRAGMENT", "Shader/skybox.frag", #filepath);
#insert #run embed_data("PLAIN_VERTEX", "Shader/plain.vert", #filepath);
#insert #run embed_data("INSTANCE_VERTEX", "Shader/instance.vert", #filepath);
#insert #run embed_data("INSTANCE_FRAGMENT", "Shader/instance.frag", #filepath);
#insert #run embed_data("TILE_VERTEX", "Shader/tile.vert", #filepath);
#insert #run embed_data("TILE_FRAGMENT", "Shader/tile.frag", #filepath);
#insert #run embed_data("QUAD_TEXTURE_VERTEX", "Shader/quad_texture.vert", #filepath);
#insert #run embed_data("QUAD_TEXTURE_FRAGMENT", "Shader/quad_texture.frag", #filepath);
#insert #run embed_data("POSTPROCESS_VERTEX", "Shader/postpro.vert", #filepath);
#insert #run embed_data("POSTPROCESS_FRAGMENT", "Shader/postpro.frag", #filepath);
#insert #run embed_data("SHADOW_VERTEX", "Shader/shadow.vert", #filepath);
#insert #run embed_data("SHADOW_FRAGMENT", "Shader/shadow.frag", #filepath);
#insert #run embed_data("SHADOW_INSTANCED_VERTEX", "Shader/shadow_instanced.vert", #filepath);
#insert #run embed_data("SHADOW_INSTANCED_FRAGMENT", "Shader/shadow_instanced.frag", #filepath);
#insert #run embed_data("INSTANCED_TEXTURE_VERTEX", "Shader/instance_texture.vert", #filepath);
#insert #run embed_data("INSTANCED_TEXTURE_FRAGMENT", "Shader/instance_texture.frag", #filepath);
#insert #run embed_data(
	"SHADOW_INSTANCED_TEXTURE_VERTEX", "Shader/instance_texture.vert", #filepath
);
#insert #run embed_data(
	"SHADOW_INSTANCED_TEXTURE_FRAGMENT", "Shader/instance_texture.frag", #filepath
);
#insert #run embed_data("PARTICLE_VERTEX", "Shader/particles.vert", #filepath);
#insert #run embed_data("PARTICLE_FRAGMENT", "Shader/particles.frag", #filepath);

#insert #run embed_data("SNOWFLAKES_AND_LIGHTS_MP3", "Sound/Snowflakes and Lights.mp3", #filepath);
#insert #run embed_data("tile_cliff_albedo_png", "Tile/cliff_albedo.png", #filepath);
#insert #run embed_data("tile_cliff_normal_png", "Tile/cliff_normal.png", #filepath);
#insert #run embed_data("tile_cliff_height_png", "Tile/cliff_height.png", #filepath);
#insert #run embed_data("tile_snow_albedo_png", "Tile/snow_albedo.png", #filepath);
#insert #run embed_data("tile_snow_normal_png", "Tile/snow_normal.png", #filepath);
#insert #run embed_data("tile_snow_height_png", "Tile/snow_height.png", #filepath);
#insert #run embed_data("tile_grass_albedo_png", "Tile/grass_albedo.png", #filepath);
#insert #run embed_data("tile_grass_normal_png", "Tile/grass_normal.png", #filepath);
#insert #run embed_data("tile_grass_height_png", "Tile/grass_height.png", #filepath);
#insert #run embed_data("tile_slippy_albedo_png", "Tile/slippy_albedo.png", #filepath);
#insert #run embed_data("tile_slippy_normal_png", "Tile/slippy_normal.png", #filepath);
#insert #run embed_data("tile_slippy_height_png", "Tile/slippy_height.png", #filepath);
#insert #run embed_data("tile_atlas_png", "Tile/atlas.png", #filepath);
#insert #run embed_data("ui_atlas_png", "UI/ui_atlas.png", #filepath);
#insert #run embed_data("ztotez_atlas_png", "ZTOtez-Regular.png", #filepath);

#insert #run embed_data("VEHICLE_RACER_OBJ", "vehicle-racer.obj", #filepath);
#insert #run embed_data("VEHICLE_SUV_OBJ", "vehicle-suv.obj", #filepath);
#insert #run embed_data("VEHICLE_SPEEDSTER_OBJ", "vehicle-speedster.obj", #filepath);
#insert #run embed_data("VEHICLE_MONSTER_TRUCK_OBJ", "vehicle-monster-truck.obj", #filepath);
#insert #run embed_data("VEHICLE_VINTAGE_RACER_OBJ", "vehicle-vintage-racer.obj", #filepath);
#insert #run embed_data("VEHICLE_DRAG_RACER_OBJ", "vehicle-drag-racer.obj", #filepath);
#insert #run embed_data("BOAT_SAIL_OBJ", "boat_sail.obj", #filepath);
#insert #run embed_data("BOAT_ROW_OBJ", "boat_row.obj", #filepath);
#insert #run embed_data("BOAT_FISHING_OBJ", "boat_fishing.obj", #filepath);
#insert #run embed_data("TAXI_OBJ", "taxi.obj", #filepath);
#insert #run embed_data("POLICE_OBJ", "police.obj", #filepath);
#insert #run embed_data("TRACTOR_OBJ", "tractor.obj", #filepath);
#insert #run embed_data("PIRATE_SHIP_OBJ", "pirate_ship.obj", #filepath);
#insert #run embed_data("AMBULANCE_OBJ", "ambulance.obj", #filepath);
#insert #run embed_data("SPACESHIP_OBJ", "spaceship.obj", #filepath);
#insert #run embed_data("ANTIAIR_CAMION_OBJ", "antiair_camion.obj", #filepath);
#insert #run embed_data("ANTIAIR_CANON_OBJ", "antiair_canon.obj", #filepath);
#insert #run embed_data("MISSILE_OBJ", "missile.obj", #filepath);
#insert #run embed_data("DRONE_OBJ", "drone.obj", #filepath);
#insert #run embed_data("DRONE_BLADE_OBJ", "drone_blade.obj", #filepath);
#insert #run embed_data("TRAP_SPIKE_OBJ", "trap_spike.obj", #filepath);

#insert #run embed_data("TROPHY_OBJ", "trophy.obj", #filepath);
#insert #run embed_data("JUKEBOX_OBJ", "jukebox.obj", #filepath);

#insert #run embed_data("NUMBER_0_OBJ", "number_0.obj", #filepath);
#insert #run embed_data("NUMBER_1_OBJ", "number_1.obj", #filepath);
#insert #run embed_data("NUMBER_2_OBJ", "number_2.obj", #filepath);
#insert #run embed_data("NUMBER_3_OBJ", "number_3.obj", #filepath);
#insert #run embed_data("NUMBER_4_OBJ", "number_4.obj", #filepath);
#insert #run embed_data("NUMBER_5_OBJ", "number_5.obj", #filepath);
#insert #run embed_data("NUMBER_6_OBJ", "number_6.obj", #filepath);
#insert #run embed_data("NUMBER_7_OBJ", "number_7.obj", #filepath);
#insert #run embed_data("NUMBER_8_OBJ", "number_8.obj", #filepath);
#insert #run embed_data("NUMBER_9_OBJ", "number_9.obj", #filepath);

#insert #run embed_data("PARTICLE_TEXTURE_PNG", "particle_texture.png", #filepath);

#insert #run embed_data("FLAG_OBJ", "flag.obj", #filepath);
#insert #run embed_data("FLAG_DOWN_OBJ", "flag_down.obj", #filepath);

#insert #run embed_data("CLICK_WAV", "click.wav", #filepath);

#insert #run embed_data("FOOTSTEP_SNOW_0_MP3", "Sound/footstep_snow_000.mp3", #filepath);
#insert #run embed_data("FOOTSTEP_SNOW_1_MP3", "Sound/footstep_snow_001.mp3", #filepath);
#insert #run embed_data("FOOTSTEP_SNOW_2_MP3", "Sound/footstep_snow_002.mp3", #filepath);
#insert #run embed_data("FOOTSTEP_SNOW_3_MP3", "Sound/footstep_snow_003.mp3", #filepath);
#insert #run embed_data("FOOTSTEP_SNOW_4_MP3", "Sound/footstep_snow_004.mp3", #filepath);

#insert #run embed_data("FOOTSTEP_ICE_0_MP3", "Sound/impactGlass_medium_000.mp3", #filepath);
#insert #run embed_data("FOOTSTEP_ICE_1_MP3", "Sound/impactGlass_medium_001.mp3", #filepath);
#insert #run embed_data("FOOTSTEP_ICE_2_MP3", "Sound/impactGlass_medium_002.mp3", #filepath);
#insert #run embed_data("FOOTSTEP_ICE_3_MP3", "Sound/impactGlass_medium_003.mp3", #filepath);
#insert #run embed_data("FOOTSTEP_ICE_4_MP3", "Sound/impactGlass_medium_004.mp3", #filepath);

#insert #run embed_data("BOAT_SAILING_0_WAV", "Sound/boat_sailing0.wav", #filepath);
#insert #run embed_data("BOAT_SAILING_1_WAV", "Sound/boat_sailing1.wav", #filepath);
#insert #run embed_data("BOAT_SAILING_2_WAV", "Sound/boat_sailing2.wav", #filepath);

#insert #run embed_data("DRONE_BUZZING_0_WAV", "Sound/drone_buzzing0.wav", #filepath);

#insert #run embed_data("EXPLOSION_0_MP3", "Sound/explosion0.mp3", #filepath);
#insert #run embed_data("EXPLOSION_1_MP3", "Sound/explosion1.mp3", #filepath);
#insert #run embed_data("EXPLOSION_2_MP3", "Sound/explosion2.mp3", #filepath);
#insert #run embed_data("EXPLOSION_3_MP3", "Sound/explosion3.mp3", #filepath);
#insert #run embed_data("EXPLOSION_4_MP3", "Sound/explosion4.mp3", #filepath);
#insert #run embed_data("EXPLOSION_5_MP3", "Sound/explosion5.mp3", #filepath);
#insert #run embed_data("EXPLOSION_6_MP3", "Sound/explosion6.mp3", #filepath);
#insert #run embed_data("EXPLOSION_7_MP3", "Sound/explosion7.mp3", #filepath);
#insert #run embed_data("EXPLOSION_8_MP3", "Sound/explosion8.mp3", #filepath);
#insert #run embed_data("POINT_UP_MP3", "Sound/point_up.mp3", #filepath);

#insert #run embed_data("LOSER_MP3", "Sound/loser.mp3", #filepath);

#insert #run embed_data("TILE_OBJ", "tile.obj", #filepath);
#insert #run embed_data("CAR_OBJ", "car.obj", #filepath);
#insert #run embed_data("TOMBSTONE_OBJ", "tombstone.obj", #filepath);
#insert #run embed_data("SKULL_OBJ", "skull.obj", #filepath);
#insert #run embed_data("COIN_OBJ", "coin.obj", #filepath);
#insert #run embed_data("SPIRIT_OBJ", "spirit.obj", #filepath);
#insert #run embed_data("KEY_OBJ", "key.obj", #filepath);
#insert #run embed_data("MARK_OBJ", "mark.obj", #filepath);
#insert #run embed_data("GATE_OBJ", "gate.obj", #filepath);
#insert #run embed_data("GATE_CLOSE_OBJ", "gate_close.obj", #filepath);
#insert #run embed_data("GATE_FINISH_OBJ", "gate-finish.obj", #filepath);
#insert #run embed_data("GATE_FINISH_CLOSE_OBJ", "gate-finish_close.obj", #filepath);
#insert #run embed_data("SHURIKEN_OBJ", "shuriken.obj", #filepath);
#insert #run embed_data("INDICATOR_OUTLINE_OBJ", "indicator_outline.obj", #filepath);
#insert #run embed_data("INDICATOR_STROKE_OBJ", "indicator_stroke.obj", #filepath);

#insert #run embed_data("TERRAIN_TREE_SNOW_A", "Terrain/tree_snow_a.obj", #filepath);
#insert #run embed_data("TERRAIN_TREE_SNOW_B", "Terrain/tree_snow_b.obj", #filepath);
#insert #run embed_data("TERRAIN_TREE_SNOW_C", "Terrain/tree_snow_c.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOWMAN", "Terrain/snowman.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOWMAN_HAT", "Terrain/snowman_hat.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOW_FLAT", "Terrain/snow_flat.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOW_FLAT_LARGE", "Terrain/snow_flat_large.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOW_PILE", "Terrain/snow_pile.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOWFLAKE_A", "Terrain/snowflake_a.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOWFLAKE_B", "Terrain/snowflake_b.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOWFLAKE_C", "Terrain/snowflake_c.obj", #filepath);
#insert #run embed_data("ROCK_SMALL", "Terrain/rock_small.obj", #filepath);
#insert #run embed_data("ROCK_MEDIUM", "Terrain/rock_medium.obj", #filepath);
#insert #run embed_data("ROCK_LARGE", "Terrain/rock_large.obj", #filepath);
#insert #run embed_data("PROP_COLORMAP", "Terrain/prop_colormap.png", #filepath);
#insert #run embed_data("SKYBOX_SKI_PNG", "skybox_ski.png", #filepath);
#insert #run embed_data("SKYBOX_OBJ", "skybox.obj", #filepath);
#insert #run embed_data("END_HOOK_OBJ", "end_hook.obj", #filepath);

#insert #run embed_data("ROBOT_A0_OBJ", "robot_A0.obj", #filepath);
#insert #run embed_data("ROBOT_A1_OBJ", "robot_A1.obj", #filepath);
#insert #run embed_data("ROBOT_A2_OBJ", "robot_A2.obj", #filepath);
#insert #run embed_data("ROBOT_A3_OBJ", "robot_A3.obj", #filepath);
#insert #run embed_data("ROBOT_A4_OBJ", "robot_A4.obj", #filepath);
#insert #run embed_data("ROBOT_A5_OBJ", "robot_A5.obj", #filepath);

#insert #run embed_data("PRESENT_A_OBJ", "present_a.obj", #filepath);
#insert #run embed_data("PRESENT_B_OBJ", "present_b.obj", #filepath);
#insert #run embed_data("ZONE_WALL_OBJ", "zone_wall.obj", #filepath);

#insert #run embed_data("UNIT_CYLINDER_OBJ", "unit_cylinder.obj", #filepath);
#insert #run embed_data("UNIT_SPHERE_OBJ", "unit_sphere.obj", #filepath);

#insert #run embed_data("GEOMETRY_WGSL", "Shader/geometry.wgsl", #filepath);
#insert #run embed_data("GEOMETRY_SHADOW_WGSL", "Shader/geometry_shadow.wgsl", #filepath);
#insert #run embed_data("PRESENT_WGSL", "Shader/present.wgsl", #filepath);
#insert #run embed_data("QUAD_WGSL", "Shader/quad.wgsl", #filepath);

#insert #run embed_data("COLORMAPS_PNG", "colormaps.png", #filepath);
#insert #run embed_data("TERRAIN_TILE_ALBEDO_PNG", "tile_albedo.png", #filepath);
#insert #run embed_data("TERRAIN_TILE_NORMAL_PNG", "tile_normal.png", #filepath);

#insert #run embed_data("HORN_CAR_0_MP3", "Sound/horn_car0.mp3", #filepath);
#insert #run embed_data("HORN_CAR_1_MP3", "Sound/horn_car1.mp3", #filepath);
#insert #run embed_data("HORN_CAR_2_MP3", "Sound/horn_car2.mp3", #filepath);
#insert #run embed_data("HORN_CAR_3_MP3", "Sound/horn_car3.mp3", #filepath);
#insert #run embed_data("HORN_CAR_4_MP3", "Sound/horn_car4.mp3", #filepath);
#insert #run embed_data("HORN_CAR_5_MP3", "Sound/horn_car5.mp3", #filepath);
#insert #run embed_data("HORN_CAR_6_MP3", "Sound/horn_car6.mp3", #filepath);
#insert #run embed_data("HORN_CAR_7_MP3", "Sound/horn_car7.mp3", #filepath);
#insert #run embed_data("HORN_CAR_8_MP3", "Sound/horn_car8.mp3", #filepath);

#insert #run embed_data("DRIFT_0_MP3", "Sound/drift_0.mp3", #filepath);
#insert #run embed_data("DRIFT_1_MP3", "Sound/drift_1.mp3", #filepath);
#insert #run embed_data("CHECKPOINT_OK_MP3", "Sound/checkpoint_ok.mp3", #filepath);
#insert #run embed_data("RES_MP3", "Sound/res.mp3", #filepath);
#insert #run embed_data("COIN_LAUNCH_MP3", "Sound/coin_launch.mp3", #filepath);

#insert #run embed_data("verdana_csv", "Font/verdana.csv", #filepath);
#insert #run embed_data("verdana_png", "Font/verdana.png", #filepath);

Prop_Id :: enum {
	TERRAIN_TREE_SNOW_A :: 0;
	TERRAIN_TREE_SNOW_B;
	TERRAIN_TREE_SNOW_C;
	TERRAIN_SNOWMAN;
	TERRAIN_SNOWMAN_HAT;
	TERRAIN_SNOW_FLAT;
	TERRAIN_SNOW_FLAT_LARGE;
	TERRAIN_SNOW_PILE;
	TERRAIN_SNOWFLAKE_A;
	TERRAIN_SNOWFLAKE_B;
	TERRAIN_SNOWFLAKE_C;
	ROCK_SMALL;
	ROCK_MEDIUM;
	ROCK_LARGE;
}

load_everything :: (platform: Platform) {
	#if !RUNTIME
		return;

	#if RUNTIME {
		names :: string.[
			"PLAIN_VERTEX",
			"INSTANCE_VERTEX",
			"INSTANCE_FRAGMENT",
			"TILE_VERTEX",
			"TILE_FRAGMENT",
			"QUAD_TEXTURE_VERTEX",
			"QUAD_TEXTURE_FRAGMENT",
			"SNOWFLAKES_AND_LIGHTS_MP3",
			"tile_cliff_albedo_png",
			"tile_cliff_normal_png",
			"tile_cliff_height_png",
			"tile_snow_albedo_png",
			"tile_snow_normal_png",
			"tile_snow_height_png",
			"tile_grass_albedo_png",
			"tile_grass_normal_png",
			"tile_grass_height_png",
			"tile_slippy_albedo_png",
			"tile_slippy_normal_png",
			"tile_slippy_height_png",
			"ui_atlas_png",
			"VEHICLE_RACER_OBJ",
			"VEHICLE_SUV_OBJ",
			"VEHICLE_SPEEDSTER_OBJ",
			"VEHICLE_DRAG_RACER_OBJ",
			"VEHICLE_MONSTER_TRUCK_OBJ",
			"VEHICLE_VINTAGE_RACER_OBJ",
			"FLAG_OBJ",
			"FLAG_DOWN_OBJ",
			"CLICK_WAV",
			"FOOTSTEP_SNOW_0_MP3",
			"FOOTSTEP_SNOW_1_MP3",
			"FOOTSTEP_SNOW_2_MP3",
			"FOOTSTEP_SNOW_3_MP3",
			"FOOTSTEP_SNOW_4_MP3",
			"FOOTSTEP_ICE_0_MP3",
			"FOOTSTEP_ICE_1_MP3",
			"FOOTSTEP_ICE_2_MP3",
			"FOOTSTEP_ICE_3_MP3",
			"FOOTSTEP_ICE_4_MP3",
			"BOAT_SAILING_0_WAV",
			"BOAT_SAILING_1_WAV",
			"BOAT_SAILING_2_WAV",
			"DRONE_BUZZING_0_WAV",
			"EXPLOSION_0_MP3",
			"EXPLOSION_1_MP3",
			"EXPLOSION_2_MP3",
			"EXPLOSION_3_MP3",
			"EXPLOSION_4_MP3",
			"EXPLOSION_5_MP3",
			"EXPLOSION_6_MP3",
			"EXPLOSION_7_MP3",
			"EXPLOSION_8_MP3",
			"LOSER_MP3",
			"TILE_OBJ",
			"CAR_OBJ",
			"TOMBSTONE_OBJ",
			"SKULL_OBJ",
			"COIN_OBJ",
			"SPIRIT_OBJ",
			"KEY_OBJ",
			"MARK_OBJ",
			"GATE_OBJ",
			"GATE_CLOSE_OBJ",
			"GATE_FINISH_OBJ",
			"GATE_FINISH_CLOSE_OBJ",
			"SHURIKEN_OBJ",
			"POSTPROCESS_VERTEX",
			"POSTPROCESS_FRAGMENT",
			"tile_atlas_png",
			"SHADOW_VERTEX",
			"SHADOW_FRAGMENT",
			"SHADOW_INSTANCED_VERTEX",
			"SHADOW_INSTANCED_FRAGMENT",
			"INSTANCED_TEXTURE_VERTEX",
			"INSTANCED_TEXTURE_FRAGMENT",
			"SHADOW_INSTANCED_TEXTURE_VERTEX",
			"SHADOW_INSTANCED_TEXTURE_FRAGMENT",
			"TERRAIN_TREE_SNOW_A",
			"TERRAIN_TREE_SNOW_B",
			"TERRAIN_TREE_SNOW_C",
			"TERRAIN_SNOWMAN",
			"TERRAIN_SNOWMAN_HAT",
			"TERRAIN_SNOW_FLAT",
			"TERRAIN_SNOW_FLAT_LARGE",
			"TERRAIN_SNOW_PILE",
			"TERRAIN_SNOWFLAKE_A",
			"TERRAIN_SNOWFLAKE_B",
			"TERRAIN_SNOWFLAKE_C",
			"PROP_COLORMAP",
			"ROCK_SMALL",
			"ROCK_LARGE",
			"ROCK_MEDIUM",
			"SKYBOX_SKI_PNG",
			"SKYBOX_OBJ",
			"END_HOOK_OBJ",
			"SKYBOX_VERTEX",
			"SKYBOX_FRAGMENT",
			"BOAT_ROW_OBJ",
			"BOAT_SAIL_OBJ",
			"BOAT_FISHING_OBJ",
			"TAXI_OBJ",
			"POLICE_OBJ",
			"TRACTOR_OBJ",
			"PIRATE_SHIP_OBJ",
			"AMBULANCE_OBJ",
			"SPACESHIP_OBJ",
			"ANTIAIR_CAMION_OBJ",
			"ANTIAIR_CANON_OBJ",
			"MISSILE_OBJ",
			"DRONE_OBJ",
			"TRAP_SPIKE_OBJ",
			"DRONE_BLADE_OBJ",
			"TROPHY_OBJ",
			"NUMBER_0_OBJ",
			"NUMBER_1_OBJ",
			"NUMBER_2_OBJ",
			"NUMBER_3_OBJ",
			"NUMBER_4_OBJ",
			"NUMBER_5_OBJ",
			"NUMBER_6_OBJ",
			"NUMBER_7_OBJ",
			"NUMBER_8_OBJ",
			"NUMBER_9_OBJ",
			"PARTICLE_TEXTURE_PNG",
			"PARTICLE_VERTEX",
			"PARTICLE_FRAGMENT",
			"INDICATOR_OUTLINE_OBJ",
			"INDICATOR_STROKE_OBJ",
			"ROBOT_A0_OBJ",
			"ROBOT_A1_OBJ",
			"ROBOT_A2_OBJ",
			"ROBOT_A3_OBJ",
			"ROBOT_A4_OBJ",
			"ROBOT_A5_OBJ",
			"PRESENT_A_OBJ",
			"PRESENT_B_OBJ",
			"ZONE_WALL_OBJ",
			"UNIT_CYLINDER_OBJ",
			"UNIT_SPHERE_OBJ",
			"GEOMETRY_WGSL",
			"GEOMETRY_SHADOW_WGSL",
			"PRESENT_WGSL",
			"QUAD_WGSL",
			"COLORMAPS_PNG",
			"TERRAIN_TILE_ALBEDO_PNG",
			"TERRAIN_TILE_NORMAL_PNG",
			"HORN_CAR_0_MP3",
			"HORN_CAR_1_MP3",
			"HORN_CAR_2_MP3",
			"HORN_CAR_3_MP3",
			"HORN_CAR_4_MP3",
			"HORN_CAR_5_MP3",
			"HORN_CAR_6_MP3",
			"HORN_CAR_7_MP3",
			"HORN_CAR_8_MP3",
			"DRIFT_0_MP3",
			"DRIFT_1_MP3",
			"CHECKPOINT_OK_MP3",
			"RES_MP3",
			"COIN_LAUNCH_MP3",
			"POINT_UP_MP3",
			"JUKEBOX_OBJ",
			"ztotez_atlas_png",
			"verdana_csv",
			"verdana_png",
		];
		#insert #run -> string {
			sb: String_Builder;
			for names {
				print_to_builder(*sb, "%_PROC(platform);\n", it);
			}
			return builder_to_string(*sb);
		};
	}
}

load_font :: (csv: string) -> Font {
	lines := split(csv, "\n",, temp);

	font: Font;

	for lines {
		g: Glyph;

		if scan2(
			it,
			"%,%,%,%,%,%,%,%,%,%",
			*g.unicode,
			*g.advance,
			*g.planex,
			*g.planey,
			*g.planew,
			*g.planeh,
			*g.atlasx,
			*g.atlasy,
			*g.atlasw,
			*g.atlash
		) {
			continue;
		}

		if g.unicode >= 256 {
			continue;
		}

		font.glyphs[g.unicode] = g;
	}

	return font;
}

