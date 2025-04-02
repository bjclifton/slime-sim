#version 450 core

in vec2 fragTexCoord;
out vec4 fragColor;

uniform sampler2D trailMap;  // The texture containing the trail map

void main() {
    fragColor = texture(trailMap, fragTexCoord);  // Sample the texture and render it
}
