// Copyright Epic Games, Inc. All Rights Reserved.

#include "DreamerCommands.h"

#define LOCTEXT_NAMESPACE "FDreamerModule"

void FDreamerCommands::RegisterCommands()
{
	UI_COMMAND(OpenCppEditor, "C++ Editor", "Open the integrated C++ Editor", EUserInterfaceActionType::Button, FInputChord(EModifierKey::Control | EModifierKey::Shift, EKeys::E));
	UI_COMMAND(BuildProject, "Build", "Build the current project", EUserInterfaceActionType::Button, FInputChord(EModifierKey::Control | EModifierKey::Shift, EKeys::B));
	UI_COMMAND(CancelBuild, "Cancel Build", "Cancel the current build", EUserInterfaceActionType::Button, FInputChord());
	UI_COMMAND(ShowBuildErrors, "Build Errors", "Show build errors and warnings", EUserInterfaceActionType::Button, FInputChord(EModifierKey::Control | EModifierKey::Shift, EKeys::L));
}

#undef LOCTEXT_NAMESPACE