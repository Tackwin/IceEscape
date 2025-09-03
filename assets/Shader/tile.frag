#version 300 es
#extension GL_OES_standard_derivatives : enable
precision highp float;

in vec3 fworld_pos;
in vec3 fworld_nor;
in vec2 ftex;
flat in int ftile_kind;
flat in vec2 tile_pos;

out vec4 outColor;

uniform vec3 playerPos;
uniform sampler2D atlas;

uniform sampler2D shadow;
uniform mat4 shadowV;
uniform mat4 shadowP;

vec4 hash4( vec2 p ) { return fract(sin(vec4( 1.0+dot(p,vec2(37.0,17.0)), 
                                              2.0+dot(p,vec2(11.0,47.0)),
                                              3.0+dot(p,vec2(41.0,29.0)),
                                              4.0+dot(p,vec2(23.0,31.0))))*103.0); }

vec2 kind_to_atlas_pos(int kind) {
	const int Ice = 1;
	const int Grass = 2;
	const int Slippy_Ice = 3;
	const int Dirt = 4;

	if (kind == Ice) {
		return vec2(0.0, 4.0 / 8.0);
	}
	if (kind == Grass) {
		return vec2(0.0, 0.0 / 8.0);
	}
	if (kind == Slippy_Ice) {
		return vec2(0.0, 1.0 / 8.0);
	}
	if (kind == Dirt) {
		return vec2(0.0, 2.0 / 8.0);
	}
	return vec2(0.0);
}


vec2 get_tiled_uv(vec2 atlas_uv) {
	vec2 tiled_uv = atlas_uv;
	// Atlas_uv is a [0, 1] range uv coordinate into a 8*8 atlas of 128*128 textures.
	// avoid edge bleeding...
	tiled_uv *= 1.0 - 1.0 / 128.0;
	tiled_uv += 0.5 / 128.0;
	tiled_uv = tiled_uv / vec2(8.0, 8.0);

	tiled_uv += kind_to_atlas_pos(ftile_kind);
	return tiled_uv;
}

float sum( vec3 v ) { return v.x+v.y+v.z; }

vec4 scaledTextureGrad(sampler2D samp, in vec2 uv, in vec2 ddx, in vec2 ddy, float normal, vec2 s)
{
	ivec2 iuv = ivec2( floor( uv ) );
	vec2 fuv = fract( uv );
	fuv = get_tiled_uv(fuv);
	fuv += vec2(iuv);

    vec4 col = textureGrad(samp, fuv + vec2(normal / 8.0, 0.0), 8.0 * ddx, 8.0 * ddy);
	if (true && normal > 0.0) {
		if (s.x > 0.0)
			col.x = 1.0 - col.x;
		if (s.y > 0.0)
			col.y = 1.0 - col.y;
	}
    return vec4(col.rgb, 1.0);
}

vec4 textureNoTile( sampler2D samp, in vec2 uv, float normal)
{
    ivec2 iuv = ivec2( floor( uv ) );
    vec2 fuv = fract( uv );

    // generate per-tile transform
    vec4 ofa = hash4(vec2(iuv + ivec2(0,0)));
    vec4 ofb = hash4(vec2(iuv + ivec2(1,0)));
    vec4 ofc = hash4(vec2(iuv + ivec2(0,1)));
    vec4 ofd = hash4(vec2(iuv + ivec2(1,1)));
    
    vec2 ddx = dFdx( uv );
    vec2 ddy = dFdy( uv );

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
    
    return mix( mix( scaledTextureGrad( samp, uva, ddxa, ddya, normal, ofa.zw ),
                     scaledTextureGrad( samp, uvb, ddxb, ddyb, normal, ofb.zw ), b.x ),
                mix( scaledTextureGrad( samp, uvc, ddxc, ddyc, normal, ofc.zw ),
                     scaledTextureGrad( samp, uvd, ddxd, ddyd, normal, ofd.zw ), b.x), b.y );
}

float inShadow() {
	vec4 shadow_space = shadowP * shadowV * vec4(fworld_pos, 1.0);
	vec3 shadow_coords = shadow_space.xyz / shadow_space.w;
	shadow_coords = shadow_coords * 0.5 + vec3(0.5);

	float sum = 0.0;

	vec2 texel_size = vec2(0.5 / 4096.0);
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float depth = texture(shadow, shadow_coords.xy + texel_size * vec2(x, y)).r;
			float my_depth = shadow_coords.z;

			// sum += my_depth < depth ? 1.0 : 0.0;
			sum += (my_depth < depth ? 1.0 : 0.0);// + smoothstep(0.0, 0.007d5, my_depth - depth);
		}
	}
	return sum / 25.0;
}

float lightIntensity(vec3 normal) {
	float S = inShadow();

	float ambient = 0.4;

	vec3 sun_dir = normalize(vec3(-1.0, -1.0, -1.0));
	float sun_dot = -dot(sun_dir, normal);
	float sun_intensity = 0.5 * clamp(sun_dot, 0.0, 1.0);

	vec3 player_light_pos = playerPos + vec3(0.0, 0.0, 1.0);
	vec3 player_dir = normalize(fworld_pos - player_light_pos);
	float player_dot = -dot(player_dir, normal);
	float player_distance = length(fworld_pos - player_light_pos);
	float player_intensity = 0.5 * clamp(player_dot, 0.0, 1.0) / (1.0 + player_distance * player_distance);

	float intensity = 0.0;
	intensity += S * sun_intensity;
	intensity += player_intensity;
	intensity += ambient;
	return intensity;
}

void main() {
	vec4 albedo = textureNoTile(atlas, ftex, 0.0);
	vec3 normal = textureNoTile(atlas, ftex, 1.0).xyz * 2.0 - vec3(1.0);

	float I = lightIntensity(normal);

	if (true) {
		outColor = vec4(
			albedo.r * I,
			albedo.g * I,
			albedo.b * I,
			1.0
		);
	} else {
		outColor = vec4(
			normal,
			1.0
		);
	}
}