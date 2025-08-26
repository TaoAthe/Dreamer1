// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "HAL/Runnable.h"
#include "HAL/RunnableThread.h"
#include "HAL/PlatformProcess.h"

class FBuildManager;

/**
 * A runnable thread to read output from a process
 */
class FOutputReaderRunnable : public FRunnable
{
public:
    /**
     * Constructor
     *
     * @param InBuildManager The build manager to notify with output
     * @param InReadPipe The read end of a pipe
     * @param InWritePipe The write end of a pipe
     * @param InProcessHandle The process handle to monitor
     */
    FOutputReaderRunnable(FBuildManager* InBuildManager, void* InReadPipe, void* InWritePipe, FProcHandle InProcessHandle)
        : BuildManager(InBuildManager)
        , ReadPipe(InReadPipe)
        , WritePipe(InWritePipe)
        , ProcessHandle(InProcessHandle)
        , bShouldStop(false)
    {
    }

    /** Begin FRunnable interface */
    virtual bool Init() override
    {
        return true;
    }

    virtual uint32 Run() override
    {
        // Keep reading until told to stop
        while (!bShouldStop)
        {
            // Check if the process is still running
            if (!FPlatformProcess::IsProcRunning(ProcessHandle))
            {
                // Process has exited, read any remaining output and exit
                ReadOutput();
                break;
            }

            // Read output
            ReadOutput();

            // Sleep for a short time
            FPlatformProcess::Sleep(0.1f);
        }

        // Close pipes
        FPlatformProcess::ClosePipe(ReadPipe, WritePipe);
        ReadPipe = WritePipe = nullptr;

        return 0;
    }

    virtual void Stop() override
    {
        bShouldStop = true;
    }

    virtual void Exit() override
    {
        // Nothing to do
    }
    /** End FRunnable interface */

private:
    /** Reads output from the pipe */
    void ReadOutput()
    {
        // Read from pipe
        FString Output;
        while (FPlatformProcess::ReadPipeToString(ReadPipe, Output))
        {
            if (!Output.IsEmpty())
            {
                // Notify the build manager of the output
                BuildManager->HandleUATOutput(Output);
            }
        }
    }

    /** The build manager to notify */
    FBuildManager* BuildManager;

    /** Read pipe handle */
    void* ReadPipe;

    /** Write pipe handle */
    void* WritePipe;

    /** Process handle */
    FProcHandle ProcessHandle;

    /** Should the thread stop? */
    volatile bool bShouldStop;
};