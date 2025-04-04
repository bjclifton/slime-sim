#version 450 core

layout (local_size_x = 16, local_size_y = 16) in;

layout(binding = 0, rgba32f) uniform image2D trailMap;  // The trail texture

float decayRate = 0.1;  // Rate at which trail fades
uniform float deltaTime;   // Time passed since last frame

void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);  // Get pixel position

    // Read the current color at this pixel
    vec4 currentColor = imageLoad(trailMap, pos);

    // Get average of the surrounding pixels
    vec4 sum = vec4(0.0);
    int count = 0;
    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            ivec2 neighborPos = pos + ivec2(x, y);
            // Ensure neighbor position is within bounds
            if (neighborPos.x < 0 || neighborPos.x >= imageSize(trailMap).x ||
                neighborPos.y < 0 || neighborPos.y >= imageSize(trailMap).y) {
                continue;  // Skip out-of-bounds neighbors
            }
            // Load the color of the neighbor pixel
            vec4 neighborColor = imageLoad(trailMap, neighborPos);
            sum += neighborColor;
            count++;
        }
    }

    // Calculate the average color of the surrounding pixels
    if (count > 0) {
        sum /= float(count);
    }

    currentColor = mix(currentColor, sum, 0.1);  // Blend current color with average
    //currentColor = mix(currentColor, vec4(0.0, 0.0, 0.0, 1.0), 0.1);  // Blend with black

    // Apply decay to the color's alpha channel (transparency)
    currentColor.r -= deltaTime * decayRate;  // Reduce red over time
    currentColor.g -= deltaTime * decayRate;  // Reduce green over time
    currentColor.b -= deltaTime * decayRate;  // Reduce blue over time

    // Store the updated color back into the texture
    imageStore(trailMap, pos, currentColor);
}
