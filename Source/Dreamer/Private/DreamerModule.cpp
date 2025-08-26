// Copyright Epic Games, Inc. All Rights Reserved.

#include "DreamerModule.h"
#include "DreamerStyle.h"
#include "DreamerCommands.h"
#include "LevelEditor.h"
#include "Widgets/Docking/SDockTab.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/Text/STextBlock.h"
#include "ToolMenus.h"
#include "DreamerCodeEditor.h"

static const FName DreamerTabName("Dreamer");

#define LOCTEXT_NAMESPACE "FDreamerModule"

void FDreamerModule::StartupModule()
{
	// Initialize the style set
	FDreamerStyle::Initialize();
	FDreamerStyle::ReloadTextures();

	// Register commands
	FDreamerCommands::Register();
	
	PluginCommands = MakeShareable(new FUICommandList);

	// Map commands
	PluginCommands->MapAction(
		FDreamerCommands::Get().OpenCppEditor,
		FExecuteAction::CreateRaw(this, &FDreamerModule::OpenCppEditorTab),
		FCanExecuteAction());

	// Register menu extensions
	UToolMenus::RegisterStartupCallback(FSimpleMulticastDelegate::FDelegate::CreateRaw(this, &FDreamerModule::RegisterMenus));
	
	// Register tab spawner
	FGlobalTabmanager::Get()->RegisterNomadTabSpawner(DreamerTabName, FOnSpawnTab::CreateRaw(this, &FDreamerModule::OnSpawnPluginTab))
		.SetDisplayName(LOCTEXT("FDreamerTabTitle", "C++ Editor"))
		.SetMenuType(ETabSpawnerMenuType::Hidden);
}

void FDreamerModule::ShutdownModule()
{
	// Unregister tab spawner
	FGlobalTabmanager::Get()->UnregisterNomadTabSpawner(DreamerTabName);

	// Unregister menus
	UToolMenus::UnRegisterStartupCallback(this);
	UToolMenus::UnregisterOwner(this);
	
	// Unregister commands
	FDreamerCommands::Unregister();

	// Unregister style set
	FDreamerStyle::Shutdown();
}

TSharedRef<SDockTab> FDreamerModule::OnSpawnPluginTab(const FSpawnTabArgs& SpawnTabArgs)
{
	return SNew(SDockTab)
		.TabRole(ETabRole::NomadTab)
		[
			SNew(SDreamerCodeEditor)
		];
}

void FDreamerModule::OpenCppEditorTab()
{
	FGlobalTabmanager::Get()->TryInvokeTab(DreamerTabName);
}

void FDreamerModule::RegisterMenus()
{
	// Owner will be used for cleanup in call to UToolMenus::UnregisterOwner
	FToolMenuOwnerScoped OwnerScoped(this);

	// Add menu entry to main Unreal Editor menu
	{
		UToolMenu* Menu = UToolMenus::Get()->ExtendMenu("LevelEditor.MainMenu.Window");
		FToolMenuSection& Section = Menu->FindOrAddSection("WindowLayout");
		Section.AddMenuEntryWithCommandList(FDreamerCommands::Get().OpenCppEditor, PluginCommands);
	}

	// Add menu entry to editor toolbar
	{
		UToolMenu* ToolbarMenu = UToolMenus::Get()->ExtendMenu("LevelEditor.LevelEditorToolBar");
		FToolMenuSection& Section = ToolbarMenu->FindOrAddSection("Settings");
		FToolMenuEntry& Entry = Section.AddEntry(FToolMenuEntry::InitToolBarButton(FDreamerCommands::Get().OpenCppEditor));
		Entry.SetCommandList(PluginCommands);
	}
}

#undef LOCTEXT_NAMESPACE
	
IMPLEMENT_MODULE(FDreamerModule, Dreamer)