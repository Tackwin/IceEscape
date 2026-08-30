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
@group(0) @binding(1) var albedoMap: texture_2d<f32>;
@group(0) @binding(2) var uiMap: texture_2d<f32>;
@group(0) @binding(3) var albedoSampler: sampler;

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

	let clip = pos[vertexIndex];
	return VertexOutput(
		vec4f(clip, 0.0, 1.0),
		vec2f(clip.x * 0.5 + 0.5, 0.5 - clip.y * 0.5)
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

fn Tonemap_ACES(x: vec3f) -> vec3f
{
	let a: f32 = 2.51;
	let b: f32 = 0.03;
	let c: f32 = 2.43;
	let d: f32 = 0.59;
	let e: f32 = 0.14;
	return (x * (a * x + b)) / (x * (c * x + d) + e);
}

fn fxaa(uv: vec2u) -> vec4f {
	let SPAN_MAX = (8.0);
	//These are more technnical and probably don't need changing:
	//Minimum "dir" reciprocal
	let REDUCE_MIN = (1.0/128.0);
	//Luma multiplier for "dir" reciprocal
	let REDUCE_MUL = (1.0/32.0);

	let u_texel = vec2f(1.0 / uniforms.size.x, 1.0 / uniforms.size.y);
	let rgbCC: vec3f = textureLoad(albedoMap, uv, 0).rgb;
	let rgb00: vec3f = textureLoad(albedoMap, uv-vec2u(1,1), 0).rgb;
	let rgb10: vec3f = textureLoad(albedoMap, uv+vec2u(1,0)-vec2u(0,1), 0).rgb;
	let rgb01: vec3f = textureLoad(albedoMap, uv+vec2u(1,0)-vec2u(0,1), 0).rgb;
	let rgb11: vec3f = textureLoad(albedoMap, uv+vec2u(1,1), 0).rgb;
	
	//Luma coefficients
	let luma: vec3f = vec3f(0.299, 0.587, 0.114);
	//Get luma from the 5 samples
	let lumaCC = dot(rgbCC, luma);
	let luma00 = dot(rgb00, luma);
	let luma10 = dot(rgb10, luma);
	let luma01 = dot(rgb01, luma);
	let luma11 = dot(rgb11, luma);

	
	//Compute gradient from luma values
	var dir = vec2((luma01 + luma11) - (luma00 + luma10), (luma00 + luma01) - (luma10 + luma11));
	//Diminish dir length based on total luma
	let dirReduce = max((luma00 + luma10 + luma01 + luma11) * REDUCE_MUL, REDUCE_MIN);
	//Divide dir by the distance to nearest edge plus dirReduce
	let rcpDir = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
	//Multiply by reciprocal and limit to pixel span
	dir = clamp(dir * rcpDir, vec2f(-SPAN_MAX), vec2f(SPAN_MAX)) * u_texel.xy;
	
	//Average middle texels along dir line
	let A = 0.5 * (
		textureSample(albedoMap, albedoSampler, vec2f(uv) / uniforms.size - dir * (1.0/6.0)) +
		textureSample(albedoMap, albedoSampler, vec2f(uv) / uniforms.size + dir * (1.0/6.0))
	);
	
	//Average with outer texels along dir line
	let B = A * 0.5 + 0.25 * (
		textureSample(albedoMap, albedoSampler, vec2f(uv) / uniforms.size - dir * 0.5) +
		textureSample(albedoMap, albedoSampler, vec2f(uv) / uniforms.size + dir * 0.5)
	);
		
		
	//Get lowest and highest luma values
	let lumaMin = min(lumaCC, min(min(luma00, luma10), min(luma01, luma11)));
	let lumaMax = max(lumaCC, max(max(luma00, luma10), max(luma01, luma11)));
	
	//Get average luma
	let lumaB = dot(B.rgb, luma);
	//If the average is outside the luma range, using the middle average
	if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
		return A;
	}
	else {
		return B;
	}
}

fn sampleTexture(uv: vec2f) -> vec4f {
	var pos: vec2<u32> = vec2<u32>(uv * uniforms.size);

	var sum: vec4f = vec4f(0.0);
	sum += textureLoad(albedoMap, pos, 0);

	return sum / 1.0;
}

@fragment fn fs(
	@location(0) uv: vec2f
) -> @location(0) vec4f {

	var uuv = uv;

	var color = sampleTexture(uuv);
	if uuv.y > 10 {
		color = fxaa(vec2u(uuv * uniforms.size));
	}
	let mapped = CommerceToneMapping(uniforms.exposure * color.rgb);
	let gamma_corrected = pow(mapped, vec3f(1.0 / uniforms.gamma));

	let ui_color = textureLoad(uiMap, vec2<u32>(uuv * uniforms.size), 0);
	
	let rgb = mix(mapped.xyz, ui_color.xyz, ui_color.w);

	return vec4f(rgb, 1.0);
}