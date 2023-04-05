/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
module engine.backend.buffer;
import bindbc.wgpu;
import engine.backend.core;
import std.math.rounding;

abstract class Bufferable {
    abstract WGPUBuffer getBuffer();
    abstract WGPUVertexBufferLayout getLayout();
    abstract size_t byteLength();
}

/**
    Mapped buffers in WGPU needs to be aligned to multiples of 4
*/
size_t uwuAlignBufferSize(size_t inputSize) {
    return cast(size_t)quantize!(ceil)(cast(float)inputSize, 4);
}

class VertexBuffer(T) : Bufferable {
private:
    WGPUBuffer buffer;
    size_t elementCount;
    WGPUVertexBufferLayout layout;

public:

    /**
        Creates a empty buffer
    */
    this(size_t length) {
        this.elementCount = length;

        WGPUBufferDescriptor desc;
        desc.mappedAtCreation = false;
        desc.size = uwuAlignBufferSize(T.sizeof*length);
        desc.usage = WGPUBufferUsage.CopySrc | WGPUBufferUsage.CopyDst | WGPUBufferUsage.Vertex;

        // Create a buffer with a mapped range and write the data in immediately
        buffer = wgpuDeviceCreateBuffer(uwuDevice, &desc);
    }
    
    /**
        Creates a buffer with data
    */
    this(T[] data) {
        import core.stdc.string : memcpy;
        this.elementCount = data.length;

        WGPUBufferDescriptor desc;
        desc.mappedAtCreation = true;
        desc.size = uwuAlignBufferSize(T.sizeof*data.length);
        desc.usage = WGPUBufferUsage.CopySrc | WGPUBufferUsage.CopyDst | WGPUBufferUsage.Vertex;

        // Create a buffer with a mapped range and write the data in immediately
        buffer = wgpuDeviceCreateBuffer(uwuDevice, &desc);
        auto buffRange = wgpuBufferGetMappedRange(buffer, 0, cast(uint)desc.size);
        memcpy(buffRange, data.ptr, data.length*T.sizeof);
        wgpuBufferUnmap(buffer);
    }

    /**
        Sets attributes for buffer
    */
    void setAttributes(WGPUVertexAttribute[] attributes) {
        layout = WGPUVertexBufferLayout(
            T.sizeof,
            WGPUVertexStepMode.Vertex,
            cast(uint)attributes.length,
            attributes.ptr
        );
    }

    /**
        Sets the data in the buffer
    */
    void setData(T[] data, size_t offset) {
        wgpuQueueWriteBuffer(uwuQueue, buffer, cast(ulong)offset, data.ptr, data.length*T.sizeof);
    }

    /**
        Gets the count of elements within the buffer
    */
    size_t count() {
        return elementCount;
    }

    /**
        Gets the length of the buffer in bytes
    */
    override
    size_t byteLength() {
        return elementCount * T.sizeof;
    }

    /**
        Gets the underlying WGPU buffer
    */
    override
    WGPUBuffer getBuffer() {
        return buffer;
    }

    /**
        Gets the underlying WGPU buffer layout
    */
    override
    WGPUVertexBufferLayout getLayout() {
        return layout;
    }
}

class UniformBuffer(T) : Bufferable {
private:
    WGPUBuffer buffer;
    T localCopy;

public:
    this(T state) {
        import core.stdc.string : memcpy;
        localCopy = state;

        WGPUBufferDescriptor desc;
        desc.mappedAtCreation = true;
        desc.size = uwuAlignBufferSize(T.sizeof);
        desc.usage = WGPUBufferUsage.CopySrc | WGPUBufferUsage.CopyDst | WGPUBufferUsage.Uniform;
        
        // Create a buffer with a mapped range and write the data in immediately
        buffer = wgpuDeviceCreateBuffer(uwuDevice, &desc);
        auto buffRange = wgpuBufferGetMappedRange(buffer, 0, cast(uint)desc.size);
        memcpy(buffRange, &state, T.sizeof);
        wgpuBufferUnmap(buffer);
    }

    /**
        Set state of uniform buffer
    */
    void setState(T newState) {
        this.localCopy = newState;
        this.refresh();
    }

    /**
        Get state of uniform buffer
    */
    ref T getState() {
        return localCopy;
    }

    /**
        Refresh the GPU-side state
    */
    void refresh() {
        wgpuQueueWriteBuffer(uwuQueue, buffer, 0, &localCopy, T.sizeof);
    }

    /**
        Gets the length of the buffer in bytes
    */
    override
    size_t byteLength() { return T.sizeof; }

    /**
        Gets the underlying WGPU buffer
    */
    override
    WGPUBuffer getBuffer() { return buffer; }

    /**
        Gets the underlying WGPU buffer layout
    */
    override
    WGPUVertexBufferLayout getLayout() { return WGPUVertexBufferLayout.init; }
}