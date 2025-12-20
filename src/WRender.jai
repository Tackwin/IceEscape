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

Graphics :: struct {
	instance: WGPUInstance;
	surface: WGPUSurface;
	adapter: WGPUAdapter;
	device: WGPUDevice;
	mainQueue: WGPUQueue;

	done: [16] bool;

	gpu: GPU_proc;
}

graphics: *Graphics;

init_graphics :: (platform: Platform, _graphics: *Graphics) {
	graphics = _graphics;
	graphics.instance = platform.gpu.createInstance(null);
	if !graphics.instance {
		print("Failed to create WGPU instance\n");
		return;
	}

	surfaceDesc := WGPUSurfaceDescriptor.{ nextInChain = xx graphics.device };
	graphics.surface = platform.gpu.myInstanceCreateSurface(graphics.instance, *surfaceDesc);

	opts: WGPURequestAdapterOptions = .{};
	opts.compatibleSurface = graphics.surface;
	cb: WGPURequestAdapterCallbackInfo = .{};
	cb.userdata1 = graphics;
	graphics.done[0] = false;
	cb.callback = (
		status: WGPURequestAdapterStatus,
		adapter: WGPUAdapter,
		message: WGPUStringView,
		userdata1: *void,
		userdata2: *void
	) #c_call {
		_graphics := userdata1.(*Graphics);
		if status == WGPURequestAdapterStatus.Success {
			_graphics.adapter = adapter;
			_graphics.done[0] = true;
		} else {
			ctx: #Context;
			push_context ctx {
				print("Failed to request WGPU adapter\n");
			}
		}
	};
	platform.gpu.instanceRequestAdapter(graphics.instance, *opts, cb);
	while !graphics.done[0] {
		;
	}

	limits: WGPULimits = .{};
	if platform.gpu.adapterGetLimits(graphics.adapter, *limits) == .Success {
		print("WGPU limits: %\n", limits);
	}

	features: WGPUSupportedFeatures;
	defer {
		platform.gpu.supportedFeaturesFreeMembers(features);
	}
	platform.gpu.adapterGetFeatures(graphics.adapter, *features);
	for 0..features.featureCount-1 {
		print("Support %\n", features.features[it]);
	}

	graphics.done[0] = false;
	deviceDesc: WGPUDeviceDescriptor = .{};
	deviceDesc.uncapturedErrorCallbackInfo.userdata1 = xx graphics;
	deviceDesc.uncapturedErrorCallbackInfo.callback = (
		device: *WGPUDevice,
		errorType: WGPUErrorType,
		message: WGPUStringView,
		userdata1: *void,
		userdata2: *void
	) #c_call {
		ctx: #Context;
		push_context ctx {
			str: string;
			str.data = message.data;
			str.count = xx message.length;
			print("WGPU ERROR %\n", str);
		}
	};

	{

		cb: WGPURequestDeviceCallbackInfo = .{};
		cb.mode = .WaitAnyOnly;
		cb.userdata1 = graphics;
		cb.callback = (
			status: WGPURequestDeviceStatus,
			device: WGPUDevice,
			message: WGPUStringView,
			userdata1: *void,
			userdata2: *void
		) #c_call {
			_graphics := userdata1.(*Graphics);
			if status == WGPURequestDeviceStatus.Success {
				_graphics.device = device;
				_graphics.done[0] = true;
			} else {
				ctx: #Context;
				push_context ctx {
					print("Failed to request WGPU device\n");
				}
			}
		};
		platform.gpu.adapterRequestDevice(graphics.adapter, *deviceDesc, cb);
	}
	while !graphics.done[0] {
		;
	}

	platform.gpu.adapterRelease(graphics.adapter);

	config: WGPUSurfaceConfiguration = .{};
	config.device = graphics.device;
	config.format = .BGRA8Unorm;
	config.usage = WGPUTextureUsage_RenderAttachment;
	config.width = 1366;
	config.height = 768;
	config.presentMode = .Fifo;
	platform.gpu.surfaceConfigure(graphics.surface, *config);

	graphics.mainQueue = platform.gpu.deviceGetQueue(graphics.device);

	platform.gpu.queueSubmit(graphics.mainQueue, 0, null);
}


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
		print("Making image % (% %)\n", label, image.width, image.height);

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
		texture.gpu = graphics.gpu.deviceCreateTexture(graphics.device, *desc);

		copyInfo: WGPUTexelCopyTextureInfo;
		copyInfo.texture = texture.gpu;
		copyInfo.mipLevel = 0;
		copyInfo.origin = .{ 0, 0, 0 };
		copyInfo.aspect = .All;
		copyLayout: WGPUTexelCopyBufferLayout;
		copyLayout.offset = 0;
		copyLayout.bytesPerRow = xx (image.width * image.channels);
		copyLayout.rowsPerImage = xx image.height;
		graphics.gpu.queueWriteTexture(
			graphics.mainQueue,
			*copyInfo,
			image.data.data,
			xx (image.width * image.height * image.channels),
			*copyLayout,
			*desc.size
		);

		texture.view = graphics.gpu.textureCreateView(texture.gpu, null);

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
		texture.sampler = graphics.gpu.deviceCreateSampler(graphics.device, *samplerDesc);

		return texture;
	}
}

Model :: struct {
	gpu: WGPUBuffer;
	prim_count: int;

	make_from_obj :: (obj: [] u8, debug: string = "unknown") -> Model {
		print("Loading OBJ model: %\n", debug);
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
		model.gpu = graphics.gpu.deviceCreateBuffer(graphics.device, *desc);
		model.prim_count = cpu_buffer.count;

		graphics.gpu.queueWriteBuffer(
			graphics.mainQueue,
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
	current_time: Apollo_Time;

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
	instanceBindGroup: WGPUBindGroup;
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
		rotation: float = 0;
		outline: float = 0;
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
		UV_REPEAT :: 1;

		M: M4f;
		texture_rect: V4f = .{ 0, 0, 1, 1 }; // x, y, width, height
		useAlbedoNormalMap: u32 = 1;
		useShadowMap: u32 = 1;
		fadeout_z: float32 = 1000.0;
		flags: u32 = 0;
		uv_offset: V2f = .{ 0, 0 };
		padding0: u32 = 0;
		padding1: u32 = 0;
		color: V4f = .{ 1, 1, 1, 1 };
	};
	mainInstances: [..] Instance;
	
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
			graphics.gpu.deviceCreateBindGroupLayout(graphics.device, *layout);
		framegraph.instanceBindGroup = instance_bind_group(framegraph, "Geometry", 32 * 1024);
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
			graphics.gpu.deviceCreateBindGroupLayout(graphics.device, *layout);
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
			graphics.gpu.deviceCreateBindGroupLayout(graphics.device, *layout);
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
		framegraph.quadModule = graphics.gpu.deviceCreateShaderModule(
			graphics.device, *desc
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

		framegraph.quadPipeline = graphics.gpu.deviceCreateRenderPipeline(
			graphics.device, *desc
		);

		framegraph.quadBindGroupLayout = graphics.gpu.renderPipelineGetBindGroupLayout(
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
		framegraph.presentModule = graphics.gpu.deviceCreateShaderModule(
			graphics.device, *desc
		);
	}

	{
		// layout: WGPUPipelineLayoutDescriptor = .{};
		// layout.label = toWGPUStringView("Present Pipeline Layout");
		// layoutEntries: [1] WGPUBindGroupLayout;
		// layoutEntries[0] = framegraph.textureBindGroupLayout;
		// layout.bindGroupLayoutCount = 1;
		// layout.bindGroupLayouts = layoutEntries.data;
		// framegraph.presentPipelineLayout = graphics.gpu.deviceCreatePipelineLayout(
		// 	graphics.device, *layout
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

		framegraph.presentPipeline = graphics.gpu.deviceCreateRenderPipeline(
			graphics.device, *desc
		);

		framegraph.presentBindGroupLayout = graphics.gpu.renderPipelineGetBindGroupLayout(
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
		framegraph.geometryModule = graphics.gpu.deviceCreateShaderModule(
			graphics.device, *desc
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
		framegraph.geometryPipelineLayout = graphics.gpu.deviceCreatePipelineLayout(
			graphics.device, *layout
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

		framegraph.geometryPipeline = graphics.gpu.deviceCreateRenderPipeline(
			graphics.device, *desc
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
		framegraph.geometryShadowModule = graphics.gpu.deviceCreateShaderModule(
			graphics.device, *desc
		);
	}

	{
		layout: WGPUPipelineLayoutDescriptor = .{};
		layout.label = toWGPUStringView("Geometry Shadow Pipeline Layout");
		layout.bindGroupLayoutCount = 1;
		layout.bindGroupLayouts = *framegraph.instanceBindGroupLayout;
		framegraph.geometryShadowPipelineLayout = graphics.gpu.deviceCreatePipelineLayout(
			graphics.device, *layout
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

		framegraph.geometryShadowPipeline = graphics.gpu.deviceCreateRenderPipeline(
			graphics.device, *desc
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
		framegraph.uniformBuffer = graphics.gpu.deviceCreateBuffer(graphics.device, *desc);
	}
	{
		desc: WGPUBufferDescriptor = .{};
		desc.label = toWGPUStringView("Present Uniform Buffer");
		desc.usage = WGPUBufferUsage_Uniform | WGPUBufferUsage_CopyDst;
		desc.size = size_of(WFramegraph.Present_Uniform);
		desc.mappedAtCreation = 0;
		framegraph.presentUniformBuffer =
			graphics.gpu.deviceCreateBuffer(graphics.device, *desc);
	}
	{
		desc: WGPUBufferDescriptor = .{};
		desc.label = toWGPUStringView("UI Uniform Buffer");
		desc.usage = WGPUBufferUsage_Uniform | WGPUBufferUsage_CopyDst;
		desc.size = size_of(WFramegraph.UI_Uniform);
		desc.mappedAtCreation = 0;
		framegraph.uiUniformBuffer = graphics.gpu.deviceCreateBuffer(graphics.device, *desc);
	}
	{
		desc: WGPUBufferDescriptor = .{};
		desc.label = toWGPUStringView("Instance Buffer");
		desc.usage = WGPUBufferUsage_Storage | WGPUBufferUsage_CopyDst;
		desc.size = 64 * 1024 * size_of(WFramegraph.Instance);
		desc.mappedAtCreation = 0;
		framegraph.instanceBuffer = graphics.gpu.deviceCreateBuffer(graphics.device, *desc);
	}
	{
		desc: WGPUBufferDescriptor = .{};
		desc.label = toWGPUStringView("UI Instance Buffer");
		desc.usage = WGPUBufferUsage_Storage | WGPUBufferUsage_CopyDst;
		desc.size = 64 * 1024 * size_of(WFramegraph.UI_Instance);
		desc.mappedAtCreation = 0;
		framegraph.uiInstanceBuffer =
			graphics.gpu.deviceCreateBuffer(graphics.device, *desc);
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
		framegraph.depthTexture = graphics.gpu.deviceCreateTexture(graphics.device, *desc);

		viewDesc: WGPUTextureViewDescriptor = .{};
		viewDesc.label = toWGPUStringView("Depth Texture View");
		viewDesc.format = .Depth32Float;
		viewDesc.dimension = ._2D;
		viewDesc.aspect = .DepthOnly;
		framegraph.depthView = graphics.gpu.textureCreateView(framegraph.depthTexture, null);
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
		framegraph.hdrTexture.gpu = graphics.gpu.deviceCreateTexture(graphics.device, *desc);

		viewDesc: WGPUTextureViewDescriptor = .{};
		viewDesc.label = toWGPUStringView("HDR Texture View");
		viewDesc.format = .RGBA16Float;
		viewDesc.dimension = ._2D;
		viewDesc.aspect = .All;
		framegraph.hdrTexture.view = graphics.gpu.textureCreateView(framegraph.hdrTexture.gpu, null);

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
			graphics.gpu.deviceCreateSampler(graphics.device, *samplerDesc);
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
			graphics.gpu.deviceCreateTexture(graphics.device, *desc);

		viewDesc: WGPUTextureViewDescriptor = .{};
		viewDesc.label = toWGPUStringView("Shadow Texture View");
		viewDesc.format = .Depth32Float;
		viewDesc.dimension = ._2D;
		viewDesc.aspect = .DepthOnly;
		framegraph.shadowTexture.view =
			graphics.gpu.textureCreateView(framegraph.shadowTexture.gpu, null);

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
			graphics.gpu.deviceCreateSampler(graphics.device, *samplerDesc);
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
	graphics.gpu.queueWriteBuffer(
		graphics.mainQueue, buffer, xx offset, data, xx size_of(T)
	);
}

writeTo :: (buffer: WGPUBuffer, offset: int, data: [] $T) {
	graphics.gpu.queueWriteBuffer(
		graphics.mainQueue, buffer, xx offset, data.data, xx (data.count * size_of(T))
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
	return graphics.gpu.deviceCreateBindGroup(graphics.device, *desc);
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
	return graphics.gpu.deviceCreateBindGroup(graphics.device, *desc);
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
	return graphics.gpu.deviceCreateBindGroup(graphics.device, *desc);
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
	return graphics.gpu.deviceCreateBindGroup(graphics.device, *desc);
}

append_instance_buffer :: (framegraph: *WFramegraph) -> [] WFramegraph.Instance {
	data: [] WFramegraph.Instance;
	data.data = framegraph.mainInstances.data + framegraph.mainInstances.count;
	data.count = 0;
	return data;
}

draw :: (framegraph: *WFramegraph, pass: WGPURenderPassEncoder, model: Model, count: int) {
	if count <= 0 {
		return;
	}
	graphics.gpu.renderPassEncoderSetVertexBuffer(
		pass, 0, model.gpu, 0, xx (model.prim_count * size_of(WFramegraph.Vertex))
	);
	graphics.gpu.renderPassEncoderDraw(
		pass, xx model.prim_count, xx count, 0, xx framegraph.mainInstances.count
	);
	framegraph.mainInstances.count += xx count;
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

Frame :: struct {
	surfaceTexture: WGPUSurfaceTexture;
	surfaceView: WGPUTextureView;

	hdrAttachment: WGPURenderPassColorAttachment;
	surfaceAttachment: WGPURenderPassColorAttachment;
	uiAttachment: WGPURenderPassColorAttachment;
	depthAttachment: WGPURenderPassDepthStencilAttachment;
	shadowAttachment: WGPURenderPassDepthStencilAttachment;

	encoder: WGPUCommandEncoder;
}

begin_frame :: (framegraph: *WFramegraph, current_time: Apollo_Time) -> Frame
{
	frame: Frame;

	graphics.gpu.surfaceGetCurrentTexture(graphics.surface, *frame.surfaceTexture);
	frame.surfaceView = graphics.gpu.textureCreateView(frame.surfaceTexture.texture, null);

	frame.hdrAttachment.view = framegraph.hdrTexture.view;
	frame.hdrAttachment.depthSlice = 0;
	frame.hdrAttachment.loadOp = .Clear;
	frame.hdrAttachment.storeOp = .Store;
	frame.hdrAttachment.clearValue = .{ 0.3, 0.3, 0.3, 1.0 };

	frame.surfaceAttachment.view = frame.surfaceView;
	frame.surfaceAttachment.depthSlice = 0;
	frame.surfaceAttachment.loadOp = .Clear;
	frame.surfaceAttachment.storeOp = .Store;
	frame.surfaceAttachment.clearValue = .{ 0.3, 0.3, 0.3, 1.0 };
	
	frame.uiAttachment.view = frame.surfaceView;
	frame.uiAttachment.depthSlice = 0;
	frame.uiAttachment.loadOp = .Load;
	frame.uiAttachment.storeOp = .Store;
	frame.uiAttachment.clearValue = .{ 0.3, 0.3, 0.3, 1.0 };

	frame.depthAttachment.view = framegraph.depthView;
	frame.depthAttachment.depthLoadOp = .Clear;
	frame.depthAttachment.depthStoreOp = .Store;
	frame.depthAttachment.depthClearValue = 1.0;
	frame.depthAttachment.stencilLoadOp = .Undefined;
	frame.depthAttachment.stencilStoreOp = .Undefined;
	frame.depthAttachment.stencilClearValue = 0;
	
	frame.shadowAttachment.view = framegraph.shadowTexture.view;
	frame.shadowAttachment.depthLoadOp = .Clear;
	frame.shadowAttachment.depthStoreOp = .Store;
	frame.shadowAttachment.depthClearValue = 1.0;
	frame.shadowAttachment.stencilLoadOp = .Undefined;
	frame.shadowAttachment.stencilStoreOp = .Undefined;
	frame.shadowAttachment.stencilClearValue = 0;
	array_resize(*framegraph.mainInstances, 64 * 1024, false);
	framegraph.mainInstances.count = 0;
	framegraph.current_time = current_time;

	frame.encoder = graphics.gpu.deviceCreateCommandEncoder(graphics.device, null);

	return frame;
}

end_frame :: (frame: *Frame) {

	bufferDesc: WGPUCommandBufferDescriptor = .{};
	bufferDesc.label = toWGPUStringView("Main Command Buffer");
	buffer := graphics.gpu.commandEncoderFinish(frame.encoder, *bufferDesc);
	defer graphics.gpu.commandBufferRelease(buffer);

	submit: [1] WGPUCommandBuffer = .[buffer];
	graphics.gpu.queueSubmit(graphics.mainQueue, 1, submit.data);

	graphics.gpu.commandEncoderRelease(frame.encoder);
	graphics.gpu.textureViewRelease(frame.surfaceView);
}

render_scene :: (
	frame: *Frame, framegraph: *WFramegraph, scene: Scene.Scene, store: Store.Store
) {
	framegraph.typicalUniform = .{};
	framegraph.typicalUniform.V =
		Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	framegraph.typicalUniform.P =
		Scene.perspective(scene.camera);
	center := V3f.{ 0, 0, 0 };
	center = v3(Scene.terrain_size(scene), 0.0) / 2.0;
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
		passDesc.depthStencilAttachment = *frame.shadowAttachment;
		shadowPass := graphics.gpu.commandEncoderBeginRenderPass(frame.encoder, *passDesc);
		graphics.gpu.renderPassEncoderSetPipeline(
			shadowPass, framegraph.geometryShadowPipeline
		);
		graphics.gpu.renderPassEncoderSetBindGroup(
			shadowPass, 0, framegraph.instanceBindGroup, 0, null
		);

		render_players(framegraph, frame.encoder, shadowPass, scene, store);
		render_keys(framegraph, frame.encoder, shadowPass, scene, store);
		render_skulls(framegraph, frame.encoder, shadowPass, scene, store);
		render_shurikens(framegraph, frame.encoder, shadowPass, scene, store);
		render_standin(framegraph, frame.encoder, shadowPass, scene, store);
		render_props(framegraph, frame.encoder, shadowPass, scene, store);
		render_gates(framegraph, frame.encoder, shadowPass, scene, store);
		render_tombstones(framegraph, frame.encoder, shadowPass, scene, store);
		render_coins(framegraph, frame.encoder, shadowPass, scene, store);
		render_trophies(framegraph, frame.encoder, shadowPass, scene, store);
		render_hooks(framegraph, frame.encoder, shadowPass, scene, store, *extra);
		render_presents(framegraph, frame.encoder, shadowPass, scene, store);
		render_robots(framegraph, frame.encoder, shadowPass, scene, store, *extra);
		render_antiairs(framegraph, frame.encoder, shadowPass, scene, store, *extra);
		render_flags(framegraph, frame.encoder, shadowPass, scene, store, *extra);
		render_traps(framegraph, frame.encoder, shadowPass, scene, store, *extra);
		render_extra(framegraph, frame.encoder, shadowPass, scene, store, *extra);
		//render_mark(framegraph, encoder, shadowPass, scene, store);

		graphics.gpu.renderPassEncoderEnd(shadowPass);
		graphics.gpu.renderPassEncoderRelease(shadowPass);
	}

	if true {
		clear(*extra);

		framegraph.instanceBufferCursor = 0;
		passDesc: WGPURenderPassDescriptor = .{};
		passDesc.label = toWGPUStringView("Geometry Pass");
		passDesc.colorAttachments = *frame.hdrAttachment;
		passDesc.colorAttachmentCount = 1;
		passDesc.depthStencilAttachment = *frame.depthAttachment;
		geometryPass := graphics.gpu.commandEncoderBeginRenderPass(frame.encoder, *passDesc);
		graphics.gpu.renderPassEncoderSetPipeline(geometryPass, framegraph.geometryPipeline);

		graphics.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 0, framegraph.instanceBindGroup, 0, null
		);
		graphics.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.geometryBindGroup, 0, null
		);

		render_players(framegraph, frame.encoder, geometryPass, scene, store);
		render_keys(framegraph, frame.encoder, geometryPass, scene, store);
		render_skulls(framegraph, frame.encoder, geometryPass, scene, store);
		render_shurikens(framegraph, frame.encoder, geometryPass, scene, store);
		render_standin(framegraph, frame.encoder, geometryPass, scene, store);
		render_props(framegraph, frame.encoder, geometryPass, scene, store);
		render_gates(framegraph, frame.encoder, geometryPass, scene, store);
		render_tombstones(framegraph, frame.encoder, geometryPass, scene, store);
		render_coins(framegraph, frame.encoder, geometryPass, scene, store);
		render_robots(framegraph, frame.encoder, geometryPass, scene, store, *extra);
		render_trophies(framegraph, frame.encoder, geometryPass, scene, store);
		render_antiairs(framegraph, frame.encoder, geometryPass, scene, store, *extra);
		render_hooks(framegraph, frame.encoder, geometryPass, scene, store, *extra);
		render_flags(framegraph, frame.encoder, geometryPass, scene, store, *extra);
		render_presents(framegraph, frame.encoder, geometryPass, scene, store);
		render_traps(framegraph, frame.encoder, geometryPass, scene, store, *extra);
		render_explosions(framegraph, frame.encoder, geometryPass, scene, store, *extra);

		graphics.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.textureBindGroup, 0, null
		);

		render_terrain(framegraph, frame.encoder, geometryPass, scene, store);
		
		graphics.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.particleBindGroup, 0, null
		);

		render_particles(framegraph, frame.encoder, geometryPass, scene, store, *extra);

		graphics.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.geometryBindGroup, 0, null
		);
		render_within_zones(framegraph, frame.encoder, geometryPass, scene, store, *extra);
		render_extra(framegraph, frame.encoder, geometryPass, scene, store, *extra);
		render_safezones(framegraph, frame.encoder, geometryPass, scene, store);
		graphics.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.particleBindGroup, 0, null
		);
		render_extra_quads(framegraph, frame.encoder, geometryPass, scene, store, *extra);
		graphics.gpu.renderPassEncoderSetBindGroup(
			geometryPass, 1, framegraph.geometryBindGroup, 0, null
		);
		render_mark(framegraph, frame.encoder, geometryPass, scene, store);
		graphics.gpu.renderPassEncoderEnd(geometryPass);
		graphics.gpu.renderPassEncoderRelease(geometryPass);
	}

	writeTo(framegraph.instanceBuffer, 0, framegraph.mainInstances);

	if true {
		passDesc: WGPURenderPassDescriptor = .{};
		passDesc.label = toWGPUStringView("Present Pass");
		passDesc.colorAttachments = *frame.surfaceAttachment;
		passDesc.colorAttachmentCount = 1;
		passDesc.depthStencilAttachment = null;
		presentPass := graphics.gpu.commandEncoderBeginRenderPass(frame.encoder, *passDesc);
		graphics.gpu.renderPassEncoderSetPipeline(presentPass, framegraph.presentPipeline);
		presentUniform: WFramegraph.Present_Uniform = .{};
		presentUniform.size = V2f.{ 1366, 768 };
		presentUniform.exposure = 1.0;
		presentUniform.gamma = 2.2;
		writeTo(framegraph.presentUniformBuffer, 0, *presentUniform);
		bindGroup := present_bind_group(
			framegraph, "Present", framegraph.hdrTexture, presentUniform
		);
		graphics.gpu.renderPassEncoderSetBindGroup(presentPass, 0, bindGroup, 0, null);
		defer graphics.gpu.bindGroupRelease(bindGroup);
		graphics.gpu.renderPassEncoderDraw(presentPass, 6, 1, 0, 0);

		// Fullscreen textured quad
		graphics.gpu.renderPassEncoderEnd(presentPass);
		graphics.gpu.renderPassEncoderRelease(presentPass);
	}
}
render_gui :: (
	frame: *Frame, framegraph: *WFramegraph, gui_state: GUI.GUI_State, store: Store.Store
) {
	passDesc: WGPURenderPassDescriptor = .{};
	passDesc.label = toWGPUStringView("UI Pass");
	passDesc.colorAttachments = *frame.uiAttachment;
	passDesc.colorAttachmentCount = 1;
	passDesc.depthStencilAttachment = null;
	uiPass := graphics.gpu.commandEncoderBeginRenderPass(frame.encoder, *passDesc);

	graphics.gpu.renderPassEncoderSetPipeline(uiPass, framegraph.quadPipeline);

	uniforms: WFramegraph.UI_Uniform = .{};
	uniforms.window_size = V2f.{ 1366, 768 };
	writeTo(framegraph.uiUniformBuffer, 0, *uniforms);

	framegraph.uiInstances.count = 0;

	for gui_state.quads {
		if it.late
			continue;
		framegraph.uiInstances.count += 1;
		instance := *framegraph.uiInstances[framegraph.uiInstances.count - 1];
		instance.* = .{};
		instance.pos = it.pos;
		instance.size = it.size;
		instance.color = it.color;
		instance.z30sdf2 = xx (it.z * 400);
		instance.texture_rect = it.texture_rect;
	}


	font := *store.verdana;
	font_atlas := *store.verdana_atlas;
	for gui_state.chars {
		framegraph.uiInstances.count += 1;
		instance := *framegraph.uiInstances[framegraph.uiInstances.count - 1];
		instance.* = .{};

		glyph := font.glyphs[it.id];

		instance.pos = it.pos;
		instance.size = it.size;
		instance.texture_rect.x = glyph.atlasx / 1024;
		instance.texture_rect.y = glyph.atlasy / 1024;
		instance.texture_rect.z = (glyph.atlasw - glyph.atlasx) / 1024;
		instance.texture_rect.w = (glyph.atlash - glyph.atlasy) / 1024;
		instance.z30sdf2 = (it.z * 400).(u32) + 1;
		instance.color = it.color;
		instance.outline = ifx it.outline then 1.0 else 0.0;
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
			font_atlas
		);
		graphics.gpu.renderPassEncoderSetBindGroup(uiPass, 0, bindGroup, 0, null);
		defer graphics.gpu.bindGroupRelease(bindGroup);
		// writeTo(framegraph.uiInstanceBuffer, 0, framegraph.uiInstances);
		graphics.gpu.renderPassEncoderDraw(uiPass, 6, xx framegraph.uiInstances.count, 0, 0);
	}

	
	before := framegraph.uiInstances.count;

	for gui_state.quads {
		if !it.late
			continue;
		framegraph.uiInstances.count += 1;
		instance := *framegraph.uiInstances[framegraph.uiInstances.count - 1];
		instance.* = .{};
		instance.pos = it.pos;
		instance.size = it.size;
		instance.color = it.color;
		instance.z30sdf2 = xx (it.z * 400);
		instance.texture_rect = it.texture_rect;
	}
	if framegraph.uiInstances.count > before {
		view: [] WFramegraph.UI_Instance;
		view.data = framegraph.uiInstances.data + before;
		view.count = framegraph.uiInstances.count - before;
		quick_sort(
			view,
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
			"UI late Instances",
			framegraph.uiInstances.count,
			store.ui_atlas,
			store.font_atlas
		);
		graphics.gpu.renderPassEncoderSetBindGroup(uiPass, 0, bindGroup, 0, null);
		defer graphics.gpu.bindGroupRelease(bindGroup);
		graphics.gpu.renderPassEncoderDraw(
			uiPass, 6, xx view.count, 0, xx before
		);
	}
	writeTo(framegraph.uiInstanceBuffer, 0, framegraph.uiInstances);

	graphics.gpu.renderPassEncoderEnd(uiPass);
	graphics.gpu.renderPassEncoderRelease(uiPass);
}

render_mark :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	if to_float64_seconds(framegraph.current_time - scene.mark_clicked_time) < 0.25 {
		instanced := append_instance_buffer(framegraph);
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(scene.mark_clicked_pos);
		M4f.scale(*instance.M, V3f.{ 0.5, 0.5, 0.33 });
		t := clamp(
			(to_float64_seconds(framegraph.current_time - scene.mark_clicked_time) / 0.5),
			0.0,
			1.0
		);
		t = 1 - ((1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t));
		instance.texture_rect = Store.Colormaps_Rect.down_arrow;
		instance.uv_offset = V2f.{ 0, xx t };
		instance.flags = WFramegraph.Instance.UV_REPEAT;
		draw(framegraph, pass, store.mark_model, instanced.count);
	}
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
	R := to_rotation_matrix(from_unit_vectors(V3f.{ 0, 0, -1 }, dt));
	instanced := append_instance_buffer(framegraph);
	for scene.particles {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = R;
		M4f.translate(*instance.M, it.position);
		instance.M *= to_rotation_matrix(axis_angle(V3f.{ 0, 0, 1 }, it.rotation));
		M4f.scale(*instance.M, .{ it.size, it.size, it.size });
		M4f.translate(*instance.M, V3f.{ -0.5, -0.5, 0 });
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

	draw(framegraph, pass, store.tile_model, instanced.count);
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
	instanced := append_instance_buffer(framegraph);
	for extra.cylinders {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = it.M;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count == 0
		return;

	draw(framegraph, pass, store.unit_cylinder_model, instanced.count);
}

render_extra_numbers :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	for n: 0..9 {
		instanced := append_instance_buffer(framegraph);
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

		draw(framegraph, pass, Store.get_number_model(store, n), instanced.count);
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
	instanced := append_instance_buffer(framegraph);
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

	draw(framegraph, pass, store.tile_model, instanced.count);
}

render_within_zones :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	instanced := append_instance_buffer(framegraph);

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
		draw(framegraph, pass, store.indicator_outline_model, instanced.count);
	}

	instanced = append_instance_buffer(framegraph);
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
		draw(framegraph, pass, store.indicator_stroke_model, instanced.count);
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
	instanced := append_instance_buffer(framegraph);
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

	draw(framegraph, pass, store.unit_sphere_model, instanced.count);
}

render_coins :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := append_instance_buffer(framegraph);
	for scene.coins {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		R := to_rotation_matrix(axis_angle(V3f.{ 0, 0, 1 }, it.client.theta));

		M := M4f.translate(it.client.position) * R;
		instance.M = M;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count == 0
		return;

	draw(framegraph, pass, store.coin_model, instanced.count);
}

render_antiairs :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	instanced := append_instance_buffer(framegraph);
	for scene.antiairs {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		M := M4f.translate(it.server.position);
		instance.M = M;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0 {
		draw(framegraph, pass, store.antiair_camion_model, instanced.count);
	}

	instanced = append_instance_buffer(framegraph);
	for scene.antiairs {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		dt := normalize(v3(it.server.next_target, 0.0) - it.server.position);
		dt.z = 0;
		dt = normalize(dt);
		R := to_rotation_matrix(from_unit_vectors(V3f.{ 1, 0, 0 }, dt));
		M := M4f.translate(it.server.position + V3f.{ -0.5, 0, 0.7 } * 0.7 * 0.8);
		instance.M = M * R;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0 {
		draw(framegraph, pass, store.antiair_canon_model, instanced.count);
	}
	instanced = append_instance_buffer(framegraph);
	for scene.antiairs {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		dt := normalize(v3(it.server.next_target, 0.0) - it.server.position);
		dt.z = 0;
		dt = normalize(dt);
		{
			R := to_rotation_matrix(from_unit_vectors(V3f.{ 1, 0, 0 }, dt));
			dt = v3(R * V4f.{ 0.58, 0.0, 0.82, 0.0 });
			dt = normalize(dt);
		}

		M := M4f.translate(it.server.position + V3f.{ -0.55, 0, 0.9 } * 0.7 * 0.8);
		R := to_rotation_matrix(from_unit_vectors(V3f.{ 0, 0, 1 }, dt));
		// In the chamber
		if it.client.t < (it.server.cooldown - 1.5) {
			instance.M = M * R;
		}
		// Taking off
		else if it.client.t < (it.server.cooldown - 1.0) {
			t := linear_step(it.client.t, it.server.cooldown - 1.5, it.server.cooldown - 0.75);
			t = ease_in_quad(t);
			instance.M = M * R * M4f.translate(V3f.{ 0, 0, 15 * t });
		}
		// In flight some place random
		else if it.client.t < (it.server.cooldown - 0.5) {
			instance.M = M4f.translate(.{ 0, 0, -100 });
		}
		// landing
		else {
			t := linear_step(it.client.t, it.server.cooldown - 0.5, it.server.cooldown);
			t = ease_in_quad(t);
			instance.M = M4f.translate(
				.{ it.client.next_target.x, it.client.next_target.y, 10 * (1 - t) }
			);
			R := to_rotation_matrix(from_unit_vectors(V3f.{ 0, 0, 1 }, V3f.{ 0, 0, -1 }));
			instance.M = instance.M * R;
		}
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0 {
		draw(framegraph, pass, store.missile_model, instanced.count);
	}

	for scene.antiairs {
		if !(it.client.t > (it.server.cooldown - 0.75))
			continue;

		particle: Extra.Quad;
		particle.M =
		M4f.translate(v3(it.client.next_target - V2f.{ it.server.radius, it.server.radius } / 2, 0.05))
		* scale_matrix(V3f.{ it.server.radius, it.server.radius, 1.0 });
		particle.texture_rect = V4f.{ 0, 3 / 4.0, 1 / 4.0, 1 / 4.0 };
		particle.color = V4f.{ 1.0, 1.0, 1.0, 0.5 };
		array_add(*extra.quads, particle);
	}
}


render_traps :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	instanced := append_instance_buffer(framegraph);
	for scene.traps {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		M := M4f.translate(it.position);
		instance.M = M;
		scale := 2 * it.radius_hitbox;
		M4f.scale(*instance.M, V3f.{ scale, scale, scale });
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count == 0
		return;

	draw(framegraph, pass, store.trap_spike_model, instanced.count);
}

render_trophies :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := append_instance_buffer(framegraph);
	for scene.trophies {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		M := M4f.translate(it.position);
		instance.M = M;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count == 0
		return;

	draw(framegraph, pass, store.trophy_model, instanced.count);
}

render_robots :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	for axe: 0..5 {
		instanced := append_instance_buffer(framegraph);
		for scene.robots {
			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			instance.M = Scene.robot_to_axis(it, axe);
			instance.texture_rect = Store.Colormaps_Rect.conveyor;
		}
		if instanced.count == 0
			continue;

		draw(framegraph, pass, Store.get_axes_model(store, axe), instanced.count);
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
	{
		instanced := append_instance_buffer(framegraph);
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
			draw(framegraph, pass, store.flag_down_model, instanced.count);
		}
	}
	{
		instanced := append_instance_buffer(framegraph);
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
			draw(framegraph, pass, store.flag_model, instanced.count);
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
	instanced := append_instance_buffer(framegraph);
	for scene.tombstones {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count == 0
		return;

	draw(framegraph, pass, store.tombstone_model, instanced.count);
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
	instanced := append_instance_buffer(framegraph);
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

	draw(framegraph, pass, store.gate_model, instanced.count);
}

render_gates_regular_closed :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := append_instance_buffer(framegraph);
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

	draw(framegraph, pass, store.gate_close_model, instanced.count);
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

	draw(framegraph, pass, store.gate_finish_model, instanced.count);
}

render_gates_finished_closed :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := append_instance_buffer(framegraph);
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

	draw(framegraph, pass, store.gate_finish_close_model, instanced.count);
}

render_shurikens :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := append_instance_buffer(framegraph);
	for scene.shurikens {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		frame := Scene.find_by_frame_id(scene, it.frame_id);
		if !frame
			continue;
		instance.M = Scene.compute_moving_frame_server_world_matrix(scene, frame);
		pos := instance.M * v4(it.server.position, 1);
		instance.M = M4f.translate(v3(pos));
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}

	if instanced.count > 0 {
		draw(framegraph, pass, store.drone_model, instanced.count);
	}

	instanced = append_instance_buffer(framegraph);
	for scene.shurikens {
		M := Scene.compute_moving_frame_server_world_matrix(
			scene, Scene.find_by_frame_id(scene, it.frame_id)
		);
		pos := v3(M * v4(it.server.position, 1));
		off := V2f.{ 0.29259, 0.32137 };

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(pos + V3f.{ -off.x, -off.y, 0.0 }) * to_rotation_matrix(
			axis_angle(V3f.{ 0, 0, 1 }, 2 * it.client.theta)
		);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;

		instanced.count += 1;
		instance = *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(
			pos + V3f.{ +off.x, -off.y, 0.0 }
		) * to_rotation_matrix(
			axis_angle(V3f.{ 0, 0, 1 }, 2 * it.client.theta + 3.14159 / 2)
		);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;

		instanced.count += 1;
		instance = *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(
			pos + V3f.{ +off.x, +off.y, 0.0 }
		) * to_rotation_matrix(
			axis_angle(V3f.{ 0, 0, 1 }, 2 * it.client.theta + 3.14159)
		);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;

		instanced.count += 1;
		instance = *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(
			pos + V3f.{ -off.x, +off.y, 0.0 }
		) * to_rotation_matrix(
			axis_angle(V3f.{ 0, 0, 1 }, 2 * it.client.theta - 3.14159 / 2)
		);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}

	if instanced.count > 0 {
		draw(framegraph, pass, store.drone_blade_model, instanced.count);
	}
}

render_hooks :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store,
	extra: *Extra
) {
	{
		instanced := append_instance_buffer(framegraph);
		for scene.hooks {
			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			pos := it.server.last_anchor_position + it.server.direction * it.server.length;
			M := M4f.translate(pos);
			M = M * to_rotation_matrix(from_unit_vectors(V3f.{ 1, 0, 0 }, it.server.direction));
			instance.M = M;
			instance.texture_rect = Store.Colormaps_Rect.vehicle;

			cylinder: Extra.Cylinder;
			cylinder.color = V3f.{ 0.8, 0.8, 0.8 };
			cylinder.M = M4f.translate(it.server.last_anchor_position);
			cylinder.M *= to_rotation_matrix(
				from_unit_vectors(V3f.{ 0, 0, 1 }, it.server.direction)
			);
			cylinder.M *= scale_matrix(V3f.{ 0.02, 0.02, it.server.length });
			array_add(*extra.cylinders, cylinder);
		}
		if instanced.count > 0
			draw(framegraph, pass, store.end_hook_model, instanced.count);
	}
}

render_presents :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := append_instance_buffer(framegraph);
	for scene.presents {
		if !it.server.available
			continue;
		if it.kind == .A {
			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			instance.M = M4f.translate(it.position);
			M4f.scale(*instance.M, .{ 0.35, 0.35, 0.35 });
			instance.texture_rect = Store.Colormaps_Rect.prop;
		}
	}
	if instanced.count > 0
		draw(framegraph, pass, store.present_a_model, instanced.count);
		
	instanced = append_instance_buffer(framegraph);
	for scene.presents {
		if !it.server.available
			continue;
		if it.kind == .B {
			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			instance.M = M4f.translate(it.position);
			M4f.scale(*instance.M, .{ 0.35, 0.35, 0.35 });
			instance.texture_rect = Store.Colormaps_Rect.prop;
		}
	}
	if instanced.count > 0
		draw(framegraph, pass, store.present_b_model, instanced.count);
}

render_safezones :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := append_instance_buffer(framegraph);
	for scene.safe_zones {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		M4f.scale(*instance.M, .{ it.radius, it.radius, 1.0 });
		instance.texture_rect = Store.Colormaps_Rect.safe_zone;
		instance.uv_offset = V2f.{ 0, xx -it.client.time };
		instance.flags = WFramegraph.Instance.UV_REPEAT;
		instance.color.w = 0.5;
		instance.fadeout_z = 1.0;
	}
	if instanced.count == 0
		return;

	draw(framegraph, pass, store.zone_wall_model, instanced.count);
}

render_skulls :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := append_instance_buffer(framegraph);
	for * scene.skulls {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = Scene.compute_skull_matrix(scene, it);
		instance.M = M4f.translate(.{ 0, 0, -0.15 }) * instance.M;
		instance.texture_rect = Store.Colormaps_Rect.pirate;
	}

	if instanced.count == 0
		return;

	draw(framegraph, pass, store.pirateship_model, instanced.count);

}

render_keys :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	instanced := append_instance_buffer(framegraph);
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

	draw(framegraph, pass, store.key_model, instanced.count);
}

render_standin :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	for model_id: 0..Scene.Model_Id_Count {
		instanced := append_instance_buffer(framegraph);
		for scene.stand_in {
			if it.model_id != model_id
				continue;
			if it.retired
				continue;

			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			instance.M = M4f.translate(it.position);
			instance.M = instance.M * to_rotation_matrix(it.orientation);
			instance.texture_rect = Store.get_rect(xx it.model_id);
		}

		if instanced.count == 0
			continue;

		model := Store.get_model(store, model_id.(Scene.Model_Id));
		if !model
			continue;

		draw(framegraph, pass, model, instanced.count);
	}
}

render_players :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	max_model_id := 0;
	for scene.players
		max_model_id = max(max_model_id, it.server.model_id);

	for model_id: 0..max_model_id {
		instanced := append_instance_buffer(framegraph);
		for scene.players {
			if it.server.dead
				continue;
			if it.server.model_id != model_id
				continue;
			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			M := M4f.identity();

			q := from_unit_vectors(V3f.{ 1, 0, 0 }, it.client.direction);
			M = to_rotation_matrix(q);

			M = M4f.translate(it.client.position) * M;
			instance.M = M;
			instance.texture_rect = Store.get_rect(xx it.server.model_id);
		}

		if instanced.count > 0 {
			model := Store.get_model(store, xx model_id);
			if !model
				model = *store.spirit_model;
			draw(framegraph, pass, model, instanced.count);
		}
	}
}

set_use_normal_map :: (instance: *WFramegraph.Instance, use: bool) {
	if use {
		instance.useAlbedoNormalMap |= 2;
	} else {
		x := instance.useAlbedoNormalMap.(s64);
		x &= ~2;
		instance.useAlbedoNormalMap = x.(u32);
	}
}

render_terrain :: (
	framegraph: *WFramegraph,
	encoder: WGPUCommandEncoder,
	pass: WGPURenderPassEncoder,
	scene: Scene.Scene,
	store: Store.Store
) {
	terrain := *scene.terrain;

	instanced := append_instance_buffer(framegraph);
	for terrain.tiles {
		x := it_index % terrain.tiles_count.x;
		y := it_index / terrain.tiles_count.x;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		pos := Scene.tile_bottom_left(scene, V2i.{ x, y });
		instance.M = M4f.translate(pos) * scale_matrix(v3(terrain.tile_size, 1.0));
		instance.texture_rect = Store.get_tile_rect(it.kind);
		set_use_normal_map(instance, true);
	}
	if instanced.count == 0 {
		return;
	}

	draw(framegraph, pass, store.tile_model, instanced.count);

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

	for prop_id: 0..max_id {
		instanced := append_instance_buffer(framegraph);
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

		draw(framegraph, pass, Store.get_wprop(store, xx prop_id), instanced.count);
	}
}

