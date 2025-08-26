/*
 * File: /Source/InEditorCppTests/Private/ClangdServiceTests.cpp
 * 
 * Purpose: Test Suite for Clangd Integration
 * Tests the language service functionality including:
 * - Server initialization
 * - Code completion
 * - Diagnostics
 * - Symbol lookup
 */

#include "Misc/AutomationTest.h"
#include "Language/ClangdService.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FClangdServiceInitTest, "InEditorCpp.Language.ClangdService.Init",
    EAutomationTestFlags::ApplicationContextMask | EAutomationTestFlags::ProductFilter)

bool FClangdServiceInitTest::RunTest(const FString& Parameters)
{
    // Test clangd service initialization
    auto& Service = FClangdService::Get();
    TestTrue("Service initializes successfully", Service.Initialize());
    
    // Test compilation database generation
    FString CompilationDbPath = Service.GenerateCompilationDatabase();
    TestTrue("Compilation database exists", FPaths::FileExists(CompilationDbPath));
    
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FClangdCompletionTest, "InEditorCpp.Language.ClangdService.Completion",
    EAutomationTestFlags::ApplicationContextMask | EAutomationTestFlags::ProductFilter)

bool FClangdCompletionTest::RunTest(const FString& Parameters)
{
    auto& Service = FClangdService::Get();
    
    // Test code completion
    const FString TestCode = "FString TestVar;\nTestVar.";
    Service.UpdateFile("TestFile.cpp", TestCode);
    
    // Request completion at specific position
    auto Completions = Service.RequestCompletion("TestFile.cpp", 2, 8);
    TestTrue("Completion results contain expected FString methods", 
        Completions.Contains("Len") && Completions.Contains("IsEmpty"));
    
    return true;
}
