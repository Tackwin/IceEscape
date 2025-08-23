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

uniform float useHeight;
uniform float useNormal;

uniform float heightRange;

uniform sampler2D albedos[5];
uniform sampler2D normals[5];
uniform sampler2D heights[5];
vec4 hash4( vec2 p ) { return fract(sin(vec4( 1.0+dot(p,vec2(37.0,17.0)), 
                                              2.0+dot(p,vec2(11.0,47.0)),
                                              3.0+dot(p,vec2(41.0,29.0)),
                                              4.0+dot(p,vec2(23.0,31.0))))*103.0); }

vec4 textureNoTile( sampler2D samp, in vec2 uv )
{
	ivec2 iuv = ivec2( floor( uv ) );
	vec2 fuv = fract( uv );

	// generate per-tile transform
	vec4 ofa = hash4( vec2(iuv + ivec2(0,0)) );
	vec4 ofb = hash4( vec2(iuv + ivec2(1,0)) );
	vec4 ofc = hash4( vec2(iuv + ivec2(0,1)) );
	vec4 ofd = hash4( vec2(iuv + ivec2(1,1)) );
	
	vec2 ddx = vec2(1.0, 0.0);
	vec2 ddy = vec2(0.0, 1.0);

	// transform per-tile uvs
	ofa.zw = sign( ofa.zw-0.5 );
	ofb.zw = sign( ofb.zw-0.5 );
	ofc.zw = sign( ofc.zw-0.5 );
	ofd.zw = sign( ofd.zw-0.5 );
	
	// uv's, and derivatives (for correct mipmapping)
	vec2 uva = uv*ofa.zw + ofa.xy, ddxa = ddx*ofa.zw, ddya = ddy*ofa.zw;
	vec2 uvb = uv*ofb.zw + ofb.xy, ddxb = ddx*ofb.zw, ddyb = ddy*ofb.zw;
	vec2 uvc = uv*ofc.zw + ofc.xy, ddxc = ddx*ofc.zw, ddyc = ddy*ofc.zw;
	vec2 uvd = uv*ofd.zw + ofd.xy, ddxd = ddx*ofd.zw, ddyd = ddy*ofd.zw;
	
	// fetch and blend
	vec2 b = smoothstep( 0.25,0.75, fuv );
	
	return mix( mix( textureGrad( samp, uva, ddxa, ddya ),
					textureGrad( samp, uvb, ddxb, ddyb ), b.x ),
				mix( textureGrad( samp, uvc, ddxc, ddyc ),
					textureGrad( samp, uvd, ddxd, ddyd ), b.x), b.y );
}
float getHeight(int index, vec2 uv) {
	if (index == 0)
		return textureNoTile(heights[0], uv).r;
	else if (index == 1)
		return textureNoTile(heights[1], uv).r;
	else if (index == 2)
		return textureNoTile(heights[2], uv).r;
	else if (index == 3)
		return textureNoTile(heights[3], uv).r;
	else if (index == 4)
		return textureNoTile(heights[4], uv).r;
	return 0.0;
}

vec3 _getNormal(int index, vec2 uv) {
	if (index == 0)
		return textureNoTile(normals[0], fract(uv)).xyz;
	else if (index == 1)
		return textureNoTile(normals[1], fract(uv)).xyz;
	else if (index == 2)
		return textureNoTile(normals[2], fract(uv)).xyz;
	else if (index == 3)
		return textureNoTile(normals[3], fract(uv)).xyz;
	else if (index == 4)
		return textureNoTile(normals[4], fract(uv)).xyz;
	return vec3(0.0);
}
vec3 getNormal(int index, vec2 uv) {
	vec3 n = _getNormal(index, uv);
	n = n * 2.0 - vec3(1.0);
	return n;
}

uniform mat4 V;
uniform mat4 P;

void main() {
	ftex = vtex;
	ftex.y = 1.0 - ftex.y;
	ftex.x += M[3][0];
	ftex.y += M[3][1];
	ftile_kind = tile_kind;

	float height = 0.5;
	if (useHeight > 0.0)
		height = getHeight(tile_kind, ftex);
	height *= heightRange;

	vec3 model_nor = vmodel_nor;
	if (useNormal > 0.0)
		model_nor = getNormal(tile_kind, ftex);

	fworld_pos = (M * vec4(vmodel_pos + model_nor * height, 1.0)).xyz;
	fworld_nor = normalize((M * vec4(model_nor, 0.0)).xyz);

	gl_Position = P * V * vec4(fworld_pos, 1.0);
}