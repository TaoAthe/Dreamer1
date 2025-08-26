// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Styling/SlateStyle.h"
#include "BuildError.h"

class FBuildManager : public TSharedFromThis<FBuildManager>
{
public:
    /** Constructor */
    FBuildManager();

    /** Destructor */
    ~FBuildManager();

    /** Initializes the build manager */
    void Initialize();

    /** Shuts down the build manager */
    void Shutdown();

    /** Builds the current project */
    void BuildProject(const FString& Configuration = TEXT("Development"), const FString& Target = TEXT("Editor"));

    /** Cancels the current build */
    void CancelBuild();

    /** Returns true if a build is currently in progress */
    bool IsBuildInProgress() const;

    /** Returns the current build progress (0.0 - 1.0) */
    float GetBuildProgress() const;

    /** Returns the list of build errors */
    const TArray<TSharedPtr<FBuildError>>& GetBuildErrors() const;

    /** Returns the list of build warnings */
    const TArray<TSharedPtr<FBuildError>>& GetBuildWarnings() const;

    /** Clears the build errors and warnings */
    void ClearBuildMessages();

    /** Delegate called when build starts */
    DECLARE_EVENT(FBuildManager, FBuildStartedEvent);
    FBuildStartedEvent& OnBuildStarted() { return BuildStartedEvent; }

    /** Delegate called when build completes */
    DECLARE_EVENT_OneParam(FBuildManager, FBuildCompletedEvent, bool /* bSuccess */);
    FBuildCompletedEvent& OnBuildCompleted() { return BuildCompletedEvent; }

    /** Delegate called when build progress changes */
    DECLARE_EVENT_OneParam(FBuildManager, FBuildProgressEvent, float /* Progress */);
    FBuildProgressEvent& OnBuildProgressChanged() { return BuildProgressEvent; }

    /** Delegate called when build errors change */
    DECLARE_EVENT(FBuildManager, FBuildErrorsChangedEvent);
    FBuildErrorsChangedEvent& OnBuildErrorsChanged() { return BuildErrorsChangedEvent; }

private:
    /** Parses build output for errors and warnings */
    void ParseBuildOutput(const FString& Output);

    /** Handles UAT process output */
    void HandleUATOutput(FString Output);

    /** Event fired when build starts */
    FBuildStartedEvent BuildStartedEvent;

    /** Event fired when build completes */
    FBuildCompletedEvent BuildCompletedEvent;

    /** Event fired when build progress changes */
    FBuildProgressEvent BuildProgressEvent;

    /** Event fired when build errors change */
    FBuildErrorsChangedEvent BuildErrorsChangedEvent;

    /** Current build errors */
    TArray<TSharedPtr<FBuildError>> BuildErrors;

    /** Current build warnings */
    TArray<TSharedPtr<FBuildError>> BuildWarnings;

    /** Current build progress */
    float BuildProgress;

    /** Is a build currently in progress */
    bool bBuildInProgress;

    /** Handle to the UAT process */
    FProcHandle UATProcessHandle;

    /** UAT process cancellation requested */
    bool bCancellationRequested;
};