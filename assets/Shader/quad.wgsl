diagnostic(off,derivative_uniformity);

struct InstanceData {
	pos: vec2f,
	size: vec2f,
	texture_rect: vec4f, // x, y, width, height
	color: vec4f,
	z30sdf2: u32,
	rotation: f32,
	outline: f32,
	use_custom_texture: u32,
};

struct UniformData {
	size: vec2f,
};

struct VertexOutput {
	@builtin(position) position: vec4f,
	@location(0) uv: vec2f,
	@interpolate(flat) @location(1) instanceIndex: u32,
};


@group(0) @binding(0) var<uniform> uniforms: UniformData;
@group(0) @binding(1) var<storage, read> instanceData: array<InstanceData>;
@group(0) @binding(2) var albedoMap: texture_2d_array<f32>;
@group(0) @binding(3) var albedoSampler: sampler;
@group(0) @binding(4) var sdfMap: texture_2d_array<f32>;
@group(0) @binding(5) var sdfSampler: sampler;

@group(1) @binding(0) var customTexture: texture_2d_array<f32>;
@group(1) @binding(1) var customSampler: sampler;

@vertex fn vs(
	@builtin(vertex_index) vertexIndex : u32,
	@builtin(instance_index) instanceIndex : u32,
) -> VertexOutput {
	let pos = array(
		vec2f(0.0, 0.0),
		vec2f(1.0, 0.0),
		vec2f(1.0, 1.0),
		vec2f(0.0, 0.0),
		vec2f(1.0, 1.0),
		vec2f(0.0, 1.0),
	);

	let instance = instanceData[instanceIndex];

	var p = pos[vertexIndex] * instance.size + instance.pos;
	p = p / uniforms.size * 2.0 - 1.0;
	p.y = -p.y;

	var uv = pos[vertexIndex];
	uv = uv * instance.texture_rect.zw + instance.texture_rect.xy;

	return VertexOutput(vec4f(p, 0.0, 1.0), uv, instanceIndex);
}

fn median(r: f32, g: f32, b: f32) -> f32 {
	return max(min(r, g), min(max(r, g), b));
}
// float screenPxRange() {
//   vec2 screenTexSize =  vec2(1.0) / fwidth(v_texcoord);
//   // For very small text, screenPxRange goes below 1.0, and
//   // antialiasing will fail, but at such small sizes the text
//   // is too small for antialiasing to matter anyway
//   return max(0.5 * dot(u_unit_range, screenTexSize), 1.0);
// }
fn screenPxRange(uv: vec2f, scale: f32) -> f32 {
	var unitRange = vec2f(scale * 15.0) / 1024.0;
	var screenTexSize = vec2f(1.0) / abs(fwidth(uv));
	return max(0.5 * dot(unitRange, screenTexSize), 1.0);
}

@fragment fn fs(
	@location(0) uv: vec2f,
	@interpolate(flat) @location(1) instanceIndex: u32,
) -> @location(0) vec4f {
	let instance = instanceData[instanceIndex];

	var color = instance.color;
	if (abs(instance.texture_rect.z) > 0.0 && abs(instance.texture_rect.w) > 0.0) {
		if ((instance.z30sdf2 % 4) > 0) {
			var msd = textureSample(sdfMap, sdfSampler, uv, 0).rgb;
			var sd = median(msd.r, msd.g, msd.b);
			var width = screenPxRange(uv, 1.0);

			var d0 = clamp(width * (sd - 0.5) + 0.5, 0.0, 1.0);
			var d1 = clamp(width * (sd - 0.4) + 0.6, 0.0, 1.0);
			// Replace thoses clamp with smoothstep for crisped and narrowed edges
			// var crisp = 1.5;
			// var d0 = smoothstep(
			// 	0.5 - (0.5 / width), 0.5 + (0.5 / width), crisp * (sd - 0.5) + 0.5
			// );
			// var d1 = smoothstep(
			// 	0.475 - (0.5 / width), 0.475 + (0.5 / width), crisp * (sd - 0.5) + 0.5
			// );

			if (instance.outline > 0.5) {
				var outline_color = vec4f(0.0, 0.0, 0.0, d1 * (1.0 - d0));
				outline_color.r *= outline_color.a;
				outline_color.g *= outline_color.a;
				outline_color.b *= outline_color.a;
				var fill_color = instance.color * vec4f(1.0, 1.0, 1.0, d0);
				fill_color.r *= fill_color.a;
				fill_color.g *= fill_color.a;
				fill_color.b *= fill_color.a;
				color = outline_color + fill_color;
			} else {
				color = instance.color * vec4f(1.0, 1.0, 1.0, d0);
			}

			// if (instance.outline > 0.5) {
			// 	color = vec4f(1.0, 0.0, 0.0, d1);
			// } else {
			// 	color = instance.color * vec4f(1.0, 1.0, 1.0, d0);
			// }

		}
		else {
			if (instance.use_custom_texture > 0) {
				color = textureSample(customTexture, customSampler, uv, 0);
			} else {
				color = textureSample(albedoMap, albedoSampler, uv, 0);
			}
		}
	}

	return vec4f(color.rgb, color.a);
}