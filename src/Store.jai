#scope_file
Render :: #import "Render";
Assets :: #import "Assets";
Platform :: #import "Platform";

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
	loser_ogg: Platform.Audio;
	footstep_0_ogg: Platform.Audio;
	footstep_1_ogg: Platform.Audio;
	footstep_2_ogg: Platform.Audio;
	footstep_3_ogg: Platform.Audio;
	footstep_4_ogg: Platform.Audio;

	font_shader: Render.Shader;
	model_shader: Render.Shader;
	texture_shader: Render.Shader;
	instance_shader: Render.Shader;
	tile_shader: Render.Shader;

	ice_texture: Render.Texture;
	coin_texture: Render.Texture;
	slippy_ice_texture: Render.Texture;
	grass_texture: Render.Texture;
	dirt_texture: Render.Texture;
	mark_texture: Render.Texture;
	vehicle_colormap: Render.Texture;

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
	shuriken_geometry: Render.Geometry;
	spirit_geometry: Render.Geometry;
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

init_store :: (platform: Platform.Platform, store: *Store) {
	store.loser_ogg = platform.load_audio(Assets.LOSER_OGG);
	store.footstep_0_ogg = platform.load_audio(Assets.FOOTSTEP_0_OGG);
	store.footstep_1_ogg = platform.load_audio(Assets.FOOTSTEP_1_OGG);
	store.footstep_2_ogg = platform.load_audio(Assets.FOOTSTEP_2_OGG);
	store.footstep_3_ogg = platform.load_audio(Assets.FOOTSTEP_3_OGG);
	store.footstep_4_ogg = platform.load_audio(Assets.FOOTSTEP_4_OGG);

	store.model_shader = Render.Shader.make(
		Assets.PLAIN_VERTEX, Assets.PLAIN_FRAGMENT
	);
	store.texture_shader = Render.Shader.make(
		Assets.PLAIN_VERTEX, Assets.TEXTURE_FRAGMENT
	);
	store.font_shader = Render.Shader.make(
		Assets.FONT_VERTEX, Assets.FONT_FRAGMENT
	);
	store.instance_shader = Render.Shader.make(
		Assets.INSTANCED_VERTEX, Assets.TEXTURE_FRAGMENT
	);
	store.tile_shader = Render.Shader.make(
		Assets.TILE_VERTEX, Assets.TILE_FRAGMENT
	);
	store.ice_texture = Render.Texture.make_from_image(Assets.ICE_TEXTURE);
	store.coin_texture = Render.Texture.make_from_image(Assets.COIN_TEXTURE);
	store.dirt_texture = Render.Texture.make_from_image(Assets.DIRT_TEXTURE);
	store.grass_texture = Render.Texture.make_from_image(Assets.GRASS_TEXTURE);
	store.slippy_ice_texture = Render.Texture.make_from_image(Assets.SLIPPY_ICE_TEXTURE);
	store.tile_geometry = Render.Geometry.make_square(
		.{ 0, 0, 0 }, .{ 1, 0, 0 },  .{ 1, 1, 0 },  .{ 0, 1, 0 }
	);
	store.mark_texture = Render.Texture.make_from_image(Assets.MARK_TEXTURE);
	store.vehicle_colormap = Render.Texture.make_from_image(Assets.VEHICLE_COLORMAP_TEXTURE);
	Render.set_clamp(store.mark_texture, .T);

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
	store.shuriken_geometry = Render.Geometry.make_from_obj(Assets.SHURIKEN_OBJ);
	store.spirit_geometry = Render.Geometry.make_from_obj(Assets.SPIRIT_OBJ);

	
}
