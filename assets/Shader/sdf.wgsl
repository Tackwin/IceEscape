diagnostic(off, derivative_uniformity);

const SHAPE_RECT: u32 = 0u;
const SHAPE_CIRCLE: u32 = 1u;
const SHAPE_LINE: u32 = 2u;
const SHAPE_CLOCK: u32 = 3u;

const FLAG_SCREEN_SPACE: u32 = 1u;
const FLAG_DEPTH_TEST: u32 = 2u;

struct SdfInstance {
	model: mat4x4<f32>,
	// Screen-space center in logical pixels, followed by local half-width and half-height.
	bounds: vec4<f32>,
	color: vec4<f32>,
	// Rectangle: corner radius, outline thickness, then shape half-width and half-height.
	// Circle: radius and outline thickness.
	// Line: half-length and thickness.
	// Clock: radius, outline thickness, normalized progress, gap to the inset fill.
	parameters: vec4<f32>,
	shape: u32,
	flags: u32,
	rotation: f32,
	// NDC depth for a screen-space SDF when depth testing is enabled.
	screen_depth: f32,
	padding: vec4<u32>,
};

struct SdfUniforms {
	view_projection: mat4x4<f32>,
	viewport_size: vec2<f32>,
	padding: vec2<f32>,
};

struct VertexOutput {
	@builtin(position) position: vec4<f32>,
	@location(0) local_position: vec2<f32>,
	@interpolate(flat) @location(1) instance_index: u32,
};

struct FragmentOutput {
	@location(0) color: vec4<f32>,
	@builtin(frag_depth) depth: f32,
};

@group(0) @binding(0) var<uniform> uniforms: SdfUniforms;
@group(0) @binding(1) var<storage, read> instances: array<SdfInstance>;

fn rotate_2d(point: vec2<f32>, angle: f32) -> vec2<f32> {
	let cosine = cos(angle);
	let sine = sin(angle);
	return vec2<f32>(
		cosine * point.x - sine * point.y,
		sine * point.x + cosine * point.y,
	);
}

@vertex fn vs(
	@builtin(vertex_index) vertex_index: u32,
	@builtin(instance_index) instance_index: u32,
) -> VertexOutput {
	let corners = array(
		vec2<f32>(-1.0, -1.0),
		vec2<f32>( 1.0, -1.0),
		vec2<f32>( 1.0,  1.0),
		vec2<f32>(-1.0, -1.0),
		vec2<f32>( 1.0,  1.0),
		vec2<f32>(-1.0,  1.0),
	);

	let instance = instances[instance_index];
	let local_position = corners[vertex_index] * instance.bounds.zw;
	var clip_position: vec4<f32>;

	if ((instance.flags & FLAG_SCREEN_SPACE) != 0u) {
		let screen_offset = rotate_2d(local_position, instance.rotation);
		let screen_position = instance.bounds.xy + screen_offset;
		clip_position = vec4<f32>(
			2.0 * screen_position.x / uniforms.viewport_size.x - 1.0,
			1.0 - 2.0 * screen_position.y / uniforms.viewport_size.y,
			instance.screen_depth,
			1.0,
		);
	} else {
		clip_position = uniforms.view_projection * instance.model *
			vec4<f32>(local_position, 0.0, 1.0);
	}

	return VertexOutput(clip_position, local_position, instance_index);
}

fn rectangle_distance(point: vec2<f32>, half_size: vec2<f32>, radius: f32) -> f32 {
	let r = clamp(radius, 0.0, min(half_size.x, half_size.y));
	let q = abs(point) - half_size + vec2<f32>(r, r);
	return length(max(q, vec2<f32>(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

fn clock_distance(point: vec2<f32>, parameters: vec4<f32>) -> f32 {
	let radius = parameters.x;
	let ring = abs(length(point) - radius) - parameters.y * 0.5;
	let fill_radius = max(radius - parameters.y * 0.5 - parameters.w, 0.0);
	let progress = clamp(parameters.z, 0.0, 1.0);
	if (progress <= 0.0 || fill_radius <= 0.0) {
		return ring;
	}
	let disk = length(point) - fill_radius;
	if (progress >= 1.0) {
		return min(ring, disk);
	}

	// Rotate the sector's bisector onto +Y, then fold its two radial edges together.
	let half_angle = progress * 3.141592653589793;
	let rotated = rotate_2d(point, half_angle);
	let folded = vec2<f32>(abs(rotated.x), rotated.y);
	let edge = vec2<f32>(sin(half_angle), cos(half_angle));
	let edge_distance = length(folded - edge * clamp(dot(folded, edge), 0.0, fill_radius));
	let side = sign(edge.y * folded.x - edge.x * folded.y);
	let sector = max(disk, edge_distance * side);
	return min(ring, sector);
}

fn shape_distance(instance: SdfInstance, point: vec2<f32>) -> f32 {
	if (instance.shape == SHAPE_RECT) {
		return rectangle_distance(point, instance.parameters.zw, instance.parameters.x);
	}
	if (instance.shape == SHAPE_CIRCLE) {
		return length(point) - instance.parameters.x;
	}
	if (instance.shape == SHAPE_LINE) {
		let q = vec2<f32>(abs(point.x) - instance.parameters.x, point.y);
		return length(max(q, vec2<f32>(0.0))) + min(max(q.x, q.y), 0.0) - instance.parameters.y * 0.5;
	}
	if (instance.shape == SHAPE_CLOCK) {
		// Logical screen coordinates have their Y axis pointing down.
		let clock_point = vec2<f32>(point.x, select(point.y, -point.y,
			(instance.flags & FLAG_SCREEN_SPACE) != 0u));
		return clock_distance(clock_point, instance.parameters);
	}
	return 1.0e20;
}

@fragment fn fs(input: VertexOutput) -> FragmentOutput {
	let instance = instances[input.instance_index];
	var distance = shape_distance(instance, input.local_position);
	if ((instance.shape == SHAPE_RECT || instance.shape == SHAPE_CIRCLE) && instance.parameters.y > 0.0) {
		distance = abs(distance) - instance.parameters.y * 0.5;
	}
	let antialias_width = max(fwidth(distance), 0.000001);
	let coverage = 1.0 - smoothstep(-antialias_width, antialias_width, distance);

	var output: FragmentOutput;
	output.color = vec4<f32>(instance.color.rgb, instance.color.a * coverage);
	// The SDF pipeline uses LessEqual depth comparison and disables depth writes.
	// A zero depth makes the depth-test-off instances pass while retaining one draw.
	output.depth = select(
		0.0,
		input.position.z,
		(instance.flags & FLAG_DEPTH_TEST) != 0u,
	);
	return output;
}
