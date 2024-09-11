#include <metal_stdlib>
using namespace metal;

vertex float4 vertexShader(uint vertexID [[vertex_id]],
                           constant float3 *vertices [[buffer(0)]])
{
  return float4(vertices[vertexID], 1.0);
}

fragment float4 fragmentShader()
{
  return float4(1.0, 0.0, 0.0, 1.0);
}