#version 300 es
precision highp float;

in vec2 tex;

uniform sampler2D hdr;
uniform sampler2D shadow;

uniform vec2 hdr_size;
uniform vec2 viewport_size;

uniform int debug_view;

const int DEBUG_VIEW_NONE = 0;
const int DEBUG_VIEW_SHADOW = 1;

out vec4 fragColor;
float startCompression = 0.8 - 0.04;
float desaturation = 0.15;

vec3 CommerceToneMapping( vec3 color ) {
	float x = min(color.r, min(color.g, color.b));
	float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
	color -= offset;

	float peak = max(color.r, max(color.g, color.b));
	if (peak < startCompression) return color;

	float d = 1. - startCompression;
	float newPeak = 1. - d * d / (peak + d - startCompression);
	color *= newPeak / peak;

	float g = 1. - 1. / (desaturation * (peak - newPeak) + 1.);
	return mix(color, newPeak * vec3(1, 1, 1), g);
}
vec3 tone_mapping(vec3 hdr_color) {
	vec3 mapped = hdr_color / (hdr_color + vec3(5.0));
	return mapped;
}

vec3 debug_view_none() {
	vec2 uv = tex * viewport_size / hdr_size;
	vec3 hdr_color = texture(hdr, uv).rgb;
	vec3 mapped_color = CommerceToneMapping(hdr_color);
	return mapped_color;
}

vec3 debug_view_shadow() {
	return vec3(texture(shadow, tex).r);
}

void main() {
	vec3 color;

	if (debug_view == DEBUG_VIEW_NONE) {
		color = debug_view_none();
	} else if (debug_view == DEBUG_VIEW_SHADOW) {
		color = debug_view_shadow();
	}

	fragColor = vec4(color, 1.0);
}