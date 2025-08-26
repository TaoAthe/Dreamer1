/*
 * File: /Source/InEditorCppTests/Private/EditorComponentTests.cpp
 * 
 * Purpose: Test Suite for ImGui Editor Integration
 * Tests the editor component functionality including:
 * - Editor initialization
 * - Text manipulation
 * - Syntax highlighting
 * - Input handling
 */

#include "Misc/AutomationTest.h"
#include "SCppEditor.h"
#include "imgui.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FEditorInitTest, "InEditorCpp.Editor.Component.Init",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter)

bool FEditorInitTest::RunTest(const FString& Parameters)
{
    // Test editor creation
    TSharedRef<SCppEditor> Editor = SNew(SCppEditor);
    TestTrue("Editor widget creates successfully", Editor.IsValid());
    
    // Test ImGui context
    TestTrue("ImGui context is valid", ImGui::GetCurrentContext() != nullptr);
    
    // Test editor state
    TestTrue("Editor starts with empty buffer", Editor->GetText().IsEmpty());
    
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FEditorOperationsTest, "InEditorCpp.Editor.Component.Operations",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter)

bool FEditorOperationsTest::RunTest(const FString& Parameters)
{
    TSharedRef<SCppEditor> Editor = SNew(SCppEditor);
    
    // Test text insertion
    const FString TestText = "void TestFunction() {\n    // Test\n}";
    Editor->SetText(TestText);
    TestEqual("Editor content matches inserted text", Editor->GetText(), TestText);
    
    // Test syntax highlighting
    auto Colors = Editor->GetLineColors(1);
    TestTrue("Function declaration is properly colored", 
        Colors.Contains(ImGuiColorTextEdit::PaletteIndex::Function));
    
    return true;
}
