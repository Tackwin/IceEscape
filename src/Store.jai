#scope_file
Render :: #import "Render";
Assets :: #import "Assets";
Platform :: #import "Platform";
Scene :: #import "Scene";
#import "String";
#import "Basic";

#scope_export

Model_Id :: enum {
	Racer :: 1;
	SUV :: 2;
	Speedster :: 3;
	Tombstone :: 4;
	Tile :: 5;
	Skull :: 6;
	Coin :: 7;
	Key :: 8;
	Mark :: 9;
	Gate :: 10;
	Gate_Close :: 11;
	Shuriken :: 12;
	Spirit :: 13;
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

Shader_Id :: enum {
	Font :: 0;
	Model :: 1;
	Texture :: 2;
	Instance :: 3;
	Tile :: 4;
}

Store :: struct {
	tile_snow_albedo_png: Assets.Image;
	tile_snow_normal_png: Assets.Image;
	tile_snow_height_png: Assets.Image;

	tile_cliff_albedo_png: Assets.Image;
	tile_cliff_normal_png: Assets.Image;
	tile_cliff_height_png: Assets.Image;

	tile_grass_albedo_png: Assets.Image;
	tile_grass_normal_png: Assets.Image;
	tile_grass_height_png: Assets.Image;

	tile_slippy_albedo_png: Assets.Image;
	tile_slippy_normal_png: Assets.Image;
	tile_slippy_height_png: Assets.Image;

	ui_atlas_png: Assets.Image;
	tile_atlas_png: Assets.Image;
	prop_colormap_png: Assets.Image;

	skybox_ski_png: Assets.Image;
	skybox_ski: Render.Texture;

	tile_snow_albedo: Render.Texture;
	tile_snow_normal: Render.Texture;
	tile_snow_height: Render.Texture;

	tile_cliff_albedo: Render.Texture;
	tile_cliff_normal: Render.Texture;
	tile_cliff_height: Render.Texture;

	tile_grass_albedo: Render.Texture;
	tile_grass_normal: Render.Texture;
	tile_grass_height: Render.Texture;

	tile_slippy_albedo: Render.Texture;
	tile_slippy_normal: Render.Texture;
	tile_slippy_height: Render.Texture;

	ui_atlas: Render.Texture;

	loser_ogg: Platform.Audio;
	footstep_0_ogg: Platform.Audio;
	footstep_1_ogg: Platform.Audio;
	footstep_2_ogg: Platform.Audio;
	footstep_3_ogg: Platform.Audio;
	footstep_4_ogg: Platform.Audio;
	click_wav: Platform.Audio;
	snowflakes_and_lights_ogg: Platform.Audio;

	font_shader: Render.Shader;
	model_shader: Render.Shader;
	texture_shader: Render.Shader;
	instance_shader: Render.Shader;
	tile_shader: Render.Shader;
	quad_texture_shader: Render.Shader;
	postpro_shader: Render.Shader;
	instanced_texture_shader: Render.Shader;
	shadow_shader: Render.Shader;
	shadow_instanced_shader: Render.Shader;
	shadow_instanced_texture_shader: Render.Shader;
	skybox_shader: Render.Shader;

	ice_texture: Render.Texture;
	coin_texture: Render.Texture;
	slippy_ice_texture: Render.Texture;
	grass_texture: Render.Texture;
	dirt_texture: Render.Texture;
	mark_texture: Render.Texture;
	vehicle_colormap: Render.Texture;
	tile_atlas: Render.Texture;
	prop_colormap: Render.Texture;

	flag_geometry: Render.Geometry;
	flag_down_geometry: Render.Geometry;
	player_geometry: Render.Geometry;
	racer_geometry: Render.Geometry;
	suv_geometry: Render.Geometry;
	speedster_geometry: Render.Geometry;
	tombstone_geometry: Render.Geometry;
	tile_geometry: Render.Geometry;
	skull_geometry: Render.Geometry;
	coin_geometry: Render.Geometry;
	key_geometry: Render.Geometry;
	mark_geometry: Render.Geometry;
	gate_geometry: Render.Geometry;
	gate_close_geometry: Render.Geometry;
	gate_finish_geometry: Render.Geometry;
	gate_finish_close_geometry: Render.Geometry;
	shuriken_geometry: Render.Geometry;
	spirit_geometry: Render.Geometry;
	terrain_tree_snow_a: Render.Geometry;
	terrain_tree_snow_b: Render.Geometry;
	terrain_tree_snow_c: Render.Geometry;
	terrain_snowman: Render.Geometry;
	terrain_snowman_hat: Render.Geometry;
	terrain_snow_flat: Render.Geometry;
	terrain_snow_flat_large: Render.Geometry;
	terrain_snow_pile: Render.Geometry;
	terrain_snowflake_a: Render.Geometry;
	terrain_snowflake_b: Render.Geometry;
	terrain_snowflake_c: Render.Geometry;
	rock_small: Render.Geometry;
	rock_medium: Render.Geometry;
	rock_large: Render.Geometry;
	skybox_geometry: Render.Geometry;
}

get_geometry :: (store: Store, id: int) -> *Render.Geometry {
	return get_geometry(store, id.(Model_Id));
}
get_geometry :: (store: Store, id: Model_Id) -> *Render.Geometry {
	if #complete id == {
		case .Racer; return *store.racer_geometry;
		case .SUV; return *store.suv_geometry;
		case .Speedster; return *store.speedster_geometry;
		case .Tombstone; return *store.tombstone_geometry;
		case .Tile; return *store.tile_geometry;
		case .Skull; return *store.skull_geometry;
		case .Coin; return *store.coin_geometry;
		case .Key; return *store.key_geometry;
		case .Mark; return *store.mark_geometry;
		case .Gate; return *store.gate_geometry;
		case .Gate_Close; return *store.gate_close_geometry;
		case .Shuriken; return *store.shuriken_geometry;
		case .Spirit; return *store.spirit_geometry;
	}
	return null;
}

get_albedo :: (store: Store, id: Scene.Tile.Kind) -> *Render.Texture {
	if #complete id == {
		case .None;
			return null;
		case .Ice;
			return *store.ice_texture;
		case .Slippy_Ice;
			return *store.tile_slippy_albedo;
		case .Grass;
			return *store.tile_grass_albedo;
		case .Dirt;
			return *store.dirt_texture;
	}
	return null;
}

get_height :: (store: Store, id: Scene.Tile.Kind) -> *Render.Texture {
	if #complete id == {
		case .None;
			return null;
		case .Ice;
			return *store.tile_snow_height;
		case .Slippy_Ice;
			return *store.tile_slippy_height;
		case .Grass;
			return *store.tile_grass_height;
		case .Dirt;
			return *store.tile_cliff_height;
	}
	return null;
}

get_normal :: (store: Store, id: Scene.Tile.Kind) -> *Render.Texture {
	if #complete id == {
		case .None;
			return null;
		case .Ice;
			return *store.ice_texture;
		case .Slippy_Ice;
			return *store.tile_slippy_normal;
		case .Grass;
			return *store.tile_grass_normal;
		case .Dirt;
			return *store.dirt_texture;
	}
	return null;
}

get_texture :: (store: Store, id: Texture_Id) -> *Render.Texture {
	if #complete id == {
		case .Ice; return *store.ice_texture;
		case .Coin; return *store.coin_texture;
		case .Slippy_Ice; return *store.slippy_ice_texture;
		case .Grass; return *store.grass_texture;
		case .Dirt; return *store.dirt_texture;
		case .Mark; return *store.mark_texture;
		case .Vehicle_Colormap; return *store.vehicle_colormap;
	}
	return null;
}

get_shader :: (store: Store, id: Shader_Id) -> *Render.Shader {
	if #complete id == {
		case .Font; return *store.font_shader;
		case .Model; return *store.model_shader;
		case .Texture; return *store.texture_shader;
		case .Instance; return *store.instance_shader;
		case .Tile; return *store.tile_shader;
	}
	return null;
}

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


get_prop :: (store: Store, id: Assets.Prop_Id) -> *Render.Geometry {
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
		Assets.load_everything();
	}

	store.ui_atlas_png = Assets.Image.make_from_memory(Assets.ui_atlas_png, 4);
	store.ui_atlas = Render.Texture.make_from_image(store.ui_atlas_png);
	
	store.tile_atlas_png = Assets.Image.make_from_memory(Assets.tile_atlas_png, 4);
	store.prop_colormap_png = Assets.Image.make_from_memory(Assets.PROP_COLORMAP, 3);
	store.tile_atlas = Render.Texture.make_from_image(store.tile_atlas_png);

	store.tile_cliff_albedo_png = Assets.Image.make_from_memory(Assets.tile_cliff_albedo_png, 4);
	store.tile_cliff_normal_png = Assets.Image.make_from_memory(Assets.tile_cliff_normal_png, 3);
	store.tile_cliff_height_png = Assets.Image.make_from_memory(Assets.tile_cliff_height_png, 3);

	store.tile_snow_albedo_png = Assets.Image.make_from_memory(Assets.tile_snow_albedo_png, 4);
	store.tile_snow_normal_png = Assets.Image.make_from_memory(Assets.tile_snow_normal_png, 3);
	store.tile_snow_height_png = Assets.Image.make_from_memory(Assets.tile_snow_height_png, 3);

	store.tile_grass_albedo_png = Assets.Image.make_from_memory(Assets.tile_grass_albedo_png, 4);
	store.tile_grass_normal_png = Assets.Image.make_from_memory(Assets.tile_grass_normal_png, 3);
	store.tile_grass_height_png = Assets.Image.make_from_memory(Assets.tile_grass_height_png, 3);

	store.tile_slippy_albedo_png = Assets.Image.make_from_memory(Assets.tile_slippy_albedo_png, 4);
	store.tile_slippy_normal_png = Assets.Image.make_from_memory(Assets.tile_slippy_normal_png, 3);
	store.tile_slippy_height_png = Assets.Image.make_from_memory(Assets.tile_slippy_height_png, 3);

	store.tile_cliff_albedo = Render.Texture.make_from_image(store.tile_cliff_albedo_png);
	store.tile_cliff_normal = Render.Texture.make_from_image(store.tile_cliff_normal_png);
	store.tile_cliff_height = Render.Texture.make_from_image(store.tile_cliff_height_png);

	store.tile_snow_albedo = Render.Texture.make_from_image(store.tile_snow_albedo_png);
	store.tile_snow_normal = Render.Texture.make_from_image(store.tile_snow_normal_png);
	store.tile_snow_height = Render.Texture.make_from_image(store.tile_snow_height_png);

	store.tile_grass_albedo = Render.Texture.make_from_image(store.tile_grass_albedo_png);
	store.tile_grass_normal = Render.Texture.make_from_image(store.tile_grass_normal_png);
	store.tile_grass_height = Render.Texture.make_from_image(store.tile_grass_height_png);

	store.tile_slippy_albedo = Render.Texture.make_from_image(store.tile_slippy_albedo_png);
	store.tile_slippy_normal = Render.Texture.make_from_image(store.tile_slippy_normal_png);
	store.tile_slippy_height = Render.Texture.make_from_image(store.tile_slippy_height_png);

	store.skybox_ski_png = Assets.Image.make_from_memory(Assets.SKYBOX_SKI_PNG, 4);
	store.skybox_ski = Render.Texture.make_from_image(store.skybox_ski_png);

	store.loser_ogg = platform.load_audio(xx Assets.LOSER_OGG);
	store.footstep_0_ogg = platform.load_audio(xx Assets.FOOTSTEP_SNOW_0_OGG);
	store.footstep_1_ogg = platform.load_audio(xx Assets.FOOTSTEP_SNOW_1_OGG);
	store.footstep_2_ogg = platform.load_audio(xx Assets.FOOTSTEP_SNOW_2_OGG);
	store.footstep_3_ogg = platform.load_audio(xx Assets.FOOTSTEP_SNOW_3_OGG);
	store.footstep_4_ogg = platform.load_audio(xx Assets.FOOTSTEP_SNOW_4_OGG);
	store.click_wav = platform.load_audio(xx Assets.CLICK_WAV);
	store.snowflakes_and_lights_ogg = platform.load_audio(xx Assets.SNOWFLAKES_AND_LIGHTS_OGG);

	store.skybox_shader = Render.Shader.make(
		xx Assets.SKYBOX_VERTEX, xx Assets.SKYBOX_FRAGMENT
	);
	store.model_shader = Render.Shader.make(
		xx Assets.PLAIN_VERTEX, Assets.PLAIN_FRAGMENT
	);
	store.texture_shader = Render.Shader.make(
		xx Assets.PLAIN_VERTEX, Assets.TEXTURE_FRAGMENT
	);
	store.font_shader = Render.Shader.make(
		Assets.FONT_VERTEX, Assets.FONT_FRAGMENT
	);
	store.instance_shader = Render.Shader.make(
		xx Assets.INSTANCE_VERTEX, xx Assets.INSTANCE_FRAGMENT
	);
	store.tile_shader = Render.Shader.make(
		xx Assets.TILE_VERTEX, xx Assets.TILE_FRAGMENT
	);
	store.quad_texture_shader = Render.Shader.make(
		xx Assets.QUAD_TEXTURE_VERTEX, xx Assets.QUAD_TEXTURE_FRAGMENT
	);
	store.postpro_shader = Render.Shader.make(
		xx Assets.POSTPROCESS_VERTEX, xx Assets.POSTPROCESS_FRAGMENT
	);
	store.shadow_shader = Render.Shader.make(
		xx Assets.SHADOW_VERTEX, xx Assets.SHADOW_FRAGMENT
	);
	store.shadow_instanced_shader = Render.Shader.make(
		xx Assets.SHADOW_INSTANCED_VERTEX, xx Assets.SHADOW_INSTANCED_FRAGMENT
	);
	store.instanced_texture_shader = Render.Shader.make(
		xx Assets.INSTANCED_TEXTURE_VERTEX, xx Assets.INSTANCED_TEXTURE_FRAGMENT
	);
	store.shadow_instanced_texture_shader = Render.Shader.make(
		xx Assets.SHADOW_INSTANCED_TEXTURE_VERTEX, xx Assets.SHADOW_INSTANCED_TEXTURE_FRAGMENT
	);

	store.ice_texture = Render.Texture.make_from_image(Assets.ICE_TEXTURE);
	store.coin_texture = Render.Texture.make_from_image(Assets.COIN_TEXTURE);
	store.dirt_texture = Render.Texture.make_from_image(Assets.DIRT_TEXTURE);
	store.grass_texture = Render.Texture.make_from_image(Assets.GRASS_TEXTURE);
	store.slippy_ice_texture = Render.Texture.make_from_image(Assets.SLIPPY_ICE_TEXTURE);
	store.mark_texture = Render.Texture.make_from_image(Assets.MARK_TEXTURE);
	store.vehicle_colormap = Render.Texture.make_from_image(Assets.VEHICLE_COLORMAP_TEXTURE);
	store.prop_colormap = Render.Texture.make_from_image(store.prop_colormap_png);
	Render.set_clamp(store.mark_texture, .T);

	// store.tile_geometry = Render.Geometry.make_square(
	// 	.{ 0, 0, 0 }, .{ 1, 0, 0 },  .{ 1, 1, 0 },  .{ 0, 1, 0 }
	// );
	store.tile_geometry = Render.Geometry.make_from_obj(Assets.TILE_OBJ);
	store.flag_geometry = Render.Geometry.make_from_obj(Assets.FLAG_OBJ);
	store.flag_down_geometry = Render.Geometry.make_from_obj(Assets.FLAG_DOWN_OBJ);
	store.player_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_RACER_OBJ);
	store.racer_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_RACER_OBJ);
	store.suv_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_SUV_OBJ);
	store.speedster_geometry = Render.Geometry.make_from_obj(Assets.VEHICLE_SPEEDSTER_OBJ);
	store.tombstone_geometry = Render.Geometry.make_from_obj(Assets.TOMBSTONE_OBJ);
	store.coin_geometry = Render.Geometry.make_from_obj(Assets.COIN_OBJ);
	store.skull_geometry = Render.Geometry.make_from_obj(Assets.SKULL_OBJ);
	store.key_geometry = Render.Geometry.make_from_obj(Assets.KEY_OBJ);
	store.mark_geometry = Render.Geometry.make_from_obj(Assets.MARK_OBJ);
	store.gate_geometry = Render.Geometry.make_from_obj(Assets.GATE_OBJ);
	store.gate_close_geometry = Render.Geometry.make_from_obj(Assets.GATE_CLOSE_OBJ);
	store.gate_finish_geometry = Render.Geometry.make_from_obj(Assets.GATE_FINISH_OBJ);
	store.gate_finish_close_geometry = Render.Geometry.make_from_obj(Assets.GATE_FINISH_CLOSE_OBJ);
	store.shuriken_geometry = Render.Geometry.make_from_obj(Assets.SHURIKEN_OBJ);
	store.spirit_geometry = Render.Geometry.make_from_obj(Assets.SPIRIT_OBJ);
	store.terrain_tree_snow_a = Render.Geometry.make_from_obj(Assets.TERRAIN_TREE_SNOW_A);
	store.terrain_tree_snow_b = Render.Geometry.make_from_obj(Assets.TERRAIN_TREE_SNOW_B);
	store.terrain_tree_snow_c = Render.Geometry.make_from_obj(Assets.TERRAIN_TREE_SNOW_C);
	store.terrain_snowman = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOWMAN);
	store.terrain_snowman_hat = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOWMAN_HAT);
	store.terrain_snow_flat = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOW_FLAT);
	store.terrain_snow_flat_large = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOW_FLAT_LARGE);
	store.terrain_snow_pile = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOW_PILE);
	store.terrain_snowflake_a = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOWFLAKE_A);
	store.terrain_snowflake_b = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOWFLAKE_B);
	store.terrain_snowflake_c = Render.Geometry.make_from_obj(Assets.TERRAIN_SNOWFLAKE_C);
	store.rock_small = Render.Geometry.make_from_obj(Assets.ROCK_SMALL);
	store.rock_medium = Render.Geometry.make_from_obj(Assets.ROCK_MEDIUM);
	store.rock_large = Render.Geometry.make_from_obj(Assets.ROCK_LARGE);
	store.skybox_geometry = Render.Geometry.make_from_obj(Assets.SKYBOX_OBJ);
}

#if Assets.RUNTIME {
	#import "File";
}

check_change :: (store: *Store, paths: [] string) {
	#if Assets.RUNTIME {

		handle_shader :: (change: string, name: string, shader: *Render.Shader) #expand {
			if ends_with(change, tprint("%.vert", name))
			|| ends_with(change, tprint("%.frag", name))
			{
				print("Recompiling % shader\n", name);

				vertex_code, ok := read_entire_file(
					tprint("%/../assets/Shader/%.vert", #filepath, name),, temp
				);
				if ok {
					fragment_code:, ok = read_entire_file(
						tprint("%/../assets/Shader/%.frag", #filepath, name),, temp
					);
					if ok {
						Render.release(shader);
						shader.* = Render.Shader.make(vertex_code, fragment_code);
					}
				}
			}
		}

		for paths {
			handle_shader(it, "tile", *store.tile_shader);
			handle_shader(it, "instance", *store.instance_shader);
			handle_shader(it, "plain", *store.model_shader);
			handle_shader(it, "postpro", *store.postpro_shader);
			handle_shader(it, "shadow", *store.shadow_shader);
			handle_shader(it, "shadow_instanced", *store.shadow_instanced_shader);
			handle_shader(it, "instance_texture", *store.instanced_texture_shader);
			handle_shader(it, "shadow_instance_texture", *store.shadow_instanced_texture_shader);
			handle_shader(it, "skybox", *store.skybox_shader);
		}
	}
}
