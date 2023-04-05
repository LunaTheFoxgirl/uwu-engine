/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
module engine.backend.pipeline;
import engine.backend.core;
import engine.backend.shader;
import bindbc.wgpu;
import std.algorithm.mutation : remove;
import core.memory : GC;

enum UWUPipelineCacheMaxGenerations = 50;

class PipelineCache {
private:
    bool usedThisFrame;

    struct PipelineI {
        uint generation;
        Shader shader;
        ShaderPipelineState state;
        WGPUPipelineLayout layout;
        WGPURenderPipeline pipeline;
    }

    PipelineI* currentPipeline;
    PipelineI[] pipelineObjects;

    WGPUPipelineLayout createLayout(ref ShaderPipelineState state) {

        WGPUPipelineLayoutDescriptor layoutdesc;
        layoutdesc.bindGroupLayoutCount = cast(uint)state.bindLayouts.length;
        layoutdesc.bindGroupLayouts = state.bindLayouts.ptr;
        return wgpuDeviceCreatePipelineLayout(uwuDevice, &layoutdesc);
    }

    WGPURenderPipeline createPipeline(WGPUSurface surface, Shader shader, ref ShaderPipelineState state, WGPUPipelineLayout layout) {
        
        WGPURenderPipelineDescriptor desc = WGPURenderPipelineDescriptor(
            null,
            "Cached Pipeline",
            layout,
            WGPUVertexState(
                null,
                shader.getHandle(),
                "vs_main",
                0,
                null,
                1,
                &state.vtxBuffer
            ),
            state.primitiveState,
            null,
            WGPUMultisampleState(
                null,
                1,
                ~0,
                false
            ),
            new WGPUFragmentState(
                null,
                shader.getHandle(),
                "fs_main",
                0,
                null,
                1,
                new WGPUColorTargetState(
                    null,
                    wgpuSurfaceGetPreferredFormat(surface, uwuAdapter),
                    &state.blendState,
                    WGPUColorWriteMask.All
                )
            )
        );

        return wgpuDeviceCreateRenderPipeline(uwuDevice, &desc);
    }

public:
    ~this() {
        this.clear();
    }

    this() {
        pipelineObjects.reserve(1000);
        maxGenerations = UWUPipelineCacheMaxGenerations;
    }

    /**
        Threshold of generations before a pipeline will be 
        removed from the cache.
    */
    size_t maxGenerations = UWUPipelineCacheMaxGenerations;

    /**
        Uses render pipeline from cache

        If pipeline is not in the cache a new one will be added.
    */
    void usePipeline(WGPURenderPassEncoder encoder, Shader shader, WGPUSurface surface) {
        WGPURenderPipeline pipeline;
        WGPUBindGroup[] bindGroups;
        getPipeline(shader, surface, pipeline, bindGroups);

        wgpuRenderPassEncoderSetPipeline(encoder, pipeline);
        foreach(i, group; bindGroups) {
            wgpuRenderPassEncoderSetBindGroup(encoder, cast(uint)i, group, 0, null);
        }
    }

    /**
        Gets render pipeline from cache

        If pipeline is not in the cache a new one will be added.
    */
    void getPipeline(Shader shader, WGPUSurface surface, out WGPURenderPipeline pipelineOut, out WGPUBindGroup[] bindGroupsOut) {
        import std.stdio : writeln;
        usedThisFrame = true;
        if(shader.getUpdated()) {
            auto state = shader.getState();
            foreach(ref pipeline; pipelineObjects) {
                if (pipeline.state == state) {

                    // Pipeline already exists, return that
                    currentPipeline.generation = 0;
                    currentPipeline = &pipeline;
                    pipelineOut = currentPipeline.pipeline;
                    bindGroupsOut = currentPipeline.state.bindGroups;
                    return;
                }
            }

            WGPUPipelineLayout layout = createLayout(state);

            // Pipeline does not exist, create it
            pipelineObjects ~= PipelineI(
                0,
                shader,
                state,
                layout,
                createPipeline(surface, shader, state, layout)
            );
            currentPipeline = &pipelineObjects[$-1];
        }
        
        currentPipeline.generation = 0;
        pipelineOut = currentPipeline.pipeline;
        bindGroupsOut = currentPipeline.state.bindGroups;
    }

    /**
        Add pipeline to the cache
    */
    void update() {
        // We do not want to update the pipeline cache if it wasn't used this frame
        // This prevents all the cached elements from being yeeted before time
        if (!usedThisFrame) return;
        usedThisFrame = false;

        // Run through pipeline objects
        for(size_t i = 0; i < pipelineObjects.length; i++) {
            if (pipelineObjects[i].generation >= maxGenerations) {
                wgpuPipelineLayoutDrop(pipelineObjects[i].layout);
                wgpuRenderPipelineDrop(pipelineObjects[i].pipeline);
                pipelineObjects = pipelineObjects.remove(i--);
                continue;
            }
            pipelineObjects[i].generation++;
        }
    }

    /**
        Clears all the pipelines from the cache
    */
    final
    void clear() {

        // Yeet all associated pipelines
        foreach(pipeline; pipelineObjects) {
            wgpuPipelineLayoutDrop(pipeline.layout);
            wgpuRenderPipelineDrop(pipeline.pipeline);
        }
        pipelineObjects.length = 0;
    }

}