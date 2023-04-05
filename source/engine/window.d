/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
module engine.window;
import bindbc.sdl;
import bindbc.wgpu;
import std.string;
import engine.backend.core;

class Window {
private:
    SDL_Window* handle;
    WGPUSurface surface;
    WGPUSwapChain swapchain;

    WGPUTextureFormat swapchainFormat;
    int width_ = 0, height_ = 0;

    bool shouldClose = false;

    WGPUSurface createSurface() {
        SDL_SysWMinfo info;
        SDL_GetWindowWMInfo(handle, &info);
        WGPUSurfaceDescriptorFromWindowsHWND windowDesc;
        windowDesc.hinstance = info.info.win.hinstance;
        windowDesc.hwnd = info.info.win.window;
        windowDesc.chain = WGPUChainedStruct(null, WGPUSType.SurfaceDescriptorFromWindowsHWND);
        
        WGPUSurfaceDescriptor surfaceDesc;
        surfaceDesc.nextInChain = new WGPUChainedStruct(
            cast(const(WGPUChainedStruct)*)&windowDesc,
            WGPUSType.SurfaceDescriptorFromWindowsHWND
        );
        return wgpuInstanceCreateSurface(uwuInstance, &surfaceDesc);
    }

    WGPUSwapChain createSwapchain() {
        swapchainFormat = wgpuSurfaceGetPreferredFormat(surface, uwuAdapter);

        WGPUSwapChainDescriptor desc;
        desc.width = width_;
        desc.height = height_;
        desc.presentMode = WGPUPresentMode.Mailbox;
        desc.format = swapchainFormat;
        desc.usage = WGPUTextureUsage.RenderAttachment;
        desc.nextInChain = cast(WGPUChainedStruct*)new WGPUSwapChainDescriptorExtras(
            WGPUChainedStruct(
                null,
                cast(WGPUSType)WGPUNativeSType.SwapChainDescriptorExtras
            ),
            WGPUCompositeAlphaMode.Auto,
            0,
            null
        );

        return wgpuDeviceCreateSwapChain(uwuDevice, surface, &desc);
    }

public:
    this(string title, int width, int height) {
        this.width_ = width;
        this.height_ = height;
        
        handle = SDL_CreateWindow(
            title.toStringz,
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            width,
            height,
            SDL_WINDOW_RESIZABLE
        );
        surface = this.createSurface();
        swapchain = this.createSwapchain();
    }

    /**
        Returns the surface associated with this window
    */
    WGPUSurface getSurface() {
        return surface;
    }

    /**
        Returns the surface associated with this window
    */
    WGPUSwapChain getSwapchain() {
        return swapchain;
    }

    /**
        Returns the texture format associated with this window
    */
    WGPUTextureFormat getSurfaceFormat() {
        return swapchainFormat;
    }

    /**
        Gets the current texture view
    */
    WGPUTextureView getCurrentTextureView() {
        return wgpuSwapChainGetCurrentTextureView(swapchain);
    }

    uint getWidth() {
        return width_;
    }

    uint getHeight() {
        return height_;
    }

    /**
        Was the window requested to close
    */
    bool isCloseRequested() {
        return shouldClose;
    }

    /**
        Closes the window
    */
    void close() {
        shouldClose = true;
    }

    /**
        Updates the window
    */
    void update(void delegate(SDL_Event ev) fallbackFunc) {

        SDL_Event ev;
        while(SDL_PollEvent(&ev) == 1) {
            if (ev.type == SDL_WINDOWEVENT) {
                switch(ev.window.event) {
                    
                    // Allow closing window
                    case SDL_WINDOWEVENT_CLOSE:
                        shouldClose = true;
                        break;

                    // Recreate swapchain on window resize
                    case SDL_WINDOWEVENT_RESIZED:
                        this.width_ = ev.window.data1;
                        this.height_ = ev.window.data2;
                        this.swapchain = this.createSwapchain();
                        break;
                    default: 
                        if (fallbackFunc) fallbackFunc(ev);
                        break;
                }
            } else if (fallbackFunc) fallbackFunc(ev);
        }
    }


    /**
        Presents the next frame of the rendering
    */
    void present() {
        wgpuSwapChainPresent(swapchain);
    }
}