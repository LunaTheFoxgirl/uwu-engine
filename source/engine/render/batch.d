/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
module engine.render.batch;
import inmath.linalg;
import engine.backend;
import engine.render.camera;
import engine.window;
import std.exception;
import bindbc.wgpu;
import engine.font.font;
import engine.font.fatlas;

class SpriteBatch {
private:
    bool hasBegun;
    Window parentWindow;

    struct BatchItem {
        vec2 pos;
        vec2 uv;
        vec4 color;
    }

    // Internal storage
    BatchItem[ushort.max*6] elements;
    size_t batchBeginIdx = 0;
    size_t batchIdx = 0;
    size_t buffIdx = 0;
    
    Shader defaultShader;
    Camera defaultCamera;

    // GPU side buffer
    WGPUCommandEncoder encoder;
    WGPUTextureView surfaceView;
    VertexBuffer!BatchItem[] buffers;
    PipelineCache cache;

    Texture currentTexture;
    Shader currentShader;
    Camera currentCamera;

    void addSprite(rect position, rect uvs, vec4 color) {
        elements[batchIdx++] = BatchItem(vec2(position.left, position.top),        vec2(uvs.left, uvs.top),    color);
        elements[batchIdx++] = BatchItem(vec2(position.left, position.bottom),     vec2(uvs.left, uvs.bottom), color);
        elements[batchIdx++] = BatchItem(vec2(position.right, position.top),       vec2(uvs.right, uvs.top),   color);
        elements[batchIdx++] = BatchItem(vec2(position.right, position.top),       vec2(uvs.right, uvs.top),   color);
        elements[batchIdx++] = BatchItem(vec2(position.left, position.bottom),     vec2(uvs.left, uvs.bottom), color);
        elements[batchIdx++] = BatchItem(vec2(position.right, position.bottom),    vec2(uvs.right, uvs.bottom), color);
    }

    void rollover() {
        buffIdx++;
        if (buffIdx >= buffers.length) {
            buffers ~= new VertexBuffer!BatchItem(elements.length);
            buffers[$-1].setAttributes([
                WGPUVertexAttribute(WGPUVertexFormat.Float32x2, BatchItem.pos.offsetof, 0),
                WGPUVertexAttribute(WGPUVertexFormat.Float32x2, BatchItem.uv.offsetof, 1),
                WGPUVertexAttribute(WGPUVertexFormat.Float32x4, BatchItem.color.offsetof, 2),
            ]);

            batchBeginIdx = 0;
            batchIdx = 0;
        }
    }


public:

    /**
        Creates a sprite batcher
    */
    this(Window window) {
        this.parentWindow = window;
        cache = new PipelineCache();
        buffers ~= new VertexBuffer!BatchItem(elements.length);
        buffers[0].setAttributes([
            WGPUVertexAttribute(WGPUVertexFormat.Float32x2, BatchItem.pos.offsetof, 0),
            WGPUVertexAttribute(WGPUVertexFormat.Float32x2, BatchItem.uv.offsetof, 1),
            WGPUVertexAttribute(WGPUVertexFormat.Float32x4, BatchItem.color.offsetof, 2),
        ]);

        defaultShader = new Shader("SpriteBatch Shader", import("shaders/spritebatch.wgsl"));
        defaultCamera = new Camera();
        defaultCamera.viewport = vec2(parentWindow.getWidth(), parentWindow.getHeight());
    }

    /**
        Begins a frame
    */
    void frameBegin(WGPUCommandEncoder encoder, WGPUTextureView surfaceView) {
        this.buffIdx = 0;
        this.batchIdx = 0;
        this.batchBeginIdx = 0;
        this.encoder = encoder;
        this.surfaceView = surfaceView;
    }

    /**
        Begins a sprite batching pass
    */
    void begin(Camera camera = null, Shader shader = null) {
        enforce(!hasBegun, "Already in a SpriteBatcher pass!");
        hasBegun = true;

        cache.update();
        this.currentCamera = camera ? camera : defaultCamera;
        this.currentShader = shader ? shader : defaultShader;

        defaultCamera.viewport = vec2(parentWindow.getWidth(), parentWindow.getHeight());
        defaultCamera.update();
    }

    /**
        Draws a texture with the sprite batcher
    */
    void draw(Texture texture, rect position, rect uvs, vec4 color = vec4(1, 1, 1, 1)) {
        if (texture != currentTexture) {
            if (currentTexture) flush();
            currentTexture = texture;
            
            currentShader.setTextureLayout(0, currentTexture);
            currentShader.setUniBufferLayout(1, currentCamera.getBuffer);
        }
        if (batchIdx+6 >= elements.length) {
            flush();
            rollover();
        }

        addSprite(position, rect(
            uvs.x/texture.getWidth(),
            uvs.x/texture.getHeight(),
            uvs.width/texture.getWidth(),
            uvs.height/texture.getHeight()
        ), color);
    }

    /**
        Draws a texture with the sprite batcher
    */
    void draw(Font font, string text, uint size, vec2 position, vec4 color = vec4(1, 1, 1, 1)) {
        if (font.getTexture() != currentTexture) {
            if (currentTexture) flush();
            currentTexture = font.getTexture();
            
            currentShader.setTextureLayout(0, currentTexture);
            currentShader.setUniBufferLayout(1, currentCamera.getBuffer);
        }

        font.buffer(text, size);

        vec2 cpos = position;
        GlyphInfo c;
        while(font.next(c)) {

            if (c.newline) {
                cpos.x = position.x;
                cpos.y += c.newlineHeight;
            } else if (c.item) {

                // Flush out if we're at the end of the buffer
                if (batchIdx+6 >= elements.length) {
                    flush();
                    rollover();
                }

                // Add the next character
                addSprite(
                    rect(
                        cpos.x-c.offset.x,
                        cpos.y-c.offset.y,
                        c.item.area.width,
                        c.item.area.height
                    ),
                    c.item.uvarea,
                    color
                );
                cpos += c.advance;
            } else cpos += c.advance;

        }
    }

    /**
        Ends a sprite batcher pass
    */
    void end() {
        enforce(hasBegun, "SpriteBatcher pass not started!");
        this.hasBegun = false;
        
        flush();
        this.encoder = null;
        this.currentCamera = defaultCamera;
        this.currentShader = defaultShader;
        this.currentTexture = null;
    }

    /**
        Flushes sprite batch
    */
    void flush() {
        int torender = cast(int)(batchIdx-batchBeginIdx);
        if (torender == 0) return;
    
        WGPURenderPassEncoder pass = wgpuCommandEncoderBeginRenderPass(encoder, 
            new WGPURenderPassDescriptor(
                null,
                "Sprite Batch Pass",
                1,
                new WGPURenderPassColorAttachment(
                    surfaceView,
                    null,
                    WGPULoadOp.Load,
                    WGPUStoreOp.Store,
                    WGPUColor(1, 1, 1, 1)
                ),
                null,
                null,
                0,
                null
            )
        );

        buffers[buffIdx].setData(elements[batchBeginIdx..batchIdx], batchBeginIdx*BatchItem.sizeof);
        currentShader.setTexture(0, currentTexture);
        currentShader.setUniBuffer(1, currentCamera.getBuffer);
        currentShader.setVtxBuffer(buffers[buffIdx]);
        currentShader.setTopology(WGPUPrimitiveTopology.TriangleList);
        currentShader.setCulling(WGPUCullMode.None);
        currentShader.setBlendFunc(WGPUBlendFactor.SrcAlpha, WGPUBlendFactor.OneMinusSrcAlpha);


        cache.usePipeline(pass, currentShader, parentWindow.getSurface());
        wgpuRenderPassEncoderSetVertexBuffer(pass, 0, buffers[buffIdx].getBuffer(), batchBeginIdx*BatchItem.sizeof, torender*BatchItem.sizeof);
        wgpuRenderPassEncoderDraw(pass, torender, 1, 0, 0);
        wgpuRenderPassEncoderEnd(pass);

        batchBeginIdx = batchIdx;
        batchIdx = batchBeginIdx;
    }
}