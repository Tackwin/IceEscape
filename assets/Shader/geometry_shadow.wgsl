struct UniformData {
	V: mat4x4<f32>,
	P: mat4x4<f32>,

	shadowV: mat4x4<f32>,
	shadowP: mat4x4<f32>,

	useAlbedoMap: u32,
	useNormalMap: u32,
	useShadowMap: u32,
	padding: u32,
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
};

@group(0) @binding(0) var<uniform> uniforms: UniformData;
@group(0) @binding(1) var<storage, read> instanceData: array<InstanceData>;

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
