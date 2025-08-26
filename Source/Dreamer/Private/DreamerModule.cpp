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
#include "BuildManager.h"
#include "BuildErrorList.h"
#include "ISourceCodeAccessModule.h"
#include "ISourceCodeAccessor.h"

static const FName DreamerTabName("Dreamer");
static const FName BuildErrorsTabName("DreamerBuildErrors");

#define LOCTEXT_NAMESPACE "FDreamerModule"

void FDreamerModule::StartupModule()
{
	// Initialize the style set
	FDreamerStyle::Initialize();
	FDreamerStyle::ReloadTextures();

	// Register commands
	FDreamerCommands::Register();
	
	PluginCommands = MakeShareable(new FUICommandList);

	// Create the build manager
	BuildManager = MakeShareable(new FBuildManager());
	BuildManager->Initialize();

	// Map commands
	PluginCommands->MapAction(
		FDreamerCommands::Get().OpenCppEditor,
		FExecuteAction::CreateRaw(this, &FDreamerModule::OpenCppEditorTab),
		FCanExecuteAction());

	PluginCommands->MapAction(
		FDreamerCommands::Get().BuildProject,
		FExecuteAction::CreateLambda([this]() {
			if (BuildManager.IsValid())
			{
				BuildManager->BuildProject();
			}
		}),
		FCanExecuteAction::CreateLambda([this]() {
			return BuildManager.IsValid() && !BuildManager->IsBuildInProgress();
		}));

	PluginCommands->MapAction(
		FDreamerCommands::Get().CancelBuild,
		FExecuteAction::CreateLambda([this]() {
			if (BuildManager.IsValid())
			{
				BuildManager->CancelBuild();
			}
		}),
		FCanExecuteAction::CreateLambda([this]() {
			return BuildManager.IsValid() && BuildManager->IsBuildInProgress();
		}));

	PluginCommands->MapAction(
		FDreamerCommands::Get().ShowBuildErrors,
		FExecuteAction::CreateLambda([this]() {
			FGlobalTabmanager::Get()->TryInvokeTab(BuildErrorsTabName);
		}),
		FCanExecuteAction());

	// Register menu extensions
	UToolMenus::RegisterStartupCallback(FSimpleMulticastDelegate::FDelegate::CreateRaw(this, &FDreamerModule::RegisterMenus));
	
	// Register tab spawners
	FGlobalTabmanager::Get()->RegisterNomadTabSpawner(DreamerTabName, FOnSpawnTab::CreateRaw(this, &FDreamerModule::OnSpawnPluginTab))
		.SetDisplayName(LOCTEXT("FDreamerTabTitle", "C++ Editor"))
		.SetMenuType(ETabSpawnerMenuType::Hidden);

	FGlobalTabmanager::Get()->RegisterNomadTabSpawner(BuildErrorsTabName, FOnSpawnTab::CreateRaw(this, &FDreamerModule::OnSpawnBuildErrorsTab))
		.SetDisplayName(LOCTEXT("FBuildErrorsTabTitle", "Build Errors"))
		.SetMenuType(ETabSpawnerMenuType::Hidden);

	// Register for build manager events
	if (BuildManager.IsValid())
	{
		BuildManager->OnBuildErrorsChanged().AddLambda([this]() {
			if (BuildErrorList.IsValid())
			{
				BuildErrorList->SetErrors(BuildManager->GetBuildErrors());
				BuildErrorList->SetWarnings(BuildManager->GetBuildWarnings());
			}
		});
	}
}

void FDreamerModule::ShutdownModule()
{
	// Unregister tab spawners
	FGlobalTabmanager::Get()->UnregisterNomadTabSpawner(BuildErrorsTabName);
	FGlobalTabmanager::Get()->UnregisterNomadTabSpawner(DreamerTabName);

	// Unregister menus
	UToolMenus::UnRegisterStartupCallback(this);
	UToolMenus::UnregisterOwner(this);
	
	// Unregister commands
	FDreamerCommands::Unregister();

	// Shutdown build manager
	if (BuildManager.IsValid())
	{
		BuildManager->Shutdown();
		BuildManager.Reset();
	}

	// Unregister style set
	FDreamerStyle::Shutdown();
}

TSharedRef<SDockTab> FDreamerModule::OnSpawnPluginTab(const FSpawnTabArgs& SpawnTabArgs)
{
	return SNew(SDockTab)
		.TabRole(ETabRole::NomadTab)
		[
			SNew(SVerticalBox)

			// Toolbar
			+ SVerticalBox::Slot()
			.AutoHeight()
			.Padding(2.0f)
			[
				SNew(SHorizontalBox)

				// Build button
				+ SHorizontalBox::Slot()
				.AutoWidth()
				.Padding(2.0f)
				.VAlign(VAlign_Center)
				[
					SNew(SButton)
					.ButtonStyle(FEditorStyle::Get(), "FlatButton.Success")
					.ContentPadding(FMargin(6.0f, 2.0f))
					.IsEnabled_Lambda([this]() { return BuildManager.IsValid() && !BuildManager->IsBuildInProgress(); })
					.OnClicked_Lambda([this]() {
						if (BuildManager.IsValid())
						{
							BuildManager->BuildProject();
						}
						return FReply::Handled();
					})
					.ToolTipText(LOCTEXT("BuildProjectTooltip", "Build the current project"))
					[
						SNew(SHorizontalBox)

						// Icon
						+ SHorizontalBox::Slot()
						.AutoWidth()
						.VAlign(VAlign_Center)
						.Padding(0.0f, 0.0f, 4.0f, 0.0f)
						[
							SNew(SImage)
							.Image(FDreamerStyle::Get().GetBrush("Dreamer.BuildProject.Small"))
						]

						// Text
						+ SHorizontalBox::Slot()
						.AutoWidth()
						.VAlign(VAlign_Center)
						[
							SNew(STextBlock)
							.Text(LOCTEXT("BuildButton", "Build"))
						]
					]
				]

				// Cancel build button
				+ SHorizontalBox::Slot()
				.AutoWidth()
				.Padding(2.0f)
				.VAlign(VAlign_Center)
				[
					SNew(SButton)
					.ButtonStyle(FEditorStyle::Get(), "FlatButton.Danger")
					.ContentPadding(FMargin(6.0f, 2.0f))
					.IsEnabled_Lambda([this]() { return BuildManager.IsValid() && BuildManager->IsBuildInProgress(); })
					.OnClicked_Lambda([this]() {
						if (BuildManager.IsValid())
						{
							BuildManager->CancelBuild();
						}
						return FReply::Handled();
					})
					.Visibility_Lambda([this]() { 
						return (BuildManager.IsValid() && BuildManager->IsBuildInProgress()) 
							? EVisibility::Visible 
							: EVisibility::Collapsed; 
					})
					.ToolTipText(LOCTEXT("CancelBuildTooltip", "Cancel the current build"))
					[
						SNew(SHorizontalBox)

						// Icon
						+ SHorizontalBox::Slot()
						.AutoWidth()
						.VAlign(VAlign_Center)
						.Padding(0.0f, 0.0f, 4.0f, 0.0f)
						[
							SNew(SImage)
							.Image(FDreamerStyle::Get().GetBrush("Dreamer.CancelBuild.Small"))
						]

						// Text
						+ SHorizontalBox::Slot()
						.AutoWidth()
						.VAlign(VAlign_Center)
						[
							SNew(STextBlock)
							.Text(LOCTEXT("CancelBuildButton", "Cancel"))
						]
					]
				]

				// Show errors button
				+ SHorizontalBox::Slot()
				.AutoWidth()
				.Padding(2.0f)
				.VAlign(VAlign_Center)
				[
					SNew(SButton)
					.ButtonStyle(FEditorStyle::Get(), "FlatButton")
					.ContentPadding(FMargin(6.0f, 2.0f))
					.OnClicked_Lambda([this]() {
						FGlobalTabmanager::Get()->TryInvokeTab(BuildErrorsTabName);
						return FReply::Handled();
					})
					.ToolTipText(LOCTEXT("ShowErrorsTooltip", "Show build errors and warnings"))
					[
						SNew(SHorizontalBox)

						// Icon
						+ SHorizontalBox::Slot()
						.AutoWidth()
						.VAlign(VAlign_Center)
						.Padding(0.0f, 0.0f, 4.0f, 0.0f)
						[
							SNew(SImage)
							.Image(FDreamerStyle::Get().GetBrush("Dreamer.ShowBuildErrors.Small"))
						]

						// Text
						+ SHorizontalBox::Slot()
						.AutoWidth()
						.VAlign(VAlign_Center)
						[
							SNew(STextBlock)
							.Text(LOCTEXT("ErrorsButton", "Errors"))
						]
					]
				]

				// Build progress
				+ SHorizontalBox::Slot()
				.FillWidth(1.0f)
				.Padding(8.0f, 0.0f)
				.VAlign(VAlign_Center)
				[
					SNew(SProgressBar)
					.Percent_Lambda([this]() { 
						return BuildManager.IsValid() ? BuildManager->GetBuildProgress() : 0.0f; 
					})
					.Visibility_Lambda([this]() { 
						return (BuildManager.IsValid() && BuildManager->IsBuildInProgress()) 
							? EVisibility::Visible 
							: EVisibility::Collapsed; 
					})
				]
			]

			// Code editor
			+ SVerticalBox::Slot()
			.FillHeight(1.0f)
			[
				SNew(SDreamerCodeEditor)
			]
		];
}

TSharedRef<SDockTab> FDreamerModule::OnSpawnBuildErrorsTab(const FSpawnTabArgs& SpawnTabArgs)
{
	// Create the error list widget if it doesn't exist
	if (!BuildErrorList.IsValid())
	{
		BuildErrorList = SNew(SBuildErrorList);

		// Populate with current errors
		if (BuildManager.IsValid())
		{
			BuildErrorList->SetErrors(BuildManager->GetBuildErrors());
			BuildErrorList->SetWarnings(BuildManager->GetBuildWarnings());
		}
	}

	return SNew(SDockTab)
		.TabRole(ETabRole::NomadTab)
		[
			BuildErrorList.ToSharedRef()
		];
}

void FDreamerModule::OpenCppEditorTab()
{
	FGlobalTabmanager::Get()->TryInvokeTab(DreamerTabName);
}

void FDreamerModule::OpenFileAtLocation(const FString& FilePath, int32 LineNumber)
{
	// Use the source code access module to open the file
	ISourceCodeAccessModule& SourceCodeAccessModule = FModuleManager::LoadModuleChecked<ISourceCodeAccessModule>("SourceCodeAccess");
	if (SourceCodeAccessModule.GetAccessor().IsAvailable())
	{
		SourceCodeAccessModule.GetAccessor()->OpenFileAtLine(FilePath, LineNumber);
	}
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
		Section.AddMenuEntryWithCommandList(FDreamerCommands::Get().ShowBuildErrors, PluginCommands);
	}

	// Add menu entries to editor toolbar
	{
		UToolMenu* ToolbarMenu = UToolMenus::Get()->ExtendMenu("LevelEditor.LevelEditorToolBar");
		FToolMenuSection& Section = ToolbarMenu->FindOrAddSection("Settings");
		
		FToolMenuEntry& CppEditorEntry = Section.AddEntry(FToolMenuEntry::InitToolBarButton(FDreamerCommands::Get().OpenCppEditor));
		CppEditorEntry.SetCommandList(PluginCommands);
		
		FToolMenuEntry& BuildEntry = Section.AddEntry(FToolMenuEntry::InitToolBarButton(FDreamerCommands::Get().BuildProject));
		BuildEntry.SetCommandList(PluginCommands);
		
		FToolMenuEntry& CancelBuildEntry = Section.AddEntry(FToolMenuEntry::InitToolBarButton(FDreamerCommands::Get().CancelBuild));
		CancelBuildEntry.SetCommandList(PluginCommands);
		
		FToolMenuEntry& ErrorsEntry = Section.AddEntry(FToolMenuEntry::InitToolBarButton(FDreamerCommands::Get().ShowBuildErrors));
		ErrorsEntry.SetCommandList(PluginCommands);
	}
}

#undef LOCTEXT_NAMESPACE
	
IMPLEMENT_MODULE(FDreamerModule, Dreamer)