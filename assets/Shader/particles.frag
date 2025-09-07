#version 300 es
precision mediump float;

in vec3 fworld_pos;
in vec2 ftex;
in vec4 fcolor;

uniform sampler2D albedo;
uniform sampler2D shadow;

uniform mat4 shadowV;
uniform mat4 shadowP;

out vec4 outColor;

float inShadow() {
	vec4 shadow_space = shadowP * shadowV * vec4(fworld_pos, 1.0);
	vec3 shadow_coords = shadow_space.xyz / shadow_space.w;
	shadow_coords = shadow_coords * 0.5 + vec3(0.5);
	float depth = texture(shadow, shadow_coords.xy).r;
	float my_depth = shadow_coords.z;

	return my_depth < (depth + 0.5) ? 1.0 : 0.0;
}

float lightIntensity(vec3 normal) {
	float S = inShadow();

	float ambient = 0.4;

	vec3 sun_dir = normalize(vec3(-1.0, -1.0, -1.0));
	float sun_dot = -dot(sun_dir, normal);
	float sun_intensity = 0.5 * clamp(sun_dot, 0.0, 1.0);

	float intensity = 0.0;
	intensity += S * sun_intensity;
	intensity += ambient;
	return intensity;
}

void main() {
	float l = lightIntensity(vec3(0.0, 0.0, 1.0));
	vec4 color = texture(albedo, ftex);

	outColor = vec4(l * fcolor.rgb * color.rgb, fcolor.a * color.a); // Color base
}