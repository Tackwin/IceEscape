#import "Platform";
#import "Basic";

#scope_export

Graphics :: struct {
	instance: WGPUInstance;
	adapter: WGPUAdapter;
}

#add_context gpu: Graphics;

init_graphics :: () {
	gpu := *context.gpu;
	gpu.instance = wgpuCreateInstance(null);
	if !gpu.instance {
		print("Failed to create WGPU instance\n");
		return;
	}

	done := false;
	opts: WGPURequestAdapterOptions = .{};
	cb: WGPURequestAdapterCallbackInfo = .{};
	cb.userdata1 = gpu;
	cb.userdata2 = *done;
	cb.callback = (
		status: WGPURequestAdapterStatus,
		adapter: WGPUAdapter,
		message: WGPUStringView,
		userdata1: *void,
		userdata2: *void
	) #c_call {
		gpu := userdata1.(*Graphics);
		if status == WGPURequestAdapterStatus.Success {
			gpu.adapter = adapter;
			userdata2.(*bool).* = true;
		} else {
			ctx: #Context;
			push_context ctx {
				print("Failed to request WGPU adapter\n");
			}
		}
	};
	wgpuInstanceRequestAdapter(gpu.instance, *opts, cb);
	while !done {
		;
	}

	limits: WGPULimits = .{};
	if wgpuAdapterGetLimits(gpu.adapter, *limits) == .Success {
		print("WGPU limits: %\n", limits);
	}

	features: WGPUSupportedFeatures;
	defer {
		wgpuSupportedFeaturesFreeMembers(features);
	}
	wgpuAdapterGetFeatures(gpu.adapter, *features);
	for 0..features.featureCount-1 {
		print("Support %\n", features.features[it]);
	}
}


