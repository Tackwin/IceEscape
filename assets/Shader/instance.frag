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