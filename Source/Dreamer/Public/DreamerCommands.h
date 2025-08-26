// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Framework/Commands/Commands.h"
#include "DreamerStyle.h"

class FDreamerCommands : public TCommands<FDreamerCommands>
{
public:
	FDreamerCommands()
		: TCommands<FDreamerCommands>(TEXT("Dreamer"), NSLOCTEXT("Contexts", "Dreamer", "Dreamer Plugin"), NAME_None, FDreamerStyle::GetStyleSetName())
	{
	}

	// TCommands<> interface
	virtual void RegisterCommands() override;

public:
	TSharedPtr<FUICommandInfo> OpenCppEditor;
};