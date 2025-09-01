#load "webgpu_type.jai";

GPU_proc :: struct {
    createInstance: WGPUProcCreateInstance = null;
    instanceRequestAdapter: WGPUProcInstanceRequestAdapter = null;
    adapterGetLimits: WGPUProcAdapterGetLimits = null;
    supportedFeaturesFreeMembers: WGPUProcSupportedFeaturesFreeMembers = null;
    adapterGetFeatures: WGPUProcAdapterGetFeatures = null;
    adapterRelease: WGPUProcAdapterRelease = null;
    adapterRequestDevice: WGPUProcAdapterRequestDevice = null;
}
