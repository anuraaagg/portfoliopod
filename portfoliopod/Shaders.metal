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

// -----------------------------------------------------------------------------
// Helper Functions for PBR-lite
// -----------------------------------------------------------------------------

// Better hash for high-frequency noise
float hash21(float2 p) {
    p = fract(p * float2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

// Micro-grain noise (High Frequency - Bead Blasted)
float microGrain(float2 uv, float strength) {
    float n = hash21(uv * 4000.0); // Very high frequency for bead-blast
    return (n - 0.5) * strength;
}

// Fresnel Schlick approximation
float fresnel(float cosTheta, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

// -----------------------------------------------------------------------------
// Fragment Shader
// -----------------------------------------------------------------------------

fragment float4 fragment_main(VertexOut in [[stage_in]],
                               constant float2 &resolution [[buffer(0)]],
                               constant float &time [[buffer(1)]],
                               constant float &lightAngle [[buffer(2)]],
                               constant float &roughness [[buffer(3)]], // Unused, hardcoded for consistency
                               constant float &grainScale [[buffer(4)]],
                               constant float &vignetteAmount [[buffer(5)]]) {
    float2 uv = in.texCoord;
    
    // -------------------------------------------------------------------------
    // 1. Material Properties (Classic 6th Gen Matte Aluminum)
    // -------------------------------------------------------------------------
    // Darker slate/blue-gray base color (matches modern "Space Gray" or "Slate")
    // Neutral "Industrial Slate" base color
    float3 albedo = float3(0.18, 0.2, 0.22); 
    float metalRoughness = 0.7; // Even more matte
    
    // -------------------------------------------------------------------------
    // 2. Micro-Surface Detail (Bead-Blasted Grain)
    // -------------------------------------------------------------------------
    // Add ultra-fine noise to albedo and normals
    float grain = microGrain(uv, 0.08);
    albedo += grain; 
    
    // -------------------------------------------------------------------------
    // 3. PBR-lite Lighting Environment
    // -------------------------------------------------------------------------
    // We simulate a lighting environment that rotates with the gyro (lightAngle)
    
    // Surface Normal (approx flat for 2D, but with subtle curvature implied)
    float3 N = normalize(float3(0.0, 0.0, 1.0));
    
    // Light Direction (Dynamic based on gyro)
    // Simulate a main soft light source moving horizontally
    // lightAngle is roughly tilt in X axis. width/height not available but UV is 0-1.
    float3 L = normalize(float3(sin(lightAngle), 0.2, 1.0)); // Z=1 keeps it somewhat front-facing
    
    // View Direction (Camera is looking -Z)
    float3 V = float3(0.0, 0.0, 1.0);
    
    // Half Vector
    float3 H = normalize(L + V);
    
    // Dot products
    float NdotL = max(dot(N, L), 0.0);
    float NdotH = max(dot(N, H), 0.0);
    
    // Diffuse Term (Simplified Lambert for matte)
    // We wrap it slightly to simulate subsurface scattering/softness of anodizing
    float diffuse = (NdotL * 0.5 + 0.5); 
    
    // Specular Term (Blinn-Phong approximation for rough surface)
    float specPower = (1.0 - metalRoughness) * 20.0; // Low power for matte
    float specular = pow(NdotH, specPower) * 0.15; // Low intensity
    
    // Fresnel (Edges get lighter)
    // float edgeFresnel = fresnel(NdotV, F0); // Not used heavily in PBR-lite here for base metal
    
    // -------------------------------------------------------------------------
    // 4. Composition
    // -------------------------------------------------------------------------
    
    float3 finalColor = albedo * diffuse + float3(specular);
    
    // Add subtle ambient gradient (Top lighter, bottom darker)
    finalColor *= (1.05 - uv.y * 0.1);
    
    // Edge darkening (Vignette) for curvature
    float2 centeredUV = uv * 2.0 - 1.0;
    float dist = dot(centeredUV, centeredUV);
    float rim = smoothstep(0.7, 1.4, dist);
    finalColor *= (1.0 - rim * 0.6); // Darken edges
    
    // Add a subtle "rim light" catch on the very edge
    float edgeCatch = smoothstep(0.95, 1.0, dist) * smoothstep(1.05, 1.0, dist);
    finalColor += float3(0.2) * edgeCatch; // Slight metallic glint on edge curve

    // Gamma correction
    return float4(pow(finalColor, float3(1.0/2.2)), 1.0);
}
