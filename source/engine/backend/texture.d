/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
module engine.backend.texture;
import engine.backend.core;
import imagefmt;
import bindbc.wgpu;
import std.exception;

class Texture {
private:
    uint width, height;
    WGPUTextureDescriptor texDesc;

    WGPUTexture texture;
    WGPUTextureView view;
    WGPUSampler sampler;

    void createTexture(ref IFImage image) {
        texDesc.mipLevelCount = 1;
        texDesc.sampleCount = 1;
        texDesc.dimension = WGPUTextureDimension.D2;
        texDesc.format = WGPUTextureFormat.RGBA8UnormSrgb;
        texDesc.usage = WGPUTextureUsage.CopySrc | WGPUTextureUsage.CopyDst | WGPUTextureUsage.TextureBinding;
        texDesc.size = WGPUExtent3D(image.w, image.h, 1);
        texture = wgpuDeviceCreateTexture(uwuDevice, &texDesc);
    }

    void createEmptyTexture(int width, int height) {
        texDesc.mipLevelCount = 1;
        texDesc.sampleCount = 1;
        texDesc.dimension = WGPUTextureDimension.D2;
        texDesc.format = WGPUTextureFormat.RGBA8UnormSrgb;
        texDesc.usage = WGPUTextureUsage.CopySrc | WGPUTextureUsage.CopyDst | WGPUTextureUsage.TextureBinding;
        texDesc.size = WGPUExtent3D(width, height, 1);
        texture = wgpuDeviceCreateTexture(uwuDevice, &texDesc);
    }

    void uploadTextureData(ref IFImage image, int x, int y) {
        import std.stdio : writeln;

        // Upload data to texture
        WGPUImageCopyTexture dest;
        dest.texture = texture;
        dest.mipLevel = 0;
        dest.origin = WGPUOrigin3D(x, y, 0);
        dest.aspect = WGPUTextureAspect.All;

        WGPUTextureDataLayout layout;
        layout.bytesPerRow = image.w*image.c;
        layout.rowsPerImage = image.h;
        layout.offset = 0;

        wgpuQueueWriteTexture(
            uwuQueue,
            &dest,
            image.buf8.ptr,
            image.buf8.length,
            &layout,
            &texDesc.size
        );
    }

    void createTextureView() {

        // Create texture view
        WGPUTextureViewDescriptor viewDesc;
        viewDesc.arrayLayerCount = 1;
        viewDesc.mipLevelCount = 1;
        viewDesc.aspect = WGPUTextureAspect.All;
        viewDesc.baseArrayLayer = 0;
        viewDesc.baseMipLevel = 0;
        viewDesc.dimension = WGPUTextureViewDimension.D2;
        view = wgpuTextureCreateView(texture, &viewDesc);
    }

    void createSampler() {
        WGPUSamplerDescriptor desc;
        desc.addressModeU = WGPUAddressMode.Repeat;
        desc.addressModeV = WGPUAddressMode.Repeat;
        desc.addressModeW = WGPUAddressMode.Repeat;
        desc.magFilter = WGPUFilterMode.Nearest;
        desc.minFilter = WGPUFilterMode.Nearest;
        desc.mipmapFilter = WGPUMipmapFilterMode.Nearest;
        desc.maxAnisotropy = 8;
        desc.lodMinClamp = 0;
        desc.lodMaxClamp = float.max;
        desc.compare = WGPUCompareFunction.Undefined;
        sampler = wgpuDeviceCreateSampler(uwuDevice, &desc);
    }

public:
    /**
        Creates a new texture from a file
    */
    this(string file) {
        this(read_image(file, 4, 8));
    }

    /**
        Creates a new texture from a IFImage
    */
    this(IFImage image) {
        enforce(image.e == 0, IF_ERROR[image.e]);

        this.width = image.w;
        this.height = image.h;
        this.createTexture(image);
        this.uploadTextureData(image, 0, 0);
        this.createTextureView();
        this.createSampler();
    }

    /**
        Creates a new texture from a IFImage
    */
    this(uint width, uint height) {

        this.width = width;
        this.height = height;
        this.createEmptyTexture(width, height);
        this.createTextureView();
        this.createSampler();
    }

    /**
        Sets a subsection of the texture data
    */
    void setSubData(IFImage image, int x, int y) {
        this.uploadTextureData(image, x, y);
    }

    /**
        Returns the view in to the texture
    */
    WGPUTextureView getView() {
        return view;
    }

    /**
        Returns the texture sampler
    */
    WGPUSampler getSampler() {
        return sampler;
    }

    /**
        Returns the width of the texture
    */
    uint getWidth() {
        return width;
    }

    /**
        Returns the height of the texture
    */
    uint getHeight() {
        return height;
    }
}