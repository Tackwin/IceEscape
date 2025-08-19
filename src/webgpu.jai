//
// This file was auto-generated using the following command:
//
// jai Build.jai - bindings
//



/**
* \defgroup UtilityTypes Utility Types
*
* @{
*/
WGPUFlags :: u64;
WGPUBool :: u32;

/**
* Nullable value defining a pointer+length view into a UTF-8 encoded string.
*
* Values passed into the API may use the special length value @ref WGPU_STRLEN
* to indicate a null-terminated string.
* Non-null values passed out of the API (for example as callback arguments)
* always provide an explicit length and **may or may not be null-terminated**.
*
* Some inputs to the API accept null values. Those which do not accept null
* values "default" to the empty string when null values are passed.
*
* Values are encoded as follows:
* - `{NULL, WGPU_STRLEN}`: the null value.
* - `{non_null_pointer, WGPU_STRLEN}`: a null-terminated string view.
* - `{any, 0}`: the empty string.
* - `{NULL, non_zero_length}`: not allowed (null dereference).
* - `{non_null_pointer, non_zero_length}`: an explictly-sized string view with
*   size `non_zero_length` (in bytes).
*
* For info on how this is used in various places, see \ref Strings.
*/
WGPUStringView :: struct {
    data:   *u8;
    length: u64;
}

WGPUAdapterImpl :: struct {}
/**
* \defgroup Objects
* \brief Opaque, non-dispatchable handles to WebGPU objects.
*
* @{
*/
WGPUAdapter :: *WGPUAdapterImpl;
WGPUBindGroupImpl :: struct {}
WGPUBindGroup :: *WGPUBindGroupImpl;
WGPUBindGroupLayoutImpl :: struct {}
WGPUBindGroupLayout :: *WGPUBindGroupLayoutImpl;
WGPUBufferImpl :: struct {}
WGPUBuffer :: *WGPUBufferImpl;
WGPUCommandBufferImpl :: struct {}
WGPUCommandBuffer :: *WGPUCommandBufferImpl;
WGPUCommandEncoderImpl :: struct {}
WGPUCommandEncoder :: *WGPUCommandEncoderImpl;
WGPUComputePassEncoderImpl :: struct {}
WGPUComputePassEncoder :: *WGPUComputePassEncoderImpl;
WGPUComputePipelineImpl :: struct {}
WGPUComputePipeline :: *WGPUComputePipelineImpl;
WGPUDeviceImpl :: struct {}
WGPUDevice :: *WGPUDeviceImpl;
WGPUInstanceImpl :: struct {}
WGPUInstance :: *WGPUInstanceImpl;
WGPUPipelineLayoutImpl :: struct {}
WGPUPipelineLayout :: *WGPUPipelineLayoutImpl;
WGPUQuerySetImpl :: struct {}
WGPUQuerySet :: *WGPUQuerySetImpl;
WGPUQueueImpl :: struct {}
WGPUQueue :: *WGPUQueueImpl;
WGPURenderBundleImpl :: struct {}
WGPURenderBundle :: *WGPURenderBundleImpl;
WGPURenderBundleEncoderImpl :: struct {}
WGPURenderBundleEncoder :: *WGPURenderBundleEncoderImpl;
WGPURenderPassEncoderImpl :: struct {}
WGPURenderPassEncoder :: *WGPURenderPassEncoderImpl;
WGPURenderPipelineImpl :: struct {}
WGPURenderPipeline :: *WGPURenderPipelineImpl;
WGPUSamplerImpl :: struct {}
WGPUSampler :: *WGPUSamplerImpl;
WGPUShaderModuleImpl :: struct {}
WGPUShaderModule :: *WGPUShaderModuleImpl;

WGPUSurfaceImpl :: struct {}
/**
* An object used to continuously present image data to the user, see @ref Surfaces for more details.
*/
WGPUSurface :: *WGPUSurfaceImpl;
WGPUTextureImpl :: struct {}
WGPUTexture :: *WGPUTextureImpl;
WGPUTextureViewImpl :: struct {}
WGPUTextureView :: *WGPUTextureViewImpl;

/**
* \defgroup Enumerations
* \brief Enums.
*
* @{
*/
WGPUAdapterType :: enum s32 {
    DiscreteGPU   :: 1;
    IntegratedGPU :: 2;
    CPU           :: 3;
    Unknown       :: 4;
    Force32       :: 2147483647;

    WGPUAdapterType_DiscreteGPU   :: DiscreteGPU;
    WGPUAdapterType_IntegratedGPU :: IntegratedGPU;
    WGPUAdapterType_CPU           :: CPU;
    WGPUAdapterType_Unknown       :: Unknown;
    WGPUAdapterType_Force32       :: Force32;
}

WGPUAddressMode :: enum s32 {
    Undefined    :: 0;
    ClampToEdge  :: 1;
    Repeat       :: 2;
    MirrorRepeat :: 3;
    Force32      :: 2147483647;

    WGPUAddressMode_Undefined    :: Undefined;
    WGPUAddressMode_ClampToEdge  :: ClampToEdge;
    WGPUAddressMode_Repeat       :: Repeat;
    WGPUAddressMode_MirrorRepeat :: MirrorRepeat;
    WGPUAddressMode_Force32      :: Force32;
}

WGPUBackendType :: enum s32 {
    Undefined :: 0;
    Null      :: 1;
    WebGPU    :: 2;
    D3D11     :: 3;
    D3D12     :: 4;
    Metal     :: 5;
    Vulkan    :: 6;
    OpenGL    :: 7;
    OpenGLES  :: 8;
    Force32   :: 2147483647;

    WGPUBackendType_Undefined :: Undefined;
    WGPUBackendType_Null      :: Null;
    WGPUBackendType_WebGPU    :: WebGPU;
    WGPUBackendType_D3D11     :: D3D11;
    WGPUBackendType_D3D12     :: D3D12;
    WGPUBackendType_Metal     :: Metal;
    WGPUBackendType_Vulkan    :: Vulkan;
    WGPUBackendType_OpenGL    :: OpenGL;
    WGPUBackendType_OpenGLES  :: OpenGLES;
    WGPUBackendType_Force32   :: Force32;
}

WGPUBlendFactor :: enum s32 {
    Undefined         :: 0;
    Zero              :: 1;
    One               :: 2;
    Src               :: 3;
    OneMinusSrc       :: 4;
    SrcAlpha          :: 5;
    OneMinusSrcAlpha  :: 6;
    Dst               :: 7;
    OneMinusDst       :: 8;
    DstAlpha          :: 9;
    OneMinusDstAlpha  :: 10;
    SrcAlphaSaturated :: 11;
    Constant          :: 12;
    OneMinusConstant  :: 13;
    Src1              :: 14;
    OneMinusSrc1      :: 15;
    Src1Alpha         :: 16;
    OneMinusSrc1Alpha :: 17;
    Force32           :: 2147483647;

    WGPUBlendFactor_Undefined         :: Undefined;
    WGPUBlendFactor_Zero              :: Zero;
    WGPUBlendFactor_One               :: One;
    WGPUBlendFactor_Src               :: Src;
    WGPUBlendFactor_OneMinusSrc       :: OneMinusSrc;
    WGPUBlendFactor_SrcAlpha          :: SrcAlpha;
    WGPUBlendFactor_OneMinusSrcAlpha  :: OneMinusSrcAlpha;
    WGPUBlendFactor_Dst               :: Dst;
    WGPUBlendFactor_OneMinusDst       :: OneMinusDst;
    WGPUBlendFactor_DstAlpha          :: DstAlpha;
    WGPUBlendFactor_OneMinusDstAlpha  :: OneMinusDstAlpha;
    WGPUBlendFactor_SrcAlphaSaturated :: SrcAlphaSaturated;
    WGPUBlendFactor_Constant          :: Constant;
    WGPUBlendFactor_OneMinusConstant  :: OneMinusConstant;
    WGPUBlendFactor_Src1              :: Src1;
    WGPUBlendFactor_OneMinusSrc1      :: OneMinusSrc1;
    WGPUBlendFactor_Src1Alpha         :: Src1Alpha;
    WGPUBlendFactor_OneMinusSrc1Alpha :: OneMinusSrc1Alpha;
    WGPUBlendFactor_Force32           :: Force32;
}

WGPUBlendOperation :: enum s32 {
    Undefined       :: 0;
    Add             :: 1;
    Subtract        :: 2;
    ReverseSubtract :: 3;
    Min             :: 4;
    Max             :: 5;
    Force32         :: 2147483647;

    WGPUBlendOperation_Undefined       :: Undefined;
    WGPUBlendOperation_Add             :: Add;
    WGPUBlendOperation_Subtract        :: Subtract;
    WGPUBlendOperation_ReverseSubtract :: ReverseSubtract;
    WGPUBlendOperation_Min             :: Min;
    WGPUBlendOperation_Max             :: Max;
    WGPUBlendOperation_Force32         :: Force32;
}

WGPUBufferBindingType :: enum s32 {
    BindingNotUsed  :: 0;

    Undefined       :: 1;
    Uniform         :: 2;
    Storage         :: 3;
    ReadOnlyStorage :: 4;
    Force32         :: 2147483647;

    WGPUBufferBindingType_BindingNotUsed  :: BindingNotUsed;

    WGPUBufferBindingType_Undefined       :: Undefined;
    WGPUBufferBindingType_Uniform         :: Uniform;
    WGPUBufferBindingType_Storage         :: Storage;
    WGPUBufferBindingType_ReadOnlyStorage :: ReadOnlyStorage;
    WGPUBufferBindingType_Force32         :: Force32;
}

WGPUBufferMapState :: enum s32 {
    Unmapped :: 1;
    Pending  :: 2;
    Mapped   :: 3;
    Force32  :: 2147483647;

    WGPUBufferMapState_Unmapped :: Unmapped;
    WGPUBufferMapState_Pending  :: Pending;
    WGPUBufferMapState_Mapped   :: Mapped;
    WGPUBufferMapState_Force32  :: Force32;
}

/**
* The callback mode controls how a callback for an asynchronous operation may be fired. See @ref Asynchronous-Operations for how these are used.
*/
WGPUCallbackMode :: enum s32 {
    WaitAnyOnly        :: 1;

    AllowProcessEvents :: 2;

    AllowSpontaneous   :: 3;
    Force32            :: 2147483647;

    WGPUCallbackMode_WaitAnyOnly        :: WaitAnyOnly;

    WGPUCallbackMode_AllowProcessEvents :: AllowProcessEvents;

    WGPUCallbackMode_AllowSpontaneous   :: AllowSpontaneous;
    WGPUCallbackMode_Force32            :: Force32;
}

WGPUCompareFunction :: enum s32 {
    Undefined    :: 0;
    Never        :: 1;
    Less         :: 2;
    Equal        :: 3;
    LessEqual    :: 4;
    Greater      :: 5;
    NotEqual     :: 6;
    GreaterEqual :: 7;
    Always       :: 8;
    Force32      :: 2147483647;

    WGPUCompareFunction_Undefined    :: Undefined;
    WGPUCompareFunction_Never        :: Never;
    WGPUCompareFunction_Less         :: Less;
    WGPUCompareFunction_Equal        :: Equal;
    WGPUCompareFunction_LessEqual    :: LessEqual;
    WGPUCompareFunction_Greater      :: Greater;
    WGPUCompareFunction_NotEqual     :: NotEqual;
    WGPUCompareFunction_GreaterEqual :: GreaterEqual;
    WGPUCompareFunction_Always       :: Always;
    WGPUCompareFunction_Force32      :: Force32;
}

WGPUCompilationInfoRequestStatus :: enum s32 {
    Success         :: 1;
    InstanceDropped :: 2;
    Error           :: 3;
    Unknown         :: 4;
    Force32         :: 2147483647;

    WGPUCompilationInfoRequestStatus_Success         :: Success;
    WGPUCompilationInfoRequestStatus_InstanceDropped :: InstanceDropped;
    WGPUCompilationInfoRequestStatus_Error           :: Error;
    WGPUCompilationInfoRequestStatus_Unknown         :: Unknown;
    WGPUCompilationInfoRequestStatus_Force32         :: Force32;
}

WGPUCompilationMessageType :: enum s32 {
    Error   :: 1;
    Warning :: 2;
    Info    :: 3;
    Force32 :: 2147483647;

    WGPUCompilationMessageType_Error   :: Error;
    WGPUCompilationMessageType_Warning :: Warning;
    WGPUCompilationMessageType_Info    :: Info;
    WGPUCompilationMessageType_Force32 :: Force32;
}

/**
* Describes how frames are composited with other contents on the screen when `::wgpuSurfacePresent` is called.
*/
WGPUCompositeAlphaMode :: enum s32 {
    Auto            :: 0;

    Opaque          :: 1;

    Premultiplied   :: 2;

    Unpremultiplied :: 3;

    Inherit         :: 4;
    Force32         :: 2147483647;

    WGPUCompositeAlphaMode_Auto            :: Auto;

    WGPUCompositeAlphaMode_Opaque          :: Opaque;

    WGPUCompositeAlphaMode_Premultiplied   :: Premultiplied;

    WGPUCompositeAlphaMode_Unpremultiplied :: Unpremultiplied;

    WGPUCompositeAlphaMode_Inherit         :: Inherit;
    WGPUCompositeAlphaMode_Force32         :: Force32;
}

WGPUCreatePipelineAsyncStatus :: enum s32 {
    Success         :: 1;
    InstanceDropped :: 2;
    ValidationError :: 3;
    InternalError   :: 4;
    Unknown         :: 5;
    Force32         :: 2147483647;

    WGPUCreatePipelineAsyncStatus_Success         :: Success;
    WGPUCreatePipelineAsyncStatus_InstanceDropped :: InstanceDropped;
    WGPUCreatePipelineAsyncStatus_ValidationError :: ValidationError;
    WGPUCreatePipelineAsyncStatus_InternalError   :: InternalError;
    WGPUCreatePipelineAsyncStatus_Unknown         :: Unknown;
    WGPUCreatePipelineAsyncStatus_Force32         :: Force32;
}

WGPUCullMode :: enum s32 {
    Undefined :: 0;
    None      :: 1;
    Front     :: 2;
    Back      :: 3;
    Force32   :: 2147483647;

    WGPUCullMode_Undefined :: Undefined;
    WGPUCullMode_None      :: None;
    WGPUCullMode_Front     :: Front;
    WGPUCullMode_Back      :: Back;
    WGPUCullMode_Force32   :: Force32;
}

WGPUDeviceLostReason :: enum s32 {
    Unknown         :: 1;
    Destroyed       :: 2;
    InstanceDropped :: 3;
    FailedCreation  :: 4;
    Force32         :: 2147483647;

    WGPUDeviceLostReason_Unknown         :: Unknown;
    WGPUDeviceLostReason_Destroyed       :: Destroyed;
    WGPUDeviceLostReason_InstanceDropped :: InstanceDropped;
    WGPUDeviceLostReason_FailedCreation  :: FailedCreation;
    WGPUDeviceLostReason_Force32         :: Force32;
}

WGPUErrorFilter :: enum s32 {
    Validation  :: 1;
    OutOfMemory :: 2;
    Internal    :: 3;
    Force32     :: 2147483647;

    WGPUErrorFilter_Validation  :: Validation;
    WGPUErrorFilter_OutOfMemory :: OutOfMemory;
    WGPUErrorFilter_Internal    :: Internal;
    WGPUErrorFilter_Force32     :: Force32;
}

WGPUErrorType :: enum s32 {
    NoError     :: 1;
    Validation  :: 2;
    OutOfMemory :: 3;
    Internal    :: 4;
    Unknown     :: 5;
    Force32     :: 2147483647;

    WGPUErrorType_NoError     :: NoError;
    WGPUErrorType_Validation  :: Validation;
    WGPUErrorType_OutOfMemory :: OutOfMemory;
    WGPUErrorType_Internal    :: Internal;
    WGPUErrorType_Unknown     :: Unknown;
    WGPUErrorType_Force32     :: Force32;
}

/**
* See @ref WGPURequestAdapterOptions::featureLevel.
*/
WGPUFeatureLevel :: enum s32 {
    Compatibility :: 1;

    Core          :: 2;
    Force32       :: 2147483647;

    WGPUFeatureLevel_Compatibility :: Compatibility;

    WGPUFeatureLevel_Core          :: Core;
    WGPUFeatureLevel_Force32       :: Force32;
}

WGPUFeatureName :: enum s32 {
    Undefined                      :: 0;
    DepthClipControl               :: 1;
    Depth32FloatStencil8           :: 2;
    TimestampQuery                 :: 3;
    TextureCompressionBC           :: 4;
    TextureCompressionBCSliced3D   :: 5;
    TextureCompressionETC2         :: 6;
    TextureCompressionASTC         :: 7;
    TextureCompressionASTCSliced3D :: 8;
    IndirectFirstInstance          :: 9;
    ShaderF16                      :: 10;
    RG11B10UfloatRenderable        :: 11;
    BGRA8UnormStorage              :: 12;
    Float32Filterable              :: 13;
    Float32Blendable               :: 14;
    ClipDistances                  :: 15;
    DualSourceBlending             :: 16;
    Force32                        :: 2147483647;

    WGPUFeatureName_Undefined                      :: Undefined;
    WGPUFeatureName_DepthClipControl               :: DepthClipControl;
    WGPUFeatureName_Depth32FloatStencil8           :: Depth32FloatStencil8;
    WGPUFeatureName_TimestampQuery                 :: TimestampQuery;
    WGPUFeatureName_TextureCompressionBC           :: TextureCompressionBC;
    WGPUFeatureName_TextureCompressionBCSliced3D   :: TextureCompressionBCSliced3D;
    WGPUFeatureName_TextureCompressionETC2         :: TextureCompressionETC2;
    WGPUFeatureName_TextureCompressionASTC         :: TextureCompressionASTC;
    WGPUFeatureName_TextureCompressionASTCSliced3D :: TextureCompressionASTCSliced3D;
    WGPUFeatureName_IndirectFirstInstance          :: IndirectFirstInstance;
    WGPUFeatureName_ShaderF16                      :: ShaderF16;
    WGPUFeatureName_RG11B10UfloatRenderable        :: RG11B10UfloatRenderable;
    WGPUFeatureName_BGRA8UnormStorage              :: BGRA8UnormStorage;
    WGPUFeatureName_Float32Filterable              :: Float32Filterable;
    WGPUFeatureName_Float32Blendable               :: Float32Blendable;
    WGPUFeatureName_ClipDistances                  :: ClipDistances;
    WGPUFeatureName_DualSourceBlending             :: DualSourceBlending;
    WGPUFeatureName_Force32                        :: Force32;
}

WGPUFilterMode :: enum s32 {
    Undefined :: 0;
    Nearest   :: 1;
    Linear    :: 2;
    Force32   :: 2147483647;

    WGPUFilterMode_Undefined :: Undefined;
    WGPUFilterMode_Nearest   :: Nearest;
    WGPUFilterMode_Linear    :: Linear;
    WGPUFilterMode_Force32   :: Force32;
}

WGPUFrontFace :: enum s32 {
    Undefined :: 0;
    CCW       :: 1;
    CW        :: 2;
    Force32   :: 2147483647;

    WGPUFrontFace_Undefined :: Undefined;
    WGPUFrontFace_CCW       :: CCW;
    WGPUFrontFace_CW        :: CW;
    WGPUFrontFace_Force32   :: Force32;
}

WGPUIndexFormat :: enum s32 {
    Undefined :: 0;
    Uint16    :: 1;
    Uint32    :: 2;
    Force32   :: 2147483647;

    WGPUIndexFormat_Undefined :: Undefined;
    WGPUIndexFormat_Uint16    :: Uint16;
    WGPUIndexFormat_Uint32    :: Uint32;
    WGPUIndexFormat_Force32   :: Force32;
}

WGPULoadOp :: enum s32 {
    Undefined :: 0;
    Load      :: 1;
    Clear     :: 2;
    Force32   :: 2147483647;

    WGPULoadOp_Undefined :: Undefined;
    WGPULoadOp_Load      :: Load;
    WGPULoadOp_Clear     :: Clear;
    WGPULoadOp_Force32   :: Force32;
}

WGPUMapAsyncStatus :: enum s32 {
    Success         :: 1;
    InstanceDropped :: 2;
    Error           :: 3;
    Aborted         :: 4;
    Unknown         :: 5;
    Force32         :: 2147483647;

    WGPUMapAsyncStatus_Success         :: Success;
    WGPUMapAsyncStatus_InstanceDropped :: InstanceDropped;
    WGPUMapAsyncStatus_Error           :: Error;
    WGPUMapAsyncStatus_Aborted         :: Aborted;
    WGPUMapAsyncStatus_Unknown         :: Unknown;
    WGPUMapAsyncStatus_Force32         :: Force32;
}

WGPUMipmapFilterMode :: enum s32 {
    Undefined :: 0;
    Nearest   :: 1;
    Linear    :: 2;
    Force32   :: 2147483647;

    WGPUMipmapFilterMode_Undefined :: Undefined;
    WGPUMipmapFilterMode_Nearest   :: Nearest;
    WGPUMipmapFilterMode_Linear    :: Linear;
    WGPUMipmapFilterMode_Force32   :: Force32;
}

WGPUOptionalBool :: enum s32 {
    False     :: 0;
    True      :: 1;
    Undefined :: 2;
    Force32   :: 2147483647;

    WGPUOptionalBool_False     :: False;
    WGPUOptionalBool_True      :: True;
    WGPUOptionalBool_Undefined :: Undefined;
    WGPUOptionalBool_Force32   :: Force32;
}

WGPUPopErrorScopeStatus :: enum s32 {
    Success         :: 1;
    InstanceDropped :: 2;

    EmptyStack      :: 3;
    Force32         :: 2147483647;

    WGPUPopErrorScopeStatus_Success         :: Success;
    WGPUPopErrorScopeStatus_InstanceDropped :: InstanceDropped;

    WGPUPopErrorScopeStatus_EmptyStack      :: EmptyStack;
    WGPUPopErrorScopeStatus_Force32         :: Force32;
}

WGPUPowerPreference :: enum s32 {
    Undefined       :: 0;
    LowPower        :: 1;
    HighPerformance :: 2;
    Force32         :: 2147483647;

    WGPUPowerPreference_Undefined       :: Undefined;
    WGPUPowerPreference_LowPower        :: LowPower;
    WGPUPowerPreference_HighPerformance :: HighPerformance;
    WGPUPowerPreference_Force32         :: Force32;
}

/**
* Describes when and in which order frames are presented on the screen when `::wgpuSurfacePresent` is called.
*/
WGPUPresentMode :: enum s32 {
    Undefined   :: 0;

    Fifo        :: 1;

    FifoRelaxed :: 2;

    Immediate   :: 3;

    Mailbox     :: 4;
    Force32     :: 2147483647;

    WGPUPresentMode_Undefined   :: Undefined;

    WGPUPresentMode_Fifo        :: Fifo;

    WGPUPresentMode_FifoRelaxed :: FifoRelaxed;

    WGPUPresentMode_Immediate   :: Immediate;

    WGPUPresentMode_Mailbox     :: Mailbox;
    WGPUPresentMode_Force32     :: Force32;
}

WGPUPrimitiveTopology :: enum s32 {
    Undefined     :: 0;
    PointList     :: 1;
    LineList      :: 2;
    LineStrip     :: 3;
    TriangleList  :: 4;
    TriangleStrip :: 5;
    Force32       :: 2147483647;

    WGPUPrimitiveTopology_Undefined     :: Undefined;
    WGPUPrimitiveTopology_PointList     :: PointList;
    WGPUPrimitiveTopology_LineList      :: LineList;
    WGPUPrimitiveTopology_LineStrip     :: LineStrip;
    WGPUPrimitiveTopology_TriangleList  :: TriangleList;
    WGPUPrimitiveTopology_TriangleStrip :: TriangleStrip;
    WGPUPrimitiveTopology_Force32       :: Force32;
}

WGPUQueryType :: enum s32 {
    Occlusion :: 1;
    Timestamp :: 2;
    Force32   :: 2147483647;

    WGPUQueryType_Occlusion :: Occlusion;
    WGPUQueryType_Timestamp :: Timestamp;
    WGPUQueryType_Force32   :: Force32;
}

WGPUQueueWorkDoneStatus :: enum s32 {
    Success         :: 1;
    InstanceDropped :: 2;
    Error           :: 3;
    Unknown         :: 4;
    Force32         :: 2147483647;

    WGPUQueueWorkDoneStatus_Success         :: Success;
    WGPUQueueWorkDoneStatus_InstanceDropped :: InstanceDropped;
    WGPUQueueWorkDoneStatus_Error           :: Error;
    WGPUQueueWorkDoneStatus_Unknown         :: Unknown;
    WGPUQueueWorkDoneStatus_Force32         :: Force32;
}

WGPURequestAdapterStatus :: enum s32 {
    Success         :: 1;
    InstanceDropped :: 2;
    Unavailable     :: 3;
    Error           :: 4;
    Unknown         :: 5;
    Force32         :: 2147483647;

    WGPURequestAdapterStatus_Success         :: Success;
    WGPURequestAdapterStatus_InstanceDropped :: InstanceDropped;
    WGPURequestAdapterStatus_Unavailable     :: Unavailable;
    WGPURequestAdapterStatus_Error           :: Error;
    WGPURequestAdapterStatus_Unknown         :: Unknown;
    WGPURequestAdapterStatus_Force32         :: Force32;
}

WGPURequestDeviceStatus :: enum s32 {
    Success         :: 1;
    InstanceDropped :: 2;
    Error           :: 3;
    Unknown         :: 4;
    Force32         :: 2147483647;

    WGPURequestDeviceStatus_Success         :: Success;
    WGPURequestDeviceStatus_InstanceDropped :: InstanceDropped;
    WGPURequestDeviceStatus_Error           :: Error;
    WGPURequestDeviceStatus_Unknown         :: Unknown;
    WGPURequestDeviceStatus_Force32         :: Force32;
}

WGPUSType :: enum s32 {
    ShaderSourceSPIRV                :: 1;
    ShaderSourceWGSL                 :: 2;
    RenderPassMaxDrawCount           :: 3;
    SurfaceSourceMetalLayer          :: 4;
    SurfaceSourceWindowsHWND         :: 5;
    SurfaceSourceXlibWindow          :: 6;
    SurfaceSourceWaylandSurface      :: 7;
    SurfaceSourceAndroidNativeWindow :: 8;
    SurfaceSourceXCBWindow           :: 9;
    Force32                          :: 2147483647;

    WGPUSType_ShaderSourceSPIRV                :: ShaderSourceSPIRV;
    WGPUSType_ShaderSourceWGSL                 :: ShaderSourceWGSL;
    WGPUSType_RenderPassMaxDrawCount           :: RenderPassMaxDrawCount;
    WGPUSType_SurfaceSourceMetalLayer          :: SurfaceSourceMetalLayer;
    WGPUSType_SurfaceSourceWindowsHWND         :: SurfaceSourceWindowsHWND;
    WGPUSType_SurfaceSourceXlibWindow          :: SurfaceSourceXlibWindow;
    WGPUSType_SurfaceSourceWaylandSurface      :: SurfaceSourceWaylandSurface;
    WGPUSType_SurfaceSourceAndroidNativeWindow :: SurfaceSourceAndroidNativeWindow;
    WGPUSType_SurfaceSourceXCBWindow           :: SurfaceSourceXCBWindow;
    WGPUSType_Force32                          :: Force32;
}

WGPUSamplerBindingType :: enum s32 {
    BindingNotUsed :: 0;

    Undefined      :: 1;
    Filtering      :: 2;
    NonFiltering   :: 3;
    Comparison     :: 4;
    Force32        :: 2147483647;

    WGPUSamplerBindingType_BindingNotUsed :: BindingNotUsed;

    WGPUSamplerBindingType_Undefined      :: Undefined;
    WGPUSamplerBindingType_Filtering      :: Filtering;
    WGPUSamplerBindingType_NonFiltering   :: NonFiltering;
    WGPUSamplerBindingType_Comparison     :: Comparison;
    WGPUSamplerBindingType_Force32        :: Force32;
}

/**
* Status code returned (synchronously) from many operations. Generally
* indicates an invalid input like an unknown enum value or @ref OutStructChainError.
* Read the function's documentation for specific error conditions.
*/
WGPUStatus :: enum s32 {
    Success :: 1;
    Error   :: 2;
    Force32 :: 2147483647;

    WGPUStatus_Success :: Success;
    WGPUStatus_Error   :: Error;
    WGPUStatus_Force32 :: Force32;
}

WGPUStencilOperation :: enum s32 {
    Undefined      :: 0;
    Keep           :: 1;
    Zero           :: 2;
    Replace        :: 3;
    Invert         :: 4;
    IncrementClamp :: 5;
    DecrementClamp :: 6;
    IncrementWrap  :: 7;
    DecrementWrap  :: 8;
    Force32        :: 2147483647;

    WGPUStencilOperation_Undefined      :: Undefined;
    WGPUStencilOperation_Keep           :: Keep;
    WGPUStencilOperation_Zero           :: Zero;
    WGPUStencilOperation_Replace        :: Replace;
    WGPUStencilOperation_Invert         :: Invert;
    WGPUStencilOperation_IncrementClamp :: IncrementClamp;
    WGPUStencilOperation_DecrementClamp :: DecrementClamp;
    WGPUStencilOperation_IncrementWrap  :: IncrementWrap;
    WGPUStencilOperation_DecrementWrap  :: DecrementWrap;
    WGPUStencilOperation_Force32        :: Force32;
}

WGPUStorageTextureAccess :: enum s32 {
    BindingNotUsed :: 0;

    Undefined      :: 1;
    WriteOnly      :: 2;
    ReadOnly       :: 3;
    ReadWrite      :: 4;
    Force32        :: 2147483647;

    WGPUStorageTextureAccess_BindingNotUsed :: BindingNotUsed;

    WGPUStorageTextureAccess_Undefined      :: Undefined;
    WGPUStorageTextureAccess_WriteOnly      :: WriteOnly;
    WGPUStorageTextureAccess_ReadOnly       :: ReadOnly;
    WGPUStorageTextureAccess_ReadWrite      :: ReadWrite;
    WGPUStorageTextureAccess_Force32        :: Force32;
}

WGPUStoreOp :: enum s32 {
    Undefined :: 0;
    Store     :: 1;
    Discard   :: 2;
    Force32   :: 2147483647;

    WGPUStoreOp_Undefined :: Undefined;
    WGPUStoreOp_Store     :: Store;
    WGPUStoreOp_Discard   :: Discard;
    WGPUStoreOp_Force32   :: Force32;
}

/**
* The status enum for `::wgpuSurfaceGetCurrentTexture`.
*/
WGPUSurfaceGetCurrentTextureStatus :: enum s32 {
    SuccessOptimal    :: 1;

    SuccessSuboptimal :: 2;

    Timeout           :: 3;

    Outdated          :: 4;

    Lost              :: 5;

    OutOfMemory       :: 6;

    DeviceLost        :: 7;

    Error             :: 8;
    Force32           :: 2147483647;

    WGPUSurfaceGetCurrentTextureStatus_SuccessOptimal    :: SuccessOptimal;

    WGPUSurfaceGetCurrentTextureStatus_SuccessSuboptimal :: SuccessSuboptimal;

    WGPUSurfaceGetCurrentTextureStatus_Timeout           :: Timeout;

    WGPUSurfaceGetCurrentTextureStatus_Outdated          :: Outdated;

    WGPUSurfaceGetCurrentTextureStatus_Lost              :: Lost;

    WGPUSurfaceGetCurrentTextureStatus_OutOfMemory       :: OutOfMemory;

    WGPUSurfaceGetCurrentTextureStatus_DeviceLost        :: DeviceLost;

    WGPUSurfaceGetCurrentTextureStatus_Error             :: Error;
    WGPUSurfaceGetCurrentTextureStatus_Force32           :: Force32;
}

WGPUTextureAspect :: enum s32 {
    Undefined   :: 0;
    All         :: 1;
    StencilOnly :: 2;
    DepthOnly   :: 3;
    Force32     :: 2147483647;

    WGPUTextureAspect_Undefined   :: Undefined;
    WGPUTextureAspect_All         :: All;
    WGPUTextureAspect_StencilOnly :: StencilOnly;
    WGPUTextureAspect_DepthOnly   :: DepthOnly;
    WGPUTextureAspect_Force32     :: Force32;
}

WGPUTextureDimension :: enum s32 {
    Undefined :: 0;
    _1D       :: 1;
    _2D       :: 2;
    _3D       :: 3;
    Force32   :: 2147483647;

    WGPUTextureDimension_Undefined :: Undefined;
    WGPUTextureDimension_1D        :: _1D;
    WGPUTextureDimension_2D        :: _2D;
    WGPUTextureDimension_3D        :: _3D;
    WGPUTextureDimension_Force32   :: Force32;
}

WGPUTextureFormat :: enum s32 {
    Undefined            :: 0;
    R8Unorm              :: 1;
    R8Snorm              :: 2;
    R8Uint               :: 3;
    R8Sint               :: 4;
    R16Uint              :: 5;
    R16Sint              :: 6;
    R16Float             :: 7;
    RG8Unorm             :: 8;
    RG8Snorm             :: 9;
    RG8Uint              :: 10;
    RG8Sint              :: 11;
    R32Float             :: 12;
    R32Uint              :: 13;
    R32Sint              :: 14;
    RG16Uint             :: 15;
    RG16Sint             :: 16;
    RG16Float            :: 17;
    RGBA8Unorm           :: 18;
    RGBA8UnormSrgb       :: 19;
    RGBA8Snorm           :: 20;
    RGBA8Uint            :: 21;
    RGBA8Sint            :: 22;
    BGRA8Unorm           :: 23;
    BGRA8UnormSrgb       :: 24;
    RGB10A2Uint          :: 25;
    RGB10A2Unorm         :: 26;
    RG11B10Ufloat        :: 27;
    RGB9E5Ufloat         :: 28;
    RG32Float            :: 29;
    RG32Uint             :: 30;
    RG32Sint             :: 31;
    RGBA16Uint           :: 32;
    RGBA16Sint           :: 33;
    RGBA16Float          :: 34;
    RGBA32Float          :: 35;
    RGBA32Uint           :: 36;
    RGBA32Sint           :: 37;
    Stencil8             :: 38;
    Depth16Unorm         :: 39;
    Depth24Plus          :: 40;
    Depth24PlusStencil8  :: 41;
    Depth32Float         :: 42;
    Depth32FloatStencil8 :: 43;
    BC1RGBAUnorm         :: 44;
    BC1RGBAUnormSrgb     :: 45;
    BC2RGBAUnorm         :: 46;
    BC2RGBAUnormSrgb     :: 47;
    BC3RGBAUnorm         :: 48;
    BC3RGBAUnormSrgb     :: 49;
    BC4RUnorm            :: 50;
    BC4RSnorm            :: 51;
    BC5RGUnorm           :: 52;
    BC5RGSnorm           :: 53;
    BC6HRGBUfloat        :: 54;
    BC6HRGBFloat         :: 55;
    BC7RGBAUnorm         :: 56;
    BC7RGBAUnormSrgb     :: 57;
    ETC2RGB8Unorm        :: 58;
    ETC2RGB8UnormSrgb    :: 59;
    ETC2RGB8A1Unorm      :: 60;
    ETC2RGB8A1UnormSrgb  :: 61;
    ETC2RGBA8Unorm       :: 62;
    ETC2RGBA8UnormSrgb   :: 63;
    EACR11Unorm          :: 64;
    EACR11Snorm          :: 65;
    EACRG11Unorm         :: 66;
    EACRG11Snorm         :: 67;
    ASTC4x4Unorm         :: 68;
    ASTC4x4UnormSrgb     :: 69;
    ASTC5x4Unorm         :: 70;
    ASTC5x4UnormSrgb     :: 71;
    ASTC5x5Unorm         :: 72;
    ASTC5x5UnormSrgb     :: 73;
    ASTC6x5Unorm         :: 74;
    ASTC6x5UnormSrgb     :: 75;
    ASTC6x6Unorm         :: 76;
    ASTC6x6UnormSrgb     :: 77;
    ASTC8x5Unorm         :: 78;
    ASTC8x5UnormSrgb     :: 79;
    ASTC8x6Unorm         :: 80;
    ASTC8x6UnormSrgb     :: 81;
    ASTC8x8Unorm         :: 82;
    ASTC8x8UnormSrgb     :: 83;
    ASTC10x5Unorm        :: 84;
    ASTC10x5UnormSrgb    :: 85;
    ASTC10x6Unorm        :: 86;
    ASTC10x6UnormSrgb    :: 87;
    ASTC10x8Unorm        :: 88;
    ASTC10x8UnormSrgb    :: 89;
    ASTC10x10Unorm       :: 90;
    ASTC10x10UnormSrgb   :: 91;
    ASTC12x10Unorm       :: 92;
    ASTC12x10UnormSrgb   :: 93;
    ASTC12x12Unorm       :: 94;
    ASTC12x12UnormSrgb   :: 95;
    Force32              :: 2147483647;

    WGPUTextureFormat_Undefined            :: Undefined;
    WGPUTextureFormat_R8Unorm              :: R8Unorm;
    WGPUTextureFormat_R8Snorm              :: R8Snorm;
    WGPUTextureFormat_R8Uint               :: R8Uint;
    WGPUTextureFormat_R8Sint               :: R8Sint;
    WGPUTextureFormat_R16Uint              :: R16Uint;
    WGPUTextureFormat_R16Sint              :: R16Sint;
    WGPUTextureFormat_R16Float             :: R16Float;
    WGPUTextureFormat_RG8Unorm             :: RG8Unorm;
    WGPUTextureFormat_RG8Snorm             :: RG8Snorm;
    WGPUTextureFormat_RG8Uint              :: RG8Uint;
    WGPUTextureFormat_RG8Sint              :: RG8Sint;
    WGPUTextureFormat_R32Float             :: R32Float;
    WGPUTextureFormat_R32Uint              :: R32Uint;
    WGPUTextureFormat_R32Sint              :: R32Sint;
    WGPUTextureFormat_RG16Uint             :: RG16Uint;
    WGPUTextureFormat_RG16Sint             :: RG16Sint;
    WGPUTextureFormat_RG16Float            :: RG16Float;
    WGPUTextureFormat_RGBA8Unorm           :: RGBA8Unorm;
    WGPUTextureFormat_RGBA8UnormSrgb       :: RGBA8UnormSrgb;
    WGPUTextureFormat_RGBA8Snorm           :: RGBA8Snorm;
    WGPUTextureFormat_RGBA8Uint            :: RGBA8Uint;
    WGPUTextureFormat_RGBA8Sint            :: RGBA8Sint;
    WGPUTextureFormat_BGRA8Unorm           :: BGRA8Unorm;
    WGPUTextureFormat_BGRA8UnormSrgb       :: BGRA8UnormSrgb;
    WGPUTextureFormat_RGB10A2Uint          :: RGB10A2Uint;
    WGPUTextureFormat_RGB10A2Unorm         :: RGB10A2Unorm;
    WGPUTextureFormat_RG11B10Ufloat        :: RG11B10Ufloat;
    WGPUTextureFormat_RGB9E5Ufloat         :: RGB9E5Ufloat;
    WGPUTextureFormat_RG32Float            :: RG32Float;
    WGPUTextureFormat_RG32Uint             :: RG32Uint;
    WGPUTextureFormat_RG32Sint             :: RG32Sint;
    WGPUTextureFormat_RGBA16Uint           :: RGBA16Uint;
    WGPUTextureFormat_RGBA16Sint           :: RGBA16Sint;
    WGPUTextureFormat_RGBA16Float          :: RGBA16Float;
    WGPUTextureFormat_RGBA32Float          :: RGBA32Float;
    WGPUTextureFormat_RGBA32Uint           :: RGBA32Uint;
    WGPUTextureFormat_RGBA32Sint           :: RGBA32Sint;
    WGPUTextureFormat_Stencil8             :: Stencil8;
    WGPUTextureFormat_Depth16Unorm         :: Depth16Unorm;
    WGPUTextureFormat_Depth24Plus          :: Depth24Plus;
    WGPUTextureFormat_Depth24PlusStencil8  :: Depth24PlusStencil8;
    WGPUTextureFormat_Depth32Float         :: Depth32Float;
    WGPUTextureFormat_Depth32FloatStencil8 :: Depth32FloatStencil8;
    WGPUTextureFormat_BC1RGBAUnorm         :: BC1RGBAUnorm;
    WGPUTextureFormat_BC1RGBAUnormSrgb     :: BC1RGBAUnormSrgb;
    WGPUTextureFormat_BC2RGBAUnorm         :: BC2RGBAUnorm;
    WGPUTextureFormat_BC2RGBAUnormSrgb     :: BC2RGBAUnormSrgb;
    WGPUTextureFormat_BC3RGBAUnorm         :: BC3RGBAUnorm;
    WGPUTextureFormat_BC3RGBAUnormSrgb     :: BC3RGBAUnormSrgb;
    WGPUTextureFormat_BC4RUnorm            :: BC4RUnorm;
    WGPUTextureFormat_BC4RSnorm            :: BC4RSnorm;
    WGPUTextureFormat_BC5RGUnorm           :: BC5RGUnorm;
    WGPUTextureFormat_BC5RGSnorm           :: BC5RGSnorm;
    WGPUTextureFormat_BC6HRGBUfloat        :: BC6HRGBUfloat;
    WGPUTextureFormat_BC6HRGBFloat         :: BC6HRGBFloat;
    WGPUTextureFormat_BC7RGBAUnorm         :: BC7RGBAUnorm;
    WGPUTextureFormat_BC7RGBAUnormSrgb     :: BC7RGBAUnormSrgb;
    WGPUTextureFormat_ETC2RGB8Unorm        :: ETC2RGB8Unorm;
    WGPUTextureFormat_ETC2RGB8UnormSrgb    :: ETC2RGB8UnormSrgb;
    WGPUTextureFormat_ETC2RGB8A1Unorm      :: ETC2RGB8A1Unorm;
    WGPUTextureFormat_ETC2RGB8A1UnormSrgb  :: ETC2RGB8A1UnormSrgb;
    WGPUTextureFormat_ETC2RGBA8Unorm       :: ETC2RGBA8Unorm;
    WGPUTextureFormat_ETC2RGBA8UnormSrgb   :: ETC2RGBA8UnormSrgb;
    WGPUTextureFormat_EACR11Unorm          :: EACR11Unorm;
    WGPUTextureFormat_EACR11Snorm          :: EACR11Snorm;
    WGPUTextureFormat_EACRG11Unorm         :: EACRG11Unorm;
    WGPUTextureFormat_EACRG11Snorm         :: EACRG11Snorm;
    WGPUTextureFormat_ASTC4x4Unorm         :: ASTC4x4Unorm;
    WGPUTextureFormat_ASTC4x4UnormSrgb     :: ASTC4x4UnormSrgb;
    WGPUTextureFormat_ASTC5x4Unorm         :: ASTC5x4Unorm;
    WGPUTextureFormat_ASTC5x4UnormSrgb     :: ASTC5x4UnormSrgb;
    WGPUTextureFormat_ASTC5x5Unorm         :: ASTC5x5Unorm;
    WGPUTextureFormat_ASTC5x5UnormSrgb     :: ASTC5x5UnormSrgb;
    WGPUTextureFormat_ASTC6x5Unorm         :: ASTC6x5Unorm;
    WGPUTextureFormat_ASTC6x5UnormSrgb     :: ASTC6x5UnormSrgb;
    WGPUTextureFormat_ASTC6x6Unorm         :: ASTC6x6Unorm;
    WGPUTextureFormat_ASTC6x6UnormSrgb     :: ASTC6x6UnormSrgb;
    WGPUTextureFormat_ASTC8x5Unorm         :: ASTC8x5Unorm;
    WGPUTextureFormat_ASTC8x5UnormSrgb     :: ASTC8x5UnormSrgb;
    WGPUTextureFormat_ASTC8x6Unorm         :: ASTC8x6Unorm;
    WGPUTextureFormat_ASTC8x6UnormSrgb     :: ASTC8x6UnormSrgb;
    WGPUTextureFormat_ASTC8x8Unorm         :: ASTC8x8Unorm;
    WGPUTextureFormat_ASTC8x8UnormSrgb     :: ASTC8x8UnormSrgb;
    WGPUTextureFormat_ASTC10x5Unorm        :: ASTC10x5Unorm;
    WGPUTextureFormat_ASTC10x5UnormSrgb    :: ASTC10x5UnormSrgb;
    WGPUTextureFormat_ASTC10x6Unorm        :: ASTC10x6Unorm;
    WGPUTextureFormat_ASTC10x6UnormSrgb    :: ASTC10x6UnormSrgb;
    WGPUTextureFormat_ASTC10x8Unorm        :: ASTC10x8Unorm;
    WGPUTextureFormat_ASTC10x8UnormSrgb    :: ASTC10x8UnormSrgb;
    WGPUTextureFormat_ASTC10x10Unorm       :: ASTC10x10Unorm;
    WGPUTextureFormat_ASTC10x10UnormSrgb   :: ASTC10x10UnormSrgb;
    WGPUTextureFormat_ASTC12x10Unorm       :: ASTC12x10Unorm;
    WGPUTextureFormat_ASTC12x10UnormSrgb   :: ASTC12x10UnormSrgb;
    WGPUTextureFormat_ASTC12x12Unorm       :: ASTC12x12Unorm;
    WGPUTextureFormat_ASTC12x12UnormSrgb   :: ASTC12x12UnormSrgb;
    WGPUTextureFormat_Force32              :: Force32;
}

WGPUTextureSampleType :: enum s32 {
    BindingNotUsed    :: 0;

    Undefined         :: 1;
    Float             :: 2;
    UnfilterableFloat :: 3;
    Depth             :: 4;
    Sint              :: 5;
    Uint              :: 6;
    Force32           :: 2147483647;

    WGPUTextureSampleType_BindingNotUsed    :: BindingNotUsed;

    WGPUTextureSampleType_Undefined         :: Undefined;
    WGPUTextureSampleType_Float             :: Float;
    WGPUTextureSampleType_UnfilterableFloat :: UnfilterableFloat;
    WGPUTextureSampleType_Depth             :: Depth;
    WGPUTextureSampleType_Sint              :: Sint;
    WGPUTextureSampleType_Uint              :: Uint;
    WGPUTextureSampleType_Force32           :: Force32;
}

WGPUTextureViewDimension :: enum s32 {
    Undefined :: 0;
    _1D       :: 1;
    _2D       :: 2;
    _2DArray  :: 3;
    Cube      :: 4;
    CubeArray :: 5;
    _3D       :: 6;
    Force32   :: 2147483647;

    WGPUTextureViewDimension_Undefined :: Undefined;
    WGPUTextureViewDimension_1D        :: _1D;
    WGPUTextureViewDimension_2D        :: _2D;
    WGPUTextureViewDimension_2DArray   :: _2DArray;
    WGPUTextureViewDimension_Cube      :: Cube;
    WGPUTextureViewDimension_CubeArray :: CubeArray;
    WGPUTextureViewDimension_3D        :: _3D;
    WGPUTextureViewDimension_Force32   :: Force32;
}

WGPUVertexFormat :: enum s32 {
    Uint8           :: 1;
    Uint8x2         :: 2;
    Uint8x4         :: 3;
    Sint8           :: 4;
    Sint8x2         :: 5;
    Sint8x4         :: 6;
    Unorm8          :: 7;
    Unorm8x2        :: 8;
    Unorm8x4        :: 9;
    Snorm8          :: 10;
    Snorm8x2        :: 11;
    Snorm8x4        :: 12;
    Uint16          :: 13;
    Uint16x2        :: 14;
    Uint16x4        :: 15;
    Sint16          :: 16;
    Sint16x2        :: 17;
    Sint16x4        :: 18;
    Unorm16         :: 19;
    Unorm16x2       :: 20;
    Unorm16x4       :: 21;
    Snorm16         :: 22;
    Snorm16x2       :: 23;
    Snorm16x4       :: 24;
    Float16         :: 25;
    Float16x2       :: 26;
    Float16x4       :: 27;
    Float32         :: 28;
    Float32x2       :: 29;
    Float32x3       :: 30;
    Float32x4       :: 31;
    Uint32          :: 32;
    Uint32x2        :: 33;
    Uint32x3        :: 34;
    Uint32x4        :: 35;
    Sint32          :: 36;
    Sint32x2        :: 37;
    Sint32x3        :: 38;
    Sint32x4        :: 39;
    Unorm10_10_10_2 :: 40;
    Unorm8x4BGRA    :: 41;
    Force32         :: 2147483647;

    WGPUVertexFormat_Uint8           :: Uint8;
    WGPUVertexFormat_Uint8x2         :: Uint8x2;
    WGPUVertexFormat_Uint8x4         :: Uint8x4;
    WGPUVertexFormat_Sint8           :: Sint8;
    WGPUVertexFormat_Sint8x2         :: Sint8x2;
    WGPUVertexFormat_Sint8x4         :: Sint8x4;
    WGPUVertexFormat_Unorm8          :: Unorm8;
    WGPUVertexFormat_Unorm8x2        :: Unorm8x2;
    WGPUVertexFormat_Unorm8x4        :: Unorm8x4;
    WGPUVertexFormat_Snorm8          :: Snorm8;
    WGPUVertexFormat_Snorm8x2        :: Snorm8x2;
    WGPUVertexFormat_Snorm8x4        :: Snorm8x4;
    WGPUVertexFormat_Uint16          :: Uint16;
    WGPUVertexFormat_Uint16x2        :: Uint16x2;
    WGPUVertexFormat_Uint16x4        :: Uint16x4;
    WGPUVertexFormat_Sint16          :: Sint16;
    WGPUVertexFormat_Sint16x2        :: Sint16x2;
    WGPUVertexFormat_Sint16x4        :: Sint16x4;
    WGPUVertexFormat_Unorm16         :: Unorm16;
    WGPUVertexFormat_Unorm16x2       :: Unorm16x2;
    WGPUVertexFormat_Unorm16x4       :: Unorm16x4;
    WGPUVertexFormat_Snorm16         :: Snorm16;
    WGPUVertexFormat_Snorm16x2       :: Snorm16x2;
    WGPUVertexFormat_Snorm16x4       :: Snorm16x4;
    WGPUVertexFormat_Float16         :: Float16;
    WGPUVertexFormat_Float16x2       :: Float16x2;
    WGPUVertexFormat_Float16x4       :: Float16x4;
    WGPUVertexFormat_Float32         :: Float32;
    WGPUVertexFormat_Float32x2       :: Float32x2;
    WGPUVertexFormat_Float32x3       :: Float32x3;
    WGPUVertexFormat_Float32x4       :: Float32x4;
    WGPUVertexFormat_Uint32          :: Uint32;
    WGPUVertexFormat_Uint32x2        :: Uint32x2;
    WGPUVertexFormat_Uint32x3        :: Uint32x3;
    WGPUVertexFormat_Uint32x4        :: Uint32x4;
    WGPUVertexFormat_Sint32          :: Sint32;
    WGPUVertexFormat_Sint32x2        :: Sint32x2;
    WGPUVertexFormat_Sint32x3        :: Sint32x3;
    WGPUVertexFormat_Sint32x4        :: Sint32x4;
    WGPUVertexFormat_Unorm10_10_10_2 :: Unorm10_10_10_2;
    WGPUVertexFormat_Unorm8x4BGRA    :: Unorm8x4BGRA;
    WGPUVertexFormat_Force32         :: Force32;
}

WGPUVertexStepMode :: enum s32 {
    VertexBufferNotUsed :: 0;

    Undefined           :: 1;
    Vertex              :: 2;
    Instance            :: 3;
    Force32             :: 2147483647;

    WGPUVertexStepMode_VertexBufferNotUsed :: VertexBufferNotUsed;

    WGPUVertexStepMode_Undefined           :: Undefined;
    WGPUVertexStepMode_Vertex              :: Vertex;
    WGPUVertexStepMode_Instance            :: Instance;
    WGPUVertexStepMode_Force32             :: Force32;
}

WGPUWGSLLanguageFeatureName :: enum s32 {
    ReadonlyAndReadwriteStorageTextures :: 1;
    Packed4x8IntegerDotProduct          :: 2;
    UnrestrictedPointerParameters       :: 3;
    PointerCompositeAccess              :: 4;
    Force32                             :: 2147483647;

    WGPUWGSLLanguageFeatureName_ReadonlyAndReadwriteStorageTextures :: ReadonlyAndReadwriteStorageTextures;
    WGPUWGSLLanguageFeatureName_Packed4x8IntegerDotProduct          :: Packed4x8IntegerDotProduct;
    WGPUWGSLLanguageFeatureName_UnrestrictedPointerParameters       :: UnrestrictedPointerParameters;
    WGPUWGSLLanguageFeatureName_PointerCompositeAccess              :: PointerCompositeAccess;
    WGPUWGSLLanguageFeatureName_Force32                             :: Force32;
}

/**
* Status returned from a call to ::wgpuInstanceWaitAny.
*/
WGPUWaitStatus :: enum s32 {
    Success                 :: 1;

    TimedOut                :: 2;

    UnsupportedTimeout      :: 3;

    UnsupportedCount        :: 4;

    UnsupportedMixedSources :: 5;
    Force32                 :: 2147483647;

    WGPUWaitStatus_Success                 :: Success;

    WGPUWaitStatus_TimedOut                :: TimedOut;

    WGPUWaitStatus_UnsupportedTimeout      :: UnsupportedTimeout;

    WGPUWaitStatus_UnsupportedCount        :: UnsupportedCount;

    WGPUWaitStatus_UnsupportedMixedSources :: UnsupportedMixedSources;
    WGPUWaitStatus_Force32                 :: Force32;
}

/**
* \defgroup Bitflags
* \brief Type and constant definitions for bitflag types.
*
* @{
*/
WGPUBufferUsage :: WGPUFlags;
WGPUBufferUsage_None: WGPUBufferUsage : 0;
WGPUBufferUsage_MapRead: WGPUBufferUsage : 1;
WGPUBufferUsage_MapWrite: WGPUBufferUsage : 2;
WGPUBufferUsage_CopySrc: WGPUBufferUsage : 4;
WGPUBufferUsage_CopyDst: WGPUBufferUsage : 8;
WGPUBufferUsage_Index: WGPUBufferUsage : 16;
WGPUBufferUsage_Vertex: WGPUBufferUsage : 32;
WGPUBufferUsage_Uniform: WGPUBufferUsage : 64;
WGPUBufferUsage_Storage: WGPUBufferUsage : 128;
WGPUBufferUsage_Indirect: WGPUBufferUsage : 256;
WGPUBufferUsage_QueryResolve: WGPUBufferUsage : 512;

WGPUColorWriteMask :: WGPUFlags;
WGPUColorWriteMask_None: WGPUColorWriteMask : 0;
WGPUColorWriteMask_Red: WGPUColorWriteMask : 1;
WGPUColorWriteMask_Green: WGPUColorWriteMask : 2;
WGPUColorWriteMask_Blue: WGPUColorWriteMask : 4;
WGPUColorWriteMask_Alpha: WGPUColorWriteMask : 8;
WGPUColorWriteMask_All: WGPUColorWriteMask : 15; /* Red | Green | Blue | Alpha */

WGPUMapMode :: WGPUFlags;
WGPUMapMode_None: WGPUMapMode : 0;
WGPUMapMode_Read: WGPUMapMode : 1;
WGPUMapMode_Write: WGPUMapMode : 2;

WGPUShaderStage :: WGPUFlags;
WGPUShaderStage_None: WGPUShaderStage : 0;
WGPUShaderStage_Vertex: WGPUShaderStage : 1;
WGPUShaderStage_Fragment: WGPUShaderStage : 2;
WGPUShaderStage_Compute: WGPUShaderStage : 4;

WGPUTextureUsage :: WGPUFlags;
WGPUTextureUsage_None: WGPUTextureUsage : 0;
WGPUTextureUsage_CopySrc: WGPUTextureUsage : 1;
WGPUTextureUsage_CopyDst: WGPUTextureUsage : 2;
WGPUTextureUsage_TextureBinding: WGPUTextureUsage : 4;
WGPUTextureUsage_StorageBinding: WGPUTextureUsage : 8;
WGPUTextureUsage_RenderAttachment: WGPUTextureUsage : 16;

/** @} */
WGPUProc :: #type () -> void #c_call;

/**
* \defgroup Callbacks
* \brief Callbacks through which asynchronous functions return.
*
* @{
*/
/**
* @param message
* This parameter is @ref PassedWithoutOwnership.
*/
WGPUBufferMapCallback :: #type (status: WGPUMapAsyncStatus, message: WGPUStringView, userdata1: *void, userdata2: *void) -> void #c_call;

/**
* @param compilationInfo
* This parameter is @ref PassedWithoutOwnership.
*/
WGPUCompilationInfoCallback :: #type (status: WGPUCompilationInfoRequestStatus, compilationInfo: *WGPUCompilationInfo, userdata1: *void, userdata2: *void) -> void #c_call;

/**
* @param pipeline
* This parameter is @ref PassedWithOwnership.
*/
WGPUCreateComputePipelineAsyncCallback :: #type (status: WGPUCreatePipelineAsyncStatus, pipeline: WGPUComputePipeline, message: WGPUStringView, userdata1: *void, userdata2: *void) -> void #c_call;

/**
* @param pipeline
* This parameter is @ref PassedWithOwnership.
*/
WGPUCreateRenderPipelineAsyncCallback :: #type (status: WGPUCreatePipelineAsyncStatus, pipeline: WGPURenderPipeline, message: WGPUStringView, userdata1: *void, userdata2: *void) -> void #c_call;

/**
* @param device
* Reference to the device which was lost. If, and only if, the `reason` is @ref WGPUDeviceLostReason_FailedCreation, this is a non-null pointer to a null @ref WGPUDevice.
* This parameter is @ref PassedWithoutOwnership.
*
* @param message
* This parameter is @ref PassedWithoutOwnership.
*/
WGPUDeviceLostCallback :: #type (device: *WGPUDevice, reason: WGPUDeviceLostReason, message: WGPUStringView, userdata1: *void, userdata2: *void) -> void #c_call;

/**
* @param status
* See @ref WGPUPopErrorScopeStatus.
*
* @param type
* The type of the error caught by the scope, or @ref WGPUErrorType_NoError if there was none.
* If the `status` is not @ref WGPUPopErrorScopeStatus_Success, this is @ref WGPUErrorType_NoError.
*
* @param message
* If the `type` is not @ref WGPUErrorType_NoError, this is a non-empty @ref LocalizableHumanReadableMessageString;
* otherwise, this is an empty string.
* This parameter is @ref PassedWithoutOwnership.
*/
WGPUPopErrorScopeCallback :: #type (status: WGPUPopErrorScopeStatus, type: WGPUErrorType, message: WGPUStringView, userdata1: *void, userdata2: *void) -> void #c_call;
WGPUQueueWorkDoneCallback :: #type (status: WGPUQueueWorkDoneStatus, userdata1: *void, userdata2: *void) -> void #c_call;

/**
* @param adapter
* This parameter is @ref PassedWithOwnership.
*
* @param message
* This parameter is @ref PassedWithoutOwnership.
*/
WGPURequestAdapterCallback :: #type (status: WGPURequestAdapterStatus, adapter: WGPUAdapter, message: WGPUStringView, userdata1: *void, userdata2: *void) -> void #c_call;

/**
* @param device
* This parameter is @ref PassedWithOwnership.
*
* @param message
* This parameter is @ref PassedWithoutOwnership.
*/
WGPURequestDeviceCallback :: #type (status: WGPURequestDeviceStatus, device: WGPUDevice, message: WGPUStringView, userdata1: *void, userdata2: *void) -> void #c_call;

/**
* @param device
* This parameter is @ref PassedWithoutOwnership.
*
* @param message
* This parameter is @ref PassedWithoutOwnership.
*/
WGPUUncapturedErrorCallback :: #type (device: *WGPUDevice, type: WGPUErrorType, message: WGPUStringView, userdata1: *void, userdata2: *void) -> void #c_call;

/** @} */
/**
* \defgroup ChainedStructures Chained Structures
* \brief Structures used to extend descriptors.
*
* @{
*/
WGPUChainedStruct :: struct {
    next:  *WGPUChainedStruct;
    sType: WGPUSType;
}

WGPUChainedStructOut :: struct {
    next:  *WGPUChainedStructOut;
    sType: WGPUSType;
}

// Callback info structure forward declarations
WGPUBufferMapCallbackInfo :: struct {
    nextInChain: *WGPUChainedStruct;
    mode:        WGPUCallbackMode;
    callback:    WGPUBufferMapCallback;
    userdata1:   *void;
    userdata2:   *void;
}

WGPUCompilationInfoCallbackInfo :: struct {
    nextInChain: *WGPUChainedStruct;
    mode:        WGPUCallbackMode;
    callback:    WGPUCompilationInfoCallback;
    userdata1:   *void;
    userdata2:   *void;
}

WGPUCreateComputePipelineAsyncCallbackInfo :: struct {
    nextInChain: *WGPUChainedStruct;
    mode:        WGPUCallbackMode;
    callback:    WGPUCreateComputePipelineAsyncCallback;
    userdata1:   *void;
    userdata2:   *void;
}

WGPUCreateRenderPipelineAsyncCallbackInfo :: struct {
    nextInChain: *WGPUChainedStruct;
    mode:        WGPUCallbackMode;
    callback:    WGPUCreateRenderPipelineAsyncCallback;
    userdata1:   *void;
    userdata2:   *void;
}

WGPUDeviceLostCallbackInfo :: struct {
    nextInChain: *WGPUChainedStruct;
    mode:        WGPUCallbackMode;
    callback:    WGPUDeviceLostCallback;
    userdata1:   *void;
    userdata2:   *void;
}

WGPUPopErrorScopeCallbackInfo :: struct {
    nextInChain: *WGPUChainedStruct;
    mode:        WGPUCallbackMode;
    callback:    WGPUPopErrorScopeCallback;
    userdata1:   *void;
    userdata2:   *void;
}

WGPUQueueWorkDoneCallbackInfo :: struct {
    nextInChain: *WGPUChainedStruct;
    mode:        WGPUCallbackMode;
    callback:    WGPUQueueWorkDoneCallback;
    userdata1:   *void;
    userdata2:   *void;
}

WGPURequestAdapterCallbackInfo :: struct {
    nextInChain: *WGPUChainedStruct;
    mode:        WGPUCallbackMode;
    callback:    WGPURequestAdapterCallback;
    userdata1:   *void;
    userdata2:   *void;
}

WGPURequestDeviceCallbackInfo :: struct {
    nextInChain: *WGPUChainedStruct;
    mode:        WGPUCallbackMode;
    callback:    WGPURequestDeviceCallback;
    userdata1:   *void;
    userdata2:   *void;
}

WGPUUncapturedErrorCallbackInfo :: struct {
    nextInChain: *WGPUChainedStruct;
    callback:    WGPUUncapturedErrorCallback;
    userdata1:   *void;
    userdata2:   *void;
}

/** @} */
// Structure forward declarations
WGPUAdapterInfo :: struct {
    nextInChain:  *WGPUChainedStructOut;

    /**
    * This is an \ref OutputString.
    */
    vendor:       WGPUStringView;

    /**
    * This is an \ref OutputString.
    */
    architecture: WGPUStringView;

    /**
    * This is an \ref OutputString.
    */
    device:       WGPUStringView;

    /**
    * This is an \ref OutputString.
    */
    description:  WGPUStringView;
    backendType:  WGPUBackendType;
    adapterType:  WGPUAdapterType;
    vendorID:     u32;
    deviceID:     u32;
}

WGPUBindGroupEntry :: struct {
    nextInChain: *WGPUChainedStruct;
    binding:     u32;
    buffer:      WGPUBuffer;
    offset:      u64;
    size:        u64;
    sampler:     WGPUSampler;
    textureView: WGPUTextureView;
}

WGPUBlendComponent :: struct {
    operation: WGPUBlendOperation;
    srcFactor: WGPUBlendFactor;
    dstFactor: WGPUBlendFactor;
}

WGPUBufferBindingLayout :: struct {
    nextInChain:      *WGPUChainedStruct;
    type:             WGPUBufferBindingType;
    hasDynamicOffset: WGPUBool;
    minBindingSize:   u64;
}

WGPUBufferDescriptor :: struct {
    nextInChain:      *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:            WGPUStringView;
    usage:            WGPUBufferUsage;
    size:             u64;
    mappedAtCreation: WGPUBool;
}

WGPUColor :: struct {
    r: float64;
    g: float64;
    b: float64;
    a: float64;
}

WGPUCommandBufferDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:       WGPUStringView;
}

WGPUCommandEncoderDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:       WGPUStringView;
}

WGPUCompilationMessage :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * A @ref LocalizableHumanReadableMessageString.
    *
    * This is an \ref OutputString.
    */
    message:     WGPUStringView;

    /**
    * Severity level of the message.
    */
    type:        WGPUCompilationMessageType;

    /**
    * Line number where the message is attached, starting at 1.
    */
    lineNum:     u64;

    /**
    * Offset in UTF-8 code units (bytes) from the beginning of the line, starting at 1.
    */
    linePos:     u64;

    /**
    * Offset in UTF-8 code units (bytes) from the beginning of the shader code, starting at 0.
    */
    offset:      u64;

    /**
    * Length in UTF-8 code units (bytes) of the span the message corresponds to.
    */
    length:      u64;
}

WGPUComputePassTimestampWrites :: struct {
    querySet:                  WGPUQuerySet;
    beginningOfPassWriteIndex: u32;
    endOfPassWriteIndex:       u32;
}

WGPUConstantEntry :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    key:         WGPUStringView;
    value:       float64;
}

WGPUExtent3D :: struct {
    width:              u32;
    height:             u32;
    depthOrArrayLayers: u32;
}

/**
* Opaque handle to an asynchronous operation. See @ref Asynchronous-Operations for more information.
*/
WGPUFuture :: struct {
    /**
    * Opaque id of the @ref WGPUFuture
    */
    id: u64;
}

/**
* Features enabled on the WGPUInstance
*/
WGPUInstanceCapabilities :: struct {
    /** This struct chain is used as mutable in some places and immutable in others. */
    nextInChain:          *WGPUChainedStructOut;

    /**
    * Enable use of ::wgpuInstanceWaitAny with `timeoutNS > 0`.
    */
    timedWaitAnyEnable:   WGPUBool;

    /**
    * The maximum number @ref WGPUFutureWaitInfo supported in a call to ::wgpuInstanceWaitAny with `timeoutNS > 0`.
    */
    timedWaitAnyMaxCount: u64;
}

WGPULimits :: struct {
    /** This struct chain is used as mutable in some places and immutable in others. */
    nextInChain:                               *WGPUChainedStructOut;
    maxTextureDimension1D:                     u32;
    maxTextureDimension2D:                     u32;
    maxTextureDimension3D:                     u32;
    maxTextureArrayLayers:                     u32;
    maxBindGroups:                             u32;
    maxBindGroupsPlusVertexBuffers:            u32;
    maxBindingsPerBindGroup:                   u32;
    maxDynamicUniformBuffersPerPipelineLayout: u32;
    maxDynamicStorageBuffersPerPipelineLayout: u32;
    maxSampledTexturesPerShaderStage:          u32;
    maxSamplersPerShaderStage:                 u32;
    maxStorageBuffersPerShaderStage:           u32;
    maxStorageTexturesPerShaderStage:          u32;
    maxUniformBuffersPerShaderStage:           u32;
    maxUniformBufferBindingSize:               u64;
    maxStorageBufferBindingSize:               u64;
    minUniformBufferOffsetAlignment:           u32;
    minStorageBufferOffsetAlignment:           u32;
    maxVertexBuffers:                          u32;
    maxBufferSize:                             u64;
    maxVertexAttributes:                       u32;
    maxVertexBufferArrayStride:                u32;
    maxInterStageShaderVariables:              u32;
    maxColorAttachments:                       u32;
    maxColorAttachmentBytesPerSample:          u32;
    maxComputeWorkgroupStorageSize:            u32;
    maxComputeInvocationsPerWorkgroup:         u32;
    maxComputeWorkgroupSizeX:                  u32;
    maxComputeWorkgroupSizeY:                  u32;
    maxComputeWorkgroupSizeZ:                  u32;
    maxComputeWorkgroupsPerDimension:          u32;
}

WGPUMultisampleState :: struct {
    nextInChain:            *WGPUChainedStruct;
    count:                  u32;
    mask:                   u32;
    alphaToCoverageEnabled: WGPUBool;
}

WGPUOrigin3D :: struct {
    x: u32;
    y: u32;
    z: u32;
}

WGPUPipelineLayoutDescriptor :: struct {
    nextInChain:          *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:                WGPUStringView;
    bindGroupLayoutCount: u64;
    bindGroupLayouts:     *WGPUBindGroupLayout;
}

WGPUPrimitiveState :: struct {
    nextInChain:      *WGPUChainedStruct;
    topology:         WGPUPrimitiveTopology;
    stripIndexFormat: WGPUIndexFormat;
    frontFace:        WGPUFrontFace;
    cullMode:         WGPUCullMode;
    unclippedDepth:   WGPUBool;
}

WGPUQuerySetDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:       WGPUStringView;
    type:        WGPUQueryType;
    count:       u32;
}

WGPUQueueDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:       WGPUStringView;
}

WGPURenderBundleDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:       WGPUStringView;
}

WGPURenderBundleEncoderDescriptor :: struct {
    nextInChain:        *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:              WGPUStringView;
    colorFormatCount:   u64;
    colorFormats:       *WGPUTextureFormat;
    depthStencilFormat: WGPUTextureFormat;
    sampleCount:        u32;
    depthReadOnly:      WGPUBool;
    stencilReadOnly:    WGPUBool;
}

WGPURenderPassDepthStencilAttachment :: struct {
    view:              WGPUTextureView;
    depthLoadOp:       WGPULoadOp;
    depthStoreOp:      WGPUStoreOp;
    depthClearValue:   float;
    depthReadOnly:     WGPUBool;
    stencilLoadOp:     WGPULoadOp;
    stencilStoreOp:    WGPUStoreOp;
    stencilClearValue: u32;
    stencilReadOnly:   WGPUBool;
}

WGPURenderPassMaxDrawCount :: struct {
    chain:        WGPUChainedStruct;
    maxDrawCount: u64;
}

WGPURenderPassTimestampWrites :: struct {
    querySet:                  WGPUQuerySet;
    beginningOfPassWriteIndex: u32;
    endOfPassWriteIndex:       u32;
}

WGPURequestAdapterOptions :: struct {
    nextInChain:          *WGPUChainedStruct;

    /**
    * "Feature level" for the adapter request. If an adapter is returned, it must support the features and limits in the requested feature level.
    *
    * Implementations may ignore @ref WGPUFeatureLevel_Compatibility and provide @ref WGPUFeatureLevel_Core instead. @ref WGPUFeatureLevel_Core is the default in the JS API, but in C, this field is **required** (must not be undefined).
    */
    featureLevel:         WGPUFeatureLevel;
    powerPreference:      WGPUPowerPreference;

    /**
    * If true, requires the adapter to be a "fallback" adapter as defined by the JS spec.
    * If this is not possible, the request returns null.
    */
    forceFallbackAdapter: WGPUBool;

    /**
    * If set, requires the adapter to have a particular backend type.
    * If this is not possible, the request returns null.
    */
    backendType:          WGPUBackendType;

    /**
    * If set, requires the adapter to be able to output to a particular surface.
    * If this is not possible, the request returns null.
    */
    compatibleSurface:    WGPUSurface;
}

WGPUSamplerBindingLayout :: struct {
    nextInChain: *WGPUChainedStruct;
    type:        WGPUSamplerBindingType;
}

WGPUSamplerDescriptor :: struct {
    nextInChain:   *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:         WGPUStringView;
    addressModeU:  WGPUAddressMode;
    addressModeV:  WGPUAddressMode;
    addressModeW:  WGPUAddressMode;
    magFilter:     WGPUFilterMode;
    minFilter:     WGPUFilterMode;
    mipmapFilter:  WGPUMipmapFilterMode;
    lodMinClamp:   float;
    lodMaxClamp:   float;
    compare:       WGPUCompareFunction;
    maxAnisotropy: u16;
}

WGPUShaderModuleDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:       WGPUStringView;
}

WGPUShaderSourceSPIRV :: struct {
    chain:    WGPUChainedStruct;
    codeSize: u32;
    code:     *u32;
}

WGPUShaderSourceWGSL :: struct {
    chain: WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    code:  WGPUStringView;
}

WGPUStencilFaceState :: struct {
    compare:     WGPUCompareFunction;
    failOp:      WGPUStencilOperation;
    depthFailOp: WGPUStencilOperation;
    passOp:      WGPUStencilOperation;
}

WGPUStorageTextureBindingLayout :: struct {
    nextInChain:   *WGPUChainedStruct;
    access:        WGPUStorageTextureAccess;
    format:        WGPUTextureFormat;
    viewDimension: WGPUTextureViewDimension;
}

WGPUSupportedFeatures :: struct {
    featureCount: u64;
    features:     *WGPUFeatureName;
}

WGPUSupportedWGSLLanguageFeatures :: struct {
    featureCount: u64;
    features:     *WGPUWGSLLanguageFeatureName;
}

/**
* Filled by `::wgpuSurfaceGetCapabilities` with what's supported for `::wgpuSurfaceConfigure` for a pair of @ref WGPUSurface and @ref WGPUAdapter.
*/
WGPUSurfaceCapabilities :: struct {
    nextInChain:      *WGPUChainedStructOut;

    /**
    * The bit set of supported @ref WGPUTextureUsage bits.
    * Guaranteed to contain @ref WGPUTextureUsage_RenderAttachment.
    */
    usages:           WGPUTextureUsage;

    /**
    * A list of supported @ref WGPUTextureFormat values, in order of preference.
    */
    formatCount:      u64;
    formats:          *WGPUTextureFormat;

    /**
    * A list of supported @ref WGPUPresentMode values.
    * Guaranteed to contain @ref WGPUPresentMode_Fifo.
    */
    presentModeCount: u64;
    presentModes:     *WGPUPresentMode;

    /**
    * A list of supported @ref WGPUCompositeAlphaMode values.
    * @ref WGPUCompositeAlphaMode_Auto will be an alias for the first element and will never be present in this array.
    */
    alphaModeCount:   u64;
    alphaModes:       *WGPUCompositeAlphaMode;
}

/**
* Options to `::wgpuSurfaceConfigure` for defining how a @ref WGPUSurface will be rendered to and presented to the user.
* See @ref Surface-Configuration for more details.
*/
WGPUSurfaceConfiguration :: struct {
    nextInChain:     *WGPUChainedStruct;

    /**
    * The @ref WGPUDevice to use to render to surface's textures.
    */
    device:          WGPUDevice;

    /**
    * The @ref WGPUTextureFormat of the surface's textures.
    */
    format:          WGPUTextureFormat;

    /**
    * The @ref WGPUTextureUsage of the surface's textures.
    */
    usage:           WGPUTextureUsage;

    /**
    * The width of the surface's textures.
    */
    width:           u32;

    /**
    * The height of the surface's textures.
    */
    height:          u32;

    /**
    * The additional @ref WGPUTextureFormat for @ref WGPUTextureView format reinterpretation of the surface's textures.
    */
    viewFormatCount: u64;
    viewFormats:     *WGPUTextureFormat;

    /**
    * How the surface's frames will be composited on the screen.
    */
    alphaMode:       WGPUCompositeAlphaMode;

    /**
    * When and in which order the surface's frames will be shown on the screen. Defaults to @ref WGPUPresentMode_Fifo.
    */
    presentMode:     WGPUPresentMode;
}

/**
* The root descriptor for the creation of an @ref WGPUSurface with `::wgpuInstanceCreateSurface`.
* It isn't sufficient by itself and must have one of the `WGPUSurfaceSource*` in its chain.
* See @ref Surface-Creation for more details.
*/
WGPUSurfaceDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * Label used to refer to the object.
    *
    * This is a \ref NonNullInputString.
    */
    label:       WGPUStringView;
}

/**
* Chained in @ref WGPUSurfaceDescriptor to make an @ref WGPUSurface wrapping an Android [`ANativeWindow`](https://developer.android.com/ndk/reference/group/a-native-window).
*/
WGPUSurfaceSourceAndroidNativeWindow :: struct {
    chain:  WGPUChainedStruct;

    /**
    * The pointer to the [`ANativeWindow`](https://developer.android.com/ndk/reference/group/a-native-window) that will be wrapped by the @ref WGPUSurface.
    */
    window: *void;
}

/**
* Chained in @ref WGPUSurfaceDescriptor to make an @ref WGPUSurface wrapping a [`CAMetalLayer`](https://developer.apple.com/documentation/quartzcore/cametallayer?language=objc).
*/
WGPUSurfaceSourceMetalLayer :: struct {
    chain: WGPUChainedStruct;

    /**
    * The pointer to the [`CAMetalLayer`](https://developer.apple.com/documentation/quartzcore/cametallayer?language=objc) that will be wrapped by the @ref WGPUSurface.
    */
    layer: *void;
}

/**
* Chained in @ref WGPUSurfaceDescriptor to make an @ref WGPUSurface wrapping a [Wayland](https://wayland.freedesktop.org/) [`wl_surface`](https://wayland.freedesktop.org/docs/html/apa.html#protocol-spec-wl_surface).
*/
WGPUSurfaceSourceWaylandSurface :: struct {
    chain:   WGPUChainedStruct;

    /**
    * A [`wl_display`](https://wayland.freedesktop.org/docs/html/apa.html#protocol-spec-wl_display) for this Wayland instance.
    */
    display: *void;

    /**
    * A [`wl_surface`](https://wayland.freedesktop.org/docs/html/apa.html#protocol-spec-wl_surface) that will be wrapped by the @ref WGPUSurface
    */
    surface: *void;
}

/**
* Chained in @ref WGPUSurfaceDescriptor to make an @ref WGPUSurface wrapping a Windows [`HWND`](https://learn.microsoft.com/en-us/windows/apps/develop/ui-input/retrieve-hwnd).
*/
WGPUSurfaceSourceWindowsHWND :: struct {
    chain:     WGPUChainedStruct;

    /**
    * The [`HINSTANCE`](https://learn.microsoft.com/en-us/windows/win32/learnwin32/winmain--the-application-entry-point) for this application.
    * Most commonly `GetModuleHandle(nullptr)`.
    */
    hinstance: *void;

    /**
    * The [`HWND`](https://learn.microsoft.com/en-us/windows/apps/develop/ui-input/retrieve-hwnd) that will be wrapped by the @ref WGPUSurface.
    */
    hwnd:      *void;
}

/**
* Chained in @ref WGPUSurfaceDescriptor to make an @ref WGPUSurface wrapping an [XCB](https://xcb.freedesktop.org/) `xcb_window_t`.
*/
WGPUSurfaceSourceXCBWindow :: struct {
    chain:      WGPUChainedStruct;

    /**
    * The `xcb_connection_t` for the connection to the X server.
    */
    connection: *void;

    /**
    * The `xcb_window_t` for the window that will be wrapped by the @ref WGPUSurface.
    */
    window:     u32;
}

/**
* Chained in @ref WGPUSurfaceDescriptor to make an @ref WGPUSurface wrapping an [Xlib](https://www.x.org/releases/current/doc/libX11/libX11/libX11.html) `Window`.
*/
WGPUSurfaceSourceXlibWindow :: struct {
    chain:   WGPUChainedStruct;

    /**
    * A pointer to the [`Display`](https://www.x.org/releases/current/doc/libX11/libX11/libX11.html#Opening_the_Display) connected to the X server.
    */
    display: *void;

    /**
    * The [`Window`](https://www.x.org/releases/current/doc/libX11/libX11/libX11.html#Creating_Windows) that will be wrapped by the @ref WGPUSurface.
    */
    window:  u64;
}

/**
* Queried each frame from a @ref WGPUSurface to get a @ref WGPUTexture to render to along with some metadata.
* See @ref Surface-Presenting for more details.
*/
WGPUSurfaceTexture :: struct {
    nextInChain: *WGPUChainedStructOut;

    /**
    * The @ref WGPUTexture representing the frame that will be shown on the surface.
    * It is @ref ReturnedWithOwnership from @ref wgpuSurfaceGetCurrentTexture.
    */
    texture:     WGPUTexture;

    /**
    * Whether the call to `::wgpuSurfaceGetCurrentTexture` succeeded and a hint as to why it might not have.
    */
    status:      WGPUSurfaceGetCurrentTextureStatus;
}

WGPUTexelCopyBufferLayout :: struct {
    offset:       u64;
    bytesPerRow:  u32;
    rowsPerImage: u32;
}

WGPUTextureBindingLayout :: struct {
    nextInChain:   *WGPUChainedStruct;
    sampleType:    WGPUTextureSampleType;
    viewDimension: WGPUTextureViewDimension;
    multisampled:  WGPUBool;
}

WGPUTextureViewDescriptor :: struct {
    nextInChain:     *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:           WGPUStringView;
    format:          WGPUTextureFormat;
    dimension:       WGPUTextureViewDimension;
    baseMipLevel:    u32;
    mipLevelCount:   u32;
    baseArrayLayer:  u32;
    arrayLayerCount: u32;
    aspect:          WGPUTextureAspect;
    usage:           WGPUTextureUsage;
}

WGPUVertexAttribute :: struct {
    format:         WGPUVertexFormat;
    offset:         u64;
    shaderLocation: u32;
}

WGPUBindGroupDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:       WGPUStringView;
    layout:      WGPUBindGroupLayout;
    entryCount:  u64;
    entries:     *WGPUBindGroupEntry;
}

WGPUBindGroupLayoutEntry :: struct {
    nextInChain:    *WGPUChainedStruct;
    binding:        u32;
    visibility:     WGPUShaderStage;
    buffer:         WGPUBufferBindingLayout;
    sampler:        WGPUSamplerBindingLayout;
    texture:        WGPUTextureBindingLayout;
    storageTexture: WGPUStorageTextureBindingLayout;
}

WGPUBlendState :: struct {
    color: WGPUBlendComponent;
    alpha: WGPUBlendComponent;
}

WGPUCompilationInfo :: struct {
    nextInChain:  *WGPUChainedStruct;
    messageCount: u64;
    messages:     *WGPUCompilationMessage;
}

WGPUComputePassDescriptor :: struct {
    nextInChain:     *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:           WGPUStringView;
    timestampWrites: *WGPUComputePassTimestampWrites;
}

WGPUDepthStencilState :: struct {
    nextInChain:         *WGPUChainedStruct;
    format:              WGPUTextureFormat;
    depthWriteEnabled:   WGPUOptionalBool;
    depthCompare:        WGPUCompareFunction;
    stencilFront:        WGPUStencilFaceState;
    stencilBack:         WGPUStencilFaceState;
    stencilReadMask:     u32;
    stencilWriteMask:    u32;
    depthBias:           s32;
    depthBiasSlopeScale: float;
    depthBiasClamp:      float;
}

WGPUDeviceDescriptor :: struct {
    nextInChain:                 *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:                       WGPUStringView;
    requiredFeatureCount:        u64;
    requiredFeatures:            *WGPUFeatureName;
    requiredLimits:              *WGPULimits;
    defaultQueue:                WGPUQueueDescriptor;
    deviceLostCallbackInfo:      WGPUDeviceLostCallbackInfo;
    uncapturedErrorCallbackInfo: WGPUUncapturedErrorCallbackInfo;
}

/**
* Struct holding a future to wait on, and a `completed` boolean flag.
*/
WGPUFutureWaitInfo :: struct {
    /**
    * The future to wait on.
    */
    future:    WGPUFuture;

    /**
    * Whether or not the future completed.
    */
    completed: WGPUBool;
}

WGPUInstanceDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * Instance features to enable
    */
    features:    WGPUInstanceCapabilities;
}

WGPUProgrammableStageDescriptor :: struct {
    nextInChain:   *WGPUChainedStruct;
    module:        WGPUShaderModule;

    /**
    * This is a \ref NullableInputString.
    */
    entryPoint:    WGPUStringView;
    constantCount: u64;
    constants:     *WGPUConstantEntry;
}

WGPURenderPassColorAttachment :: struct {
    nextInChain:   *WGPUChainedStruct;
    view:          WGPUTextureView;
    depthSlice:    u32;
    resolveTarget: WGPUTextureView;
    loadOp:        WGPULoadOp;
    storeOp:       WGPUStoreOp;
    clearValue:    WGPUColor;
}

WGPUTexelCopyBufferInfo :: struct {
    layout: WGPUTexelCopyBufferLayout;
    buffer: WGPUBuffer;
}

WGPUTexelCopyTextureInfo :: struct {
    texture:  WGPUTexture;
    mipLevel: u32;
    origin:   WGPUOrigin3D;
    aspect:   WGPUTextureAspect;
}

WGPUTextureDescriptor :: struct {
    nextInChain:     *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:           WGPUStringView;
    usage:           WGPUTextureUsage;
    dimension:       WGPUTextureDimension;
    size:            WGPUExtent3D;
    format:          WGPUTextureFormat;
    mipLevelCount:   u32;
    sampleCount:     u32;
    viewFormatCount: u64;
    viewFormats:     *WGPUTextureFormat;
}

WGPUVertexBufferLayout :: struct {
    /**
    * The step mode for the vertex buffer. If @ref WGPUVertexStepMode_VertexBufferNotUsed,
    * indicates a "hole" in the parent @ref WGPUVertexState `buffers` array:
    * the pipeline does not use a vertex buffer at this `location`.
    */
    stepMode:       WGPUVertexStepMode;
    arrayStride:    u64;
    attributeCount: u64;
    attributes:     *WGPUVertexAttribute;
}

WGPUBindGroupLayoutDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:       WGPUStringView;
    entryCount:  u64;
    entries:     *WGPUBindGroupLayoutEntry;
}

WGPUColorTargetState :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * The texture format of the target. If @ref WGPUTextureFormat_Undefined,
    * indicates a "hole" in the parent @ref WGPUFragmentState `targets` array:
    * the pipeline does not output a value at this `location`.
    */
    format:      WGPUTextureFormat;
    blend:       *WGPUBlendState;
    writeMask:   WGPUColorWriteMask;
}

WGPUComputePipelineDescriptor :: struct {
    nextInChain: *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:       WGPUStringView;
    layout:      WGPUPipelineLayout;
    compute:     WGPUProgrammableStageDescriptor;
}

WGPURenderPassDescriptor :: struct {
    nextInChain:            *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:                  WGPUStringView;
    colorAttachmentCount:   u64;
    colorAttachments:       *WGPURenderPassColorAttachment;
    depthStencilAttachment: *WGPURenderPassDepthStencilAttachment;
    occlusionQuerySet:      WGPUQuerySet;
    timestampWrites:        *WGPURenderPassTimestampWrites;
}

WGPUVertexState :: struct {
    nextInChain:   *WGPUChainedStruct;
    module:        WGPUShaderModule;

    /**
    * This is a \ref NullableInputString.
    */
    entryPoint:    WGPUStringView;
    constantCount: u64;
    constants:     *WGPUConstantEntry;
    bufferCount:   u64;
    buffers:       *WGPUVertexBufferLayout;
}

WGPUFragmentState :: struct {
    nextInChain:   *WGPUChainedStruct;
    module:        WGPUShaderModule;

    /**
    * This is a \ref NullableInputString.
    */
    entryPoint:    WGPUStringView;
    constantCount: u64;
    constants:     *WGPUConstantEntry;
    targetCount:   u64;
    targets:       *WGPUColorTargetState;
}

WGPURenderPipelineDescriptor :: struct {
    nextInChain:  *WGPUChainedStruct;

    /**
    * This is a \ref NonNullInputString.
    */
    label:        WGPUStringView;
    layout:       WGPUPipelineLayout;
    vertex:       WGPUVertexState;
    primitive:    WGPUPrimitiveState;
    depthStencil: *WGPUDepthStencilState;
    multisample:  WGPUMultisampleState;
    fragment:     *WGPUFragmentState;
}

/**
* Proc pointer type for @ref wgpuCreateInstance:
* > @copydoc wgpuCreateInstance
*/
WGPUProcCreateInstance :: #type (descriptor: *WGPUInstanceDescriptor) -> WGPUInstance #c_call;

/**
* Proc pointer type for @ref wgpuGetInstanceCapabilities:
* > @copydoc wgpuGetInstanceCapabilities
*/
WGPUProcGetInstanceCapabilities :: #type (capabilities: *WGPUInstanceCapabilities) -> WGPUStatus #c_call;

/**
* Proc pointer type for @ref wgpuGetProcAddress:
* > @copydoc wgpuGetProcAddress
*/
WGPUProcGetProcAddress :: #type (procName: WGPUStringView) -> WGPUProc #c_call;

// Procs of Adapter
/**
* Proc pointer type for @ref wgpuAdapterGetFeatures:
* > @copydoc wgpuAdapterGetFeatures
*/
WGPUProcAdapterGetFeatures :: #type (adapter: WGPUAdapter, features: *WGPUSupportedFeatures) -> void #c_call;

/**
* Proc pointer type for @ref wgpuAdapterGetInfo:
* > @copydoc wgpuAdapterGetInfo
*/
WGPUProcAdapterGetInfo :: #type (adapter: WGPUAdapter, info: *WGPUAdapterInfo) -> WGPUStatus #c_call;

/**
* Proc pointer type for @ref wgpuAdapterGetLimits:
* > @copydoc wgpuAdapterGetLimits
*/
WGPUProcAdapterGetLimits :: #type (adapter: WGPUAdapter, limits: *WGPULimits) -> WGPUStatus #c_call;

/**
* Proc pointer type for @ref wgpuAdapterHasFeature:
* > @copydoc wgpuAdapterHasFeature
*/
WGPUProcAdapterHasFeature :: #type (adapter: WGPUAdapter, feature: WGPUFeatureName) -> WGPUBool #c_call;

/**
* Proc pointer type for @ref wgpuAdapterRequestDevice:
* > @copydoc wgpuAdapterRequestDevice
*/
WGPUProcAdapterRequestDevice :: #type (adapter: WGPUAdapter, descriptor: *WGPUDeviceDescriptor, callbackInfo: WGPURequestDeviceCallbackInfo) -> WGPUFuture #c_call;

/**
* Proc pointer type for @ref wgpuAdapterAddRef.
* > @copydoc wgpuAdapterAddRef
*/
WGPUProcAdapterAddRef :: #type (adapter: WGPUAdapter) -> void #c_call;

/**
* Proc pointer type for @ref wgpuAdapterRelease.
* > @copydoc wgpuAdapterRelease
*/
WGPUProcAdapterRelease :: #type (adapter: WGPUAdapter) -> void #c_call;

// Procs of AdapterInfo
/**
* Proc pointer type for @ref wgpuAdapterInfoFreeMembers:
* > @copydoc wgpuAdapterInfoFreeMembers
*/
WGPUProcAdapterInfoFreeMembers :: #type (adapterInfo: WGPUAdapterInfo) -> void #c_call;

// Procs of BindGroup
/**
* Proc pointer type for @ref wgpuBindGroupSetLabel:
* > @copydoc wgpuBindGroupSetLabel
*/
WGPUProcBindGroupSetLabel :: #type (bindGroup: WGPUBindGroup, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuBindGroupAddRef.
* > @copydoc wgpuBindGroupAddRef
*/
WGPUProcBindGroupAddRef :: #type (bindGroup: WGPUBindGroup) -> void #c_call;

/**
* Proc pointer type for @ref wgpuBindGroupRelease.
* > @copydoc wgpuBindGroupRelease
*/
WGPUProcBindGroupRelease :: #type (bindGroup: WGPUBindGroup) -> void #c_call;

// Procs of BindGroupLayout
/**
* Proc pointer type for @ref wgpuBindGroupLayoutSetLabel:
* > @copydoc wgpuBindGroupLayoutSetLabel
*/
WGPUProcBindGroupLayoutSetLabel :: #type (bindGroupLayout: WGPUBindGroupLayout, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuBindGroupLayoutAddRef.
* > @copydoc wgpuBindGroupLayoutAddRef
*/
WGPUProcBindGroupLayoutAddRef :: #type (bindGroupLayout: WGPUBindGroupLayout) -> void #c_call;

/**
* Proc pointer type for @ref wgpuBindGroupLayoutRelease.
* > @copydoc wgpuBindGroupLayoutRelease
*/
WGPUProcBindGroupLayoutRelease :: #type (bindGroupLayout: WGPUBindGroupLayout) -> void #c_call;

// Procs of Buffer
/**
* Proc pointer type for @ref wgpuBufferDestroy:
* > @copydoc wgpuBufferDestroy
*/
WGPUProcBufferDestroy :: #type (buffer: WGPUBuffer) -> void #c_call;

/**
* Proc pointer type for @ref wgpuBufferGetConstMappedRange:
* > @copydoc wgpuBufferGetConstMappedRange
*/
WGPUProcBufferGetConstMappedRange :: #type (buffer: WGPUBuffer, offset: u64, size: u64) -> *void #c_call;

/**
* Proc pointer type for @ref wgpuBufferGetMapState:
* > @copydoc wgpuBufferGetMapState
*/
WGPUProcBufferGetMapState :: #type (buffer: WGPUBuffer) -> WGPUBufferMapState #c_call;

/**
* Proc pointer type for @ref wgpuBufferGetMappedRange:
* > @copydoc wgpuBufferGetMappedRange
*/
WGPUProcBufferGetMappedRange :: #type (buffer: WGPUBuffer, offset: u64, size: u64) -> *void #c_call;

/**
* Proc pointer type for @ref wgpuBufferGetSize:
* > @copydoc wgpuBufferGetSize
*/
WGPUProcBufferGetSize :: #type (buffer: WGPUBuffer) -> u64 #c_call;

/**
* Proc pointer type for @ref wgpuBufferGetUsage:
* > @copydoc wgpuBufferGetUsage
*/
WGPUProcBufferGetUsage :: #type (buffer: WGPUBuffer) -> WGPUBufferUsage #c_call;

/**
* Proc pointer type for @ref wgpuBufferMapAsync:
* > @copydoc wgpuBufferMapAsync
*/
WGPUProcBufferMapAsync :: #type (buffer: WGPUBuffer, mode: WGPUMapMode, offset: u64, size: u64, callbackInfo: WGPUBufferMapCallbackInfo) -> WGPUFuture #c_call;

/**
* Proc pointer type for @ref wgpuBufferSetLabel:
* > @copydoc wgpuBufferSetLabel
*/
WGPUProcBufferSetLabel :: #type (buffer: WGPUBuffer, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuBufferUnmap:
* > @copydoc wgpuBufferUnmap
*/
WGPUProcBufferUnmap :: #type (buffer: WGPUBuffer) -> void #c_call;

/**
* Proc pointer type for @ref wgpuBufferAddRef.
* > @copydoc wgpuBufferAddRef
*/
WGPUProcBufferAddRef :: #type (buffer: WGPUBuffer) -> void #c_call;

/**
* Proc pointer type for @ref wgpuBufferRelease.
* > @copydoc wgpuBufferRelease
*/
WGPUProcBufferRelease :: #type (buffer: WGPUBuffer) -> void #c_call;

// Procs of CommandBuffer
/**
* Proc pointer type for @ref wgpuCommandBufferSetLabel:
* > @copydoc wgpuCommandBufferSetLabel
*/
WGPUProcCommandBufferSetLabel :: #type (commandBuffer: WGPUCommandBuffer, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandBufferAddRef.
* > @copydoc wgpuCommandBufferAddRef
*/
WGPUProcCommandBufferAddRef :: #type (commandBuffer: WGPUCommandBuffer) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandBufferRelease.
* > @copydoc wgpuCommandBufferRelease
*/
WGPUProcCommandBufferRelease :: #type (commandBuffer: WGPUCommandBuffer) -> void #c_call;

// Procs of CommandEncoder
/**
* Proc pointer type for @ref wgpuCommandEncoderBeginComputePass:
* > @copydoc wgpuCommandEncoderBeginComputePass
*/
WGPUProcCommandEncoderBeginComputePass :: #type (commandEncoder: WGPUCommandEncoder, descriptor: *WGPUComputePassDescriptor) -> WGPUComputePassEncoder #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderBeginRenderPass:
* > @copydoc wgpuCommandEncoderBeginRenderPass
*/
WGPUProcCommandEncoderBeginRenderPass :: #type (commandEncoder: WGPUCommandEncoder, descriptor: *WGPURenderPassDescriptor) -> WGPURenderPassEncoder #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderClearBuffer:
* > @copydoc wgpuCommandEncoderClearBuffer
*/
WGPUProcCommandEncoderClearBuffer :: #type (commandEncoder: WGPUCommandEncoder, buffer: WGPUBuffer, offset: u64, size: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderCopyBufferToBuffer:
* > @copydoc wgpuCommandEncoderCopyBufferToBuffer
*/
WGPUProcCommandEncoderCopyBufferToBuffer :: #type (commandEncoder: WGPUCommandEncoder, source: WGPUBuffer, sourceOffset: u64, destination: WGPUBuffer, destinationOffset: u64, size: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderCopyBufferToTexture:
* > @copydoc wgpuCommandEncoderCopyBufferToTexture
*/
WGPUProcCommandEncoderCopyBufferToTexture :: #type (commandEncoder: WGPUCommandEncoder, source: *WGPUTexelCopyBufferInfo, destination: *WGPUTexelCopyTextureInfo, copySize: *WGPUExtent3D) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderCopyTextureToBuffer:
* > @copydoc wgpuCommandEncoderCopyTextureToBuffer
*/
WGPUProcCommandEncoderCopyTextureToBuffer :: #type (commandEncoder: WGPUCommandEncoder, source: *WGPUTexelCopyTextureInfo, destination: *WGPUTexelCopyBufferInfo, copySize: *WGPUExtent3D) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderCopyTextureToTexture:
* > @copydoc wgpuCommandEncoderCopyTextureToTexture
*/
WGPUProcCommandEncoderCopyTextureToTexture :: #type (commandEncoder: WGPUCommandEncoder, source: *WGPUTexelCopyTextureInfo, destination: *WGPUTexelCopyTextureInfo, copySize: *WGPUExtent3D) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderFinish:
* > @copydoc wgpuCommandEncoderFinish
*/
WGPUProcCommandEncoderFinish :: #type (commandEncoder: WGPUCommandEncoder, descriptor: *WGPUCommandBufferDescriptor) -> WGPUCommandBuffer #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderInsertDebugMarker:
* > @copydoc wgpuCommandEncoderInsertDebugMarker
*/
WGPUProcCommandEncoderInsertDebugMarker :: #type (commandEncoder: WGPUCommandEncoder, markerLabel: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderPopDebugGroup:
* > @copydoc wgpuCommandEncoderPopDebugGroup
*/
WGPUProcCommandEncoderPopDebugGroup :: #type (commandEncoder: WGPUCommandEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderPushDebugGroup:
* > @copydoc wgpuCommandEncoderPushDebugGroup
*/
WGPUProcCommandEncoderPushDebugGroup :: #type (commandEncoder: WGPUCommandEncoder, groupLabel: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderResolveQuerySet:
* > @copydoc wgpuCommandEncoderResolveQuerySet
*/
WGPUProcCommandEncoderResolveQuerySet :: #type (commandEncoder: WGPUCommandEncoder, querySet: WGPUQuerySet, firstQuery: u32, queryCount: u32, destination: WGPUBuffer, destinationOffset: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderSetLabel:
* > @copydoc wgpuCommandEncoderSetLabel
*/
WGPUProcCommandEncoderSetLabel :: #type (commandEncoder: WGPUCommandEncoder, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderWriteTimestamp:
* > @copydoc wgpuCommandEncoderWriteTimestamp
*/
WGPUProcCommandEncoderWriteTimestamp :: #type (commandEncoder: WGPUCommandEncoder, querySet: WGPUQuerySet, queryIndex: u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderAddRef.
* > @copydoc wgpuCommandEncoderAddRef
*/
WGPUProcCommandEncoderAddRef :: #type (commandEncoder: WGPUCommandEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuCommandEncoderRelease.
* > @copydoc wgpuCommandEncoderRelease
*/
WGPUProcCommandEncoderRelease :: #type (commandEncoder: WGPUCommandEncoder) -> void #c_call;

// Procs of ComputePassEncoder
/**
* Proc pointer type for @ref wgpuComputePassEncoderDispatchWorkgroups:
* > @copydoc wgpuComputePassEncoderDispatchWorkgroups
*/
WGPUProcComputePassEncoderDispatchWorkgroups :: #type (computePassEncoder: WGPUComputePassEncoder, workgroupCountX: u32, workgroupCountY: u32, workgroupCountZ: u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePassEncoderDispatchWorkgroupsIndirect:
* > @copydoc wgpuComputePassEncoderDispatchWorkgroupsIndirect
*/
WGPUProcComputePassEncoderDispatchWorkgroupsIndirect :: #type (computePassEncoder: WGPUComputePassEncoder, indirectBuffer: WGPUBuffer, indirectOffset: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePassEncoderEnd:
* > @copydoc wgpuComputePassEncoderEnd
*/
WGPUProcComputePassEncoderEnd :: #type (computePassEncoder: WGPUComputePassEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePassEncoderInsertDebugMarker:
* > @copydoc wgpuComputePassEncoderInsertDebugMarker
*/
WGPUProcComputePassEncoderInsertDebugMarker :: #type (computePassEncoder: WGPUComputePassEncoder, markerLabel: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePassEncoderPopDebugGroup:
* > @copydoc wgpuComputePassEncoderPopDebugGroup
*/
WGPUProcComputePassEncoderPopDebugGroup :: #type (computePassEncoder: WGPUComputePassEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePassEncoderPushDebugGroup:
* > @copydoc wgpuComputePassEncoderPushDebugGroup
*/
WGPUProcComputePassEncoderPushDebugGroup :: #type (computePassEncoder: WGPUComputePassEncoder, groupLabel: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePassEncoderSetBindGroup:
* > @copydoc wgpuComputePassEncoderSetBindGroup
*/
WGPUProcComputePassEncoderSetBindGroup :: #type (computePassEncoder: WGPUComputePassEncoder, groupIndex: u32, group: WGPUBindGroup, dynamicOffsetCount: u64, dynamicOffsets: *u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePassEncoderSetLabel:
* > @copydoc wgpuComputePassEncoderSetLabel
*/
WGPUProcComputePassEncoderSetLabel :: #type (computePassEncoder: WGPUComputePassEncoder, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePassEncoderSetPipeline:
* > @copydoc wgpuComputePassEncoderSetPipeline
*/
WGPUProcComputePassEncoderSetPipeline :: #type (computePassEncoder: WGPUComputePassEncoder, pipeline: WGPUComputePipeline) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePassEncoderAddRef.
* > @copydoc wgpuComputePassEncoderAddRef
*/
WGPUProcComputePassEncoderAddRef :: #type (computePassEncoder: WGPUComputePassEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePassEncoderRelease.
* > @copydoc wgpuComputePassEncoderRelease
*/
WGPUProcComputePassEncoderRelease :: #type (computePassEncoder: WGPUComputePassEncoder) -> void #c_call;

// Procs of ComputePipeline
/**
* Proc pointer type for @ref wgpuComputePipelineGetBindGroupLayout:
* > @copydoc wgpuComputePipelineGetBindGroupLayout
*/
WGPUProcComputePipelineGetBindGroupLayout :: #type (computePipeline: WGPUComputePipeline, groupIndex: u32) -> WGPUBindGroupLayout #c_call;

/**
* Proc pointer type for @ref wgpuComputePipelineSetLabel:
* > @copydoc wgpuComputePipelineSetLabel
*/
WGPUProcComputePipelineSetLabel :: #type (computePipeline: WGPUComputePipeline, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePipelineAddRef.
* > @copydoc wgpuComputePipelineAddRef
*/
WGPUProcComputePipelineAddRef :: #type (computePipeline: WGPUComputePipeline) -> void #c_call;

/**
* Proc pointer type for @ref wgpuComputePipelineRelease.
* > @copydoc wgpuComputePipelineRelease
*/
WGPUProcComputePipelineRelease :: #type (computePipeline: WGPUComputePipeline) -> void #c_call;

// Procs of Device
/**
* Proc pointer type for @ref wgpuDeviceCreateBindGroup:
* > @copydoc wgpuDeviceCreateBindGroup
*/
WGPUProcDeviceCreateBindGroup :: #type (device: WGPUDevice, descriptor: *WGPUBindGroupDescriptor) -> WGPUBindGroup #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateBindGroupLayout:
* > @copydoc wgpuDeviceCreateBindGroupLayout
*/
WGPUProcDeviceCreateBindGroupLayout :: #type (device: WGPUDevice, descriptor: *WGPUBindGroupLayoutDescriptor) -> WGPUBindGroupLayout #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateBuffer:
* > @copydoc wgpuDeviceCreateBuffer
*/
WGPUProcDeviceCreateBuffer :: #type (device: WGPUDevice, descriptor: *WGPUBufferDescriptor) -> WGPUBuffer #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateCommandEncoder:
* > @copydoc wgpuDeviceCreateCommandEncoder
*/
WGPUProcDeviceCreateCommandEncoder :: #type (device: WGPUDevice, descriptor: *WGPUCommandEncoderDescriptor) -> WGPUCommandEncoder #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateComputePipeline:
* > @copydoc wgpuDeviceCreateComputePipeline
*/
WGPUProcDeviceCreateComputePipeline :: #type (device: WGPUDevice, descriptor: *WGPUComputePipelineDescriptor) -> WGPUComputePipeline #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateComputePipelineAsync:
* > @copydoc wgpuDeviceCreateComputePipelineAsync
*/
WGPUProcDeviceCreateComputePipelineAsync :: #type (device: WGPUDevice, descriptor: *WGPUComputePipelineDescriptor, callbackInfo: WGPUCreateComputePipelineAsyncCallbackInfo) -> WGPUFuture #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreatePipelineLayout:
* > @copydoc wgpuDeviceCreatePipelineLayout
*/
WGPUProcDeviceCreatePipelineLayout :: #type (device: WGPUDevice, descriptor: *WGPUPipelineLayoutDescriptor) -> WGPUPipelineLayout #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateQuerySet:
* > @copydoc wgpuDeviceCreateQuerySet
*/
WGPUProcDeviceCreateQuerySet :: #type (device: WGPUDevice, descriptor: *WGPUQuerySetDescriptor) -> WGPUQuerySet #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateRenderBundleEncoder:
* > @copydoc wgpuDeviceCreateRenderBundleEncoder
*/
WGPUProcDeviceCreateRenderBundleEncoder :: #type (device: WGPUDevice, descriptor: *WGPURenderBundleEncoderDescriptor) -> WGPURenderBundleEncoder #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateRenderPipeline:
* > @copydoc wgpuDeviceCreateRenderPipeline
*/
WGPUProcDeviceCreateRenderPipeline :: #type (device: WGPUDevice, descriptor: *WGPURenderPipelineDescriptor) -> WGPURenderPipeline #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateRenderPipelineAsync:
* > @copydoc wgpuDeviceCreateRenderPipelineAsync
*/
WGPUProcDeviceCreateRenderPipelineAsync :: #type (device: WGPUDevice, descriptor: *WGPURenderPipelineDescriptor, callbackInfo: WGPUCreateRenderPipelineAsyncCallbackInfo) -> WGPUFuture #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateSampler:
* > @copydoc wgpuDeviceCreateSampler
*/
WGPUProcDeviceCreateSampler :: #type (device: WGPUDevice, descriptor: *WGPUSamplerDescriptor) -> WGPUSampler #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateShaderModule:
* > @copydoc wgpuDeviceCreateShaderModule
*/
WGPUProcDeviceCreateShaderModule :: #type (device: WGPUDevice, descriptor: *WGPUShaderModuleDescriptor) -> WGPUShaderModule #c_call;

/**
* Proc pointer type for @ref wgpuDeviceCreateTexture:
* > @copydoc wgpuDeviceCreateTexture
*/
WGPUProcDeviceCreateTexture :: #type (device: WGPUDevice, descriptor: *WGPUTextureDescriptor) -> WGPUTexture #c_call;

/**
* Proc pointer type for @ref wgpuDeviceDestroy:
* > @copydoc wgpuDeviceDestroy
*/
WGPUProcDeviceDestroy :: #type (device: WGPUDevice) -> void #c_call;

/**
* Proc pointer type for @ref wgpuDeviceGetAdapterInfo:
* > @copydoc wgpuDeviceGetAdapterInfo
*/
WGPUProcDeviceGetAdapterInfo :: #type (device: WGPUDevice) -> WGPUAdapterInfo #c_call;

/**
* Proc pointer type for @ref wgpuDeviceGetFeatures:
* > @copydoc wgpuDeviceGetFeatures
*/
WGPUProcDeviceGetFeatures :: #type (device: WGPUDevice, features: *WGPUSupportedFeatures) -> void #c_call;

/**
* Proc pointer type for @ref wgpuDeviceGetLimits:
* > @copydoc wgpuDeviceGetLimits
*/
WGPUProcDeviceGetLimits :: #type (device: WGPUDevice, limits: *WGPULimits) -> WGPUStatus #c_call;

/**
* Proc pointer type for @ref wgpuDeviceGetLostFuture:
* > @copydoc wgpuDeviceGetLostFuture
*/
WGPUProcDeviceGetLostFuture :: #type (device: WGPUDevice) -> WGPUFuture #c_call;

/**
* Proc pointer type for @ref wgpuDeviceGetQueue:
* > @copydoc wgpuDeviceGetQueue
*/
WGPUProcDeviceGetQueue :: #type (device: WGPUDevice) -> WGPUQueue #c_call;

/**
* Proc pointer type for @ref wgpuDeviceHasFeature:
* > @copydoc wgpuDeviceHasFeature
*/
WGPUProcDeviceHasFeature :: #type (device: WGPUDevice, feature: WGPUFeatureName) -> WGPUBool #c_call;

/**
* Proc pointer type for @ref wgpuDevicePopErrorScope:
* > @copydoc wgpuDevicePopErrorScope
*/
WGPUProcDevicePopErrorScope :: #type (device: WGPUDevice, callbackInfo: WGPUPopErrorScopeCallbackInfo) -> WGPUFuture #c_call;

/**
* Proc pointer type for @ref wgpuDevicePushErrorScope:
* > @copydoc wgpuDevicePushErrorScope
*/
WGPUProcDevicePushErrorScope :: #type (device: WGPUDevice, filter: WGPUErrorFilter) -> void #c_call;

/**
* Proc pointer type for @ref wgpuDeviceSetLabel:
* > @copydoc wgpuDeviceSetLabel
*/
WGPUProcDeviceSetLabel :: #type (device: WGPUDevice, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuDeviceAddRef.
* > @copydoc wgpuDeviceAddRef
*/
WGPUProcDeviceAddRef :: #type (device: WGPUDevice) -> void #c_call;

/**
* Proc pointer type for @ref wgpuDeviceRelease.
* > @copydoc wgpuDeviceRelease
*/
WGPUProcDeviceRelease :: #type (device: WGPUDevice) -> void #c_call;

// Procs of Instance
/**
* Proc pointer type for @ref wgpuInstanceCreateSurface:
* > @copydoc wgpuInstanceCreateSurface
*/
WGPUProcInstanceCreateSurface :: #type (instance: WGPUInstance, descriptor: *WGPUSurfaceDescriptor) -> WGPUSurface #c_call;

/**
* Proc pointer type for @ref wgpuInstanceGetWGSLLanguageFeatures:
* > @copydoc wgpuInstanceGetWGSLLanguageFeatures
*/
WGPUProcInstanceGetWGSLLanguageFeatures :: #type (instance: WGPUInstance, features: *WGPUSupportedWGSLLanguageFeatures) -> WGPUStatus #c_call;

/**
* Proc pointer type for @ref wgpuInstanceHasWGSLLanguageFeature:
* > @copydoc wgpuInstanceHasWGSLLanguageFeature
*/
WGPUProcInstanceHasWGSLLanguageFeature :: #type (instance: WGPUInstance, feature: WGPUWGSLLanguageFeatureName) -> WGPUBool #c_call;

/**
* Proc pointer type for @ref wgpuInstanceProcessEvents:
* > @copydoc wgpuInstanceProcessEvents
*/
WGPUProcInstanceProcessEvents :: #type (instance: WGPUInstance) -> void #c_call;

/**
* Proc pointer type for @ref wgpuInstanceRequestAdapter:
* > @copydoc wgpuInstanceRequestAdapter
*/
WGPUProcInstanceRequestAdapter :: #type (instance: WGPUInstance, options: *WGPURequestAdapterOptions, callbackInfo: WGPURequestAdapterCallbackInfo) -> WGPUFuture #c_call;

/**
* Proc pointer type for @ref wgpuInstanceWaitAny:
* > @copydoc wgpuInstanceWaitAny
*/
WGPUProcInstanceWaitAny :: #type (instance: WGPUInstance, futureCount: u64, futures: *WGPUFutureWaitInfo, timeoutNS: u64) -> WGPUWaitStatus #c_call;

/**
* Proc pointer type for @ref wgpuInstanceAddRef.
* > @copydoc wgpuInstanceAddRef
*/
WGPUProcInstanceAddRef :: #type (instance: WGPUInstance) -> void #c_call;

/**
* Proc pointer type for @ref wgpuInstanceRelease.
* > @copydoc wgpuInstanceRelease
*/
WGPUProcInstanceRelease :: #type (instance: WGPUInstance) -> void #c_call;

// Procs of PipelineLayout
/**
* Proc pointer type for @ref wgpuPipelineLayoutSetLabel:
* > @copydoc wgpuPipelineLayoutSetLabel
*/
WGPUProcPipelineLayoutSetLabel :: #type (pipelineLayout: WGPUPipelineLayout, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuPipelineLayoutAddRef.
* > @copydoc wgpuPipelineLayoutAddRef
*/
WGPUProcPipelineLayoutAddRef :: #type (pipelineLayout: WGPUPipelineLayout) -> void #c_call;

/**
* Proc pointer type for @ref wgpuPipelineLayoutRelease.
* > @copydoc wgpuPipelineLayoutRelease
*/
WGPUProcPipelineLayoutRelease :: #type (pipelineLayout: WGPUPipelineLayout) -> void #c_call;

// Procs of QuerySet
/**
* Proc pointer type for @ref wgpuQuerySetDestroy:
* > @copydoc wgpuQuerySetDestroy
*/
WGPUProcQuerySetDestroy :: #type (querySet: WGPUQuerySet) -> void #c_call;

/**
* Proc pointer type for @ref wgpuQuerySetGetCount:
* > @copydoc wgpuQuerySetGetCount
*/
WGPUProcQuerySetGetCount :: #type (querySet: WGPUQuerySet) -> u32 #c_call;

/**
* Proc pointer type for @ref wgpuQuerySetGetType:
* > @copydoc wgpuQuerySetGetType
*/
WGPUProcQuerySetGetType :: #type (querySet: WGPUQuerySet) -> WGPUQueryType #c_call;

/**
* Proc pointer type for @ref wgpuQuerySetSetLabel:
* > @copydoc wgpuQuerySetSetLabel
*/
WGPUProcQuerySetSetLabel :: #type (querySet: WGPUQuerySet, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuQuerySetAddRef.
* > @copydoc wgpuQuerySetAddRef
*/
WGPUProcQuerySetAddRef :: #type (querySet: WGPUQuerySet) -> void #c_call;

/**
* Proc pointer type for @ref wgpuQuerySetRelease.
* > @copydoc wgpuQuerySetRelease
*/
WGPUProcQuerySetRelease :: #type (querySet: WGPUQuerySet) -> void #c_call;

// Procs of Queue
/**
* Proc pointer type for @ref wgpuQueueOnSubmittedWorkDone:
* > @copydoc wgpuQueueOnSubmittedWorkDone
*/
WGPUProcQueueOnSubmittedWorkDone :: #type (queue: WGPUQueue, callbackInfo: WGPUQueueWorkDoneCallbackInfo) -> WGPUFuture #c_call;

/**
* Proc pointer type for @ref wgpuQueueSetLabel:
* > @copydoc wgpuQueueSetLabel
*/
WGPUProcQueueSetLabel :: #type (queue: WGPUQueue, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuQueueSubmit:
* > @copydoc wgpuQueueSubmit
*/
WGPUProcQueueSubmit :: #type (queue: WGPUQueue, commandCount: u64, commands: *WGPUCommandBuffer) -> void #c_call;

/**
* Proc pointer type for @ref wgpuQueueWriteBuffer:
* > @copydoc wgpuQueueWriteBuffer
*/
WGPUProcQueueWriteBuffer :: #type (queue: WGPUQueue, buffer: WGPUBuffer, bufferOffset: u64, data: *void, size: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuQueueWriteTexture:
* > @copydoc wgpuQueueWriteTexture
*/
WGPUProcQueueWriteTexture :: #type (queue: WGPUQueue, destination: *WGPUTexelCopyTextureInfo, data: *void, dataSize: u64, dataLayout: *WGPUTexelCopyBufferLayout, writeSize: *WGPUExtent3D) -> void #c_call;

/**
* Proc pointer type for @ref wgpuQueueAddRef.
* > @copydoc wgpuQueueAddRef
*/
WGPUProcQueueAddRef :: #type (queue: WGPUQueue) -> void #c_call;

/**
* Proc pointer type for @ref wgpuQueueRelease.
* > @copydoc wgpuQueueRelease
*/
WGPUProcQueueRelease :: #type (queue: WGPUQueue) -> void #c_call;

// Procs of RenderBundle
/**
* Proc pointer type for @ref wgpuRenderBundleSetLabel:
* > @copydoc wgpuRenderBundleSetLabel
*/
WGPUProcRenderBundleSetLabel :: #type (renderBundle: WGPURenderBundle, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleAddRef.
* > @copydoc wgpuRenderBundleAddRef
*/
WGPUProcRenderBundleAddRef :: #type (renderBundle: WGPURenderBundle) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleRelease.
* > @copydoc wgpuRenderBundleRelease
*/
WGPUProcRenderBundleRelease :: #type (renderBundle: WGPURenderBundle) -> void #c_call;

// Procs of RenderBundleEncoder
/**
* Proc pointer type for @ref wgpuRenderBundleEncoderDraw:
* > @copydoc wgpuRenderBundleEncoderDraw
*/
WGPUProcRenderBundleEncoderDraw :: #type (renderBundleEncoder: WGPURenderBundleEncoder, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderDrawIndexed:
* > @copydoc wgpuRenderBundleEncoderDrawIndexed
*/
WGPUProcRenderBundleEncoderDrawIndexed :: #type (renderBundleEncoder: WGPURenderBundleEncoder, indexCount: u32, instanceCount: u32, firstIndex: u32, baseVertex: s32, firstInstance: u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderDrawIndexedIndirect:
* > @copydoc wgpuRenderBundleEncoderDrawIndexedIndirect
*/
WGPUProcRenderBundleEncoderDrawIndexedIndirect :: #type (renderBundleEncoder: WGPURenderBundleEncoder, indirectBuffer: WGPUBuffer, indirectOffset: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderDrawIndirect:
* > @copydoc wgpuRenderBundleEncoderDrawIndirect
*/
WGPUProcRenderBundleEncoderDrawIndirect :: #type (renderBundleEncoder: WGPURenderBundleEncoder, indirectBuffer: WGPUBuffer, indirectOffset: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderFinish:
* > @copydoc wgpuRenderBundleEncoderFinish
*/
WGPUProcRenderBundleEncoderFinish :: #type (renderBundleEncoder: WGPURenderBundleEncoder, descriptor: *WGPURenderBundleDescriptor) -> WGPURenderBundle #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderInsertDebugMarker:
* > @copydoc wgpuRenderBundleEncoderInsertDebugMarker
*/
WGPUProcRenderBundleEncoderInsertDebugMarker :: #type (renderBundleEncoder: WGPURenderBundleEncoder, markerLabel: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderPopDebugGroup:
* > @copydoc wgpuRenderBundleEncoderPopDebugGroup
*/
WGPUProcRenderBundleEncoderPopDebugGroup :: #type (renderBundleEncoder: WGPURenderBundleEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderPushDebugGroup:
* > @copydoc wgpuRenderBundleEncoderPushDebugGroup
*/
WGPUProcRenderBundleEncoderPushDebugGroup :: #type (renderBundleEncoder: WGPURenderBundleEncoder, groupLabel: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderSetBindGroup:
* > @copydoc wgpuRenderBundleEncoderSetBindGroup
*/
WGPUProcRenderBundleEncoderSetBindGroup :: #type (renderBundleEncoder: WGPURenderBundleEncoder, groupIndex: u32, group: WGPUBindGroup, dynamicOffsetCount: u64, dynamicOffsets: *u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderSetIndexBuffer:
* > @copydoc wgpuRenderBundleEncoderSetIndexBuffer
*/
WGPUProcRenderBundleEncoderSetIndexBuffer :: #type (renderBundleEncoder: WGPURenderBundleEncoder, buffer: WGPUBuffer, format: WGPUIndexFormat, offset: u64, size: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderSetLabel:
* > @copydoc wgpuRenderBundleEncoderSetLabel
*/
WGPUProcRenderBundleEncoderSetLabel :: #type (renderBundleEncoder: WGPURenderBundleEncoder, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderSetPipeline:
* > @copydoc wgpuRenderBundleEncoderSetPipeline
*/
WGPUProcRenderBundleEncoderSetPipeline :: #type (renderBundleEncoder: WGPURenderBundleEncoder, pipeline: WGPURenderPipeline) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderSetVertexBuffer:
* > @copydoc wgpuRenderBundleEncoderSetVertexBuffer
*/
WGPUProcRenderBundleEncoderSetVertexBuffer :: #type (renderBundleEncoder: WGPURenderBundleEncoder, slot: u32, buffer: WGPUBuffer, offset: u64, size: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderAddRef.
* > @copydoc wgpuRenderBundleEncoderAddRef
*/
WGPUProcRenderBundleEncoderAddRef :: #type (renderBundleEncoder: WGPURenderBundleEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderBundleEncoderRelease.
* > @copydoc wgpuRenderBundleEncoderRelease
*/
WGPUProcRenderBundleEncoderRelease :: #type (renderBundleEncoder: WGPURenderBundleEncoder) -> void #c_call;

// Procs of RenderPassEncoder
/**
* Proc pointer type for @ref wgpuRenderPassEncoderBeginOcclusionQuery:
* > @copydoc wgpuRenderPassEncoderBeginOcclusionQuery
*/
WGPUProcRenderPassEncoderBeginOcclusionQuery :: #type (renderPassEncoder: WGPURenderPassEncoder, queryIndex: u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderDraw:
* > @copydoc wgpuRenderPassEncoderDraw
*/
WGPUProcRenderPassEncoderDraw :: #type (renderPassEncoder: WGPURenderPassEncoder, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderDrawIndexed:
* > @copydoc wgpuRenderPassEncoderDrawIndexed
*/
WGPUProcRenderPassEncoderDrawIndexed :: #type (renderPassEncoder: WGPURenderPassEncoder, indexCount: u32, instanceCount: u32, firstIndex: u32, baseVertex: s32, firstInstance: u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderDrawIndexedIndirect:
* > @copydoc wgpuRenderPassEncoderDrawIndexedIndirect
*/
WGPUProcRenderPassEncoderDrawIndexedIndirect :: #type (renderPassEncoder: WGPURenderPassEncoder, indirectBuffer: WGPUBuffer, indirectOffset: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderDrawIndirect:
* > @copydoc wgpuRenderPassEncoderDrawIndirect
*/
WGPUProcRenderPassEncoderDrawIndirect :: #type (renderPassEncoder: WGPURenderPassEncoder, indirectBuffer: WGPUBuffer, indirectOffset: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderEnd:
* > @copydoc wgpuRenderPassEncoderEnd
*/
WGPUProcRenderPassEncoderEnd :: #type (renderPassEncoder: WGPURenderPassEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderEndOcclusionQuery:
* > @copydoc wgpuRenderPassEncoderEndOcclusionQuery
*/
WGPUProcRenderPassEncoderEndOcclusionQuery :: #type (renderPassEncoder: WGPURenderPassEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderExecuteBundles:
* > @copydoc wgpuRenderPassEncoderExecuteBundles
*/
WGPUProcRenderPassEncoderExecuteBundles :: #type (renderPassEncoder: WGPURenderPassEncoder, bundleCount: u64, bundles: *WGPURenderBundle) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderInsertDebugMarker:
* > @copydoc wgpuRenderPassEncoderInsertDebugMarker
*/
WGPUProcRenderPassEncoderInsertDebugMarker :: #type (renderPassEncoder: WGPURenderPassEncoder, markerLabel: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderPopDebugGroup:
* > @copydoc wgpuRenderPassEncoderPopDebugGroup
*/
WGPUProcRenderPassEncoderPopDebugGroup :: #type (renderPassEncoder: WGPURenderPassEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderPushDebugGroup:
* > @copydoc wgpuRenderPassEncoderPushDebugGroup
*/
WGPUProcRenderPassEncoderPushDebugGroup :: #type (renderPassEncoder: WGPURenderPassEncoder, groupLabel: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderSetBindGroup:
* > @copydoc wgpuRenderPassEncoderSetBindGroup
*/
WGPUProcRenderPassEncoderSetBindGroup :: #type (renderPassEncoder: WGPURenderPassEncoder, groupIndex: u32, group: WGPUBindGroup, dynamicOffsetCount: u64, dynamicOffsets: *u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderSetBlendConstant:
* > @copydoc wgpuRenderPassEncoderSetBlendConstant
*/
WGPUProcRenderPassEncoderSetBlendConstant :: #type (renderPassEncoder: WGPURenderPassEncoder, color: *WGPUColor) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderSetIndexBuffer:
* > @copydoc wgpuRenderPassEncoderSetIndexBuffer
*/
WGPUProcRenderPassEncoderSetIndexBuffer :: #type (renderPassEncoder: WGPURenderPassEncoder, buffer: WGPUBuffer, format: WGPUIndexFormat, offset: u64, size: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderSetLabel:
* > @copydoc wgpuRenderPassEncoderSetLabel
*/
WGPUProcRenderPassEncoderSetLabel :: #type (renderPassEncoder: WGPURenderPassEncoder, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderSetPipeline:
* > @copydoc wgpuRenderPassEncoderSetPipeline
*/
WGPUProcRenderPassEncoderSetPipeline :: #type (renderPassEncoder: WGPURenderPassEncoder, pipeline: WGPURenderPipeline) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderSetScissorRect:
* > @copydoc wgpuRenderPassEncoderSetScissorRect
*/
WGPUProcRenderPassEncoderSetScissorRect :: #type (renderPassEncoder: WGPURenderPassEncoder, x: u32, y: u32, width: u32, height: u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderSetStencilReference:
* > @copydoc wgpuRenderPassEncoderSetStencilReference
*/
WGPUProcRenderPassEncoderSetStencilReference :: #type (renderPassEncoder: WGPURenderPassEncoder, reference: u32) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderSetVertexBuffer:
* > @copydoc wgpuRenderPassEncoderSetVertexBuffer
*/
WGPUProcRenderPassEncoderSetVertexBuffer :: #type (renderPassEncoder: WGPURenderPassEncoder, slot: u32, buffer: WGPUBuffer, offset: u64, size: u64) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderSetViewport:
* > @copydoc wgpuRenderPassEncoderSetViewport
*/
WGPUProcRenderPassEncoderSetViewport :: #type (renderPassEncoder: WGPURenderPassEncoder, x: float, y: float, width: float, height: float, minDepth: float, maxDepth: float) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderAddRef.
* > @copydoc wgpuRenderPassEncoderAddRef
*/
WGPUProcRenderPassEncoderAddRef :: #type (renderPassEncoder: WGPURenderPassEncoder) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPassEncoderRelease.
* > @copydoc wgpuRenderPassEncoderRelease
*/
WGPUProcRenderPassEncoderRelease :: #type (renderPassEncoder: WGPURenderPassEncoder) -> void #c_call;

// Procs of RenderPipeline
/**
* Proc pointer type for @ref wgpuRenderPipelineGetBindGroupLayout:
* > @copydoc wgpuRenderPipelineGetBindGroupLayout
*/
WGPUProcRenderPipelineGetBindGroupLayout :: #type (renderPipeline: WGPURenderPipeline, groupIndex: u32) -> WGPUBindGroupLayout #c_call;

/**
* Proc pointer type for @ref wgpuRenderPipelineSetLabel:
* > @copydoc wgpuRenderPipelineSetLabel
*/
WGPUProcRenderPipelineSetLabel :: #type (renderPipeline: WGPURenderPipeline, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPipelineAddRef.
* > @copydoc wgpuRenderPipelineAddRef
*/
WGPUProcRenderPipelineAddRef :: #type (renderPipeline: WGPURenderPipeline) -> void #c_call;

/**
* Proc pointer type for @ref wgpuRenderPipelineRelease.
* > @copydoc wgpuRenderPipelineRelease
*/
WGPUProcRenderPipelineRelease :: #type (renderPipeline: WGPURenderPipeline) -> void #c_call;

// Procs of Sampler
/**
* Proc pointer type for @ref wgpuSamplerSetLabel:
* > @copydoc wgpuSamplerSetLabel
*/
WGPUProcSamplerSetLabel :: #type (sampler: WGPUSampler, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuSamplerAddRef.
* > @copydoc wgpuSamplerAddRef
*/
WGPUProcSamplerAddRef :: #type (sampler: WGPUSampler) -> void #c_call;

/**
* Proc pointer type for @ref wgpuSamplerRelease.
* > @copydoc wgpuSamplerRelease
*/
WGPUProcSamplerRelease :: #type (sampler: WGPUSampler) -> void #c_call;

// Procs of ShaderModule
/**
* Proc pointer type for @ref wgpuShaderModuleGetCompilationInfo:
* > @copydoc wgpuShaderModuleGetCompilationInfo
*/
WGPUProcShaderModuleGetCompilationInfo :: #type (shaderModule: WGPUShaderModule, callbackInfo: WGPUCompilationInfoCallbackInfo) -> WGPUFuture #c_call;

/**
* Proc pointer type for @ref wgpuShaderModuleSetLabel:
* > @copydoc wgpuShaderModuleSetLabel
*/
WGPUProcShaderModuleSetLabel :: #type (shaderModule: WGPUShaderModule, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuShaderModuleAddRef.
* > @copydoc wgpuShaderModuleAddRef
*/
WGPUProcShaderModuleAddRef :: #type (shaderModule: WGPUShaderModule) -> void #c_call;

/**
* Proc pointer type for @ref wgpuShaderModuleRelease.
* > @copydoc wgpuShaderModuleRelease
*/
WGPUProcShaderModuleRelease :: #type (shaderModule: WGPUShaderModule) -> void #c_call;

// Procs of SupportedFeatures
/**
* Proc pointer type for @ref wgpuSupportedFeaturesFreeMembers:
* > @copydoc wgpuSupportedFeaturesFreeMembers
*/
WGPUProcSupportedFeaturesFreeMembers :: #type (supportedFeatures: WGPUSupportedFeatures) -> void #c_call;

// Procs of SupportedWGSLLanguageFeatures
/**
* Proc pointer type for @ref wgpuSupportedWGSLLanguageFeaturesFreeMembers:
* > @copydoc wgpuSupportedWGSLLanguageFeaturesFreeMembers
*/
WGPUProcSupportedWGSLLanguageFeaturesFreeMembers :: #type (supportedWGSLLanguageFeatures: WGPUSupportedWGSLLanguageFeatures) -> void #c_call;

// Procs of Surface
/**
* Proc pointer type for @ref wgpuSurfaceConfigure:
* > @copydoc wgpuSurfaceConfigure
*/
WGPUProcSurfaceConfigure :: #type (surface: WGPUSurface, config: *WGPUSurfaceConfiguration) -> void #c_call;

/**
* Proc pointer type for @ref wgpuSurfaceGetCapabilities:
* > @copydoc wgpuSurfaceGetCapabilities
*/
WGPUProcSurfaceGetCapabilities :: #type (surface: WGPUSurface, adapter: WGPUAdapter, capabilities: *WGPUSurfaceCapabilities) -> WGPUStatus #c_call;

/**
* Proc pointer type for @ref wgpuSurfaceGetCurrentTexture:
* > @copydoc wgpuSurfaceGetCurrentTexture
*/
WGPUProcSurfaceGetCurrentTexture :: #type (surface: WGPUSurface, surfaceTexture: *WGPUSurfaceTexture) -> void #c_call;

/**
* Proc pointer type for @ref wgpuSurfacePresent:
* > @copydoc wgpuSurfacePresent
*/
WGPUProcSurfacePresent :: #type (surface: WGPUSurface) -> WGPUStatus #c_call;

/**
* Proc pointer type for @ref wgpuSurfaceSetLabel:
* > @copydoc wgpuSurfaceSetLabel
*/
WGPUProcSurfaceSetLabel :: #type (surface: WGPUSurface, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuSurfaceUnconfigure:
* > @copydoc wgpuSurfaceUnconfigure
*/
WGPUProcSurfaceUnconfigure :: #type (surface: WGPUSurface) -> void #c_call;

/**
* Proc pointer type for @ref wgpuSurfaceAddRef.
* > @copydoc wgpuSurfaceAddRef
*/
WGPUProcSurfaceAddRef :: #type (surface: WGPUSurface) -> void #c_call;

/**
* Proc pointer type for @ref wgpuSurfaceRelease.
* > @copydoc wgpuSurfaceRelease
*/
WGPUProcSurfaceRelease :: #type (surface: WGPUSurface) -> void #c_call;

// Procs of SurfaceCapabilities
/**
* Proc pointer type for @ref wgpuSurfaceCapabilitiesFreeMembers:
* > @copydoc wgpuSurfaceCapabilitiesFreeMembers
*/
WGPUProcSurfaceCapabilitiesFreeMembers :: #type (surfaceCapabilities: WGPUSurfaceCapabilities) -> void #c_call;

// Procs of Texture
/**
* Proc pointer type for @ref wgpuTextureCreateView:
* > @copydoc wgpuTextureCreateView
*/
WGPUProcTextureCreateView :: #type (texture: WGPUTexture, descriptor: *WGPUTextureViewDescriptor) -> WGPUTextureView #c_call;

/**
* Proc pointer type for @ref wgpuTextureDestroy:
* > @copydoc wgpuTextureDestroy
*/
WGPUProcTextureDestroy :: #type (texture: WGPUTexture) -> void #c_call;

/**
* Proc pointer type for @ref wgpuTextureGetDepthOrArrayLayers:
* > @copydoc wgpuTextureGetDepthOrArrayLayers
*/
WGPUProcTextureGetDepthOrArrayLayers :: #type (texture: WGPUTexture) -> u32 #c_call;

/**
* Proc pointer type for @ref wgpuTextureGetDimension:
* > @copydoc wgpuTextureGetDimension
*/
WGPUProcTextureGetDimension :: #type (texture: WGPUTexture) -> WGPUTextureDimension #c_call;

/**
* Proc pointer type for @ref wgpuTextureGetFormat:
* > @copydoc wgpuTextureGetFormat
*/
WGPUProcTextureGetFormat :: #type (texture: WGPUTexture) -> WGPUTextureFormat #c_call;

/**
* Proc pointer type for @ref wgpuTextureGetHeight:
* > @copydoc wgpuTextureGetHeight
*/
WGPUProcTextureGetHeight :: #type (texture: WGPUTexture) -> u32 #c_call;

/**
* Proc pointer type for @ref wgpuTextureGetMipLevelCount:
* > @copydoc wgpuTextureGetMipLevelCount
*/
WGPUProcTextureGetMipLevelCount :: #type (texture: WGPUTexture) -> u32 #c_call;

/**
* Proc pointer type for @ref wgpuTextureGetSampleCount:
* > @copydoc wgpuTextureGetSampleCount
*/
WGPUProcTextureGetSampleCount :: #type (texture: WGPUTexture) -> u32 #c_call;

/**
* Proc pointer type for @ref wgpuTextureGetUsage:
* > @copydoc wgpuTextureGetUsage
*/
WGPUProcTextureGetUsage :: #type (texture: WGPUTexture) -> WGPUTextureUsage #c_call;

/**
* Proc pointer type for @ref wgpuTextureGetWidth:
* > @copydoc wgpuTextureGetWidth
*/
WGPUProcTextureGetWidth :: #type (texture: WGPUTexture) -> u32 #c_call;

/**
* Proc pointer type for @ref wgpuTextureSetLabel:
* > @copydoc wgpuTextureSetLabel
*/
WGPUProcTextureSetLabel :: #type (texture: WGPUTexture, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuTextureAddRef.
* > @copydoc wgpuTextureAddRef
*/
WGPUProcTextureAddRef :: #type (texture: WGPUTexture) -> void #c_call;

/**
* Proc pointer type for @ref wgpuTextureRelease.
* > @copydoc wgpuTextureRelease
*/
WGPUProcTextureRelease :: #type (texture: WGPUTexture) -> void #c_call;

// Procs of TextureView
/**
* Proc pointer type for @ref wgpuTextureViewSetLabel:
* > @copydoc wgpuTextureViewSetLabel
*/
WGPUProcTextureViewSetLabel :: #type (textureView: WGPUTextureView, label: WGPUStringView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuTextureViewAddRef.
* > @copydoc wgpuTextureViewAddRef
*/
WGPUProcTextureViewAddRef :: #type (textureView: WGPUTextureView) -> void #c_call;

/**
* Proc pointer type for @ref wgpuTextureViewRelease.
* > @copydoc wgpuTextureViewRelease
*/
WGPUProcTextureViewRelease :: #type (textureView: WGPUTextureView) -> void #c_call;

WGPUNativeSType :: enum s32 {
    WGPUSType_DeviceExtras               :: 196609;
    WGPUSType_NativeLimits               :: 196610;
    WGPUSType_PipelineLayoutExtras       :: 196611;
    WGPUSType_ShaderSourceGLSL           :: 196612;
    WGPUSType_InstanceExtras             :: 196614;
    WGPUSType_BindGroupEntryExtras       :: 196615;
    WGPUSType_BindGroupLayoutEntryExtras :: 196616;
    WGPUSType_QuerySetDescriptorExtras   :: 196617;
    WGPUSType_SurfaceConfigurationExtras :: 196618;
    Force32                              :: 2147483647;
    WGPUNativeSType_Force32 :: Force32;
}

WGPUNativeFeature :: enum s32 {
    PushConstants                                         :: 196609;
    TextureAdapterSpecificFormatFeatures                  :: 196610;
    MultiDrawIndirect                                     :: 196611;
    MultiDrawIndirectCount                                :: 196612;
    VertexWritableStorage                                 :: 196613;
    TextureBindingArray                                   :: 196614;
    SampledTextureAndStorageBufferArrayNonUniformIndexing :: 196615;
    PipelineStatisticsQuery                               :: 196616;
    StorageResourceBindingArray                           :: 196617;
    PartiallyBoundBindingArray                            :: 196618;
    TextureFormat16bitNorm                                :: 196619;
    TextureCompressionAstcHdr                             :: 196620;
    MappablePrimaryBuffers                                :: 196622;
    BufferBindingArray                                    :: 196623;
    UniformBufferAndStorageTextureArrayNonUniformIndexing :: 196624;

    SpirvShaderPassthrough                                :: 196631;

    VertexAttribute64bit                                  :: 196633;
    TextureFormatNv12                                     :: 196634;
    RayTracingAccelerationStructure                       :: 196635;
    RayQuery                                              :: 196636;
    ShaderF64                                             :: 196637;
    ShaderI16                                             :: 196638;
    ShaderPrimitiveIndex                                  :: 196639;
    ShaderEarlyDepthTest                                  :: 196640;
    Subgroup                                              :: 196641;
    SubgroupVertex                                        :: 196642;
    SubgroupBarrier                                       :: 196643;
    TimestampQueryInsideEncoders                          :: 196644;
    TimestampQueryInsidePasses                            :: 196645;
    Force32                                               :: 2147483647;

    WGPUNativeFeature_PushConstants                                         :: PushConstants;
    WGPUNativeFeature_TextureAdapterSpecificFormatFeatures                  :: TextureAdapterSpecificFormatFeatures;
    WGPUNativeFeature_MultiDrawIndirect                                     :: MultiDrawIndirect;
    WGPUNativeFeature_MultiDrawIndirectCount                                :: MultiDrawIndirectCount;
    WGPUNativeFeature_VertexWritableStorage                                 :: VertexWritableStorage;
    WGPUNativeFeature_TextureBindingArray                                   :: TextureBindingArray;
    WGPUNativeFeature_SampledTextureAndStorageBufferArrayNonUniformIndexing :: SampledTextureAndStorageBufferArrayNonUniformIndexing;
    WGPUNativeFeature_PipelineStatisticsQuery                               :: PipelineStatisticsQuery;
    WGPUNativeFeature_StorageResourceBindingArray                           :: StorageResourceBindingArray;
    WGPUNativeFeature_PartiallyBoundBindingArray                            :: PartiallyBoundBindingArray;
    WGPUNativeFeature_TextureFormat16bitNorm                                :: TextureFormat16bitNorm;
    WGPUNativeFeature_TextureCompressionAstcHdr                             :: TextureCompressionAstcHdr;
    WGPUNativeFeature_MappablePrimaryBuffers                                :: MappablePrimaryBuffers;
    WGPUNativeFeature_BufferBindingArray                                    :: BufferBindingArray;
    WGPUNativeFeature_UniformBufferAndStorageTextureArrayNonUniformIndexing :: UniformBufferAndStorageTextureArrayNonUniformIndexing;

    WGPUNativeFeature_SpirvShaderPassthrough                                :: SpirvShaderPassthrough;

    WGPUNativeFeature_VertexAttribute64bit                                  :: VertexAttribute64bit;
    WGPUNativeFeature_TextureFormatNv12                                     :: TextureFormatNv12;
    WGPUNativeFeature_RayTracingAccelerationStructure                       :: RayTracingAccelerationStructure;
    WGPUNativeFeature_RayQuery                                              :: RayQuery;
    WGPUNativeFeature_ShaderF64                                             :: ShaderF64;
    WGPUNativeFeature_ShaderI16                                             :: ShaderI16;
    WGPUNativeFeature_ShaderPrimitiveIndex                                  :: ShaderPrimitiveIndex;
    WGPUNativeFeature_ShaderEarlyDepthTest                                  :: ShaderEarlyDepthTest;
    WGPUNativeFeature_Subgroup                                              :: Subgroup;
    WGPUNativeFeature_SubgroupVertex                                        :: SubgroupVertex;
    WGPUNativeFeature_SubgroupBarrier                                       :: SubgroupBarrier;
    WGPUNativeFeature_TimestampQueryInsideEncoders                          :: TimestampQueryInsideEncoders;
    WGPUNativeFeature_TimestampQueryInsidePasses                            :: TimestampQueryInsidePasses;
    WGPUNativeFeature_Force32                                               :: Force32;
}

WGPULogLevel :: enum s32 {
    Off     :: 0;
    Error   :: 1;
    Warn    :: 2;
    Info    :: 3;
    Debug   :: 4;
    Trace   :: 5;
    Force32 :: 2147483647;

    WGPULogLevel_Off     :: Off;
    WGPULogLevel_Error   :: Error;
    WGPULogLevel_Warn    :: Warn;
    WGPULogLevel_Info    :: Info;
    WGPULogLevel_Debug   :: Debug;
    WGPULogLevel_Trace   :: Trace;
    WGPULogLevel_Force32 :: Force32;
}

WGPUInstanceBackend :: WGPUFlags;
WGPUInstanceBackend_All: WGPUInstanceBackend : 0;
WGPUInstanceBackend_Vulkan: WGPUInstanceBackend : 1 << 0;
WGPUInstanceBackend_GL: WGPUInstanceBackend : 1 << 1;
WGPUInstanceBackend_Metal: WGPUInstanceBackend : 1 << 2;
WGPUInstanceBackend_DX12: WGPUInstanceBackend : 1 << 3;
WGPUInstanceBackend_DX11: WGPUInstanceBackend : 1 << 4;
WGPUInstanceBackend_BrowserWebGPU: WGPUInstanceBackend : 1 << 5;

// Vulkan, Metal, DX12 and BrowserWebGPU
WGPUInstanceBackend_Primary: WGPUInstanceBackend : (1 << 0) | (1 << 2) | (1 << 3) | (1 << 5);

// GL and DX11
WGPUInstanceBackend_Secondary: WGPUInstanceBackend : (1 << 1) | (1 << 4);
WGPUInstanceBackend_Force32: WGPUInstanceBackend : 2147483647;

WGPUInstanceFlag :: WGPUFlags;
WGPUInstanceFlag_Default: WGPUInstanceFlag : 0;
WGPUInstanceFlag_Debug: WGPUInstanceFlag : 1 << 0;
WGPUInstanceFlag_Validation: WGPUInstanceFlag : 1 << 1;
WGPUInstanceFlag_DiscardHalLabels: WGPUInstanceFlag : 1 << 2;
WGPUInstanceFlag_Force32: WGPUInstanceFlag : 2147483647;

WGPUDx12Compiler :: enum s32 {
    Undefined :: 0;
    Fxc       :: 1;
    Dxc       :: 2;
    Force32   :: 2147483647;

    WGPUDx12Compiler_Undefined :: Undefined;
    WGPUDx12Compiler_Fxc       :: Fxc;
    WGPUDx12Compiler_Dxc       :: Dxc;
    WGPUDx12Compiler_Force32   :: Force32;
}

WGPUGles3MinorVersion :: enum s32 {
    Automatic :: 0;
    Version0  :: 1;
    Version1  :: 2;
    Version2  :: 3;
    Force32   :: 2147483647;

    WGPUGles3MinorVersion_Automatic :: Automatic;
    WGPUGles3MinorVersion_Version0  :: Version0;
    WGPUGles3MinorVersion_Version1  :: Version1;
    WGPUGles3MinorVersion_Version2  :: Version2;
    WGPUGles3MinorVersion_Force32   :: Force32;
}

WGPUPipelineStatisticName :: enum s32 {
    VertexShaderInvocations   :: 0;
    ClipperInvocations        :: 1;
    ClipperPrimitivesOut      :: 2;
    FragmentShaderInvocations :: 3;
    ComputeShaderInvocations  :: 4;
    Force32                   :: 2147483647;

    WGPUPipelineStatisticName_VertexShaderInvocations   :: VertexShaderInvocations;
    WGPUPipelineStatisticName_ClipperInvocations        :: ClipperInvocations;
    WGPUPipelineStatisticName_ClipperPrimitivesOut      :: ClipperPrimitivesOut;
    WGPUPipelineStatisticName_FragmentShaderInvocations :: FragmentShaderInvocations;
    WGPUPipelineStatisticName_ComputeShaderInvocations  :: ComputeShaderInvocations;
    WGPUPipelineStatisticName_Force32                   :: Force32;
}

WGPUNativeQueryType :: enum s32 {
    PipelineStatistics :: 196608;
    Force32            :: 2147483647;

    WGPUNativeQueryType_PipelineStatistics :: PipelineStatistics;
    WGPUNativeQueryType_Force32            :: Force32;
}

WGPUDxcMaxShaderModel :: enum s32 {
    V6_0    :: 0;
    V6_1    :: 1;
    V6_2    :: 2;
    V6_3    :: 3;
    V6_4    :: 4;
    V6_5    :: 5;
    V6_6    :: 6;
    V6_7    :: 7;
    Force32 :: 2147483647;

    WGPUDxcMaxShaderModel_V6_0    :: V6_0;
    WGPUDxcMaxShaderModel_V6_1    :: V6_1;
    WGPUDxcMaxShaderModel_V6_2    :: V6_2;
    WGPUDxcMaxShaderModel_V6_3    :: V6_3;
    WGPUDxcMaxShaderModel_V6_4    :: V6_4;
    WGPUDxcMaxShaderModel_V6_5    :: V6_5;
    WGPUDxcMaxShaderModel_V6_6    :: V6_6;
    WGPUDxcMaxShaderModel_V6_7    :: V6_7;
    WGPUDxcMaxShaderModel_Force32 :: Force32;
}

WGPUGLFenceBehaviour :: enum s32 {
    Normal     :: 0;
    AutoFinish :: 1;
    Force32    :: 2147483647;

    WGPUGLFenceBehaviour_Normal     :: Normal;
    WGPUGLFenceBehaviour_AutoFinish :: AutoFinish;
    WGPUGLFenceBehaviour_Force32    :: Force32;
}

WGPUInstanceExtras :: struct {
    chain:              WGPUChainedStruct;
    backends:           WGPUInstanceBackend;
    flags:              WGPUInstanceFlag;
    dx12ShaderCompiler: WGPUDx12Compiler;
    gles3MinorVersion:  WGPUGles3MinorVersion;
    glFenceBehaviour:   WGPUGLFenceBehaviour;
    dxilPath:           WGPUStringView;
    dxcPath:            WGPUStringView;
    dxcMaxShaderModel:  WGPUDxcMaxShaderModel;
}

WGPUDeviceExtras :: struct {
    chain:     WGPUChainedStruct;
    tracePath: WGPUStringView;
}

WGPUNativeLimits :: struct {
    /** This struct chain is used as mutable in some places and immutable in others. */
    chain:                 WGPUChainedStructOut;
    maxPushConstantSize:   u32;
    maxNonSamplerBindings: u32;
}

WGPUPushConstantRange :: struct {
    stages: WGPUShaderStage;
    start:  u32;
    end:    u32;
}

WGPUPipelineLayoutExtras :: struct {
    chain:                  WGPUChainedStruct;
    pushConstantRangeCount: u64;
    pushConstantRanges:     *WGPUPushConstantRange;
}

WGPUSubmissionIndex :: u64;

WGPUShaderDefine :: struct {
    name:  WGPUStringView;
    value: WGPUStringView;
}

WGPUShaderSourceGLSL :: struct {
    chain:       WGPUChainedStruct;
    stage:       WGPUShaderStage;
    code:        WGPUStringView;
    defineCount: u32;
    defines:     *WGPUShaderDefine;
}

WGPUShaderModuleDescriptorSpirV :: struct {
    label:      WGPUStringView;
    sourceSize: u32;
    source:     *u32;
}

WGPURegistryReport :: struct {
    numAllocated:        u64;
    numKeptFromUser:     u64;
    numReleasedFromUser: u64;
    elementSize:         u64;
}

WGPUHubReport :: struct {
    adapters:         WGPURegistryReport;
    devices:          WGPURegistryReport;
    queues:           WGPURegistryReport;
    pipelineLayouts:  WGPURegistryReport;
    shaderModules:    WGPURegistryReport;
    bindGroupLayouts: WGPURegistryReport;
    bindGroups:       WGPURegistryReport;
    commandBuffers:   WGPURegistryReport;
    renderBundles:    WGPURegistryReport;
    renderPipelines:  WGPURegistryReport;
    computePipelines: WGPURegistryReport;
    pipelineCaches:   WGPURegistryReport;
    querySets:        WGPURegistryReport;
    buffers:          WGPURegistryReport;
    textures:         WGPURegistryReport;
    textureViews:     WGPURegistryReport;
    samplers:         WGPURegistryReport;
}

WGPUGlobalReport :: struct {
    surfaces: WGPURegistryReport;
    hub:      WGPUHubReport;
}

WGPUInstanceEnumerateAdapterOptions :: struct {
    nextInChain: *WGPUChainedStruct;
    backends:    WGPUInstanceBackend;
}

WGPUBindGroupEntryExtras :: struct {
    chain:            WGPUChainedStruct;
    buffers:          *WGPUBuffer;
    bufferCount:      u64;
    samplers:         *WGPUSampler;
    samplerCount:     u64;
    textureViews:     *WGPUTextureView;
    textureViewCount: u64;
}

WGPUBindGroupLayoutEntryExtras :: struct {
    chain: WGPUChainedStruct;
    count: u32;
}

WGPUQuerySetDescriptorExtras :: struct {
    chain:                  WGPUChainedStruct;
    pipelineStatistics:     *WGPUPipelineStatisticName;
    pipelineStatisticCount: u64;
}

WGPUSurfaceConfigurationExtras :: struct {
    chain:                      WGPUChainedStruct;
    desiredMaximumFrameLatency: u32;
}

WGPULogCallback :: #type (level: WGPULogLevel, message: WGPUStringView, userdata: *void) -> void #c_call;

WGPUNativeTextureFormat :: enum s32 {
    R16Unorm    :: 196609;
    R16Snorm    :: 196610;
    Rg16Unorm   :: 196611;
    Rg16Snorm   :: 196612;
    Rgba16Unorm :: 196613;
    Rgba16Snorm :: 196614;

    NV12        :: 196615;

    WGPUNativeTextureFormat_R16Unorm    :: R16Unorm;
    WGPUNativeTextureFormat_R16Snorm    :: R16Snorm;
    WGPUNativeTextureFormat_Rg16Unorm   :: Rg16Unorm;
    WGPUNativeTextureFormat_Rg16Snorm   :: Rg16Snorm;
    WGPUNativeTextureFormat_Rgba16Unorm :: Rgba16Unorm;
    WGPUNativeTextureFormat_Rgba16Snorm :: Rgba16Snorm;

    WGPUNativeTextureFormat_NV12        :: NV12;
}

#scope_file

#import "Basic"; // For assert


#run {
    {
        info := type_info(WGPUStringView);
        for info.members {
            if it.name == {
                case "data";
                    assert(it.offset_in_bytes == 0, "WGPUStringView.data has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUStringView.data has unexpected size % instead of 8", it.type.runtime_size);
                case "length";
                    assert(it.offset_in_bytes == 8, "WGPUStringView.length has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUStringView.length has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUStringView) == 16, "WGPUStringView has size % instead of 16", size_of(WGPUStringView));
    }

    {
        info := type_info(WGPUChainedStruct);
        for info.members {
            if it.name == {
                case "next";
                    assert(it.offset_in_bytes == 0, "WGPUChainedStruct.next has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUChainedStruct.next has unexpected size % instead of 8", it.type.runtime_size);
                case "sType";
                    assert(it.offset_in_bytes == 8, "WGPUChainedStruct.sType has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUChainedStruct.sType has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUChainedStruct) == 16, "WGPUChainedStruct has size % instead of 16", size_of(WGPUChainedStruct));
    }

    {
        info := type_info(WGPUChainedStructOut);
        for info.members {
            if it.name == {
                case "next";
                    assert(it.offset_in_bytes == 0, "WGPUChainedStructOut.next has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUChainedStructOut.next has unexpected size % instead of 8", it.type.runtime_size);
                case "sType";
                    assert(it.offset_in_bytes == 8, "WGPUChainedStructOut.sType has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUChainedStructOut.sType has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUChainedStructOut) == 16, "WGPUChainedStructOut has size % instead of 16", size_of(WGPUChainedStructOut));
    }

    {
        info := type_info(WGPUBufferMapCallbackInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUBufferMapCallbackInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBufferMapCallbackInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "mode";
                    assert(it.offset_in_bytes == 8, "WGPUBufferMapCallbackInfo.mode has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUBufferMapCallbackInfo.mode has unexpected size % instead of 4", it.type.runtime_size);
                case "callback";
                    assert(it.offset_in_bytes == 16, "WGPUBufferMapCallbackInfo.callback has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBufferMapCallbackInfo.callback has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata1";
                    assert(it.offset_in_bytes == 24, "WGPUBufferMapCallbackInfo.userdata1 has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBufferMapCallbackInfo.userdata1 has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata2";
                    assert(it.offset_in_bytes == 32, "WGPUBufferMapCallbackInfo.userdata2 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBufferMapCallbackInfo.userdata2 has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBufferMapCallbackInfo) == 40, "WGPUBufferMapCallbackInfo has size % instead of 40", size_of(WGPUBufferMapCallbackInfo));
    }

    {
        info := type_info(WGPUCompilationInfoCallbackInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUCompilationInfoCallbackInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationInfoCallbackInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "mode";
                    assert(it.offset_in_bytes == 8, "WGPUCompilationInfoCallbackInfo.mode has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUCompilationInfoCallbackInfo.mode has unexpected size % instead of 4", it.type.runtime_size);
                case "callback";
                    assert(it.offset_in_bytes == 16, "WGPUCompilationInfoCallbackInfo.callback has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationInfoCallbackInfo.callback has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata1";
                    assert(it.offset_in_bytes == 24, "WGPUCompilationInfoCallbackInfo.userdata1 has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationInfoCallbackInfo.userdata1 has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata2";
                    assert(it.offset_in_bytes == 32, "WGPUCompilationInfoCallbackInfo.userdata2 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationInfoCallbackInfo.userdata2 has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUCompilationInfoCallbackInfo) == 40, "WGPUCompilationInfoCallbackInfo has size % instead of 40", size_of(WGPUCompilationInfoCallbackInfo));
    }

    {
        info := type_info(WGPUCreateComputePipelineAsyncCallbackInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUCreateComputePipelineAsyncCallbackInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCreateComputePipelineAsyncCallbackInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "mode";
                    assert(it.offset_in_bytes == 8, "WGPUCreateComputePipelineAsyncCallbackInfo.mode has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUCreateComputePipelineAsyncCallbackInfo.mode has unexpected size % instead of 4", it.type.runtime_size);
                case "callback";
                    assert(it.offset_in_bytes == 16, "WGPUCreateComputePipelineAsyncCallbackInfo.callback has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCreateComputePipelineAsyncCallbackInfo.callback has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata1";
                    assert(it.offset_in_bytes == 24, "WGPUCreateComputePipelineAsyncCallbackInfo.userdata1 has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCreateComputePipelineAsyncCallbackInfo.userdata1 has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata2";
                    assert(it.offset_in_bytes == 32, "WGPUCreateComputePipelineAsyncCallbackInfo.userdata2 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCreateComputePipelineAsyncCallbackInfo.userdata2 has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUCreateComputePipelineAsyncCallbackInfo) == 40, "WGPUCreateComputePipelineAsyncCallbackInfo has size % instead of 40", size_of(WGPUCreateComputePipelineAsyncCallbackInfo));
    }

    {
        info := type_info(WGPUCreateRenderPipelineAsyncCallbackInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUCreateRenderPipelineAsyncCallbackInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCreateRenderPipelineAsyncCallbackInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "mode";
                    assert(it.offset_in_bytes == 8, "WGPUCreateRenderPipelineAsyncCallbackInfo.mode has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUCreateRenderPipelineAsyncCallbackInfo.mode has unexpected size % instead of 4", it.type.runtime_size);
                case "callback";
                    assert(it.offset_in_bytes == 16, "WGPUCreateRenderPipelineAsyncCallbackInfo.callback has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCreateRenderPipelineAsyncCallbackInfo.callback has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata1";
                    assert(it.offset_in_bytes == 24, "WGPUCreateRenderPipelineAsyncCallbackInfo.userdata1 has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCreateRenderPipelineAsyncCallbackInfo.userdata1 has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata2";
                    assert(it.offset_in_bytes == 32, "WGPUCreateRenderPipelineAsyncCallbackInfo.userdata2 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCreateRenderPipelineAsyncCallbackInfo.userdata2 has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUCreateRenderPipelineAsyncCallbackInfo) == 40, "WGPUCreateRenderPipelineAsyncCallbackInfo has size % instead of 40", size_of(WGPUCreateRenderPipelineAsyncCallbackInfo));
    }

    {
        info := type_info(WGPUDeviceLostCallbackInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUDeviceLostCallbackInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUDeviceLostCallbackInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "mode";
                    assert(it.offset_in_bytes == 8, "WGPUDeviceLostCallbackInfo.mode has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUDeviceLostCallbackInfo.mode has unexpected size % instead of 4", it.type.runtime_size);
                case "callback";
                    assert(it.offset_in_bytes == 16, "WGPUDeviceLostCallbackInfo.callback has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUDeviceLostCallbackInfo.callback has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata1";
                    assert(it.offset_in_bytes == 24, "WGPUDeviceLostCallbackInfo.userdata1 has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUDeviceLostCallbackInfo.userdata1 has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata2";
                    assert(it.offset_in_bytes == 32, "WGPUDeviceLostCallbackInfo.userdata2 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUDeviceLostCallbackInfo.userdata2 has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUDeviceLostCallbackInfo) == 40, "WGPUDeviceLostCallbackInfo has size % instead of 40", size_of(WGPUDeviceLostCallbackInfo));
    }

    {
        info := type_info(WGPUPopErrorScopeCallbackInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUPopErrorScopeCallbackInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPopErrorScopeCallbackInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "mode";
                    assert(it.offset_in_bytes == 8, "WGPUPopErrorScopeCallbackInfo.mode has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUPopErrorScopeCallbackInfo.mode has unexpected size % instead of 4", it.type.runtime_size);
                case "callback";
                    assert(it.offset_in_bytes == 16, "WGPUPopErrorScopeCallbackInfo.callback has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPopErrorScopeCallbackInfo.callback has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata1";
                    assert(it.offset_in_bytes == 24, "WGPUPopErrorScopeCallbackInfo.userdata1 has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPopErrorScopeCallbackInfo.userdata1 has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata2";
                    assert(it.offset_in_bytes == 32, "WGPUPopErrorScopeCallbackInfo.userdata2 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPopErrorScopeCallbackInfo.userdata2 has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUPopErrorScopeCallbackInfo) == 40, "WGPUPopErrorScopeCallbackInfo has size % instead of 40", size_of(WGPUPopErrorScopeCallbackInfo));
    }

    {
        info := type_info(WGPUQueueWorkDoneCallbackInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUQueueWorkDoneCallbackInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUQueueWorkDoneCallbackInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "mode";
                    assert(it.offset_in_bytes == 8, "WGPUQueueWorkDoneCallbackInfo.mode has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUQueueWorkDoneCallbackInfo.mode has unexpected size % instead of 4", it.type.runtime_size);
                case "callback";
                    assert(it.offset_in_bytes == 16, "WGPUQueueWorkDoneCallbackInfo.callback has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUQueueWorkDoneCallbackInfo.callback has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata1";
                    assert(it.offset_in_bytes == 24, "WGPUQueueWorkDoneCallbackInfo.userdata1 has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUQueueWorkDoneCallbackInfo.userdata1 has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata2";
                    assert(it.offset_in_bytes == 32, "WGPUQueueWorkDoneCallbackInfo.userdata2 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUQueueWorkDoneCallbackInfo.userdata2 has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUQueueWorkDoneCallbackInfo) == 40, "WGPUQueueWorkDoneCallbackInfo has size % instead of 40", size_of(WGPUQueueWorkDoneCallbackInfo));
    }

    {
        info := type_info(WGPURequestAdapterCallbackInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPURequestAdapterCallbackInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURequestAdapterCallbackInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "mode";
                    assert(it.offset_in_bytes == 8, "WGPURequestAdapterCallbackInfo.mode has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURequestAdapterCallbackInfo.mode has unexpected size % instead of 4", it.type.runtime_size);
                case "callback";
                    assert(it.offset_in_bytes == 16, "WGPURequestAdapterCallbackInfo.callback has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURequestAdapterCallbackInfo.callback has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata1";
                    assert(it.offset_in_bytes == 24, "WGPURequestAdapterCallbackInfo.userdata1 has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURequestAdapterCallbackInfo.userdata1 has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata2";
                    assert(it.offset_in_bytes == 32, "WGPURequestAdapterCallbackInfo.userdata2 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURequestAdapterCallbackInfo.userdata2 has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURequestAdapterCallbackInfo) == 40, "WGPURequestAdapterCallbackInfo has size % instead of 40", size_of(WGPURequestAdapterCallbackInfo));
    }

    {
        info := type_info(WGPURequestDeviceCallbackInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPURequestDeviceCallbackInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURequestDeviceCallbackInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "mode";
                    assert(it.offset_in_bytes == 8, "WGPURequestDeviceCallbackInfo.mode has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURequestDeviceCallbackInfo.mode has unexpected size % instead of 4", it.type.runtime_size);
                case "callback";
                    assert(it.offset_in_bytes == 16, "WGPURequestDeviceCallbackInfo.callback has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURequestDeviceCallbackInfo.callback has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata1";
                    assert(it.offset_in_bytes == 24, "WGPURequestDeviceCallbackInfo.userdata1 has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURequestDeviceCallbackInfo.userdata1 has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata2";
                    assert(it.offset_in_bytes == 32, "WGPURequestDeviceCallbackInfo.userdata2 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURequestDeviceCallbackInfo.userdata2 has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURequestDeviceCallbackInfo) == 40, "WGPURequestDeviceCallbackInfo has size % instead of 40", size_of(WGPURequestDeviceCallbackInfo));
    }

    {
        info := type_info(WGPUUncapturedErrorCallbackInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUUncapturedErrorCallbackInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUUncapturedErrorCallbackInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "callback";
                    assert(it.offset_in_bytes == 8, "WGPUUncapturedErrorCallbackInfo.callback has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUUncapturedErrorCallbackInfo.callback has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata1";
                    assert(it.offset_in_bytes == 16, "WGPUUncapturedErrorCallbackInfo.userdata1 has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUUncapturedErrorCallbackInfo.userdata1 has unexpected size % instead of 8", it.type.runtime_size);
                case "userdata2";
                    assert(it.offset_in_bytes == 24, "WGPUUncapturedErrorCallbackInfo.userdata2 has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUUncapturedErrorCallbackInfo.userdata2 has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUUncapturedErrorCallbackInfo) == 32, "WGPUUncapturedErrorCallbackInfo has size % instead of 32", size_of(WGPUUncapturedErrorCallbackInfo));
    }

    {
        info := type_info(WGPUAdapterInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUAdapterInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUAdapterInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "vendor";
                    assert(it.offset_in_bytes == 8, "WGPUAdapterInfo.vendor has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUAdapterInfo.vendor has unexpected size % instead of 16", it.type.runtime_size);
                case "architecture";
                    assert(it.offset_in_bytes == 24, "WGPUAdapterInfo.architecture has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUAdapterInfo.architecture has unexpected size % instead of 16", it.type.runtime_size);
                case "device";
                    assert(it.offset_in_bytes == 40, "WGPUAdapterInfo.device has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUAdapterInfo.device has unexpected size % instead of 16", it.type.runtime_size);
                case "description";
                    assert(it.offset_in_bytes == 56, "WGPUAdapterInfo.description has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUAdapterInfo.description has unexpected size % instead of 16", it.type.runtime_size);
                case "backendType";
                    assert(it.offset_in_bytes == 72, "WGPUAdapterInfo.backendType has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUAdapterInfo.backendType has unexpected size % instead of 4", it.type.runtime_size);
                case "adapterType";
                    assert(it.offset_in_bytes == 76, "WGPUAdapterInfo.adapterType has unexpected offset % instead of 76", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUAdapterInfo.adapterType has unexpected size % instead of 4", it.type.runtime_size);
                case "vendorID";
                    assert(it.offset_in_bytes == 80, "WGPUAdapterInfo.vendorID has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUAdapterInfo.vendorID has unexpected size % instead of 4", it.type.runtime_size);
                case "deviceID";
                    assert(it.offset_in_bytes == 84, "WGPUAdapterInfo.deviceID has unexpected offset % instead of 84", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUAdapterInfo.deviceID has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUAdapterInfo) == 88, "WGPUAdapterInfo has size % instead of 88", size_of(WGPUAdapterInfo));
    }

    {
        info := type_info(WGPUBindGroupEntry);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUBindGroupEntry.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntry.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "binding";
                    assert(it.offset_in_bytes == 8, "WGPUBindGroupEntry.binding has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUBindGroupEntry.binding has unexpected size % instead of 4", it.type.runtime_size);
                case "buffer";
                    assert(it.offset_in_bytes == 16, "WGPUBindGroupEntry.buffer has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntry.buffer has unexpected size % instead of 8", it.type.runtime_size);
                case "offset";
                    assert(it.offset_in_bytes == 24, "WGPUBindGroupEntry.offset has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntry.offset has unexpected size % instead of 8", it.type.runtime_size);
                case "size";
                    assert(it.offset_in_bytes == 32, "WGPUBindGroupEntry.size has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntry.size has unexpected size % instead of 8", it.type.runtime_size);
                case "sampler";
                    assert(it.offset_in_bytes == 40, "WGPUBindGroupEntry.sampler has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntry.sampler has unexpected size % instead of 8", it.type.runtime_size);
                case "textureView";
                    assert(it.offset_in_bytes == 48, "WGPUBindGroupEntry.textureView has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntry.textureView has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBindGroupEntry) == 56, "WGPUBindGroupEntry has size % instead of 56", size_of(WGPUBindGroupEntry));
    }

    {
        info := type_info(WGPUBlendComponent);
        for info.members {
            if it.name == {
                case "operation";
                    assert(it.offset_in_bytes == 0, "WGPUBlendComponent.operation has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUBlendComponent.operation has unexpected size % instead of 4", it.type.runtime_size);
                case "srcFactor";
                    assert(it.offset_in_bytes == 4, "WGPUBlendComponent.srcFactor has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUBlendComponent.srcFactor has unexpected size % instead of 4", it.type.runtime_size);
                case "dstFactor";
                    assert(it.offset_in_bytes == 8, "WGPUBlendComponent.dstFactor has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUBlendComponent.dstFactor has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBlendComponent) == 12, "WGPUBlendComponent has size % instead of 12", size_of(WGPUBlendComponent));
    }

    {
        info := type_info(WGPUBufferBindingLayout);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUBufferBindingLayout.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBufferBindingLayout.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "type";
                    assert(it.offset_in_bytes == 8, "WGPUBufferBindingLayout.type has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUBufferBindingLayout.type has unexpected size % instead of 4", it.type.runtime_size);
                case "hasDynamicOffset";
                    assert(it.offset_in_bytes == 12, "WGPUBufferBindingLayout.hasDynamicOffset has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUBufferBindingLayout.hasDynamicOffset has unexpected size % instead of 4", it.type.runtime_size);
                case "minBindingSize";
                    assert(it.offset_in_bytes == 16, "WGPUBufferBindingLayout.minBindingSize has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBufferBindingLayout.minBindingSize has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBufferBindingLayout) == 24, "WGPUBufferBindingLayout has size % instead of 24", size_of(WGPUBufferBindingLayout));
    }

    {
        info := type_info(WGPUBufferDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUBufferDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBufferDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUBufferDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUBufferDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "usage";
                    assert(it.offset_in_bytes == 24, "WGPUBufferDescriptor.usage has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBufferDescriptor.usage has unexpected size % instead of 8", it.type.runtime_size);
                case "size";
                    assert(it.offset_in_bytes == 32, "WGPUBufferDescriptor.size has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBufferDescriptor.size has unexpected size % instead of 8", it.type.runtime_size);
                case "mappedAtCreation";
                    assert(it.offset_in_bytes == 40, "WGPUBufferDescriptor.mappedAtCreation has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUBufferDescriptor.mappedAtCreation has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBufferDescriptor) == 48, "WGPUBufferDescriptor has size % instead of 48", size_of(WGPUBufferDescriptor));
    }

    {
        info := type_info(WGPUColor);
        for info.members {
            if it.name == {
                case "r";
                    assert(it.offset_in_bytes == 0, "WGPUColor.r has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUColor.r has unexpected size % instead of 8", it.type.runtime_size);
                case "g";
                    assert(it.offset_in_bytes == 8, "WGPUColor.g has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUColor.g has unexpected size % instead of 8", it.type.runtime_size);
                case "b";
                    assert(it.offset_in_bytes == 16, "WGPUColor.b has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUColor.b has unexpected size % instead of 8", it.type.runtime_size);
                case "a";
                    assert(it.offset_in_bytes == 24, "WGPUColor.a has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUColor.a has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUColor) == 32, "WGPUColor has size % instead of 32", size_of(WGPUColor));
    }

    {
        info := type_info(WGPUCommandBufferDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUCommandBufferDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCommandBufferDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUCommandBufferDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUCommandBufferDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUCommandBufferDescriptor) == 24, "WGPUCommandBufferDescriptor has size % instead of 24", size_of(WGPUCommandBufferDescriptor));
    }

    {
        info := type_info(WGPUCommandEncoderDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUCommandEncoderDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCommandEncoderDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUCommandEncoderDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUCommandEncoderDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUCommandEncoderDescriptor) == 24, "WGPUCommandEncoderDescriptor has size % instead of 24", size_of(WGPUCommandEncoderDescriptor));
    }

    {
        info := type_info(WGPUCompilationMessage);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUCompilationMessage.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationMessage.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "message";
                    assert(it.offset_in_bytes == 8, "WGPUCompilationMessage.message has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUCompilationMessage.message has unexpected size % instead of 16", it.type.runtime_size);
                case "type";
                    assert(it.offset_in_bytes == 24, "WGPUCompilationMessage.type has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUCompilationMessage.type has unexpected size % instead of 4", it.type.runtime_size);
                case "lineNum";
                    assert(it.offset_in_bytes == 32, "WGPUCompilationMessage.lineNum has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationMessage.lineNum has unexpected size % instead of 8", it.type.runtime_size);
                case "linePos";
                    assert(it.offset_in_bytes == 40, "WGPUCompilationMessage.linePos has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationMessage.linePos has unexpected size % instead of 8", it.type.runtime_size);
                case "offset";
                    assert(it.offset_in_bytes == 48, "WGPUCompilationMessage.offset has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationMessage.offset has unexpected size % instead of 8", it.type.runtime_size);
                case "length";
                    assert(it.offset_in_bytes == 56, "WGPUCompilationMessage.length has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationMessage.length has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUCompilationMessage) == 64, "WGPUCompilationMessage has size % instead of 64", size_of(WGPUCompilationMessage));
    }

    {
        info := type_info(WGPUComputePassTimestampWrites);
        for info.members {
            if it.name == {
                case "querySet";
                    assert(it.offset_in_bytes == 0, "WGPUComputePassTimestampWrites.querySet has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUComputePassTimestampWrites.querySet has unexpected size % instead of 8", it.type.runtime_size);
                case "beginningOfPassWriteIndex";
                    assert(it.offset_in_bytes == 8, "WGPUComputePassTimestampWrites.beginningOfPassWriteIndex has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUComputePassTimestampWrites.beginningOfPassWriteIndex has unexpected size % instead of 4", it.type.runtime_size);
                case "endOfPassWriteIndex";
                    assert(it.offset_in_bytes == 12, "WGPUComputePassTimestampWrites.endOfPassWriteIndex has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUComputePassTimestampWrites.endOfPassWriteIndex has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUComputePassTimestampWrites) == 16, "WGPUComputePassTimestampWrites has size % instead of 16", size_of(WGPUComputePassTimestampWrites));
    }

    {
        info := type_info(WGPUConstantEntry);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUConstantEntry.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUConstantEntry.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "key";
                    assert(it.offset_in_bytes == 8, "WGPUConstantEntry.key has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUConstantEntry.key has unexpected size % instead of 16", it.type.runtime_size);
                case "value";
                    assert(it.offset_in_bytes == 24, "WGPUConstantEntry.value has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUConstantEntry.value has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUConstantEntry) == 32, "WGPUConstantEntry has size % instead of 32", size_of(WGPUConstantEntry));
    }

    {
        info := type_info(WGPUExtent3D);
        for info.members {
            if it.name == {
                case "width";
                    assert(it.offset_in_bytes == 0, "WGPUExtent3D.width has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUExtent3D.width has unexpected size % instead of 4", it.type.runtime_size);
                case "height";
                    assert(it.offset_in_bytes == 4, "WGPUExtent3D.height has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUExtent3D.height has unexpected size % instead of 4", it.type.runtime_size);
                case "depthOrArrayLayers";
                    assert(it.offset_in_bytes == 8, "WGPUExtent3D.depthOrArrayLayers has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUExtent3D.depthOrArrayLayers has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUExtent3D) == 12, "WGPUExtent3D has size % instead of 12", size_of(WGPUExtent3D));
    }

    {
        info := type_info(WGPUFuture);
        for info.members {
            if it.name == {
                case "id";
                    assert(it.offset_in_bytes == 0, "WGPUFuture.id has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUFuture.id has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUFuture) == 8, "WGPUFuture has size % instead of 8", size_of(WGPUFuture));
    }

    {
        info := type_info(WGPUInstanceCapabilities);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUInstanceCapabilities.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUInstanceCapabilities.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "timedWaitAnyEnable";
                    assert(it.offset_in_bytes == 8, "WGPUInstanceCapabilities.timedWaitAnyEnable has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUInstanceCapabilities.timedWaitAnyEnable has unexpected size % instead of 4", it.type.runtime_size);
                case "timedWaitAnyMaxCount";
                    assert(it.offset_in_bytes == 16, "WGPUInstanceCapabilities.timedWaitAnyMaxCount has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUInstanceCapabilities.timedWaitAnyMaxCount has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUInstanceCapabilities) == 24, "WGPUInstanceCapabilities has size % instead of 24", size_of(WGPUInstanceCapabilities));
    }

    {
        info := type_info(WGPULimits);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPULimits.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPULimits.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "maxTextureDimension1D";
                    assert(it.offset_in_bytes == 8, "WGPULimits.maxTextureDimension1D has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxTextureDimension1D has unexpected size % instead of 4", it.type.runtime_size);
                case "maxTextureDimension2D";
                    assert(it.offset_in_bytes == 12, "WGPULimits.maxTextureDimension2D has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxTextureDimension2D has unexpected size % instead of 4", it.type.runtime_size);
                case "maxTextureDimension3D";
                    assert(it.offset_in_bytes == 16, "WGPULimits.maxTextureDimension3D has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxTextureDimension3D has unexpected size % instead of 4", it.type.runtime_size);
                case "maxTextureArrayLayers";
                    assert(it.offset_in_bytes == 20, "WGPULimits.maxTextureArrayLayers has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxTextureArrayLayers has unexpected size % instead of 4", it.type.runtime_size);
                case "maxBindGroups";
                    assert(it.offset_in_bytes == 24, "WGPULimits.maxBindGroups has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxBindGroups has unexpected size % instead of 4", it.type.runtime_size);
                case "maxBindGroupsPlusVertexBuffers";
                    assert(it.offset_in_bytes == 28, "WGPULimits.maxBindGroupsPlusVertexBuffers has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxBindGroupsPlusVertexBuffers has unexpected size % instead of 4", it.type.runtime_size);
                case "maxBindingsPerBindGroup";
                    assert(it.offset_in_bytes == 32, "WGPULimits.maxBindingsPerBindGroup has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxBindingsPerBindGroup has unexpected size % instead of 4", it.type.runtime_size);
                case "maxDynamicUniformBuffersPerPipelineLayout";
                    assert(it.offset_in_bytes == 36, "WGPULimits.maxDynamicUniformBuffersPerPipelineLayout has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxDynamicUniformBuffersPerPipelineLayout has unexpected size % instead of 4", it.type.runtime_size);
                case "maxDynamicStorageBuffersPerPipelineLayout";
                    assert(it.offset_in_bytes == 40, "WGPULimits.maxDynamicStorageBuffersPerPipelineLayout has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxDynamicStorageBuffersPerPipelineLayout has unexpected size % instead of 4", it.type.runtime_size);
                case "maxSampledTexturesPerShaderStage";
                    assert(it.offset_in_bytes == 44, "WGPULimits.maxSampledTexturesPerShaderStage has unexpected offset % instead of 44", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxSampledTexturesPerShaderStage has unexpected size % instead of 4", it.type.runtime_size);
                case "maxSamplersPerShaderStage";
                    assert(it.offset_in_bytes == 48, "WGPULimits.maxSamplersPerShaderStage has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxSamplersPerShaderStage has unexpected size % instead of 4", it.type.runtime_size);
                case "maxStorageBuffersPerShaderStage";
                    assert(it.offset_in_bytes == 52, "WGPULimits.maxStorageBuffersPerShaderStage has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxStorageBuffersPerShaderStage has unexpected size % instead of 4", it.type.runtime_size);
                case "maxStorageTexturesPerShaderStage";
                    assert(it.offset_in_bytes == 56, "WGPULimits.maxStorageTexturesPerShaderStage has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxStorageTexturesPerShaderStage has unexpected size % instead of 4", it.type.runtime_size);
                case "maxUniformBuffersPerShaderStage";
                    assert(it.offset_in_bytes == 60, "WGPULimits.maxUniformBuffersPerShaderStage has unexpected offset % instead of 60", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxUniformBuffersPerShaderStage has unexpected size % instead of 4", it.type.runtime_size);
                case "maxUniformBufferBindingSize";
                    assert(it.offset_in_bytes == 64, "WGPULimits.maxUniformBufferBindingSize has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPULimits.maxUniformBufferBindingSize has unexpected size % instead of 8", it.type.runtime_size);
                case "maxStorageBufferBindingSize";
                    assert(it.offset_in_bytes == 72, "WGPULimits.maxStorageBufferBindingSize has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPULimits.maxStorageBufferBindingSize has unexpected size % instead of 8", it.type.runtime_size);
                case "minUniformBufferOffsetAlignment";
                    assert(it.offset_in_bytes == 80, "WGPULimits.minUniformBufferOffsetAlignment has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.minUniformBufferOffsetAlignment has unexpected size % instead of 4", it.type.runtime_size);
                case "minStorageBufferOffsetAlignment";
                    assert(it.offset_in_bytes == 84, "WGPULimits.minStorageBufferOffsetAlignment has unexpected offset % instead of 84", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.minStorageBufferOffsetAlignment has unexpected size % instead of 4", it.type.runtime_size);
                case "maxVertexBuffers";
                    assert(it.offset_in_bytes == 88, "WGPULimits.maxVertexBuffers has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxVertexBuffers has unexpected size % instead of 4", it.type.runtime_size);
                case "maxBufferSize";
                    assert(it.offset_in_bytes == 96, "WGPULimits.maxBufferSize has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPULimits.maxBufferSize has unexpected size % instead of 8", it.type.runtime_size);
                case "maxVertexAttributes";
                    assert(it.offset_in_bytes == 104, "WGPULimits.maxVertexAttributes has unexpected offset % instead of 104", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxVertexAttributes has unexpected size % instead of 4", it.type.runtime_size);
                case "maxVertexBufferArrayStride";
                    assert(it.offset_in_bytes == 108, "WGPULimits.maxVertexBufferArrayStride has unexpected offset % instead of 108", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxVertexBufferArrayStride has unexpected size % instead of 4", it.type.runtime_size);
                case "maxInterStageShaderVariables";
                    assert(it.offset_in_bytes == 112, "WGPULimits.maxInterStageShaderVariables has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxInterStageShaderVariables has unexpected size % instead of 4", it.type.runtime_size);
                case "maxColorAttachments";
                    assert(it.offset_in_bytes == 116, "WGPULimits.maxColorAttachments has unexpected offset % instead of 116", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxColorAttachments has unexpected size % instead of 4", it.type.runtime_size);
                case "maxColorAttachmentBytesPerSample";
                    assert(it.offset_in_bytes == 120, "WGPULimits.maxColorAttachmentBytesPerSample has unexpected offset % instead of 120", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxColorAttachmentBytesPerSample has unexpected size % instead of 4", it.type.runtime_size);
                case "maxComputeWorkgroupStorageSize";
                    assert(it.offset_in_bytes == 124, "WGPULimits.maxComputeWorkgroupStorageSize has unexpected offset % instead of 124", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxComputeWorkgroupStorageSize has unexpected size % instead of 4", it.type.runtime_size);
                case "maxComputeInvocationsPerWorkgroup";
                    assert(it.offset_in_bytes == 128, "WGPULimits.maxComputeInvocationsPerWorkgroup has unexpected offset % instead of 128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxComputeInvocationsPerWorkgroup has unexpected size % instead of 4", it.type.runtime_size);
                case "maxComputeWorkgroupSizeX";
                    assert(it.offset_in_bytes == 132, "WGPULimits.maxComputeWorkgroupSizeX has unexpected offset % instead of 132", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxComputeWorkgroupSizeX has unexpected size % instead of 4", it.type.runtime_size);
                case "maxComputeWorkgroupSizeY";
                    assert(it.offset_in_bytes == 136, "WGPULimits.maxComputeWorkgroupSizeY has unexpected offset % instead of 136", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxComputeWorkgroupSizeY has unexpected size % instead of 4", it.type.runtime_size);
                case "maxComputeWorkgroupSizeZ";
                    assert(it.offset_in_bytes == 140, "WGPULimits.maxComputeWorkgroupSizeZ has unexpected offset % instead of 140", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxComputeWorkgroupSizeZ has unexpected size % instead of 4", it.type.runtime_size);
                case "maxComputeWorkgroupsPerDimension";
                    assert(it.offset_in_bytes == 144, "WGPULimits.maxComputeWorkgroupsPerDimension has unexpected offset % instead of 144", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPULimits.maxComputeWorkgroupsPerDimension has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPULimits) == 152, "WGPULimits has size % instead of 152", size_of(WGPULimits));
    }

    {
        info := type_info(WGPUMultisampleState);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUMultisampleState.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUMultisampleState.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "count";
                    assert(it.offset_in_bytes == 8, "WGPUMultisampleState.count has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUMultisampleState.count has unexpected size % instead of 4", it.type.runtime_size);
                case "mask";
                    assert(it.offset_in_bytes == 12, "WGPUMultisampleState.mask has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUMultisampleState.mask has unexpected size % instead of 4", it.type.runtime_size);
                case "alphaToCoverageEnabled";
                    assert(it.offset_in_bytes == 16, "WGPUMultisampleState.alphaToCoverageEnabled has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUMultisampleState.alphaToCoverageEnabled has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUMultisampleState) == 24, "WGPUMultisampleState has size % instead of 24", size_of(WGPUMultisampleState));
    }

    {
        info := type_info(WGPUOrigin3D);
        for info.members {
            if it.name == {
                case "x";
                    assert(it.offset_in_bytes == 0, "WGPUOrigin3D.x has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUOrigin3D.x has unexpected size % instead of 4", it.type.runtime_size);
                case "y";
                    assert(it.offset_in_bytes == 4, "WGPUOrigin3D.y has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUOrigin3D.y has unexpected size % instead of 4", it.type.runtime_size);
                case "z";
                    assert(it.offset_in_bytes == 8, "WGPUOrigin3D.z has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUOrigin3D.z has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUOrigin3D) == 12, "WGPUOrigin3D has size % instead of 12", size_of(WGPUOrigin3D));
    }

    {
        info := type_info(WGPUPipelineLayoutDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUPipelineLayoutDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPipelineLayoutDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUPipelineLayoutDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUPipelineLayoutDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "bindGroupLayoutCount";
                    assert(it.offset_in_bytes == 24, "WGPUPipelineLayoutDescriptor.bindGroupLayoutCount has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPipelineLayoutDescriptor.bindGroupLayoutCount has unexpected size % instead of 8", it.type.runtime_size);
                case "bindGroupLayouts";
                    assert(it.offset_in_bytes == 32, "WGPUPipelineLayoutDescriptor.bindGroupLayouts has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPipelineLayoutDescriptor.bindGroupLayouts has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUPipelineLayoutDescriptor) == 40, "WGPUPipelineLayoutDescriptor has size % instead of 40", size_of(WGPUPipelineLayoutDescriptor));
    }

    {
        info := type_info(WGPUPrimitiveState);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUPrimitiveState.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPrimitiveState.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "topology";
                    assert(it.offset_in_bytes == 8, "WGPUPrimitiveState.topology has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUPrimitiveState.topology has unexpected size % instead of 4", it.type.runtime_size);
                case "stripIndexFormat";
                    assert(it.offset_in_bytes == 12, "WGPUPrimitiveState.stripIndexFormat has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUPrimitiveState.stripIndexFormat has unexpected size % instead of 4", it.type.runtime_size);
                case "frontFace";
                    assert(it.offset_in_bytes == 16, "WGPUPrimitiveState.frontFace has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUPrimitiveState.frontFace has unexpected size % instead of 4", it.type.runtime_size);
                case "cullMode";
                    assert(it.offset_in_bytes == 20, "WGPUPrimitiveState.cullMode has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUPrimitiveState.cullMode has unexpected size % instead of 4", it.type.runtime_size);
                case "unclippedDepth";
                    assert(it.offset_in_bytes == 24, "WGPUPrimitiveState.unclippedDepth has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUPrimitiveState.unclippedDepth has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUPrimitiveState) == 32, "WGPUPrimitiveState has size % instead of 32", size_of(WGPUPrimitiveState));
    }

    {
        info := type_info(WGPUQuerySetDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUQuerySetDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUQuerySetDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUQuerySetDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUQuerySetDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "type";
                    assert(it.offset_in_bytes == 24, "WGPUQuerySetDescriptor.type has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUQuerySetDescriptor.type has unexpected size % instead of 4", it.type.runtime_size);
                case "count";
                    assert(it.offset_in_bytes == 28, "WGPUQuerySetDescriptor.count has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUQuerySetDescriptor.count has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUQuerySetDescriptor) == 32, "WGPUQuerySetDescriptor has size % instead of 32", size_of(WGPUQuerySetDescriptor));
    }

    {
        info := type_info(WGPUQueueDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUQueueDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUQueueDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUQueueDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUQueueDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUQueueDescriptor) == 24, "WGPUQueueDescriptor has size % instead of 24", size_of(WGPUQueueDescriptor));
    }

    {
        info := type_info(WGPURenderBundleDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPURenderBundleDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderBundleDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPURenderBundleDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPURenderBundleDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURenderBundleDescriptor) == 24, "WGPURenderBundleDescriptor has size % instead of 24", size_of(WGPURenderBundleDescriptor));
    }

    {
        info := type_info(WGPURenderBundleEncoderDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPURenderBundleEncoderDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderBundleEncoderDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPURenderBundleEncoderDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPURenderBundleEncoderDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "colorFormatCount";
                    assert(it.offset_in_bytes == 24, "WGPURenderBundleEncoderDescriptor.colorFormatCount has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderBundleEncoderDescriptor.colorFormatCount has unexpected size % instead of 8", it.type.runtime_size);
                case "colorFormats";
                    assert(it.offset_in_bytes == 32, "WGPURenderBundleEncoderDescriptor.colorFormats has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderBundleEncoderDescriptor.colorFormats has unexpected size % instead of 8", it.type.runtime_size);
                case "depthStencilFormat";
                    assert(it.offset_in_bytes == 40, "WGPURenderBundleEncoderDescriptor.depthStencilFormat has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderBundleEncoderDescriptor.depthStencilFormat has unexpected size % instead of 4", it.type.runtime_size);
                case "sampleCount";
                    assert(it.offset_in_bytes == 44, "WGPURenderBundleEncoderDescriptor.sampleCount has unexpected offset % instead of 44", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderBundleEncoderDescriptor.sampleCount has unexpected size % instead of 4", it.type.runtime_size);
                case "depthReadOnly";
                    assert(it.offset_in_bytes == 48, "WGPURenderBundleEncoderDescriptor.depthReadOnly has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderBundleEncoderDescriptor.depthReadOnly has unexpected size % instead of 4", it.type.runtime_size);
                case "stencilReadOnly";
                    assert(it.offset_in_bytes == 52, "WGPURenderBundleEncoderDescriptor.stencilReadOnly has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderBundleEncoderDescriptor.stencilReadOnly has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURenderBundleEncoderDescriptor) == 56, "WGPURenderBundleEncoderDescriptor has size % instead of 56", size_of(WGPURenderBundleEncoderDescriptor));
    }

    {
        info := type_info(WGPURenderPassDepthStencilAttachment);
        for info.members {
            if it.name == {
                case "view";
                    assert(it.offset_in_bytes == 0, "WGPURenderPassDepthStencilAttachment.view has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassDepthStencilAttachment.view has unexpected size % instead of 8", it.type.runtime_size);
                case "depthLoadOp";
                    assert(it.offset_in_bytes == 8, "WGPURenderPassDepthStencilAttachment.depthLoadOp has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassDepthStencilAttachment.depthLoadOp has unexpected size % instead of 4", it.type.runtime_size);
                case "depthStoreOp";
                    assert(it.offset_in_bytes == 12, "WGPURenderPassDepthStencilAttachment.depthStoreOp has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassDepthStencilAttachment.depthStoreOp has unexpected size % instead of 4", it.type.runtime_size);
                case "depthClearValue";
                    assert(it.offset_in_bytes == 16, "WGPURenderPassDepthStencilAttachment.depthClearValue has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassDepthStencilAttachment.depthClearValue has unexpected size % instead of 4", it.type.runtime_size);
                case "depthReadOnly";
                    assert(it.offset_in_bytes == 20, "WGPURenderPassDepthStencilAttachment.depthReadOnly has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassDepthStencilAttachment.depthReadOnly has unexpected size % instead of 4", it.type.runtime_size);
                case "stencilLoadOp";
                    assert(it.offset_in_bytes == 24, "WGPURenderPassDepthStencilAttachment.stencilLoadOp has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassDepthStencilAttachment.stencilLoadOp has unexpected size % instead of 4", it.type.runtime_size);
                case "stencilStoreOp";
                    assert(it.offset_in_bytes == 28, "WGPURenderPassDepthStencilAttachment.stencilStoreOp has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassDepthStencilAttachment.stencilStoreOp has unexpected size % instead of 4", it.type.runtime_size);
                case "stencilClearValue";
                    assert(it.offset_in_bytes == 32, "WGPURenderPassDepthStencilAttachment.stencilClearValue has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassDepthStencilAttachment.stencilClearValue has unexpected size % instead of 4", it.type.runtime_size);
                case "stencilReadOnly";
                    assert(it.offset_in_bytes == 36, "WGPURenderPassDepthStencilAttachment.stencilReadOnly has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassDepthStencilAttachment.stencilReadOnly has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURenderPassDepthStencilAttachment) == 40, "WGPURenderPassDepthStencilAttachment has size % instead of 40", size_of(WGPURenderPassDepthStencilAttachment));
    }

    {
        info := type_info(WGPURenderPassMaxDrawCount);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPURenderPassMaxDrawCount.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPURenderPassMaxDrawCount.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "maxDrawCount";
                    assert(it.offset_in_bytes == 16, "WGPURenderPassMaxDrawCount.maxDrawCount has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassMaxDrawCount.maxDrawCount has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURenderPassMaxDrawCount) == 24, "WGPURenderPassMaxDrawCount has size % instead of 24", size_of(WGPURenderPassMaxDrawCount));
    }

    {
        info := type_info(WGPURenderPassTimestampWrites);
        for info.members {
            if it.name == {
                case "querySet";
                    assert(it.offset_in_bytes == 0, "WGPURenderPassTimestampWrites.querySet has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassTimestampWrites.querySet has unexpected size % instead of 8", it.type.runtime_size);
                case "beginningOfPassWriteIndex";
                    assert(it.offset_in_bytes == 8, "WGPURenderPassTimestampWrites.beginningOfPassWriteIndex has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassTimestampWrites.beginningOfPassWriteIndex has unexpected size % instead of 4", it.type.runtime_size);
                case "endOfPassWriteIndex";
                    assert(it.offset_in_bytes == 12, "WGPURenderPassTimestampWrites.endOfPassWriteIndex has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassTimestampWrites.endOfPassWriteIndex has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURenderPassTimestampWrites) == 16, "WGPURenderPassTimestampWrites has size % instead of 16", size_of(WGPURenderPassTimestampWrites));
    }

    {
        info := type_info(WGPURequestAdapterOptions);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPURequestAdapterOptions.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURequestAdapterOptions.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "featureLevel";
                    assert(it.offset_in_bytes == 8, "WGPURequestAdapterOptions.featureLevel has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURequestAdapterOptions.featureLevel has unexpected size % instead of 4", it.type.runtime_size);
                case "powerPreference";
                    assert(it.offset_in_bytes == 12, "WGPURequestAdapterOptions.powerPreference has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURequestAdapterOptions.powerPreference has unexpected size % instead of 4", it.type.runtime_size);
                case "forceFallbackAdapter";
                    assert(it.offset_in_bytes == 16, "WGPURequestAdapterOptions.forceFallbackAdapter has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURequestAdapterOptions.forceFallbackAdapter has unexpected size % instead of 4", it.type.runtime_size);
                case "backendType";
                    assert(it.offset_in_bytes == 20, "WGPURequestAdapterOptions.backendType has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURequestAdapterOptions.backendType has unexpected size % instead of 4", it.type.runtime_size);
                case "compatibleSurface";
                    assert(it.offset_in_bytes == 24, "WGPURequestAdapterOptions.compatibleSurface has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURequestAdapterOptions.compatibleSurface has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURequestAdapterOptions) == 32, "WGPURequestAdapterOptions has size % instead of 32", size_of(WGPURequestAdapterOptions));
    }

    {
        info := type_info(WGPUSamplerBindingLayout);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUSamplerBindingLayout.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSamplerBindingLayout.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "type";
                    assert(it.offset_in_bytes == 8, "WGPUSamplerBindingLayout.type has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSamplerBindingLayout.type has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSamplerBindingLayout) == 16, "WGPUSamplerBindingLayout has size % instead of 16", size_of(WGPUSamplerBindingLayout));
    }

    {
        info := type_info(WGPUSamplerDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUSamplerDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSamplerDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUSamplerDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUSamplerDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "addressModeU";
                    assert(it.offset_in_bytes == 24, "WGPUSamplerDescriptor.addressModeU has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSamplerDescriptor.addressModeU has unexpected size % instead of 4", it.type.runtime_size);
                case "addressModeV";
                    assert(it.offset_in_bytes == 28, "WGPUSamplerDescriptor.addressModeV has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSamplerDescriptor.addressModeV has unexpected size % instead of 4", it.type.runtime_size);
                case "addressModeW";
                    assert(it.offset_in_bytes == 32, "WGPUSamplerDescriptor.addressModeW has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSamplerDescriptor.addressModeW has unexpected size % instead of 4", it.type.runtime_size);
                case "magFilter";
                    assert(it.offset_in_bytes == 36, "WGPUSamplerDescriptor.magFilter has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSamplerDescriptor.magFilter has unexpected size % instead of 4", it.type.runtime_size);
                case "minFilter";
                    assert(it.offset_in_bytes == 40, "WGPUSamplerDescriptor.minFilter has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSamplerDescriptor.minFilter has unexpected size % instead of 4", it.type.runtime_size);
                case "mipmapFilter";
                    assert(it.offset_in_bytes == 44, "WGPUSamplerDescriptor.mipmapFilter has unexpected offset % instead of 44", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSamplerDescriptor.mipmapFilter has unexpected size % instead of 4", it.type.runtime_size);
                case "lodMinClamp";
                    assert(it.offset_in_bytes == 48, "WGPUSamplerDescriptor.lodMinClamp has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSamplerDescriptor.lodMinClamp has unexpected size % instead of 4", it.type.runtime_size);
                case "lodMaxClamp";
                    assert(it.offset_in_bytes == 52, "WGPUSamplerDescriptor.lodMaxClamp has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSamplerDescriptor.lodMaxClamp has unexpected size % instead of 4", it.type.runtime_size);
                case "compare";
                    assert(it.offset_in_bytes == 56, "WGPUSamplerDescriptor.compare has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSamplerDescriptor.compare has unexpected size % instead of 4", it.type.runtime_size);
                case "maxAnisotropy";
                    assert(it.offset_in_bytes == 60, "WGPUSamplerDescriptor.maxAnisotropy has unexpected offset % instead of 60", it.offset_in_bytes);
                    assert(it.type.runtime_size == 2, "WGPUSamplerDescriptor.maxAnisotropy has unexpected size % instead of 2", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSamplerDescriptor) == 64, "WGPUSamplerDescriptor has size % instead of 64", size_of(WGPUSamplerDescriptor));
    }

    {
        info := type_info(WGPUShaderModuleDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUShaderModuleDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUShaderModuleDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUShaderModuleDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUShaderModuleDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUShaderModuleDescriptor) == 24, "WGPUShaderModuleDescriptor has size % instead of 24", size_of(WGPUShaderModuleDescriptor));
    }

    {
        info := type_info(WGPUShaderSourceSPIRV);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUShaderSourceSPIRV.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUShaderSourceSPIRV.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "codeSize";
                    assert(it.offset_in_bytes == 16, "WGPUShaderSourceSPIRV.codeSize has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUShaderSourceSPIRV.codeSize has unexpected size % instead of 4", it.type.runtime_size);
                case "code";
                    assert(it.offset_in_bytes == 24, "WGPUShaderSourceSPIRV.code has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUShaderSourceSPIRV.code has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUShaderSourceSPIRV) == 32, "WGPUShaderSourceSPIRV has size % instead of 32", size_of(WGPUShaderSourceSPIRV));
    }

    {
        info := type_info(WGPUShaderSourceWGSL);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUShaderSourceWGSL.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUShaderSourceWGSL.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "code";
                    assert(it.offset_in_bytes == 16, "WGPUShaderSourceWGSL.code has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUShaderSourceWGSL.code has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUShaderSourceWGSL) == 32, "WGPUShaderSourceWGSL has size % instead of 32", size_of(WGPUShaderSourceWGSL));
    }

    {
        info := type_info(WGPUStencilFaceState);
        for info.members {
            if it.name == {
                case "compare";
                    assert(it.offset_in_bytes == 0, "WGPUStencilFaceState.compare has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUStencilFaceState.compare has unexpected size % instead of 4", it.type.runtime_size);
                case "failOp";
                    assert(it.offset_in_bytes == 4, "WGPUStencilFaceState.failOp has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUStencilFaceState.failOp has unexpected size % instead of 4", it.type.runtime_size);
                case "depthFailOp";
                    assert(it.offset_in_bytes == 8, "WGPUStencilFaceState.depthFailOp has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUStencilFaceState.depthFailOp has unexpected size % instead of 4", it.type.runtime_size);
                case "passOp";
                    assert(it.offset_in_bytes == 12, "WGPUStencilFaceState.passOp has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUStencilFaceState.passOp has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUStencilFaceState) == 16, "WGPUStencilFaceState has size % instead of 16", size_of(WGPUStencilFaceState));
    }

    {
        info := type_info(WGPUStorageTextureBindingLayout);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUStorageTextureBindingLayout.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUStorageTextureBindingLayout.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "access";
                    assert(it.offset_in_bytes == 8, "WGPUStorageTextureBindingLayout.access has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUStorageTextureBindingLayout.access has unexpected size % instead of 4", it.type.runtime_size);
                case "format";
                    assert(it.offset_in_bytes == 12, "WGPUStorageTextureBindingLayout.format has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUStorageTextureBindingLayout.format has unexpected size % instead of 4", it.type.runtime_size);
                case "viewDimension";
                    assert(it.offset_in_bytes == 16, "WGPUStorageTextureBindingLayout.viewDimension has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUStorageTextureBindingLayout.viewDimension has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUStorageTextureBindingLayout) == 24, "WGPUStorageTextureBindingLayout has size % instead of 24", size_of(WGPUStorageTextureBindingLayout));
    }

    {
        info := type_info(WGPUSupportedFeatures);
        for info.members {
            if it.name == {
                case "featureCount";
                    assert(it.offset_in_bytes == 0, "WGPUSupportedFeatures.featureCount has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSupportedFeatures.featureCount has unexpected size % instead of 8", it.type.runtime_size);
                case "features";
                    assert(it.offset_in_bytes == 8, "WGPUSupportedFeatures.features has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSupportedFeatures.features has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSupportedFeatures) == 16, "WGPUSupportedFeatures has size % instead of 16", size_of(WGPUSupportedFeatures));
    }

    {
        info := type_info(WGPUSupportedWGSLLanguageFeatures);
        for info.members {
            if it.name == {
                case "featureCount";
                    assert(it.offset_in_bytes == 0, "WGPUSupportedWGSLLanguageFeatures.featureCount has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSupportedWGSLLanguageFeatures.featureCount has unexpected size % instead of 8", it.type.runtime_size);
                case "features";
                    assert(it.offset_in_bytes == 8, "WGPUSupportedWGSLLanguageFeatures.features has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSupportedWGSLLanguageFeatures.features has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSupportedWGSLLanguageFeatures) == 16, "WGPUSupportedWGSLLanguageFeatures has size % instead of 16", size_of(WGPUSupportedWGSLLanguageFeatures));
    }

    {
        info := type_info(WGPUSurfaceCapabilities);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceCapabilities.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceCapabilities.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "usages";
                    assert(it.offset_in_bytes == 8, "WGPUSurfaceCapabilities.usages has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceCapabilities.usages has unexpected size % instead of 8", it.type.runtime_size);
                case "formatCount";
                    assert(it.offset_in_bytes == 16, "WGPUSurfaceCapabilities.formatCount has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceCapabilities.formatCount has unexpected size % instead of 8", it.type.runtime_size);
                case "formats";
                    assert(it.offset_in_bytes == 24, "WGPUSurfaceCapabilities.formats has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceCapabilities.formats has unexpected size % instead of 8", it.type.runtime_size);
                case "presentModeCount";
                    assert(it.offset_in_bytes == 32, "WGPUSurfaceCapabilities.presentModeCount has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceCapabilities.presentModeCount has unexpected size % instead of 8", it.type.runtime_size);
                case "presentModes";
                    assert(it.offset_in_bytes == 40, "WGPUSurfaceCapabilities.presentModes has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceCapabilities.presentModes has unexpected size % instead of 8", it.type.runtime_size);
                case "alphaModeCount";
                    assert(it.offset_in_bytes == 48, "WGPUSurfaceCapabilities.alphaModeCount has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceCapabilities.alphaModeCount has unexpected size % instead of 8", it.type.runtime_size);
                case "alphaModes";
                    assert(it.offset_in_bytes == 56, "WGPUSurfaceCapabilities.alphaModes has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceCapabilities.alphaModes has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceCapabilities) == 64, "WGPUSurfaceCapabilities has size % instead of 64", size_of(WGPUSurfaceCapabilities));
    }

    {
        info := type_info(WGPUSurfaceConfiguration);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceConfiguration.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceConfiguration.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "device";
                    assert(it.offset_in_bytes == 8, "WGPUSurfaceConfiguration.device has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceConfiguration.device has unexpected size % instead of 8", it.type.runtime_size);
                case "format";
                    assert(it.offset_in_bytes == 16, "WGPUSurfaceConfiguration.format has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSurfaceConfiguration.format has unexpected size % instead of 4", it.type.runtime_size);
                case "usage";
                    assert(it.offset_in_bytes == 24, "WGPUSurfaceConfiguration.usage has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceConfiguration.usage has unexpected size % instead of 8", it.type.runtime_size);
                case "width";
                    assert(it.offset_in_bytes == 32, "WGPUSurfaceConfiguration.width has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSurfaceConfiguration.width has unexpected size % instead of 4", it.type.runtime_size);
                case "height";
                    assert(it.offset_in_bytes == 36, "WGPUSurfaceConfiguration.height has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSurfaceConfiguration.height has unexpected size % instead of 4", it.type.runtime_size);
                case "viewFormatCount";
                    assert(it.offset_in_bytes == 40, "WGPUSurfaceConfiguration.viewFormatCount has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceConfiguration.viewFormatCount has unexpected size % instead of 8", it.type.runtime_size);
                case "viewFormats";
                    assert(it.offset_in_bytes == 48, "WGPUSurfaceConfiguration.viewFormats has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceConfiguration.viewFormats has unexpected size % instead of 8", it.type.runtime_size);
                case "alphaMode";
                    assert(it.offset_in_bytes == 56, "WGPUSurfaceConfiguration.alphaMode has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSurfaceConfiguration.alphaMode has unexpected size % instead of 4", it.type.runtime_size);
                case "presentMode";
                    assert(it.offset_in_bytes == 60, "WGPUSurfaceConfiguration.presentMode has unexpected offset % instead of 60", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSurfaceConfiguration.presentMode has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceConfiguration) == 64, "WGPUSurfaceConfiguration has size % instead of 64", size_of(WGPUSurfaceConfiguration));
    }

    {
        info := type_info(WGPUSurfaceDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUSurfaceDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUSurfaceDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceDescriptor) == 24, "WGPUSurfaceDescriptor has size % instead of 24", size_of(WGPUSurfaceDescriptor));
    }

    {
        info := type_info(WGPUSurfaceSourceAndroidNativeWindow);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceSourceAndroidNativeWindow.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUSurfaceSourceAndroidNativeWindow.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "window";
                    assert(it.offset_in_bytes == 16, "WGPUSurfaceSourceAndroidNativeWindow.window has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceSourceAndroidNativeWindow.window has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceSourceAndroidNativeWindow) == 24, "WGPUSurfaceSourceAndroidNativeWindow has size % instead of 24", size_of(WGPUSurfaceSourceAndroidNativeWindow));
    }

    {
        info := type_info(WGPUSurfaceSourceMetalLayer);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceSourceMetalLayer.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUSurfaceSourceMetalLayer.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "layer";
                    assert(it.offset_in_bytes == 16, "WGPUSurfaceSourceMetalLayer.layer has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceSourceMetalLayer.layer has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceSourceMetalLayer) == 24, "WGPUSurfaceSourceMetalLayer has size % instead of 24", size_of(WGPUSurfaceSourceMetalLayer));
    }

    {
        info := type_info(WGPUSurfaceSourceWaylandSurface);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceSourceWaylandSurface.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUSurfaceSourceWaylandSurface.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "display";
                    assert(it.offset_in_bytes == 16, "WGPUSurfaceSourceWaylandSurface.display has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceSourceWaylandSurface.display has unexpected size % instead of 8", it.type.runtime_size);
                case "surface";
                    assert(it.offset_in_bytes == 24, "WGPUSurfaceSourceWaylandSurface.surface has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceSourceWaylandSurface.surface has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceSourceWaylandSurface) == 32, "WGPUSurfaceSourceWaylandSurface has size % instead of 32", size_of(WGPUSurfaceSourceWaylandSurface));
    }

    {
        info := type_info(WGPUSurfaceSourceWindowsHWND);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceSourceWindowsHWND.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUSurfaceSourceWindowsHWND.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "hinstance";
                    assert(it.offset_in_bytes == 16, "WGPUSurfaceSourceWindowsHWND.hinstance has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceSourceWindowsHWND.hinstance has unexpected size % instead of 8", it.type.runtime_size);
                case "hwnd";
                    assert(it.offset_in_bytes == 24, "WGPUSurfaceSourceWindowsHWND.hwnd has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceSourceWindowsHWND.hwnd has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceSourceWindowsHWND) == 32, "WGPUSurfaceSourceWindowsHWND has size % instead of 32", size_of(WGPUSurfaceSourceWindowsHWND));
    }

    {
        info := type_info(WGPUSurfaceSourceXCBWindow);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceSourceXCBWindow.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUSurfaceSourceXCBWindow.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "connection";
                    assert(it.offset_in_bytes == 16, "WGPUSurfaceSourceXCBWindow.connection has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceSourceXCBWindow.connection has unexpected size % instead of 8", it.type.runtime_size);
                case "window";
                    assert(it.offset_in_bytes == 24, "WGPUSurfaceSourceXCBWindow.window has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSurfaceSourceXCBWindow.window has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceSourceXCBWindow) == 32, "WGPUSurfaceSourceXCBWindow has size % instead of 32", size_of(WGPUSurfaceSourceXCBWindow));
    }

    {
        info := type_info(WGPUSurfaceSourceXlibWindow);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceSourceXlibWindow.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUSurfaceSourceXlibWindow.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "display";
                    assert(it.offset_in_bytes == 16, "WGPUSurfaceSourceXlibWindow.display has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceSourceXlibWindow.display has unexpected size % instead of 8", it.type.runtime_size);
                case "window";
                    assert(it.offset_in_bytes == 24, "WGPUSurfaceSourceXlibWindow.window has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceSourceXlibWindow.window has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceSourceXlibWindow) == 32, "WGPUSurfaceSourceXlibWindow has size % instead of 32", size_of(WGPUSurfaceSourceXlibWindow));
    }

    {
        info := type_info(WGPUSurfaceTexture);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceTexture.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceTexture.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "texture";
                    assert(it.offset_in_bytes == 8, "WGPUSurfaceTexture.texture has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUSurfaceTexture.texture has unexpected size % instead of 8", it.type.runtime_size);
                case "status";
                    assert(it.offset_in_bytes == 16, "WGPUSurfaceTexture.status has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSurfaceTexture.status has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceTexture) == 24, "WGPUSurfaceTexture has size % instead of 24", size_of(WGPUSurfaceTexture));
    }

    {
        info := type_info(WGPUTexelCopyBufferLayout);
        for info.members {
            if it.name == {
                case "offset";
                    assert(it.offset_in_bytes == 0, "WGPUTexelCopyBufferLayout.offset has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUTexelCopyBufferLayout.offset has unexpected size % instead of 8", it.type.runtime_size);
                case "bytesPerRow";
                    assert(it.offset_in_bytes == 8, "WGPUTexelCopyBufferLayout.bytesPerRow has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTexelCopyBufferLayout.bytesPerRow has unexpected size % instead of 4", it.type.runtime_size);
                case "rowsPerImage";
                    assert(it.offset_in_bytes == 12, "WGPUTexelCopyBufferLayout.rowsPerImage has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTexelCopyBufferLayout.rowsPerImage has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUTexelCopyBufferLayout) == 16, "WGPUTexelCopyBufferLayout has size % instead of 16", size_of(WGPUTexelCopyBufferLayout));
    }

    {
        info := type_info(WGPUTextureBindingLayout);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUTextureBindingLayout.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUTextureBindingLayout.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "sampleType";
                    assert(it.offset_in_bytes == 8, "WGPUTextureBindingLayout.sampleType has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureBindingLayout.sampleType has unexpected size % instead of 4", it.type.runtime_size);
                case "viewDimension";
                    assert(it.offset_in_bytes == 12, "WGPUTextureBindingLayout.viewDimension has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureBindingLayout.viewDimension has unexpected size % instead of 4", it.type.runtime_size);
                case "multisampled";
                    assert(it.offset_in_bytes == 16, "WGPUTextureBindingLayout.multisampled has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureBindingLayout.multisampled has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUTextureBindingLayout) == 24, "WGPUTextureBindingLayout has size % instead of 24", size_of(WGPUTextureBindingLayout));
    }

    {
        info := type_info(WGPUTextureViewDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUTextureViewDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUTextureViewDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUTextureViewDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUTextureViewDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "format";
                    assert(it.offset_in_bytes == 24, "WGPUTextureViewDescriptor.format has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureViewDescriptor.format has unexpected size % instead of 4", it.type.runtime_size);
                case "dimension";
                    assert(it.offset_in_bytes == 28, "WGPUTextureViewDescriptor.dimension has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureViewDescriptor.dimension has unexpected size % instead of 4", it.type.runtime_size);
                case "baseMipLevel";
                    assert(it.offset_in_bytes == 32, "WGPUTextureViewDescriptor.baseMipLevel has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureViewDescriptor.baseMipLevel has unexpected size % instead of 4", it.type.runtime_size);
                case "mipLevelCount";
                    assert(it.offset_in_bytes == 36, "WGPUTextureViewDescriptor.mipLevelCount has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureViewDescriptor.mipLevelCount has unexpected size % instead of 4", it.type.runtime_size);
                case "baseArrayLayer";
                    assert(it.offset_in_bytes == 40, "WGPUTextureViewDescriptor.baseArrayLayer has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureViewDescriptor.baseArrayLayer has unexpected size % instead of 4", it.type.runtime_size);
                case "arrayLayerCount";
                    assert(it.offset_in_bytes == 44, "WGPUTextureViewDescriptor.arrayLayerCount has unexpected offset % instead of 44", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureViewDescriptor.arrayLayerCount has unexpected size % instead of 4", it.type.runtime_size);
                case "aspect";
                    assert(it.offset_in_bytes == 48, "WGPUTextureViewDescriptor.aspect has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureViewDescriptor.aspect has unexpected size % instead of 4", it.type.runtime_size);
                case "usage";
                    assert(it.offset_in_bytes == 56, "WGPUTextureViewDescriptor.usage has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUTextureViewDescriptor.usage has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUTextureViewDescriptor) == 64, "WGPUTextureViewDescriptor has size % instead of 64", size_of(WGPUTextureViewDescriptor));
    }

    {
        info := type_info(WGPUVertexAttribute);
        for info.members {
            if it.name == {
                case "format";
                    assert(it.offset_in_bytes == 0, "WGPUVertexAttribute.format has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUVertexAttribute.format has unexpected size % instead of 4", it.type.runtime_size);
                case "offset";
                    assert(it.offset_in_bytes == 8, "WGPUVertexAttribute.offset has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUVertexAttribute.offset has unexpected size % instead of 8", it.type.runtime_size);
                case "shaderLocation";
                    assert(it.offset_in_bytes == 16, "WGPUVertexAttribute.shaderLocation has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUVertexAttribute.shaderLocation has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUVertexAttribute) == 24, "WGPUVertexAttribute has size % instead of 24", size_of(WGPUVertexAttribute));
    }

    {
        info := type_info(WGPUBindGroupDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUBindGroupDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUBindGroupDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUBindGroupDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "layout";
                    assert(it.offset_in_bytes == 24, "WGPUBindGroupDescriptor.layout has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupDescriptor.layout has unexpected size % instead of 8", it.type.runtime_size);
                case "entryCount";
                    assert(it.offset_in_bytes == 32, "WGPUBindGroupDescriptor.entryCount has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupDescriptor.entryCount has unexpected size % instead of 8", it.type.runtime_size);
                case "entries";
                    assert(it.offset_in_bytes == 40, "WGPUBindGroupDescriptor.entries has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupDescriptor.entries has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBindGroupDescriptor) == 48, "WGPUBindGroupDescriptor has size % instead of 48", size_of(WGPUBindGroupDescriptor));
    }

    {
        info := type_info(WGPUBindGroupLayoutEntry);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUBindGroupLayoutEntry.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupLayoutEntry.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "binding";
                    assert(it.offset_in_bytes == 8, "WGPUBindGroupLayoutEntry.binding has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUBindGroupLayoutEntry.binding has unexpected size % instead of 4", it.type.runtime_size);
                case "visibility";
                    assert(it.offset_in_bytes == 16, "WGPUBindGroupLayoutEntry.visibility has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupLayoutEntry.visibility has unexpected size % instead of 8", it.type.runtime_size);
                case "buffer";
                    assert(it.offset_in_bytes == 24, "WGPUBindGroupLayoutEntry.buffer has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "WGPUBindGroupLayoutEntry.buffer has unexpected size % instead of 24", it.type.runtime_size);
                case "sampler";
                    assert(it.offset_in_bytes == 48, "WGPUBindGroupLayoutEntry.sampler has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUBindGroupLayoutEntry.sampler has unexpected size % instead of 16", it.type.runtime_size);
                case "texture";
                    assert(it.offset_in_bytes == 64, "WGPUBindGroupLayoutEntry.texture has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "WGPUBindGroupLayoutEntry.texture has unexpected size % instead of 24", it.type.runtime_size);
                case "storageTexture";
                    assert(it.offset_in_bytes == 88, "WGPUBindGroupLayoutEntry.storageTexture has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "WGPUBindGroupLayoutEntry.storageTexture has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBindGroupLayoutEntry) == 112, "WGPUBindGroupLayoutEntry has size % instead of 112", size_of(WGPUBindGroupLayoutEntry));
    }

    {
        info := type_info(WGPUBlendState);
        for info.members {
            if it.name == {
                case "color";
                    assert(it.offset_in_bytes == 0, "WGPUBlendState.color has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "WGPUBlendState.color has unexpected size % instead of 12", it.type.runtime_size);
                case "alpha";
                    assert(it.offset_in_bytes == 12, "WGPUBlendState.alpha has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "WGPUBlendState.alpha has unexpected size % instead of 12", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBlendState) == 24, "WGPUBlendState has size % instead of 24", size_of(WGPUBlendState));
    }

    {
        info := type_info(WGPUCompilationInfo);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUCompilationInfo.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationInfo.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "messageCount";
                    assert(it.offset_in_bytes == 8, "WGPUCompilationInfo.messageCount has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationInfo.messageCount has unexpected size % instead of 8", it.type.runtime_size);
                case "messages";
                    assert(it.offset_in_bytes == 16, "WGPUCompilationInfo.messages has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUCompilationInfo.messages has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUCompilationInfo) == 24, "WGPUCompilationInfo has size % instead of 24", size_of(WGPUCompilationInfo));
    }

    {
        info := type_info(WGPUComputePassDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUComputePassDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUComputePassDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUComputePassDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUComputePassDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "timestampWrites";
                    assert(it.offset_in_bytes == 24, "WGPUComputePassDescriptor.timestampWrites has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUComputePassDescriptor.timestampWrites has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUComputePassDescriptor) == 32, "WGPUComputePassDescriptor has size % instead of 32", size_of(WGPUComputePassDescriptor));
    }

    {
        info := type_info(WGPUDepthStencilState);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUDepthStencilState.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUDepthStencilState.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "format";
                    assert(it.offset_in_bytes == 8, "WGPUDepthStencilState.format has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUDepthStencilState.format has unexpected size % instead of 4", it.type.runtime_size);
                case "depthWriteEnabled";
                    assert(it.offset_in_bytes == 12, "WGPUDepthStencilState.depthWriteEnabled has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUDepthStencilState.depthWriteEnabled has unexpected size % instead of 4", it.type.runtime_size);
                case "depthCompare";
                    assert(it.offset_in_bytes == 16, "WGPUDepthStencilState.depthCompare has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUDepthStencilState.depthCompare has unexpected size % instead of 4", it.type.runtime_size);
                case "stencilFront";
                    assert(it.offset_in_bytes == 20, "WGPUDepthStencilState.stencilFront has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUDepthStencilState.stencilFront has unexpected size % instead of 16", it.type.runtime_size);
                case "stencilBack";
                    assert(it.offset_in_bytes == 36, "WGPUDepthStencilState.stencilBack has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUDepthStencilState.stencilBack has unexpected size % instead of 16", it.type.runtime_size);
                case "stencilReadMask";
                    assert(it.offset_in_bytes == 52, "WGPUDepthStencilState.stencilReadMask has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUDepthStencilState.stencilReadMask has unexpected size % instead of 4", it.type.runtime_size);
                case "stencilWriteMask";
                    assert(it.offset_in_bytes == 56, "WGPUDepthStencilState.stencilWriteMask has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUDepthStencilState.stencilWriteMask has unexpected size % instead of 4", it.type.runtime_size);
                case "depthBias";
                    assert(it.offset_in_bytes == 60, "WGPUDepthStencilState.depthBias has unexpected offset % instead of 60", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUDepthStencilState.depthBias has unexpected size % instead of 4", it.type.runtime_size);
                case "depthBiasSlopeScale";
                    assert(it.offset_in_bytes == 64, "WGPUDepthStencilState.depthBiasSlopeScale has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUDepthStencilState.depthBiasSlopeScale has unexpected size % instead of 4", it.type.runtime_size);
                case "depthBiasClamp";
                    assert(it.offset_in_bytes == 68, "WGPUDepthStencilState.depthBiasClamp has unexpected offset % instead of 68", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUDepthStencilState.depthBiasClamp has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUDepthStencilState) == 72, "WGPUDepthStencilState has size % instead of 72", size_of(WGPUDepthStencilState));
    }

    {
        info := type_info(WGPUDeviceDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUDeviceDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUDeviceDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUDeviceDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUDeviceDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "requiredFeatureCount";
                    assert(it.offset_in_bytes == 24, "WGPUDeviceDescriptor.requiredFeatureCount has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUDeviceDescriptor.requiredFeatureCount has unexpected size % instead of 8", it.type.runtime_size);
                case "requiredFeatures";
                    assert(it.offset_in_bytes == 32, "WGPUDeviceDescriptor.requiredFeatures has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUDeviceDescriptor.requiredFeatures has unexpected size % instead of 8", it.type.runtime_size);
                case "requiredLimits";
                    assert(it.offset_in_bytes == 40, "WGPUDeviceDescriptor.requiredLimits has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUDeviceDescriptor.requiredLimits has unexpected size % instead of 8", it.type.runtime_size);
                case "defaultQueue";
                    assert(it.offset_in_bytes == 48, "WGPUDeviceDescriptor.defaultQueue has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "WGPUDeviceDescriptor.defaultQueue has unexpected size % instead of 24", it.type.runtime_size);
                case "deviceLostCallbackInfo";
                    assert(it.offset_in_bytes == 72, "WGPUDeviceDescriptor.deviceLostCallbackInfo has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 40, "WGPUDeviceDescriptor.deviceLostCallbackInfo has unexpected size % instead of 40", it.type.runtime_size);
                case "uncapturedErrorCallbackInfo";
                    assert(it.offset_in_bytes == 112, "WGPUDeviceDescriptor.uncapturedErrorCallbackInfo has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUDeviceDescriptor.uncapturedErrorCallbackInfo has unexpected size % instead of 32", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUDeviceDescriptor) == 144, "WGPUDeviceDescriptor has size % instead of 144", size_of(WGPUDeviceDescriptor));
    }

    {
        info := type_info(WGPUFutureWaitInfo);
        for info.members {
            if it.name == {
                case "future";
                    assert(it.offset_in_bytes == 0, "WGPUFutureWaitInfo.future has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUFutureWaitInfo.future has unexpected size % instead of 8", it.type.runtime_size);
                case "completed";
                    assert(it.offset_in_bytes == 8, "WGPUFutureWaitInfo.completed has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUFutureWaitInfo.completed has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUFutureWaitInfo) == 16, "WGPUFutureWaitInfo has size % instead of 16", size_of(WGPUFutureWaitInfo));
    }

    {
        info := type_info(WGPUInstanceDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUInstanceDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUInstanceDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "features";
                    assert(it.offset_in_bytes == 8, "WGPUInstanceDescriptor.features has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "WGPUInstanceDescriptor.features has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUInstanceDescriptor) == 32, "WGPUInstanceDescriptor has size % instead of 32", size_of(WGPUInstanceDescriptor));
    }

    {
        info := type_info(WGPUProgrammableStageDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUProgrammableStageDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUProgrammableStageDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "module";
                    assert(it.offset_in_bytes == 8, "WGPUProgrammableStageDescriptor.module has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUProgrammableStageDescriptor.module has unexpected size % instead of 8", it.type.runtime_size);
                case "entryPoint";
                    assert(it.offset_in_bytes == 16, "WGPUProgrammableStageDescriptor.entryPoint has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUProgrammableStageDescriptor.entryPoint has unexpected size % instead of 16", it.type.runtime_size);
                case "constantCount";
                    assert(it.offset_in_bytes == 32, "WGPUProgrammableStageDescriptor.constantCount has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUProgrammableStageDescriptor.constantCount has unexpected size % instead of 8", it.type.runtime_size);
                case "constants";
                    assert(it.offset_in_bytes == 40, "WGPUProgrammableStageDescriptor.constants has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUProgrammableStageDescriptor.constants has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUProgrammableStageDescriptor) == 48, "WGPUProgrammableStageDescriptor has size % instead of 48", size_of(WGPUProgrammableStageDescriptor));
    }

    {
        info := type_info(WGPURenderPassColorAttachment);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPURenderPassColorAttachment.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassColorAttachment.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "view";
                    assert(it.offset_in_bytes == 8, "WGPURenderPassColorAttachment.view has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassColorAttachment.view has unexpected size % instead of 8", it.type.runtime_size);
                case "depthSlice";
                    assert(it.offset_in_bytes == 16, "WGPURenderPassColorAttachment.depthSlice has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassColorAttachment.depthSlice has unexpected size % instead of 4", it.type.runtime_size);
                case "resolveTarget";
                    assert(it.offset_in_bytes == 24, "WGPURenderPassColorAttachment.resolveTarget has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassColorAttachment.resolveTarget has unexpected size % instead of 8", it.type.runtime_size);
                case "loadOp";
                    assert(it.offset_in_bytes == 32, "WGPURenderPassColorAttachment.loadOp has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassColorAttachment.loadOp has unexpected size % instead of 4", it.type.runtime_size);
                case "storeOp";
                    assert(it.offset_in_bytes == 36, "WGPURenderPassColorAttachment.storeOp has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPURenderPassColorAttachment.storeOp has unexpected size % instead of 4", it.type.runtime_size);
                case "clearValue";
                    assert(it.offset_in_bytes == 40, "WGPURenderPassColorAttachment.clearValue has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPURenderPassColorAttachment.clearValue has unexpected size % instead of 32", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURenderPassColorAttachment) == 72, "WGPURenderPassColorAttachment has size % instead of 72", size_of(WGPURenderPassColorAttachment));
    }

    {
        info := type_info(WGPUTexelCopyBufferInfo);
        for info.members {
            if it.name == {
                case "layout";
                    assert(it.offset_in_bytes == 0, "WGPUTexelCopyBufferInfo.layout has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUTexelCopyBufferInfo.layout has unexpected size % instead of 16", it.type.runtime_size);
                case "buffer";
                    assert(it.offset_in_bytes == 16, "WGPUTexelCopyBufferInfo.buffer has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUTexelCopyBufferInfo.buffer has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUTexelCopyBufferInfo) == 24, "WGPUTexelCopyBufferInfo has size % instead of 24", size_of(WGPUTexelCopyBufferInfo));
    }

    {
        info := type_info(WGPUTexelCopyTextureInfo);
        for info.members {
            if it.name == {
                case "texture";
                    assert(it.offset_in_bytes == 0, "WGPUTexelCopyTextureInfo.texture has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUTexelCopyTextureInfo.texture has unexpected size % instead of 8", it.type.runtime_size);
                case "mipLevel";
                    assert(it.offset_in_bytes == 8, "WGPUTexelCopyTextureInfo.mipLevel has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTexelCopyTextureInfo.mipLevel has unexpected size % instead of 4", it.type.runtime_size);
                case "origin";
                    assert(it.offset_in_bytes == 12, "WGPUTexelCopyTextureInfo.origin has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "WGPUTexelCopyTextureInfo.origin has unexpected size % instead of 12", it.type.runtime_size);
                case "aspect";
                    assert(it.offset_in_bytes == 24, "WGPUTexelCopyTextureInfo.aspect has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTexelCopyTextureInfo.aspect has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUTexelCopyTextureInfo) == 32, "WGPUTexelCopyTextureInfo has size % instead of 32", size_of(WGPUTexelCopyTextureInfo));
    }

    {
        info := type_info(WGPUTextureDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUTextureDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUTextureDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUTextureDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUTextureDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "usage";
                    assert(it.offset_in_bytes == 24, "WGPUTextureDescriptor.usage has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUTextureDescriptor.usage has unexpected size % instead of 8", it.type.runtime_size);
                case "dimension";
                    assert(it.offset_in_bytes == 32, "WGPUTextureDescriptor.dimension has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureDescriptor.dimension has unexpected size % instead of 4", it.type.runtime_size);
                case "size";
                    assert(it.offset_in_bytes == 36, "WGPUTextureDescriptor.size has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "WGPUTextureDescriptor.size has unexpected size % instead of 12", it.type.runtime_size);
                case "format";
                    assert(it.offset_in_bytes == 48, "WGPUTextureDescriptor.format has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureDescriptor.format has unexpected size % instead of 4", it.type.runtime_size);
                case "mipLevelCount";
                    assert(it.offset_in_bytes == 52, "WGPUTextureDescriptor.mipLevelCount has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureDescriptor.mipLevelCount has unexpected size % instead of 4", it.type.runtime_size);
                case "sampleCount";
                    assert(it.offset_in_bytes == 56, "WGPUTextureDescriptor.sampleCount has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUTextureDescriptor.sampleCount has unexpected size % instead of 4", it.type.runtime_size);
                case "viewFormatCount";
                    assert(it.offset_in_bytes == 64, "WGPUTextureDescriptor.viewFormatCount has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUTextureDescriptor.viewFormatCount has unexpected size % instead of 8", it.type.runtime_size);
                case "viewFormats";
                    assert(it.offset_in_bytes == 72, "WGPUTextureDescriptor.viewFormats has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUTextureDescriptor.viewFormats has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUTextureDescriptor) == 80, "WGPUTextureDescriptor has size % instead of 80", size_of(WGPUTextureDescriptor));
    }

    {
        info := type_info(WGPUVertexBufferLayout);
        for info.members {
            if it.name == {
                case "stepMode";
                    assert(it.offset_in_bytes == 0, "WGPUVertexBufferLayout.stepMode has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUVertexBufferLayout.stepMode has unexpected size % instead of 4", it.type.runtime_size);
                case "arrayStride";
                    assert(it.offset_in_bytes == 8, "WGPUVertexBufferLayout.arrayStride has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUVertexBufferLayout.arrayStride has unexpected size % instead of 8", it.type.runtime_size);
                case "attributeCount";
                    assert(it.offset_in_bytes == 16, "WGPUVertexBufferLayout.attributeCount has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUVertexBufferLayout.attributeCount has unexpected size % instead of 8", it.type.runtime_size);
                case "attributes";
                    assert(it.offset_in_bytes == 24, "WGPUVertexBufferLayout.attributes has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUVertexBufferLayout.attributes has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUVertexBufferLayout) == 32, "WGPUVertexBufferLayout has size % instead of 32", size_of(WGPUVertexBufferLayout));
    }

    {
        info := type_info(WGPUBindGroupLayoutDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUBindGroupLayoutDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupLayoutDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUBindGroupLayoutDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUBindGroupLayoutDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "entryCount";
                    assert(it.offset_in_bytes == 24, "WGPUBindGroupLayoutDescriptor.entryCount has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupLayoutDescriptor.entryCount has unexpected size % instead of 8", it.type.runtime_size);
                case "entries";
                    assert(it.offset_in_bytes == 32, "WGPUBindGroupLayoutDescriptor.entries has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupLayoutDescriptor.entries has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBindGroupLayoutDescriptor) == 40, "WGPUBindGroupLayoutDescriptor has size % instead of 40", size_of(WGPUBindGroupLayoutDescriptor));
    }

    {
        info := type_info(WGPUColorTargetState);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUColorTargetState.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUColorTargetState.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "format";
                    assert(it.offset_in_bytes == 8, "WGPUColorTargetState.format has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUColorTargetState.format has unexpected size % instead of 4", it.type.runtime_size);
                case "blend";
                    assert(it.offset_in_bytes == 16, "WGPUColorTargetState.blend has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUColorTargetState.blend has unexpected size % instead of 8", it.type.runtime_size);
                case "writeMask";
                    assert(it.offset_in_bytes == 24, "WGPUColorTargetState.writeMask has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUColorTargetState.writeMask has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUColorTargetState) == 32, "WGPUColorTargetState has size % instead of 32", size_of(WGPUColorTargetState));
    }

    {
        info := type_info(WGPUComputePipelineDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUComputePipelineDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUComputePipelineDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPUComputePipelineDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUComputePipelineDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "layout";
                    assert(it.offset_in_bytes == 24, "WGPUComputePipelineDescriptor.layout has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUComputePipelineDescriptor.layout has unexpected size % instead of 8", it.type.runtime_size);
                case "compute";
                    assert(it.offset_in_bytes == 32, "WGPUComputePipelineDescriptor.compute has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "WGPUComputePipelineDescriptor.compute has unexpected size % instead of 48", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUComputePipelineDescriptor) == 80, "WGPUComputePipelineDescriptor has size % instead of 80", size_of(WGPUComputePipelineDescriptor));
    }

    {
        info := type_info(WGPURenderPassDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPURenderPassDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPURenderPassDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPURenderPassDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "colorAttachmentCount";
                    assert(it.offset_in_bytes == 24, "WGPURenderPassDescriptor.colorAttachmentCount has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassDescriptor.colorAttachmentCount has unexpected size % instead of 8", it.type.runtime_size);
                case "colorAttachments";
                    assert(it.offset_in_bytes == 32, "WGPURenderPassDescriptor.colorAttachments has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassDescriptor.colorAttachments has unexpected size % instead of 8", it.type.runtime_size);
                case "depthStencilAttachment";
                    assert(it.offset_in_bytes == 40, "WGPURenderPassDescriptor.depthStencilAttachment has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassDescriptor.depthStencilAttachment has unexpected size % instead of 8", it.type.runtime_size);
                case "occlusionQuerySet";
                    assert(it.offset_in_bytes == 48, "WGPURenderPassDescriptor.occlusionQuerySet has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassDescriptor.occlusionQuerySet has unexpected size % instead of 8", it.type.runtime_size);
                case "timestampWrites";
                    assert(it.offset_in_bytes == 56, "WGPURenderPassDescriptor.timestampWrites has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPassDescriptor.timestampWrites has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURenderPassDescriptor) == 64, "WGPURenderPassDescriptor has size % instead of 64", size_of(WGPURenderPassDescriptor));
    }

    {
        info := type_info(WGPUVertexState);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUVertexState.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUVertexState.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "module";
                    assert(it.offset_in_bytes == 8, "WGPUVertexState.module has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUVertexState.module has unexpected size % instead of 8", it.type.runtime_size);
                case "entryPoint";
                    assert(it.offset_in_bytes == 16, "WGPUVertexState.entryPoint has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUVertexState.entryPoint has unexpected size % instead of 16", it.type.runtime_size);
                case "constantCount";
                    assert(it.offset_in_bytes == 32, "WGPUVertexState.constantCount has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUVertexState.constantCount has unexpected size % instead of 8", it.type.runtime_size);
                case "constants";
                    assert(it.offset_in_bytes == 40, "WGPUVertexState.constants has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUVertexState.constants has unexpected size % instead of 8", it.type.runtime_size);
                case "bufferCount";
                    assert(it.offset_in_bytes == 48, "WGPUVertexState.bufferCount has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUVertexState.bufferCount has unexpected size % instead of 8", it.type.runtime_size);
                case "buffers";
                    assert(it.offset_in_bytes == 56, "WGPUVertexState.buffers has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUVertexState.buffers has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUVertexState) == 64, "WGPUVertexState has size % instead of 64", size_of(WGPUVertexState));
    }

    {
        info := type_info(WGPUFragmentState);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUFragmentState.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUFragmentState.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "module";
                    assert(it.offset_in_bytes == 8, "WGPUFragmentState.module has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUFragmentState.module has unexpected size % instead of 8", it.type.runtime_size);
                case "entryPoint";
                    assert(it.offset_in_bytes == 16, "WGPUFragmentState.entryPoint has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUFragmentState.entryPoint has unexpected size % instead of 16", it.type.runtime_size);
                case "constantCount";
                    assert(it.offset_in_bytes == 32, "WGPUFragmentState.constantCount has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUFragmentState.constantCount has unexpected size % instead of 8", it.type.runtime_size);
                case "constants";
                    assert(it.offset_in_bytes == 40, "WGPUFragmentState.constants has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUFragmentState.constants has unexpected size % instead of 8", it.type.runtime_size);
                case "targetCount";
                    assert(it.offset_in_bytes == 48, "WGPUFragmentState.targetCount has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUFragmentState.targetCount has unexpected size % instead of 8", it.type.runtime_size);
                case "targets";
                    assert(it.offset_in_bytes == 56, "WGPUFragmentState.targets has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUFragmentState.targets has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUFragmentState) == 64, "WGPUFragmentState has size % instead of 64", size_of(WGPUFragmentState));
    }

    {
        info := type_info(WGPURenderPipelineDescriptor);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPURenderPipelineDescriptor.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPipelineDescriptor.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "label";
                    assert(it.offset_in_bytes == 8, "WGPURenderPipelineDescriptor.label has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPURenderPipelineDescriptor.label has unexpected size % instead of 16", it.type.runtime_size);
                case "layout";
                    assert(it.offset_in_bytes == 24, "WGPURenderPipelineDescriptor.layout has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPipelineDescriptor.layout has unexpected size % instead of 8", it.type.runtime_size);
                case "vertex";
                    assert(it.offset_in_bytes == 32, "WGPURenderPipelineDescriptor.vertex has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "WGPURenderPipelineDescriptor.vertex has unexpected size % instead of 64", it.type.runtime_size);
                case "primitive";
                    assert(it.offset_in_bytes == 96, "WGPURenderPipelineDescriptor.primitive has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPURenderPipelineDescriptor.primitive has unexpected size % instead of 32", it.type.runtime_size);
                case "depthStencil";
                    assert(it.offset_in_bytes == 128, "WGPURenderPipelineDescriptor.depthStencil has unexpected offset % instead of 128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPipelineDescriptor.depthStencil has unexpected size % instead of 8", it.type.runtime_size);
                case "multisample";
                    assert(it.offset_in_bytes == 136, "WGPURenderPipelineDescriptor.multisample has unexpected offset % instead of 136", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "WGPURenderPipelineDescriptor.multisample has unexpected size % instead of 24", it.type.runtime_size);
                case "fragment";
                    assert(it.offset_in_bytes == 160, "WGPURenderPipelineDescriptor.fragment has unexpected offset % instead of 160", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURenderPipelineDescriptor.fragment has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURenderPipelineDescriptor) == 168, "WGPURenderPipelineDescriptor has size % instead of 168", size_of(WGPURenderPipelineDescriptor));
    }

    {
        info := type_info(WGPUInstanceExtras);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUInstanceExtras.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUInstanceExtras.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "backends";
                    assert(it.offset_in_bytes == 16, "WGPUInstanceExtras.backends has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUInstanceExtras.backends has unexpected size % instead of 8", it.type.runtime_size);
                case "flags";
                    assert(it.offset_in_bytes == 24, "WGPUInstanceExtras.flags has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUInstanceExtras.flags has unexpected size % instead of 8", it.type.runtime_size);
                case "dx12ShaderCompiler";
                    assert(it.offset_in_bytes == 32, "WGPUInstanceExtras.dx12ShaderCompiler has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUInstanceExtras.dx12ShaderCompiler has unexpected size % instead of 4", it.type.runtime_size);
                case "gles3MinorVersion";
                    assert(it.offset_in_bytes == 36, "WGPUInstanceExtras.gles3MinorVersion has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUInstanceExtras.gles3MinorVersion has unexpected size % instead of 4", it.type.runtime_size);
                case "glFenceBehaviour";
                    assert(it.offset_in_bytes == 40, "WGPUInstanceExtras.glFenceBehaviour has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUInstanceExtras.glFenceBehaviour has unexpected size % instead of 4", it.type.runtime_size);
                case "dxilPath";
                    assert(it.offset_in_bytes == 48, "WGPUInstanceExtras.dxilPath has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUInstanceExtras.dxilPath has unexpected size % instead of 16", it.type.runtime_size);
                case "dxcPath";
                    assert(it.offset_in_bytes == 64, "WGPUInstanceExtras.dxcPath has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUInstanceExtras.dxcPath has unexpected size % instead of 16", it.type.runtime_size);
                case "dxcMaxShaderModel";
                    assert(it.offset_in_bytes == 80, "WGPUInstanceExtras.dxcMaxShaderModel has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUInstanceExtras.dxcMaxShaderModel has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUInstanceExtras) == 88, "WGPUInstanceExtras has size % instead of 88", size_of(WGPUInstanceExtras));
    }

    {
        info := type_info(WGPUDeviceExtras);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUDeviceExtras.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUDeviceExtras.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "tracePath";
                    assert(it.offset_in_bytes == 16, "WGPUDeviceExtras.tracePath has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUDeviceExtras.tracePath has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUDeviceExtras) == 32, "WGPUDeviceExtras has size % instead of 32", size_of(WGPUDeviceExtras));
    }

    {
        info := type_info(WGPUNativeLimits);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUNativeLimits.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUNativeLimits.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "maxPushConstantSize";
                    assert(it.offset_in_bytes == 16, "WGPUNativeLimits.maxPushConstantSize has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUNativeLimits.maxPushConstantSize has unexpected size % instead of 4", it.type.runtime_size);
                case "maxNonSamplerBindings";
                    assert(it.offset_in_bytes == 20, "WGPUNativeLimits.maxNonSamplerBindings has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUNativeLimits.maxNonSamplerBindings has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUNativeLimits) == 24, "WGPUNativeLimits has size % instead of 24", size_of(WGPUNativeLimits));
    }

    {
        info := type_info(WGPUPushConstantRange);
        for info.members {
            if it.name == {
                case "stages";
                    assert(it.offset_in_bytes == 0, "WGPUPushConstantRange.stages has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPushConstantRange.stages has unexpected size % instead of 8", it.type.runtime_size);
                case "start";
                    assert(it.offset_in_bytes == 8, "WGPUPushConstantRange.start has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUPushConstantRange.start has unexpected size % instead of 4", it.type.runtime_size);
                case "end";
                    assert(it.offset_in_bytes == 12, "WGPUPushConstantRange.end has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUPushConstantRange.end has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUPushConstantRange) == 16, "WGPUPushConstantRange has size % instead of 16", size_of(WGPUPushConstantRange));
    }

    {
        info := type_info(WGPUPipelineLayoutExtras);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUPipelineLayoutExtras.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUPipelineLayoutExtras.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "pushConstantRangeCount";
                    assert(it.offset_in_bytes == 16, "WGPUPipelineLayoutExtras.pushConstantRangeCount has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPipelineLayoutExtras.pushConstantRangeCount has unexpected size % instead of 8", it.type.runtime_size);
                case "pushConstantRanges";
                    assert(it.offset_in_bytes == 24, "WGPUPipelineLayoutExtras.pushConstantRanges has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUPipelineLayoutExtras.pushConstantRanges has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUPipelineLayoutExtras) == 32, "WGPUPipelineLayoutExtras has size % instead of 32", size_of(WGPUPipelineLayoutExtras));
    }

    {
        info := type_info(WGPUShaderDefine);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "WGPUShaderDefine.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUShaderDefine.name has unexpected size % instead of 16", it.type.runtime_size);
                case "value";
                    assert(it.offset_in_bytes == 16, "WGPUShaderDefine.value has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUShaderDefine.value has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUShaderDefine) == 32, "WGPUShaderDefine has size % instead of 32", size_of(WGPUShaderDefine));
    }

    {
        info := type_info(WGPUShaderSourceGLSL);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUShaderSourceGLSL.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUShaderSourceGLSL.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "stage";
                    assert(it.offset_in_bytes == 16, "WGPUShaderSourceGLSL.stage has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUShaderSourceGLSL.stage has unexpected size % instead of 8", it.type.runtime_size);
                case "code";
                    assert(it.offset_in_bytes == 24, "WGPUShaderSourceGLSL.code has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUShaderSourceGLSL.code has unexpected size % instead of 16", it.type.runtime_size);
                case "defineCount";
                    assert(it.offset_in_bytes == 40, "WGPUShaderSourceGLSL.defineCount has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUShaderSourceGLSL.defineCount has unexpected size % instead of 4", it.type.runtime_size);
                case "defines";
                    assert(it.offset_in_bytes == 48, "WGPUShaderSourceGLSL.defines has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUShaderSourceGLSL.defines has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUShaderSourceGLSL) == 56, "WGPUShaderSourceGLSL has size % instead of 56", size_of(WGPUShaderSourceGLSL));
    }

    {
        info := type_info(WGPUShaderModuleDescriptorSpirV);
        for info.members {
            if it.name == {
                case "label";
                    assert(it.offset_in_bytes == 0, "WGPUShaderModuleDescriptorSpirV.label has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUShaderModuleDescriptorSpirV.label has unexpected size % instead of 16", it.type.runtime_size);
                case "sourceSize";
                    assert(it.offset_in_bytes == 16, "WGPUShaderModuleDescriptorSpirV.sourceSize has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUShaderModuleDescriptorSpirV.sourceSize has unexpected size % instead of 4", it.type.runtime_size);
                case "source";
                    assert(it.offset_in_bytes == 24, "WGPUShaderModuleDescriptorSpirV.source has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUShaderModuleDescriptorSpirV.source has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUShaderModuleDescriptorSpirV) == 32, "WGPUShaderModuleDescriptorSpirV has size % instead of 32", size_of(WGPUShaderModuleDescriptorSpirV));
    }

    {
        info := type_info(WGPURegistryReport);
        for info.members {
            if it.name == {
                case "numAllocated";
                    assert(it.offset_in_bytes == 0, "WGPURegistryReport.numAllocated has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURegistryReport.numAllocated has unexpected size % instead of 8", it.type.runtime_size);
                case "numKeptFromUser";
                    assert(it.offset_in_bytes == 8, "WGPURegistryReport.numKeptFromUser has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURegistryReport.numKeptFromUser has unexpected size % instead of 8", it.type.runtime_size);
                case "numReleasedFromUser";
                    assert(it.offset_in_bytes == 16, "WGPURegistryReport.numReleasedFromUser has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURegistryReport.numReleasedFromUser has unexpected size % instead of 8", it.type.runtime_size);
                case "elementSize";
                    assert(it.offset_in_bytes == 24, "WGPURegistryReport.elementSize has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPURegistryReport.elementSize has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPURegistryReport) == 32, "WGPURegistryReport has size % instead of 32", size_of(WGPURegistryReport));
    }

    {
        info := type_info(WGPUHubReport);
        for info.members {
            if it.name == {
                case "adapters";
                    assert(it.offset_in_bytes == 0, "WGPUHubReport.adapters has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.adapters has unexpected size % instead of 32", it.type.runtime_size);
                case "devices";
                    assert(it.offset_in_bytes == 32, "WGPUHubReport.devices has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.devices has unexpected size % instead of 32", it.type.runtime_size);
                case "queues";
                    assert(it.offset_in_bytes == 64, "WGPUHubReport.queues has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.queues has unexpected size % instead of 32", it.type.runtime_size);
                case "pipelineLayouts";
                    assert(it.offset_in_bytes == 96, "WGPUHubReport.pipelineLayouts has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.pipelineLayouts has unexpected size % instead of 32", it.type.runtime_size);
                case "shaderModules";
                    assert(it.offset_in_bytes == 128, "WGPUHubReport.shaderModules has unexpected offset % instead of 128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.shaderModules has unexpected size % instead of 32", it.type.runtime_size);
                case "bindGroupLayouts";
                    assert(it.offset_in_bytes == 160, "WGPUHubReport.bindGroupLayouts has unexpected offset % instead of 160", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.bindGroupLayouts has unexpected size % instead of 32", it.type.runtime_size);
                case "bindGroups";
                    assert(it.offset_in_bytes == 192, "WGPUHubReport.bindGroups has unexpected offset % instead of 192", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.bindGroups has unexpected size % instead of 32", it.type.runtime_size);
                case "commandBuffers";
                    assert(it.offset_in_bytes == 224, "WGPUHubReport.commandBuffers has unexpected offset % instead of 224", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.commandBuffers has unexpected size % instead of 32", it.type.runtime_size);
                case "renderBundles";
                    assert(it.offset_in_bytes == 256, "WGPUHubReport.renderBundles has unexpected offset % instead of 256", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.renderBundles has unexpected size % instead of 32", it.type.runtime_size);
                case "renderPipelines";
                    assert(it.offset_in_bytes == 288, "WGPUHubReport.renderPipelines has unexpected offset % instead of 288", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.renderPipelines has unexpected size % instead of 32", it.type.runtime_size);
                case "computePipelines";
                    assert(it.offset_in_bytes == 320, "WGPUHubReport.computePipelines has unexpected offset % instead of 320", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.computePipelines has unexpected size % instead of 32", it.type.runtime_size);
                case "pipelineCaches";
                    assert(it.offset_in_bytes == 352, "WGPUHubReport.pipelineCaches has unexpected offset % instead of 352", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.pipelineCaches has unexpected size % instead of 32", it.type.runtime_size);
                case "querySets";
                    assert(it.offset_in_bytes == 384, "WGPUHubReport.querySets has unexpected offset % instead of 384", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.querySets has unexpected size % instead of 32", it.type.runtime_size);
                case "buffers";
                    assert(it.offset_in_bytes == 416, "WGPUHubReport.buffers has unexpected offset % instead of 416", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.buffers has unexpected size % instead of 32", it.type.runtime_size);
                case "textures";
                    assert(it.offset_in_bytes == 448, "WGPUHubReport.textures has unexpected offset % instead of 448", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.textures has unexpected size % instead of 32", it.type.runtime_size);
                case "textureViews";
                    assert(it.offset_in_bytes == 480, "WGPUHubReport.textureViews has unexpected offset % instead of 480", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.textureViews has unexpected size % instead of 32", it.type.runtime_size);
                case "samplers";
                    assert(it.offset_in_bytes == 512, "WGPUHubReport.samplers has unexpected offset % instead of 512", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUHubReport.samplers has unexpected size % instead of 32", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUHubReport) == 544, "WGPUHubReport has size % instead of 544", size_of(WGPUHubReport));
    }

    {
        info := type_info(WGPUGlobalReport);
        for info.members {
            if it.name == {
                case "surfaces";
                    assert(it.offset_in_bytes == 0, "WGPUGlobalReport.surfaces has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "WGPUGlobalReport.surfaces has unexpected size % instead of 32", it.type.runtime_size);
                case "hub";
                    assert(it.offset_in_bytes == 32, "WGPUGlobalReport.hub has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 544, "WGPUGlobalReport.hub has unexpected size % instead of 544", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUGlobalReport) == 576, "WGPUGlobalReport has size % instead of 576", size_of(WGPUGlobalReport));
    }

    {
        info := type_info(WGPUInstanceEnumerateAdapterOptions);
        for info.members {
            if it.name == {
                case "nextInChain";
                    assert(it.offset_in_bytes == 0, "WGPUInstanceEnumerateAdapterOptions.nextInChain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUInstanceEnumerateAdapterOptions.nextInChain has unexpected size % instead of 8", it.type.runtime_size);
                case "backends";
                    assert(it.offset_in_bytes == 8, "WGPUInstanceEnumerateAdapterOptions.backends has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUInstanceEnumerateAdapterOptions.backends has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUInstanceEnumerateAdapterOptions) == 16, "WGPUInstanceEnumerateAdapterOptions has size % instead of 16", size_of(WGPUInstanceEnumerateAdapterOptions));
    }

    {
        info := type_info(WGPUBindGroupEntryExtras);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUBindGroupEntryExtras.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUBindGroupEntryExtras.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "buffers";
                    assert(it.offset_in_bytes == 16, "WGPUBindGroupEntryExtras.buffers has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntryExtras.buffers has unexpected size % instead of 8", it.type.runtime_size);
                case "bufferCount";
                    assert(it.offset_in_bytes == 24, "WGPUBindGroupEntryExtras.bufferCount has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntryExtras.bufferCount has unexpected size % instead of 8", it.type.runtime_size);
                case "samplers";
                    assert(it.offset_in_bytes == 32, "WGPUBindGroupEntryExtras.samplers has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntryExtras.samplers has unexpected size % instead of 8", it.type.runtime_size);
                case "samplerCount";
                    assert(it.offset_in_bytes == 40, "WGPUBindGroupEntryExtras.samplerCount has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntryExtras.samplerCount has unexpected size % instead of 8", it.type.runtime_size);
                case "textureViews";
                    assert(it.offset_in_bytes == 48, "WGPUBindGroupEntryExtras.textureViews has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntryExtras.textureViews has unexpected size % instead of 8", it.type.runtime_size);
                case "textureViewCount";
                    assert(it.offset_in_bytes == 56, "WGPUBindGroupEntryExtras.textureViewCount has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUBindGroupEntryExtras.textureViewCount has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBindGroupEntryExtras) == 64, "WGPUBindGroupEntryExtras has size % instead of 64", size_of(WGPUBindGroupEntryExtras));
    }

    {
        info := type_info(WGPUBindGroupLayoutEntryExtras);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUBindGroupLayoutEntryExtras.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUBindGroupLayoutEntryExtras.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "count";
                    assert(it.offset_in_bytes == 16, "WGPUBindGroupLayoutEntryExtras.count has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUBindGroupLayoutEntryExtras.count has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUBindGroupLayoutEntryExtras) == 24, "WGPUBindGroupLayoutEntryExtras has size % instead of 24", size_of(WGPUBindGroupLayoutEntryExtras));
    }

    {
        info := type_info(WGPUQuerySetDescriptorExtras);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUQuerySetDescriptorExtras.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUQuerySetDescriptorExtras.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "pipelineStatistics";
                    assert(it.offset_in_bytes == 16, "WGPUQuerySetDescriptorExtras.pipelineStatistics has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUQuerySetDescriptorExtras.pipelineStatistics has unexpected size % instead of 8", it.type.runtime_size);
                case "pipelineStatisticCount";
                    assert(it.offset_in_bytes == 24, "WGPUQuerySetDescriptorExtras.pipelineStatisticCount has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "WGPUQuerySetDescriptorExtras.pipelineStatisticCount has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUQuerySetDescriptorExtras) == 32, "WGPUQuerySetDescriptorExtras has size % instead of 32", size_of(WGPUQuerySetDescriptorExtras));
    }

    {
        info := type_info(WGPUSurfaceConfigurationExtras);
        for info.members {
            if it.name == {
                case "chain";
                    assert(it.offset_in_bytes == 0, "WGPUSurfaceConfigurationExtras.chain has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "WGPUSurfaceConfigurationExtras.chain has unexpected size % instead of 16", it.type.runtime_size);
                case "desiredMaximumFrameLatency";
                    assert(it.offset_in_bytes == 16, "WGPUSurfaceConfigurationExtras.desiredMaximumFrameLatency has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "WGPUSurfaceConfigurationExtras.desiredMaximumFrameLatency has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(WGPUSurfaceConfigurationExtras) == 24, "WGPUSurfaceConfigurationExtras has size % instead of 24", size_of(WGPUSurfaceConfigurationExtras));
    }
}

