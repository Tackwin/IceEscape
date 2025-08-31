#version 300 es
precision highp float;
in vec3 vmodel_pos;
in vec3 vmodel_nor;
in vec2 vtex;
in mat4 M;
in int  tile_kind;

out vec3 fworld_pos;
out vec3 fworld_nor;
out vec2 ftex;
flat out int ftile_kind;
flat out vec2 tile_pos;

uniform mat4 V;
uniform mat4 P;

void main() {
	ftex = vtex;
	ftex.x += M[3][0];
	ftex.y += M[3][1];
	ftile_kind = tile_kind;


	fworld_pos = (M * vec4(vmodel_pos + vmodel_nor - vmodel_nor, 1.0)).xyz;

	gl_Position = P * V * vec4(fworld_pos, 1.0);
}