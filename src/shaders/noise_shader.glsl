#version 450 core

layout (local_size_x = 1, local_size_y = 1) in;  // One thread per agent

struct Agent {
    float x; 
    float y;  // Agent's position
    float angle;    // Agent's direction in radians
    int species;
};

// Define the SSBO binding point
layout(binding = 1) buffer AgentBuffer {
    Agent agents[]; // The array of agents
};

layout(binding = 0, rgba32f) uniform image2D trailMap;  // Trail texture

// Uniform for time and deltaTime
uniform float deltaTime;  // Time passed since last frame

// Control speed independently of deltaTime
uniform float baseSpeed = 250.0f; // Base speed of agent movement (this controls the speed)

void main() {
    uint agentID = gl_GlobalInvocationID.x;  // Get the ID of the current agent
    
    if (agentID >= 100) {
        return;  // Only process up to NUM_AGENTS agents
    }

    Agent agent = agents[agentID];  // Get the agent from the buffer

    // Calculate speed adjusted by deltaTime
    float speed = baseSpeed * deltaTime;  // Move based on deltaTime
    

    // Update the agent's position based on its angle
    agent.x += cos(agent.angle) * speed; // Move the agent based on its angle
    agent.y += sin(agent.angle) * speed;

    // Ensure the agent wraps around the screen edges 640 x 480
    if (agent.x < 0.0) {
        agent.x += 640.0;  // Wrap around to the right edge
    } else if (agent.x >= 640.0) {
        agent.x -= 640.0;  // Wrap around to the left edge
    }
    if (agent.y < 0.0) {
        agent.y += 480.0;  // Wrap around to the bottom edge
    } else if (agent.y >= 480.0) {
        agent.y -= 480.0;  // Wrap around to the top edge
    }


    // Round to nearest integer before storing
    ivec2 intPos = ivec2(floor(agent.x), floor(agent.y));  // Convert to integer coordinates

    // Store a trail based on species
    ivec4 color = ivec4(0, 0, 0, 0);  // Default color (black)
    if (agent.species == 0) {
        color = ivec4(1, 0, 0, 1);  // Red for species 0
    } else if (agent.species == 1) {
        color = ivec4(0, 1, 0, 1);  // Green for species 1
    } else if (agent.species == 2) {
        color = ivec4(0, 0, 1, 1);  // Blue for species 2
    }
    // Store the color in the trail map at the agent's position

    imageStore(trailMap, intPos, color);  // Store white pixel at agent's position

    // Optionally update the agent's position in the array (for the next frame)
    agents[agentID] = agent;
}
