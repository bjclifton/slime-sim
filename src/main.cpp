#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <fstream>
#include <sstream>

const GLuint WIDTH = 640, HEIGHT = 480;
const int NUM_AGENTS = 1;

struct Agent {
    GLint x, y;
    GLfloat angle;
};

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
        char infoLog[512];
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

    // Create agents data
    Agent agents[NUM_AGENTS];
    for (int i = 0; i < NUM_AGENTS; ++i) {
        agents[i].x = rand() % WIDTH;
        agents[i].y = rand() % HEIGHT;
        agents[i].angle = 0.785f;
        // static_cast<float>(rand()) / RAND_MAX * 2.0f * 3.14159f; // Random angle
    }

    GLuint agentBuffer;
    glGenBuffers(1, &agentBuffer);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, agentBuffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, NUM_AGENTS * sizeof(Agent), agents, GL_STATIC_DRAW);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, agentBuffer);

    // Create and compile compute shader program
    unsigned int compute_program = create_compute_program("../../src/shaders/noise_shader.glsl");
    glUseProgram(compute_program);

    // Bind the noise texture to texture unit 0
    glBindImageTexture(0, trailMap, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA32F);



    // Create shader program for rendering the texture
    unsigned int render_program = create_shader_program("../../src/shaders/quad.vert", "../../src/shaders/quad.frag");
    glUseProgram(render_program);

    // Pass the texture to the fragment shader
    glUniform1i(glGetUniformLocation(render_program, "noiseTexture"), 0);

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
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        glClear(GL_COLOR_BUFFER_BIT);
        
        // Update agent positions using compute shader
        glUseProgram(compute_program);
        glBindImageTexture(0, trailMap, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA32F);
        glDispatchCompute(WIDTH / 16, HEIGHT / 16, 1); // Dispatch in 16x16 workgroups for the entire texture
        glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT); // Wait for the compute shader to finish

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
