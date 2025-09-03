#load "webgpu_type.jai";

GPU_proc :: struct {
    createInstance: WGPUProcCreateInstance = null;
    myInstanceCreateSurface: WGPUProcInstanceCreateSurface = null;
    instanceRequestAdapter: WGPUProcInstanceRequestAdapter = null;
    adapterGetLimits: WGPUProcAdapterGetLimits = null;
    supportedFeaturesFreeMembers: WGPUProcSupportedFeaturesFreeMembers = null;
    adapterGetFeatures: WGPUProcAdapterGetFeatures = null;
    adapterRelease: WGPUProcAdapterRelease = null;
    adapterRequestDevice: WGPUProcAdapterRequestDevice = null;
    deviceGetQueue: WGPUProcDeviceGetQueue = null;
    queueRelease: WGPUProcQueueRelease = null;
    queueSubmit: WGPUProcQueueSubmit = null;
    queueWriteBuffer: WGPUProcQueueWriteBuffer = null;
    queueWriteTexture: WGPUProcQueueWriteTexture = null;
    deviceCreateCommandEncoder: WGPUProcDeviceCreateCommandEncoder = null;
    commandEncoderFinish: WGPUProcCommandEncoderFinish = null;
    commandEncoderRelease: WGPUProcCommandEncoderRelease = null;
    commandEncoderInsertDebugMarker: WGPUProcCommandEncoderInsertDebugMarker = null;
    commandBufferRelease: WGPUProcCommandBufferRelease = null;
    deviceCreateBuffer: WGPUProcDeviceCreateBuffer = null;
    bufferRelease: WGPUProcBufferRelease = null;
    bufferGetMappedRange: WGPUProcBufferGetMappedRange = null;
    bufferUnmap: WGPUProcBufferUnmap = null;
}
