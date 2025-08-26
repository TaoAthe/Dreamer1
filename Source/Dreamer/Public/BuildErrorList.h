// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Widgets/SCompoundWidget.h"
#include "Widgets/Views/STableRow.h"
#include "Widgets/Views/SListView.h"
#include "BuildError.h"

/**
 * Widget that displays a list of build errors and warnings
 */
class DREAMER_API SBuildErrorList : public SCompoundWidget
{
public:
    SLATE_BEGIN_ARGS(SBuildErrorList)
    {}
    SLATE_END_ARGS()

    /** Widget constructor */
    void Construct(const FArguments& InArgs);

    /** Sets the error list */
    void SetErrors(const TArray<TSharedPtr<FBuildError>>& InErrors);

    /** Sets the warning list */
    void SetWarnings(const TArray<TSharedPtr<FBuildError>>& InWarnings);

    /** Clears all errors and warnings */
    void ClearAll();

private:
    /** Called when an error is selected */
    void OnErrorSelected(TSharedPtr<FBuildError> InError, ESelectInfo::Type SelectType);

    /** Creates a row for the error list */
    TSharedRef<ITableRow> OnGenerateRow(TSharedPtr<FBuildError> InError, const TSharedRef<STableViewBase>& OwnerTable);

    /** Gets the text color for an error */
    FSlateColor GetErrorTextColor(TSharedPtr<FBuildError> InError) const;

    /** Gets the severity icon for an error */
    const FSlateBrush* GetSeverityIcon(TSharedPtr<FBuildError> InError) const;

    /** The list of all errors and warnings */
    TArray<TSharedPtr<FBuildError>> AllMessages;

    /** The error list widget */
    TSharedPtr<SListView<TSharedPtr<FBuildError>>> ErrorListView;
};