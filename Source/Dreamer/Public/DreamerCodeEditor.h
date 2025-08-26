// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Widgets/SCompoundWidget.h"
#include "Widgets/Input/SMultiLineEditableText.h"
#include "Widgets/Views/STreeView.h"
#include "Widgets/Input/SSearchBox.h"

struct FCodeFileItem
{
    FString FileName;
    FString FilePath;
    TArray<TSharedPtr<FCodeFileItem>> Children;

    FCodeFileItem(const FString& InFileName, const FString& InFilePath)
        : FileName(InFileName), FilePath(InFilePath)
    {
    }
};

/**
 * The main C++ code editor widget for the Dreamer plugin
 */
class DREAMER_API SDreamerCodeEditor : public SCompoundWidget
{
public:
    SLATE_BEGIN_ARGS(SDreamerCodeEditor)
    {}
    SLATE_END_ARGS()

    /** Widget constructor */
    void Construct(const FArguments& InArgs);

private:
    /** Text editor widget */
    TSharedPtr<SMultiLineEditableText> CodeEditor;
    
    /** File browser widget */
    TSharedPtr<STreeView<TSharedPtr<FCodeFileItem>>> FileTreeView;
    
    /** List of code files */
    TArray<TSharedPtr<FCodeFileItem>> RootItems;
    
    /** Currently loaded file path */
    FString CurrentFilePath;

    /** Refreshes the file tree */
    void RefreshFileTree();
    
    /** Loads source files from the project */
    void LoadSourceFiles();
    
    /** Called when a file is selected in the tree */
    void OnFileSelected(TSharedPtr<FCodeFileItem> Item, ESelectInfo::Type SelectType);
    
    /** Generates a row in the file tree */
    TSharedRef<ITableRow> GenerateFileTreeRow(TSharedPtr<FCodeFileItem> Item, const TSharedRef<STableViewBase>& OwnerTable);
    
    /** Gets children for the file tree */
    void GetFileTreeChildren(TSharedPtr<FCodeFileItem> Item, TArray<TSharedPtr<FCodeFileItem>>& OutChildren);
    
    /** Loads a source file */
    void LoadSourceFile(const FString& FilePath);
    
    /** Saves the current file */
    void SaveCurrentFile();
    
    /** Creates a syntax highlighter for C++ code */
    TSharedPtr<class FTextSyntaxHighlighter> CreateCppSyntaxHighlighter();
};