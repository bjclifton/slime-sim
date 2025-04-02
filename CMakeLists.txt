cmake_minimum_required(VERSION 4.0.0)
project(hello_window VERSION 1.0.0)

find_package(OpenGL REQUIRED)

# Add your source files
add_executable(hello_window
    src/config.h
    src/main.cpp
    src/glad.c
    src/config.cpp
    src/material.cpp
)

# Specify the path to the GLFW headers
target_include_directories(hello_window PRIVATE dependencies) # Adjust the path to your GLFW include folder

# Add the path to the GLFW libraries
target_link_directories(hello_window PRIVATE
    ${CMAKE_SOURCE_DIR}/dependencies/lib-vc2019 # Adjust to your version and path
)

# Link the GLFW library (GLFW3 library if using the appropriate folder)
target_link_libraries(hello_window glfw3 OpenGL::GL)