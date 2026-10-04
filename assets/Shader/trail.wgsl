const MAX_TRAIL_POINTS: u32 = 8u;

const FLAG_TEXTURED: u32 = 1u;
const FLAG_UV_REPEAT: u32 = 2u;
const FLAG_DEPTH_TEST: u32 = 4u;

struct TrailPoint {
	position_thickness: vec4<f32>,
	uv_x: f32,
	padding0: u32,
	padding1: u32,
	padding2: u32,
};

struct TrailInstance {
	points: array<TrailPoint, 8>,
	color: vec4<f32>,
	texture_rect: vec4<f32>,
	point_count: u32,
	flags: u32,
	texture_layer: u32,
	padding: u32,
};

struct TrailUniforms {
	view_projection: mat4x4<f32>,
	camera_position: vec3<f32>,
	padding: f32,
};

struct VertexOutput {
	@builtin(position) position: vec4<f32>,
	@location(0) uv: vec2<f32>,
	@interpolate(flat) @location(1) instance_index: u32,
};

struct FragmentOutput {
	@location(0) color: vec4<f32>,
	@builtin(frag_depth) depth: f32,
};

@group(0) @binding(0) var<uniform> uniforms: TrailUniforms;
@group(0) @binding(1) var<storage, read> instances: array<TrailInstance>;

@group(1) @binding(0) var trail_texture: texture_2d_array<f32>;
@group(1) @binding(1) var trail_sampler: sampler;

fn safe_normalize(value: vec3<f32>, fallback: vec3<f32>) -> vec3<f32> {
	let magnitude_squared = dot(value, value);
	if (magnitude_squared <= 0.0000001) {
		return fallback;
	}
	return value * inverseSqrt(magnitude_squared);
}

fn point_position(instance: TrailInstance, index: u32) -> vec3<f32> {
	return instance.points[index].position_thickness.xyz;
}

@vertex fn vs(
	@builtin(vertex_index) vertex_index: u32,
	@builtin(instance_index) instance_index: u32,
) -> VertexOutput {
	let instance = instances[instance_index];
	let point_count = min(instance.point_count, MAX_TRAIL_POINTS);
	let last_point = max(point_count, 1u) - 1u;
	let point_index = min(vertex_index / 2u, last_point);
	let previous_index = max(point_index, 1u) - 1u;
	let next_index = min(point_index + 1u, last_point);

	let point = instance.points[point_index];
	let position = point.position_thickness.xyz;
	let previous_position = point_position(instance, previous_index);
	let next_position = point_position(instance, next_index);

	var forward_tangent = safe_normalize(next_position - position, vec3<f32>(1.0, 0.0, 0.0));
	var backward_tangent = safe_normalize(position - previous_position, forward_tangent);
	if (point_index == 0u) {
		backward_tangent = forward_tangent;
	}
	if (point_index == last_point) {
		forward_tangent = backward_tangent;
	}
	let view_direction = safe_normalize(uniforms.camera_position - position, vec3<f32>(0.0, 0.0, 1.0));
	let fallback_width = safe_normalize(
		cross(forward_tangent, vec3<f32>(0.0, 0.0, 1.0)),
		vec3<f32>(1.0, 0.0, 0.0),
	);
	let previous_width = safe_normalize(cross(backward_tangent, view_direction), fallback_width);
	let next_width = safe_normalize(cross(forward_tangent, view_direction), previous_width);
	var width_direction = safe_normalize(previous_width + next_width, next_width);
	let miter_denominator = max(abs(dot(width_direction, next_width)), 0.5);
	width_direction *= min(1.0 / miter_denominator, 2.0);

	// If the trail points directly at the camera, use a stable camera-facing fallback.
	if (dot(cross(forward_tangent, view_direction), cross(forward_tangent, view_direction)) <= 0.0000001) {
		width_direction = fallback_width;
	}

	let side = select(-1.0, 1.0, (vertex_index & 1u) != 0u);
	let half_width = max(point.position_thickness.w, 0.0) * 0.5;
	let world_position = position + width_direction * side * half_width;

	var output: VertexOutput;
	output.position = uniforms.view_projection * vec4<f32>(world_position, 1.0);
	output.uv = vec2<f32>(point.uv_x, side);
	output.instance_index = instance_index;
	return output;
}

@fragment fn fs(input: VertexOutput) -> FragmentOutput {
	let instance = instances[input.instance_index];

	// The cross-trail coordinate remains [-1, 1] between the two generated edges.
	let edge_width = max(fwidth(input.uv.y), 0.000001);
	let coverage = 1.0 - smoothstep(1.0 - edge_width, 1.0, abs(input.uv.y));

	var sampled_color = vec4<f32>(1.0);
	if ((instance.flags & FLAG_TEXTURED) != 0u) {
		var texture_uv = vec2<f32>(input.uv.x, input.uv.y * 0.5 + 0.5);
		var texture_uv_dx = dpdx(texture_uv);
		var texture_uv_dy = dpdy(texture_uv);
		if ((instance.flags & FLAG_UV_REPEAT) != 0u) {
			texture_uv.x = fract(texture_uv.x);
		}
		texture_uv = instance.texture_rect.xy + texture_uv * instance.texture_rect.zw;
		texture_uv_dx *= instance.texture_rect.zw;
		texture_uv_dy *= instance.texture_rect.zw;
		sampled_color = textureSampleGrad(
			trail_texture,
			trail_sampler,
			texture_uv,
			i32(instance.texture_layer),
			texture_uv_dx,
			texture_uv_dy,
		);
	}

	var output: FragmentOutput;
	output.color = vec4<f32>(
		instance.color.rgb * sampled_color.rgb,
		instance.color.a * sampled_color.a * coverage,
	);
	// A zero depth bypasses scene occlusion while retaining one pipeline and draw path.
	output.depth = select(
		0.0,
		input.position.z,
		(instance.flags & FLAG_DEPTH_TEST) != 0u,
	);
	return output;
}
