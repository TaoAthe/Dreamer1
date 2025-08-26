/*
 * Dummy ImGui implementation
 * This is a placeholder implementation that will be used when the actual
 * ImGui library is not available. This allows the plugin to compile
 * but with limited functionality.
 */

#pragma once

namespace ImGui
{
    // Basic types and structures
    struct ImVec2 { float x, y; ImVec2(float _x = 0.0f, float _y = 0.0f) : x(_x), y(_y) {} };
    struct ImVec4 { float x, y, z, w; ImVec4(float _x = 0.0f, float _y = 0.0f, float _z = 0.0f, float _w = 0.0f) : x(_x), y(_y), z(_z), w(_w) {} };

    // Forward declarations
    struct ImGuiContext;
    struct ImGuiIO;

    // Basic functions
    inline ImGuiIO& GetIO() { static ImGuiIO io; return io; }
    
    // Window functions
    inline bool Begin(const char* name, bool* p_open = nullptr, int flags = 0) { return true; }
    inline void End() {}
    
    // Menu functions
    inline bool BeginMenuBar() { return true; }
    inline void EndMenuBar() {}
    inline bool BeginMenu(const char* label, bool enabled = true) { return true; }
    inline void EndMenu() {}
    inline bool MenuItem(const char* label, const char* shortcut = nullptr, bool selected = false, bool enabled = true) { return false; }
    inline bool MenuItem(const char* label, const char* shortcut, bool* p_selected, bool enabled = true) { return false; }
    
    // Layout
    inline void Separator() {}
    inline void SameLine(float offset_from_start_x = 0.0f, float spacing = -1.0f) {}
    
    // Style
    inline void PushStyleVar(int idx, float val) {}
    inline void PushStyleVar(int idx, const ImVec2& val) {}
    inline void PopStyleVar(int count = 1) {}
    
    // Window positioning & sizing
    inline void SetNextWindowPos(const ImVec2& pos, int cond = 0, const ImVec2& pivot = ImVec2(0, 0)) {}
    inline void SetNextWindowSize(const ImVec2& size, int cond = 0) {}
    
    // Text
    inline void Text(const char* fmt, ...) {}
    
    // Status bar
    inline bool BeginStatusBar() { return true; }
    inline void EndStatusBar() {}
    
    // Window width
    inline float GetWindowWidth() { return 0.0f; }
    
    // Window flags
    enum ImGuiWindowFlags_
    {
        ImGuiWindowFlags_None                   = 0,
        ImGuiWindowFlags_NoTitleBar             = 1 << 0,
        ImGuiWindowFlags_NoResize               = 1 << 1,
        ImGuiWindowFlags_NoMove                 = 1 << 2,
        ImGuiWindowFlags_NoScrollbar            = 1 << 3,
        ImGuiWindowFlags_NoScrollWithMouse      = 1 << 4,
        ImGuiWindowFlags_NoCollapse             = 1 << 5,
        ImGuiWindowFlags_AlwaysAutoResize       = 1 << 6,
        ImGuiWindowFlags_NoBackground           = 1 << 7,
        ImGuiWindowFlags_NoSavedSettings        = 1 << 8,
        ImGuiWindowFlags_NoMouseInputs          = 1 << 9,
        ImGuiWindowFlags_MenuBar                = 1 << 10,
        ImGuiWindowFlags_HorizontalScrollbar    = 1 << 11,
        ImGuiWindowFlags_NoFocusOnAppearing     = 1 << 12,
        ImGuiWindowFlags_NoBringToFrontOnFocus  = 1 << 13
    };

    // Style variables
    enum ImGuiStyleVar_
    {
        ImGuiStyleVar_Alpha                     = 0,
        ImGuiStyleVar_WindowPadding             = 1,
        ImGuiStyleVar_WindowRounding            = 2,
        ImGuiStyleVar_FramePadding              = 3,
        ImGuiStyleVar_FrameRounding             = 4,
        ImGuiStyleVar_ItemSpacing               = 5,
        ImGuiStyleVar_ItemInnerSpacing          = 6,
        ImGuiStyleVar_IndentSpacing             = 7,
        ImGuiStyleVar_ScrollbarSize             = 8,
        ImGuiStyleVar_ScrollbarRounding         = 9,
        ImGuiStyleVar_GrabMinSize               = 10,
        ImGuiStyleVar_GrabRounding              = 11,
        ImGuiStyleVar_TabRounding               = 12,
        ImGuiStyleVar_ButtonTextAlign           = 13
    };
}

// Basic IO structure
struct ImGuiIO
{
    // Display size
    float DisplaySize_x = 0.0f;
    float DisplaySize_y = 0.0f;
    ImGui::ImVec2 DisplaySize;
    
    ImGuiIO() : DisplaySize(0, 0) {}
};