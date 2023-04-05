/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
module engine.backend.core;
import std.stdio;
import std.string;
import std.exception;
import bindbc.wgpu;
import bindbc.sdl;

WGPUInstance uwuInstance;

WGPUAdapter uwuAdapter;
WGPUDevice uwuDevice;
WGPUQueue uwuQueue;

extern(C) void uwuLogCallback (WGPULogLevel level, const(char)* message, void* userdata) {
    writeln(level, ": ", message.fromStringz);
}

void uwuInit() {
    // Load SDL and WGPU
    auto sdlSupport = loadSDL();
    auto wgpuSupport = loadWGPU();
    enforce(sdlSupport != SDLSupport.noLibrary, "SDL2 not found!");
    enforce(wgpuSupport != WGPUSupport.noLibrary, "WGPU Native not found!");
    SDL_Init(SDL_INIT_EVERYTHING);

    WGPUInstanceDescriptor desc;
    uwuInstance = wgpuCreateInstance(&desc);

    WGPURequestAdapterOptions reqOptions;
    reqOptions.powerPreference = WGPUPowerPreference.HighPerformance;
    wgpuInstanceRequestAdapter(uwuInstance, &reqOptions, &uwuAdapterCreateCallback, &uwuAdapter);

    // Minimum limits need to be specified manually with wgpu native
    WGPURequiredLimits limits;
    limits.limits.maxTextureDimension1D = 2048;
    limits.limits.maxTextureDimension2D = 2048;
    limits.limits.maxTextureDimension3D = 256;
    limits.limits.maxTextureArrayLayers = 256;
    limits.limits.maxBindGroups = 4;
    limits.limits.maxBindingsPerBindGroup = 640;
    limits.limits.maxDynamicUniformBuffersPerPipelineLayout = 8;
    limits.limits.maxDynamicStorageBuffersPerPipelineLayout = 4;
    limits.limits.maxSampledTexturesPerShaderStage = 16;
    limits.limits.maxSamplersPerShaderStage = 16;
    limits.limits.maxStorageBuffersPerShaderStage = 4;
    limits.limits.maxStorageTexturesPerShaderStage = 4;
    limits.limits.maxUniformBuffersPerShaderStage = 12;
    limits.limits.maxUniformBufferBindingSize = 16 << 10;
    limits.limits.maxStorageBufferBindingSize = 128 << 20;
    limits.limits.maxVertexBuffers = 8;
    limits.limits.maxVertexAttributes = 16;
    limits.limits.maxVertexBufferArrayStride = 2048;
    limits.limits.minUniformBufferOffsetAlignment = 256;
    limits.limits.minStorageBufferOffsetAlignment = 256;
    limits.limits.maxInterStageShaderComponents = 60;
    limits.limits.maxComputeWorkgroupStorageSize = 16352;
    limits.limits.maxComputeInvocationsPerWorkgroup = 256;
    limits.limits.maxComputeWorkgroupSizeX = 256;
    limits.limits.maxComputeWorkgroupSizeY = 256;
    limits.limits.maxComputeWorkgroupSizeZ = 64;
    limits.limits.maxComputeWorkgroupsPerDimension = 65535;
    limits.limits.maxBufferSize = 1 << 28;

    WGPUDeviceDescriptor reqDesc;
    reqDesc.requiredLimits = &limits;
    wgpuAdapterRequestDevice(uwuAdapter, &reqDesc, &uwuDeviceCreateCallback, &uwuDevice);

    // We'll need the queue for basic operation like filling buffers
    uwuQueue = wgpuDeviceGetQueue(uwuDevice);

    wgpuSetLogLevel(WGPULogLevel.Info);
    wgpuSetLogCallback(&uwuLogCallback, null);
}

void uwuCleanup() {
    wgpuInstanceDrop(uwuInstance);
}

private {
    extern(C)
    void uwuAdapterCreateCallback(WGPURequestAdapterStatus status, WGPUAdapter adapter, const(char)* message, void* userdata) {
        if (status == WGPURequestAdapterStatus.Success) {
            *cast(WGPUAdapter*)userdata = adapter;
        } else {
            writeln(status, " ", message.fromStringz);
        }
    }

    extern(C)
    void uwuDeviceCreateCallback(WGPURequestDeviceStatus status, WGPUDevice device, const(char)* message, void* userdata) {
        if (status == WGPURequestDeviceStatus.Success) {
            *cast(WGPUDevice*)userdata = device;
        } else {
            writeln(status, " ", message.fromStringz);
        }
    }
}