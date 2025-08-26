#include "editor_window.h"
#include "language_service.h"
#include <GLFW/glfw3.h>
#include <iostream>

EditorWindow::EditorWindow() 
    : window(nullptr)
    , langService(std::make_unique<LanguageService>())
    , shouldClose(false)
{
    editor.SetLanguageDefinition(TextEditor::LanguageDefinition::CPlusPlus());
}

EditorWindow::~EditorWindow() {
    if (window) {
        glfwDestroyWindow(window);
    }
}

void EditorWindow::Initialize() {
    // Create window
    window = glfwCreateWindow(1280, 720, "Standalone C++ Editor", nullptr, nullptr);
    if (!window) {
        std::cerr << "Failed to create window\n";
        return;
    }
    glfwMakeContextCurrent(window);

    // Setup ImGui
    SetupImGui();

    // Initialize language service
    if (!langService->Initialize()) {
        std::cerr << "Failed to initialize language service\n";
    }
}

void EditorWindow::Render() {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();

    // Create main window
    ImGui::SetNextWindowPos(ImVec2(0, 0));
    ImGui::SetNextWindowSize(ImGui::GetIO().DisplaySize);
    ImGui::Begin("Editor", nullptr, 
        ImGuiWindowFlags_MenuBar | 
        ImGuiWindowFlags_NoMove | 
        ImGuiWindowFlags_NoResize | 
        ImGuiWindowFlags_NoTitleBar);

    RenderMenuBar();
    RenderEditor();
    RenderStatusBar();

    ImGui::End();

    // Render ImGui
    ImGui::Render();
    int display_w, display_h;
    glfwGetFramebufferSize(window, &display_w, &display_h);
    glViewport(0, 0, display_w, display_h);
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

    glfwSwapBuffers(window);
}

void EditorWindow::RenderMenuBar() {
    if (ImGui::BeginMenuBar()) {
        if (ImGui::BeginMenu("File")) {
            if (ImGui::MenuItem("Open", "Ctrl+O")) {
                // TODO: Add file dialog
            }
            if (ImGui::MenuItem("Save", "Ctrl+S")) {
                SaveFile(currentFile);
            }
            if (ImGui::MenuItem("Save As..", "Ctrl+Shift+S")) {
                // TODO: Add file dialog
            }
            ImGui::Separator();
            if (ImGui::MenuItem("Exit")) {
                shouldClose = true;
            }
            ImGui::EndMenu();
        }
        ImGui::EndMenuBar();
    }
}

void EditorWindow::RenderEditor() {
    editor.Render("TextEditor");
}

void EditorWindow::RenderStatusBar() {
    ImGui::Text("Line: %d/%d Col: %d", 
        editor.GetCursorPosition().mLine + 1,
        editor.GetTotalLines(),
        editor.GetCursorPosition().mColumn + 1);
}

bool EditorWindow::ShouldClose() const {
    return shouldClose || glfwWindowShouldClose(window);
}

void EditorWindow::LoadFile(const std::string& path) {
    // TODO: Implement file loading
}

void EditorWindow::SaveFile(const std::string& path) {
    // TODO: Implement file saving
}

void EditorWindow::SetText(const std::string& text) {
    editor.SetText(text);
}
