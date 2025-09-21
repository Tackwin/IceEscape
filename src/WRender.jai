#import "Basic";
#import "String";
#import "Algebra";
#import "Assets";
#import "Math";
#import "Platform";
#import "Hash_Table";
#import "Rand";
#import "Sort";
Store :: #import "Store";
STB :: #import "stb_image";
Scene :: #import "Scene";
GUI :: #import "GUI";

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
	rng: XORState;

	quadModule: WGPUShaderModule;
	quadPipeline: WGPURenderPipeline;

	instanceBindGroupLayout: WGPUBindGroupLayout;
	textureBindGroupLayout: WGPUBindGroupLayout;
	presentBindGroupLayout: WGPUBindGroupLayout;
	quadBindGroupLayout: WGPUBindGroupLayout;

	geometryModule: WGPUShaderModule;
	geometryPipeline: WGPURenderPipeline;
	geometryPipelineLayout: WGPUPipelineLayout;

	geometryShadowModule: WGPUShaderModule;
	geometryShadowPipeline: WGPURenderPipeline;
	geometryShadowPipelineLayout: WGPUPipelineLayout;

	presentModule: WGPUShaderModule;
	presentPipeline: WGPURenderPipeline;
	presentPipelineLayout: WGPUPipelineLayout;

	depthTexture: WGPUTexture;
	depthView: WGPUTextureView;

	shadowTexture: WTexture;
	hdrTexture: WTexture;

	surfaceTexture: WGPUSurfaceTexture;

	geometryBindGroup: WGPUBindGroup;
	textureBindGroup: WGPUBindGroup;
	particleBindGroup: WGPUBindGroup;

	UI_Uniform :: struct {
		window_size: V2f;
	}
	uiUniformBuffer: WGPUBuffer;
	UI_Instance :: struct {
		pos: V2f;
		size: V2f;
		texture_rect: V4f = .{ 0, 0, 0, 0 }; // x, y, width, height
		color: V4f = .{ 1, 1, 1, 1 };
		z30sdf2: u32 = 0;
		padding0: u32 = 0;
		padding1: u32 = 0;
		padding2: u32 = 0;
	}
	uiInstanceBuffer: WGPUBuffer;
	uiInstances: [..] UI_Instance;

	Present_Uniform :: struct {
		size: V2f;
		exposure: float32 = 1.0;
		gamma: float32 = 2.2;
	}
	presentUniformBuffer: WGPUBuffer;
	Uniforms :: struct {
		V: M4f;
		P: M4f;
		shadowV: M4f;
		shadowP: M4f;

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
		useShadowMap: u32 = 1;
		padding1: u32 = 0;
		color: V4f = .{ 1, 1, 1, 1 };
	};
	instanceBuffer: WGPUBuffer;
	instances: [..] Instance;
	instanceBufferCursor := 0;
};

init_bindgroup_layout :: (framegraph: *WFramegraph) {
	{
		layout: WGPUBindGroupLayoutDescriptor = .{};
		entries: [2] WGPUBindGroupLayoutEntry;
			entries[0].binding = 0;
			entries[0].visibility = WGPUShaderStage_Vertex | WGPUShaderStage_Fragment;
			entries[0].buffer.type = .Uniform;
			entries[0].buffer.hasDynamicOffset = 0;
			entries[0].buffer.minBindingSize = size_of(WFramegraph.Uniforms);
			entries[1].binding = 1;
			entries[1].visibility = WGPUShaderStage_Vertex | WGPUShaderStage_Fragment;
			entries[1].buffer.type = .ReadOnlyStorage;
			entries[1].buffer.hasDynamicOffset = 0;
			entries[1].buffer.minBindingSize = 0;
		layout.entryCount = entries.count;
		layout.entries = entries.data;
		layout.label = toWGPUStringView("Instance Bind Group Layout");
		framegraph.instanceBindGroupLayout =
			context.gpu.deviceCreateBindGroupLayout(context.graphics.device, *layout);
	}
	{
		layout: WGPUBindGroupLayoutDescriptor = .{};
		entries: [6] WGPUBindGroupLayoutEntry;
			entries[0].binding = 0;
			entries[0].visibility = WGPUShaderStage_Fragment;
			entries[0].texture.sampleType = .Float;
			entries[0].texture.viewDimension = ._2D;
			entries[0].texture.multisampled = 0;
			entries[1].binding = 1;
			entries[1].visibility = WGPUShaderStage_Fragment;
			entries[1].texture.sampleType = .Float;
			entries[1].texture.viewDimension = ._2D;
			entries[1].texture.multisampled = 0;
			entries[2].binding = 2;
			entries[2].visibility = WGPUShaderStage_Fragment;
			entries[2].texture.sampleType = .Depth;
			entries[2].texture.viewDimension = ._2D;
			entries[2].texture.multisampled = 0;
			entries[3].binding = 3;
			entries[3].visibility = WGPUShaderStage_Fragment;
			entries[3].sampler.type = .Filtering;
			entries[4].binding = 4;
			entries[4].visibility = WGPUShaderStage_Fragment;
			entries[4].sampler.type = .Filtering;
			entries[5].binding = 5;
			entries[5].visibility = WGPUShaderStage_Fragment;
			entries[5].sampler.type = .Comparison;
		layout.entryCount = entries.count;
		layout.entries = entries.data;
		layout.label = toWGPUStringView("Texture Bind Group Layout");
		framegraph.textureBindGroupLayout =
			context.gpu.deviceCreateBindGroupLayout(context.graphics.device, *layout);
	}
	if false {
		layout: WGPUBindGroupLayoutDescriptor = .{};
		entries: [6] WGPUBindGroupLayoutEntry;
			entries[0].binding = 0;
			entries[0].visibility = WGPUShaderStage_Vertex;
			entries[0].buffer.type = .Uniform;
			entries[0].buffer.hasDynamicOffset = 0;
			entries[0].buffer.minBindingSize = 8;
			entries[1].binding = 1;
			entries[1].visibility = WGPUShaderStage_Vertex | WGPUShaderStage_Fragment;
			entries[1].buffer.type = .ReadOnlyStorage;
			entries[1].buffer.hasDynamicOffset = 0;
			entries[1].buffer.minBindingSize = 0;
			entries[2].binding = 2;
			entries[2].visibility = WGPUShaderStage_Fragment;
			entries[2].texture.sampleType = .Float;
			entries[2].texture.viewDimension = ._2D;
			entries[2].texture.multisampled = 0;
			entries[3].binding = 3;
			entries[3].visibility = WGPUShaderStage_Fragment;
			entries[3].sampler.type = .Filtering;
			entries[4].binding = 4;
			entries[4].visibility = WGPUShaderStage_Fragment;
			entries[4].texture.sampleType = .Float;
			entries[4].texture.viewDimension = ._2D;
			entries[4].texture.multisampled = 0;
			entries[5].binding = 5;
			entries[5].visibility = WGPUShaderStage_Fragment;
			entries[5].sampler.type = .Filtering;
		layout.entryCount = entries.count;
		layout.entries = entries.data;
		layout.label = toWGPUStringView("UI Bind Group Layout");
		framegraph.quadBindGroupLayout =
			context.gpu.deviceCreateBindGroupLayout(context.graphics.device, *layout);
	}
}

init_quad_pipeline :: (framegraph: *WFramegraph, store: *Store.Store) {
	{
		desc: WGPUShaderModuleDescriptor = .{};
		wgsl: WGPUShaderSourceWGSL = .{};
		wgsl.code = toWGPUStringView(store.quad_shader.code);
		wgsl.chain.next = null;
		wgsl.chain.sType = .ShaderSourceWGSL;
		desc.nextInChain = *wgsl.chain;
		framegraph.quadModule = context.gpu.deviceCreateShaderModule(
			context.graphics.device, *desc
		);
	}
	{
		desc: WGPURenderPipelineDescriptor = .{};
		desc.label = toWGPUStringView("Quad Pipeline");
		desc.layout = null;
		desc.vertex.module = framegraph.quadModule;
		desc.vertex.entryPoint = toWGPUStringView("vs");
		desc.vertex.bufferCount = 0;
		desc.vertex.buffers = null;
		desc.primitive.topology = .WGPUPrimitiveTopology_TriangleList;
		desc.primitive.stripIndexFormat = .Undefined;
		desc.primitive.frontFace = .CCW;
		desc.primitive.cullMode = .None;
		desc.primitive.unclippedDepth = 0;

		desc.depthStencil = null;

		desc.multisample.count = 1;
		desc.multisample.mask = 0xFFFFFFFF;
		desc.multisample.alphaToCoverageEnabled = 0;
			fragment: WGPUFragmentState = .{};
			fragment.module = framegraph.quadModule;
			fragment.entryPoint = toWGPUStringView("fs");
				targets: [1] WGPUColorTargetState;
				targets[0].format = .BGRA8Unorm;
					blend: WGPUBlendState = .{};
					blend.color.operation = .Add;
					blend.color.srcFactor = .SrcAlpha;
					blend.color.dstFactor = .OneMinusSrcAlpha;
					blend.alpha.operation = .Add;
					blend.alpha.srcFactor = .One;
					blend.alpha.dstFactor = .OneMinusSrcAlpha;
				targets[0].blend = *blend;
				targets[0].writeMask = WGPUColorWriteMask_All;
			fragment.targets = targets.data;
			fragment.targetCount = targets.count;
		desc.fragment = *fragment;

		framegraph.quadPipeline = context.gpu.deviceCreateRenderPipeline(
			context.graphics.device, *desc
		);

		framegraph.quadBindGroupLayout = context.gpu.renderPipelineGetBindGroupLayout(
			framegraph.quadPipeline, 0
		);
	}
}

init_present_pipeline :: (framegraph: *WFramegraph, store: *Store.Store) {
	{
		desc: WGPUShaderModuleDescriptor = .{};
		wgsl: WGPUShaderSourceWGSL = .{};
		wgsl.code = toWGPUStringView(store.present_shader.code);
		wgsl.chain.next = null;
		wgsl.chain.sType = .ShaderSourceWGSL;
		desc.nextInChain = *wgsl.chain;
		framegraph.presentModule = context.gpu.deviceCreateShaderModule(
			context.graphics.device, *desc
		);
	}

	{
		// layout: WGPUPipelineLayoutDescriptor = .{};
		// layout.label = toWGPUStringView("Present Pipeline Layout");
		// layoutEntries: [1] WGPUBindGroupLayout;
		// layoutEntries[0] = framegraph.textureBindGroupLayout;
		// layout.bindGroupLayoutCount = 1;
		// layout.bindGroupLayouts = layoutEntries.data;
		// framegraph.presentPipelineLayout = context.gpu.deviceCreatePipelineLayout(
		// 	context.graphics.device, *layout
		// );

		desc: WGPURenderPipelineDescriptor = .{};
		desc.label = toWGPUStringView("Present Pipeline");
		desc.layout = null;
		desc.vertex.module = framegraph.presentModule;
		desc.vertex.entryPoint = toWGPUStringView("vs");

		desc.vertex.bufferCount = 0;
		desc.vertex.buffers = null;

		desc.primitive.topology = .WGPUPrimitiveTopology_TriangleList;
		desc.primitive.stripIndexFormat = .Undefined;
		desc.primitive.frontFace = .CCW;
		desc.primitive.cullMode = .None;
		desc.primitive.unclippedDepth = 0;

		desc.depthStencil = null;

		desc.multisample.count = 1;
		desc.multisample.mask = 0xFFFFFFFF;
		desc.multisample.alphaToCoverageEnabled = 0;

			fragment: WGPUFragmentState = .{};
			fragment.module = framegraph.presentModule;
			fragment.entryPoint = toWGPUStringView("fs");
				targets: [1] WGPUColorTargetState;
				targets[0].format = .BGRA8Unorm;
				targets[0].blend = null;
				targets[0].writeMask = WGPUColorWriteMask_All;
			fragment.targets = targets.data;
			fragment.targetCount = targets.count;
		desc.fragment = *fragment;

		framegraph.presentPipeline = context.gpu.deviceCreateRenderPipeline(
			context.graphics.device, *desc
		);

		framegraph.presentBindGroupLayout = context.gpu.renderPipelineGetBindGroupLayout(
			framegraph.presentPipeline, 0
		);
	}
}

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
		layout: WGPUPipelineLayoutDescriptor = .{};
		layout.label = toWGPUStringView("Geometry Pipeline Layout");
		layoutEntries: [2] WGPUBindGroupLayout;
		layoutEntries[0] = framegraph.instanceBindGroupLayout;
		layoutEntries[1] = framegraph.textureBindGroupLayout;
		layout.bindGroupLayoutCount = 2;
		layout.bindGroupLayouts = layoutEntries.data;
		framegraph.geometryPipelineLayout = context.gpu.deviceCreatePipelineLayout(
			context.graphics.device, *layout
		);

		desc: WGPURenderPipelineDescriptor = .{};
		desc.label = toWGPUStringView("Geometry Pipeline");
		desc.layout = framegraph.geometryPipelineLayout;
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

		desc.multisample.count = 4;
		desc.multisample.mask = 0xFFFFFFFF;
		desc.multisample.alphaToCoverageEnabled = 0;

			fragment: WGPUFragmentState = .{};
			fragment.module = framegraph.geometryModule;
			fragment.entryPoint = toWGPUStringView("fs");
				targets: [1] WGPUColorTargetState;
				targets[0].format = .RGBA16Float;

					blend: WGPUBlendState = .{};
					blend.color.operation = .Add;
					blend.color.srcFactor = .SrcAlpha;
					blend.color.dstFactor = .OneMinusSrcAlpha;
					blend.alpha.operation = .Add;
					blend.alpha.srcFactor = .One;
					blend.alpha.dstFactor = .OneMinusSrcAlpha;

				targets[0].blend = *blend;
				targets[0].writeMask = WGPUColorWriteMask_All;
			fragment.targets = targets.data;
			fragment.targetCount = targets.count;
		desc.fragment = *fragment;

		framegraph.geometryPipeline = context.gpu.deviceCreateRenderPipeline(
			context.graphics.device, *desc
		);
	}
}

init_geometry_shadow_pipeline :: (framegraph: *WFramegraph, store: *Store.Store) {
{
		desc: WGPUShaderModuleDescriptor = .{};
		wgsl: WGPUShaderSourceWGSL = .{};
		wgsl.code = toWGPUStringView(store.geometry_shadow_shader.code);
		wgsl.chain.next = null;
		wgsl.chain.sType = .ShaderSourceWGSL;
		desc.nextInChain = *wgsl.chain;
		framegraph.geometryShadowModule = context.gpu.deviceCreateShaderModule(
			context.graphics.device, *desc
		);
	}

	{
		layout: WGPUPipelineLayoutDescriptor = .{};
		layout.label = toWGPUStringView("Geometry Shadow Pipeline Layout");
		layout.bindGroupLayoutCount = 1;
		layout.bindGroupLayouts = *framegraph.instanceBindGroupLayout;
		framegraph.geometryShadowPipelineLayout = context.gpu.deviceCreatePipelineLayout(
			context.graphics.device, *layout
		);

		desc: WGPURenderPipelineDescriptor = .{};
		desc.label = toWGPUStringView("Geometry Shadow Pipeline");
		desc.layout = framegraph.geometryShadowPipelineLayout;
		desc.vertex.module = framegraph.geometryShadowModule;
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

		desc.fragment = null;

		framegraph.geometryShadowPipeline = context.gpu.deviceCreateRenderPipeline(
			context.graphics.device, *desc
		);

	}
}

init_framegraph :: (framegraph: *WFramegraph, store: *Store.Store) {
	framegraph.rng = seed(123456789);
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
		desc.label = toWGPUStringView("Present Uniform Buffer");
		desc.usage = WGPUBufferUsage_Uniform | WGPUBufferUsage_CopyDst;
		desc.size = size_of(WFramegraph.Present_Uniform);
		desc.mappedAtCreation = 0;
		framegraph.presentUniformBuffer =
			context.gpu.deviceCreateBuffer(context.graphics.device, *desc);
	}
	{
		desc: WGPUBufferDescriptor = .{};
		desc.label = toWGPUStringView("UI Uniform Buffer");
		desc.usage = WGPUBufferUsage_Uniform | WGPUBufferUsage_CopyDst;
		desc.size = size_of(WFramegraph.UI_Uniform);
		desc.mappedAtCreation = 0;
		framegraph.uiUniformBuffer = context.gpu.deviceCreateBuffer(context.graphics.device, *desc);
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
		desc: WGPUBufferDescriptor = .{};
		desc.label = toWGPUStringView("UI Instance Buffer");
		desc.usage = WGPUBufferUsage_Storage | WGPUBufferUsage_CopyDst;
		desc.size = 64 * 1024 * size_of(WFramegraph.UI_Instance);
		desc.mappedAtCreation = 0;
		framegraph.uiInstanceBuffer =
			context.gpu.deviceCreateBuffer(context.graphics.device, *desc);
	}
	{
		desc: WGPUTextureDescriptor = .{};
		desc.label = toWGPUStringView("Depth Texture");
		desc.usage = WGPUTextureUsage_RenderAttachment | WGPUTextureUsage_TextureBinding;
		desc.size.width = 1366;
		desc.size.height = 768;
		desc.size.depthOrArrayLayers = 1;
		desc.mipLevelCount = 1;
		desc.sampleCount = 4;
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

	{
		desc: WGPUTextureDescriptor = .{};
		desc.label = toWGPUStringView("HDR Texture");
		desc.usage = WGPUTextureUsage_RenderAttachment | WGPUTextureUsage_TextureBinding;
		desc.size.width = 1366;
		desc.size.height = 768;
		desc.size.depthOrArrayLayers = 1;
		desc.mipLevelCount = 1;
		desc.sampleCount = 4;
		desc.dimension = ._2D;
		desc.format = .RGBA16Float;
		framegraph.hdrTexture.gpu = context.gpu.deviceCreateTexture(context.graphics.device, *desc);

		viewDesc: WGPUTextureViewDescriptor = .{};
		viewDesc.label = toWGPUStringView("HDR Texture View");
		viewDesc.format = .RGBA16Float;
		viewDesc.dimension = ._2D;
		viewDesc.aspect = .All;
		framegraph.hdrTexture.view = context.gpu.textureCreateView(framegraph.hdrTexture.gpu, null);

		samplerDesc: WGPUSamplerDescriptor = .{};
		samplerDesc.label = toWGPUStringView("HDR Texture Sampler");
		samplerDesc.addressModeU = .ClampToEdge;
		samplerDesc.addressModeV = .ClampToEdge;
		samplerDesc.addressModeW = .ClampToEdge;
		samplerDesc.magFilter = .Linear;
		samplerDesc.minFilter = .Linear;
		samplerDesc.mipmapFilter = .Linear;
		samplerDesc.lodMinClamp = 0;
		samplerDesc.lodMaxClamp = 32;
		samplerDesc.maxAnisotropy = 1;
		framegraph.hdrTexture.sampler =
			context.gpu.deviceCreateSampler(context.graphics.device, *samplerDesc);
	}

	{
		desc: WGPUTextureDescriptor = .{};
		desc.label = toWGPUStringView("Shadow Texture");
		desc.usage = WGPUTextureUsage_RenderAttachment | WGPUTextureUsage_TextureBinding;
		desc.size.width = 4096;
		desc.size.height = 4096;
		desc.size.depthOrArrayLayers = 1;
		desc.mipLevelCount = 1;
		desc.sampleCount = 1;
		desc.dimension = ._2D;
		desc.format = .Depth32Float;
		framegraph.shadowTexture.gpu =
			context.gpu.deviceCreateTexture(context.graphics.device, *desc);

		viewDesc: WGPUTextureViewDescriptor = .{};
		viewDesc.label = toWGPUStringView("Shadow Texture View");
		viewDesc.format = .Depth32Float;
		viewDesc.dimension = ._2D;
		viewDesc.aspect = .DepthOnly;
		framegraph.shadowTexture.view =
			context.gpu.textureCreateView(framegraph.shadowTexture.gpu, null);

		samplerDesc: WGPUSamplerDescriptor = .{};
		samplerDesc.label = toWGPUStringView("Shadow Texture Sampler");
		samplerDesc.addressModeU = .ClampToEdge;
		samplerDesc.addressModeV = .ClampToEdge;
		samplerDesc.addressModeW = .ClampToEdge;
		samplerDesc.magFilter = .Linear;
		samplerDesc.minFilter = .Linear;
		samplerDesc.mipmapFilter = .Linear;
		samplerDesc.compare = .Less;
		samplerDesc.lodMinClamp = 0;
		samplerDesc.lodMaxClamp = 32;
		samplerDesc.maxAnisotropy = 1;
		framegraph.shadowTexture.sampler =
			context.gpu.deviceCreateSampler(context.graphics.device, *samplerDesc);
	}

	init_bindgroup_layout(framegraph);

	if store.geometry_shader.dirty {
		store.geometry_shader.dirty = false;
		init_geometry_pipeline(framegraph, store);
	}

	if store.geometry_shadow_shader.dirty {
		store.geometry_shadow_shader.dirty = false;
		init_geometry_shadow_pipeline(framegraph, store);
	}

	if store.present_shader.dirty {
		store.present_shader.dirty = false;
		init_present_pipeline(framegraph, store);
	}

	if store.quad_shader.dirty {
		store.quad_shader.dirty = false;
		init_quad_pipeline(framegraph, store);
	}

	array_reserve(*framegraph.instances, 64 * 1024);
	array_reserve(*framegraph.uiInstances, 1024);

	framegraph.geometryBindGroup =texture_bind_group(
		framegraph, "Typical textures", *store.colormaps, null, *framegraph.shadowTexture
	);
	framegraph.textureBindGroup = texture_bind_group(
		framegraph,
		"Terrain textures",
		*store.terrain_tile_albedo,
		*store.terrain_tile_normal,
		*framegraph.shadowTexture
	);
	framegraph.particleBindGroup = texture_bind_group(
		framegraph,
		"Particle textures",
		*store.particle_texture,
		null,
		null
	);
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

present_bind_group :: (
	framegraph: *WFramegraph,
	name: string,
	hdr: WTexture,
	uniform: WFramegraph.Present_Uniform
) -> WGPUBindGroup {
	desc: WGPUBindGroupDescriptor = .{};
	desc.label = toWGPUStringView(tprint("% Present Bind Group", name));
	desc.layout = framegraph.presentBindGroupLayout;
	entries: [2] WGPUBindGroupEntry;
	entries[0].binding = 0;
	entries[0].buffer = framegraph.presentUniformBuffer;
	entries[0].offset = 0;
	entries[0].size = size_of(WFramegraph.Present_Uniform);
	entries[1].binding = 1;
	entries[1].textureView = hdr.view;
	// entries[2].binding = 2;
	// entries[2].sampler = hdr.sampler;
	desc.entryCount = entries.count;
	desc.entries = entries.data;
	return context.gpu.deviceCreateBindGroup(context.graphics.device, *desc);
}

ui_instance_bind_group :: (
	framegraph: *WFramegraph,
	name: string,
	instanced_count: int,
	albedo_map: WTexture,
	sdf_map: WTexture
) -> WGPUBindGroup {
	desc: WGPUBindGroupDescriptor = .{};
	desc.label = toWGPUStringView("UI Instance Bind Group");
	desc.layout = framegraph.quadBindGroupLayout;
	entries: [6] WGPUBindGroupEntry;
	entries[0].binding = 0;
	entries[0].buffer = framegraph.uiUniformBuffer;
	entries[0].offset = 0;
	entries[0].size = size_of(WFramegraph.UI_Uniform);
	entries[1].binding = 1;
	entries[1].buffer = framegraph.uiInstanceBuffer;
	entries[1].offset = 0;
	entries[1].size = xx (framegraph.uiInstances.count * size_of(WFramegraph.UI_Instance));
	entries[2].binding = 2;
	entries[2].textureView = albedo_map.view;
	entries[3].binding = 3;
	entries[3].sampler = albedo_map.sampler;
	entries[4].binding = 4;
	entries[4].textureView = sdf_map.view;
	entries[5].binding = 5;
	entries[5].sampler = sdf_map.sampler;
	desc.entryCount = entries.count;
	desc.entries = entries.data;
	return context.gpu.deviceCreateBindGroup(context.graphics.device, *desc);
}


instance_bind_group :: (
	framegraph: *WFramegraph,
	name: string,
	instanced_count: int
) -> WGPUBindGroup {
	desc: WGPUBindGroupDescriptor = .{};
	desc.label = toWGPUStringView(tprint("% Instance Bind Group", name));
	desc.layout = framegraph.instanceBindGroupLayout;
	entries: [2] WGPUBindGroupEntry;
	entries[0].binding = 0;
	entries[0].buffer = framegraph.uniformBuffer;
	entries[0].offset = 0;
	entries[0].size = size_of(WFramegraph.Uniforms);
	entries[1].binding = 1;
	entries[1].buffer = framegraph.instanceBuffer;
	entries[1].offset = xx framegraph.instanceBufferCursor;
	entries[1].size = xx (instanced_count * size_of(WFramegraph.Instance));
	desc.entryCount = entries.count;
	desc.entries = entries.data;
	return context.gpu.deviceCreateBindGroup(context.graphics.device, *desc);
}

texture_bind_group :: (
	framegraph: *WFramegraph,
	name: string,
	albedo: *WTexture = null,
	normal: *WTexture = null,
	shadow: *WTexture = null
) -> WGPUBindGroup {
	desc: WGPUBindGroupDescriptor = .{};
	desc.label = toWGPUStringView(tprint("% Bind Group", name));
	desc.layout = framegraph.textureBindGroupLayout;
	entries: [6] WGPUBindGroupEntry;

	entries[0].binding = 0;
	if albedo {
		entries[0].textureView = albedo.view;
		entries[1].textureView = albedo.view;
		entries[2].textureView = albedo.view;
	}

	entries[1].binding = 1;
	if normal
		entries[1].textureView = normal.view;

	entries[2].binding = 2;
	entries[2].textureView = framegraph.shadowTexture.view;

	entries[3].binding = 3;
	if albedo {
		entries[3].sampler = albedo.sampler;
		entries[4].sampler = albedo.sampler;
		entries[5].sampler = albedo.sampler;
	}

	entries[4].binding = 4;
	if normal
		entries[4].sampler = normal.sampler;

	entries[5].binding = 5;
	entries[5].sampler = framegraph.shadowTexture.sampler;
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

Extra :: struct {
	Number :: struct {
		M: M4f;
		number: u8;
	}
	numbers: [..] Number;

	Cylinder :: struct {
		M: M4f;
		color: V3f;
	}
	cylinders: [..] Cylinder;

	Sphere :: struct {
		M: M4f;
		color: V3f;
	}
	spheres: [..] Sphere;

	Quad :: struct {
		M: M4f;
		texture_rect: V4f;
		color: V4f;
	}
	quads: [..] Quad;
}

reserve :: (extra: *Extra, count: int) {
	extra.numbers.allocator = temp;
	array_reserve(*extra.numbers, count);
	extra.cylinders.allocator = temp;
	array_reserve(*extra.cylinders, count);
	extra.spheres.allocator = temp;
	array_reserve(*extra.spheres, count);
	extra.quads.allocator = temp;
	array_reserve(*extra.quads, count);
}

clear :: (extra: *Extra) {
	extra.numbers.count = 0;
	extra.cylinders.count = 0;
	extra.spheres.count = 0;
	extra.quads.count = 0;
}

free :: (extra: *Extra) {
	array_free(extra.numbers);
	array_free(extra.cylinders);
	array_free(extra.spheres);
	array_free(extra.quads);
}

render :: (framegraph: *WFramegraph, scene: Scene.Scene, store: Store.Store) {
	surfaceTexture: WGPUSurfaceTexture;
	context.gpu.surfaceGetCurrentTexture(context.graphics.surface, *surfaceTexture);
	surfaceView := context.gpu.textureCreateView(surfaceTexture.texture, null);
	defer {
		context.gpu.textureViewRelease(surfaceView);
	}
	encoder := context.gpu.deviceCreateCommandEncoder(context.graphics.device, null);
	defer {
		context.gpu.commandEncoderRelease(encoder);
	}

	framegraph.typicalUniform = .{};
	framegraph.typicalUniform.V =
		Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	framegraph.typicalUniform.P =
		Scene.perspective(scene.camera);
	center := V3f.{ 0, 0, 0 };
	center.x += scene.terrain.tiles_count.x / 2.0;
	center.y += scene.terrain.tiles_count.y / 2.0;
	if false && scene.players.count > 0 {
		center.x = scene.players[0].client.position.x +
			random_uniform(*framegraph.rng, -0.001, 0.001);
		center.y = scene.players[0].client.position.y +
			random_uniform(*framegraph.rng, -0.001, 0.001);
	}
	framegraph.typicalUniform.shadowV =
		Scene.look_at(center + V3f.{ 100, 100, 100 }, center, V3f.{ 0, 1, 0 });
	framegraph.typicalUniform.shadowP =
		Scene.orthographic(-40, 40, -40, 40, 0.1, 500);
	framegraph.typicalUniform.sun_dir = normalize(V3f.{ -1, -1, -1 });
	framegraph.typicalUniform.sun_color = V3f.{ 1, 1, 1 };
	framegraph.typicalUniform.sun_strength = 0.5;

	writeTo(framegraph.uniformBuffer, 0, *framegraph.typicalUniform);
	
	hdrAttachment: WGPURenderPassColorAttachment = .{};
	hdrAttachment.view = framegraph.hdrTexture.view;
	hdrAttachment.depthSlice = 0;
	hdrAttachment.loadOp = .Clear;
	hdrAttachment.storeOp = .Store;
	hdrAttachment.clearValue = .{ 0.3, 0.3, 0.3, 1.0 };

	surfaceAttachment: WGPURenderPassColorAttachment = .{};
	surfaceAttachment.view = surfaceView;
	surfaceAttachment.depthSlice = 0;
	surfaceAttachment.loadOp = .Clear;
	surfaceAttachment.storeOp = .Store;
	surfaceAttachment.clearValue = .{ 0.3, 0.3, 0.3, 1.0 };
	
	uiAttachment: WGPURenderPassColorAttachment = .{};
	uiAttachment.view = surfaceView;
	uiAttachment.depthSlice = 0;
	uiAttachment.loadOp = .Load;
	uiAttachment.storeOp = .Store;
	uiAttachment.clearValue = .{ 0.3, 0.3, 0.3, 1.0 };

	depthAttachment: WGPURenderPassDepthStencilAttachment = .{};
	depthAttachment.view = framegraph.depthView;
	depthAttachment.depthLoadOp = .Clear;
	depthAttachment.depthStoreOp = .Store;
	depthAttachment.depthClearValue = 1.0;
	depthAttachment.stencilLoadOp = .Undefined;
	depthAttachment.stencilStoreOp = .Undefined;
	depthAttachment.stencilClearValue = 0;
	
	shadowAttachment: WGPURenderPassDepthStencilAttachment = .{};
	shadowAttachment.view = framegraph.shadowTexture.view;
	shadowAttachment.depthLoadOp = .Clear;
	shadowAttachment.depthStoreOp = .Store;
	shadowAttachment.depthClearValue = 1.0;
	shadowAttachment.stencilLoadOp = .Undefined;
	shadowAttachment.stencilStoreOp = .Undefined;
	shadowAttachment.stencilClearValue = 0;

	extra: Extra;
	reserve(*extra, 16);
	defer {
		free(*extra);
	}

	if true {
		clear(*extra);

		framegraph.instanceBufferCursor = 0;
		framegraph.instances.count = 0;
		passDesc: WGPURenderPassDescriptor = .{};
		passDesc.label = toWGPUStringView("Shadow Pass");
		passDesc.colorAttachments = null;
		passDesc.colorAttachmentCount = 0;
		passDesc.depthStencilAttachment = *shadowAttachment;
		shadowPass := context.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);
		context.gpu.renderPassEncoderSetPipeline(
			shadowPass, framegraph.geometryShadowPipeline
		);

		render_players(framegraph, encoder, shadowPass, scene, store);
		render_keys(framegraph, encoder, shadowPass, scene, store);
		render_skulls(framegraph, encoder, shadowPass, scene, store);
		render_shurikens(framegraph, encoder, shadowPass, scene, store);
		render_standin(framegraph, encoder, shadowPass, scene, store);
		render_props(framegraph, encoder, shadowPass, scene, store);
		render_gates(framegraph, encoder, shadowPass, scene, store);
		render_tombstones(framegraph, encoder, shadowPass, scene, store);
		render_robots(framegraph, encoder, shadowPass, scene, store, *extra);
		render_flags(framegraph, encoder, shadowPass, scene, store, *extra);
		render_extra(framegraph, encoder, shadowPass, scene, store, *extra);

		context.gpu.renderPassEncoderEnd(shadowPass);
		context.gpu.renderPassEncoderRelease(shadowPass);
	}

	if true {
		clear(*extra);

		framegraph.instanceBufferCursor = 0;
		passDesc: WGPURenderPassDescriptor = .{};
		passDesc.label = toWGPUStringView("Geometry Pass");
		passDesc.colorAttachments = *hdrAttachment;
		passDesc.colorAttachmentCount = 1;
		passDesc.depthStencilAttachment = *depthAttachment;
		geometryPass := context.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);
		context.gpu.renderPassEncoderSetPipeline(geometryPass, framegraph.geometryPipeline);

		context.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.geometryBindGroup, 0, null
		);

		render_players(framegraph, encoder, geometryPass, scene, store);
		render_keys(framegraph, encoder, geometryPass, scene, store);
		render_skulls(framegraph, encoder, geometryPass, scene, store);
		render_shurikens(framegraph, encoder, geometryPass, scene, store);
		render_standin(framegraph, encoder, geometryPass, scene, store);
		render_props(framegraph, encoder, geometryPass, scene, store);
		render_gates(framegraph, encoder, geometryPass, scene, store);
		render_tombstones(framegraph, encoder, geometryPass, scene, store);
		render_robots(framegraph, encoder, geometryPass, scene, store, *extra);
		render_flags(framegraph, encoder, geometryPass, scene, store, *extra);
		render_explosions(framegraph, encoder, geometryPass, scene, store, *extra);

		context.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.textureBindGroup, 0, null
		);

		render_terrain(framegraph, encoder, geometryPass, scene, store);
		
		context.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.particleBindGroup, 0, null
		);

		render_particles(framegraph, encoder, geometryPass, scene, store, *extra);

		context.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.geometryBindGroup, 0, null
		);
		render_within_zones(framegraph, encoder, geometryPass, scene, store, *extra);
		render_extra(framegraph, encoder, geometryPass, scene, store, *extra);
		context.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.particleBindGroup, 0, null
		);
		render_extra_quads(framegraph, encoder, geometryPass, scene, store, *extra);

		context.gpu.renderPassEncoderEnd(geometryPass);
		context.gpu.renderPassEncoderRelease(geometryPass);
	}

	if true {
		
	}

	if true {
		passDesc: WGPURenderPassDescriptor = .{};
		passDesc.label = toWGPUStringView("Present Pass");
		passDesc.colorAttachments = *surfaceAttachment;
		passDesc.colorAttachmentCount = 1;
		passDesc.depthStencilAttachment = null;
		presentPass := context.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);

		context.gpu.renderPassEncoderSetPipeline(presentPass, framegraph.presentPipeline);
		presentUniform: WFramegraph.Present_Uniform = .{};
		presentUniform.size = V2f.{ 1366, 768 };
		presentUniform.exposure = 1.0;
		presentUniform.gamma = 2.2;
		writeTo(framegraph.presentUniformBuffer, 0, *presentUniform);
		bindGroup := present_bind_group(
			framegraph, "Present", *framegraph.hdrTexture, presentUniform
		);
		context.gpu.renderPassEncoderSetBindGroup(presentPass, 0, bindGroup, 0, null);
		defer context.gpu.bindGroupRelease(bindGroup);
		context.gpu.renderPassEncoderDraw(presentPass, 6, 1, 0, 0);

		// Fullscreen textured quad
		context.gpu.renderPassEncoderEnd(presentPass);
		context.gpu.renderPassEncoderRelease(presentPass);
	}

	if true {
		passDesc: WGPURenderPassDescriptor = .{};
		passDesc.label = toWGPUStringView("UI Pass");
		passDesc.colorAttachments = *uiAttachment;
		passDesc.colorAttachmentCount = 1;
		passDesc.depthStencilAttachment = null;
		uiPass := context.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);

		context.gpu.renderPassEncoderSetPipeline(uiPass, framegraph.quadPipeline);

		uniforms: WFramegraph.UI_Uniform = .{};
		uniforms.window_size = V2f.{ 1366, 768 };
		writeTo(framegraph.uiUniformBuffer, 0, *uniforms);

		framegraph.uiInstances.count = 0;

		for GUI.IM.quads {
			framegraph.uiInstances.count += 1;
			instance := *framegraph.uiInstances[framegraph.uiInstances.count - 1];
			instance.* = .{};
			instance.pos = it.pos;
			instance.size = it.size;
			instance.color = it.color;
			instance.z30sdf2 = xx (it.z * 400);
			instance.texture_rect = it.texture_rect;
		}

		for GUI.IM.chars {
			framegraph.uiInstances.count += 1;
			instance := *framegraph.uiInstances[framegraph.uiInstances.count - 1];
			instance.* = .{};

			sprite := MAIN_FONT.sprites[it.id];

			x := it.pos.x;
			y := it.pos.y;
			width := sprite.sourceWidth * it.height / MAIN_FONT.height;
			height := sprite.sourceHeight * it.height / MAIN_FONT.height;
			pos := V2f.{
				xx (sprite.positionX - sprite.padding), xx (sprite.positionY - sprite.padding)
			};
			size := V2f.{ xx sprite.sourceWidth, xx sprite.sourceHeight };
			pos.x /= MAIN_FONT.atlas.width;
			pos.y /= MAIN_FONT.atlas.height;
			pos.y = 1.0 - pos.y;
			size.x /= MAIN_FONT.atlas.width;
			size.y /= MAIN_FONT.atlas.height;
			pos.y -= size.y;

			instance.pos = V2f.{ x, y };
			instance.size = V2f.{ width, height };
			instance.texture_rect = .{ pos.x, pos.y, size.x, size.y };
			instance.z30sdf2 = (it.z * 400).(u32) + 1;
			instance.color = v4(it.color, 1.0);
		}

		if framegraph.uiInstances.count > 0 {
			quick_sort(
				framegraph.uiInstances,
				(a: WFramegraph.UI_Instance, b: WFramegraph.UI_Instance) -> int {
					az := a.z30sdf2 / 4;
					bz := b.z30sdf2 / 4;
					if az < bz
						return -1;
					if az > bz
						return 1;
					return 0;
				});

			bindGroup := ui_instance_bind_group(
				framegraph,
				"UI Instances",
				framegraph.uiInstances.count,
				store.ui_atlas,
				store.font_atlas
			);
			context.gpu.renderPassEncoderSetBindGroup(uiPass, 0, bindGroup, 0, null);
			defer context.gpu.bindGroupRelease(bindGroup);
			writeTo(framegraph.uiInstanceBuffer, 0, framegraph.uiInstances);
			context.gpu.renderPassEncoderDraw(uiPass, 6, xx framegraph.uiInstances.count, 0, 0);
		}

		context.gpu.renderPassEncoderEnd(uiPass);
		context.gpu.renderPassEncoderRelease(uiPass);
	}

	bufferDesc: WGPUCommandBufferDescriptor = .{};
	bufferDesc.label = toWGPUStringView("Main Command Buffer");
	buffer := context.gpu.commandEncoderFinish(encoder, *bufferDesc);
	defer context.gpu.commandBufferRelease(buffer);

	submit: [1] WGPUCommandBuffer = .[buffer];
	context.gpu.queueSubmit(context.graphics.mainQueue, 1, submit.data);
}

render_particles :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	dt := normalize(scene.camera.target - scene.camera.position);
	instanced := NewArray(scene.particles.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for scene.particles {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.identity();
		instance.M *= M4f.translate(it.position);
		instance.M *= to_rotation_matrix(from_unit_vectors(V3f.{ 0, 0, -1 }, dt));
		instance.M *= scale_matrix(it.size);
		instance.M *= to_rotation_matrix(axis_angle(V3f.{ 0, 0, 1 }, it.rotation));
		instance.M *= M4f.translate(V3f.{ -0.5, -0.5, 0 });
		instance.texture_rect = .{
			it.texture_rec.x, it.texture_rec.y, it.texture_rec.z, it.texture_rec.w
		};
		instance.color = .{ it.color.x, it.color.y, it.color.z, it.color.w };
		if it.fade_out_time > 0 {
			t := clamp((it.lifetime - it.age) / it.fade_out_time, 0.0, 1.0);
			instance.color.w *= t;
		}
	}
	if instanced.count == 0
		return;

	bindGroup := instance_bind_group(framegraph, "Particles bind group", instanced.count);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
	encode_and_draw(framegraph, pass, store.tile_model, instanced.count);
}

render_extra  :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	render_extra_numbers(framegraph, encoder, pass, scene, store, extra);
	render_extra_cylinders(framegraph, encoder, pass, scene, store, extra);
}

render_extra_cylinders :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	instanced := NewArray(extra.cylinders.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for extra.cylinders {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = it.M;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count == 0
		return;

	bindGroup := instance_bind_group(framegraph, "Extra Cylinders", instanced.count);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
	encode_and_draw(framegraph, pass, store.unit_cylinder_model, instanced.count);
}

render_extra_numbers :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	instanced := NewArray(extra.numbers.count, WFramegraph.Instance, false,, temp);
	for n: 0..9 {
		instanced.count = 0;
		for extra.numbers {
			if it.number != n
				continue;

			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			instance.M = it.M;
			instance.texture_rect = Store.Colormaps_Rect.vehicle;
		}
		if instanced.count == 0
			continue;

		bindGroup := instance_bind_group(framegraph, tprint("Number %", n), instanced.count);
		context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
		defer context.gpu.bindGroupRelease(bindGroup);
		writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
		encode_and_draw(framegraph, pass, Store.get_number_model(store, n), instanced.count);

		instanced.count = 0;
	}
}

render_extra_quads :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	instanced := NewArray(extra.quads.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for extra.quads {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = it.M;
		instance.texture_rect = it.texture_rect;
		instance.color = it.color;
	}
	if instanced.count == 0
		return;

	bindGroup := instance_bind_group(framegraph, "Extra Quads", instanced.count);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
	encode_and_draw(framegraph, pass, store.tile_model, instanced.count);
}

render_within_zones :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	instanced := NewArray(scene.within_zones.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;

	for scene.within_zones {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(v3(it.pos, 0.001));
		instance.M *= scale_matrix(v3(it.size, 1.0));
		instance.color = V4f.{ 1.0, 1.0, 1.0, 0.125 };
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0 {
		bindGroup := instance_bind_group(framegraph, "Within zone", instanced.count);
		context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
		defer context.gpu.bindGroupRelease(bindGroup);
		writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
		encode_and_draw(framegraph, pass, store.indicator_outline_model, instanced.count);
	}

	instanced.count = 0;
	for scene.within_zones {
		if it.time_stayed <= 0.0
			continue;
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];

		instance.M = M4f.translate(v3(it.pos + V2f.{ it.size.x * 0.15, it.size.y * 0.15 }, 0.001));
		t := clamp(it.time_stayed / it.time_to_stay, 0.0, 1.0);
		t = t * 0.7;
		t *= it.size.y;
		instance.M *= scale_matrix(V3f.{it.size.x * 0.7, t , 1.0});
		instance.color = V4f.{ 1.0, 1.0, 1.0, 0.25 };
	}
	if instanced.count > 0 {
		bindGroup := instance_bind_group(framegraph, "Within zone stroked", instanced.count);
		context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
		defer context.gpu.bindGroupRelease(bindGroup);
		writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
		encode_and_draw(framegraph, pass, store.indicator_stroke_model, instanced.count);
	}


	for scene.within_zones {
		if it.time_stayed >= it.time_to_stay
			continue;

		needed := ceil(scene.players.count * it.min_player_percent).(int);
		left := needed - it.last_player_count;

		pos := v3(it.pos, 0.0) + V3f.{ it.size.x / 2, -0.5, 0.5 };
		while left > 0 {
			M := M4f.translate(pos);
			if it.count_changed_juice_t > 0 {
				M = M * scale_matrix(
					1.0 + ease_up_and_back(1.0 - it.count_changed_juice_t) * 0.5
				);
			}

			number: Extra.Number;
			number.M = M;
			number.number = xx (left % 10);
			array_add(*extra.numbers, number);

			left /= 10;
			pos.x -= 0.3;
		}
	}
}

render_explosions :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	instanced := NewArray(scene.explosions.count, WFramegraph.Instance, false,, temp);
	instanced.count = 0;
	for scene.explosions {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		ts := ease_out_quad(clamp(it.age / it.lifetime, 0.0, 1.0)) * it.max_size;

		instance.M = M4f.translate(it.position);
		instance.M *= scale_matrix(V3f.{ ts, ts, ts });
	}
	if instanced.count == 0
		return;

	bindGroup := instance_bind_group(framegraph, "Explosion", instanced.count);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
	defer context.gpu.bindGroupRelease(bindGroup);
	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
	encode_and_draw(framegraph, pass, store.unit_sphere_model, instanced.count);
}

render_robots :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	instanced := NewArray(scene.robots.count, WFramegraph.Instance, false,, temp);
	for axe: 0..5 {
		instanced.count = 0;
		for scene.robots {
			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			instance.M = Scene.robot_to_axis(it, axe);
			instance.texture_rect = Store.Colormaps_Rect.vehicle;
		}
		if instanced.count == 0
			continue;

		bindGroup := instance_bind_group(framegraph, tprint("Robot axe %", axe), instanced.count);
		context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
		defer context.gpu.bindGroupRelease(bindGroup);
		writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
		encode_and_draw(framegraph, pass, Store.get_axes_model(store, axe), instanced.count);
	}
	for robot: scene.robots {
		M := Scene.robot_matrix_local_to_joint(robot, 6);

		if !((robot.shooting_cd + robot.charging_time) < robot.shooting_time
		&& robot.shooting_time < (robot.shooting_cd + robot.charging_time + robot.effectshoot_time))
			continue;

		over_t := robot.shooting_time - robot.shooting_cd - robot.charging_time;
		t := clamp(over_t / robot.effectshoot_time, 0.0, 1.0);

		ts := ease_up_and_back(clamp(t * 5, 0.0, 1.0)) * 0.3;
		tz := ease_out_quad(clamp(t * 20, 0.0, 1.0)) * 100;

		cylinder: Extra.Cylinder;
		cylinder.color = V3f.{ 1, 0.5, 0.0 };
		cylinder.M = M;
		cylinder.M *= scale_matrix(V3f.{ ts, ts, tz });
		array_add(*extra.cylinders, cylinder);
	}

	for robot: scene.robots {
		if robot.shooting_cd < robot.shooting_time
		&& robot.shooting_time < robot.shooting_cd + robot.charging_time
		{
			M := Scene.robot_matrix_local_to_joint(robot, 6);
			ray_origin := v3(M * V4f.{ 0, 0, 0, 1 });
			ray_direction := normalize(v3(M * V4f.{ 0, 0, 1, 0 }));

			target, hit := ray_plane(ray_origin, ray_direction, V3f.{ 0, 0, 1 });
			if hit {
				particle: Extra.Quad;
				particle.M = M4f.translate(target + V3f.{ -1.0, -1.0, 0.01 });
				particle.M *= scale_matrix(V3f.{ 2.0, 2.0, 1.0 });
				particle.texture_rect = V4f.{ 0, 3 / 4.0, 1 / 4.0, 1 / 4.0 };
				particle.color = V4f.{ 1.0, 0.0, 0.0, 1.0 };
				array_add(*extra.quads, particle);
			}
		}
	}
}

render_flags :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	instanced := NewArray(scene.flags.count, WFramegraph.Instance, false,, temp);
	{
		instanced.count = 0;
		for scene.flags {
			if (it.activated && it.activated_juice_t < 0.5)
				continue;

			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			
			M := M4f.translate(it.position);
			if it.activated_juice_t > 0 {
				R := axis_angle(
					V3f.{ 0, 0, 1}, it.activated_juice_t * 3.1415926 * 2.0 * 5.0
				);
				S := scale_matrix(1.0 + ease_up_and_back(1.0 - it.activated_juice_t));

				M = M * to_rotation_matrix(R) * S;
			}
			if !it.activated && it.count_changed_juice_t > 0 {
				M = M * scale_matrix(1.0 + ease_up_and_back(1.0 - it.count_changed_juice_t));
			}
			instance.M = M;
			instance.texture_rect = Store.Colormaps_Rect.vehicle;
			
			{
				needed := ceil(scene.players.count / 1.5).(int);
				left := needed - it.last_player_count;
				added_numbers := 0;
				while left > 0 {
					M := M4f.translate(it.position + V3f.{ added_numbers * 0.5, 0, 1.5 });
					if it.count_changed_juice_t > 0 {
						M = M * scale_matrix(
							1.0 + ease_up_and_back(1.0 - it.count_changed_juice_t) * 0.5
						);
					}

					number: Extra.Number;
					number.M = M;
					number.number = xx (left % 10);
					array_add(*extra.numbers, number);
					left /= 10;
					added_numbers += 1;
				}
			}
		}
		if instanced.count > 0 {
			bindGroup := instance_bind_group(framegraph, "Flag", instanced.count);
			context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
			defer context.gpu.bindGroupRelease(bindGroup);
			writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
			encode_and_draw(framegraph, pass, store.flag_down_model, instanced.count);
		}
	}
	{
		instanced.count = 0;
		for scene.flags {
			if !(it.activated && it.activated_juice_t < 0.5)
				continue;

			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			
			M := M4f.translate(it.position);
			if it.activated_juice_t > 0 {
				R := axis_angle(
					V3f.{ 0, 0, 1}, it.activated_juice_t * 3.1415926 * 2.0 * 5.0
				);
				S := scale_matrix(1.0 + ease_up_and_back(1.0 - it.activated_juice_t));

				M = M * to_rotation_matrix(R) * S;
			}
			if !it.activated && it.count_changed_juice_t > 0 {
				M = M * scale_matrix(1.0 + ease_up_and_back(1.0 - it.count_changed_juice_t));
			}
			instance.M = M;
			instance.texture_rect = Store.Colormaps_Rect.vehicle;
		}
		if instanced.count > 0 {
			bindGroup := instance_bind_group(framegraph, "Flag", instanced.count);
			context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
			defer context.gpu.bindGroupRelease(bindGroup);
			writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);
			encode_and_draw(framegraph, pass, store.flag_model, instanced.count);
		}
	}
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

	bindGroup := instance_bind_group(framegraph, "Tombstone", instanced.count);
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

	bindGroup := instance_bind_group(framegraph, "Gate", instanced.count);
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

	bindGroup := instance_bind_group(framegraph, "Gate", instanced.count);
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

	bindGroup := instance_bind_group(framegraph, "Gate", instanced.count);
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

	bindGroup := instance_bind_group(framegraph, "Gate", instanced.count);
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
	bindGroup := instance_bind_group(framegraph, "Shuriken", instanced.count);
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

	bindGroup := instance_bind_group(framegraph, "Skull", instanced.count);
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

	bindGroup := instance_bind_group(framegraph, "Key", instanced.count);
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

		bindGroup := instance_bind_group(framegraph, "Standin", instanced.count);
		defer context.gpu.bindGroupRelease(bindGroup);
		context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
		encode_and_draw(framegraph, pass, model, instanced.count);
	}
}

render_players :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
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

	writeTo(framegraph.instanceBuffer, framegraph.instanceBufferCursor, instanced);

	bindGroup := instance_bind_group(framegraph, "Player", instanced.count);
	defer context.gpu.bindGroupRelease(bindGroup);
	context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);

	encode_and_draw(framegraph, pass, store.racer_model, instanced.count);
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

	bindGroup := instance_bind_group(framegraph, "Terrain", instanced.count);
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

		bindGroup := instance_bind_group(framegraph, "Prop", instanced.count);
		defer context.gpu.bindGroupRelease(bindGroup);
		context.gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
		encode_and_draw(framegraph, pass, Store.get_wprop(store, xx prop_id), instanced.count);
	}
}

