#include "editor_window.h"
#include "language_service.h"
#include <GLFW/glfw3.h>
#include <iostream>

int main(int argc, char** argv) {
    // Initialize GLFW
    if (!glfwInit()) {
        std::cerr << "Failed to initialize GLFW\n";
        return -1;
    }

    // Create editor window
    EditorWindow editor;
    editor.Initialize();

    // Main loop
    while (!editor.ShouldClose()) {
        editor.Render();
        glfwPollEvents();
    }

    // Cleanup
    glfwTerminate();
    return 0;
}
