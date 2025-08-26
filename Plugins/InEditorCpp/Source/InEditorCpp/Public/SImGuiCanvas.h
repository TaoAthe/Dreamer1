#pragma once

#include "CoreMinimal.h"
#include "Widgets/SCompoundWidget.h"

// Check if ImGui is available
#if WITH_IMGUI
#include "ImGuiModule.h"
#endif

#include "Framework/Application/SlateApplication.h"
#include "Input/Events.h"
#include "Input/Reply.h"

/**
 * A Slate widget that hosts an ImGui canvas/viewport
 */
class INEDITORCPP_API SImGuiCanvas : public SCompoundWidget
{
public:
    SLATE_BEGIN_ARGS(SImGuiCanvas)
        : _ContextIndex(0)
    {}
        /** The ImGui context index to use */
        SLATE_ARGUMENT(int32, ContextIndex)
    SLATE_END_ARGS()

    void Construct(const FArguments& InArgs);

private:
    // SWidget interface
    virtual int32 OnPaint(const FPaintArgs& Args, const FGeometry& AllottedGeometry, const FSlateRect& MyCullingRect, FSlateWindowElementList& OutDrawElements, int32 LayerId, const FWidgetStyle& InWidgetStyle, bool bParentEnabled) const override;
    virtual FReply OnMouseButtonDown(const FGeometry& MyGeometry, const FPointerEvent& MouseEvent) override;
    virtual FReply OnMouseButtonUp(const FGeometry& MyGeometry, const FPointerEvent& MouseEvent) override;
    virtual FReply OnMouseMove(const FGeometry& MyGeometry, const FPointerEvent& MouseEvent) override;
    virtual FReply OnMouseWheel(const FGeometry& MyGeometry, const FPointerEvent& MouseEvent) override;
    virtual FReply OnKeyDown(const FGeometry& MyGeometry, const FKeyEvent& InKeyEvent) override;
    virtual FReply OnKeyUp(const FGeometry& MyGeometry, const FKeyEvent& InKeyEvent) override;
    virtual FReply OnKeyChar(const FGeometry& MyGeometry, const FCharacterEvent& InCharacterEvent) override;
    virtual FCursorReply OnCursorQuery(const FGeometry& MyGeometry, const FPointerEvent& CursorEvent) const override;
    // End of SWidget interface

private:
    /** The ImGui context index */
    int32 ContextIndex;
};