#version 450 core

layout (local_size_x = 16, local_size_y = 16) in;

layout(binding = 0, rgba32f) uniform image2D noiseTexture;

// Simple hash function
uint hash(uint state) {
    state ^= 2747636419u;
    state *= 2654435769u;
    state ^= state >> 16;
    state *= 2654435769u;
    state ^= state >> 16;
    state *= 2654435769u;
    return state;
}

// Scale the hash value to the range [0, 1]
float scaleToRange01(uint state) {
    return float(state) / 4294967295.0;
}

void main() {
    ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy); // Get the pixel coordinates

    // Generate a unique hash for each pixel based on its coordinates
    uint state = uint(pixel_coords.x) + uint(pixel_coords.y) * 1024u; // Simple hash based on coordinates
    uint hashed = hash(state);

    // Scale the hashed value to the range [0, 1]
    float noiseValue = scaleToRange01(hashed);

    // Store the nosie value as a grayscale color
    imageStore(noiseTexture, pixel_coords, vec4(noiseValue, noiseValue, noiseValue, 1.0)); // Store the noise value in the texture
}
