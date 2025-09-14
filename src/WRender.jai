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
	geometryBindGroup: WGPUBindGroup;

	depthTexture: WGPUTexture;
	depthView: WGPUTextureView;

	Uniforms :: struct {
		V: M4f;
		P: M4f;
		shadowV: M4f;
		shadowP: M4f;

		tint: V3f;

		useAlbedoMap: u32;
		useNormalMap: u32;
		useShadowMap: u32;
		padding: [2] u32;
	}
	uniformBuffer: WGPUBuffer;

	Vertex :: struct {
		position: V3f;
		normal: V3f;
		uv: V2f;
	};

	Instance :: struct {
		M: M4f;
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

render :: (framegraph: *WFramegraph, scene: Scene.Scene) {
	framegraph.instanceBufferCursor = 0;

	surfaceTexture: WGPUSurfaceTexture;
	context.gpu.surfaceGetCurrentTexture(context.graphics.surface, *surfaceTexture);
	surfaceView := context.gpu.textureCreateView(surfaceTexture.texture, null);
	defer {
		context.gpu.textureViewRelease(surfaceView);
	}

	encoder := context.gpu.deviceCreateCommandEncoder(context.graphics.device, null);

	uniforms: WFramegraph.Uniforms = .{};
	uniforms.V = Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	uniforms.P = Scene.perspective(scene.camera);
	center := V3f.{ 0, 0, 0 };
	center.x += scene.terrain.tiles_count.x / 2.0;
	center.y += scene.terrain.tiles_count.y / 2.0;
	uniforms.shadowV = Scene.look_at(center + V3f.{ 100, 100, 100 }, center, V3f.{ 0, 1, 0 });
	uniforms.shadowP = Scene.orthographic(-40, 40, -40, 40, 0.1, 500);
	uniforms.tint = V3f.{ 1, 1, 1 };
	uniforms.useAlbedoMap = 1;

	context.gpu.queueWriteBuffer(
		context.graphics.mainQueue,
		framegraph.uniformBuffer,
		0,
		*uniforms,
		size_of(WFramegraph.Uniforms)
	);

	
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

	render_props(framegraph, encoder, attachment, depthAttachment, scene);

	
	bufferDesc: WGPUCommandBufferDescriptor = .{};
	bufferDesc.label = toWGPUStringView("Main Command Buffer");
	buffer := context.gpu.commandEncoderFinish(encoder, *bufferDesc);

	submit: [1] WGPUCommandBuffer = .[buffer];
	context.gpu.queueSubmit(context.graphics.mainQueue, 1, submit.data);
}

render_props :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	target: WGPURenderPassColorAttachment,
	depthTarget: WGPURenderPassDepthStencilAttachment,
	scene: Scene.Scene
) {
	store := scene.store;

	max_id := 0;
	for scene.props
		max_id = max(max_id, it.id);

	passDesc: WGPURenderPassDescriptor = .{};
	passDesc.label = toWGPUStringView("Props Pass");
	passDesc.colorAttachments = *target;
	passDesc.colorAttachmentCount = 1;
	passDesc.depthStencilAttachment = *depthTarget;
	pass := context.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);
	context.gpu.renderPassEncoderSetPipeline(pass, framegraph.geometryPipeline);

	instanced := NewArray(scene.props.count, WFramegraph.Instance, false,, temp);
	for prop_id: 0..max_id {
		instanced.count = 0;
		for scene.props {
			if it.id != prop_id
				continue;
			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.M = it.M;
		}
		if instanced.count == 0 {
			continue;
		}

		context.gpu.queueWriteBuffer(
			context.graphics.mainQueue,
			framegraph.instanceBuffer,
			xx framegraph.instanceBufferCursor,
			instanced.data,
			xx (instanced.count * size_of(WFramegraph.Instance))
		);

		bindGroup: WGPUBindGroup;
		{
			desc: WGPUBindGroupDescriptor = .{};
			desc.label = toWGPUStringView("Prop Bind Group");
			desc.layout = framegraph.geometryBindGroupLayout;
				entries: [8] WGPUBindGroupEntry;
				entries[0].binding = 0;
				entries[0].buffer = framegraph.uniformBuffer;
				entries[0].offset = 0;
				entries[0].size = size_of(WFramegraph.Uniforms);
				entries[1].binding = 1;
				entries[1].buffer = framegraph.instanceBuffer;
				entries[1].offset = xx framegraph.instanceBufferCursor;
				entries[1].size = xx (instanced.count * size_of(WFramegraph.Instance));
				entries[2].binding = 2;
				entries[2].textureView = store.prop_colormap.view;
				entries[3].binding = 3;
				entries[3].textureView = store.prop_colormap.view;
				entries[4].binding = 4;
				entries[4].textureView = store.prop_colormap.view;
				entries[5].binding = 5;
				entries[5].sampler = store.prop_colormap.sampler;
				entries[6].binding = 6;
				entries[6].sampler = store.prop_colormap.sampler;
				entries[7].binding = 7;
				entries[7].sampler = store.prop_colormap.sampler;
			desc.entryCount = entries.count;
			desc.entries = entries.data;
			bindGroup = context.gpu.deviceCreateBindGroup(context.graphics.device, *desc);
		}

		context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
		context.gpu.renderPassEncoderSetVertexBuffer(
			pass,
			0,
			Store.get_wprop(store, xx prop_id).gpu,
			0,
			xx (Store.get_wprop(store, xx prop_id).prim_count * size_of(WFramegraph.Vertex))
		);
		context.gpu.renderPassEncoderDraw(
			pass, xx Store.get_wprop(store, xx prop_id).prim_count, xx instanced.count, 0, 0
		);
		context.gpu.bindGroupRelease(bindGroup);
		framegraph.instanceBufferCursor += xx (instanced.count * size_of(WFramegraph.Instance));
		align_up(*framegraph.instanceBufferCursor, 256);
	}

	context.gpu.renderPassEncoderEnd(pass);
	context.gpu.renderPassEncoderRelease(pass);
}

