// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"

/** Represents the severity of a build message */
enum class EBuildMessageSeverity : uint8
{
    Info,
    Warning,
    Error
};

/** Represents a build error or warning */
class FBuildError
{
public:
    /** Constructor */
    FBuildError(const FString& InMessage, const FString& InFilePath, int32 InLineNumber, int32 InColumnNumber, EBuildMessageSeverity InSeverity)
        : Message(InMessage)
        , FilePath(InFilePath)
        , LineNumber(InLineNumber)
        , ColumnNumber(InColumnNumber)
        , Severity(InSeverity)
    {
    }

    /** Gets the error message */
    const FString& GetMessage() const { return Message; }

    /** Gets the file path */
    const FString& GetFilePath() const { return FilePath; }

    /** Gets the line number */
    int32 GetLineNumber() const { return LineNumber; }

    /** Gets the column number */
    int32 GetColumnNumber() const { return ColumnNumber; }

    /** Gets the severity */
    EBuildMessageSeverity GetSeverity() const { return Severity; }

private:
    /** The error message */
    FString Message;

    /** The file path */
    FString FilePath;

    /** The line number */
    int32 LineNumber;

    /** The column number */
    int32 ColumnNumber;

    /** The severity */
    EBuildMessageSeverity Severity;
};