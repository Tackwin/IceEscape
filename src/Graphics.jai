#import "Platform";
#import "Basic";

#scope_export

Graphics :: struct {
	instance: WGPUInstance;
	adapter: WGPUAdapter;
}

#add_context graphics: Graphics;

init_graphics :: () {
	using context;
	graphics.instance = gpu.createInstance(null);
	if !graphics.instance {
		print("Failed to create WGPU instance\n");
		return;
	}

	done := false;
	opts: WGPURequestAdapterOptions = .{};
	cb: WGPURequestAdapterCallbackInfo = .{};
	cb.userdata1 = *context.graphics;
	cb.userdata2 = *done;
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
			userdata2.(*bool).* = true;
		} else {
			ctx: #Context;
			push_context ctx {
				print("Failed to request WGPU adapter\n");
			}
		}
	};
	gpu.instanceRequestAdapter(graphics.instance, *opts, cb);
	while !done {
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
}


