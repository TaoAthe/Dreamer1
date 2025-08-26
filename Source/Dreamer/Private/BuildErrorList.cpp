// Copyright Epic Games, Inc. All Rights Reserved.

#include "BuildErrorList.h"
#include "EditorStyleSet.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/Text/STextBlock.h"
#include "Widgets/Images/SImage.h"
#include "Widgets/Layout/SBorder.h"
#include "Widgets/Input/SButton.h"
#include "Widgets/Views/SHeaderRow.h"
#include "Widgets/Views/STableRow.h"
#include "Widgets/Layout/SBox.h"
#include "Framework/Commands/UIAction.h"
#include "Framework/Commands/UICommandList.h"
#include "DreamerModule.h"

#define LOCTEXT_NAMESPACE "BuildErrorList"

void SBuildErrorList::Construct(const FArguments& InArgs)
{
    ChildSlot
    [
        SNew(SBorder)
        .BorderImage(FEditorStyle::GetBrush("ToolPanel.GroupBorder"))
        .Padding(4.0f)
        [
            SNew(SVerticalBox)

            // Toolbar
            + SVerticalBox::Slot()
            .AutoHeight()
            .Padding(0.0f, 0.0f, 0.0f, 4.0f)
            [
                SNew(SHorizontalBox)

                // Clear button
                + SHorizontalBox::Slot()
                .AutoWidth()
                .VAlign(VAlign_Center)
                .Padding(0.0f, 0.0f, 4.0f, 0.0f)
                [
                    SNew(SButton)
                    .Text(LOCTEXT("ClearAll", "Clear All"))
                    .ToolTipText(LOCTEXT("ClearAllTooltip", "Clear all build messages"))
                    .OnClicked(this, &SBuildErrorList::OnClearAllClicked)
                ]

                // Filter options will go here in the future

                // Message count
                + SHorizontalBox::Slot()
                .FillWidth(1.0f)
                .HAlign(HAlign_Right)
                .VAlign(VAlign_Center)
                .Padding(4.0f, 0.0f, 0.0f, 0.0f)
                [
                    SNew(STextBlock)
                    .Text(this, &SBuildErrorList::GetMessageCountText)
                ]
            ]

            // Error list
            + SVerticalBox::Slot()
            .FillHeight(1.0f)
            [
                SAssignNew(ErrorListView, SListView<TSharedPtr<FBuildError>>)
                .ItemHeight(24.0f)
                .ListItemsSource(&AllMessages)
                .OnGenerateRow(this, &SBuildErrorList::OnGenerateRow)
                .OnSelectionChanged(this, &SBuildErrorList::OnErrorSelected)
                .SelectionMode(ESelectionMode::Single)
                .HeaderRow
                (
                    SNew(SHeaderRow)
                    
                    // Severity column
                    + SHeaderRow::Column("Severity")
                    .DefaultLabel(LOCTEXT("SeverityColumn", ""))
                    .FixedWidth(24.0f)
                    
                    // Description column
                    + SHeaderRow::Column("Description")
                    .DefaultLabel(LOCTEXT("DescriptionColumn", "Description"))
                    .FillWidth(0.5f)
                    
                    // File column
                    + SHeaderRow::Column("File")
                    .DefaultLabel(LOCTEXT("FileColumn", "File"))
                    .FillWidth(0.3f)
                    
                    // Line column
                    + SHeaderRow::Column("Line")
                    .DefaultLabel(LOCTEXT("LineColumn", "Line"))
                    .FixedWidth(60.0f)
                )
            ]
        ]
    ];
}

void SBuildErrorList::SetErrors(const TArray<TSharedPtr<FBuildError>>& InErrors)
{
    // Remove old errors from the list
    AllMessages.RemoveAll([](TSharedPtr<FBuildError> Error) { 
        return Error->GetSeverity() == EBuildMessageSeverity::Error; 
    });

    // Add new errors
    AllMessages.Append(InErrors);

    // Sort messages (errors first, then by file, then by line)
    AllMessages.Sort([](const TSharedPtr<FBuildError>& A, const TSharedPtr<FBuildError>& B) {
        // Sort by severity first
        if (A->GetSeverity() != B->GetSeverity())
        {
            return A->GetSeverity() > B->GetSeverity(); // Errors before warnings
        }

        // Then by file
        if (A->GetFilePath() != B->GetFilePath())
        {
            return A->GetFilePath() < B->GetFilePath();
        }

        // Then by line
        return A->GetLineNumber() < B->GetLineNumber();
    });

    // Refresh the list view
    if (ErrorListView.IsValid())
    {
        ErrorListView->RequestListRefresh();
    }
}

void SBuildErrorList::SetWarnings(const TArray<TSharedPtr<FBuildError>>& InWarnings)
{
    // Remove old warnings from the list
    AllMessages.RemoveAll([](TSharedPtr<FBuildError> Error) { 
        return Error->GetSeverity() == EBuildMessageSeverity::Warning; 
    });

    // Add new warnings
    AllMessages.Append(InWarnings);

    // Sort messages (errors first, then by file, then by line)
    AllMessages.Sort([](const TSharedPtr<FBuildError>& A, const TSharedPtr<FBuildError>& B) {
        // Sort by severity first
        if (A->GetSeverity() != B->GetSeverity())
        {
            return A->GetSeverity() > B->GetSeverity(); // Errors before warnings
        }

        // Then by file
        if (A->GetFilePath() != B->GetFilePath())
        {
            return A->GetFilePath() < B->GetFilePath();
        }

        // Then by line
        return A->GetLineNumber() < B->GetLineNumber();
    });

    // Refresh the list view
    if (ErrorListView.IsValid())
    {
        ErrorListView->RequestListRefresh();
    }
}

void SBuildErrorList::ClearAll()
{
    AllMessages.Empty();

    // Refresh the list view
    if (ErrorListView.IsValid())
    {
        ErrorListView->RequestListRefresh();
    }
}

FReply SBuildErrorList::OnClearAllClicked()
{
    ClearAll();
    return FReply::Handled();
}

FText SBuildErrorList::GetMessageCountText() const
{
    int32 ErrorCount = 0;
    int32 WarningCount = 0;

    // Count errors and warnings
    for (const TSharedPtr<FBuildError>& Message : AllMessages)
    {
        if (Message->GetSeverity() == EBuildMessageSeverity::Error)
        {
            ErrorCount++;
        }
        else if (Message->GetSeverity() == EBuildMessageSeverity::Warning)
        {
            WarningCount++;
        }
    }

    return FText::Format(
        LOCTEXT("MessageCount", "{0} error(s), {1} warning(s)"),
        FText::AsNumber(ErrorCount),
        FText::AsNumber(WarningCount)
    );
}

void SBuildErrorList::OnErrorSelected(TSharedPtr<FBuildError> InError, ESelectInfo::Type SelectType)
{
    if (!InError.IsValid())
    {
        return;
    }

    // Get the file path and line number
    FString FilePath = InError->GetFilePath();
    int32 LineNumber = InError->GetLineNumber();

    // Notify the module to open the file at the specified location
    FDreamerModule& DreamerModule = FModuleManager::GetModuleChecked<FDreamerModule>("Dreamer");
    DreamerModule.OpenFileAtLocation(FilePath, LineNumber);
}

TSharedRef<ITableRow> SBuildErrorList::OnGenerateRow(TSharedPtr<FBuildError> InError, const TSharedRef<STableViewBase>& OwnerTable)
{
    return SNew(STableRow<TSharedPtr<FBuildError>>, OwnerTable)
        [
            SNew(SHorizontalBox)

            // Severity icon
            + SHorizontalBox::Slot()
            .AutoWidth()
            .HAlign(HAlign_Center)
            .VAlign(VAlign_Center)
            .Padding(4.0f, 0.0f)
            [
                SNew(SImage)
                .Image(GetSeverityIcon(InError))
                .ColorAndOpacity(GetErrorTextColor(InError))
            ]

            // Description
            + SHorizontalBox::Slot()
            .FillWidth(0.5f)
            .VAlign(VAlign_Center)
            .Padding(4.0f, 0.0f)
            [
                SNew(STextBlock)
                .Text(FText::FromString(InError->GetMessage()))
                .ColorAndOpacity(GetErrorTextColor(InError))
            ]

            // File
            + SHorizontalBox::Slot()
            .FillWidth(0.3f)
            .VAlign(VAlign_Center)
            .Padding(4.0f, 0.0f)
            [
                SNew(STextBlock)
                .Text(FText::FromString(FPaths::GetCleanFilename(InError->GetFilePath())))
                .ToolTipText(FText::FromString(InError->GetFilePath()))
            ]

            // Line
            + SHorizontalBox::Slot()
            .AutoWidth()
            .VAlign(VAlign_Center)
            .Padding(4.0f, 0.0f)
            [
                SNew(SBox)
                .WidthOverride(60.0f)
                [
                    SNew(STextBlock)
                    .Text(FText::AsNumber(InError->GetLineNumber()))
                ]
            ]
        ];
}

FSlateColor SBuildErrorList::GetErrorTextColor(TSharedPtr<FBuildError> InError) const
{
    switch (InError->GetSeverity())
    {
    case EBuildMessageSeverity::Error:
        return FLinearColor::Red;
    case EBuildMessageSeverity::Warning:
        return FLinearColor(1.0f, 0.8f, 0.0f); // Yellow
    default:
        return FLinearColor::White;
    }
}

const FSlateBrush* SBuildErrorList::GetSeverityIcon(TSharedPtr<FBuildError> InError) const
{
    switch (InError->GetSeverity())
    {
    case EBuildMessageSeverity::Error:
        return FEditorStyle::GetBrush("Icons.Error");
    case EBuildMessageSeverity::Warning:
        return FEditorStyle::GetBrush("Icons.Warning");
    default:
        return FEditorStyle::GetBrush("Icons.Info");
    }
}

#undef LOCTEXT_NAMESPACE