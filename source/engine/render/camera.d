/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
module engine.render.camera;
import inmath;
import engine.backend.buffer;

class Camera {
private:
    UniformBuffer!mat4 cameraBuffer;
    mat4 matrix;

    vec2 position_;
    vec2 viewport_;

public:
    this() {
        cameraBuffer = new UniformBuffer!mat4(mat4.identity());
        matrix = mat4.identity();
        position_ = vec2(0, 0);
        viewport_ = vec2(0, 0);
    }

    /**
        The viewport position
    */
    ref vec2 position() {
        return position_;
    }

    /**
        The viewport size
    */
    ref vec2 viewport() {
        return viewport_;
    }

    /**
        Updates the camera
    */
    void update() {
        matrix = mat4.orthographic(0, viewport_.x, viewport_.y, 0, -100, 100);// * mat4.translation((viewport_.x/2), (viewport_.y/2), 0);
        cameraBuffer.setState(matrix.transposed);
    }

    /**
        Returns the matrix
    */
    mat4 getMatrix() {
        return matrix;
    }

    /**
        Returns the camera uniform buffer
    */
    UniformBuffer!mat4 getBuffer() {
        return cameraBuffer;
    }
}