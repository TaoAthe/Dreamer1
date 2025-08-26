#pragma once

#include "CoreMinimal.h"
#include "Misc/AutomationTest.h"

class FEditorTestBase : public FAutomationTestBase
{
public:
    FEditorTestBase(const FString& InName, const bool bInComplexTask)
        : FAutomationTestBase(InName, bInComplexTask)
    {}

protected:
    // Common test utilities
    bool InitializeTestEnvironment();
    void CleanupTestEnvironment();
    
    // ImGui test helpers
    bool CreateTestWindow();
    void DestroyTestWindow();
    
    // Editor test helpers
    bool LoadTestFile(const FString& Content);
    FString GetEditorContent();
    
    // Language service test helpers
    bool WaitForLanguageService();
    bool CheckCompletion(const FString& Trigger, const TArray<FString>& ExpectedResults);
};
