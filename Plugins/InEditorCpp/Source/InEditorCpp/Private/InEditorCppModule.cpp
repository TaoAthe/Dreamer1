/*
 * File: /Source/InEditorCpp/Private/InEditorCppModule.cpp
 * 
 * Purpose: Plugin Module Implementation
 * Implements the IInEditorCppModule interface for the InEditorCpp plugin.
 * Handles module startup, shutdown, and core plugin functionality.
 */

#include "InEditorCppPrivatePCH.h"
#include "InEditorCpp.h"
#include "SCppEditor.h"
#include "CppEditorBridge.h"
#include "Language/ClangdService.h"

#include "Modules/ModuleManager.h"
#include "Widgets/Docking/SDockTab.h"
#include "LevelEditor.h"
#include "Framework/MultiBox/MultiBoxBuilder.h"
#include "ToolMenus.h"

#define LOCTEXT_NAMESPACE "InEditorCppModule"

class FInEditorCppModule : public IInEditorCppModule
{
public:
    // IModuleInterface implementation
    virtual void StartupModule() override;
    virtual void ShutdownModule() override;

    // IInEditorCppModule implementation
    virtual TSharedRef<SDockTab> SpawnCppEditorTab(const FSpawnTabArgs& Args) override;
    virtual void RegisterMenus() override;

private:
    TSharedPtr<FCppEditorBridge> CppEditorBridge;
    TSharedPtr<FClangdService> ClangdService;
    TSharedPtr<FExtender> ToolbarExtender;
    
    // Handlers
    void HandleEditorTabClosed(TSharedRef<SDockTab> Tab);
};

void FInEditorCppModule::StartupModule()
{
    // Initialize Services
    ClangdService = MakeShared<FClangdService>();
    CppEditorBridge = MakeShared<FCppEditorBridge>(ClangdService);
    
    // Register tab spawners
    FGlobalTabmanager::Get()->RegisterNomadTabSpawner(
        "CppEditor", 
        FOnSpawnTab::CreateRaw(this, &FInEditorCppModule::SpawnCppEditorTab))
        .SetDisplayName(LOCTEXT("CppEditorTabTitle", "C++ Editor"))
        .SetMenuType(ETabSpawnerMenuType::Hidden);
    
    // Register menus and toolbar buttons
    RegisterMenus();
}

void FInEditorCppModule::ShutdownModule()
{
    // Unregister tab spawners
    FGlobalTabmanager::Get()->UnregisterNomadTabSpawner("CppEditor");
    
    // Unregister toolbar extensions
    if (ToolbarExtender.IsValid() && FModuleManager::Get().IsModuleLoaded("LevelEditor"))
    {
        FLevelEditorModule& LevelEditorModule = FModuleManager::GetModuleChecked<FLevelEditorModule>("LevelEditor");
        LevelEditorModule.GetToolBarExtensibilityManager()->RemoveExtender(ToolbarExtender);
    }
    
    // Release services
    ClangdService.Reset();
    CppEditorBridge.Reset();
}

TSharedRef<SDockTab> FInEditorCppModule::SpawnCppEditorTab(const FSpawnTabArgs& Args)
{
    TSharedRef<SDockTab> Tab = SNew(SDockTab)
        .TabRole(ETabRole::NomadTab)
        .OnTabClosed(SDockTab::FOnTabClosedCallback::CreateRaw(this, &FInEditorCppModule::HandleEditorTabClosed));
    
    Tab->SetContent(
        SNew(SCppEditor)
        .EditorBridge(CppEditorBridge)
    );
    
    return Tab;
}

void FInEditorCppModule::RegisterMenus()
{
    if (!IsRunningCommandlet())
    {
        ToolbarExtender = MakeShareable(new FExtender);
        
        ToolbarExtender->AddToolBarExtension(
            "Settings",
            EExtensionHook::After,
            nullptr,
            FToolBarExtensionDelegate::CreateLambda([this](FToolBarBuilder& Builder)
            {
                Builder.AddToolBarButton(
                    FUIAction(
                        FExecuteAction::CreateLambda([this]()
                        {
                            FGlobalTabmanager::Get()->TryInvokeTab(FTabId("CppEditor"));
                        })
                    ),
                    NAME_None,
                    LOCTEXT("CppEditorButton", "C++ Editor"),
                    LOCTEXT("CppEditorTooltip", "Open the Native C++ Editor"),
                    FSlateIcon(FAppStyle::GetAppStyleSetName(), "ClassIcon.BlueprintCore")
                );
            })
        );
        
        // Register the toolbar extension
        FLevelEditorModule& LevelEditorModule = FModuleManager::LoadModuleChecked<FLevelEditorModule>("LevelEditor");
        LevelEditorModule.GetToolBarExtensibilityManager()->AddExtender(ToolbarExtender);
    }
}

void FInEditorCppModule::HandleEditorTabClosed(TSharedRef<SDockTab> Tab)
{
    // Handle any cleanup when the editor tab is closed
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(FInEditorCppModule, InEditorCpp)
