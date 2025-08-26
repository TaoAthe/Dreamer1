// Copyright Epic Games, Inc. All Rights Reserved.

#include "DreamerCodeEditor.h"
#include "Widgets/Layout/SSplitter.h"
#include "Widgets/Text/STextBlock.h"
#include "Widgets/Input/SButton.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/Layout/SScrollBox.h"
#include "HAL/FileManager.h"
#include "Misc/FileHelper.h"
#include "EditorStyleSet.h"
#include "Framework/Text/SyntaxHighlighterTextLayoutMarshaller.h"
#include "Framework/Text/TextLayout.h"
#include "Framework/Text/IRun.h"
#include "Framework/Text/SlateTextRun.h"

#define LOCTEXT_NAMESPACE "SDreamerCodeEditor"

// Custom syntax highlighter for C++ code
class FCppSyntaxHighlighter : public FSyntaxHighlighterTextLayoutMarshaller
{
public:
    FCppSyntaxHighlighter()
        : FSyntaxHighlighterTextLayoutMarshaller(FTextBlockStyle())
    {
        // Define colors for different syntax elements
        KeywordColor = FLinearColor(0.45f, 0.6f, 0.87f);  // Blue for keywords
        TypeColor = FLinearColor(0.42f, 0.87f, 0.45f);    // Green for types
        CommentColor = FLinearColor(0.5f, 0.5f, 0.5f);    // Gray for comments
        StringColor = FLinearColor(0.87f, 0.45f, 0.43f);  // Red for strings
        NumberColor = FLinearColor(0.9f, 0.6f, 0.1f);     // Orange for numbers
        PreprocessorColor = FLinearColor(0.7f, 0.4f, 0.7f); // Purple for preprocessor
        
        // Initialize keyword list
        Keywords = {
            TEXT("if"), TEXT("else"), TEXT("for"), TEXT("while"), TEXT("do"),
            TEXT("switch"), TEXT("case"), TEXT("default"), TEXT("break"), TEXT("continue"),
            TEXT("return"), TEXT("goto"), TEXT("new"), TEXT("delete"), TEXT("nullptr"),
            TEXT("true"), TEXT("false"), TEXT("this"), TEXT("super"), TEXT("class"),
            TEXT("struct"), TEXT("enum"), TEXT("union"), TEXT("const"), TEXT("static"),
            TEXT("volatile"), TEXT("public"), TEXT("private"), TEXT("protected"), TEXT("virtual"),
            TEXT("override"), TEXT("final"), TEXT("template"), TEXT("typename"), TEXT("namespace"),
            TEXT("using"), TEXT("try"), TEXT("catch"), TEXT("throw"), TEXT("noexcept")
        };
        
        // Initialize type list
        Types = {
            TEXT("void"), TEXT("bool"), TEXT("char"), TEXT("short"), TEXT("int"),
            TEXT("long"), TEXT("float"), TEXT("double"), TEXT("unsigned"), TEXT("signed"),
            TEXT("uint8"), TEXT("uint16"), TEXT("uint32"), TEXT("uint64"),
            TEXT("int8"), TEXT("int16"), TEXT("int32"), TEXT("int64"),
            TEXT("FString"), TEXT("FName"), TEXT("FText"), TEXT("TArray"),
            TEXT("TMap"), TEXT("TSet"), TEXT("TSharedPtr"), TEXT("TSharedRef"),
            TEXT("FVector"), TEXT("FRotator"), TEXT("FQuat"), TEXT("FTransform")
        };
    }

    virtual ~FCppSyntaxHighlighter() {}

protected:
    virtual void ParseTokens(const FString& SourceString, FTextLayout& TargetTextLayout, TArray<FSyntaxTokenizer::FTokenizedLine> TokenizedLines) override
    {
        TArray<FTextLayout::FNewLineData> LinesToAdd;
        LinesToAdd.Reserve(TokenizedLines.Num());
        
        for (int32 LineIndex = 0; LineIndex < TokenizedLines.Num(); ++LineIndex)
        {
            const FSyntaxTokenizer::FTokenizedLine& TokenizedLine = TokenizedLines[LineIndex];
            
            TSharedRef<FString> LineText = MakeShared<FString>(SourceString.Mid(TokenizedLine.Range.BeginIndex, TokenizedLine.Range.Len()));
            
            TArray<TSharedRef<IRun>> Runs;
            bool bIsInComment = false;
            bool bIsInString = false;
            bool bIsInChar = false;
            bool bIsInPreprocessor = false;
            
            // Check if this line starts with a preprocessor directive
            FString TrimmedLine = *LineText;
            TrimmedLine.TrimStartInline();
            if (TrimmedLine.StartsWith(TEXT("#")))
            {
                bIsInPreprocessor = true;
            }
            
            for (int32 TokenIndex = 0; TokenIndex < TokenizedLine.Tokens.Num(); ++TokenIndex)
            {
                const FSyntaxTokenizer::FToken& Token = TokenizedLine.Tokens[TokenIndex];
                FString TokenText = SourceString.Mid(Token.Range.BeginIndex, Token.Range.Len());
                FTextRange Range(Token.Range.BeginIndex - TokenizedLine.Range.BeginIndex, Token.Range.EndIndex - TokenizedLine.Range.BeginIndex);
                
                // Comment detection
                if (TokenText == TEXT("//"))
                {
                    bIsInComment = true;
                }
                else if (TokenText == TEXT("/*"))
                {
                    bIsInComment = true;
                }
                else if (TokenText == TEXT("*/"))
                {
                    bIsInComment = false;
                    continue;
                }
                
                // String detection
                if (TokenText == TEXT("\"") && !bIsInComment && !bIsInChar)
                {
                    bIsInString = !bIsInString;
                }
                
                // Character detection
                if (TokenText == TEXT("'") && !bIsInComment && !bIsInString)
                {
                    bIsInChar = !bIsInChar;
                }
                
                // Apply color based on token type
                FTextBlockStyle RunStyle = TextStyle;
                
                if (bIsInComment)
                {
                    RunStyle.ColorAndOpacity = FSlateColor(CommentColor);
                }
                else if (bIsInString || bIsInChar)
                {
                    RunStyle.ColorAndOpacity = FSlateColor(StringColor);
                }
                else if (bIsInPreprocessor)
                {
                    RunStyle.ColorAndOpacity = FSlateColor(PreprocessorColor);
                }
                else if (Keywords.Contains(TokenText))
                {
                    RunStyle.ColorAndOpacity = FSlateColor(KeywordColor);
                }
                else if (Types.Contains(TokenText))
                {
                    RunStyle.ColorAndOpacity = FSlateColor(TypeColor);
                }
                else if (TokenText.IsNumeric())
                {
                    RunStyle.ColorAndOpacity = FSlateColor(NumberColor);
                }
                
                Runs.Add(FSlateTextRun::Create(FRunInfo(), LineText, RunStyle, Range));
            }
            
            LinesToAdd.Add(FTextLayout::FNewLineData(MoveTemp(LineText), MoveTemp(Runs)));
        }
        
        TargetTextLayout.AddLines(LinesToAdd);
    }

private:
    FTextBlockStyle TextStyle;
    FLinearColor KeywordColor;
    FLinearColor TypeColor;
    FLinearColor CommentColor;
    FLinearColor StringColor;
    FLinearColor NumberColor;
    FLinearColor PreprocessorColor;
    TSet<FString> Keywords;
    TSet<FString> Types;
};

void SDreamerCodeEditor::Construct(const FArguments& InArgs)
{
    // Create the C++ syntax highlighter
    TSharedPtr<FCppSyntaxHighlighter> SyntaxHighlighter = MakeShared<FCppSyntaxHighlighter>();

    ChildSlot
    [
        SNew(SVerticalBox)
        
        // Toolbar
        + SVerticalBox::Slot()
        .AutoHeight()
        .Padding(2.0f)
        [
            SNew(SHorizontalBox)
            
            // Refresh button
            + SHorizontalBox::Slot()
            .AutoWidth()
            .Padding(2.0f)
            [
                SNew(SButton)
                .Text(LOCTEXT("RefreshFiles", "Refresh"))
                .ToolTipText(LOCTEXT("RefreshFilesTooltip", "Refresh the file list"))
                .OnClicked_Lambda([this]() { RefreshFileTree(); return FReply::Handled(); })
            ]
            
            // Save button
            + SHorizontalBox::Slot()
            .AutoWidth()
            .Padding(2.0f)
            [
                SNew(SButton)
                .Text(LOCTEXT("SaveFile", "Save"))
                .ToolTipText(LOCTEXT("SaveFileTooltip", "Save the current file"))
                .OnClicked_Lambda([this]() { SaveCurrentFile(); return FReply::Handled(); })
            ]
            
            // Current file label
            + SHorizontalBox::Slot()
            .FillWidth(1.0f)
            .VAlign(VAlign_Center)
            .Padding(8.0f, 0.0f)
            [
                SNew(STextBlock)
                .Text_Lambda([this]() { return FText::FromString(CurrentFilePath.IsEmpty() ? TEXT("No file selected") : CurrentFilePath); })
            ]
        ]
        
        // Main content area
        + SVerticalBox::Slot()
        .FillHeight(1.0f)
        [
            SNew(SSplitter)
            .Orientation(Orient_Horizontal)
            
            // File browser panel (left)
            + SSplitter::Slot()
            .Value(0.2f)
            [
                SNew(SBorder)
                .BorderImage(FEditorStyle::GetBrush("ToolPanel.GroupBorder"))
                .Padding(4.0f)
                [
                    SNew(SVerticalBox)
                    
                    // Search box
                    + SVerticalBox::Slot()
                    .AutoHeight()
                    .Padding(0.0f, 0.0f, 0.0f, 4.0f)
                    [
                        SNew(SSearchBox)
                        .HintText(LOCTEXT("SearchFiles", "Search files..."))
                        // We'll implement filtering later
                    ]
                    
                    // File tree
                    + SVerticalBox::Slot()
                    .FillHeight(1.0f)
                    [
                        SAssignNew(FileTreeView, STreeView<TSharedPtr<FCodeFileItem>>)
                        .TreeItemsSource(&RootItems)
                        .OnGenerateRow(this, &SDreamerCodeEditor::GenerateFileTreeRow)
                        .OnGetChildren(this, &SDreamerCodeEditor::GetFileTreeChildren)
                        .OnSelectionChanged(this, &SDreamerCodeEditor::OnFileSelected)
                        .SelectionMode(ESelectionMode::Single)
                    ]
                ]
            ]
            
            // Code editor panel (right)
            + SSplitter::Slot()
            .Value(0.8f)
            [
                SNew(SBorder)
                .BorderImage(FEditorStyle::GetBrush("ToolPanel.GroupBorder"))
                .Padding(4.0f)
                [
                    SNew(SHorizontalBox)
                    
                    // Line markers (for errors)
                    + SHorizontalBox::Slot()
                    .AutoWidth()
                    [
                        SNew(SBox)
                        .WidthOverride(16.0f)
                        [
                            SNew(SScrollBox)
                            .Orientation(Orient_Vertical)
                            .ScrollBarAlwaysVisible(false)
                            .ConsumeMouseWheel(EConsumeMouseWheel::Never)
                            
                            + SScrollBox::Slot()
                            [
                                SNew(SVerticalBox)
                                .Visibility_Lambda([this]() { return CurrentFileErrors.Num() > 0 ? EVisibility::Visible : EVisibility::Hidden; })
                                
                                // Generate line markers for each line in the document
                                // This is a simplified approach - a more robust implementation would
                                // dynamically create these markers based on the visible lines
                                + SVerticalBox::Slot()
                                .AutoHeight()
                                [
                                    SNew(STextBlock)
                                    .Text(FText::FromString(TEXT("1")))
                                    .ColorAndOpacity(this, &SDreamerCodeEditor::GetLineMarkerColor, 1)
                                    .ToolTipText(this, &SDreamerCodeEditor::GetLineToolTip, 1)
                                ]
                                
                                // Repeat for more lines - this is simplified
                                // In practice, you would generate these dynamically based on the document
                            ]
                        ]
                    ]
                    
                    // Code editor
                    + SHorizontalBox::Slot()
                    .FillWidth(1.0f)
                    [
                        SAssignNew(CodeEditor, SMultiLineEditableText)
                        .Text(FText::FromString(TEXT("")))
                        .TextStyle(FEditorStyle::Get(), "TextEditor.NormalText")
                        .Marshaller(SyntaxHighlighter)
                        .AutoWrapText(false)
                        .WrappingPolicy(ETextWrappingPolicy::NoWrap)
                        .AllowContextMenu(true)
                        .IsReadOnly(false)
                    ]
                ]
            ]
        ]
    ];

    // Initial file loading
    LoadSourceFiles();
}

void SDreamerCodeEditor::RefreshFileTree()
{
    LoadSourceFiles();
}

void SDreamerCodeEditor::LoadSourceFiles()
{
    RootItems.Empty();
    
    // Get the project source directory
    FString ProjectDir = FPaths::ProjectDir();
    FString SourceDir = FPaths::Combine(ProjectDir, TEXT("Source"));
    
    // Add project source files
    if (IFileManager::Get().DirectoryExists(*SourceDir))
    {
        TSharedPtr<FCodeFileItem> SourceRoot = MakeShared<FCodeFileItem>(TEXT("Source"), SourceDir);
        RootItems.Add(SourceRoot);
        
        // Recursively add files from the Source directory
        TArray<FString> FoundFiles;
        IFileManager::Get().FindFilesRecursive(FoundFiles, *SourceDir, TEXT("*.h"), true, true);
        IFileManager::Get().FindFilesRecursive(FoundFiles, *SourceDir, TEXT("*.cpp"), true, true);
        
        // Group files by directory
        TMap<FString, TSharedPtr<FCodeFileItem>> DirectoryMap;
        DirectoryMap.Add(SourceDir, SourceRoot);
        
        for (const FString& FilePath : FoundFiles)
        {
            FString FileName = FPaths::GetCleanFilename(FilePath);
            FString Directory = FPaths::GetPath(FilePath);
            
            // Create directory items if they don't exist
            TSharedPtr<FCodeFileItem> ParentItem = nullptr;
            if (Directory != SourceDir)
            {
                FString CurrentPath = SourceDir;
                FString RelativePath = Directory;
                RelativePath.RemoveFromStart(SourceDir);
                RelativePath.RemoveFromStart(TEXT("/"));
                
                TArray<FString> PathParts;
                RelativePath.ParseIntoArray(PathParts, TEXT("/"));
                
                for (const FString& Part : PathParts)
                {
                    CurrentPath = FPaths::Combine(CurrentPath, Part);
                    
                    if (!DirectoryMap.Contains(CurrentPath))
                    {
                        TSharedPtr<FCodeFileItem> NewItem = MakeShared<FCodeFileItem>(Part, CurrentPath);
                        DirectoryMap.Add(CurrentPath, NewItem);
                        
                        // Add to parent
                        FString ParentPath = FPaths::GetPath(CurrentPath);
                        if (DirectoryMap.Contains(ParentPath))
                        {
                            DirectoryMap[ParentPath]->Children.Add(NewItem);
                        }
                    }
                }
                
                ParentItem = DirectoryMap[Directory];
            }
            else
            {
                ParentItem = SourceRoot;
            }
            
            // Add file to its parent directory
            if (ParentItem.IsValid())
            {
                TSharedPtr<FCodeFileItem> FileItem = MakeShared<FCodeFileItem>(FileName, FilePath);
                ParentItem->Children.Add(FileItem);
            }
        }
    }
    
    // Add plugin source files
    FString PluginsDir = FPaths::Combine(ProjectDir, TEXT("Plugins"));
    if (IFileManager::Get().DirectoryExists(*PluginsDir))
    {
        TSharedPtr<FCodeFileItem> PluginsRoot = MakeShared<FCodeFileItem>(TEXT("Plugins"), PluginsDir);
        RootItems.Add(PluginsRoot);
        
        // Find plugin directories
        TArray<FString> PluginDirs;
        IFileManager::Get().FindFiles(PluginDirs, *PluginsDir, false, true);
        
        for (const FString& PluginName : PluginDirs)
        {
            FString PluginDir = FPaths::Combine(PluginsDir, PluginName);
            FString PluginSourceDir = FPaths::Combine(PluginDir, TEXT("Source"));
            
            if (IFileManager::Get().DirectoryExists(*PluginSourceDir))
            {
                TSharedPtr<FCodeFileItem> PluginItem = MakeShared<FCodeFileItem>(PluginName, PluginDir);
                PluginsRoot->Children.Add(PluginItem);
                
                // Add source files from this plugin
                TArray<FString> FoundFiles;
                IFileManager::Get().FindFilesRecursive(FoundFiles, *PluginSourceDir, TEXT("*.h"), true, true);
                IFileManager::Get().FindFilesRecursive(FoundFiles, *PluginSourceDir, TEXT("*.cpp"), true, true);
                
                // Group files by module
                TMap<FString, TSharedPtr<FCodeFileItem>> ModuleMap;
                
                for (const FString& FilePath : FoundFiles)
                {
                    FString FileName = FPaths::GetCleanFilename(FilePath);
                    FString Directory = FPaths::GetPath(FilePath);
                    
                    // Extract module name from path
                    FString RelPath = Directory;
                    RelPath.RemoveFromStart(PluginSourceDir);
                    RelPath.RemoveFromStart(TEXT("/"));
                    
                    TArray<FString> PathParts;
                    RelPath.ParseIntoArray(PathParts, TEXT("/"));
                    
                    if (PathParts.Num() > 0)
                    {
                        FString ModuleName = PathParts[0];
                        FString ModulePath = FPaths::Combine(PluginSourceDir, ModuleName);
                        
                        // Create module item if it doesn't exist
                        if (!ModuleMap.Contains(ModulePath))
                        {
                            TSharedPtr<FCodeFileItem> ModuleItem = MakeShared<FCodeFileItem>(ModuleName, ModulePath);
                            ModuleMap.Add(ModulePath, ModuleItem);
                            PluginItem->Children.Add(ModuleItem);
                        }
                        
                        // Create file item
                        TSharedPtr<FCodeFileItem> FileItem = MakeShared<FCodeFileItem>(FileName, FilePath);
                        ModuleMap[ModulePath]->Children.Add(FileItem);
                    }
                }
            }
        }
    }
    
    // Refresh the view
    if (FileTreeView.IsValid())
    {
        FileTreeView->RequestTreeRefresh();
    }
}

void SDreamerCodeEditor::OnFileSelected(TSharedPtr<FCodeFileItem> Item, ESelectInfo::Type SelectType)
{
    if (Item.IsValid())
    {
        // Only load if it's a file (not a directory)
        if (Item->Children.Num() == 0 && IFileManager::Get().FileExists(*Item->FilePath))
        {
            LoadSourceFile(Item->FilePath);
        }
    }
}

TSharedRef<ITableRow> SDreamerCodeEditor::GenerateFileTreeRow(TSharedPtr<FCodeFileItem> Item, const TSharedRef<STableViewBase>& OwnerTable)
{
    return SNew(STableRow<TSharedPtr<FCodeFileItem>>, OwnerTable)
    [
        SNew(SHorizontalBox)
        
        + SHorizontalBox::Slot()
        .AutoWidth()
        .Padding(0, 0, 4, 0)
        [
            SNew(STextBlock)
            .Text(FText::FromString(Item->FileName))
            .ColorAndOpacity(Item->Children.Num() > 0 ? FLinearColor(0.9f, 0.9f, 0.5f) : FLinearColor::White)
        ]
    ];
}

void SDreamerCodeEditor::GetFileTreeChildren(TSharedPtr<FCodeFileItem> Item, TArray<TSharedPtr<FCodeFileItem>>& OutChildren)
{
    OutChildren = Item->Children;
}

void SDreamerCodeEditor::LoadSourceFile(const FString& FilePath)
{
    FString FileContent;
    if (FFileHelper::LoadFileToString(FileContent, *FilePath))
    {
        CurrentFilePath = FilePath;
        CodeEditor->SetText(FText::FromString(FileContent));
    }
}

void SDreamerCodeEditor::SaveCurrentFile()
{
    if (!CurrentFilePath.IsEmpty())
    {
        FString Content = CodeEditor->GetText().ToString();
        FFileHelper::SaveStringToFile(Content, *CurrentFilePath);
    }
}

TSharedPtr<FTextSyntaxHighlighter> SDreamerCodeEditor::CreateCppSyntaxHighlighter()
{
    // This is now handled by our custom FCppSyntaxHighlighter class
    return nullptr;
}

void SDreamerCodeEditor::SetErrors(const TArray<TSharedPtr<FBuildError>>& InErrors)
{
    CurrentFileErrors.Empty();
    
    // Filter errors for the current file
    for (const TSharedPtr<FBuildError>& Error : InErrors)
    {
        if (Error->GetFilePath() == CurrentFilePath)
        {
            CurrentFileErrors.Add(Error);
        }
    }
    
    // The editor needs to be refreshed to show the error markers
    if (CodeEditor.IsValid())
    {
        // This is a simplified approach - ideally you would redraw only the line markers
        // rather than forcing a full refresh
        CodeEditor->Refresh();
    }
}

FText SDreamerCodeEditor::GetLineToolTip(int32 LineNumber) const
{
    // Collect all errors for this line
    TArray<FString> ErrorMessages;
    
    for (const TSharedPtr<FBuildError>& Error : CurrentFileErrors)
    {
        if (Error->GetLineNumber() == LineNumber)
        {
            ErrorMessages.Add(Error->GetMessage());
        }
    }
    
    if (ErrorMessages.Num() > 0)
    {
        return FText::FromString(FString::Join(ErrorMessages, TEXT("\n")));
    }
    
    return FText::GetEmpty();
}

FSlateColor SDreamerCodeEditor::GetLineMarkerColor(int32 LineNumber) const
{
    // Check if there are any errors on this line
    for (const TSharedPtr<FBuildError>& Error : CurrentFileErrors)
    {
        if (Error->GetLineNumber() == LineNumber)
        {
            if (Error->GetSeverity() == EBuildMessageSeverity::Error)
            {
                return FLinearColor::Red;
            }
            else if (Error->GetSeverity() == EBuildMessageSeverity::Warning)
            {
                return FLinearColor(1.0f, 0.8f, 0.0f); // Yellow
            }
        }
    }
    
    // No errors on this line
    return FLinearColor::Transparent;
}

#undef LOCTEXT_NAMESPACE