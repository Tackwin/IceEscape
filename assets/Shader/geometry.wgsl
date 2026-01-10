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
	albedo16normal16indices: u32,
	useShadowMap: u32,
	fadeout_z: f32,
	flags: u32,
	uv_offset: vec2f,
	color: vec4f,
	color_overlay: vec4f,
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

@group(1) @binding(0) var albedoMap: texture_2d_array<f32>;
@group(1) @binding(1) var normalMap: texture_2d_array<f32>;
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
	output.uv = uv + instanceData[instanceIndex].uv_offset;
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


fn hash4(p: vec2f) -> vec4f {
	return fract(sin(vec4f(1.0 + dot(p,vec2f(37.0,17.0)),
						   2.0 + dot(p,vec2f(11.0,47.0)),
						   3.0 + dot(p,vec2f(41.0,29.0)),
						   4.0 + dot(p,vec2f(23.0,31.0))
			)
		) * 103.0
	);
}
fn textureNoTile(
	t: texture_2d_array<f32>,
	samp: sampler,
	idx: u32,
	uv: vec2f
) -> vec4f
{
	let iuv = floor(uv);
	let fuv = fract(uv);

	// generate per-tile transform
	var ofa = hash4(iuv + vec2f(0,0));
	var ofb = hash4(iuv + vec2f(1,0));
	var ofc = hash4(iuv + vec2f(0,1));
	var ofd = hash4(iuv + vec2f(1,1));
	
	let ddx = dpdx( uv );
	let ddy = dpdy( uv );

	// transform per-tile uvs
	ofa.z = sign( ofa.z-0.5 );
	ofa.w = sign( ofa.w-0.5 );

	ofb.z = sign( ofb.z-0.5 );
	ofb.w = sign( ofb.w-0.5 );

	ofc.z = sign( ofc.z-0.5 );
	ofc.w = sign( ofc.w-0.5 );

	ofd.z = sign( ofd.z-0.5 );
	ofd.w = sign( ofd.w-0.5 );
	
	// uv's, and derivatives (for correct mipmapping)
	let uva = uv*ofa.zw + ofa.xy;
	let ddxa = ddx*ofa.zw;
	let ddya = ddy*ofa.zw;

	let uvb = uv*ofb.zw + ofb.xy;
	let ddxb = ddx*ofb.zw;
	let ddyb = ddy*ofb.zw;

	let uvc = uv*ofc.zw + ofc.xy;
	let ddxc = ddx*ofc.zw;
	let ddyc = ddy*ofc.zw;

	let uvd = uv*ofd.zw + ofd.xy;
	let ddxd = ddx*ofd.zw;
	let ddyd = ddy*ofd.zw;

	// fetch and blend
	let b = smoothstep(vec2f(0.25, 0.25), vec2f(0.75, 0.75), fuv);
	
	return mix(mix(textureSampleGrad(t, samp, uva, idx, ddxa, ddya),
	               textureSampleGrad(t, samp, uvb, idx, ddxb, ddyb), b.x),
	           mix(textureSampleGrad(t, samp, uvc, idx, ddxc, ddyc),
	               textureSampleGrad(t, samp, uvd, idx, ddxd, ddyd), b.x), b.y);
}

fn flaggedSample(
	map: texture_2d_array<f32>, samp: sampler, uv: vec2f, idx: u32, flags: u32
) -> vec4f {
	let UV_NO_TILE = u32(2);

	if (flags & UV_NO_TILE) > 0 {
		return textureNoTile(map, samp, idx, uv);
	} else {
		return textureSample(map, samp, uv, idx);
	}
	return vec4f();
}

@fragment fn fs(
	@location(0) worldPos: vec3f,
	@location(1) worldNor: vec3f,
	@location(2) uv: vec2f,
	@interpolate(flat) @location(3) instanceIndex: u32
) -> @location(0) vec4f {
	var true_uv = uv;
	let albedoIdx = instanceData[instanceIndex].albedo16normal16indices & 0xFFFF;
	let normalIdx = instanceData[instanceIndex].albedo16normal16indices >> 16;
	let flags = instanceData[instanceIndex].flags;

	if ((flags & 1) != 0) {
		// UV_REPEAT
		var wrapped_uv = vec2f(
			true_uv.x - floor(true_uv.x),
			true_uv.y - floor(true_uv.y)
		);
		true_uv = wrapped_uv;
	}
	true_uv = true_uv * instanceData[instanceIndex].texture_rect.zw;
	true_uv += instanceData[instanceIndex].texture_rect.xy;

	// let shadowCoord = uniforms.shadowP * uniforms.shadowV * vec4f(worldPos, 1.0);
	// let shadowUV = shadowCoord.xy * 0.5 + vec2f(0.5, 0.5);
	// return vec4f(shadowUV, shadowCoord.z / shadowCoord.w, 1.0);

	var color: vec4f = vec4f(1.0, 0.0, 1.0, 1.0);
	if (albedoIdx < textureNumLayers(albedoMap)) {
		color = flaggedSample(albedoMap, albedoSampler, true_uv, albedoIdx, flags);
	}

	var alpha = color.w;

	if (instanceData[instanceIndex].fadeout_z > 0.0) {
		var fade_start: f32 = instanceData[instanceIndex].fadeout_z - 1.0;
		var fade_end: f32 = instanceData[instanceIndex].fadeout_z;
		var fade_factor: f32 = clamp((fade_end - worldPos.z) / 1.0, 0.0, 1.0);
		alpha = alpha * fade_factor;
	}

	if (alpha < 0.05) {
		discard;
	}

	var normal: vec3f = normalize(worldNor);
	if (normalIdx < textureNumLayers(albedoMap)) {
		normal = flaggedSample(normalMap, normalSampler, true_uv, normalIdx, flags).rgb * 2.0 - vec3f(1.0);
		normal = normalize(normal);
	}

	// Shadow mapping
	var light: f32 = light_intensity(
		f32(instanceData[instanceIndex].useShadowMap), worldPos, normal
	);
	return vec4f(
		light * instanceData[instanceIndex].color.xyz * color.xyz / alpha,
		instanceData[instanceIndex].color.w * alpha
	);
}