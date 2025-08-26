/*
 * File: /Source/InEditorCpp/Public/CppEditorBridge.h
 * 
 * Purpose: C++ Editor Bridge
 * Provides a bridge between the Unreal Editor and the native C++ editor.
 * Handles file operations, compiler integration, and editor state.
 */

#pragma once

#include "CoreMinimal.h"
#include "Language/ClangdService.h"

/**
 * Bridge between the C++ editor UI and the language services
 */
class INEDITORCPP_API FCppEditorBridge
{
public:
    FCppEditorBridge(TSharedPtr<FClangdService> InClangdService);
    ~FCppEditorBridge();

    // File operations
    bool OpenFile(const FString& FilePath);
    bool SaveFile(const FString& FilePath, const FString& Content);
    bool GetFileContent(const FString& FilePath, FString& OutContent);
    
    // Project operations
    TArray<FString> GetProjectSourceFiles();
    TArray<FString> GetRecentFiles();
    void AddRecentFile(const FString& FilePath);
    
    // Language service integration
    TSharedPtr<FClangdService> GetClangdService() const { return ClangdService; }

private:
    TSharedPtr<FClangdService> ClangdService;
    TArray<FString> RecentFiles;
    
    // Helpers
    void LoadRecentFiles();
    void SaveRecentFiles();
};
