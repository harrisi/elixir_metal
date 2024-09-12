#include <metal_stdlib>
using namespace metal;

struct VertexOut {
  float4 position [[position]];
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                           constant float3 *vertices [[buffer(0)]],
                           constant float4x4 &transform [[buffer(1)]]
                           )
{
  VertexOut out;
  float4 position = float4(vertices[vertexID], 1.0);
  out.position = transform * position;
  return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]])
{
  return float4(1.0, 0.0, 0.0, 1.0);
}