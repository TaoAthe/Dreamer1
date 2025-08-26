/*
 * File: /Source/InEditorCpp/Private/SCppEditor.cpp
 * 
 * Purpose: Main Editor Widget Implementation
 * Implements the core functionality of the C++ editor widget, including:
 * - ImGui integration with ImGuiColorTextEdit
 * - File operations (open, save, save as)
 * - Editor UI construction and management
 * - Language service integration
 */

#include "InEditorCppPrivatePCH.h"
#include "SCppEditor.h"
#include "CppEditorBridge.h"
#include "SImGuiCanvas.h"
#include "Framework/Application/SlateApplication.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "DesktopPlatformModule.h"
#include "IDesktopPlatform.h"

#if WITH_IMGUI
#include "ImGuiModule.h"
#include "ImGuiDelegates.h"
#endif

#define LOCTEXT_NAMESPACE "SCppEditor"

void SCppEditor::Construct(const FArguments& InArgs)
{
    EditorBridge = InArgs._EditorBridge;
    LanguageService = EditorBridge->GetClangdService();
    bNeedsSave = false;
    LastAutoSaveTime = FPlatformTime::Seconds();
    
    // Initialize the text editor
    InitializeEditor();
    
#if WITH_IMGUI
    // Register ImGui delegates if the module is available
    if (FImGuiModule::IsAvailable())
    {
        // Add a delegate to render the editor
        FImGuiModule::Get().GetProperties();
        
        // In a real implementation, we would register a delegate to render the editor
        // This is a placeholder and would need to be implemented based on the actual ImGui module structure
    }
#endif
    
    // Set up the child slot to host the ImGui viewport
    ChildSlot
    [
        SNew(SImGuiCanvas)
        .ContextIndex(0)
    ];
}

void SCppEditor::InitializeEditor()
{
    // Set up editor with language configuration
    Editor.SetLanguageDefinition(TextEditor::LanguageDefinition::CPlusPlus());
    
    // Configure editor appearance
    auto Palette = TextEditor::GetDarkPalette();
    Editor.SetPalette(Palette);
    Editor.SetShowWhitespaces(false);
    Editor.SetTabSize(4);
    
    // Set up C++ language syntax highlighting
    auto& Lang = Editor.GetLanguageDefinition();
    
    // Add UE-specific keywords to syntax highlighting
    static const char* UEKeywords[] = {
        "UCLASS", "USTRUCT", "UFUNCTION", "UPROPERTY", "GENERATED_BODY",
        "TArray", "TMap", "TSet", "FString", "FName", "FText",
        "check", "ensure", "UE_LOG", "TEXT"
    };
    
    for (auto& k : UEKeywords)
        Lang.mKeywords.insert(k);
}

void SCppEditor::RenderEditor()
{
#if WITH_IMGUI
    // This function would be called from the ImGui delegate
    // Set up the ImGui main window for the editor
    // For now, this is a placeholder
#endif
}

void SCppEditor::RenderMenuBar()
{
#if WITH_IMGUI
    // This would render the menu bar using ImGui
    // For now, this is a placeholder
#endif
}

void SCppEditor::RenderStatusBar()
{
#if WITH_IMGUI
    // This would render the status bar using ImGui
    // For now, this is a placeholder
#endif
}

void SCppEditor::LoadFile(const FString& Path)
{
    FString Content;
    if (EditorBridge->GetFileContent(Path, Content))
    {
        Editor.SetText(TCHAR_TO_UTF8(*Content));
        CurrentFilePath = Path;
        bNeedsSave = false;
        EditorBridge->AddRecentFile(Path);
        
        // Register with language service
        if (LanguageService.IsValid())
        {
            LanguageService->UpdateFile(Path, Content);
        }
    }
}

bool SCppEditor::SaveCurrentFile()
{
    if (CurrentFilePath.IsEmpty())
    {
        return false;
    }
    
    const std::string& Text = Editor.GetText();
    FString Content = UTF8_TO_TCHAR(Text.c_str());
    
    if (EditorBridge->SaveFile(CurrentFilePath, Content))
    {
        bNeedsSave = false;
        
        // Update language service
        if (LanguageService.IsValid())
        {
            LanguageService->UpdateFile(CurrentFilePath, Content);
        }
        
        return true;
    }
    
    return false;
}

#undef LOCTEXT_NAMESPACE
