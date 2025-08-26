#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

class FInEditorCppTestsModule : public IModuleInterface
{
public:
    virtual void StartupModule() override;
    virtual void ShutdownModule() override;

    static FInEditorCppTestsModule& Get()
    {
        return FModuleManager::LoadModuleChecked<FInEditorCppTestsModule>("InEditorCppTests");
    }
};
