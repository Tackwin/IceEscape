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
struct Light {
	position: vec3f,
	padding0: u32,
	direction: vec3f,
	padding1: u32,
	color: vec3f,
	kind: u32, // 0 = directional, 1 = point, 2 = cone
	range: f32, // for point and cone
	angle: f32, // for cone
	padding2: u32,
};


struct VertexOutput {
	@builtin(position) Position : vec4f,
};

@group(0) @binding(0) var<uniform> uniforms: UniformData;
@group(0) @binding(1) var<storage, read> instanceData: array<InstanceData>;
@group(0) @binding(2) var<storage, read> lights: array<Light>;

@vertex fn vs(
	@builtin(vertex_index) vertexIndex : u32,
	@builtin(instance_index) instanceIndex : u32,
	@location(0) pos: vec3f,
	@location(1) normal: vec3f,
	@location(2) uv: vec2f
) -> VertexOutput {
	var output: VertexOutput;

	let model = instanceData[instanceIndex].M;
	output.Position = uniforms.shadowP * uniforms.shadowV * model * vec4f(pos, 1.0);
	return output;
}
