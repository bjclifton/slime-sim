#version 450 core

in vec2 fragTexCoord;  // Texture coordinates passed from vertex shader
out vec4 fragColor;    // Final color to be rendered

uniform sampler2D trailMap; // The texture containing the trail map

void main() {
    fragColor = texture(trailMap, fragTexCoord);  // Sample the TrailMap texture
}
