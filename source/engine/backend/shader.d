/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
module engine.backend.shader;
import engine.backend.core;
import bindbc.wgpu;
import std.string;
import engine.backend.texture;
import engine.backend.buffer;

private {
    
    // Implemented for the future, but not implemented in WGPU yet
    extern(C)
    void uwuShaderCompileCallback(WGPUCompilationInfoRequestStatus status, const(WGPUCompilationInfo)* compilationInfo, void* userdata) {
        import std.stdio : writeln;
        if (compilationInfo) {
            if (status == WGPUCompilationInfoRequestStatus.Success) return;
            foreach(i; 0..compilationInfo.messageCount) {
                const(WGPUCompilationMessage)* msg = (compilationInfo.messages+i);
                if (msg) {
                    writeln(msg.type, " ", msg.lineNum, ":", msg.linePos, " ", msg.message.fromStringz);
                }
            }
        }
    }
}

struct ShaderPipelineState {
    WGPUBlendState blendState;
    WGPUFragmentState fragmentState;
    WGPUPrimitiveState primitiveState;
    WGPUVertexBufferLayout vtxBuffer;
    WGPUBindGroupLayout[] bindLayouts;
    WGPUBindGroup[] bindGroups;
}

class Shader {
private:
    string name;
    string source;

    WGPUShaderModule shader;
    ShaderPipelineState pipelineState;

    bool hasUpdated = false;
    bool finalized;

    void uploadShader() {
        WGPUShaderModuleWGSLDescriptor wgslDesc;
        wgslDesc.code = source.toStringz;
        wgslDesc.chain.sType = WGPUSType.ShaderModuleWGSLDescriptor;
        
        WGPUShaderModuleDescriptor desc;
        desc.nextInChain = new WGPUChainedStruct(
            cast(const(WGPUChainedStruct)*)&wgslDesc,
            WGPUSType.ShaderModuleWGSLDescriptor
        );
        desc.label = name.toStringz;

        shader = wgpuDeviceCreateShaderModule(uwuDevice, &desc);
    }

public:
    this(string name, string source) {
        this.source = source;
        this.name = name;
        this.uploadShader();
    }

    /**
        Returns whether the pipeline state of the shader has changed
    */
    bool getUpdated() {
        return hasUpdated;
    }

    /**
        Returns the pipeline state of the shader

        This will mark the pipeline state as up to date.
    */
    ShaderPipelineState getState() {
        this.hasUpdated = false;
        return pipelineState;
    }

    /**
        Sets the color blending operation
    */
    void setBlendOp(WGPUBlendOperation op) {
        this.hasUpdated = true;
        pipelineState.blendState.color.operation = op;
        pipelineState.blendState.alpha.operation = op;
    }

    /**
        Sets the color blending function
    */
    void setBlendFunc(WGPUBlendFactor srcFactor, WGPUBlendFactor dstFactor) {
        this.hasUpdated = true;
        pipelineState.blendState.color.srcFactor = srcFactor;
        pipelineState.blendState.color.dstFactor = dstFactor;
        pipelineState.blendState.alpha.srcFactor = srcFactor;
        pipelineState.blendState.alpha.dstFactor = dstFactor;
    }

    /**
        Sets the color blending function for color and alpha seperately
    */
    void setBlendFuncSeperate(WGPUBlendFactor srcFactor, WGPUBlendFactor dstFactor, WGPUBlendFactor srcFactorA, WGPUBlendFactor dstFactorA) {
        this.hasUpdated = true;
        pipelineState.blendState.color.srcFactor = srcFactor;
        pipelineState.blendState.color.dstFactor = dstFactor;
        pipelineState.blendState.alpha.srcFactor = srcFactorA;
        pipelineState.blendState.alpha.dstFactor = dstFactorA;
    }

    /**
        Sets the rendering topology
    */
    void setTopology(WGPUPrimitiveTopology topology) {
        this.hasUpdated = true;
        pipelineState.primitiveState.topology = topology;
    }

    /**
        Sets the rendering winding mode
    */
    void setWinding(WGPUFrontFace winding) {
        this.hasUpdated = true;
        pipelineState.primitiveState.frontFace = winding;
    }

    /**
        Sets the rendering cull mode, None for no culling
    */
    void setCulling(WGPUCullMode culling) {
        this.hasUpdated = true;
        pipelineState.primitiveState.cullMode = culling;
    }

    /**
        Sets a texture for a binding group ID
    */
    void setTextureLayout(uint group, Texture texture) {
        this.hasUpdated = true;

        // Resize if size doesn't match
        if (group >= pipelineState.bindLayouts.length) pipelineState.bindLayouts.length = group+1;
        if (group >= pipelineState.bindGroups.length) pipelineState.bindGroups.length = group+1;
        
        // Drop old data
        if (pipelineState.bindLayouts[group]) {
            wgpuBindGroupLayoutDrop(pipelineState.bindLayouts[group]);
        }
        if (pipelineState.bindGroups[group]) {
            wgpuBindGroupDrop(pipelineState.bindGroups[group]);
        }

        WGPUBindGroupLayoutDescriptor layoutDesc;
        layoutDesc.entryCount = 2;
        layoutDesc.entries = [
            WGPUBindGroupLayoutEntry(
                null,
                0,
                WGPUShaderStage.Fragment,
                WGPUBufferBindingLayout(null, WGPUBufferBindingType.Undefined, false, 0),
                WGPUSamplerBindingLayout(null, WGPUSamplerBindingType.Undefined),
                WGPUTextureBindingLayout(
                    null,
                    WGPUTextureSampleType.Float,
                    WGPUTextureViewDimension.D2,
                    false
                ),
                WGPUStorageTextureBindingLayout(null, WGPUStorageTextureAccess.Undefined, WGPUTextureFormat.Undefined, WGPUTextureViewDimension.Undefined),
            ),
            WGPUBindGroupLayoutEntry(
                null,
                1,
                WGPUShaderStage.Fragment,
                WGPUBufferBindingLayout(null, WGPUBufferBindingType.Undefined, false, 0),
                WGPUSamplerBindingLayout(
                    null,
                    WGPUSamplerBindingType.Filtering
                ),
                WGPUTextureBindingLayout(null, WGPUTextureSampleType.Undefined, WGPUTextureViewDimension.Undefined, false),
                WGPUStorageTextureBindingLayout(null, WGPUStorageTextureAccess.Undefined, WGPUTextureFormat.Undefined, WGPUTextureViewDimension.Undefined),
            ),
        ].ptr;

        pipelineState.bindLayouts[group] = wgpuDeviceCreateBindGroupLayout(uwuDevice, &layoutDesc);
    }

    void setTexture(uint group, Texture texture) {
        WGPUBindGroupDescriptor desc;
        desc.layout = pipelineState.bindLayouts[group];
        desc.entryCount = 2;
        desc.entries = [
            WGPUBindGroupEntry(
                null,
                0,
                null,
                0,
                0,
                null,
                texture.getView()
            ),
            WGPUBindGroupEntry(
                null,
                1,
                null,
                0,
                0,
                texture.getSampler(),
                null
            ),
        ].ptr;

        pipelineState.bindGroups[group] = wgpuDeviceCreateBindGroup(uwuDevice, &desc);
    }

    /**
        Sets a vertex buffer for a binding group ID
    */
    void setVtxBuffer(Bufferable buffer) {
        this.hasUpdated = true;
        pipelineState.vtxBuffer = buffer.getLayout();
    }

    /**
        Sets a uniform buffer for a binding group ID
    */
    void setUniBufferLayout(uint group, Bufferable buffer) {
        this.hasUpdated = true;

        // Resize if size doesn't match
        if (group >= pipelineState.bindLayouts.length) pipelineState.bindLayouts.length = group+1;
        if (group >= pipelineState.bindGroups.length) pipelineState.bindGroups.length = group+1;
        
        // Drop old data
        if (pipelineState.bindLayouts[group]) {
            wgpuBindGroupLayoutDrop(pipelineState.bindLayouts[group]);
        }
        if (pipelineState.bindGroups[group]) {
            wgpuBindGroupDrop(pipelineState.bindGroups[group]);
        }

        WGPUBindGroupLayoutDescriptor layoutDesc;
        layoutDesc.entryCount = 1;
        layoutDesc.entries = [
            WGPUBindGroupLayoutEntry(
                null,
                0,
                WGPUShaderStage.Fragment | WGPUShaderStage.Vertex,
                WGPUBufferBindingLayout(
                    null, 
                    WGPUBufferBindingType.Uniform, 
                    false, 
                    buffer.byteLength()
                ),
                WGPUSamplerBindingLayout.init,
                WGPUTextureBindingLayout.init
            )
        ].ptr;

        pipelineState.bindLayouts[group] = wgpuDeviceCreateBindGroupLayout(uwuDevice, &layoutDesc);
    }

    /**
        Sets a uniform buffer for a binding group ID
    */
    void setUniBuffer(uint group, Bufferable buffer) {
        WGPUBindGroupDescriptor desc;
        desc.layout = pipelineState.bindLayouts[group];
        desc.entryCount = 1;
        desc.entries = [
            WGPUBindGroupEntry(
                null,
                0,
                buffer.getBuffer(),
                0,
                buffer.byteLength(),
                null,
                null
            ),
        ].ptr;

        pipelineState.bindGroups[group] = wgpuDeviceCreateBindGroup(uwuDevice, &desc);
    }

    /**
        Returns the WGPU shader module handle
    */
    WGPUShaderModule getHandle() {
        return shader;
    }
}