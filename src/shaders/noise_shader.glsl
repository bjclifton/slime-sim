#version 450 core

layout (local_size_x = 1, local_size_y = 1) in;  // One thread per agent

// Struct to represent each agent
struct Agent {
    float x;     // Agent's position (x-coordinate)
    float y;     // Agent's position (y-coordinate)
    float angle; // Agent's direction in radians
    int species; // Agent's species identifier
};

// Buffer to store the agents
layout(binding = 1) buffer AgentBuffer {
    Agent agents[]; // Array of agents
};

// Uniform variables
layout(binding = 0, rgba32f) uniform image2D trailMap;  // Trail texture
uniform float deltaTime;  // Time passed since last frame
uniform float time;       // Current time in seconds

// Constants for simulation
const uint NUM_AGENTS = 10000;  // Number of agents to process
const float RANDOM_TURN = 0.04;  // Random turn factor
const float BASE_SPEED = 100.0;  // Base speed of the agents
const uint SCREEN_WIDTH = 1280;  // Screen width
const uint SCREEN_HEIGHT = 720; // Screen height

// Simple hash function to generate pseudo-random numbers
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

// Function to sense the trail strength in a given direction
float sense(Agent agent, float sensorAngleOffset) {
    // Determine the sensor's direction based on its angle and offset
    float sensorAngle = agent.angle + sensorAngleOffset;
    vec2 sensorDir = vec2(cos(sensorAngle), sin(sensorAngle));
    
    // Determine the position of the sensor (just slightly offset from the agent)
    vec2 sensorPos = vec2(agent.x, agent.y) + sensorDir * 10.0; // Using a fixed offset of 10 units for sensing
    ivec2 sensorCoord = ivec2(floor(sensorPos.x), floor(sensorPos.y));

    // Clamp the sensor coordinates to the screen bounds
    sensorCoord.x = int(clamp(sensorCoord.x, 0, SCREEN_WIDTH - 1));
    sensorCoord.y = int(clamp(sensorCoord.y, 0, SCREEN_HEIGHT - 1));

    // Sample the trail map at the sensor position to get the trail strength (the color intensity)
    vec4 trailColor = imageLoad(trailMap, sensorCoord);
    
    // The intensity of the trail (can be based on the red, green, or blue component)
    // Assuming species 0 corresponds to red, species 1 to green, and species 2 to blue
    float senseWeight = 0.0;
    if (agent.species == 0) {
        senseWeight = trailColor.r;  // Red channel for species 0
    } else if (agent.species == 1) {
        senseWeight = trailColor.g;  // Green channel for species 1
    } else if (agent.species == 2) {
        senseWeight = trailColor.b;  // Blue channel for species 2
    }
    
    return senseWeight;
}

// Main function to update the agents and store their trails
void main() {
    uint agentID = gl_GlobalInvocationID.x;  // Get the ID of the current agent
    
    if (agentID >= NUM_AGENTS) {
        return;  // Skip if agent ID exceeds the total number of agents
    }

    // Retrieve the agent's data from the buffer
    Agent agent = agents[agentID];

    // Generate a random value for the agent based on its position and the current time
    uint randomState = hash(agentID + uint(agent.x * 100 + agent.y) + uint(time * 10));
    float randomAngleVariation = scaleToRange01(randomState) * 2.0 * RANDOM_TURN - RANDOM_TURN;  // Random angle change

    // Apply the random angle variation to the agent's current angle
    agent.angle += randomAngleVariation;

    // Calculate the agent's movement speed adjusted by deltaTime
    float speed = BASE_SPEED * deltaTime;  // Adjust movement based on deltaTime

    // Sense the environment
    float weightForward = sense(agent, 0.0);  // Forward sensing
    float weightLeft = sense(agent, 3.1415 / 4.0);  // Left sensing (45 degrees)
    float weightRight = sense(agent, -3.1415 / 4.0); // Right sensing (-45 degrees)

    // Decision making based on sensed environment
    float randomSteerStrength = scaleToRange01(randomState) + 0.2; // from .2 to 1.2
    float turnSpeed = 0.1 * 3.1415; // Arbitrary turn speed factor

    // If the forward direction is clear, keep going straight
    if (weightForward > weightLeft && weightForward > weightRight) {
        agent.angle += 0.0;  // No change in angle
    } else if (weightLeft > weightRight) {
        agent.angle += randomSteerStrength * turnSpeed;  // Turn left
    } else {
        agent.angle -= randomSteerStrength * turnSpeed;  // Turn right
    }

    // Update agent's position based on its angle and speed
    agent.x += cos(agent.angle) * speed;
    agent.y += sin(agent.angle) * speed;

    // Ensure the agent wraps around the screen edges (WIDTH x HEIGHT)
    if (agent.x < 0.0) {
        agent.x += SCREEN_WIDTH;
    } else if (agent.x >= SCREEN_WIDTH) {
        agent.x -= SCREEN_WIDTH;
    }

    if (agent.y < 0.0) {
        agent.y += SCREEN_HEIGHT;
    } else if (agent.y >= SCREEN_HEIGHT) {
        agent.y -= SCREEN_HEIGHT;
    }

    // Convert agent's position to integer coordinates for the trail texture
    ivec2 intPos = ivec2(floor(agent.x), floor(agent.y));

    // Assign a color based on the agent's species
    ivec4 color = ivec4(0, 0, 0, 0); // Default color (black)

    // Map species to color
    if (agent.species == 0) {
        color = ivec4(1, 0, 0, 1);  // Red for species 0
    } else if (agent.species == 1) {
        color = ivec4(0, 1, 0, 1);  // Green for species 1
    } else if (agent.species == 2) {
        color = ivec4(0, 0, 1, 1);  // Blue for species 2
    }

    // Store the color in the trail texture at the agent's position
    imageStore(trailMap, intPos, color);

    // Optionally update the agent's position for the next frame
    agents[agentID] = agent;
}
