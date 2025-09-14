#import "Platform";
#import "Basic";
#import "Algebra";

#scope_export

Graphics :: struct {
	instance: WGPUInstance;
	surface: WGPUSurface;
	adapter: WGPUAdapter;
	device: WGPUDevice;
	mainQueue: WGPUQueue;

	done: [16] bool;
}

#add_context graphics: Graphics;

tWGPUStringView :: (str: string) -> WGPUStringView {
	view: WGPUStringView;
	view.data = str.data;
	view.length = xx str.count;
	return view;
}

offset_of :: ($T: Type, $member: string) -> int {
	for type_info(T).members {
		if it.name == member
			return it.offset_in_bytes;
	}

	assert(false, "Type '%' does not have member '%'", T, member);
	return -1;
}
init_graphics :: () {
	using context;
	graphics.instance = gpu.createInstance(null);
	if !graphics.instance {
		print("Failed to create WGPU instance\n");
		return;
	}

	surfaceDesc := WGPUSurfaceDescriptor.{ nextInChain = xx graphics.device };
	graphics.surface = gpu.myInstanceCreateSurface(graphics.instance, *surfaceDesc);

	opts: WGPURequestAdapterOptions = .{};
	opts.compatibleSurface = graphics.surface;
	cb: WGPURequestAdapterCallbackInfo = .{};
	cb.userdata1 = *context.graphics;
	context.graphics.done[0] = false;
	cb.callback = (
		status: WGPURequestAdapterStatus,
		adapter: WGPUAdapter,
		message: WGPUStringView,
		userdata1: *void,
		userdata2: *void
	) #c_call {
		graphics := userdata1.(*Graphics);
		if status == WGPURequestAdapterStatus.Success {
			graphics.adapter = adapter;
			graphics.done[0] = true;
		} else {
			ctx: #Context;
			push_context ctx {
				print("Failed to request WGPU adapter\n");
			}
		}
	};
	gpu.instanceRequestAdapter(graphics.instance, *opts, cb);
	while !graphics.done[0] {
		;
	}

	limits: WGPULimits = .{};
	if gpu.adapterGetLimits(graphics.adapter, *limits) == .Success {
		print("WGPU limits: %\n", limits);
	}

	features: WGPUSupportedFeatures;
	defer {
		gpu.supportedFeaturesFreeMembers(features);
	}
	gpu.adapterGetFeatures(graphics.adapter, *features);
	for 0..features.featureCount-1 {
		print("Support %\n", features.features[it]);
	}

	graphics.done[0] = false;
	deviceDesc: WGPUDeviceDescriptor = .{};
	deviceDesc.uncapturedErrorCallbackInfo.userdata1 = xx *context.graphics;
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
		cb.userdata1 = *context.graphics;
		cb.callback = (
			status: WGPURequestDeviceStatus,
			device: WGPUDevice,
			message: WGPUStringView,
			userdata1: *void,
			userdata2: *void
		) #c_call {
			graphics := userdata1.(*Graphics);
			if status == WGPURequestDeviceStatus.Success {
				graphics.device = device;
				graphics.done[0] = true;
			} else {
				ctx: #Context;
				push_context ctx {
					print("Failed to request WGPU device\n");
				}
			}
		};
		gpu.adapterRequestDevice(graphics.adapter, *deviceDesc, cb);
	}
	while !graphics.done[0] {
		;
	}

	gpu.adapterRelease(graphics.adapter);

	config: WGPUSurfaceConfiguration = .{};
	config.device = graphics.device;
	config.format = .BGRA8Unorm;
	config.usage = WGPUTextureUsage_RenderAttachment;
	config.width = 1366;
	config.height = 768;
	config.presentMode = .Fifo;
	gpu.surfaceConfigure(graphics.surface, *config);

	graphics.mainQueue = gpu.deviceGetQueue(graphics.device);

// 	moduleDesc : WGPUShaderModuleDescriptor = .{};
// 	moduleDescWGSL: WGPUShaderSourceWGSL = .{};
// 	print("Size of WGPUShaderSourceWGSL: %\n", size_of(WGPUChainedStruct));
// 	moduleDescWGSL.chain.sType = .ShaderSourceWGSL;
// 	moduleDescWGSL.chain.next = null;
// 	moduleDescWGSL.code = tWGPUStringView(#string SHADER

// struct UniformStruct {
// 	color: vec4f,
// 	scale: vec2f,
// 	offset: vec2f,
// };

// @group(0) @binding(0) var<uniform> uniforms: UniformStruct;

// @vertex fn vs(
// 	@builtin(vertex_index) vertexIndex : u32
// ) -> @builtin(position) vec4f {
// 	let pos = array(
// 		vec2f( 0.0,  0.5),  // top center
// 		vec2f(-0.5, -0.5),  // bottom left
// 		vec2f( 0.5, -0.5)   // bottom right
// 	);

// 	return vec4f(pos[vertexIndex] * uniforms.scale + uniforms.offset, 0.0, 1.0);
// }

// @fragment fn fs() -> @location(0) vec4f {
// 	return uniforms.color;
// }
// SHADER);
// 	moduleDesc.nextInChain = *moduleDescWGSL.chain;
// 	module := gpu.deviceCreateShaderModule(graphics.device, *moduleDesc);

// 	fragmentState: WGPUFragmentState = .{};
// 	fragmentState.module = module;
// 	fragmentState.entryPoint = tWGPUStringView("fs");
// 	fragmentState.targetCount = 1;
// 	target: WGPUColorTargetState = .{};
// 	target.format = .BGRA8Unorm;
// 	target.blend = null;
// 	target.writeMask = WGPUColorWriteMask_All;
// 	fragmentState.targets = *target;

// 	pipelineDesc: WGPURenderPipelineDescriptor = .{};
// 	pipelineDesc.label = tWGPUStringView("Hello");
// 	pipelineDesc.layout = null;
// 	pipelineDesc.vertex.module = module;
// 	pipelineDesc.vertex.entryPoint = tWGPUStringView("vs");
// 	pipelineDesc.vertex.bufferCount = 0;
// 	pipelineDesc.vertex.buffers = null;
// 	pipelineDesc.primitive.topology = .WGPUPrimitiveTopology_TriangleList;
// 	pipelineDesc.primitive.stripIndexFormat = .Undefined;
// 	pipelineDesc.primitive.frontFace = .CCW;
// 	pipelineDesc.primitive.cullMode = .None;
// 	pipelineDesc.primitive.unclippedDepth = 0;
// 	pipelineDesc.depthStencil = null;
// 	pipelineDesc.multisample.count = 1;
// 	pipelineDesc.multisample.mask = 0xFFFFFFFF;
// 	pipelineDesc.multisample.alphaToCoverageEnabled = 0;
// 	pipelineDesc.fragment = *fragmentState;
// 	graphicsPipeline = gpu.deviceCreateRenderPipeline(graphics.device, *pipelineDesc);

// 	uniformBufferDesc: WGPUBufferDescriptor = .{};
// 	uniformBufferDesc.label = tWGPUStringView("Uniform Buffer");
// 	uniformBufferDesc.usage = WGPUBufferUsage_Uniform | WGPUBufferUsage_CopyDst;
// 	uniformBufferDesc.size = 32;
// 	uniformBufferDesc.mappedAtCreation = 0;
// 	uniformBuffer = gpu.deviceCreateBuffer(graphics.device, *uniformBufferDesc);

// 	bindGroupDesc: WGPUBindGroupDescriptor = .{};
// 	bindGroupDesc.label = tWGPUStringView("Uniform Bind Group");
// 	bindGroupDesc.layout = gpu.renderPipelineGetBindGroupLayout(graphicsPipeline, 0);
// 	bindEntry: WGPUBindGroupEntry = .{};
// 	bindEntry.binding = 0;
// 	bindEntry.buffer = uniformBuffer;
// 	bindEntry.offset = 0;
// 	bindEntry.size = 32;
// 	bindGroupDesc.entryCount = 1;
// 	bindGroupDesc.entries = *bindEntry;
// 	bindGroup = gpu.deviceCreateBindGroup(graphics.device, *bindGroupDesc);

	gpu.queueSubmit(graphics.mainQueue, 0, null);
	return;
}
graphicsPipeline: WGPURenderPipeline;
uniformBuffer: WGPUBuffer;
bindGroup: WGPUBindGroup;

loop :: () {
	using context;

	{
		Uniform :: struct {
			color: V4f;
			scale: V2f;
			offset: V2f;
		}

		uniformData: Uniform;
		uniformData.color = V4f.{ 0.0, 1.0, 0.0, 1.0 };
		uniformData.scale = V2f.{ 0.5, 0.5 };
		uniformData.offset = V2f.{ 0.0, 0.0 };
		gpu.queueWriteBuffer(graphics.mainQueue, uniformBuffer, 0, *uniformData, 32);

		surfaceTexture: WGPUSurfaceTexture;
		gpu.surfaceGetCurrentTexture(graphics.surface, *surfaceTexture);
		view := gpu.textureCreateView(surfaceTexture.texture, null);
		encoder: WGPUCommandEncoder = gpu.deviceCreateCommandEncoder(graphics.device, null);


		renderPassDesc: WGPURenderPassDescriptor = .{};
		renderPassDesc.label = tWGPUStringView("Main Render Pass");
		renderPassDesc.colorAttachmentCount = 1;
		attachment: WGPURenderPassColorAttachment = .{};
		attachment.view = view;
		attachment.depthSlice = 0;
		attachment.loadOp = .Clear;
		attachment.storeOp = .Store;
		attachment.clearValue = .{ 0.3, 0.3, 0.3, 1.0 };
		renderPassDesc.colorAttachments = *attachment;


		pass: WGPURenderPassEncoder = gpu.commandEncoderBeginRenderPass(encoder, *renderPassDesc);
		gpu.renderPassEncoderSetPipeline(pass, graphicsPipeline);
		gpu.renderPassEncoderSetBindGroup(pass, 0, bindGroup, 0, null);
		gpu.renderPassEncoderDraw(pass, 3, 1, 0, 0);
		gpu.renderPassEncoderEnd(pass);
		gpu.renderPassEncoderRelease(pass);
		gpu.textureViewRelease(view);

		bufferDesc: WGPUCommandBufferDescriptor = .{};
		bufferDesc.label = tWGPUStringView("Main Command Buffer");
		buffer := gpu.commandEncoderFinish(encoder, *bufferDesc);

		submit: [1] WGPUCommandBuffer = .[buffer];
		gpu.queueSubmit(graphics.mainQueue, 1, submit.data);
	}

	gpu.surfacePresent(graphics.surface);
	return;
}

