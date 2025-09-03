#version 300 es
precision mediump float;

in vec3 fworld_pos;
in vec3 fworld_nor;
in vec2 ftex;

uniform sampler2D skybox;

out vec4 outColor;

void main() {
	outColor = vec4(texture(skybox, ftex).xyz, 1.0);
}