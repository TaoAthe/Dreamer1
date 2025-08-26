/*
 * File: /Source/InEditorCpp/Public/SCppEditor.h
 * 
 * Purpose: Native Code Editor Widget Header
 * Declares the primary editor widget class that provides native C++ editing
 * within Unreal Engine using ImGui and ImGuiColorTextEdit.
 */

#pragma once

#include "CoreMinimal.h"
#include "Widgets/SCompoundWidget.h"

// Conditionally include ImGui
#if WITH_IMGUI
#include "imgui.h"
#endif

// Always include TextEditor (we have a fallback version if the real one isn't available)
#include "TextEditor.h"  // ImGuiColorTextEdit
#include "Language/ClangdService.h"

class SCppEditor : public SCompoundWidget
{
public:
    SLATE_BEGIN_ARGS(SCppEditor) {}
        SLATE_ARGUMENT(TSharedPtr<class FCppEditorBridge>, EditorBridge)
    SLATE_END_ARGS()

    void Construct(const FArguments& InArgs);

private:
    // Editor core
    void InitializeEditor();
    void UpdateEditor();
    void RenderEditor();
    
    // File operations
    void LoadFile(const FString& Path);
    void SaveFile(const FString& Path);
    bool SaveCurrentFile();
    
    // Language services
    void InitializeClangd();
    void UpdateDiagnostics();
    void HandleCompletion();
    
    // ImGui integration
    void SetupImGuiStyle();
    void RenderMenuBar();
    void RenderStatusBar();
    
private:
    // Editor state
    TextEditor Editor;
    FString CurrentFilePath;
    bool bNeedsSave;
    
    // Bridge to editor functionality
    TSharedPtr<FCppEditorBridge> EditorBridge;
    
    // Language service
    TSharedPtr<FClangdService> LanguageService;
    
    // Auto-save
    double LastAutoSaveTime;
    static constexpr double AutoSaveInterval = 300.0; // 5 minutes
};
