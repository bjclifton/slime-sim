#version 450 core

layout (local_size_x = 16, local_size_y = 16) in;  // One thread per agent

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
uniform uint NUM_AGENTS; // Number of agents to process
const float RANDOM_TURN = 0.2;  // Random turn factor
const float BASE_SPEED = 100.0;  // Base speed of the agents
uniform uint SCREEN_WIDTH;  // Screen width
uniform uint SCREEN_HEIGHT; // Screen height

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

// Function to sense the trail strength in a given direction, only sensing its own color
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

    // Sample the trail map at the sensor position to get the trail color
    vec4 trailColor = imageLoad(trailMap, sensorCoord);

    // ATTRACTION TO SIMILAR COLOR
    // vec4 agentColor = vec4(0.0, 0.0, 0.0, 0.0); // Default color (black)
    // agentColor = imageLoad(trailMap, ivec2(agent.x, agent.y)); // Load the agent's color

    // Calculate the weight using abs difference between each rgb channel
    // float weight = 0.0;
    // weight += abs(trailColor.r - agentColor.r); // Red channel difference
    // weight += abs(trailColor.g - agentColor.g); // Green channel difference
    // weight += abs(trailColor.b - agentColor.b); // Blue channel difference

    // return 1.0 - (weight / 3.0); // Normalize to [0, 1] range

    // ATTRACTION TO SPECIES 
    if (agent.species == 0) {
        return trailColor.r; // Red channel for species 0
    } else if (agent.species == 1) {
        return trailColor.g; // Green channel for species 1
    } else if (agent.species == 2) {
        return trailColor.b; // Blue channel for species 2
    }
    return 0.0; // Default case (should not happen)
}


// Function to reflect the agent's angle when it hits a wall
void bounceOffWalls(inout Agent agent) {
    // Reflect the agent's direction upon hitting the boundaries (bounce effect)
    if (agent.x <= 0.0 || agent.x >= SCREEN_WIDTH) {
        agent.angle = 3.1415 - agent.angle; // Reflect horizontally
    }
    if (agent.y <= 0.0 || agent.y >= SCREEN_HEIGHT) {
        agent.angle = -agent.angle; // Reflect vertically
    }
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
    // float randomAngleVariation = scaleToRange01(randomState) * 2.0 * RANDOM_TURN - RANDOM_TURN;  // Random angle change

    // // Apply the random angle variation to the agent's current angle
    // agent.angle += randomAngleVariation;

    // Calculate the agent's movement speed adjusted by deltaTime
    float speed = BASE_SPEED * deltaTime;  // Adjust movement based on deltaTime

    // Sense the environment
    float weightForward = sense(agent, 0.0);  // Forward sensing
    float weightLeft = sense(agent, 3.1415 / 8.0);  // Left sensing (45 degrees)
    float weightRight = sense(agent, -3.1415 / 8.0); // Right sensing (-45 degrees)

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

    // Introduce some randomness to the movement for wiggling effect
    agent.angle += randomSteerStrength * RANDOM_TURN;

    // Reflect agent's direction if it hits the screen boundaries (bounce effect)
    bounceOffWalls(agent);

    // Ensure the agent's position stays within the screen bounds
    agent.x = clamp(agent.x, 0.0, float(SCREEN_WIDTH - 1));
    agent.y = clamp(agent.y, 0.0, float(SCREEN_HEIGHT - 1));

    // Convert agent's position to integer coordinates for the trail texture
    ivec2 intPos = ivec2(floor(agent.x), floor(agent.y));

    // Assign a color based on the agent's species
    ivec4 color = ivec4(0, 0, 0, 0); // Default color (black)

    // Map species to color
    if (agent.species == 0) {
        color = ivec4(1.0, 0.0, 1.0, 1.0);  // Red for species 0
    } else if (agent.species == 1) {
        color = ivec4(1.0, 0.0, 1.0, 1.0);  // Green for species 1
    } else if (agent.species == 2) {
        color = ivec4(1.0, 0.0, 1.0, 1.0);  // Blue for species 2
    }

    // Store the color in the trail texture at the agent's position
    imageStore(trailMap, intPos, color);

    // Optionally update the agent's position for the next frame
    agents[agentID] = agent;
}
