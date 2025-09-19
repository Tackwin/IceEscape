diagnostic(off,derivative_uniformity);

struct UniformData {
	V: mat4x4<f32>,
	P: mat4x4<f32>,

	shadowV: mat4x4<f32>,
	shadowP: mat4x4<f32>,

	sun_dir: vec3f,
	padding2: f32,
	sun_color: vec3f,
	sun_strength: f32,
};

struct InstanceData {
	M: mat4x4<f32>,
	texture_rect: vec4f, // x, y, width, height
	useAlbedoMap: u32,
	useNormalMap: u32,
	useShadowMap: u32,
	padding: u32,
	color: vec4f,
};

struct VertexOutput {
	@builtin(position) Position : vec4f,
	@location(0) worldPos: vec3f,
	@location(1) worldNor: vec3f,
	@location(2) uv: vec2f,
	@interpolate(flat) @location(3) instanceIndex: u32,
};

@group(0) @binding(0) var<uniform> uniforms: UniformData;
@group(0) @binding(1) var<storage, read> instanceData: array<InstanceData>;

@group(1) @binding(0) var albedoMap: texture_2d<f32>;
@group(1) @binding(1) var normalMap: texture_2d<f32>;
@group(1) @binding(2) var shadowMap: texture_depth_2d;
@group(1) @binding(3) var albedoSampler: sampler;
@group(1) @binding(4) var normalSampler: sampler;
@group(1) @binding(5) var shadowSampler: sampler_comparison;

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
	output.instanceIndex = instanceIndex;
	output.Position = uniforms.P * uniforms.V * vec4f(worldPos, 1.0);
	return output;
}

fn in_shadow(world_pos: vec3f) -> f32 {
	var shadow: f32 = 0.0;
	let shadowCoord = uniforms.shadowP * uniforms.shadowV * vec4f(world_pos, 1.0);
	var shadowUV = shadowCoord.xy * 0.5 + vec2f(0.5, 0.5);
	shadowUV.y = 1.0 - shadowUV.y;
	let shadowDepth = shadowCoord.z / shadowCoord.w;

	var offset: vec2f = vec2f(0.5, 0.5) / 4096.0;

	for (var i: i32 = -2; i <= 2; i = i + 1) {
		for (var j: i32 = -2; j <= 2; j = j + 1) {
			var uv = shadowUV + vec2f(f32(i) * offset.x,  f32(j) * offset.y);
			let visibility = textureSampleCompare(shadowMap, shadowSampler, uv, shadowDepth - 0.0001);
			if (visibility > 0) {
				shadow += 1.0;
			}
		}
	}
	shadow = shadow / 25.0;

	// var uvB = shadowUV + vec2f( offset.x, -offset.y);
	// var uvC = shadowUV + vec2f(-offset.x,  offset.y);
	// var uvD = shadowUV + vec2f(-offset.x, -offset.y);

	// let visibility0 = textureSampleCompare(shadowMap, shadowSampler, shadowUV, shadowDepth);
	// let visibilityA = textureSampleCompare(shadowMap, shadowSampler, uvA, shadowDepth - 0.0001);
	// let visibilityB = textureSampleCompare(shadowMap, shadowSampler, uvB, shadowDepth - 0.0001);
	// let visibilityC = textureSampleCompare(shadowMap, shadowSampler, uvC, shadowDepth - 0.0001);
	// let visibilityD = textureSampleCompare(shadowMap, shadowSampler, uvD, shadowDepth - 0.0001);

	// if (visibility0 > 0) {
	// 	shadow += 1.0;
	// }
	// if (visibilityA > 0) {
	// 	shadow += 1.0;
	// }
	// if (visibilityB > 0) {
	// 	shadow += 1.0;
	// }
	// if (visibilityC > 0) {
	// 	shadow += 1.0;
	// }
	// if (visibilityD > 0) {
	// 	shadow += 1.0;
	// }
	// shadow = shadow / 5.0;
	return shadow;
}

fn light_intensity(use_shadow: f32, world_pos: vec3f, world_nor: vec3f) -> f32 {
	var ambient: f32 = 0.4;

	var sun_dot: f32 = -dot(uniforms.sun_dir, normalize(world_nor));
	var sun_intensity: f32 = clamp(sun_dot, 0.0, 1.0) * uniforms.sun_strength;
	var shadow: f32 = 1.0;
	if (use_shadow > 0.0) {
		shadow = in_shadow(world_pos);
	}

	var intensity: f32 = 0;
	intensity += ambient;
	intensity += shadow * sun_intensity;
	return intensity;
}

@fragment fn fs(
	@location(0) worldPos: vec3f,
	@location(1) worldNor: vec3f,
	@location(2) uv: vec2f,
	@interpolate(flat) @location(3) instanceIndex: u32
) -> @location(0) vec4f {
	// let shadowCoord = uniforms.shadowP * uniforms.shadowV * vec4f(worldPos, 1.0);
	// let shadowUV = shadowCoord.xy * 0.5 + vec2f(0.5, 0.5);
	// return vec4f(shadowUV, shadowCoord.z / shadowCoord.w, 1.0);

	var color: vec4f = vec4f(1.0, 0.0, 1.0, 1.0);
	if (instanceData[instanceIndex].useAlbedoMap > 0u) {
		color = textureSample(albedoMap, albedoSampler, uv);
	}

	var normal: vec3f = normalize(worldNor);
	if (instanceData[instanceIndex].useNormalMap > 0u) {
		normal = textureSample(normalMap, normalSampler, uv).xyz * 2.0 - 1.0;
		normal = normalize(normal);
	}

	// Shadow mapping

	var light: f32 = light_intensity(f32(instanceData[instanceIndex].useShadowMap), worldPos, normal);
	return vec4f(
		light * instanceData[instanceIndex].color.xyz * color.xyz / color.w,
		instanceData[instanceIndex].color.w * color.w
	);
}