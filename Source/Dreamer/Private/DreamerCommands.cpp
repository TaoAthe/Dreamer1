// Copyright Epic Games, Inc. All Rights Reserved.

#include "DreamerCommands.h"

#define LOCTEXT_NAMESPACE "FDreamerModule"

void FDreamerCommands::RegisterCommands()
{
	UI_COMMAND(OpenCppEditor, "C++ Editor", "Open the integrated C++ Editor", EUserInterfaceActionType::Button, FInputChord(EModifierKey::Control | EModifierKey::Shift, EKeys::E));
}

#undef LOCTEXT_NAMESPACE