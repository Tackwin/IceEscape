#version 300 es
in vec3 vmodel_pos;
in vec3 vmodel_nor;
in vec2 vtex;
in mat4 M;
in vec4 texture_rec;
in vec4 color;

out vec3 fworld_pos;
out vec2 ftex;
out vec4 fcolor;

uniform mat4 V;
uniform mat4 P;

void main() {
	vec3 pos = vmodel_pos;
	pos += vmodel_nor;
	pos -= vmodel_nor;

	gl_Position = P * V * M * vec4(pos, 1.0);
	ftex = vtex;
	ftex *= texture_rec.zw;
	ftex += texture_rec.xy;
	fworld_pos = (M * vec4(pos, 1.0)).xyz;
	fcolor = color;
}