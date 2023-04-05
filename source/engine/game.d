/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
module engine.game;
import engine.window;
import engine.backend;
import bindbc.wgpu;
import bindbc.sdl;
import engine.render.batch;
import inmath;

class Game {
private:
    Window window;
    float currTime;
    float timeAcc;
    SpriteBatch spriteBatch;
    vec4 clearColor = vec4(0.392, 0.584, 0.929, 1);

protected:

    /**
        Fixed time step update, ideal for physics
    */
    void onFixedUpdate(float deltaTime) { }
    
    /**
        Normal update for non-time-sensitive gameplay logic
    */
    void onUpdate(float deltaTime) { }
    
    /**
        Draw commands
    */
    void onDraw(SpriteBatch spriteBatch) { }

    /**
        Called on game initialisation
    */
    void onInit() { }

public:
    /**
        How much delta-time should be iterated in each fixed time step
    */
    float fixedUpdateStep = 0.016;

    /**
        Maximum fixed time step iterations
    */
    int maxFixedIterations = 60;

    /**
        Creates a new game
    */
    this(string title, int width = 640, int height = 480) {
        window = new Window(title, width, height);
        spriteBatch = new SpriteBatch(window);
    }

    /**
        Run a single iteration of the game loop
    */
    final
    void runOne() {
        window.update(null);

        // Delta-time calculation
        float delta = (cast(float)SDL_GetTicks64()/1000)-currTime;
        currTime = (cast(float)SDL_GetTicks64()/1000);

        // Delta Update
        onUpdate(delta);

        // Fixed update
        timeAcc += delta;
        int iterations;
        while (timeAcc >= fixedUpdateStep && iterations++ < maxFixedIterations) {

            // Decrease internal timestep and run the fixed update
            timeAcc -= fixedUpdateStep;
            onFixedUpdate(fixedUpdateStep);
        }

        // We give up, reset accumulator
        if (iterations >= maxFixedIterations) timeAcc = 0;

        // Get next texture in swapchain
        WGPUTextureView next = wgpuSwapChainGetCurrentTextureView(window.getSwapchain());
        if (next) {

            // Create an encoder to encode this frame's commands
            WGPUCommandEncoder encoder = wgpuDeviceCreateCommandEncoder(uwuDevice, new WGPUCommandEncoderDescriptor(null, "Game Commands"));

            // Render clear color
            wgpuRenderPassEncoderEnd(
                    wgpuCommandEncoderBeginRenderPass(encoder, new WGPURenderPassDescriptor(
                    null,
                    null,
                    1,
                    new WGPURenderPassColorAttachment(next, null, WGPULoadOp.Clear, WGPUStoreOp.Store, WGPUColor(clearColor.x, clearColor.y, clearColor.z, clearColor.w)),
                    null,
                ))
            );
            
            // Run user specified draw commands
            spriteBatch.frameBegin(encoder, next);
            onDraw(spriteBatch);
            
            // Drop texture so that we can render to it.
            wgpuTextureViewDrop(next);


            // Create a command buffer and submit it to the GPU
            WGPUCommandBuffer cmdbuffer = wgpuCommandEncoderFinish(encoder, new WGPUCommandBufferDescriptor(
                null,
                "Game Command Buffer"
            ));
            wgpuQueueSubmit(uwuQueue, 1, &cmdbuffer);

            // Swap :)
            window.present();
        }
    }

    /**
        Start the game
    */
    final
    void start() {
        onInit();
        while(!window.isCloseRequested) {
            runOne();
        }
    }

    /**
        Close the game
    */
    final
    void close() {
        window.close();
    }

    /**
        Sets the clear color
    */
    final
    void setClearColor(vec4 color) {
        this.clearColor = color;
    }

    /**
        Gets the current runtime of the application
    */
    float getCurrentTime() {
        return currTime;
    }
}