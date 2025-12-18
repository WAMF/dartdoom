#version 460 core

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uResolution;
uniform float uMode;
uniform sampler2D uTexture;

out vec4 fragColor;

const float kHardScanSoft = -8.0;
const float kHardScanMedium = -12.0;
const float kHardPixSoft = -3.0;
const float kHardPixMedium = -4.0;
const vec2 kWarp = vec2(1.0 / 32.0, 1.0 / 24.0);
const float kMaskDark = 0.5;
const float kMaskLight = 1.5;
const vec2 kDoomRes = vec2(320.0, 200.0);

float toLinear1(float c) {
    return (c <= 0.04045) ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

vec3 toLinear(vec3 c) {
    return vec3(toLinear1(c.r), toLinear1(c.g), toLinear1(c.b));
}

float toSrgb1(float c) {
    return (c < 0.0031308) ? c * 12.92 : 1.055 * pow(c, 0.41666) - 0.055;
}

vec3 toSrgb(vec3 c) {
    return vec3(toSrgb1(c.r), toSrgb1(c.g), toSrgb1(c.b));
}

vec2 getRes() {
    return kDoomRes;
}

vec3 fetch(vec2 pos, vec2 off, vec2 res) {
    pos = (floor(pos * res) + off + 0.5) / res;
    if (pos.x < 0.0 || pos.x > 1.0 || pos.y < 0.0 || pos.y > 1.0) {
        return vec3(0.0);
    }
    return toLinear(texture(uTexture, pos).rgb);
}

vec2 dist(vec2 pos, vec2 res) {
    pos = pos * res;
    return -((pos - floor(pos)) - vec2(0.5));
}

float gaus(float pos, float scale) {
    return exp2(scale * pos * pos);
}

vec3 horz3(vec2 pos, float off, float hardPix, vec2 res) {
    vec3 b = fetch(pos, vec2(-1.0, off), res);
    vec3 c = fetch(pos, vec2(0.0, off), res);
    vec3 d = fetch(pos, vec2(1.0, off), res);
    float dst = dist(pos, res).x;
    float scale = hardPix;
    float wb = gaus(dst - 1.0, scale);
    float wc = gaus(dst + 0.0, scale);
    float wd = gaus(dst + 1.0, scale);
    return (b * wb + c * wc + d * wd) / (wb + wc + wd);
}

vec3 horz5(vec2 pos, float off, float hardPix, vec2 res) {
    vec3 a = fetch(pos, vec2(-2.0, off), res);
    vec3 b = fetch(pos, vec2(-1.0, off), res);
    vec3 c = fetch(pos, vec2(0.0, off), res);
    vec3 d = fetch(pos, vec2(1.0, off), res);
    vec3 e = fetch(pos, vec2(2.0, off), res);
    float dst = dist(pos, res).x;
    float scale = hardPix;
    float wa = gaus(dst - 2.0, scale);
    float wb = gaus(dst - 1.0, scale);
    float wc = gaus(dst + 0.0, scale);
    float wd = gaus(dst + 1.0, scale);
    float we = gaus(dst + 2.0, scale);
    return (a * wa + b * wb + c * wc + d * wd + e * we) / (wa + wb + wc + wd + we);
}

float scan(vec2 pos, float off, float hardScan, vec2 res) {
    float dst = dist(pos, res).y;
    return gaus(dst + off, hardScan);
}

vec3 tri(vec2 pos, float hardScan, float hardPix, vec2 res) {
    vec3 a = horz3(pos, -1.0, hardPix, res);
    vec3 b = horz5(pos, 0.0, hardPix, res);
    vec3 c = horz3(pos, 1.0, hardPix, res);
    float wa = scan(pos, -1.0, hardScan, res);
    float wb = scan(pos, 0.0, hardScan, res);
    float wc = scan(pos, 1.0, hardScan, res);
    return a * wa + b * wb + c * wc;
}

vec2 warp(vec2 pos) {
    pos = pos * 2.0 - 1.0;
    pos *= vec2(1.0 + (pos.y * pos.y) * kWarp.x, 1.0 + (pos.x * pos.x) * kWarp.y);
    return pos * 0.5 + 0.5;
}

vec3 mask(vec2 pos) {
    pos.x += pos.y * 3.0;
    vec3 m = vec3(kMaskDark);
    pos.x = fract(pos.x / 6.0);
    if (pos.x < 0.333) {
        m.r = kMaskLight;
    } else if (pos.x < 0.666) {
        m.g = kMaskLight;
    } else {
        m.b = kMaskLight;
    }
    return m;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    vec2 res = getRes();

    int mode = int(uMode);

    if (mode == 0) {
        fragColor = texture(uTexture, uv);
    } else if (mode == 1) {
        vec2 warpedPos = warp(uv);
        vec3 color = tri(warpedPos, kHardScanMedium, kHardPixMedium, res);
        fragColor = vec4(toSrgb(color), 1.0);
    } else if (mode == 2) {
        vec2 warpedPos = warp(uv);
        vec3 color = tri(warpedPos, kHardScanSoft, kHardPixSoft, res) * mask(fragCoord);
        fragColor = vec4(toSrgb(color), 1.0);
    } else {
        vec3 color = tri(uv, kHardScanSoft, kHardPixSoft, res) * mask(fragCoord);
        fragColor = vec4(toSrgb(color), 1.0);
    }
}
