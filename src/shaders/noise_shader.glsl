#version 450 core

layout (local_size_x = 1, local_size_y = 1) in;  // One thread per agent

struct Agent {
    ivec2 position;  // Agent position in texture space (integer coordinates)
    float angle;     // Agent's direction in radians
};

// Define the SSBO binding point
layout(binding = 1) buffer AgentBuffer {
    Agent agents[]; // The array of agents
};

layout(binding = 0, rgba32f) uniform image2D trailMap;  // Trail texture

void main() {
    uint agentID = gl_GlobalInvocationID.x;  // Get the ID of the current agent
    
    if (agentID >= 100) {
        return;  // Only process up to NUM_AGENTS agents
    }

    Agent agent = agents[agentID];  // Get the agent from the buffer

    // Update the agent's position based on its angle
    agent.position.x += int(cos(agent.angle) * 2.0f); // Move the agent based on its angle
    agent.position.y += int(sin(agent.angle) * 2.0f);

    // Wrap around if out of bounds
    agent.position.x = int(mod(float(agent.position.x) + 640.0, 640.0)); // Wrap horizontally
    agent.position.y = int(mod(float(agent.position.y) + 480.0, 480.0)); // Wrap vertically

    // Store a white trail at the agent's new position
    imageStore(trailMap, agent.position, vec4(1.0, 1.0, 1.0, 1.0));  // Store white pixel at agent's position

    // Optionally update the agent's position in the array (for the next frame)
    agents[agentID] = agent;
}
