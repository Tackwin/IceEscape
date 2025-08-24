#version 300 es
precision highp float;

in vec4 vColor;
in vec2 vTex;

uniform sampler2D tex;
uniform vec2 tex_size;

out vec4 fragColor;

void main() {
	fragColor = vColor * texture(tex, vTex / tex_size);
}