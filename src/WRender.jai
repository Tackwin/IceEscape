#import "Basic";
#import "String";
#import "Algebra";
#import "Assets";
#import "Math";
#import "Platform";
#import "Hash_Table";
#import "Rand";
#import "Sort";
#import "Pool";
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

align_up :: (value: *int, alig1: int, alig2: int) {
	gcd :: (a: int, b:int) -> int {
		if b == 0
			return a;
		return gcd(b, a % b);
	}
	lcm := alig2 * alig1 / gcd(alig1, alig2);

	align_up(value, lcm);
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
	cb.mode = .AllowSpontaneous;
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
		cb.mode = .AllowSpontaneous;
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

	make_from_image :: (
		image: Image, label: string = "unknown", tiles_count := V2i.{ 1, 1 }
	) -> WTexture {
		texture: WTexture;
		print("Making image % (% %)\n", label, image.width, image.height);

		desc: WGPUTextureDescriptor = .{};
		desc.label = toWGPUStringView(tprint("Texture (%)", label));
		desc.usage = WGPUTextureUsage_TextureBinding | WGPUTextureUsage_CopyDst;
		desc.size.width = xx (image.width / tiles_count.x);
		desc.size.height = xx (image.height / tiles_count.y);
		desc.size.depthOrArrayLayers = xx (tiles_count.x * tiles_count.y);
		desc.mipLevelCount = 1;
		desc.sampleCount = 1;
		desc.dimension = ._2D;
		desc.format = .RGBA8Unorm;
		texture.gpu = graphics.gpu.deviceCreateTexture(graphics.device, *desc);

		arrayBuffer := image.data.data;
		if tiles_count.x * tiles_count.y > 1 {
			c := image.channels;
			tilesSize := V2i.{
				image.width / tiles_count.x,
				image.height / tiles_count.y
			};
			arrayBuffer = xx talloc(image.data.count);

			for y: 0..tiles_count.y - 1 {
				for x: 0..tiles_count.x - 1 {
					byte_offset :=
						y * (image.width * tilesSize.y) + x * tilesSize.x;

					for r: 0..image.height / tiles_count.y - 1 {
						dstBufferX := 0;
						dstBufferY := (y * tiles_count.x + x) * tilesSize.y + r;
						dstBufferOffset := dstBufferX + dstBufferY * tilesSize.x;

						srcBufferX := x * tilesSize.x;
						srcBufferY := y * tilesSize.y + r;
						srcBufferOffset := srcBufferX + srcBufferY * image.width;

						memcpy(
							arrayBuffer + dstBufferOffset * image.channels,
							image.data.data + srcBufferOffset * image.channels,
							tilesSize.x * image.channels
						);
					}
				}
			}
		}

		copyInfo: WGPUTexelCopyTextureInfo;
		copyInfo.texture = texture.gpu;
		copyInfo.mipLevel = 0;
		copyInfo.origin = .{ 0, 0, 0 };
		copyInfo.aspect = .All;
		copyLayout: WGPUTexelCopyBufferLayout;
		copyLayout.offset = 0;
		copyLayout.bytesPerRow = xx (image.width / tiles_count.x * image.channels);
		copyLayout.rowsPerImage = xx (image.height / tiles_count.y);
		graphics.gpu.queueWriteTexture(
			graphics.mainQueue,
			*copyInfo,
			arrayBuffer,
			xx (image.width * image.height * image.channels),
			*copyLayout,
			*desc.size
		);

		viewDesc: WGPUTextureViewDescriptor;
		viewDesc.label = toWGPUStringView(tprint("Texture View (%)", label));
		viewDesc.format = desc.format;
		viewDesc.dimension = ._2DArray;
		viewDesc.mipLevelCount = 1;
		viewDesc.baseArrayLayer = 0;
		viewDesc.arrayLayerCount = xx (tiles_count.x * tiles_count.y);
		viewDesc.aspect = .All;
		viewDesc.usage = WGPUTextureUsage_TextureBinding;
		texture.view = graphics.gpu.textureCreateView(texture.gpu, *viewDesc);

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

Frame :: struct {
	Draw :: struct {
		instance_start := 0;
		instance_count := 0;
		model: *Model = null;
		second_bind_group: *WGPUBindGroup = null;
	}

	Pass :: struct(U: Type) {
		draws: [..] Draw;
		uniforms: U;
		current_bind_group: *WGPUBindGroup;
	}
	shadow: Pass(WFramegraph.Uniforms);
	geometry: Pass(WFramegraph.Uniforms);
	ui: Pass(WFramegraph.UI_Uniform);

	cpu: [..] u8;
	cpu_cursor := 0;

	current_time: Apollo_Time;
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
	uiTexture: WTexture;

	geometryBindGroup: WGPUBindGroup;
	textureBindGroup: WGPUBindGroup;
	particleBindGroup: WGPUBindGroup;

	frame_buffer: WGPUBuffer;

	UI_Uniform :: struct {
		window_size: V2f;
	}
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

	Present_Uniform :: struct {
		size: V2f;
		exposure: float32 = 1.0;
		gamma: float32 = 2.2;
	}
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

	Vertex :: struct {
		position: V3f;
		normal: V3f;
		uv: V2f;
	};

	Instance :: struct {
		UV_REPEAT :: 1;
		UV_NO_TILE :: 2;

		M: M4f;
		texture_rect: V4f = .{ 0, 0, 1, 1 }; // x, y, width, height
		albedo16normal16indices: u32 = 0xFFFF0000; // no normal, albedo 0
		useShadowMap: u32 = 1;
		fadeout_z: float32 = 1000.0;
		flags: u32 = 0;
		uv_offset: V2f = .{ 0, 0 };
		padding0: u32 = 0;
		padding1: u32 = 0;
		color: V4f = .{ 1, 1, 1, 1 };
		overlay_color: V4f = .{ 1, 1, 1, 1 };
	};

	frames: [3] Frame;

	rendering_frame_idx := -1;
	working_frame_idx := -1;
	ready_frame_idx := -1;

	frame_lock: u32 = 0;
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
	}
	{
		layout: WGPUBindGroupLayoutDescriptor = .{};
		entries: [6] WGPUBindGroupLayoutEntry;
			entries[0].binding = 0;
			entries[0].visibility = WGPUShaderStage_Fragment;
			entries[0].texture.sampleType = .Float;
			entries[0].texture.viewDimension = ._2DArray;
			entries[0].texture.multisampled = 0;
			entries[1].binding = 1;
			entries[1].visibility = WGPUShaderStage_Fragment;
			entries[1].texture.sampleType = .Float;
			entries[1].texture.viewDimension = ._2DArray;
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
				targets[0].format = .RGBA8Unorm;
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
		desc.label = toWGPUStringView("Frame Buffer");
		desc.usage = WGPUBufferUsage_Storage | WGPUBufferUsage_CopyDst | WGPUBufferUsage_Uniform;
		desc.size = 128 * 1024 * 1024;
		desc.mappedAtCreation = 0;
		framegraph.frame_buffer = graphics.gpu.deviceCreateBuffer(graphics.device, *desc);
	}
	for * framegraph.frames {
		array_resize(*it.cpu, 128 * 1024 * 1024);
		array_reserve(*it.shadow.draws, 1024 * 1024);
		array_reserve(*it.geometry.draws, 1024 * 1024);
		array_reserve(*it.ui.draws, 1024 * 1024);
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
		desc.label = toWGPUStringView("UI Texture");
		desc.usage = WGPUTextureUsage_RenderAttachment | WGPUTextureUsage_TextureBinding;
		desc.size.width = 1366;
		desc.size.height = 768;
		desc.size.depthOrArrayLayers = 1;
		desc.mipLevelCount = 1;
		desc.sampleCount = 1;
		desc.dimension = ._2D;
		desc.format = .RGBA8Unorm;
		framegraph.uiTexture.gpu = graphics.gpu.deviceCreateTexture(graphics.device, *desc);

		viewDesc: WGPUTextureViewDescriptor = .{};
		viewDesc.label = toWGPUStringView("UI Texture View");
		viewDesc.format = .RGBA8Unorm;
		viewDesc.dimension = ._2D;
		viewDesc.aspect = .All;
		framegraph.uiTexture.view = graphics.gpu.textureCreateView(framegraph.uiTexture.gpu, null);

		samplerDesc: WGPUSamplerDescriptor = .{};
		samplerDesc.label = toWGPUStringView("Ui Texture Sampler");
		samplerDesc.addressModeU = .ClampToEdge;
		samplerDesc.addressModeV = .ClampToEdge;
		samplerDesc.addressModeW = .ClampToEdge;
		samplerDesc.magFilter = .Linear;
		samplerDesc.minFilter = .Linear;
		samplerDesc.mipmapFilter = .Linear;
		samplerDesc.lodMinClamp = 0;
		samplerDesc.lodMaxClamp = 32;
		samplerDesc.maxAnisotropy = 1;
		framegraph.uiTexture.sampler =
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

present_bind_group :: (
	framegraph: *WFramegraph,
	uniforms: WFramegraph.Present_Uniform,
	name: string,
	hdr: WTexture,
	ui: WTexture
) -> WGPUBindGroup {
	frame := *framegraph.frames[framegraph.rendering_frame_idx]; // not working, rendering
	align_up(*frame.cpu_cursor, 256);

	desc: WGPUBindGroupDescriptor = .{};
	desc.label = toWGPUStringView(tprint("% Present Bind Group", name));
	desc.layout = framegraph.presentBindGroupLayout;
	entries: [3] WGPUBindGroupEntry;
	entries[0].binding = 0;
	entries[0].buffer = framegraph.frame_buffer;
	entries[0].offset = xx frame.cpu_cursor;
	entries[0].size = size_of(WFramegraph.Present_Uniform);
	entries[1].binding = 1;
	entries[1].textureView = hdr.view;
	entries[2].binding = 2;
	entries[2].textureView = ui.view;
	desc.entryCount = entries.count;
	desc.entries = entries.data;

	memcpy(frame.cpu.data + frame.cpu_cursor, *uniforms, size_of(type_of(uniforms)));
	frame.cpu_cursor += size_of(type_of(uniforms));

	return graphics.gpu.deviceCreateBindGroup(graphics.device, *desc);
}

ui_instance_bind_group :: (
	framegraph: *WFramegraph,
	uniforms: WFramegraph.UI_Uniform,
	albedo_map: WTexture,
	sdf_map: WTexture
) -> WGPUBindGroup {
	frame := *framegraph.frames[framegraph.rendering_frame_idx];
	align_up(*frame.cpu_cursor, 256);

	desc: WGPUBindGroupDescriptor = .{};
	desc.label = toWGPUStringView("UI Instance Bind Group");
	desc.layout = framegraph.quadBindGroupLayout;
	entries: [6] WGPUBindGroupEntry;
	entries[0].binding = 0;
	entries[0].buffer = framegraph.frame_buffer;
	entries[0].offset = xx frame.cpu_cursor;
	entries[0].size = size_of(WFramegraph.UI_Uniform);
	entries[1].binding = 1;
	entries[1].buffer = framegraph.frame_buffer;
	entries[1].offset = 0;
	entries[1].size = xx frame.cpu.count;
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

	memcpy(frame.cpu.data + frame.cpu_cursor, *uniforms, size_of(type_of(uniforms)));
	frame.cpu_cursor += size_of(type_of(uniforms));

	return graphics.gpu.deviceCreateBindGroup(graphics.device, *desc);
}


instance_bind_group :: (
	framegraph: *WFramegraph,
	uniforms: WFramegraph.Uniforms,
	name: string
) -> WGPUBindGroup {
	frame := *framegraph.frames[framegraph.rendering_frame_idx];

	align_up(*frame.cpu_cursor, 256);

	desc: WGPUBindGroupDescriptor = .{};
	desc.label = toWGPUStringView(tprint("% Instance Bind Group", name));
	desc.layout = framegraph.instanceBindGroupLayout;
	entries: [2] WGPUBindGroupEntry;
	entries[0].binding = 0;
	entries[0].buffer = framegraph.frame_buffer;
	entries[0].offset = xx frame.cpu_cursor;
	entries[0].size = size_of(WFramegraph.Uniforms);
	entries[1].binding = 1;
	entries[1].buffer = framegraph.frame_buffer;
	entries[1].offset = 0;
	entries[1].size = xx frame.cpu.count;
	desc.entryCount = entries.count;
	desc.entries = entries.data;
	
	memcpy(frame.cpu.data + frame.cpu_cursor, *uniforms, size_of(type_of(uniforms)));
	frame.cpu_cursor += size_of(type_of(uniforms));

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

append_instance_buffer :: (frame: *Frame) -> [] WFramegraph.Instance {
	align_up(*frame.cpu_cursor, size_of(WFramegraph.Instance));
	
	data: [] WFramegraph.Instance;
	data.data = (frame.cpu.data + frame.cpu_cursor).(*WFramegraph.Instance);
	data.count = 0;
	return data;
}

append_ui_instance_buffer :: (frame: *Frame) -> [] WFramegraph.UI_Instance {
	align_up(*frame.cpu_cursor, size_of(WFramegraph.UI_Instance));
	
	data: [] WFramegraph.UI_Instance;
	data.data = (frame.cpu.data + frame.cpu_cursor).(*WFramegraph.UI_Instance);
	data.count = 0;
	return data;
}

commit_geometry :: (
	frame: *Frame, pass: *Frame.Pass, model: *Model, count: int
) {
	if count <= 0
		return;

	stride := size_of(WFramegraph.Instance);
	draw: Frame.Draw;
	draw.model = model;
	draw.instance_count = count;
	draw.instance_start = frame.cpu_cursor / stride;
	draw.second_bind_group = pass.current_bind_group;
	array_add(*pass.draws, draw);
	frame.cpu_cursor += xx (count * stride);
}

commit_ui :: (frame: *Frame, pass: *Frame.Pass, count: int) {
	if count <= 0
		return;

	stride := size_of(WFramegraph.UI_Instance);
	draw: Frame.Draw;
	draw.instance_count = count;
	draw.instance_start = frame.cpu_cursor / stride;
	draw.second_bind_group = pass.current_bind_group;
	array_add(*pass.draws, draw);
	frame.cpu_cursor += xx (count * stride);
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

begin_frame :: (framegraph: *WFramegraph, current_time: Apollo_Time) -> *Frame
{
	while true {
		if (compare_and_swap(*framegraph.frame_lock, 0, 1))
			break;
	}

	// get a frame that is not ready or working.
	for 0..2 {
		if it == framegraph.rendering_frame_idx
			continue;
		if it == framegraph.ready_frame_idx
			continue;
		framegraph.working_frame_idx = it;
		break;
	}

	compare_and_swap(*framegraph.frame_lock, 1, 0);
	framegraph.current_time = current_time;

	frame := *framegraph.frames[framegraph.working_frame_idx];
	frame.cpu_cursor = 0;
	frame.shadow.draws.count = 0;
	frame.geometry.draws.count = 0;
	frame.ui.draws.count = 0;
	frame.current_time = current_time;

	return frame;
}

end_frame :: (framegraph: *WFramegraph, frame: *Frame) {
	while true {
		if (compare_and_swap(*framegraph.frame_lock, 0, 1))
			break;
	}

	// Put ready idx to the current working idx to signal that this frame is the most recent one.
	framegraph.ready_frame_idx = framegraph.working_frame_idx;

	compare_and_swap(*framegraph.frame_lock, 1, 0);

}

present_frame :: (framegraph: *WFramegraph, store: *Store.Store) -> bool {
	while true {
		if (compare_and_swap(*framegraph.frame_lock, 0, 1))
			break;
	}

	// swap the ready and rendering frame idx
	{
		old := framegraph.ready_frame_idx;
		framegraph.ready_frame_idx = framegraph.rendering_frame_idx;
		framegraph.rendering_frame_idx = old;
	}

	compare_and_swap(*framegraph.frame_lock, 1, 0);

	if framegraph.rendering_frame_idx < 0
		return false;

	frame := *framegraph.frames[framegraph.rendering_frame_idx];

	encoder := graphics.gpu.deviceCreateCommandEncoder(graphics.device, null);
	defer graphics.gpu.commandEncoderRelease(encoder);

	surfaceTexture: WGPUSurfaceTexture;
	graphics.gpu.surfaceGetCurrentTexture(graphics.surface, *surfaceTexture);
	surfaceView := graphics.gpu.textureCreateView(surfaceTexture.texture, null);
	defer graphics.gpu.textureViewRelease(surfaceView);

	hdrAttachment: WGPURenderPassColorAttachment;
	hdrAttachment.view = framegraph.hdrTexture.view;
	hdrAttachment.depthSlice = DEPTH_SLICE_UNDEFINED;
	hdrAttachment.loadOp = .Clear;
	hdrAttachment.storeOp = .Store;
	hdrAttachment.clearValue = .{ 0.3, 0.3, 0.3, 1.0 };
	
	uiAttachment: WGPURenderPassColorAttachment;
	uiAttachment.view = framegraph.uiTexture.view;
	uiAttachment.depthSlice = DEPTH_SLICE_UNDEFINED;
	uiAttachment.loadOp = .Clear;
	uiAttachment.storeOp = .Store;
	uiAttachment.clearValue = .{ 0.3, 0.3, 0.3, 0.0 };

	depthAttachment: WGPURenderPassDepthStencilAttachment;
	depthAttachment.view = framegraph.depthView;
	depthAttachment.depthLoadOp = .Clear;
	depthAttachment.depthStoreOp = .Store;
	depthAttachment.depthClearValue = 1.0;
	depthAttachment.stencilLoadOp = .Undefined;
	depthAttachment.stencilStoreOp = .Undefined;
	depthAttachment.stencilClearValue = 0;
	
	shadowAttachment: WGPURenderPassDepthStencilAttachment;
	shadowAttachment.view = framegraph.shadowTexture.view;
	shadowAttachment.depthLoadOp = .Clear;
	shadowAttachment.depthStoreOp = .Store;
	shadowAttachment.depthClearValue = 1.0;
	shadowAttachment.stencilLoadOp = .Undefined;
	shadowAttachment.stencilStoreOp = .Undefined;
	shadowAttachment.stencilClearValue = 0;

	surfaceAttachment: WGPURenderPassColorAttachment;
	surfaceAttachment.view = surfaceView;
	surfaceAttachment.depthSlice = DEPTH_SLICE_UNDEFINED;
	surfaceAttachment.loadOp = .Clear;
	surfaceAttachment.storeOp = .Store;
	surfaceAttachment.clearValue = .{ 0.3, 0.3, 0.3, 1.0 };
	
	geometry_bind_group := instance_bind_group(framegraph, frame.geometry.uniforms, "Geometry");
	defer graphics.gpu.bindGroupRelease(geometry_bind_group);
	ui_bind_group :=
		ui_instance_bind_group(framegraph, frame.ui.uniforms, store.ui_atlas, store.verdana_atlas);
	defer graphics.gpu.bindGroupRelease(ui_bind_group);

	extra: Extra;
	reserve(*extra, 16);
	defer free(*extra);

	render_depth :: true;
	if render_depth {
		passDesc: WGPURenderPassDescriptor = .{};
		passDesc.label = toWGPUStringView("Shadow Pass");
		passDesc.colorAttachments = null;
		passDesc.colorAttachmentCount = 0;
		passDesc.depthStencilAttachment = *shadowAttachment;
		pass := graphics.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);
		defer graphics.gpu.renderPassEncoderRelease(pass);

		graphics.gpu.renderPassEncoderSetPipeline(pass, framegraph.geometryShadowPipeline);
		graphics.gpu.renderPassEncoderSetBindGroup(pass, 0, geometry_bind_group, 0, null);
		
		last_bind_group: *WGPUBindGroup = null;
		for * frame.shadow.draws {
			if it.second_bind_group != last_bind_group {
				graphics.gpu.renderPassEncoderSetBindGroup(
					pass, 1, it.second_bind_group.*, 0, null
				);
				last_bind_group = it.second_bind_group;
			}
			if !it.model
				continue;

			graphics.gpu.renderPassEncoderSetVertexBuffer(
				pass, 0, it.model.gpu, 0, xx (it.model.prim_count * size_of(WFramegraph.Vertex))
			);
			graphics.gpu.renderPassEncoderDraw(
				pass, xx it.model.prim_count, xx it.instance_count, 0, xx it.instance_start
			);
		}
		graphics.gpu.renderPassEncoderEnd(pass);
	}

	render_geometry:: true;
	if render_geometry {
		passDesc: WGPURenderPassDescriptor = .{};
		passDesc.label = toWGPUStringView("Geometry Pass");
		passDesc.colorAttachments = *hdrAttachment;
		passDesc.colorAttachmentCount = 1;
		passDesc.depthStencilAttachment = *depthAttachment;
		pass := graphics.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);
		defer graphics.gpu.renderPassEncoderRelease(pass);

		graphics.gpu.renderPassEncoderSetPipeline(pass, framegraph.geometryPipeline);
		graphics.gpu.renderPassEncoderSetBindGroup(pass, 0, geometry_bind_group, 0, null);
		
		last_bind_group: *WGPUBindGroup = null;
		for * frame.geometry.draws {
			if it.second_bind_group != last_bind_group {
				graphics.gpu.renderPassEncoderSetBindGroup(
					pass, 1, it.second_bind_group.*, 0, null
				);
				last_bind_group = it.second_bind_group;
			}
			if !it.model
				continue;

			graphics.gpu.renderPassEncoderSetVertexBuffer(
				pass, 0, it.model.gpu, 0, xx (it.model.prim_count * size_of(WFramegraph.Vertex))
			);
			graphics.gpu.renderPassEncoderDraw(
				pass, xx it.model.prim_count, xx it.instance_count, 0, xx it.instance_start
			);
		}
		graphics.gpu.renderPassEncoderEnd(pass);
	}
	render_ui:: true;
	if render_ui {
		passDesc: WGPURenderPassDescriptor = .{};
		passDesc.label = toWGPUStringView("UI Pass");
		passDesc.colorAttachments = *uiAttachment;
		passDesc.colorAttachmentCount = 1;
		passDesc.depthStencilAttachment = null;
		pass := graphics.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);
		defer graphics.gpu.renderPassEncoderRelease(pass);

		graphics.gpu.renderPassEncoderSetPipeline(pass, framegraph.quadPipeline);
		graphics.gpu.renderPassEncoderSetBindGroup(pass, 0, ui_bind_group, 0, null);
		
		last_bind_group: *WGPUBindGroup = null;
		for * frame.ui.draws {
			if it.second_bind_group != last_bind_group {
				graphics.gpu.renderPassEncoderSetBindGroup(
					pass, 1, it.second_bind_group.*, 0, null
				);
				last_bind_group = it.second_bind_group;
			}
			graphics.gpu.renderPassEncoderDraw(
				pass, 6, xx it.instance_count, 0, xx it.instance_start
			);
		}
		graphics.gpu.renderPassEncoderEnd(pass);
	}

	if true {
		passDesc: WGPURenderPassDescriptor = .{};
		passDesc.label = toWGPUStringView("Present Pass");
		passDesc.colorAttachments = *surfaceAttachment;
		passDesc.colorAttachmentCount = 1;
		passDesc.depthStencilAttachment = null;
		presentPass := graphics.gpu.commandEncoderBeginRenderPass(encoder, *passDesc);
		graphics.gpu.renderPassEncoderSetPipeline(presentPass, framegraph.presentPipeline);

		presentUniform: WFramegraph.Present_Uniform = .{};
		presentUniform.size = V2f.{ 1366, 768 };
		presentUniform.exposure = 1.0;
		presentUniform.gamma = 2.2;
		bindGroup := present_bind_group(
			framegraph, presentUniform, "Present", framegraph.hdrTexture, framegraph.uiTexture
		);
		defer graphics.gpu.bindGroupRelease(bindGroup);

		graphics.gpu.renderPassEncoderSetBindGroup(presentPass, 0, bindGroup, 0, null);
		graphics.gpu.renderPassEncoderDraw(presentPass, 6, 1, 0, 0);

		// Fullscreen textured quad
		graphics.gpu.renderPassEncoderEnd(presentPass);
		graphics.gpu.renderPassEncoderRelease(presentPass);
	}
	view: [] u8;
	view.data = frame.cpu.data;
	view.count = frame.cpu_cursor;
	graphics.gpu.queueWriteBuffer(
		graphics.mainQueue, framegraph.frame_buffer, 0, frame.cpu.data, xx frame.cpu_cursor
	);

	bufferDesc: WGPUCommandBufferDescriptor = .{};
	bufferDesc.label = toWGPUStringView("Command Buffer");
	present := graphics.gpu.commandEncoderFinish(encoder, *bufferDesc);
	defer graphics.gpu.commandBufferRelease(present);

	submit: [] WGPUCommandBuffer = .[present];
	graphics.gpu.queueSubmit(graphics.mainQueue, xx submit.count, submit.data);

	return true;
}

render_scene :: (
	frame: *Frame, framegraph: *WFramegraph, scene: Scene.Scene, store: Store.Store
) {
	frame.geometry.uniforms = .{};
	frame.geometry.uniforms.V =
		Scene.look_at(scene.camera.position, scene.camera.target, .{ 0, 0, 1 });
	frame.geometry.uniforms.P = Scene.perspective(scene.camera);

	center := V3f.{ 0, 0, 0 };
	center = v3(Scene.terrain_size(scene), 0.0) / 2.0;
	frame.geometry.uniforms.shadowV =
		Scene.look_at(center + V3f.{ 100, 100, 100 }, center, V3f.{ 0, 1, 0 });
	frame.geometry.uniforms.shadowP = Scene.orthographic(-40, 40, -40, 40, 0.1, 500);
	frame.geometry.uniforms.sun_dir = normalize(V3f.{ -1, -1, -1 });
	frame.geometry.uniforms.sun_color = V3f.{ 1, 1, 1 };
	frame.geometry.uniforms.sun_strength = 0.5;
	frame.shadow.uniforms = frame.geometry.uniforms;
	
	extra: Extra;
	reserve(*extra, 16);
	defer {
		free(*extra);
	}
	if true {
		clear(*extra);

		frame.shadow.current_bind_group = null;

		render_players(frame, *frame.shadow, scene, store, *extra);
		render_keys(frame, *frame.shadow, scene, store, *extra);
		render_skulls(frame, *frame.shadow, scene, store, *extra);
		render_shurikens(frame, *frame.shadow, scene, store, *extra);
		render_standin(frame, *frame.shadow, scene, store, *extra);
		render_props(frame, *frame.shadow, scene, store, *extra);
		render_gates(frame, *frame.shadow, scene, store, *extra);
		render_tombstones(frame, *frame.shadow, scene, store, *extra);
		render_coins(frame, *frame.shadow, scene, store, *extra);
		render_trophies(frame, *frame.shadow, scene, store, *extra);
		render_hooks(frame, *frame.shadow, scene, store, *extra);
		render_presents(frame, *frame.shadow, scene, store, *extra);
		render_robots(frame, *frame.shadow, scene, store, *extra);
		render_antiairs(frame, *frame.shadow, scene, store, *extra);
		render_flags(frame, *frame.shadow, scene, store, *extra);
		render_block_rocks(frame, *frame.shadow, scene, store, *extra);
		render_turn_tables(frame, *frame.shadow, scene, store, *extra);
		render_bombs(frame, *frame.shadow, scene, store, *extra);
		render_pressbuttons(frame, *frame.shadow, scene, store, *extra);
		render_jukeboxes(frame, *frame.shadow, scene, store, *extra);
		render_traps(frame, *frame.shadow, scene, store, *extra);
		render_extra(frame, *frame.shadow, scene, store, *extra);
		//render_mark(framegraph, encoder, shadowPass, scene, store);
	}

	if true {
		clear(*extra);

		frame.geometry.current_bind_group = *framegraph.textureBindGroup;
		render_terrain(frame, *frame.geometry, scene, store, *extra);

		frame.geometry.current_bind_group = *framegraph.geometryBindGroup;
		render_players(frame, *frame.geometry, scene, store, *extra);
		render_keys(frame, *frame.geometry, scene, store, *extra);
		render_skulls(frame, *frame.geometry, scene, store, *extra);
		render_shurikens(frame, *frame.geometry, scene, store, *extra);
		render_standin(frame, *frame.geometry, scene, store, *extra);
		render_props(frame, *frame.geometry, scene, store, *extra);
		render_gates(frame, *frame.geometry, scene, store, *extra);
		render_tombstones(frame, *frame.geometry, scene, store, *extra);
		render_coins(frame, *frame.geometry, scene, store, *extra);
		render_robots(frame, *frame.geometry, scene, store, *extra);
		render_trophies(frame, *frame.geometry, scene, store, *extra);
		render_antiairs(frame, *frame.geometry, scene, store, *extra);
		render_hooks(frame, *frame.geometry, scene, store, *extra);
		render_flags(frame, *frame.geometry, scene, store, *extra);
		render_presents(frame, *frame.geometry, scene, store, *extra);
		render_turn_tables(frame, *frame.geometry, scene, store, *extra);
		render_pressbuttons(frame, *frame.geometry, scene, store, *extra);
		render_jukeboxes(frame, *frame.geometry, scene, store, *extra);
		render_block_rocks(frame, *frame.geometry, scene, store, *extra);
		render_bombs(frame, *frame.geometry, scene, store, *extra);
		render_traps(frame, *frame.geometry, scene, store, *extra);
		render_explosions(frame, *frame.geometry, scene, store, *extra);

		if false {
			for 0..10 {
				t := it / 11.0 * 2 * 3.1415926;
				factor := cos(t);
				factor = (1 - factor) / 2.0;
				factor = factor * factor * factor;
				factor = exp(-factor) + 0.7;
				dt := v3(cos(t), sin(t), 0) * factor * 1.5;
				add_debug_sphere(*extra, scene.camera.locked_drag_anchor_last_drag_pos + dt, scale = 0.05);
			}
			add_debug_sphere(*extra, scene.camera.target, scale = 0.05);
			add_debug_sphere(*extra, scene.camera.target_target, scale = 0.1);
			add_debug_sphere(*extra, scene.camera.locked_drag_anchor, scale = 0.2);
			add_debug_sphere(
				*extra,
				scene.camera.locked_drag_anchor_last_drag_pos,
				color = V4f.{ 1, 0, 0, 1 },
				scale = 0.3
			);
		}

		if true {
			// Debug visualization for camera rails
			for rail: scene.camera_rails {
				waypoints := Scene.iterator(rail.waypoints, scene.camera_rail_waypoints);
				prev_waypoint: V3f;
				first := true;
				end := min(waypoints.span.count + waypoints.span.index, waypoints.array.count);
				for index: waypoints.span.index..end - 1 {
					waypoint := waypoints.array[index];
					if !first {
						// Draw cylinder between waypoints
						direction := waypoint - prev_waypoint;
						length := norm(direction);
						if length > 0.001 {
							mid_point := (prev_waypoint + waypoint) / 2.0;

							cylinder: Extra.Cylinder;
							cylinder.color = V3f.{ 0.0, 1.0, 1.0 }; // Cyan color for rails
							cylinder.M = M4f.translate(prev_waypoint);
							cylinder.M *= to_rotation_matrix(
								from_unit_vectors(V3f.{ 0, 0, 1 }, normalize(direction))
							);
							cylinder.M *= scale_matrix(V3f.{ 0.05, 0.05, length });
							array_add(*extra.cylinders, cylinder);
						}
					}
					first = false;
					prev_waypoint = waypoint;
				}
			}

			// Debug visualization for camera POIs
			for poi: scene.camera_pois {
				cylinder: Extra.Cylinder;
				cylinder.color = V3f.{ 1.0, 0.0, 1.0 }; // Magenta color for POIs
				cylinder.M = M4f.translate(poi.position);
				cylinder.M *= scale_matrix(V3f.{ 0.1, 0.1, 0.5 });
				array_add(*extra.cylinders, cylinder);
			}
		}
		render_within_zones(frame, *frame.geometry, scene, store, *extra);
		render_extra(frame, *frame.geometry, scene, store, *extra);
		render_safezones(frame, *frame.geometry, scene, store, *extra);

		frame.geometry.current_bind_group = *framegraph.particleBindGroup;
		render_particles(frame, *frame.geometry, scene, store, *extra);
		render_extra_quads(frame, *frame.geometry, scene, store, *extra);

		frame.geometry.current_bind_group = *framegraph.geometryBindGroup;
		render_mark(frame, *frame.geometry, scene, store, *extra);
	}
}
render_gui :: (
	frame: *Frame, framegraph: *WFramegraph, gui_state: GUI.GUI_State, store: Store.Store
) {
	frame.ui.uniforms = .{};
	frame.ui.uniforms.window_size = V2f.{ 1366, 768 };

	font := *store.verdana;

	instances := append_ui_instance_buffer(frame);
	for gui_state.quads {
		if it.late
			continue;
		instances.count += 1;
		instance := *instances[instances.count - 1];
		instance.* = .{};
		instance.pos = it.pos;
		instance.size = it.size;
		instance.color = it.color;
		instance.z30sdf2 = xx (it.z * 400);
		instance.texture_rect = it.texture_rect;
	}

	for gui_state.chars {
		instances.count += 1;
		instance := *instances[instances.count - 1];
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

	quick_sort(
		instances, (a: WFramegraph.UI_Instance, b: WFramegraph.UI_Instance) -> int {
			az := a.z30sdf2 / 4;
			bz := b.z30sdf2 / 4;
			if az < bz
				return -1;
			if az > bz
				return 1;
			return 0;
		}
	);
	commit_ui(frame, *frame.ui, instances.count);
	instances = append_ui_instance_buffer(frame);
	
	for gui_state.quads {
		if !it.late
			continue;
		instances.count += 1;
		instance := *instances[instances.count - 1];
		instance.* = .{};
		instance.pos = it.pos;
		instance.size = it.size;
		instance.color = it.color;
		instance.z30sdf2 = xx (it.z * 400);
		instance.texture_rect = it.texture_rect;
	}
	quick_sort(
		instances, (a: WFramegraph.UI_Instance, b: WFramegraph.UI_Instance) -> int {
			az := a.z30sdf2 / 4;
			bz := b.z30sdf2 / 4;
			if az < bz
				return -1;
			if az > bz
				return 1;
			return 0;
		}
	);
	commit_ui(frame, *frame.ui, instances.count);
}

add_debug_sphere :: (
	extra: *Extra,
	pos: V3f,
	color := V4f.{ 1, 1, 1, 1 },
	scale := 1.0
) {
	cylinder: Extra.Cylinder;
	cylinder.M = M4f.translate(pos);
	M4f.scale(*cylinder.M, v3(scale, scale, scale));
	cylinder.color = v3(color);
	array_add(*extra.cylinders, cylinder);

}

render_mark :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	if to_float64_seconds(frame.current_time - scene.mark_clicked_time) < 0.25 {
		instanced := append_instance_buffer(frame);
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(scene.mark_clicked_pos);
		M4f.scale(*instance.M, V3f.{ 0.5, 0.5, 0.33 });
		t := clamp(
			(to_float64_seconds(frame.current_time - scene.mark_clicked_time) / 0.5),
			0.0,
			1.0
		);
		t = 1 - ((1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t));
		instance.texture_rect = Store.Colormaps_Rect.down_arrow;
		instance.uv_offset = V2f.{ 0, xx t };
		instance.flags = WFramegraph.Instance.UV_REPEAT;
		commit_geometry(frame, pass, *store.mark_model, instanced.count);
	}
}

render_particles :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	dt := normalize(scene.camera.target - scene.camera.position);
	R := to_rotation_matrix(from_unit_vectors(V3f.{ 0, 0, -1 }, dt));
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.tile_model, instanced.count);
}

render_extra  :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	render_extra_numbers(frame, pass, scene, store, extra);
	render_extra_cylinders(frame, pass, scene, store, extra);
}

render_extra_cylinders :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
	for extra.cylinders {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = it.M;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count == 0
		return;

	commit_geometry(frame, pass, *store.unit_cylinder_model, instanced.count);
}

render_extra_numbers :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	for n: 0..9 {
		instanced := append_instance_buffer(frame);
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

		commit_geometry(frame, pass, Store.get_number_model(store, n), instanced.count);
	}
}

render_extra_quads :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.tile_model, instanced.count);
}

render_within_zones :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);

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
		commit_geometry(frame, pass, *store.indicator_outline_model, instanced.count);
	}

	instanced = append_instance_buffer(frame);
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
		commit_geometry(frame, pass, *store.indicator_stroke_model, instanced.count);
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
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.unit_sphere_model, instanced.count);
}

render_coins :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.coin_model, instanced.count);
}

render_antiairs :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
	for scene.antiairs {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		M := M4f.translate(it.server.position);
		instance.M = M;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0 {
		commit_geometry(frame, pass, *store.antiair_camion_model, instanced.count);
	}

	instanced = append_instance_buffer(frame);
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
		commit_geometry(frame, pass, *store.antiair_canon_model, instanced.count);
	}
	instanced = append_instance_buffer(frame);
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
		commit_geometry(frame, pass, *store.missile_model, instanced.count);
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

render_turn_tables :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
	for scene.turn_tables {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0
		commit_geometry(frame, pass, *store.turn_table_base_model, instanced.count);
	
	instanced = append_instance_buffer(frame);
	for scene.turn_tables {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		angle := Scene.get_pointing_angle(scene, it);
		instance.M = M4f.translate(it.position);
		instance.M *= to_rotation_matrix(axis_angle(v3(0.0, 0, 1), angle));
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0
		commit_geometry(frame, pass, *store.turn_table_turn_model, instanced.count);
}

render_bombs :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
	for scene.bombs {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};

		s := 0.0;
		if it.client.time > it.server.explosion_time / 2 {
			t := it.client.time - it.server.explosion_time / 2;
			s = sin(t * t);
			if t > 3
				s = sin(t * 2 * 3);
		}
		s *= s;
		scale := s * 0.5 + 1;

		color := v4(1.0, 1.0, 1.0, 1.0);
		if it.client.time + 2 > it.server.explosion_time {
			color.y = (it.server.explosion_time - it.client.time) / min(2.0, it.server.explosion_time);
			color.y = sqrt(color.y);
			color.y = sqrt(color.y);
			color.z = color.y;
		}
		instance.color = color;

		off := v3(0.0, 0.0, 0.0);
		if it.holder >= 0
			off.z += 0.5;
		instance.M = M4f.identity();
		instance.M *= M4f.translate(it.client.position + off);
		M4f.scale(*instance.M, v3(scale, scale, scale));
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	for scene.bomb_spawners {
		if it.spawned_id != -1
			continue;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0
		commit_geometry(frame, pass, *store.bomb_model, instanced.count);

	instanced = append_instance_buffer(frame);
	for scene.bomb_spawners {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0
		commit_geometry(frame, pass, *store.crate_model, instanced.count);
}

render_pressbuttons :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	render_pressbuttons_check(frame, pass, scene, store, extra);
	render_pressbuttons_radio(frame, pass, scene, store, extra);
}
render_pressbuttons_check :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
	for scene.pressbuttons {
		if it.activated
			continue;
		if it.is_radio
			continue;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);

		instance.texture_rect = Store.Colormaps_Rect.vehicle;
		{
			needed := ceil(scene.players.count / 1.5).(int);
			left := needed - it.last_player_count;
			added_numbers := 0;
			while left > 0 {
				M := M4f.translate(it.position + V3f.{ added_numbers * 0.5, 0, 0.25 });
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
	if instanced.count > 0
		commit_geometry(frame, pass, *store.pressbutton_unpressed, instanced.count);
	
	instanced = append_instance_buffer(frame);
	for scene.pressbuttons {
		if !it.activated
			continue;
		if it.is_radio
			continue;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0
		commit_geometry(frame, pass, *store.pressbutton_pressed, instanced.count);
}

render_pressbuttons_radio :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
	for scene.pressbuttons {
		if it.activated
			continue;
		if !it.is_radio
			continue;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);

		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0
		commit_geometry(frame, pass, *store.pressbutton_unpressed_radio, instanced.count);
	
	instanced = append_instance_buffer(frame);
	for scene.pressbuttons {
		if !it.activated
			continue;
		if !it.is_radio
			continue;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0
		commit_geometry(frame, pass, *store.pressbutton_pressed_radio, instanced.count);
}

render_jukeboxes :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
	for scene.jukeboxes {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		M := M4f.translate(it.position);
		M *= to_rotation_matrix(
			axis_angle(v3(0.0, 0, 1), (0.5 * 2 * 3.1415926).(float32))
		);
		instance.M = M;
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count == 0
		return;

	commit_geometry(frame, pass, *store.jukebox_model, instanced.count);
}

render_traps :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.trap_spike_model, instanced.count);
}

render_trophies :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.trophy_model, instanced.count);
}

render_robots :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	for axe: 0..5 {
		instanced := append_instance_buffer(frame);
		for scene.robots {
			instanced.count += 1;
			instance := *instanced[instanced.count - 1];
			instance.* = .{};
			instance.M = Scene.robot_to_axis(it, axe);
			instance.texture_rect = Store.Colormaps_Rect.conveyor;
		}
		if instanced.count == 0
			continue;

		commit_geometry(frame, pass, Store.get_axes_model(store, axe), instanced.count);
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
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	{
		instanced := append_instance_buffer(frame);
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
			commit_geometry(frame, pass, *store.flag_down_model, instanced.count);
		}
	}
	{
		instanced := append_instance_buffer(frame);
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
			commit_geometry(frame, pass, *store.flag_model, instanced.count);
		}
	}
}

render_block_rocks :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
	for scene.block_rocks {
		if it.exploded
			continue;
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0
		commit_geometry(frame, pass, *store.block_rock, instanced.count);

	instanced = append_instance_buffer(frame);
	for scene.block_rocks {
		if !it.exploded
			continue;
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count > 0
		commit_geometry(frame, pass, *store.no_block_rock, instanced.count);
}
render_tombstones :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
	for scene.tombstones {
		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		instance.M = M4f.translate(it.position);
		instance.texture_rect = Store.Colormaps_Rect.vehicle;
	}
	if instanced.count == 0
		return;

	commit_geometry(frame, pass, *store.tombstone_model, instanced.count);
}

render_gates :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	render_gates_regular_open(frame, pass, scene, store, extra);
	render_gates_regular_closed(frame, pass, scene, store, extra);
	render_gates_finished_open(frame, pass, scene, store, extra);
	render_gates_finished_closed(frame, pass, scene, store, extra);
}

render_gates_regular_open :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.gate_model, instanced.count);
}

render_gates_regular_closed :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.gate_close_model, instanced.count);
}

render_gates_finished_open :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
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

	commit_geometry(frame, pass, *store.gate_finish_model, instanced.count);
}

render_gates_finished_closed :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.gate_finish_close_model, instanced.count);
}

render_shurikens :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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
		commit_geometry(frame, pass, *store.drone_model, instanced.count);
	}

	instanced = append_instance_buffer(frame);
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
		commit_geometry(frame, pass, *store.drone_blade_model, instanced.count);
	}
}

render_hooks :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	{
		instanced := append_instance_buffer(frame);
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
			commit_geometry(frame, pass, *store.end_hook_model, instanced.count);
	}
}

render_presents :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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
		commit_geometry(frame, pass, *store.present_a_model, instanced.count);
		
	instanced = append_instance_buffer(frame);
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
		commit_geometry(frame, pass, *store.present_b_model, instanced.count);
}

render_safezones :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.zone_wall_model, instanced.count);
}

render_skulls :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.pirateship_model, instanced.count);

}

render_keys :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	instanced := append_instance_buffer(frame);
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

	commit_geometry(frame, pass, *store.key_model, instanced.count);
}

render_standin :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	for model_id: 0..Scene.Model_Id_Count {
		instanced := append_instance_buffer(frame);
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

		commit_geometry(frame, pass, model, instanced.count);
	}
}

render_players :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	max_model_id := 0;
	for scene.players
		max_model_id = max(max_model_id, it.server.model_id);

	for model_id: 0..max_model_id {
		instanced := append_instance_buffer(frame);
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
			commit_geometry(frame, pass, model, instanced.count);
		}
	}
}

set_albedo_map_idx :: (instance: *WFramegraph.Instance, idx: int) {
	instance.albedo16normal16indices &= 0xFFFF0000;
	instance.albedo16normal16indices |= (idx & 0xFFFF).(u32);
}
set_normal_map_idx :: (instance: *WFramegraph.Instance, idx: int) {
	instance.albedo16normal16indices &= 0x0000FFFF;
	instance.albedo16normal16indices |= (idx << 16).(u32);
}

render_terrain :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	terrain := *scene.terrain;

	instanced := append_instance_buffer(frame);
	for terrain.tiles {
		x := it_index % terrain.tiles_count.x;
		y := it_index / terrain.tiles_count.x;

		instanced.count += 1;
		instance := *instanced[instanced.count - 1];
		instance.* = .{};
		pos := Scene.tile_bottom_left(scene, V2i.{ x, y });
		instance.M = M4f.translate(pos) * scale_matrix(v3(terrain.tile_size, 1.0));
		set_normal_map_idx(instance, Store.get_tile_idx(it.kind));
		set_albedo_map_idx(instance, Store.get_tile_idx(it.kind));
		instance.texture_rect.x = xx x;
		instance.texture_rect.y = xx y;
		if it.kind != .Grass
			instance.flags = instance.UV_NO_TILE;
	}
	if instanced.count == 0 {
		return;
	}

	commit_geometry(frame, pass, *store.tile_model, instanced.count);

}

render_props :: (
	frame: *Frame, pass: *Frame.Pass, scene: Scene.Scene, store: Store.Store, extra: *Extra
) {
	if scene.props.count == 0
		return;

	max_id := 0;
	for scene.props
		max_id = max(max_id, it.id);

	for prop_id: 0..max_id {
		instanced := append_instance_buffer(frame);
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

		commit_geometry(frame, pass, Store.get_wprop(store, xx prop_id), instanced.count);
	}
}

