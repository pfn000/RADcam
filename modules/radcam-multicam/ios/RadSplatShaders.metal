#include <metal_stdlib>
using namespace metal;

kernel void radialSplatKernel(
  texture2d<float, access::sample> source [[texture(0)]],
  texture2d<float, access::read_write> destination [[texture(1)]],
  uint2 gid [[thread_position_in_grid]]) {
  if (gid.x >= destination.get_width() || gid.y >= destination.get_height()) {
    return;
  }

  constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
  float2 uv = float2(gid) / float2(destination.get_width(), destination.get_height());

  float2 centered = uv * 2.0 - 1.0;
  float r = length(centered);
  float theta = atan2(centered.y, centered.x);

  float warpedR = pow(r, 1.2);
  float2 warped = float2(cos(theta), sin(theta)) * warpedR;
  float2 sourceUV = (warped + 1.0) * 0.5;

  float4 pixel = source.sample(s, sourceUV);
  float glow = smoothstep(0.85, 0.15, r);
  float3 tint = mix(pixel.rgb, float3(0.15, 0.4, 1.0), glow * 0.25);

  float4 prev = destination.read(gid);
  destination.write(float4(max(prev.rgb, tint), 1.0), gid);
}

kernel void compositeKernel(
  texture2d<float, access::read> source [[texture(0)]],
  texture2d<float, access::write> destination [[texture(1)]],
  uint2 gid [[thread_position_in_grid]]) {
  if (gid.x >= source.get_width() || gid.y >= source.get_height()) {
    return;
  }

  float4 pixel = source.read(gid);
  float vignette = 1.0 - smoothstep(0.2, 1.0, length((float2(gid) / float2(source.get_width(), source.get_height())) * 2.0 - 1.0));
  destination.write(float4(pixel.rgb * (0.65 + 0.35 * vignette), 1.0), gid);
}
