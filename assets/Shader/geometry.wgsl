diagnostic(off,derivative_uniformity);

struct UniformData {
	V: mat4x4<f32>,
	P: mat4x4<f32>,

	shadowV: mat4x4<f32>,
	shadowP: mat4x4<f32>,

	sun_dir: vec3f,
	shadow_pcf_count: u32,
	sun_color: vec3f,
	sun_strength: f32,

	use_shadow_map: f32,
	use_lighting: f32,

	light_bin_offset: u32,
	light_bin_count_x: u32,
	light_bin_count_y: u32,
	light_bin_min_x: f32,
	light_bin_min_y: f32,
	light_bin_max_x: f32,
	light_bin_max_y: f32,
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
	light_count: u32,
	light_index: u32,
	padding0: u32,
	padding1: u32,
};

struct VertexOutput {
	@builtin(position) Position : vec4f,
	@location(0) worldPos: vec3f,
	@location(1) worldNor: vec3f,
	@location(2) uv: vec2f,
	@interpolate(flat) @location(3) instanceIndex: u32,
};

struct Light {
	position: vec3f,
	padding0: u32,
	direction: vec3f,
	padding1: u32,
	color: vec3f,
	kind: u32, // 0 = directional, 1 = point, 2 = cone, 3 = square
	range: f32, // for point and cone, for square it's the width
	angle: f32, // for cone, for square it's the height
	intensity: f32,
	padding3: u32,
};

struct LightBin {
	lightIndices: array<u32, 16>, // 1 indexed, 0 means empty
};

@group(0) @binding(0) var<uniform> uniforms: UniformData;
@group(0) @binding(1) var<storage, read> instanceData: array<InstanceData>;
@group(0) @binding(2) var<storage, read> lights: array<Light>;
@group(0) @binding(3) var<storage, read> lightBins: array<LightBin>;

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

	var offset: vec2f = vec2f(0.5, 0.5) / 1024.0;

	for (var i: u32 = 0; i < uniforms.shadow_pcf_count; i += 1) {
		var t = 2 * 3.1415926 * f32(i) / f32(uniforms.shadow_pcf_count);
		var c = cos(t) * 2;
		var s = sin(t) * 2;
		var uv = shadowUV + vec2f(c * offset.x, s * offset.y);
		let visibility = textureSampleCompare(shadowMap, shadowSampler, uv, shadowDepth - 0.0001);
		if (visibility > 0) {
			shadow += 1.0;
		}
	}
	shadow = shadow / f32(uniforms.shadow_pcf_count);
	return max(shadow, 0.4);

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
	// return shadow;
}

fn light_intensity(use_shadow: f32, world_pos: vec3f, world_nor: vec3f) -> f32 {
	var ambient: f32 = 0.8;

	var sun_dot: f32 = -dot(uniforms.sun_dir, normalize(world_nor));
	var sun_intensity: f32 = clamp(sun_dot, 0.0, 1.0) * uniforms.sun_strength;
	var shadow: f32 = 1.0;
	if (use_shadow > 0.0 && uniforms.use_shadow_map > 0.0) {
		shadow = in_shadow(world_pos);
	}

	var intensity: f32 = 0;
	intensity += ambient * uniforms.sun_strength + shadow * sun_intensity;

	if (uniforms.use_lighting == 0.0) {
		return intensity;
	}
	var bin_x = u32(
		(f32(uniforms.light_bin_count_x) * (world_pos.x - uniforms.light_bin_min_x)) /
		(uniforms.light_bin_max_x - uniforms.light_bin_min_x)
	);
	if (bin_x >= uniforms.light_bin_count_x) {
		bin_x = uniforms.light_bin_count_x - 1;
	}
	var bin_y = u32(
		(f32(uniforms.light_bin_count_y) * (world_pos.y - uniforms.light_bin_min_y)) /
		(uniforms.light_bin_max_y - uniforms.light_bin_min_y)
	);
	if (bin_y >= uniforms.light_bin_count_y) {
		bin_y = uniforms.light_bin_count_y - 1;
	}
	var bin_index = bin_y * uniforms.light_bin_count_x + bin_x;
	var lightBin = lightBins[uniforms.light_bin_offset + bin_index];

	var maxIntensity: f32 = 0.0;
	for (var i: u32 = 0; i < 16; i += 1) {
		if (lightBin.lightIndices[i] == 0) {
			break;
		}
		var light = lights[lightBin.lightIndices[i] - 1];

		{
			var dt = world_pos - light.position;
			var dist = length(dt);
			var ldir = dt / dist;
			var attenuation = 1.0 - smoothstep(light.range * 0.95, light.range * 1.05, dist);

			if (light.kind == 1) {
				maxIntensity = max(maxIntensity, light.intensity * attenuation);
			}
			if (light.kind == 2) {
				var spotEffect = dot(ldir, light.direction);
				let treshold = cos(radians(light.angle));
				var dot = max(-dot(world_nor, ldir), 0.0) * 0.5 + 0.5;
				if (spotEffect > treshold) {
					let t = smoothstep(treshold, cos(radians(light.angle * 0.95)), spotEffect);
					maxIntensity = max(maxIntensity, light.intensity * dot * attenuation * t);
				}
			}
			if (light.kind == 3) {
				if (abs(dt.x) < light.range && abs(dt.y) < light.angle) {
					var dot = max(world_nor.z, 0.0) * 0.5 + 0.5;
					var tx = 1.0 - smoothstep(light.range - 0.2, light.range, abs(dt.x));
					var ty = 1.0 - smoothstep(light.angle - 0.2, light.angle, abs(dt.y));
					var attenuation = tx * ty;
					maxIntensity = max(maxIntensity, light.intensity * dot * attenuation);
				}
			}

			// if (light.kind == 1) {
			// 	intensity += light.color.x * max(n_dot_l, 0.0) * attenuation;
			// } else if (light.kind == 2) {
			// 	var spotEffect = dot(ldir, light.direction);
			// 	if (spotEffect > cos(radians(light.angle))) {
			// 		intensity += light.color.x * max(n_dot_l, 0.0) * attenuation * pow(spotEffect, 4.0);
			// 	}
			// }
		}
	}
	intensity += maxIntensity;

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

	if ((flags & UV_NO_TILE) > 0) {
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
	true_uv.y = 1.0 - true_uv.y;
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

	if ((flags & 4) != 0) {
		let uvx = uv.x;
		let uvy = uv.y;
		var sleft = smoothstep(0.0, 3.0 / 128.0, uvx);
		var sright = smoothstep(1.0, 1.0 - 3.0 / 128.0, uvx);
		var stop = smoothstep(0.0, 3.0 / 128.0, uvy);
		var sbottom = smoothstep(1.0, 1.0 - 3.0 / 128.0, uvy);
		var s = 1.0;
		if ((flags & 8) != 0) {
			s *= stop;
		}
		if ((flags & 16) != 0) {
			s *= sleft;
		}
		if ((flags & 32) != 0) {
			s *= sbottom;
		}
		if ((flags & 64) != 0) {
			s *= sright;
		}

		let newColor = mix(vec3(0.25), color.rgb, s);
		color.r = newColor.r;
		color.g = newColor.g;
		color.b = newColor.b;
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