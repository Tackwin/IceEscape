#import "Basic";

#scope_export

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

TEXTURE_FRAGMENT :: #string FRAGMENT
#version 300 es
precision mediump float;

in vec3 fworld_pos;
in vec3 fworld_nor;
in vec2 ftex;

out vec4 outColor;

uniform sampler2D texture_sampler;
uniform vec3 tint;

void main() {
	float d = dot(fworld_nor, vec3(0.0, 0.0, 1.0)) * 0.5 + 0.5;

	vec4 texture_color = texture(texture_sampler, ftex);
	outColor = vec4(
		texture_color.r * d * tint.r,
		texture_color.g * d * tint.g,
		texture_color.b * d * tint.b,
		texture_color.a
	);
}
FRAGMENT;

CAR_OBJ :: #run,host -> string {
	#import "Basic";
	read_ct_file :: (path: string) -> string {
		CT_File :: #import "File";

		str, ok := CT_File.read_entire_file(path);
		return str;
	}

	return read_ct_file(tprint("%/../assets/car.obj", #filepath));
}
;//string;// : #run CT_File.read_entire_file("assets/car.obj");

Image :: struct {
	width: u32;
	height: u32;
	data: [] u8;
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
