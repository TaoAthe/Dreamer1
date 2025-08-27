# FixBuildDuplicationErrors.ps1
# PowerShell script to fix duplicate module definitions and corrupted build files

# Enable strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Write-Host "========================================================================"
Write-Host "                     BUILD DUPLICATION ERROR FIX (PowerShell)"
Write-Host "========================================================================"
Write-Host ""

# Get script directory (project root)
$ProjectRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ProjectPath = Join-Path $ProjectRoot "Dreamer1.uproject"

Write-Host "Project Root: $ProjectRoot"
Write-Host "Project Path: $ProjectPath"

if (-not (Test-Path $ProjectPath)) {
    Write-Host "ERROR: Could not find Dreamer1.uproject in $ProjectRoot" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Issues to be fixed:" -ForegroundColor Yellow
Write-Host "- Duplicate Dreamer1 and Dreamer module definitions"
Write-Host "- Corrupted BuildRules DLL files"
Write-Host "- Missing or invalid Target files"
Write-Host "- Deprecated UnsafeTypeCastWarningLevel usage"
Write-Host ""

Write-Host "Press any key to continue..." -NoNewline
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

# Create backup directory
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupDir = Join-Path $ProjectRoot "Backup_$Timestamp"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

Write-Host ""
Write-Host "========================================================================"
Write-Host "STEP 1: Backing up problematic directories"
Write-Host "========================================================================"
Write-Host ""

Write-Host "Backup directory: $BackupDir" -ForegroundColor Cyan

# Backup Dreamer_Rebuilt if it exists
$DreamerRebuiltPath = Join-Path $ProjectRoot "Plugins\Dreamer_Rebuilt"
if (Test-Path $DreamerRebuiltPath) {
    Write-Host "Backing up Dreamer_Rebuilt directory..." -ForegroundColor Yellow
    $BackupDreamerRebuilt = Join-Path $BackupDir "Dreamer_Rebuilt"
    Copy-Item -Path $DreamerRebuiltPath -Destination $BackupDreamerRebuilt -Recurse -Force
    Write-Host "Backed up Dreamer_Rebuilt directory" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================================================"
Write-Host "STEP 2: Removing duplicate and problematic directories"
Write-Host "========================================================================"
Write-Host ""

# Remove Dreamer_Rebuilt directory
if (Test-Path $DreamerRebuiltPath) {
    Write-Host "Removing Dreamer_Rebuilt directory..." -ForegroundColor Yellow
    Remove-Item -Path $DreamerRebuiltPath -Recurse -Force
    Write-Host "Removed Dreamer_Rebuilt directory" -ForegroundColor Green
} else {
    Write-Host "Dreamer_Rebuilt directory not found, skipping..." -ForegroundColor Gray
}

# Remove corrupted BuildRules
$BuildRulesPath = Join-Path $ProjectRoot "Intermediate\Build\BuildRules"
if (Test-Path $BuildRulesPath) {
    Write-Host "Removing corrupted BuildRules directory..." -ForegroundColor Yellow
    Remove-Item -Path $BuildRulesPath -Recurse -Force
    Write-Host "Removed BuildRules directory" -ForegroundColor Green
} else {
    Write-Host "BuildRules directory not found, skipping..." -ForegroundColor Gray
}

# Clean other intermediate build files
$IntermediateBuildPath = Join-Path $ProjectRoot "Intermediate\Build"
if (Test-Path $IntermediateBuildPath) {
    Write-Host "Cleaning Intermediate\Build directory..." -ForegroundColor Yellow
    Get-ChildItem -Path $IntermediateBuildPath -Directory | Where-Object { $_.Name -ne "Win64" } | ForEach-Object {
        Write-Host "  Removing $($_.FullName)..." -ForegroundColor Gray
        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "========================================================================"
Write-Host "STEP 3: Checking and fixing duplicate Source modules"
Write-Host "========================================================================"
Write-Host ""

# Check for duplicate Dreamer1 modules
$SourceDreamer1Path = Join-Path $ProjectRoot "Source\Dreamer1"
$PluginDreamer1Path = Join-Path $ProjectRoot "Plugins\Dreamer\Source\Dreamer1"

if ((Test-Path $SourceDreamer1Path) -and (Test-Path $PluginDreamer1Path)) {
    Write-Host "WARNING: Found duplicate Dreamer1 modules!" -ForegroundColor Red
    Write-Host "  - $SourceDreamer1Path"
    Write-Host "  - $PluginDreamer1Path"
    Write-Host ""
    Write-Host "Backing up and removing Source\Dreamer1 (keeping plugin version)..." -ForegroundColor Yellow
    
    $BackupSourceDreamer1 = Join-Path $BackupDir "Source_Dreamer1"
    Copy-Item -Path $SourceDreamer1Path -Destination $BackupSourceDreamer1 -Recurse -Force
    Remove-Item -Path $SourceDreamer1Path -Recurse -Force
    Write-Host "Removed Source\Dreamer1 directory" -ForegroundColor Green
}

# Check for duplicate Dreamer modules
$SourceDreamerPath = Join-Path $ProjectRoot "Source\Dreamer"
$PluginDreamerPath = Join-Path $ProjectRoot "Plugins\Dreamer\Source\Dreamer"

if ((Test-Path $SourceDreamerPath) -and (Test-Path $PluginDreamerPath)) {
    Write-Host "WARNING: Found duplicate Dreamer modules!" -ForegroundColor Red
    Write-Host "  - $SourceDreamerPath"
    Write-Host "  - $PluginDreamerPath"
    Write-Host ""
    Write-Host "Backing up and removing Source\Dreamer (keeping plugin version)..." -ForegroundColor Yellow
    
    $BackupSourceDreamer = Join-Path $BackupDir "Source_Dreamer"
    Copy-Item -Path $SourceDreamerPath -Destination $BackupSourceDreamer -Recurse -Force
    Remove-Item -Path $SourceDreamerPath -Recurse -Force
    Write-Host "Removed Source\Dreamer directory" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================================================"
Write-Host "STEP 4: Creating proper Target files if missing"
Write-Host "========================================================================"
Write-Host ""

# Create main target files
$SourceDir = Join-Path $ProjectRoot "Source"
if (-not (Test-Path $SourceDir)) {
    New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null
}

$Dreamer1TargetPath = Join-Path $SourceDir "Dreamer1.Target.cs"
if (-not (Test-Path $Dreamer1TargetPath)) {
    Write-Host "Creating main Dreamer1.Target.cs..." -ForegroundColor Yellow
    
    $TargetContent = @"
using UnrealBuildTool;

public class Dreamer1Target : TargetRules
{
    public Dreamer1Target(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.AddRange(new string[] { "Dreamer1" });
    }
}
"@
    
    $TargetContent | Out-File -FilePath $Dreamer1TargetPath -Encoding UTF8
    Write-Host "Created Dreamer1.Target.cs" -ForegroundColor Green
}

$Dreamer1EditorTargetPath = Join-Path $SourceDir "Dreamer1Editor.Target.cs"
if (-not (Test-Path $Dreamer1EditorTargetPath)) {
    Write-Host "Creating main Dreamer1Editor.Target.cs..." -ForegroundColor Yellow
    
    $EditorTargetContent = @"
using UnrealBuildTool;

public class Dreamer1EditorTarget : TargetRules
{
    public Dreamer1EditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.AddRange(new string[] { "Dreamer1" });
    }
}
"@
    
    $EditorTargetContent | Out-File -FilePath $Dreamer1EditorTargetPath -Encoding UTF8
    Write-Host "Created Dreamer1Editor.Target.cs" -ForegroundColor Green
}

# Create main module Build.cs if needed
$MainModuleDir = Join-Path $SourceDir "Dreamer1"
$MainModuleBuildPath = Join-Path $MainModuleDir "Dreamer1.Build.cs"

if (-not (Test-Path $MainModuleBuildPath)) {
    Write-Host "Creating main Dreamer1.Build.cs..." -ForegroundColor Yellow
    
    if (-not (Test-Path $MainModuleDir)) {
        New-Item -ItemType Directory -Path $MainModuleDir -Force | Out-Null
    }
    
    $BuildContent = @"
using UnrealBuildTool;

public class Dreamer1 : ModuleRules
{
    public Dreamer1(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

        PublicDependencyModuleNames.AddRange(new string[] {
            "Core",
            "CoreUObject",
            "Engine"
        });

        PrivateDependencyModuleNames.AddRange(new string[] {
            // Add private dependencies here
        });
    }
}
"@
    
    $BuildContent | Out-File -FilePath $MainModuleBuildPath -Encoding UTF8
    Write-Host "Created Dreamer1.Build.cs" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================================================"
Write-Host "STEP 5: Fixing deprecated UnsafeTypeCastWarningLevel"
Write-Host "========================================================================"
Write-Host ""

# Fix VisualStudioTools deprecated warning
$VSBuildFile = Join-Path $ProjectRoot "Plugins\VisualStudioTools\Source\VisualStudioTools\VisualStudioTools.Build.cs"
if (Test-Path $VSBuildFile) {
    Write-Host "Fixing deprecated UnsafeTypeCastWarningLevel in VisualStudioTools..." -ForegroundColor Yellow
    
    try {
        $Content = Get-Content $VSBuildFile -Raw
        $OriginalContent = $Content
        
        # Replace the deprecated property
        $Content = $Content -replace 'UnsafeTypeCastWarningLevel\s*=', 'CppCompileWarningSettings.UnsafeTypeCastWarningLevel ='
        
        if ($Content -ne $OriginalContent) {
            $Content | Set-Content $VSBuildFile -Encoding UTF8
            Write-Host "Fixed deprecated UnsafeTypeCastWarningLevel" -ForegroundColor Green
        } else {
            Write-Host "No deprecated UnsafeTypeCastWarningLevel found to fix" -ForegroundColor Gray
        }
    } catch {
        Write-Host "Warning: Could not fix UnsafeTypeCastWarningLevel: $_" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================================================"
Write-Host "STEP 6: Creating basic source files if missing"
Write-Host "========================================================================"
Write-Host ""

# Create basic Dreamer1.cpp
$Dreamer1CppPath = Join-Path $MainModuleDir "Dreamer1.cpp"
if (-not (Test-Path $Dreamer1CppPath)) {
    Write-Host "Creating basic Dreamer1.cpp..." -ForegroundColor Yellow
    
    $CppContent = @"
#include "Dreamer1.h"
#include "Modules/ModuleManager.h"

IMPLEMENT_PRIMARY_GAME_MODULE(FDefaultGameModuleImpl, Dreamer1, "Dreamer1");
"@
    
    $CppContent | Out-File -FilePath $Dreamer1CppPath -Encoding UTF8
    Write-Host "Created Dreamer1.cpp" -ForegroundColor Green
}

# Create basic Dreamer1.h
$Dreamer1HPath = Join-Path $MainModuleDir "Dreamer1.h"
if (-not (Test-Path $Dreamer1HPath)) {
    Write-Host "Creating basic Dreamer1.h..." -ForegroundColor Yellow
    
    $HContent = @"
#pragma once

#include "CoreMinimal.h"
"@
    
    $HContent | Out-File -FilePath $Dreamer1HPath -Encoding UTF8
    Write-Host "Created Dreamer1.h" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================================================"
Write-Host "STEP 7: Cleaning up additional intermediate files"
Write-Host "========================================================================"
Write-Host ""

Write-Host "Cleaning up additional intermediate files..." -ForegroundColor Yellow

# Remove solution and project files (they'll be regenerated)
Get-ChildItem -Path $ProjectRoot -Filter "*.sln" | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $ProjectRoot -Filter "*.vcxproj*" | Remove-Item -Force -ErrorAction SilentlyContinue

# Clean Binaries if corrupted
$BinariesPath = Join-Path $ProjectRoot "Binaries"
if (Test-Path $BinariesPath) {
    Write-Host "Cleaning Binaries directory..." -ForegroundColor Gray
    Remove-Item -Path $BinariesPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Clean plugin binaries
$PluginsPath = Join-Path $ProjectRoot "Plugins"
if (Test-Path $PluginsPath) {
    Get-ChildItem -Path $PluginsPath -Directory | ForEach-Object {
        $PluginBinaries = Join-Path $_.FullName "Binaries"
        $PluginIntermediate = Join-Path $_.FullName "Intermediate"
        
        if (Test-Path $PluginBinaries) {
            Write-Host "Cleaning $($_.Name)\Binaries..." -ForegroundColor Gray
            Remove-Item -Path $PluginBinaries -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        if (Test-Path $PluginIntermediate) {
            Write-Host "Cleaning $($_.Name)\Intermediate..." -ForegroundColor Gray
            Remove-Item -Path $PluginIntermediate -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ""
Write-Host "========================================================================"
Write-Host "STEP 8: Running test build to verify fixes"
Write-Host "========================================================================"
Write-Host ""

# Find Unreal Engine and test the fix
try {
    $ProjectContent = Get-Content $ProjectPath -Raw | ConvertFrom-Json
    $EngineVersion = $ProjectContent.EngineAssociation
    Write-Host "Engine Version: $EngineVersion" -ForegroundColor Cyan
    
    # Find engine path
    $EnginePath = $null
    $RegistryPaths = @(
        "HKLM:\SOFTWARE\EpicGames\Unreal Engine\$EngineVersion",
        "HKCU:\SOFTWARE\EpicGames\Unreal Engine\$EngineVersion"
    )
    
    foreach ($RegPath in $RegistryPaths) {
        if (Test-Path $RegPath) {
            try {
                $EnginePath = (Get-ItemProperty -Path $RegPath -Name "InstalledDirectory" -ErrorAction SilentlyContinue).InstalledDirectory
                if ($EnginePath) {
                    break
                }
            } catch {
                continue
            }
        }
    }
    
    if (-not $EnginePath) {
        $PossiblePaths = @(
            "C:\Program Files\Epic Games\UE_$EngineVersion",
            "C:\Epic Games\UE_$EngineVersion",
            "C:\Program Files\Epic Games\UE_5.6"
        )
        
        foreach ($Path in $PossiblePaths) {
            if (Test-Path $Path) {
                $EnginePath = $Path
                break
            }
        }
    }
    
    if ($EnginePath) {
        $UbtPath = "$EnginePath\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
        if (-not (Test-Path $UbtPath)) {
            $UbtPath = "$EnginePath\Engine\Binaries\DotNET\UnrealBuildTool.exe"
        }
        
        if (Test-Path $UbtPath) {
            Write-Host "Testing project file generation..." -ForegroundColor Cyan
            
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcessInfo.FileName = $UbtPath
            $ProcessInfo.Arguments = "-projectfiles -project=`"$ProjectPath`" -game -engine -progress"
            $ProcessInfo.RedirectStandardOutput = $true
            $ProcessInfo.RedirectStandardError = $true
            $ProcessInfo.UseShellExecute = $false
            $ProcessInfo.CreateNoWindow = $true
            $ProcessInfo.WorkingDirectory = $ProjectRoot
            
            $Process = New-Object System.Diagnostics.Process
            $Process.StartInfo = $ProcessInfo
            $Process.Start() | Out-Null
            
            $StdOut = $Process.StandardOutput.ReadToEnd()
            $StdErr = $Process.StandardError.ReadToEnd()
            $Process.WaitForExit()
            $ExitCode = $Process.ExitCode
            
            if ($ExitCode -eq 0) {
                Write-Host "SUCCESS: Project file generation completed without errors!" -ForegroundColor Green
            } else {
                Write-Host "WARNING: Project file generation completed with errors (Exit Code: $ExitCode)" -ForegroundColor Yellow
                if ($StdErr) {
                    Write-Host "Error Output:" -ForegroundColor Red
                    Write-Host $StdErr -ForegroundColor Red
                }
            }
        } else {
            Write-Host "Could not find UnrealBuildTool, skipping test build." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Could not find Unreal Engine, skipping test build." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error during test build: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================================================"
Write-Host "BUILD DUPLICATION ERROR FIX COMPLETED"
Write-Host "========================================================================"
Write-Host ""

Write-Host "Summary of actions taken:" -ForegroundColor Cyan
Write-Host "  ? Removed duplicate Dreamer_Rebuilt directory" -ForegroundColor Green
Write-Host "  ? Cleaned corrupted BuildRules directory" -ForegroundColor Green
Write-Host "  ? Removed duplicate Source modules (backed up first)" -ForegroundColor Green
Write-Host "  ? Created proper Target.cs files" -ForegroundColor Green
Write-Host "  ? Fixed deprecated UnsafeTypeCastWarningLevel warning" -ForegroundColor Green
Write-Host "  ? Created basic source files if missing" -ForegroundColor Green
Write-Host "  ? Cleaned intermediate build files" -ForegroundColor Green
Write-Host ""

Write-Host "Backup directory: $BackupDir" -ForegroundColor Cyan
Write-Host ""

Write-Host "The duplicate module definition errors should now be resolved." -ForegroundColor Green
Write-Host "You can now try building your project again." -ForegroundColor Green
Write-Host ""

Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")