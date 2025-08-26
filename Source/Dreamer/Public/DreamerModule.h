// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

class FToolBarBuilder;
class FMenuBuilder;

class FDreamerModule : public IModuleInterface
{
public:
	/** IModuleInterface implementation */
	virtual void StartupModule() override;
	virtual void ShutdownModule() override;
	
	/** Callback for spawning the C++ editor tab */
	TSharedRef<class SDockTab> OnSpawnPluginTab(const class FSpawnTabArgs& SpawnTabArgs);
	
	/** Opens the C++ editor tab */
	void OpenCppEditorTab();

private:
	/** Registers menu extensions */
	void RegisterMenus();

private:
	TSharedPtr<class FUICommandList> PluginCommands;
};