#version 300 es
in vec2 pos;

out vec2 tex;

void main() {
	gl_Position = vec4(pos, 0.0, 1.0);
	tex = pos * 0.5 + vec2(0.5);
}