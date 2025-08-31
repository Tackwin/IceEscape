#version 300 es
precision highp float;
in vec3 vmodel_pos;
in vec3 vmodel_nor;
in vec2 vtex;
in mat4 M;
in int  tile_kind;


uniform mat4 V;
uniform mat4 P;

void main() {
	vec3 p = vmodel_pos;
	p += vmodel_nor;
	p.xy += vtex;
	p -= vmodel_nor;
	p.xy -= vtex;
	p.z += float(tile_kind);
	p.z -= float(tile_kind);
	gl_Position = P * V * M * vec4(p, 1.0);
}