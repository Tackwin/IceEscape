diagnostic(off,derivative_uniformity);

struct InstanceData {
	pos: vec2f,
	size: vec2f,
	texture_rect: vec4f, // x, y, width, height
	color: vec4f,
	z30sdf2: u32,
	rotation: f32,
	padding1: u32,
	padding2: u32,
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
@group(0) @binding(2) var albedoMap: texture_2d<f32>;
@group(0) @binding(3) var albedoSampler: sampler;
@group(0) @binding(4) var sdfMap: texture_2d<f32>;
@group(0) @binding(5) var sdfSampler: sampler;

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

	var uv = pos[vertexIndex];
	uv = uv * instance.texture_rect.zw + instance.texture_rect.xy;

	return VertexOutput(vec4f(p, 0.0, 1.0), uv, instanceIndex);
}

@fragment fn fs(
	@location(0) uv: vec2f,
	@interpolate(flat) @location(1) instanceIndex: u32,
) -> @location(0) vec4f {
	let instance = instanceData[instanceIndex];

	var color = instance.color;
	if (instance.texture_rect.z > 0.0 && instance.texture_rect.w > 0.0) {
		if ((instance.z30sdf2 % 4) > 0) {
			var _2 = 0.70710678118; // SQRT2_DIV_2
			var d = textureSample(sdfMap, sdfSampler, uv).a;
			var s = d - 0.5;

			var v = s / fwidth( s );
			var a = clamp( v + 0.5, 0.0, 1.0 );
			color = vec4f(color.rgb, color.a * a);
		}
		else {
			color = textureSample(albedoMap, albedoSampler, uv);
		}
	}

	return vec4f(color.rgb, color.a);
}