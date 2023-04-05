/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/

@group(0) @binding(0)
var t_diffuse: texture_2d<f32>;

@group(0) @binding(1)
var s_diffuse: sampler;

@group(1) @binding(0)
var<uniform> camera: mat4x4<f32>;

struct vtxin {
    @location(0) position: vec2<f32>,
    @location(1) uvs: vec2<f32>,
    @location(2) color: vec4<f32>,
};

struct vtxout {
    @builtin(position) pos: vec4<f32>,
    @location(1) uvs: vec2<f32>,
    @location(2) color: vec4<f32>,
}

@vertex
fn vs_main(in: vtxin) -> vtxout {
    var out: vtxout;
    out.pos = camera * vec4<f32>(in.position, 0.0, 1.0);
    out.uvs = in.uvs;
    out.color = in.color;
    return out;
}

@fragment
fn fs_main(in: vtxout) -> @location(0) vec4<f32> {
    let ratio = 0.01;
    return textureSample(t_diffuse, s_diffuse, in.uvs) * in.color;
}