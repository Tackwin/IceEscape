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

	data_got := get_data("%");
	print("Loaded % KB from %\n", data_got.count / 1024);
	return add_global_data(data_got, .READ_ONLY);
};
FORMAT;

	return sprint(format_text, name, "%", "%", root, "%", "%", path, "%", name);
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

#insert #run embed_data("VEHICLE_RACER_OBJ", "Mesh/Vehicle_Racer.obj", #filepath);
#insert #run embed_data("VEHICLE_SUV_OBJ", "Mesh/Vehicle_Suv.obj", #filepath);
#insert #run embed_data("VEHICLE_SPEEDSTER_OBJ", "Mesh/Vehicle_Speedster.obj", #filepath);
#insert #run embed_data("VEHICLE_MONSTER_TRUCK_OBJ", "Mesh/Vehicle_Monster_Truck.obj", #filepath);
#insert #run embed_data("VEHICLE_VINTAGE_RACER_OBJ", "Mesh/Vehicle_Vintage_Racer.obj", #filepath);
#insert #run embed_data("VEHICLE_DRAG_RACER_OBJ", "Mesh/Vehicle_Drag_Racer.obj", #filepath);
#insert #run embed_data("BOAT_SAIL_OBJ", "Mesh/Vehicle_Boat_Sail.obj", #filepath);
#insert #run embed_data("BOAT_ROW_OBJ", "Mesh/Vehicle_Boat_Row.obj", #filepath);
#insert #run embed_data("BOAT_FISHING_OBJ", "Mesh/Vehicle_Boat_Fishing.obj", #filepath);
#insert #run embed_data("TAXI_OBJ", "Mesh/Vehicle_Taxi.obj", #filepath);
#insert #run embed_data("POLICE_OBJ", "Mesh/Vehicle_Police.obj", #filepath);
#insert #run embed_data("TRACTOR_OBJ", "Mesh/Vehicle_Tractor.obj", #filepath);
#insert #run embed_data("PIRATE_SHIP_OBJ", "pirate_ship.obj", #filepath);
#insert #run embed_data("AMBULANCE_OBJ", "Mesh/Vehicle_Ambulance.obj", #filepath);
#insert #run embed_data("SPACESHIP_OBJ", "spaceship.obj", #filepath);
#insert #run embed_data("ANTIAIR_CAMION_OBJ", "antiair_camion.obj", #filepath);
#insert #run embed_data("ANTIAIR_CANON_OBJ", "antiair_canon.obj", #filepath);
#insert #run embed_data("MISSILE_OBJ", "missile.obj", #filepath);
#insert #run embed_data("DRONE_OBJ", "drone.obj", #filepath);
#insert #run embed_data("DRONE_BLADE_OBJ", "drone_blade.obj", #filepath);
#insert #run embed_data("PRESSBUTTON_UNPRESSED_OBJ", "Mesh/PressButton_Unpressed.obj", #filepath);
#insert #run embed_data("PRESSBUTTON_PRESSED_OBJ", "Mesh/PressButton_Pressed.obj", #filepath);
#insert #run embed_data("PRESSBUTTON_UNPRESSED_RADIO_OBJ", "Mesh/PressButton_Unpressed_radio.obj", #filepath);
#insert #run embed_data("PRESSBUTTON_PRESSED_RADIO_OBJ", "Mesh/PressButton_Pressed_radio.obj", #filepath);
#insert #run embed_data("BOMB_OBJ", "Mesh/Bomb.obj", #filepath);
#insert #run embed_data("CRATE_OBJ", "Mesh/Crate.obj", #filepath);
#insert #run embed_data("GRAVESTONE_OBJ", "Mesh/Gravestone.obj", #filepath);

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

#insert #run embed_data("TURN_TABLE_TURN_OBJ", "mesh/turntable_turn.obj", #filepath);
#insert #run embed_data("TURN_TABLE_BASE_OBJ", "mesh/turntable_base.obj", #filepath);

#insert #run embed_data("FLAG_OBJ", "flag.obj", #filepath);
#insert #run embed_data("FLAG_DOWN_OBJ", "flag_down.obj", #filepath);

#insert #run embed_data("CLICK_WAV", "click.wav", #filepath);

#insert #run embed_data("NOTE_WAV", "Sound/Note.wav", #filepath);
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
#insert #run embed_data("TOMBSTONE_OBJ", "tombstone.obj", #filepath);
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

#insert #run embed_data("TRAP_SPIKE_OBJ", "Mesh/Trap_Spike.obj", #filepath);
#insert #run embed_data("TRAP_BASE_OBJ", "Mesh/Trap_Base.obj", #filepath);
#insert #run embed_data("LANTERN_OBJ", "Mesh/Lantern.obj", #filepath);
#insert #run embed_data("TERRAIN_TREE_SNOW_A", "Mesh/tree_snow_a.obj", #filepath);
#insert #run embed_data("TERRAIN_TREE_SNOW_B", "Mesh/tree_snow_b.obj", #filepath);
#insert #run embed_data("TERRAIN_TREE_SNOW_C", "Mesh/tree_snow_c.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOWMAN", "Mesh/snowman.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOWMAN_HAT", "Mesh/snowman_hat.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOW_FLAT", "Mesh/snow_flat.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOW_FLAT_LARGE", "Mesh/snow_flat_large.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOW_PILE", "Mesh/snow_pile.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOWFLAKE_A", "Mesh/snowflake_a.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOWFLAKE_B", "Mesh/snowflake_b.obj", #filepath);
#insert #run embed_data("TERRAIN_SNOWFLAKE_C", "Mesh/snowflake_c.obj", #filepath);
#insert #run embed_data("BLOCK_ROCK_OBJ", "Mesh/Block_Rock.obj", #filepath);
#insert #run embed_data("NO_BLOCK_ROCK_OBJ", "Mesh/No_Block_Rock.obj", #filepath);
#insert #run embed_data("ROCK_SMALL", "Mesh/rock_small.obj", #filepath);
#insert #run embed_data("ROCK_MEDIUM", "Mesh/rock_medium.obj", #filepath);
#insert #run embed_data("ROCK_LARGE", "Mesh/rock_large.obj", #filepath);
#insert #run embed_data("PROP_COLORMAP", "Images/prop_colormap.png", #filepath);
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
#insert #run embed_data("UNIT_CUBE_OBJ", "Mesh/Cube.obj", #filepath);

#insert #run embed_data("GEOMETRY_WGSL", "Shader/geometry.wgsl", #filepath);
#insert #run embed_data("GEOMETRY_SHADOW_WGSL", "Shader/geometry_shadow.wgsl", #filepath);
#insert #run embed_data("PRESENT_WGSL", "Shader/present.wgsl", #filepath);
#insert #run embed_data("QUAD_WGSL", "Shader/quad.wgsl", #filepath);


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
#insert #run embed_data("COLORMAPS_PNG", "images/colormaps.png", #filepath);
#insert #run embed_data("TERRAIN_TILE_ALBEDO_PNG", "Images/tile_albedo.png", #filepath);
#insert #run embed_data("TERRAIN_TILE_NORMAL_PNG", "Images/tile_normal.png", #filepath);
#insert #run embed_data("PARTICLE_TEXTURE_PNG", "Images/particle_texture.png", #filepath);
#insert #run embed_data("ui_atlas_png", "UI/ui_atlas.png", #filepath);

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
			"NOTE_WAV",
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
			"TOMBSTONE_OBJ",
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
			"SHADOW_VERTEX",
			"SHADOW_FRAGMENT",
			"SHADOW_INSTANCED_VERTEX",
			"SHADOW_INSTANCED_FRAGMENT",
			"INSTANCED_TEXTURE_VERTEX",
			"INSTANCED_TEXTURE_FRAGMENT",
			"SHADOW_INSTANCED_TEXTURE_VERTEX",
			"SHADOW_INSTANCED_TEXTURE_FRAGMENT",
			"LANTERN_OBJ",
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
			"BLOCK_ROCK_OBJ",
			"NO_BLOCK_ROCK_OBJ",
			"ROCK_SMALL",
			"ROCK_LARGE",
			"ROCK_MEDIUM",
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
			"TRAP_BASE_OBJ",
			"PRESSBUTTON_UNPRESSED_OBJ",
			"PRESSBUTTON_PRESSED_OBJ",
			"PRESSBUTTON_UNPRESSED_RADIO_OBJ",
			"PRESSBUTTON_PRESSED_RADIO_OBJ",
			"BOMB_OBJ",
			"CRATE_OBJ",
			"GRAVESTONE_OBJ",
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
			"TURN_TABLE_TURN_OBJ",
			"TURN_TABLE_BASE_OBJ",
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
			"UNIT_CUBE_OBJ",
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

		atlas_h := 1024.0;
		old_y := g.atlasy;
		g.atlasy = atlas_h - g.atlash;
		g.atlash = atlas_h - old_y;

		font.glyphs[g.unicode] = g;
	}

	return font;
}

load_png :: (data: [] u8) -> Image {
	PNG :: #import "PNG";

	rgba: [..] u8;
	width: int;
	height: int;
	if data.count == 0 || !PNG.read_rgba(data, *rgba, *width, *height) {
		print("Failed to decode PNG (% bytes)\n", data.count);
		return .{};
	}

	image: Image;
	image.width = xx width;
	image.height = xx height;
	image.channels = 4;
	image.data = rgba;
	return image;
}
