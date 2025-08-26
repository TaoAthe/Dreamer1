// Copyright Epic Games, Inc. All Rights Reserved.

#include "DreamerStyle.h"
#include "Styling/SlateStyleRegistry.h"
#include "Framework/Application/SlateApplication.h"
#include "Slate/SlateGameResources.h"
#include "Interfaces/IPluginManager.h"

TSharedPtr<FSlateStyleSet> FDreamerStyle::StyleInstance = NULL;

void FDreamerStyle::Initialize()
{
	if (!StyleInstance.IsValid())
	{
		StyleInstance = CreateStyleSet();
		FSlateStyleRegistry::RegisterSlateStyle(*StyleInstance);
	}
}

void FDreamerStyle::Shutdown()
{
	FSlateStyleRegistry::UnRegisterSlateStyle(*StyleInstance);
	ensure(StyleInstance.IsUnique());
	StyleInstance.Reset();
}

FName FDreamerStyle::GetStyleSetName()
{
	static FName StyleSetName(TEXT("DreamerStyle"));
	return StyleSetName;
}

#define IMAGE_BRUSH( RelativePath, ... ) FSlateImageBrush( Style->RootToContentDir( RelativePath, TEXT(".png") ), __VA_ARGS__ )
#define BOX_BRUSH( RelativePath, ... ) FSlateBoxBrush( Style->RootToContentDir( RelativePath, TEXT(".png") ), __VA_ARGS__ )
#define BORDER_BRUSH( RelativePath, ... ) FSlateBorderBrush( Style->RootToContentDir( RelativePath, TEXT(".png") ), __VA_ARGS__ )
#define TTF_FONT( RelativePath, ... ) FSlateFontInfo( Style->RootToContentDir( RelativePath, TEXT(".ttf") ), __VA_ARGS__ )
#define OTF_FONT( RelativePath, ... ) FSlateFontInfo( Style->RootToContentDir( RelativePath, TEXT(".otf") ), __VA_ARGS__ )

TSharedRef<FSlateStyleSet> FDreamerStyle::CreateStyleSet()
{
	TSharedRef<FSlateStyleSet> Style = MakeShareable(new FSlateStyleSet(GetStyleSetName()));
	Style->SetContentRoot(IPluginManager::Get().FindPlugin("Dreamer")->GetBaseDir() / TEXT("Resources"));

	// Icon for the plugin button
	Style->Set("Dreamer.OpenCppEditor", new IMAGE_BRUSH(TEXT("ButtonIcon_40x"), FVector2D(40.0f, 40.0f)));
	Style->Set("Dreamer.OpenCppEditor.Small", new IMAGE_BRUSH(TEXT("ButtonIcon_40x"), FVector2D(20.0f, 20.0f)));

	return Style;
}

#undef IMAGE_BRUSH
#undef BOX_BRUSH
#undef BORDER_BRUSH
#undef TTF_FONT
#undef OTF_FONT

void FDreamerStyle::ReloadTextures()
{
	if (FSlateApplication::IsInitialized())
	{
		FSlateApplication::Get().GetRenderer()->ReloadTextureResources();
	}
}

const ISlateStyle& FDreamerStyle::Get()
{
	return *StyleInstance;
}

TSharedPtr<FSlateStyleSet> FDreamerStyle::GetStyleSet()
{
	return StyleInstance;
}