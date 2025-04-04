#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <glm/glm.hpp>

const GLuint HEIGHT = 480;
const GLuint WIDTH = (GLuint)(HEIGHT * 4.0f / 3.0f); // 16:9 aspect ratio
const int NUM_AGENTS = 10000;

struct Agent {
    GLfloat x, y, angle;
    GLint species;
};

unsigned int simple_hash_random(int seed) {
    // Use ^ a bunch to make it random
    seed ^= (seed << 13);
    seed ^= (seed >> 17);
    seed ^= (seed << 5);
    seed ^= (seed >> 7);
    seed ^= (seed << 11);
    seed ^= (seed >> 19);
    return seed;
}

// Shader loading and program creation
unsigned int load_shader(const std::string& shader_file, GLenum shader_type) {
    std::ifstream file(shader_file);
    std::stringstream buffer;
    buffer << file.rdbuf();
    std::string source = buffer.str();

    const char* shader_source = source.c_str();
    unsigned int shader = glCreateShader(shader_type);
    glShaderSource(shader, 1, &shader_source, nullptr);
    glCompileShader(shader);

    int success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        char infoLog[1024];
        glGetShaderInfoLog(shader, 512, nullptr, infoLog);
        std::cerr << "Shader compilation failed: " << infoLog << std::endl;
    }

    return shader;
}

unsigned int create_compute_program(const std::string& shader_file) {
    unsigned int compute_shader = load_shader(shader_file, GL_COMPUTE_SHADER);
    unsigned int program = glCreateProgram();
    glAttachShader(program, compute_shader);
    glLinkProgram(program);

    int success;
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        char infoLog[512];
        glGetProgramInfoLog(program, 512, nullptr, infoLog);
        std::cerr << "Program linking failed: " << infoLog << std::endl;
    }

    glDeleteShader(compute_shader);
    return program;
}

unsigned int create_shader_program(const std::string& vertex_file, const std::string& fragment_file) {
    unsigned int vertex_shader = load_shader(vertex_file, GL_VERTEX_SHADER);
    unsigned int fragment_shader = load_shader(fragment_file, GL_FRAGMENT_SHADER);
    
    unsigned int program = glCreateProgram();
    glAttachShader(program, vertex_shader);
    glAttachShader(program, fragment_shader);
    glLinkProgram(program);
    
    int success;
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        char infoLog[512];
        glGetProgramInfoLog(program, 512, nullptr, infoLog);
        std::cerr << "Program linking failed: " << infoLog << std::endl;
    }
    
    glDeleteShader(vertex_shader);
    glDeleteShader(fragment_shader);
    return program;
}

int main() {
    if (!glfwInit()) {
        std::cerr << "GLFW initialization failed!" << std::endl;
        return -1;
    }

    GLFWwindow* window = glfwCreateWindow(WIDTH, HEIGHT, "Random Noise Texture", nullptr, nullptr);
    if (!window) {
        std::cerr << "GLFW window creation failed!" << std::endl;
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        std::cerr << "Failed to initialize GLAD!" << std::endl;
        return -1;
    }

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

    // Create a texture to store noise
    GLuint trailMap, diffusedTrailMap, displayTexture;
    glGenTextures(1, &trailMap);
    glBindTexture(GL_TEXTURE_2D, trailMap);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, WIDTH, HEIGHT, 0, GL_RGBA, GL_FLOAT, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    float currentTime = glfwGetTime();

    int seed = simple_hash_random(static_cast<int>(currentTime)%10000); // Use time as seed
    srand(static_cast<unsigned int>(seed * 1000)); // Seed with time + index

    // Create agents data
    Agent agents[NUM_AGENTS];
    for (int i = 0; i < NUM_AGENTS; ++i) {
        agents[i].x = static_cast<float>(rand()) / RAND_MAX * WIDTH; // Random x position
        agents[i].y = static_cast<float>(rand()) / RAND_MAX * HEIGHT; // Random y position
        // random angle using time
        // Use time + agent index to generate a unique random angle
        // Generate random angle using srand
        agents[i].angle = static_cast<float>(rand()) / RAND_MAX * 2.0f * 3.14159f; // Random angle
        agents[i].species = i % 3; // Random species (0, 1, or 2)

        // std::cout << "Agent " << i << ": (" << agents[i].x << ", " << agents[i].y << "), angle: " << agents[i].angle << std::endl;
        // static_cast<float>(rand()) / RAND_MAX * 2.0f * 3.14159f; // Random angle
    }

    GLuint agentBuffer;
    glGenBuffers(1, &agentBuffer);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, agentBuffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, NUM_AGENTS * sizeof(Agent), agents, GL_STATIC_DRAW);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, agentBuffer);

    // Create and compile compute shader program
    unsigned int compute_program = create_compute_program("../../src/shaders/agents.glsl");
    glUseProgram(compute_program);

    unsigned int diffusion_program = create_compute_program("../../src/shaders/diffusion_shader.glsl");
    glUseProgram(diffusion_program);





    // Bind the noise texture to texture unit 0
    glBindImageTexture(0, trailMap, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA32F);



    // Create shader program for rendering the texture
    unsigned int render_program = create_shader_program("../../src/shaders/quad.vert", "../../src/shaders/quad.frag");
    glUseProgram(render_program);


    // Fullscreen quad
    float vertices[] = {
        -1.0f, -1.0f, 0.0f, 0.0f,
         1.0f, -1.0f, 1.0f, 0.0f,
         1.0f,  1.0f, 1.0f, 1.0f,
        -1.0f, -1.0f, 0.0f, 0.0f,
         1.0f,  1.0f, 1.0f, 1.0f,
        -1.0f,  1.0f, 0.0f, 1.0f
    };

    unsigned int quadVAO, quadVBO;
    glGenVertexArrays(1, &quadVAO);
    glGenBuffers(1, &quadVBO);
    glBindVertexArray(quadVAO);
    glBindBuffer(GL_ARRAY_BUFFER, quadVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)(2 * sizeof(float)));
    glEnableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    // Render loop
    float lastTime = glfwGetTime();
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        float currentTime = glfwGetTime();
        float deltaTime = currentTime - lastTime;
        lastTime = currentTime;

        glClear(GL_COLOR_BUFFER_BIT);

        
        // Update agent positions using compute shader
        glUseProgram(compute_program);
        glUniform1f(glGetUniformLocation(compute_program, "deltaTime"), deltaTime);
        glUniform1f(glGetUniformLocation(compute_program, "time"), currentTime);
        // Pass in NUM_AGENTS uint
        glUniform1ui(glGetUniformLocation(compute_program, "NUM_AGENTS"), NUM_AGENTS);
        // Pass dimensions of the texture to the compute shader as separate uints   
        glUniform1ui(glGetUniformLocation(compute_program, "SCREEN_WIDTH"), WIDTH);
        glUniform1ui(glGetUniformLocation(compute_program, "SCREEN_HEIGHT"), HEIGHT);

        glBindImageTexture(0, trailMap, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA32F);
        int workgroupSize = 16;  // Or 32 for larger workgroups
        glDispatchCompute((NUM_AGENTS + workgroupSize - 1) / workgroupSize, 1, 1); // Round up to fit workgroups

        glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT); // Wait for the compute shader to finish

        // Dispatch the diffusion shader (same size as the texture)
        glUseProgram(diffusion_program);
        glBindImageTexture(0, trailMap, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA32F);
        glUniform1f(glGetUniformLocation(diffusion_program, "deltaTime"), deltaTime);
        glDispatchCompute(WIDTH / 16, HEIGHT / 16, 1);  // Dispatch in 16x16 workgroups
        glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);  // Wait for the diffusion to complete


        // Render the texture to the screen
        glUseProgram(render_program);  // Use rendering program
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, trailMap);  // Bind the updated texture
        glBindVertexArray(quadVAO);
        glDrawArrays(GL_TRIANGLES, 0, 6);  // Draw the texture to the screen
        glBindVertexArray(0);

        glfwSwapBuffers(window);  // Swap the buffer to display the updated frame
    }


    glDeleteTextures(1, &trailMap);
    glDeleteProgram(compute_program);
    glDeleteProgram(render_program);
    glDeleteVertexArrays(1, &quadVAO);
    glDeleteBuffers(1, &quadVBO);

    glfwTerminate();
    return 0;
}
