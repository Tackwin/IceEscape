#load "webgpu_wgpu.jai";
// #load "webgpu_dawn.jai";

#if OS == .WASM {
    DEPTH_SLICE_UNDEFINED :: 0;
} else {
    DEPTH_SLICE_UNDEFINED :: 0xFFFFFFFF;
}


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
    deviceCreateShaderModule: WGPUProcDeviceCreateShaderModule = null;
    deviceCreateRenderPipeline: WGPUProcDeviceCreateRenderPipeline = null;
    commandEncoderBeginRenderPass: WGPUProcCommandEncoderBeginRenderPass = null;
    renderPassEncoderSetPipeline: WGPUProcRenderPassEncoderSetPipeline = null;
    renderPassEncoderSetBindGroup: WGPUProcRenderPassEncoderSetBindGroup = null;
    renderPassEncoderDraw: WGPUProcRenderPassEncoderDraw = null;
    renderPassEncoderDrawIndexed: WGPUProcRenderPassEncoderDrawIndexed = null;
    renderPassEncoderEnd: WGPUProcRenderPassEncoderEnd = null;
    renderPassEncoderRelease: WGPUProcRenderPassEncoderRelease = null;
    renderPassEncoderSetVertexBuffer: WGPUProcRenderPassEncoderSetVertexBuffer = null;
    renderPassEncoderSetIndexBuffer: WGPUProcRenderPassEncoderSetIndexBuffer = null;
    renderPassEncoderSetViewport: WGPUProcRenderPassEncoderSetViewport = null;
    commandEncoderCopyTextureToBuffer: WGPUProcCommandEncoderCopyTextureToBuffer = null;
    surfaceGetCurrentTexture: WGPUProcSurfaceGetCurrentTexture = null;
    textureCreateView: WGPUProcTextureCreateView = null;
    textureViewRelease: WGPUProcTextureViewRelease = null;
    surfaceConfigure: WGPUProcSurfaceConfigure = null;
    surfacePresent: WGPUProcSurfacePresent = null;
    textureGetFormat: WGPUProcTextureGetFormat = null;
    deviceCreateBindGroupLayout: WGPUProcDeviceCreateBindGroupLayout = null;
    bindGroupLayoutRelease: WGPUProcBindGroupLayoutRelease = null;
    deviceCreateBindGroup: WGPUProcDeviceCreateBindGroup = null;
    bindGroupRelease: WGPUProcBindGroupRelease = null;
    renderPipelineGetBindGroupLayout: WGPUProcRenderPipelineGetBindGroupLayout = null;
    deviceCreateTexture: WGPUProcDeviceCreateTexture = null;
    textureRelease: WGPUProcTextureRelease = null;
    deviceCreateSampler: WGPUProcDeviceCreateSampler = null;
    samplerRelease: WGPUProcSamplerRelease = null;
    deviceCreatePipelineLayout: WGPUProcDeviceCreatePipelineLayout = null;
    pipelineLayoutRelease: WGPUProcPipelineLayoutRelease = null;
    myGpuToCpu: #type (instance: WGPUInstance, buffer: WGPUBuffer, cpu: [] u8) -> void #c_call = null;
}
