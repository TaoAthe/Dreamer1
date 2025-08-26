/*
 * File: /Source/InEditorCpp/Private/CppEditorBridge.cpp
 * 
 * Purpose: C++ Editor Bridge Implementation
 * Implements the bridge between the Unreal Editor and the native C++ editor.
 */

#include "InEditorCppPrivatePCH.h"
#include "CppEditorBridge.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "HAL/PlatformFileManager.h"
#include "GenericPlatform/GenericPlatformFile.h"
#include "DesktopPlatformModule.h"
#include "IDesktopPlatform.h"

FCppEditorBridge::FCppEditorBridge(TSharedPtr<FClangdService> InClangdService)
    : ClangdService(InClangdService)
{
    LoadRecentFiles();
}

FCppEditorBridge::~FCppEditorBridge()
{
    SaveRecentFiles();
}

bool FCppEditorBridge::OpenFile(const FString& FilePath)
{
    IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();
    if (!PlatformFile.FileExists(*FilePath))
    {
        return false;
    }

    AddRecentFile(FilePath);
    return true;
}

bool FCppEditorBridge::SaveFile(const FString& FilePath, const FString& Content)
{
    return FFileHelper::SaveStringToFile(Content, *FilePath);
}

bool FCppEditorBridge::GetFileContent(const FString& FilePath, FString& OutContent)
{
    return FFileHelper::LoadFileToString(OutContent, *FilePath);
}

TArray<FString> FCppEditorBridge::GetProjectSourceFiles()
{
    TArray<FString> SourceFiles;
    FString ProjectDir = FPaths::ProjectDir();
    FString SourceDir = FPaths::Combine(ProjectDir, TEXT("Source"));
    
    IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();
    
    auto RecursiveFileSearch = [&](const FString& Dir, TArray<FString>& Files)
    {
        PlatformFile.IterateDirectory(*Dir, [&](const TCHAR* FilenameOrDirectory, bool bIsDirectory) -> bool
        {
            FString FullPath = FilenameOrDirectory;
            
            if (bIsDirectory)
            {
                RecursiveFileSearch(FullPath, Files);
            }
            else if (FullPath.EndsWith(TEXT(".h")) || FullPath.EndsWith(TEXT(".cpp")))
            {
                Files.Add(FullPath);
            }
            
            return true;
        });
    };
    
    RecursiveFileSearch(SourceDir, SourceFiles);
    return SourceFiles;
}

TArray<FString> FCppEditorBridge::GetRecentFiles()
{
    return RecentFiles;
}

void FCppEditorBridge::AddRecentFile(const FString& FilePath)
{
    // Remove if already exists to move to front
    RecentFiles.Remove(FilePath);
    
    // Add to front
    RecentFiles.Insert(FilePath, 0);
    
    // Keep only last 10
    if (RecentFiles.Num() > 10)
    {
        RecentFiles.RemoveAt(10, RecentFiles.Num() - 10);
    }
    
    SaveRecentFiles();
}

void FCppEditorBridge::LoadRecentFiles()
{
    FString SavePath = FPaths::Combine(FPaths::ProjectSavedDir(), TEXT("InEditorCpp"), TEXT("RecentFiles.txt"));
    FString FileContent;
    
    if (FFileHelper::LoadFileToString(FileContent, *SavePath))
    {
        FileContent.ParseIntoArray(RecentFiles, TEXT("\n"), true);
    }
}

void FCppEditorBridge::SaveRecentFiles()
{
    FString SavePath = FPaths::Combine(FPaths::ProjectSavedDir(), TEXT("InEditorCpp"), TEXT("RecentFiles.txt"));
    FString FileContent = FString::Join(RecentFiles, TEXT("\n"));
    
    // Ensure directory exists
    FString SaveDir = FPaths::Combine(FPaths::ProjectSavedDir(), TEXT("InEditorCpp"));
    IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();
    
    if (!PlatformFile.DirectoryExists(*SaveDir))
    {
        PlatformFile.CreateDirectoryTree(*SaveDir);
    }
    
    FFileHelper::SaveStringToFile(FileContent, *SavePath);
}
