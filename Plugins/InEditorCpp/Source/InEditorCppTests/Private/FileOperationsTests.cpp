/*
 * File: /Source/InEditorCppTests/Private/FileOperationsTests.cpp
 * 
 * Purpose: Test Suite for File Operations
 * Tests file handling functionality including:
 * - File loading
 * - File saving
 * - Auto-save
 * - File watching
 */

#include "Misc/AutomationTest.h"
#include "SCppEditor.h"
#include "Misc/Paths.h"
#include "HAL/FileManager.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FFileOperationsTest, "InEditorCpp.Editor.FileOps",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter)

bool FFileOperationsTest::RunTest(const FString& Parameters)
{
    TSharedRef<SCppEditor> Editor = SNew(SCppEditor);
    
    // Create test file
    const FString TestPath = FPaths::Combine(FPaths::AutomationTransientDir(), TEXT("TestFile.cpp"));
    const FString TestContent = "// Test Content\nvoid TestFunc() {}\n";
    FFileHelper::SaveStringToFile(TestContent, *TestPath);
    
    // Test file loading
    TestTrue("File loads successfully", Editor->LoadFile(TestPath));
    TestEqual("Loaded content matches", Editor->GetText(), TestContent);
    
    // Test file saving
    const FString NewContent = "// Modified Content\n";
    Editor->SetText(NewContent);
    TestTrue("File saves successfully", Editor->SaveFile(TestPath));
    
    // Verify saved content
    FString LoadedContent;
    FFileHelper::LoadFileToString(LoadedContent, *TestPath);
    TestEqual("Saved content matches", LoadedContent, NewContent);
    
    // Cleanup
    IFileManager::Get().Delete(*TestPath);
    
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FAutoSaveTest, "InEditorCpp.Editor.AutoSave",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter)

bool FAutoSaveTest::RunTest(const FString& Parameters)
{
    TSharedRef<SCppEditor> Editor = SNew(SCppEditor);
    
    // Set up test file
    const FString TestPath = FPaths::Combine(FPaths::AutomationTransientDir(), TEXT("AutoSaveTest.cpp"));
    Editor->LoadFile(TestPath);
    
    // Modify content and trigger auto-save
    Editor->SetText("// Auto-save test");
    Editor->SimulateTimePassage(301.0); // Just over 5 minutes
    
    // Verify auto-save
    FString SavedContent;
    FFileHelper::LoadFileToString(SavedContent, *TestPath);
    TestEqual("Auto-saved content matches", SavedContent, "// Auto-save test");
    
    // Cleanup
    IFileManager::Get().Delete(*TestPath);
    
    return true;
}
