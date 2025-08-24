#version 300 es
precision highp float;

in vec3 pos;
in vec4 color;
in vec2 tex;

out vec4 vColor;
out vec2 vTex;

void main() {
	gl_Position = vec4(pos, 1.0);
	vColor = color;
	vTex = tex;
}