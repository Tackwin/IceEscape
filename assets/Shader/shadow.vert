#version 300 es
in vec3 vmodel_pos;
in vec3 vmodel_nor;
in vec2 vtex;

uniform mat4 M;
uniform mat4 V;
uniform mat4 P;

void main() {
	gl_Position = P * V * M * vec4(vmodel_pos, 1.0);
}