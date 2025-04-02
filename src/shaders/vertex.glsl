#version 450 core

layout(location = 0) in vec2 vertexPosition; // Vertex position

out vec2 fragTexCoord; // Texture coordinate to pass to fragment shader

void main() {
    fragTexCoord = vertexPosition * 0.5 + 0.5;  // Map from [-1, 1] to [0, 1]
    gl_Position = vec4(vertexPosition, 0.0, 1.0); // Position for fullscreen quad
}
