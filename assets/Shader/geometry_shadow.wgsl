struct UniformData {
	V: mat4x4<f32>,
	P: mat4x4<f32>,

	shadowV: mat4x4<f32>,
	shadowP: mat4x4<f32>,

	tint: vec3f,

	useAlbedoMap: u32,
	useNormalMap: u32,
	useShadowMap: u32,
	padding: u32,
};

struct InstanceData {
	M: mat4x4<f32>,
	texture_rect: vec4f, // x, y, width, height
};

struct VertexOutput {
	@builtin(position) Position : vec4f,
	@location(0) worldPos: vec3f,
	@location(1) worldNor: vec3f,
	@location(2) uv: vec2f,
};

@group(0) @binding(0) var<uniform> uniforms: UniformData;
@group(0) @binding(1) var<storage, read> instanceData: array<InstanceData>;
@group(0) @binding(2) var albedoMap: texture_2d<f32>;
@group(0) @binding(3) var normalMap: texture_2d<f32>;
@group(0) @binding(4) var shadowMap: texture_2d<f32>;
@group(0) @binding(5) var albedoSampler: sampler;
@group(0) @binding(6) var normalSampler: sampler;
@group(0) @binding(7) var shadowSampler: sampler;

@vertex fn vs(
	@builtin(vertex_index) vertexIndex : u32,
	@builtin(instance_index) instanceIndex : u32,
	@location(0) pos: vec3f,
	@location(1) normal: vec3f,
	@location(2) uv: vec2f
) -> VertexOutput {
	var output: VertexOutput;

	let model = instanceData[instanceIndex].M;
	let worldPos = (model * vec4f(pos, 1.0)).xyz;
	output.worldPos = worldPos;
	output.worldNor = (model * vec4f(normal, 0.0)).xyz;
	output.uv = uv;
	output.uv = output.uv * instanceData[instanceIndex].texture_rect.zw;
	output.uv += instanceData[instanceIndex].texture_rect.xy;

	output.Position = uniforms.P * uniforms.V * vec4f(worldPos, 1.0);
	return output;
}

@fragment fn fs(
	@location(0) worldPos: vec3f,
	@location(1) worldNor: vec3f,
	@location(2) uv: vec2f
) -> @location(0) f32 {
	var color: vec3f = vec3f(1.0, 0.0, 1.0);
	if (uniforms.useAlbedoMap > 0u) {
		color = textureSample(albedoMap, albedoSampler, uv).xyz;
	}

	var normal: vec3f = normalize(worldNor);
	if (uniforms.useNormalMap > 0u) {
		normal = textureSample(normalMap, normalSampler, uv).xyz * 2.0 - 1.0;
		normal = normalize(normal);
	}

	// Shadow mapping
	var shadow: f32 = 1.0;
	if (uniforms.useShadowMap > 0u) {
		let shadowCoord = uniforms.shadowP * uniforms.shadowV * vec4f(worldPos, 1.0);
		let shadowUV = shadowCoord.xy / shadowCoord.w * 0.5 + vec2f(0.5, 0.5);
		let shadowDepth = shadowCoord.z / shadowCoord.w;
		let shadowMapDepth = textureSample(shadowMap, shadowSampler, shadowUV).x;
		if (shadowDepth - 0.005 > shadowMapDepth) {
			shadow = 0.3;
		}
	}

	return vec4f(uniforms.tint * color, 1.0);
}