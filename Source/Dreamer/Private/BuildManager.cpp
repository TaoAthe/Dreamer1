// Copyright Epic Games, Inc. All Rights Reserved.

#include "BuildManager.h"
#include "Misc/App.h"
#include "Misc/OutputDeviceRedirector.h"
#include "Misc/FileHelper.h"
#include "HAL/PlatformProcess.h"
#include "Interfaces/IMainFrameModule.h"
#include "DesktopPlatformModule.h"
#include "Framework/Notifications/NotificationManager.h"
#include "Widgets/Notifications/SNotificationList.h"
#include "Editor.h"
#include "ISourceCodeAccessModule.h"
#include "Developer/HotReload/Public/IHotReload.h"
#include "AssetRegistry/AssetRegistryModule.h"

FBuildManager::FBuildManager()
    : BuildProgress(0.0f)
    , bBuildInProgress(false)
    , bCancellationRequested(false)
{
}

FBuildManager::~FBuildManager()
{
    Shutdown();
}

void FBuildManager::Initialize()
{
    // Initialize any necessary resources
}

void FBuildManager::Shutdown()
{
    // Cancel any in-progress build
    if (bBuildInProgress)
    {
        CancelBuild();
    }
}

void FBuildManager::BuildProject(const FString& Configuration, const FString& Target)
{
    if (bBuildInProgress)
    {
        UE_LOG(LogTemp, Warning, TEXT("A build is already in progress"));
        return;
    }

    // Clear previous build messages
    ClearBuildMessages();

    // Set build in progress flag
    bBuildInProgress = true;
    bCancellationRequested = false;
    BuildProgress = 0.0f;

    // Notify that a build has started
    BuildStartedEvent.Broadcast();

    // Get project path
    FString ProjectPath = FPaths::ConvertRelativePathToFull(FPaths::GetProjectFilePath());

    // Display a notification
    FNotificationInfo Info(FText::Format(
        NSLOCTEXT("DreamerBuildManager", "BuildInProgress", "Building {0} ({1})..."),
        FText::FromString(FApp::GetProjectName()),
        FText::FromString(Configuration)
    ));
    Info.bFireAndForget = false;
    Info.bUseSuccessFailIcons = true;
    Info.bUseLargeFont = false;
    Info.bUseThrobber = true;
    Info.FadeOutDuration = 0.5f;
    TSharedPtr<SNotificationItem> NotificationItem = FSlateNotificationManager::Get().AddNotification(Info);
    NotificationItem->SetCompletionState(SNotificationItem::CS_Pending);

    // Save all unsaved files
    IMainFrameModule& MainFrameModule = FModuleManager::LoadModuleChecked<IMainFrameModule>("MainFrame");
    MainFrameModule.GetMainFrameCommandBindings()->GetActionForCommand("SaveAll")->Execute();

    // Get engine path
    FString EnginePath = FPaths::ConvertRelativePathToFull(FPaths::EngineDir());
    FString UATPath = FPaths::Combine(EnginePath, TEXT("Build/BatchFiles"));

#if PLATFORM_WINDOWS
    UATPath = FPaths::Combine(UATPath, TEXT("RunUAT.bat"));
#else
    UATPath = FPaths::Combine(UATPath, TEXT("RunUAT.sh"));
#endif

    // Build command line
    FString PlatformName = TEXT("Win64"); // Default to Win64, could be parameterized later
    FString CommandLine = FString::Printf(TEXT("BuildEditor -Project=\"%s\" -Target=%s%s -Platform=%s -Configuration=%s -WaitMutex -FromMsBuild"),
        *ProjectPath,
        *FApp::GetProjectName(),
        *Target,
        *PlatformName,
        *Configuration);

    // Create process
    FProcHandle ProcessHandle = FPlatformProcess::CreateProc(
        *UATPath,
        *CommandLine,
        true,
        false,
        false,
        nullptr,
        0,
        *FPaths::GetPath(ProjectPath),
        nullptr);

    if (ProcessHandle.IsValid())
    {
        UATProcessHandle = ProcessHandle;

        // Start a thread to read the process output
        FPlatformProcess::CreatePipe(ReadPipe, WritePipe);
        OutputReaderThread = FRunnableThread::Create(
            new FOutputReaderRunnable(this, ReadPipe, WritePipe, ProcessHandle),
            TEXT("BuildOutputReader"));

        // Setup process completion callback
        FPlatformProcess::SetThreadAffinityMask(OutputReaderThread->GetThreadID(), FPlatformAffinity::GetNoAffinityMask());

        // Output some debug info
        UE_LOG(LogTemp, Display, TEXT("Build started with command line: %s %s"), *UATPath, *CommandLine);
    }
    else
    {
        // Failed to start the build process
        bBuildInProgress = false;
        NotificationItem->SetCompletionState(SNotificationItem::CS_Fail);
        NotificationItem->SetText(NSLOCTEXT("DreamerBuildManager", "BuildFailed", "Failed to start build process"));
        NotificationItem->ExpireAndFadeout();

        // Notify that the build has completed (with failure)
        BuildCompletedEvent.Broadcast(false);
    }
}

void FBuildManager::CancelBuild()
{
    if (!bBuildInProgress)
    {
        return;
    }

    bCancellationRequested = true;

    if (UATProcessHandle.IsValid())
    {
        // Terminate the UAT process
        FPlatformProcess::TerminateProc(UATProcessHandle, true);
        UATProcessHandle.Reset();
    }

    // Update status
    bBuildInProgress = false;
    BuildProgress = 0.0f;

    // Notify that the build has been cancelled
    BuildCompletedEvent.Broadcast(false);
}

bool FBuildManager::IsBuildInProgress() const
{
    return bBuildInProgress;
}

float FBuildManager::GetBuildProgress() const
{
    return BuildProgress;
}

const TArray<TSharedPtr<FBuildError>>& FBuildManager::GetBuildErrors() const
{
    return BuildErrors;
}

const TArray<TSharedPtr<FBuildError>>& FBuildManager::GetBuildWarnings() const
{
    return BuildWarnings;
}

void FBuildManager::ClearBuildMessages()
{
    BuildErrors.Empty();
    BuildWarnings.Empty();
    BuildErrorsChangedEvent.Broadcast();
}

void FBuildManager::ParseBuildOutput(const FString& Output)
{
    // Split the output into lines
    TArray<FString> Lines;
    Output.ParseIntoArrayLines(Lines);

    for (const FString& Line : Lines)
    {
        // Skip empty lines
        if (Line.IsEmpty())
        {
            continue;
        }

        // Look for error patterns in the output
        
        // Pattern 1: Standard compiler error format:
        // file(line,column): error/warning: message
        FRegexPattern Pattern1(TEXT("([^(:]+)\\((\\d+)(,(\\d+))?\\): (error|warning)( [A-Z0-9]+)?: (.*)"));
        FRegexMatcher Matcher1(Pattern1, Line);

        if (Matcher1.FindNext())
        {
            FString FilePath = Matcher1.GetCaptureGroup(1);
            int32 LineNumber = FCString::Atoi(*Matcher1.GetCaptureGroup(2));
            int32 ColumnNumber = Matcher1.GetCaptureGroup(4).IsEmpty() ? 0 : FCString::Atoi(*Matcher1.GetCaptureGroup(4));
            FString Type = Matcher1.GetCaptureGroup(5);
            FString Message = Matcher1.GetCaptureGroup(7);

            EBuildMessageSeverity Severity = Type.Equals(TEXT("error"), ESearchCase::IgnoreCase) 
                ? EBuildMessageSeverity::Error 
                : EBuildMessageSeverity::Warning;

            TSharedPtr<FBuildError> BuildError = MakeShared<FBuildError>(Message, FilePath, LineNumber, ColumnNumber, Severity);

            if (Severity == EBuildMessageSeverity::Error)
            {
                BuildErrors.Add(BuildError);
            }
            else
            {
                BuildWarnings.Add(BuildError);
            }

            continue;
        }
        
        // Pattern 2: More general error message with file path in it
        // Error: <message> [file: path/to/file.cpp line: 123]
        FRegexPattern Pattern2(TEXT("(Error|Warning): (.*) \\[file: ([^\\]]+) line: (\\d+)\\]"));
        FRegexMatcher Matcher2(Pattern2, Line);

        if (Matcher2.FindNext())
        {
            FString Type = Matcher2.GetCaptureGroup(1);
            FString Message = Matcher2.GetCaptureGroup(2);
            FString FilePath = Matcher2.GetCaptureGroup(3);
            int32 LineNumber = FCString::Atoi(*Matcher2.GetCaptureGroup(4));
            int32 ColumnNumber = 0;

            EBuildMessageSeverity Severity = Type.Equals(TEXT("Error"), ESearchCase::IgnoreCase) 
                ? EBuildMessageSeverity::Error 
                : EBuildMessageSeverity::Warning;

            TSharedPtr<FBuildError> BuildError = MakeShared<FBuildError>(Message, FilePath, LineNumber, ColumnNumber, Severity);

            if (Severity == EBuildMessageSeverity::Error)
            {
                BuildErrors.Add(BuildError);
            }
            else
            {
                BuildWarnings.Add(BuildError);
            }

            continue;
        }

        // Look for progress indicators in the output
        if (Line.Contains(TEXT("Progress: ")))
        {
            FRegexPattern ProgressPattern(TEXT("Progress: (\\d+)%"));
            FRegexMatcher ProgressMatcher(ProgressPattern, Line);

            if (ProgressMatcher.FindNext())
            {
                int32 ProgressPercent = FCString::Atoi(*ProgressMatcher.GetCaptureGroup(1));
                BuildProgress = ProgressPercent / 100.0f;
                BuildProgressEvent.Broadcast(BuildProgress);
            }
        }
    }

    // Notify that the build errors have changed
    if (BuildErrors.Num() > 0 || BuildWarnings.Num() > 0)
    {
        BuildErrorsChangedEvent.Broadcast();
    }
}

void FBuildManager::HandleUATOutput(FString Output)
{
    // Parse the output for errors and warnings
    ParseBuildOutput(Output);

    // Check if the build is complete
    if (Output.Contains(TEXT("BUILD SUCCESSFUL")) || Output.Contains(TEXT("BUILD COMPLETED SUCCESSFULLY")))
    {
        // Build succeeded
        bBuildInProgress = false;
        BuildProgress = 1.0f;
        BuildProgressEvent.Broadcast(BuildProgress);

        // Display a success notification
        FNotificationInfo Info(NSLOCTEXT("DreamerBuildManager", "BuildSucceeded", "Build completed successfully"));
        Info.bFireAndForget = true;
        Info.bUseSuccessFailIcons = true;
        Info.FadeOutDuration = 1.0f;
        TSharedPtr<SNotificationItem> NotificationItem = FSlateNotificationManager::Get().AddNotification(Info);
        NotificationItem->SetCompletionState(SNotificationItem::CS_Success);

        // Notify that the build has completed
        BuildCompletedEvent.Broadcast(true);
    }
    else if (Output.Contains(TEXT("BUILD FAILED")) || Output.Contains(TEXT("BUILD CANCELED")))
    {
        // Build failed
        bBuildInProgress = false;
        BuildProgress = 1.0f;
        BuildProgressEvent.Broadcast(BuildProgress);

        // Display a failure notification
        FNotificationInfo Info(FText::Format(
            NSLOCTEXT("DreamerBuildManager", "BuildFailed", "Build failed with {0} error(s) and {1} warning(s)"),
            FText::AsNumber(BuildErrors.Num()),
            FText::AsNumber(BuildWarnings.Num())
        ));
        Info.bFireAndForget = true;
        Info.bUseSuccessFailIcons = true;
        Info.FadeOutDuration = 1.0f;
        TSharedPtr<SNotificationItem> NotificationItem = FSlateNotificationManager::Get().AddNotification(Info);
        NotificationItem->SetCompletionState(SNotificationItem::CS_Fail);

        // Notify that the build has completed
        BuildCompletedEvent.Broadcast(false);
    }
}