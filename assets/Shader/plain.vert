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