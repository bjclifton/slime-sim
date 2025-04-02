#version 450 core

// Number of agents
#define NUM_AGENTS 100
#define MOVE_SPEED 200.0
#define PI 3.14159265358979323846

struct Agent {
  vec2 position;
  float angle;
};

// Shared memory to store all agents

layout(std430, binding = 0) buffer Agents {
  Agent agents[NUM_AGENTS];
};

// Trail Map
layout(binding = 1, rgba32f) uniform image2D TrailMap;  // Declare TrailMap as rgba32f image2D for both reading and writing

// Time passed since last update
uniform float deltaTime;
uniform float time;  // Pass time as a uniform from C++
// Map size
uniform vec2 mapSize;

// Pseudo random Number Generator
uint hash(uint state)
{
    state ^= 2747636419u;
    state *= 2654435769u;
    state ^= state >> 16;
    state *= 2654435769u;
    state ^= state >> 16;
    state *= 2654435769u;
    return state;
}

float scaleToRange01(uint state)
{
    return state / 4294967295.0;
}


layout(local_size_x = 1) in;

void main() {
  uint id = gl_GlobalInvocationID.x;

  if (id >= NUM_AGENTS) {
    return;
  }

  Agent agent = agents[id];

  vec2 direction = vec2(cos(agent.angle), sin(agent.angle));
  vec2 newPosition = agent.position + direction * deltaTime * MOVE_SPEED;

  // Check if agent is out of bounds
  if (newPosition.x < 0.0 || newPosition.x >= mapSize.x || 
      newPosition.y < 0.0 || newPosition.y >= mapSize.y) {

    // Generate a new random angle using position, id, and time
    uint randomSeed = hash(uint(agent.position.x * 1000.0) + uint(agent.position.y * 1000.0) + id + uint(time * 100000.0));
    float randomAngle = scaleToRange01(randomSeed) * 2.0 * PI; // Convert to radians

    // Clamp to map boundaries
    newPosition.x = clamp(newPosition.x, 1.0, mapSize.x - 1.0);
    newPosition.y = clamp(newPosition.y, 1.0, mapSize.y - 1.0);

    // Update agent's angle
    agent.angle = randomAngle;
  }

  // Update agent's position
  agent.position = newPosition;

  // Update trail map based on the agent's position
  ivec2 coord = ivec2(agent.position);
  vec4 oldTrail = imageLoad(TrailMap, coord);  // Use imageLoad for reading data from the image
  float trailWeight = 0.8; 

  // Write the updated trail to the image (TrailMap)
  imageStore(TrailMap, coord, min(vec4(1.0), oldTrail + vec4(1.0) * trailWeight * deltaTime));

  // Write back the updated agent
  agents[id] = agent;
}
