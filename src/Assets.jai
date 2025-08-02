CT_File :: #import "File";
CT_STB :: #import "stb_image";
#import "Basic";

#scope_export

// Just a plain vertex shader for opengl es 3.3
PLAIN_VERTEX :: #string VERTEX
#version 330 core
#extension GL_ARB_separate_shader_objects : enable
layout(location = 0) in vec3 vmodel_pos;
layout(location = 1) in vec3 vmodel_nor;
layout(location = 2) in vec2 vtex;

layout(location = 0) out vec3 fworld_pos;
layout(location = 1) out vec3 fworld_nor;
layout(location = 2) out vec2 ftex;

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
#version 330 core
#extension GL_ARB_separate_shader_objects : enable

layout(location = 0) in vec3 fworld_pos;
layout(location = 1) in vec3 fworld_nor;
layout(location = 2) in vec2 ftex;

out vec4 outColor;

void main() {
	float d = dot(fworld_nor, vec3(0.0, 0.0, 1.0)) * 0.5 + 0.5;

	outColor = vec4(d, d, d, 1.0); // Color base
}
FRAGMENT;

TEXTURE_FRAGMENT :: #string FRAGMENT
#version 330 core
#extension GL_ARB_separate_shader_objects : enable

layout(location = 0) in vec3 fworld_pos;
layout(location = 1) in vec3 fworld_nor;
layout(location = 2) in vec2 ftex;

out vec4 outColor;

uniform sampler2D texture_sampler;

void main() {
	float d = dot(fworld_nor, vec3(0.0, 0.0, 1.0)) * 0.5 + 0.5;

	vec2 tex_size = textureSize(texture_sampler, 0);
	vec4 texture_color = texture(texture_sampler, ftex);
	outColor = vec4(
		texture_color.r * d,
		texture_color.g * d,
		texture_color.b * d,
		texture_color.a
	);
}
FRAGMENT;

CAR_OBJ :: #run CT_File.read_entire_file("assets/car.obj");

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

ICE_TEXTURE :: #run decode_image("assets/ice_texture.png");
