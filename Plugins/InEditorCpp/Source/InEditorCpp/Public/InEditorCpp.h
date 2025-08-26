/*
 * File: /Source/InEditorCpp/Public/InEditorCpp.h
 * 
 * Purpose: Plugin Module Interface
 * Main plugin module header that defines the interface for the InEditorCpp plugin.
 * Handles module startup, shutdown, and core plugin functionality.
 */

#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleInterface.h"
#include "Widgets/Docking/SDockTab.h"

class INEDITORCPP_API IInEditorCppModule : public IModuleInterface
{
public:
    /**
     * Spawns the C++ editor tab
     */
    virtual TSharedRef<SDockTab> SpawnCppEditorTab(const FSpawnTabArgs& Args) = 0;
    
    /**
     * Registers menus and UI elements
     */
    virtual void RegisterMenus() = 0;
    
    /**
     * Gets the module instance
     */
    static inline IInEditorCppModule& Get()
    {
        return FModuleManager::LoadModuleChecked<IInEditorCppModule>("InEditorCpp");
    }

    /**
     * Checks if the module is loaded
     */
    static inline bool IsAvailable()
    {
        return FModuleManager::Get().IsModuleLoaded("InEditorCpp");
    }
};
