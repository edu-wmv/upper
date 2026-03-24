//
//  WelcomeBurst.metal
//  upper
//
//  Radial burst effect for the first-launch welcome sequence.
//  Applied as a SwiftUI `.colorEffect` on a fullscreen overlay.
//

#include <metal_stdlib>
using namespace metal;

// ── Noise helpers ──

static float welcomeHash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

static float welcomeNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = welcomeHash(i);
    float b = welcomeHash(i + float2(1.0, 0.0));
    float c = welcomeHash(i + float2(0.0, 1.0));
    float d = welcomeHash(i + float2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// ── Main effect ──

[[stitchable]] half4 welcomeBurst(
    float2 position,
    half4 currentColor,
    float2 size,
    float2 anchor,
    float progress,
    float dimAlpha
) {
    if (progress <= 0.001 && dimAlpha <= 0.001) {
        return half4(0.0h);
    }

    if (progress <= 0.001) {
        return half4(0.0h, 0.0h, 0.0h, half(dimAlpha));
    }

    float2 uv = position / size;
    float2 anchorUV = anchor / size;

    float aspect = size.x / size.y;
    float2 diff = uv - anchorUV;
    diff.x *= aspect;
    float dist = length(diff);

    float n = welcomeNoise(uv * 8.0 + float2(progress * 2.0, 0.0));
    float noisyDist = dist + (n - 0.5) * 0.025;

    float maxRadius = length(float2(aspect, 1.0)) * 1.3;
    float waveRadius = progress * maxRadius;
    float waveWidth = 0.07 + progress * 0.03;

    float waveDist = noisyDist - waveRadius;

    float sigma = waveWidth * 0.5;
    float waveFront = exp(-waveDist * waveDist / (2.0 * sigma * sigma));
    waveFront *= (1.0 - progress * 0.2);

    float cleared = smoothstep(sigma, -sigma * 1.5, waveDist);
    float dimRemaining = dimAlpha * (1.0 - cleared);

    // Iridescent spectral ring with chromatic aberration
    float angle = atan2(diff.y, diff.x);
    float hueBase = angle / (2.0 * M_PI_F) + 0.5;

    float spread = 0.08 * waveFront;
    float hueR = fract(hueBase + spread + progress * 0.5 + dist);
    float hueG = fract(hueBase + progress * 0.5 + dist);
    float hueB = fract(hueBase - spread + progress * 0.5 + dist);

    half r = half(sin(hueR * 6.283) * 0.5 + 0.5) * half(waveFront);
    half g = half(sin(hueG * 6.283) * 0.5 + 0.5) * half(waveFront);
    half b = half(sin(hueB * 6.283) * 0.5 + 0.5) * half(waveFront);

    half brightness = half(waveFront) * 0.6h;
    half3 waveColor = half3(r, g, b) * 0.7h + half3(brightness * 0.3h);

    float waveAlpha = waveFront * 0.5;
    float finalAlpha = max(dimRemaining, waveAlpha);
    half3 finalColor = waveColor;

    float endFade = smoothstep(0.9, 1.0, progress);
    finalAlpha *= (1.0 - endFade);
    finalColor *= half(1.0 - endFade);

    return half4(finalColor, half(finalAlpha));
}