#import "Platform";
#import "Basic";

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

init_graphics :: () {
	using context;
	graphics.instance = gpu.createInstance(null);
	if !graphics.instance {
		print("Failed to create WGPU instance\n");
		return;
	}

	graphics.surface = gpu.instanceCreateSurface(graphics.instance, null);

	opts: WGPURequestAdapterOptions = .{};
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

	graphics.mainQueue = gpu.deviceGetQueue(graphics.device);
}


