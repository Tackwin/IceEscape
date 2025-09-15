#import "Basic";
#import "String";
#import "Algebra";
#import "Assets";
#import "Math";
#import "Platform";
#import "Hash_Table";
Store :: #import "Store";
STB :: #import "stb_image";
Scene :: #import "Scene";

offset_of :: ($T: Type, $member: string) -> int {
	for type_info(T).members {
		if it.name == member
			return it.offset_in_bytes;
	}

	assert(false, "Type '%' does not have member '%'", T, member);
	return -1;
}

toWGPUStringView :: (str: string) -> WGPUStringView {
	view: WGPUStringView;
	view.data = str.data;
	view.length = xx str.count;
	return view;
}

align_up :: (value: *int, alignment: int) {
	value.* = ((value.* + alignment - 1) / alignment) * alignment;
}

#scope_export


WShader :: struct {
	code: string;
	dirty := true;

	module: WGPUShaderModule;

	input: Type_Info;
}

WTexture :: struct {
	gpu: WGPUTexture;
	view: WGPUTextureView;
	sampler: WGPUSampler;

	width: int;
	height: int;

	make_from_image :: (image: Image, label: string = "unknown") -> WTexture {
		texture: WTexture;

		desc: WGPUTextureDescriptor = .{};
		desc.label = toWGPUStringView(tprint("Texture (%)", label));
		desc.usage = WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopyDst;
		desc.size.width = xx image.width;
		desc.size.height = xx image.height;
		desc.size.depthOrArrayLayers = 1;
		desc.mipLevelCount = 1;
		desc.sampleCount = 1;
		desc.dimension = ._2D;
		desc.format = .RGBA8Unorm;
		texture.gpu = context.gpu.deviceCreateTexture(context.graphics.device, *desc);

		copyInfo: WGPUTexelCopyTextureInfo;
		copyInfo.texture = texture.gpu;
		copyInfo.mipLevel = 0;
		copyInfo.origin = .{ 0, 0, 0 };
		copyInfo.aspect = .All;
		copyLayout: WGPUTexelCopyBufferLayout;
		copyLayout.offset = 0;
		copyLayout.bytesPerRow = xx (image.width * image.channels);
		copyLayout.rowsPerImage = xx image.height;
		context.gpu.queueWriteTexture(
			context.graphics.mainQueue,
			*copyInfo,
			image.data.data,
			xx (image.width * image.height * image.channels),
			*copyLayout,
			*desc.size
		);

		texture.view = context.gpu.textureCreateView(texture.gpu, null);

		samplerDesc: WGPUSamplerDescriptor = .{};
		samplerDesc.label = toWGPUStringView(tprint("Texture Sampler (%)", label));
		samplerDesc.addressModeU = .Repeat;
		samplerDesc.addressModeV = .Repeat;
		samplerDesc.addressModeW = .Repeat;
		samplerDesc.magFilter = .Linear;
		samplerDesc.minFilter = .Linear;
		samplerDesc.mipmapFilter = .Linear;
		samplerDesc.lodMinClamp = 0;
		samplerDesc.lodMaxClamp = 32;
		samplerDesc.maxAnisotropy = 1;
		texture.sampler = context.gpu.deviceCreateSampler(context.graphics.device, *samplerDesc);

		return texture;
	}
}

Model :: struct {
	gpu: WGPUBuffer;
	prim_count: int;

	make_from_obj :: (obj: [] u8, debug: string = "unknown") -> Model {
		model: Model;

		vertices: [..] V3f;
		vertices.allocator = temp;
		array_add(*vertices, .{ 0, 0, 0 });

		normals: [..] V3f;
		normals.allocator = temp;
		array_add(*normals, .{ 0, 0, 0 });

		textures: [..] V2f;
		textures.allocator = temp;
		array_add(*textures, .{ 0, 0 });

		Obj_Face :: struct {
			positions: [3] u32 = .[ 0, 0, 0 ];
			normals: [3] u32 = .[ 0, 0, 0 ];
			textures: [3] u32 = .[ 0, 0, 0 ];
		}

		faces: [..] Obj_Face;
		faces.allocator = temp;

		cursor := 0;
		line: string;

		while true {
			next_cursor := find_index_from_left(xx obj, "\n", cursor);
			if next_cursor < 0
				break;

			line.data = obj.data + cursor;
			line.count = next_cursor - cursor;
			cursor = next_cursor + 1;
			if line.count == 0
				continue;

			x: float32;
			y: float32;
			z: float32;
			r: float32;
			g: float32;
			b: float32;

			i: [9] u32;

			if scan2(line, "v % % %", *x, *y, *z) {
				array_add(*vertices, .{ x = x, y = y, z = z });
			}
			if scan2(line, "v % % % % % %", *x, *y, *z, *r, *g, *b) {
				array_add(*vertices, .{ x = x, y = y, z = z });
			}
			if scan2(line, "vn % % %", *x, *y, *z) {
				array_add(*normals, .{ x = x, y = y, z = z });
			}
			if scan2(line, "vt % %", *x, *y) {
				array_add(*textures, .{ x = x, y = y });
			}
			if scan2(
				line,
				"f %/%/% %/%/% %/%/%",
				*i[0], *i[1], *i[2], *i[3], *i[4], *i[5], *i[6], *i[7], *i[8]
			) {
				face: Obj_Face;
				face.positions[0] = i[0];
				face.positions[1] = i[3];
				face.positions[2] = i[6];
				face.normals[0] = i[2];
				face.normals[1] = i[5];
				face.normals[2] = i[8];
				face.textures[0] = i[1];
				face.textures[1] = i[4];
				face.textures[2] = i[7];
				array_add(*faces, face);
			}
			if scan2(
				line,
				"f %//% %//% %//%",
				*i[0], *i[1], *i[2], *i[3], *i[4], *i[5]
			) {
				face: Obj_Face;
				face.positions[0] = i[0];
				face.positions[1] = i[2];
				face.positions[2] = i[4];
				face.normals[0] = i[1];
				face.normals[1] = i[3];
				face.normals[2] = i[5];
				array_add(*faces, face);
			}
		}

		cpu_buffer := NewArray(faces.count * 3, WFramegraph.Vertex, false,, temp);
		for faces {
			cpu_buffer[it_index * 3 + 0].position = vertices[it.positions[0]];
			cpu_buffer[it_index * 3 + 0].normal = normals[it.normals[0]];
			cpu_buffer[it_index * 3 + 0].uv = textures[it.textures[0]];

			cpu_buffer[it_index * 3 + 1].position = vertices[it.positions[1]];
			cpu_buffer[it_index * 3 + 1].normal = normals[it.normals[1]];
			cpu_buffer[it_index * 3 + 1].uv = textures[it.textures[1]];

			cpu_buffer[it_index * 3 + 2].position = vertices[it.positions[2]];
			cpu_buffer[it_index * 3 + 2].normal = normals[it.normals[2]];
			cpu_buffer[it_index * 3 + 2].uv = textures[it.textures[2]];
		}

		desc: WGPUBufferDescriptor = .{};
		desc.label = toWGPUStringView(tprint("Vertex Buffer (%))", debug));
		desc.usage = WGPUBufferUsage_Vertex | WGPUBufferUsage_CopyDst;
		desc.size = xx (cpu_buffer.count * size_of(WFramegraph.Vertex));
		desc.mappedAtCreation = 0;
		model.gpu = context.gpu.deviceCreateBuffer(context.graphics.device, *desc);
		model.prim_count = cpu_buffer.count;

		context.gpu.queueWriteBuffer(
			context.graphics.mainQueue,
			model.gpu,
			0,
			cpu_buffer.data,
			xx (cpu_buffer.count * size_of(WFramegraph.Vertex))
		);

		return model;
	}
}

WFramegraph :: struct {
	geometryModule: WGPUShaderModule;
	geometryPipeline: WGPURenderPipeline;
	geometryBindGroupLayout: WGPUBindGroupLayout;

	geometryShadowModule: WGPUShaderModule;
	geometryShadowPipeline: WGPURenderPipeline;
	geometryShadowBindGroupLayout: WGPUBindGroupLayout;

	depthTexture: WGPUTexture;
	depthView: WGPUTextureView;

	Uniforms :: struct {
		V: M4f;
		P: M4f;
		shadowV: M4f;
		shadowP: M4f;

		tint: V3f;
		padding0: u32;

		sun_dir: V3f;
		padding2: u32;
		sun_color: V3f;
		sun_strength: float32;
	}
	typicalUniform: Uniforms;
	uniformBuffer: WGPUBuffer;

	Vertex :: struct {
		position: V3f;
		normal: V3f;
		uv: V2f;
	};

	Instance :: struct {
		M: M4f;
		texture_rect: V4f = .{ 0, 0, 1, 1 }; // x, y, width, height
		useAlbedoMap: u32 = 1;
		useNormalMap: u32 = 0;
		useShadowMap: u32 = 0;
		padding1: u32 = 0;
	};
	instanceBuffer: WGPUBuffer;
	instanceBufferCursor := 0;
};

init_geometry_pipeline :: (framegraph: *WFramegraph, store: *Store.Store) {
	{
		desc: WGPUShaderModuleDescriptor = .{};
		wgsl: WGPUShaderSourceWGSL = .{};
		wgsl.code = toWGPUStringView(store.geometry_shader.code);
		wgsl.chain.next = null;
		wgsl.chain.sType = .ShaderSourceWGSL;
		desc.nextInChain = *wgsl.chain;
		framegraph.geometryModule = context.gpu.deviceCreateShaderModule(
			context.graphics.device, *desc
		);
	}

	{
		desc: WGPURenderPipelineDescriptor = .{};
		desc.label = toWGPUStringView("Geometry Pipeline");
		desc.layout = null;
		desc.vertex.module = framegraph.geometryModule;
		desc.vertex.entryPoint = toWGPUStringView("vs");

			vertexBuffers: [1] WGPUVertexBufferLayout;
			vertexBuffers[0] = .{};
			vertexBuffers[0].stepMode = .Vertex;
			vertexBuffers[0].arrayStride = xx size_of(WFramegraph.Vertex);

				attributes: [3] WGPUVertexAttribute;
				attributes[0].format = .Float32x3;
				attributes[0].offset = xx offset_of(WFramegraph.Vertex, "position");
				attributes[0].shaderLocation = 0;
				attributes[1].format = .Float32x3;
				attributes[1].offset = xx offset_of(WFramegraph.Vertex, "normal");
				attributes[1].shaderLocation = 1;
				attributes[2].format = .Float32x2;
				attributes[2].offset = xx offset_of(WFramegraph.Vertex, "uv");
				attributes[2].shaderLocation = 2;

			vertexBuffers[0].attributeCount = attributes.count;
			vertexBuffers[0].attributes = attributes.data;

		desc.vertex.buffers = vertexBuffers.data;
		desc.vertex.bufferCount = vertexBuffers.count;

		desc.primitive.topology = .WGPUPrimitiveTopology_TriangleList;
		desc.primitive.stripIndexFormat = .Undefined;
		desc.primitive.frontFace = .CCW;
		desc.primitive.cullMode = .None;
		desc.primitive.unclippedDepth = 0;

			depthDesc: WGPUDepthStencilState = .{};
			depthDesc.format = .Depth32Float;
			depthDesc.depthWriteEnabled = xx 1;
			depthDesc.depthCompare = .Less;
			depthDesc.stencilFront = .{};
			depthDesc.stencilBack = .{};
			depthDesc.stencilReadMask = 0;
			depthDesc.stencilWriteMask = 0;
			depthDesc.depthBias = 0;
			depthDesc.depthBiasSlopeScale = 0.0;
			depthDesc.depthBiasClamp = 0.0;

		desc.depthStencil = *depthDesc;

		desc.multisample.count = 1;
		desc.multisample.mask = 0xFFFFFFFF;
		desc.multisample.alphaToCoverageEnabled = 0;

			fragment: WGPUFragmentState = .{};
			fragment.module = framegraph.geometryModule;
			fragment.entryPoint = toWGPUStringView("fs");
				targets: [1] WGPUColorTargetState;
				targets[0].format = .BGRA8Unorm;
				targets[0].blend = null;
				targets[0].writeMask = WGPUColorWriteMask_All;
			fragment.targets = targets.data;
			fragment.targetCount = targets.count;
		desc.fragment = *fragment;

		framegraph.geometryPipeline = context.gpu.deviceCreateRenderPipeline(
			context.graphics.device, *desc
		);

		framegraph.geometryBindGroupLayout = context.gpu.renderPipelineGetBindGroupLayout(
			framegraph.geometryPipeline, 0
		);
	}
}

init_geometry_shadow_pipeline :: (framegraph: *WFramegraph, store: *Store.Store) {

}

init_framegraph :: (framegraph: *WFramegraph, store: *Store.Store) {
	{
		desc: WGPUBufferDescriptor = .{};
		desc.label = toWGPUStringView("Frame Uniform Buffer");
		desc.usage = WGPUBufferUsage_Uniform | WGPUBufferUsage_CopyDst;
		desc.size = size_of(WFramegraph.Uniforms);
		desc.mappedAtCreation = 0;
		framegraph.uniformBuffer = context.gpu.deviceCreateBuffer(context.graphics.device, *desc);
	}
	{
		desc: WGPUBufferDescriptor = .{};
		desc.label = toWGPUStringView("Instance Buffer");
		desc.usage = WGPUBufferUsage_Storage | WGPUBufferUsage_CopyDst;
		desc.size = 64 * 1024 * size_of(WFramegraph.Instance);
		desc.mappedAtCreation = 0;
		framegraph.instanceBuffer = context.gpu.deviceCreateBuffer(context.graphics.device, *desc);
	}
	{
		desc: WGPUTextureDescriptor = .{};
		desc.label = toWGPUStringView("Depth Texture");
		desc.usage = WGPUTextureUsage_RenderAttachment | WGPUTextureUsage_TextureBinding;
		desc.size.width = 1366;
		desc.size.height = 768;
		desc.size.depthOrArrayLayers = 1;
		desc.mipLevelCount = 1;
		desc.sampleCount = 1;
		desc.dimension = ._2D;
		desc.format = .Depth32Float;
		framegraph.depthTexture = context.gpu.deviceCreateTexture(context.graphics.device, *desc);

		viewDesc: WGPUTextureViewDescriptor = .{};
		viewDesc.label = toWGPUStringView("Depth Texture View");
		viewDesc.format = .Depth32Float;
		viewDesc.dimension = ._2D;
		viewDesc.aspect = .DepthOnly;
		framegraph.depthView = context.gpu.textureCreateView(framegraph.depthTexture, null);
	}

	if store.geometry_shader.dirty {
		store.geometry_shader.dirty = false;
		init_geometry_pipeline(framegraph, store);
	}
}

writeTo :: (buffer: WGPUBuffer, offset: int, data: *$T) {
	context.gpu.queueWriteBuffer(
		context.graphics.mainQueue, buffer, xx offset, data, xx size_of(T)
	);
}

writeTo :: (buffer: WGPUBuffer, offset: int, data: [] $T) {
	context.gpu.queueWriteBuffer(
		context.graphics.mainQueue, buffer, xx offset, data.data, xx (data.count * size_of(T))
	);
}

typical_bind_group :: (
	framegraph: *WFramegraph,
	name: string,
	instanced_count: int,
	albedo: *WTexture = null,
	normal: *WTexture = null,
	shadow: *WTexture = null
) -> WGPUBindGroup {
	desc: WGPUBindGroupDescriptor = .{};
	desc.label = toWGPUStringView(tprint("% Bind Group", name));
	desc.layout = framegraph.geometryBindGroupLayout;
	entries: [8] WGPUBindGroupEntry;
	entries[0].binding = 0;
	entries[0].buffer = framegraph.uniformBuffer;
	entries[0].offset = 0;
	entries[0].size = size_of(WFramegraph.Uniforms);
	entries[1].binding = 1;
	entries[1].buffer = framegraph.instanceBuffer;
	entries[1].offset = xx framegraph.instanceBufferCursor;
	entries[1].size = xx (instanced_count * size_of(WFramegraph.Instance));

	entries[2].binding = 2;
	if albedo {
		entries[2].textureView = albedo.view;
		entries[3].textureView = albedo.view;
		entries[4].textureView = albedo.view;
	}

	entries[3].binding = 3;
	if normal
		entries[3].textureView = normal.view;

	entries[4].binding = 4;
	if shadow
		entries[4].textureView = shadow.view;

	entries[5].binding = 5;
	if albedo {
		entries[5].sampler = albedo.sampler;
		entries[6].sampler = albedo.sampler;
		entries[7].sampler = albedo.sampler;
	}

	entries[6].binding = 6;
	if normal
		entries[6].sampler = normal.sampler;

	entries[7].binding = 7;
	if shadow
		entries[7].sampler = shadow.sampler;
	desc.entryCount = entries.count;
	desc.entries = entries.data;
	return context.gpu.deviceCreateBindGroup(context.graphics.device, *desc);
}

encode_and_draw :: (
	framegraph: *WFramegraph, pass: WGPURenderPassEncoder, model: Model, instanced_count: int
) {
	context.gpu.renderPassEncoderSetVertexBuffer(
		pass, 0, model.gpu, 0, xx (model.prim_count * size_of(WFramegraph.Vertex))
	);
	context.gpu.renderPassEncoderDraw(
		pass, xx model.prim_count, xx instanced_count, 0, 0
	);
	framegraph.instanceBufferCursor += xx (instanced_count * size_of(WFramegraph.Instance));
	align_up(*framegraph.instanceBufferCursor, 256);
}

render :: (framegraph: *WFramegraph, scene: Scene.Scene, store: Store.Store) {
	framegraph.instanceBufferCursor = 0;

	surfaceTexture: WGPUSurfaceTexture;
	context.gpu.surfaceGetCurrentTexture(context.graphics.surface, *surfaceTexture);
	surfaceView := context.gpu.textureCreateView(surfaceTexture.texture, null);
	defer {
		context.gpu.textureViewRelease(surfaceView);
	}

	encoder := context.gpu.deviceCreateCommandEncoder(context.graphics.device, null);

	framegraph.typicalUniform = .{};
	framegraph.typicalUniform.V =
		Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	framegraph.typicalUniform.P =
		Scene.perspective(scene.camera);
	center := V3f.{ 0, 0, 0 };
	center.x += scene.terrain.tiles_count.x / 2.0;
	center.y += scene.terrain.tiles_count.y / 2.0;
	framegraph.typicalUniform.shadowV =
		Scene.look_at(center + V3f.{ 100, 100, 100 }, center, V3f.{ 0, 1, 0 });
	framegraph.typicalUniform.shadowP =
		Scene.orthographic(-40, 40, -40, 40, 0.1, 500);
	framegraph.typicalUniform.tint = V3f.{ 1, 1, 1 };
	framegraph.typicalUniform.sun_dir = normalize(V3f.{ -1, -1, -1 });
	framegraph.typicalUniform.sun_color = V3f.{ 1, 1, 1 };
	framegraph.typicalUniform.sun_strength = 0.5;

	writeTo(framegraph.uniformBuffer, 0, *framegraph.typicalUniform);
	
	attachment: WGPURenderPassColorAttachment = .{};
	attachment.view = surfaceView;
	attachment.depthSlice = 0;
	attachment.loadOp = .Clear;
	attachment.storeOp = .Store;
	attachment.clearValue = .{ 0.3, 0.3, 0.3, 1.0 };

	depthAttachment: WGPURenderPassDepthStencilAttachment = .{};
	depthAttachment.view = framegraph.depthView;
	depthAttachment.depthLoadOp = .Clear;
	depthAttachment.depthStoreOp = .Store;
	depthAttachment.depthClearValue = 1.0;
	depthAttachment.stencilLoadOp = .Undefined;
	depthAttachment.stencilStoreOp = .Undefined;
	depthAttachment.stencilClearValue = 0;
	render_players(framegraph, encoder, *attachment, *depthAttachment, scene, store);

	attachment.loadOp = .Load;
	depthAttachment.depthLoadOp = .Load;
	passDesc: WGPURenderPassDescriptor = .{};
	passDesc.label = toWGPUStringView("Tombstone Pass");
	passDesc.colorAttachments = *attachment;
	passDesc.colorAttachmentCount = 1;
	passDesc.depthStencilAttachment = *depthAttachment;
	geometryPass := context.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);
	context.gpu.renderPassEncoderSetPipeline(geometryPass, framegraph.geometryPipeline);

	render_keys(framegraph, encoder, geometryPass, scene, store);
	render_skulls(framegraph, encoder, geometryPass, scene, store);
	render_shurikens(framegraph, encoder, geometryPass, scene, store);
	render_standin(framegraph, encoder, geometryPass, scene, store);
	render_props(framegraph, encoder, geometryPass, scene, store);
	render_gates(framegraph, encoder, geometryPass, scene, store);
	render_tombstones(framegraph, encoder, geometryPass, scene, store);
	render_terrain(framegraph, encoder, geometryPass, scene, store);

	context.gpu.renderPassEncoderEnd(geometryPass);
	context.gpu.renderPassEncoderRelease(geometryPass);

	bufferDesc: WGPUCommandBufferDescriptor = .{};
	bufferDesc.label = toWGPUStringView("Main Command Buffer");
	buffer := context.gpu.commandEncoderFinish(encoder, *bufferDesc);

	submit: [1] WGPUCommandBuffer = .[buffer];
	context.gpu.queueSubmit(context.graphics.mainQueue, 1, submit.data);
}

render_tombstones :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {

	instanced := NewArray(scene.tombstones.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for scene.tombstones {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count == 0
		return;

	bindGroup := typical_bind_group(framegraph, "Tombstone", instanced.count, *store.colormaps);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
	encode_and_draw(framegraph, pass, store.tombstone_model, instanced.count);
}

render_gates :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	render_gates_regular_open(framegraph, encoder, pass, scene, store);
	render_gates_regular_closed(framegraph, encoder, pass, scene, store);
	render_gates_finished_open(framegraph, encoder, pass, scene, store);
	render_gates_finished_closed(framegraph, encoder, pass, scene, store);
}

render_gates_regular_open :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := NewArray(scene.gates.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for scene.gates {
		if !(!it.is_end && !it.is_closed)
			continue;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		R := to_rotation_matrix(from_unit_vectors(V3f.{ 1, 0, 0 }, it.direction));
		instance.M = M4f.translate(it.position) * R;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}

	if instanced.count == 0
		return;

	bindGroup := typical_bind_group(framegraph, "Gate", instanced.count, *store.colormaps, null);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
	encode_and_draw(framegraph, pass, store.gate_model, instanced.count);
}

render_gates_regular_closed :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := NewArray(scene.gates.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for scene.gates {
		if !(!it.is_end && it.is_closed)
			continue;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		R := to_rotation_matrix(from_unit_vectors(V3f.{ 1, 0, 0 }, it.direction));
		instance.M = M4f.translate(it.position) * R;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}

	if instanced.count == 0
		return;

	bindGroup := typical_bind_group(framegraph, "Gate", instanced.count, *store.colormaps, null);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
	encode_and_draw(framegraph, pass, store.gate_close_model, instanced.count);
}

render_gates_finished_open :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := NewArray(scene.gates.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for scene.gates {
		if !(it.is_end && !it.is_closed)
			continue;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		R := to_rotation_matrix(from_unit_vectors(V3f.{ 1, 0, 0 }, it.direction));
		instance.M = M4f.translate(it.position) * R;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}

	if instanced.count == 0
		return;

	bindGroup := typical_bind_group(framegraph, "Gate", instanced.count, *store.colormaps, null);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
	encode_and_draw(framegraph, pass, store.gate_finish_model, instanced.count);
}

render_gates_finished_closed :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := NewArray(scene.gates.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for scene.gates {
		if !(it.is_end && it.is_closed)
			continue;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		R := to_rotation_matrix(from_unit_vectors(V3f.{ 1, 0, 0 }, it.direction));
		instance.M = M4f.translate(it.position) * R;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}

	if instanced.count == 0
		return;

	bindGroup := typical_bind_group(framegraph, "Gate", instanced.count, *store.colormaps, null);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
	encode_and_draw(framegraph, pass, store.gate_finish_close_model, instanced.count);
}

render_shurikens :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := NewArray(scene.shurikens.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for scene.shurikens {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = Scene.compute_moving_frame_server_world_matrix(
			scene, Scene.find_by_frame_id(scene, it.frame_id)
		);
		instance.M *= M4f.translate(it.server.position) * to_rotation_matrix(
			axis_angle(V3f.{ 0, 0, 1 }, it.client.theta)
		);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}

	if instanced.count == 0
		return;


	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
	bindGroup := typical_bind_group(framegraph, "Shuriken", instanced.count, *store.colormaps, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);

	encode_and_draw(framegraph, pass, store.shuriken_model, instanced.count);
}

render_skulls :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := NewArray(scene.skulls.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for * scene.skulls {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = Scene.compute_skull_matrix(scene, it);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}

	if instanced.count == 0
		return;

	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);

	bindGroup := typical_bind_group(framegraph, "Skull", instanced.count, *store.colormaps, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);

	encode_and_draw(framegraph, pass, store.skull_model, instanced.count);

}

render_keys :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {

	instanced := NewArray(scene.keys.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for scene.keys {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		p := it.client.position;
		if it.holder >= 0
			p.z += 1;

		instance.M = M4f.translate(p);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}

	if instanced.count == 0
		return;


	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);

	bindGroup := typical_bind_group(framegraph, "Key", instanced.count, *store.colormaps, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);

	encode_and_draw(framegraph, pass, store.key_model, instanced.count);
}

render_standin :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := NewArray(scene.stand_in.count, WFramegraph.Instance, false,, temp);
	for model_id: 0..Store.Model_Id_Count {
		instanced.count = 0;
		for scene.stand_in {
			if it.model_id != model_id
				continue;

			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			instance.M = M4f.translate(it.position);
			instance.M = instance.M * to_rotation_matrix(it.orientation);
			instance.texture_rect = Store.Colormaps_Rect.vehicle;
		}

		if instanced.count == 0
			continue;

		model := Store.get_model(store, model_id.(Store.Model_Id));
		if !model
			continue;


		writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);

		bindGroup := typical_bind_group(framegraph, "Standin", instanced.count, *store.colormaps, null);
		defer context.gpu.bindGroupRelease(bindGroup);
		context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
		encode_and_draw(framegraph, pass, model, instanced.count);
	}
}

render_players :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	target: *WGPURenderPassColorAttachment,
	depthTarget: *WGPURenderPassDepthStencilAttachment,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := NewArray(scene.players.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for scene.players {
		if it.server.dead
			continue;
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		M := M4f.identity();

		q := from_unit_vectors(V3f.{ 1, 0, 0 }, it.client.direction);
		M = to_rotation_matrix(q);

		M = M4f.translate(it.client.position) * M;
		instance.M = M;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}

	if instanced.count == 0
		return;

	passDesc: WGPURenderPassDescriptor = .{};
	passDesc.label = toWGPUStringView("Tombstone Pass");
	passDesc.colorAttachments = target;
	passDesc.colorAttachmentCount = 1;
	passDesc.depthStencilAttachment = depthTarget;
	pass := context.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);
	context.gpu.renderPassEncoderSetPipeline(pass, framegraph.geometryPipeline);

	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);

	bindGroup := typical_bind_group(framegraph, "Player", instanced.count, *store.colormaps, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);

	encode_and_draw(framegraph, pass, store.racer_model, instanced.count);

	context.gpu.renderPassEncoderEnd(pass);
	context.gpu.renderPassEncoderRelease(pass);
}

render_terrain :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	terrain := *scene.terrain;

	instanced := NewArray(terrain.tiles.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for terrain.tiles {
		x := it_index % terrain.tiles_count.x;
		y := it_index / terrain.tiles_count.x;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		pos := V3f.{ x.(float), y.(float), 0 };
		pos -= v3(scene.camera_min, 0.0);
		instance.M = M4f.translate(pos);
		instance.texture_rect = Store.get_tile_rect(it.kind);
		instance.useNormalMap = 1;
	}
	if instanced.count == 0 {
		return;
	}

	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);

	bindGroup := typical_bind_group(
		framegraph,
		"Terrain",
		instanced.count,
		*store.terrain_tile_albedo,
		*store.terrain_tile_normal
	);
	defer context.gpu.bindGroupRelease(bindGroup);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
	encode_and_draw(framegraph, pass, store.tile_model, instanced.count);

}

render_props :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	if scene.props.count == 0
		return;

	max_id := 0;
	for scene.props
		max_id = max(max_id, it.id);

	instanced := NewArray(scene.props.count, WFramegraph.Instance, false,, temp);
	for prop_id: 0..max_id {
		instanced.count = 0;
		for scene.props {
			if it.id != prop_id
				continue;
			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			instance.M = it.M;
			instance.texture_rect = Store.Colormaps_Rect.prop;
		}
		if instanced.count == 0
			continue;

		writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);

		bindGroup := typical_bind_group(framegraph, "Prop", instanced.count, *store.colormaps);
		defer context.gpu.bindGroupRelease(bindGroup);
		context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
		encode_and_draw(framegraph, pass, Store.get_wprop(store, xx prop_id), instanced.count);
	}
}

