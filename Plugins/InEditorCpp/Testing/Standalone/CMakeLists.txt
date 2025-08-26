# CMake minimum version requirement
cmake_minimum_required(VERSION 3.20)

# Project name
project(InEditorCppStandalone)

# C++ standard requirement
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add ImGui
add_subdirectory(vendor/imgui)

# Add ImGuiColorTextEdit
add_subdirectory(vendor/ImGuiColorTextEdit)

# Add GLFW for window management
find_package(glfw3 REQUIRED)

# Find clangd
find_program(CLANGD_EXECUTABLE clangd)
if(NOT CLANGD_EXECUTABLE)
    message(FATAL_ERROR "clangd not found!")
endif()

# Main executable
add_executable(standalone_editor
    src/main.cpp
    src/editor_window.cpp
    src/language_service.cpp
)

# Include directories
target_include_directories(standalone_editor PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor/imgui
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor/ImGuiColorTextEdit
)

# Link libraries
target_link_libraries(standalone_editor PRIVATE
    imgui
    ImGuiColorTextEdit
    glfw
)
