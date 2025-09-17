diagnostic(off,derivative_uniformity);

struct UniformData {
	size: vec2f,
	exposure: f32,
	gamma: f32,
};

struct VertexOutput {
	@builtin(position) position: vec4f,
	@location(0) uv: vec2f,
};


@group(0) @binding(0) var<uniform> uniforms: UniformData;
@group(0) @binding(1) var albedoMap: texture_multisampled_2d<f32>;

@vertex fn vs(
	@builtin(vertex_index) vertexIndex : u32
) -> VertexOutput {
	let pos = array(
		vec2f(-1.0, -1.0),
		vec2f( 1.0, -1.0),
		vec2f( 1.0,  1.0),
		vec2f(-1.0, -1.0),
		vec2f( 1.0,  1.0),
		vec2f(-1.0,  1.0),
	);

	return VertexOutput(
		vec4f(pos[vertexIndex], 0.0, 1.0),
		vec2f(pos[vertexIndex] * 0.5 + 0.5)
	);
}

fn CommerceToneMapping(ccolor: vec3f) -> vec3f {
	var color = ccolor;

	let startCompression: f32 = 0.8 - 0.04;
	let desaturation: f32 = 0.15;

	var x: f32 = min(color.r, min(color.g, color.b));
	var offset: f32 = 0.04;
	if (x < 0.08) {
		offset = x - 6.25 * x * x;
	}
	color -= vec3f(offset);

	var peak: f32 = max(color.r, max(color.g, color.b));
	if (peak < startCompression) {
		return color;
	}

	var d: f32 = 1.0 - startCompression;
	var newPeak: f32 = 1.0 - d * d / (peak + d - startCompression);

	color *= newPeak / peak;

	var g: f32 = 1.0 - 1.0 / (desaturation * (peak - newPeak) + 1.0);
	return mix(color, newPeak * vec3f(1.0), vec3f(g));
}

fn sampleTexture(uv: vec2f) -> vec4f {
	var pos: vec2<u32> = vec2<u32>(uv * uniforms.size);

	var sum: vec4f = vec4f(0.0);
	sum += textureLoad(albedoMap, pos, 0);
	sum += textureLoad(albedoMap, pos, 1);
	sum += textureLoad(albedoMap, pos, 2);
	sum += textureLoad(albedoMap, pos, 3);

	return sum / 4.0;
}

@fragment fn fs(
	@location(0) uv: vec2f
) -> @location(0) vec4f {

	var uuv = uv;
	uuv.y = 1.0 - uv.y;

	let color = sampleTexture(uuv);
	let mapped = CommerceToneMapping(color.rgb);
	let gamma_corrected = pow(mapped, vec3f(1.0 / uniforms.gamma));
	return vec4f(mapped, 1.0);
}