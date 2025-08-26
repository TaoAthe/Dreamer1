#pragma once

#include "imgui.h"
#include "TextEditor.h"
#include <memory>
#include <string>

class LanguageService;

class EditorWindow {
public:
    EditorWindow();
    ~EditorWindow();

    void Initialize();
    void Render();
    bool ShouldClose() const;
    
    // File operations
    void LoadFile(const std::string& path);
    void SaveFile(const std::string& path);
    
    // Editor operations
    void SetText(const std::string& text);
    std::string GetText() const;

private:
    void SetupImGui();
    void RenderMenuBar();
    void RenderEditor();
    void RenderStatusBar();
    void HandleInput();

private:
    GLFWwindow* window;
    TextEditor editor;
    std::unique_ptr<LanguageService> langService;
    std::string currentFile;
    bool shouldClose;
};
