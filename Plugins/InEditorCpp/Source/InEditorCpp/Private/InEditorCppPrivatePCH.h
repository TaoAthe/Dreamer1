/*
 * File: /Source/InEditorCpp/Private/InEditorCppPrivatePCH.h
 * 
 * Purpose: Private Precompiled Header
 * Contains common includes and definitions used throughout the private
 * implementation files of the plugin.
 */

#pragma once

// Core Unreal headers
#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"
#include "Widgets/Docking/SDockTab.h"
#include "Framework/MultiBox/MultiBoxBuilder.h"
#include "Framework/Application/SlateApplication.h"
#include "ToolMenus.h"
#include "EditorStyleSet.h"
#include "LevelEditor.h"
#include "WorkspaceMenuStructure.h"
#include "WorkspaceMenuStructureModule.h"

// ImGui integration - conditionally included
#if WITH_IMGUI
#include "ImGuiModule.h"
#endif

#include "SImGuiCanvas.h"

// Project-specific headers
#include "InEditorCpp.h"
