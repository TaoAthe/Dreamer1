/*
 * File: /Source/InEditorCpp/Public/Language/ClangdService.h
 * 
 * Purpose: Language Service Interface
 * Provides the interface for clangd language server integration,
 * handling code intelligence features like completion and diagnostics.
 */

#pragma once

#include "CoreMinimal.h"

class INEDITORCPP_API FClangdService
{
public:
    // Service lifecycle
    static FClangdService& Get();
    void Initialize();
    void Shutdown();
    
    // Language features
    void UpdateFile(const FString& Path, const FString& Content);
    void RequestCompletion(const FString& Path, int Line, int Column);
    void RequestDiagnostics(const FString& Path);
    
    // Configuration
    void GenerateCompilationDatabase();
    void UpdateCompilationSettings();
    
private:
    // Server management
    void StartLanguageServer();
    void StopLanguageServer();
    void HandleServerResponse();
    
    // State
    bool bIsInitialized;
    FString ServerPath;
    FString WorkspacePath;
    
private:
    FClangdService();
    ~FClangdService();
};
