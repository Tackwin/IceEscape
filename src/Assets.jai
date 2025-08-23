#import "Basic";
#import "Compiler";
STB :: #import "stb_image";

#scope_export

QUAD_VERTEX :: #string VERTEX
#version 300 es
precision highp float;

in vec3 pos;
in vec4 color;

out vec4 vColor;

void main() {
	gl_Position = vec4(pos, 1.0);
	vColor = color;
}
VERTEX;

QUAD_FRAGMENT :: #string FRAGMENT
#version 300 es
precision highp float;

in vec4 vColor;

out vec4 fragColor;

void main() {
	fragColor = vColor;
}
FRAGMENT;

FONT_VERTEX :: #string VERTEX
#version 300 es
precision highp float;

in vec3 pos;
in vec3 color;
in vec2 tex;

out vec3 vColor;
out vec2 vTex;

void main() {
	gl_Position = vec4(pos, 1.0);
	vColor = color;
	vTex = tex;
}
VERTEX;

FONT_FRAGMENT :: #string FRAGMENT
#version 300 es
#extension GL_OES_standard_derivatives : enable
precision highp float;

in vec3 vColor;
in vec2 vTex;

uniform sampler2D font_sampler;

out vec4 fragColor;

void main() {
	vec4 texture_color = texture(font_sampler, vTex);

	float dist = 0.5 - texture_color.w;

	vec2 dtDist = vec2(dFdx(dist), dFdy(dist));

	float constantDist = dist / length(dtDist);

	fragColor = vec4(
		vColor.x * texture_color.x,
		vColor.y * texture_color.y,
		vColor.z * texture_color.z,
		clamp(0.5 - constantDist, 0.0, 1.0)
	);
}
FRAGMENT;

PLAIN_FRAGMENT :: #string FRAGMENT
#version 300 es
precision mediump float;

in vec3 fworld_pos;
in vec3 fworld_nor;
in vec2 ftex;

uniform vec3 tint;
out vec4 outColor;

void main() {
	float d = dot(fworld_nor, vec3(0.0, 0.0, 1.0)) * 0.5 + 0.5;

	outColor = vec4(tint * d, 1.0); // Color base
}
FRAGMENT;



TEXTURE_FRAGMENT :: #string FRAGMENT
#version 300 es
precision mediump float;

in vec3 fworld_pos;
in vec3 fworld_nor;
in vec2 ftex;

out vec4 outColor;

uniform sampler2D texture_sampler;
uniform vec3 tint;
uniform vec2 texture_offset;

void main() {
	float d = dot(fworld_nor, vec3(0.0, 0.0, 1.0)) * 0.5 + 0.5;

	vec4 texture_color = texture(texture_sampler, ftex + texture_offset);
	outColor = vec4(
		texture_color.r * d * tint.r,
		texture_color.g * d * tint.g,
		texture_color.b * d * tint.b,
		texture_color.a
	);
}
FRAGMENT;

Image :: struct {
	width: u32;
	height: u32;
	data: [] u8;
	channels: int = 3;

	make_from_memory :: (data: [] u8, channels: int) -> Image {
		image: Image;
		x: s32;
		y: s32;
		c: s32;
		image.data.data = STB.stbi_load_from_memory(
			xx data.data, xx data.count, *x, *y, *c, xx channels
		);
		image.data.count = x * y * c;
		image.width = xx x;
		image.height = xx y;
		image.channels = xx c;
		return image;
	}
}

embed_data :: (name: string, path: string, root: string) -> string {
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

#insert #run embed_data("SNOWFLAKES_AND_LIGHTS_OGG", "Snowflakes and Lights.ogg", #filepath);
#insert #run embed_data("PLAIN_VERTEX", "Shader/plain.vert", #filepath);
#insert #run embed_data("INSTANCE_VERTEX", "Shader/instance.vert", #filepath);
#insert #run embed_data("INSTANCE_FRAGMENT", "Shader/instance.frag", #filepath);
#insert #run embed_data("TILE_VERTEX", "Shader/tile.vert", #filepath);
#insert #run embed_data("TILE_FRAGMENT", "Shader/tile.frag", #filepath);
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
#insert #run embed_data("ui_atlas_png", "UI/ui_atlas.png", #filepath);

#insert #run embed_data("VEHICLE_RACER_OBJ", "vehicle-racer.obj", #filepath);
#insert #run embed_data("VEHICLE_SUV_OBJ", "vehicle-suv.obj", #filepath);
#insert #run embed_data("VEHICLE_SPEEDSTER_OBJ", "vehicle-speedster.obj", #filepath);

#insert #run embed_data("CLICK_WAV", "click.wav", #filepath);

#insert #run embed_data("FOOTSTEP_0_OGG", "footstep_snow_000-converted.ogg", #filepath);
#insert #run embed_data("FOOTSTEP_1_OGG", "footstep_snow_001.ogg", #filepath);
#insert #run embed_data("FOOTSTEP_2_OGG", "footstep_snow_002.ogg", #filepath);
#insert #run embed_data("FOOTSTEP_3_OGG", "footstep_snow_003.ogg", #filepath);
#insert #run embed_data("FOOTSTEP_4_OGG", "footstep_snow_004.ogg", #filepath);

#insert #run embed_data("LOSER_OGG", "loser.ogg", #filepath);

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
#insert #run embed_data("SHURIKEN_OBJ", "shuriken.obj", #filepath);



vehicle_colormap_texture_help :: () -> Image {
	a, b, c := #run, host -> [] u8, int, int {

		Image :: struct {
			width: u32;
			height: u32;
			data: [] u8;
		}

		decode_image :: (path: string) -> Image {
			image: Image;
			CT_File :: #import "File";
			CT_STB :: #import "stb_image";
			#import "Basic";

			file, ok := CT_File.read_entire_file(path);
			if !ok {
				print("Failed to load vehicle_colormap.png\n");
				return image;
			}

			x: s32;
			y: s32;
			c: s32;
			image.data.data = CT_STB.stbi_load_from_memory(file.data, xx file.count, *x, *y, *c, 3);
			image.data.count = x * y * 3;
			image.width = xx x;
			image.height = xx y;

			if !image.data.data {
				cstr: *u8 = CT_STB.stbi_failure_reason();
				str: string;
				str.data = cstr;
				str.count = c_style_strlen(cstr);
				print("Failed to load vehicle_colormap.png: %\n", str);
				return image;
			}

			return image;
		}
		#import "Basic";

		image := decode_image(tprint("%/../assets/vehicle_colormap.png", #filepath));
		return image.data, image.width, image.height;
	};
	return .{ width = xx b, height = xx c, data = a };
}

VEHICLE_COLORMAP_TEXTURE :: #run vehicle_colormap_texture_help();

ice_texture_help :: () -> Image {
	a, b, c := #run, host -> [] u8, int, int {

		Image :: struct {
			width: u32;
			height: u32;
			data: [] u8;
		}

		decode_image :: (path: string) -> Image {
			image: Image;
			CT_File :: #import "File";
			CT_STB :: #import "stb_image";
			#import "Basic";

			file, ok := CT_File.read_entire_file(path);
			if !ok {
				print("Failed to load ice_texture.png\n");
				return image;
			}

			x: s32;
			y: s32;
			c: s32;
			image.data.data = CT_STB.stbi_load_from_memory(file.data, xx file.count, *x, *y, *c, 3);
			image.data.count = x * y * 3;
			image.width = xx x;
			image.height = xx y;

			if !image.data.data {
				cstr: *u8 = CT_STB.stbi_failure_reason();
				str: string;
				str.data = cstr;
				str.count = c_style_strlen(cstr);
				print("Failed to load ice_texture.png: %\n", str);
				return image;
			}

			return image;
		}
		#import "Basic";

		image := decode_image(tprint("%/../assets/ice_texture.png", #filepath));
		return image.data, image.width, image.height;
	};
	return .{ width = xx b, height = xx c, data = a };
}

ICE_TEXTURE :: #run ice_texture_help();

grass_texture_help :: () -> Image {
	a, b, c := #run, host -> [] u8, int, int {

		Image :: struct {
			width: u32;
			height: u32;
			data: [] u8;
		}

		decode_image :: (path: string) -> Image {
			image: Image;
			CT_File :: #import "File";
			CT_STB :: #import "stb_image";
			#import "Basic";

			file, ok := CT_File.read_entire_file(path);
			if !ok {
				print("Failed to load ice_texture.png\n");
				return image;
			}

			x: s32;
			y: s32;
			c: s32;
			image.data.data = CT_STB.stbi_load_from_memory(file.data, xx file.count, *x, *y, *c, 3);
			image.data.count = x * y * 3;
			image.width = xx x;
			image.height = xx y;

			if !image.data.data {
				cstr: *u8 = CT_STB.stbi_failure_reason();
				str: string;
				str.data = cstr;
				str.count = c_style_strlen(cstr);
				print("Failed to load ice_texture.png: %\n", str);
				return image;
			}

			return image;
		}
		#import "Basic";

		image := decode_image(tprint("%/../assets/Elements_14-128x128.png", #filepath));
		return image.data, image.width, image.height;
	};
	return .{ width = xx b, height = xx c, data = a };
}

GRASS_TEXTURE :: #run grass_texture_help();


slippy_ice_texture_help :: () -> Image {
	a, b, c := #run, host -> [] u8, int, int {

		Image :: struct {
			width: u32;
			height: u32;
			data: [] u8;
		}

		decode_image :: (path: string) -> Image {
			image: Image;
			CT_File :: #import "File";
			CT_STB :: #import "stb_image";
			#import "Basic";

			file, ok := CT_File.read_entire_file(path);
			if !ok {
				print("Failed to load ice_texture.png\n");
				return image;
			}

			x: s32;
			y: s32;
			c: s32;
			image.data.data = CT_STB.stbi_load_from_memory(file.data, xx file.count, *x, *y, *c, 3);
			image.data.count = x * y * 3;
			image.width = xx x;
			image.height = xx y;

			if !image.data.data {
				cstr: *u8 = CT_STB.stbi_failure_reason();
				str: string;
				str.data = cstr;
				str.count = c_style_strlen(cstr);
				print("Failed to load ice_texture.png: %\n", str);
				return image;
			}

			return image;
		}
		#import "Basic";

		image := decode_image(tprint("%/../assets/Water_01.png", #filepath));
		return image.data, image.width, image.height;
	};
	return .{ width = xx b, height = xx c, data = a };
}

SLIPPY_ICE_TEXTURE :: #run slippy_ice_texture_help();


dirt_texture_help :: () -> Image {
	a, b, c := #run, host -> [] u8, int, int {

		Image :: struct {
			width: u32;
			height: u32;
			data: [] u8;
		}

		decode_image :: (path: string) -> Image {
			image: Image;
			CT_File :: #import "File";
			CT_STB :: #import "stb_image";
			#import "Basic";

			file, ok := CT_File.read_entire_file(path);
			if !ok {
				print("Failed to load ice_texture.png\n");
				return image;
			}

			x: s32;
			y: s32;
			c: s32;
			image.data.data = CT_STB.stbi_load_from_memory(file.data, xx file.count, *x, *y, *c, 3);
			image.data.count = x * y * 3;
			image.width = xx x;
			image.height = xx y;

			if !image.data.data {
				cstr: *u8 = CT_STB.stbi_failure_reason();
				str: string;
				str.data = cstr;
				str.count = c_style_strlen(cstr);
				print("Failed to load ice_texture.png: %\n", str);
				return image;
			}

			return image;
		}
		#import "Basic";

		image := decode_image(tprint("%/../assets/Dirt_01.png", #filepath));
		return image.data, image.width, image.height;
	};
	return .{ width = xx b, height = xx c, data = a };
}

DIRT_TEXTURE :: #run dirt_texture_help();

coin_texture_help :: () -> Image {
	a, b, c := #run, host -> [] u8, int, int {

		Image :: struct {
			width: u32;
			height: u32;
			data: [] u8;
		}

		decode_image :: (path: string) -> Image {
			image: Image;
			CT_File :: #import "File";
			CT_STB :: #import "stb_image";
			#import "Basic";

			file, ok := CT_File.read_entire_file(path);
			if !ok {
				print("Failed to load ice_texture.png\n");
				return image;
			}

			x: s32;
			y: s32;
			c: s32;
			image.data.data = CT_STB.stbi_load_from_memory(file.data, xx file.count, *x, *y, *c, 3);
			image.data.count = x * y * 3;
			image.width = xx x;
			image.height = xx y;

			if !image.data.data {
				cstr: *u8 = CT_STB.stbi_failure_reason();
				str: string;
				str.data = cstr;
				str.count = c_style_strlen(cstr);
				print("Failed to load ice_texture.png: %\n", str);
				return image;
			}

			return image;
		}
		#import "Basic";

		image := decode_image(tprint("%/../assets/coin_texture.png", #filepath));
		return image.data, image.width, image.height;
	};
	return .{ width = xx b, height = xx c, data = a };
}

COIN_TEXTURE :: #run coin_texture_help();

mark_texture_help :: () -> Image {
	a, b, c := #run, host -> [] u8, int, int {

		Image :: struct {
			width: u32;
			height: u32;
			data: [] u8;
		}

		decode_image :: (path: string) -> Image {
			image: Image;
			CT_File :: #import "File";
			CT_STB :: #import "stb_image";
			#import "Basic";

			file, ok := CT_File.read_entire_file(path);
			if !ok {
				print("Failed to load ice_texture.png\n");
				return image;
			}

			x: s32;
			y: s32;
			c: s32;
			image.data.data = CT_STB.stbi_load_from_memory(file.data, xx file.count, *x, *y, *c, 4);
			image.data.count = x * y * 4;
			image.width = xx x;
			image.height = xx y;

			if !image.data.data {
				cstr: *u8 = CT_STB.stbi_failure_reason();
				str: string;
				str.data = cstr;
				str.count = c_style_strlen(cstr);
				print("Failed to load ice_texture.png: %\n", str);
				return image;
			}

			return image;
		}
		#import "Basic";

		image := decode_image(tprint("%/../assets/mark.png", #filepath));
		return image.data, image.width, image.height;
	};
	return .{ width = xx b, height = xx c, data = a, channels = 4 };
}

MARK_TEXTURE :: #run mark_texture_help();


// Atlas sprite properties
Font_Sprite :: struct {
	cnameId: string;
	ctag: string;
	originX: int;
	originY: int;
	positionX: int;
	positionY: int;
	sourceWidth: int;
	sourceHeight: int;
	padding: int;
	trimmed: bool;
	trimRecX: int;
	trimRecY: int;
	trimRecWidth: int;
	trimRecHeight: int;
	colliderType: int;
	colliderPosX: int;
	colliderPosY: int;
	colliderSizeX: int;
	colliderSizeY: int;

	// Atlas contains font data
	charValue: int;
	charOffsetX: int;
	charOffsetY: int;
	charAdvanceX: int;
}

Font :: struct {
	atlas: Image;
	sprites: [] Font_Sprite;
	height: int;
}

ztotez_help :: () -> Font {
	#load "../assets/ZTOtez_regular.jai";

	a, b, c := #run, host -> [] u8, int, int {
		Image :: struct {
			width: u32;
			height: u32;
			data: [] u8;
		}

		decode_image :: (path: string) -> Image {
			image: Image;
			CT_File :: #import "File";
			CT_STB :: #import "stb_image";
			#import "Basic";

			file, ok := CT_File.read_entire_file(path);
			if !ok {
				print("Failed to load ice_texture.png\n");
				return image;
			}

			x: s32;
			y: s32;
			c: s32;
			image.data.data = CT_STB.stbi_load_from_memory(file.data, xx file.count, *x, *y, *c, 4);
			image.data.count = x * y * 4;
			image.width = xx x;
			image.height = xx y;

			if !image.data.data {
				cstr: *u8 = CT_STB.stbi_failure_reason();
				str: string;
				str.data = cstr;
				str.count = c_style_strlen(cstr);
				print("Failed to load ice_texture.png: %\n", str);
				return image;
			}

			return image;
		}
		#import "Basic";

		image := decode_image(tprint("%/../assets/ZTOtez-Regular.png", #filepath));
		return image.data, image.width, image.height;
	};
	font: Font;
	font.atlas = .{ width = xx b, height = xx c, data = a, channels = 4 };
	font.sprites = rtpDescAtlas;
	font.height = ATLAS_ATLAS_FONT_SIZE;
	return font;
}


MAIN_FONT :: #run ztotez_help();

