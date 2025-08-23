#import "Basic";

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

// Just a plain vertex shader for opengl es 3.3
PLAIN_VERTEX :: #string VERTEX
#version 300 es
in vec3 vmodel_pos;
in vec3 vmodel_nor;
in vec2 vtex;

out vec3 fworld_pos;
out vec3 fworld_nor;
out vec2 ftex;

uniform mat4 M;
uniform mat4 V;
uniform mat4 P;

void main() {
	gl_Position = P * V * M * vec4(vmodel_pos, 1.0);
	ftex = vtex;
	ftex.y = 1.0 - ftex.y;
	fworld_pos = (M * vec4(vmodel_pos, 1.0)).xyz;
	fworld_nor = normalize((M * vec4(vmodel_nor, 0.0)).xyz);
}
VERTEX;
INSTANCED_VERTEX :: #string VERTEX
#version 300 es
in vec3 vmodel_pos;
in vec3 vmodel_nor;
in vec2 vtex;
in mat4 M;

out vec3 fworld_pos;
out vec3 fworld_nor;
out vec2 ftex;

uniform mat4 V;
uniform mat4 P;

void main() {
	gl_Position = P * V * M * vec4(vmodel_pos, 1.0);
	ftex = vtex;
	ftex.y = 1.0 - ftex.y;
	fworld_pos = (M * vec4(vmodel_pos, 1.0)).xyz;
	fworld_nor = normalize((M * vec4(vmodel_nor, 0.0)).xyz);
}
VERTEX;

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

TILE_VERTEX :: #string VERTEX
#version 300 es
in vec3 vmodel_pos;
in vec3 vmodel_nor;
in vec2 vtex;
in mat4 M;
in int  tile_kind;

out vec3 fworld_pos;
out vec3 fworld_nor;
out vec2 ftex;
flat out int  ftile_kind;

uniform mat4 V;
uniform mat4 P;

void main() {
	gl_Position = P * V * M * vec4(vmodel_pos, 1.0);
	ftex = vtex;
	ftex.y = 1.0 - ftex.y;
	fworld_pos = (M * vec4(vmodel_pos, 1.0)).xyz;
	fworld_nor = normalize((M * vec4(vmodel_nor, 0.0)).xyz);
	ftile_kind = tile_kind;
}
VERTEX;

TILE_FRAGMENT :: #string FRAGMENT
#version 300 es
precision mediump float;

in vec3 fworld_pos;
in vec3 fworld_nor;
in vec2 ftex;
flat in int  ftile_kind;

out vec4 outColor;

uniform sampler2D samplers[16];

void main() {
	float d = dot(fworld_nor, vec3(0.0, 0.0, 1.0)) * 0.5 + 0.5;

	// What a stupid restriction...
	vec4 texture_color = vec4(1.0);
	if (ftile_kind == 0)
		texture_color = texture(samplers[0], ftex);
	else if (ftile_kind == 1)
		texture_color = texture(samplers[1], ftex);
	else if (ftile_kind == 2)
		texture_color = texture(samplers[2], ftex);
	else if (ftile_kind == 3)
		texture_color = texture(samplers[3], ftex);
	else if (ftile_kind == 4)
		texture_color = texture(samplers[4], ftex);
	else if (ftile_kind == 5)
		texture_color = texture(samplers[5], ftex);
	else if (ftile_kind == 6)
		texture_color = texture(samplers[6], ftex);
	else if (ftile_kind == 7)
		texture_color = texture(samplers[7], ftex);

	outColor = vec4(
		texture_color.r * d,
		texture_color.g * d,
		texture_color.b * d,
		texture_color.a
	);
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

CLICK_WAV :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {{
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
		
	}
	}

	return read_ct_file(tprint("%/../assets/click.wav", #filepath));
}
SNOWFLAKES_AND_LIGHTS_OGG :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {{
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);

		if !ok {
			print("Failed to read file: %\n", path);
		}
		return str;
		
	}
	}

	return read_ct_file(tprint("%/../assets/Snowflakes and Lights.ogg", #filepath));
}

FOOTSTEP_0_OGG :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {{
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);

		if !ok {
			print("Failed to read file: %\n", path);
		}
		return str;
		
	}
	}

	return read_ct_file(tprint("%/../assets/footstep_snow_000-converted.ogg", #filepath));
}

FOOTSTEP_1_OGG :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {{
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
		
	}
	}

	return read_ct_file(tprint("%/../assets/footstep_snow_001.ogg", #filepath));
}

FOOTSTEP_2_OGG :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {{
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
		
	}
	}

	return read_ct_file(tprint("%/../assets/footstep_snow_002.ogg", #filepath));
}

FOOTSTEP_3_OGG :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {{
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
		
	}
	}

	return read_ct_file(tprint("%/../assets/footstep_snow_003.ogg", #filepath));
}

FOOTSTEP_4_OGG :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {{
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
		
	}
	}

	return read_ct_file(tprint("%/../assets/footstep_snow_004.ogg", #filepath));
}

LOSER_OGG :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {{
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
		
	}
	}

	return read_ct_file(tprint("%/../assets/loser.ogg", #filepath));
};

CAR_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {{
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
		
	}
	}

	return read_ct_file(tprint("%/../assets/car.obj", #filepath));
};

TOMBSTONE_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
	}

	return read_ct_file(tprint("%/../assets/tombstone.obj", #filepath));
};

SKULL_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
	}

	return read_ct_file(tprint("%/../assets/skull.obj", #filepath));
};

COIN_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
	}

	return read_ct_file(tprint("%/../assets/coin.obj", #filepath));
};

SPIRIT_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
	}

	return read_ct_file(tprint("%/../assets/spirit.obj", #filepath));
};

KEY_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
	}

	return read_ct_file(tprint("%/../assets/key.obj", #filepath));
};

MARK_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
	}

	return read_ct_file(tprint("%/../assets/mark.obj", #filepath));
};

GATE_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
	}

	return read_ct_file(tprint("%/../assets/gate.obj", #filepath));
};

GATE_CLOSE_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
	}

	return read_ct_file(tprint("%/../assets/gate_close.obj", #filepath));
};

SHURIKEN_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
	}

	return read_ct_file(tprint("%/../assets/shuriken.obj", #filepath));
};

VEHICLE_RACER_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		if !ok {
			print("Could not read vehicle-racer.obj\n");
		}
		return str;
	}

	return read_ct_file(tprint("%/../assets/vehicle-racer.obj", #filepath));
};
VEHICLE_SUV_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		if !ok {
			print("Could not read vehicle-suv.obj\n");
		}
		return str;
	}

	return read_ct_file(tprint("%/../assets/vehicle-suv.obj", #filepath));
};
VEHICLE_SPEEDSTER_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		if !ok {
			print("Could not read vehicle-speedster.obj\n");
		}
		return str;
	}

	return read_ct_file(tprint("%/../assets/vehicle-speedster.obj", #filepath));
};

Image :: struct {
	width: u32;
	height: u32;
	data: [] u8;
	has_alpha := false;
}

decode_image :: (path: string) -> Image {
	image: Image;

	file, ok := CT_File.read_entire_file(path,, temp);
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

		image := decode_image(tprint("%/../assets/grass_texture.png", #filepath));
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

		image := decode_image(tprint("%/../assets/slippy_ice_texture.png", #filepath));
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

		image := decode_image(tprint("%/../assets/dirt_texture.png", #filepath));
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
	return .{ width = xx b, height = xx c, data = a, has_alpha = true };
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
	font.atlas = .{ width = xx b, height = xx c, data = a, has_alpha = true };
	font.sprites = rtpDescAtlas;
	font.height = ATLAS_ATLAS_FONT_SIZE;
	return font;
}


MAIN_FONT :: #run ztotez_help();

