// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Styling/SlateStyle.h"

/**  */
class FDreamerStyle
{
public:
	static void Initialize();
	static void Shutdown();

	/** @return The Slate style set for the plugin */
	static TSharedRef<FSlateStyleSet> CreateStyleSet();

	/** @return The Slate style set for the plugin */
	static TSharedPtr<FSlateStyleSet> GetStyleSet();

	/** @return The name of the style set */
	static FName GetStyleSetName();

	/** Reloads textures used by slate renderer */
	static void ReloadTextures();

private:
	static TSharedPtr<FSlateStyleSet> StyleInstance;
};