#version 450 core

in vec2 TexCoords; // Passed from vertex shader
out vec4 FragColor;

uniform sampler2D noiseTexture; // Sampler for the noise texture

void main() {
    // Sample the texture at the given texture coordinates
    FragColor = texture(noiseTexture, TexCoords);
}
