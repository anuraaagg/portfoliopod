//
//  Shaders.metal
//  portfoliopod
//
//  Metal shader for brushed aluminum device shell
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    return out;
}

// Simple hash function for noise
float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// 2D noise function
float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Vertical grain noise
float grain(float2 uv, float scale) {
    float grainValue = noise(uv * scale);
    // Make it more vertical/directional
    grainValue = abs(grainValue - 0.5) * 2.0;
    return grainValue;
}

// Edge vignette
float vignette(float2 uv, float amount) {
    float2 center = float2(0.5, 0.5);
    float dist = distance(uv, center);
    return 1.0 - smoothstep(0.3, 0.7, dist) * amount;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                               constant float2 &resolution [[buffer(0)]],
                               constant float &time [[buffer(1)]],
                               constant float &lightAngle [[buffer(2)]],
                               constant float &roughness [[buffer(3)]],
                               constant float &grainScale [[buffer(4)]],
                               constant float &vignetteAmount [[buffer(5)]]) {
    float2 uv = in.texCoord;
    
    // Base aluminum color (modern matte gray/silver)
    float3 baseColor = float3(0.85, 0.85, 0.88);
    
    // Vertical Grain Architecture
    // We use a high-frequency noise stretched vertically
    float2 grainUV = uv * float2(500.0, 5.0); // Extreme horizontal stretch for vertical grain
    float grainValue = noise(grainUV);
    
    // Anisotropic Modulation
    // Simulate how light stretches across the surface
    float anisotropic = pow(abs(sin(uv.x * 3.14159 + lightAngle)), 2.0) * 0.05;
    
    // Grain intensity ≤ 3%
    float grainIntensity = (grainValue - 0.5) * 0.03;
    
    // Combine base, grain, and anisotropic lighting
    float3 color = baseColor + grainIntensity + float3(anisotropic);
    
    // Edge Vignette (Simulating ambient occlusion and material depth)
    float2 centeredUV = uv * 2.0 - 1.0;
    float vign = 1.0 - dot(centeredUV, centeredUV) * vignetteAmount;
    color *= vign;
    
    // Soft lighting falloff (slight vertical gradient)
    color *= (1.0 - uv.y * 0.05);
    
    // Gamma correction for material realism
    color = pow(max(color, 0.0), float3(1.0 / 2.2));
    
    return float4(color, 1.0);
}
