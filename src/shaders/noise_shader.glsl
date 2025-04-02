#version 450 core

layout (local_size_x = 16, local_size_y = 16) in;

layout(binding = 0, rgba32f) uniform image2D noiseTexture;

void main() {
    ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy); // Get the pixel coordinates

    // For debugging, let's output a known color
    imageStore(noiseTexture, pixel_coords, vec4(1.0, 0.0, 0.0, 1.0));  // Red


}
