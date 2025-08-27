# FixUnrealBuildTool.ps1
# This script addresses the "could not fetch all the available targets from the unreal build tool" error
# by properly setting up the environment and ensuring all dependencies are available.

# Enable strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "                     UNREAL BUILD TOOL FIX SCRIPT                      " -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Get the current directory and assume it's the project root
$ProjectRoot = Get-Location
$ProjectPath = "$ProjectRoot\Dreamer1.uproject"

# Validate that the .uproject file exists
if (-not (Test-Path $ProjectPath)) {
    Write-Host "ERROR: Could not find Dreamer1.uproject in $ProjectRoot" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory." -ForegroundColor Red
    exit 1
}

# Locate the Unreal Engine installation
Write-Host "Locating Unreal Engine installation..." -ForegroundColor Yellow
$EnginePath = $null

# Try to find the engine path from the .uproject file
try {
    $ProjectContent = Get-Content $ProjectPath -Raw | ConvertFrom-Json
    $EngineAssociation = $ProjectContent.EngineAssociation
    
    Write-Host "Project uses engine association: $EngineAssociation" -ForegroundColor Green
    
    # Try to find the engine path from the registry
    $RegistryPath = "HKLM:\SOFTWARE\EpicGames\Unreal Engine\$EngineAssociation"
    if (Test-Path $RegistryPath) {
        $EnginePath = (Get-ItemProperty -Path $RegistryPath -Name "InstalledDirectory").InstalledDirectory
        Write-Host "Found engine path from registry: $EnginePath" -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Could not parse .uproject file or find engine in registry: $_" -ForegroundColor Yellow
}

# If we still don't have an engine path, try common locations
if (-not $EnginePath -or -not (Test-Path $EnginePath)) {
    $PossiblePaths = @(
        "C:\Program Files\Epic Games\UE_$EngineAssociation",
        "C:\Program Files\Epic Games\UE_5.6",
        "C:\Program Files\Epic Games\UE_5.5",
        "C:\Program Files\Epic Games\UE_5.4",
        "C:\Program Files\Epic Games\UE_5.3",
        "C:\Program Files\Epic Games\UE_5.2",
        "C:\Program Files\Epic Games\UE_5.1",
        "C:\Program Files\Epic Games\UE_5.0"
    )
    
    foreach ($Path in $PossiblePaths) {
        if (Test-Path $Path) {
            $EnginePath = $Path
            Write-Host "Found engine at: $EnginePath" -ForegroundColor Green
            break
        }
    }
}

if (-not $EnginePath -or -not (Test-Path $EnginePath)) {
    Write-Host "ERROR: Could not locate Unreal Engine installation." -ForegroundColor Red
    Write-Host "Please specify the engine path manually:" -ForegroundColor Yellow
    $EnginePath = Read-Host "Engine path"
    
    if (-not (Test-Path $EnginePath)) {
        Write-Host "ERROR: Specified engine path does not exist." -ForegroundColor Red
        exit 1
    }
}

# Create a log file
$LogFile = "$ProjectRoot\UnrealBuildFix.log"
"Build fix started at $(Get-Date)" | Out-File $LogFile

# Function to log messages both to console and log file
function Log-Message {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    
    Write-Host $Message -ForegroundColor $Color
    $Message | Out-File $LogFile -Append
}

# Function to ensure all required .NET assemblies are loaded
function Ensure-RequiredAssemblies {
    Log-Message "Ensuring required .NET assemblies are loaded..." "Yellow"
    
    # These are assemblies that UBT might need
    $requiredAssemblies = @(
        "System.CodeDom",
        "System.Collections",
        "System.IO.Compression",
        "System.IO.Compression.FileSystem",
        "System.Xml",
        "System.Xml.Linq"
    )
    
    foreach ($assembly in $requiredAssemblies) {
        try {
            if (-not ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq $assembly })) {
                Log-Message "Loading $assembly assembly..." "Yellow"
                [System.Reflection.Assembly]::Load($assembly) | Out-Null
            }
        } catch {
            Log-Message "Warning: Could not load $assembly: $_" "Yellow"
        }
    }
}

# Function to ensure proper dotnet version is available
function Ensure-DotNetVersion {
    Log-Message "Checking .NET version..." "Yellow"
    
    try {
        $dotnetOutput = & dotnet --version
        Log-Message "Found .NET version: $dotnetOutput" "Green"
    } catch {
        Log-Message "WARNING: dotnet command not found or failed. This might cause issues with Unreal Build Tool." "Yellow"
        Log-Message "Error details: $_" "Yellow"
    }
}

# Function to fix common permission issues
function Fix-Permissions {
    Log-Message "Checking and fixing permissions..." "Yellow"
    
    # Try to ensure we have sufficient permissions to write to Binaries and Intermediate folders
    $foldersToCheck = @(
        "$ProjectRoot\Binaries",
        "$ProjectRoot\Intermediate",
        "$ProjectRoot\Plugins\*\Binaries",
        "$ProjectRoot\Plugins\*\Intermediate"
    )
    
    foreach ($folderPattern in $foldersToCheck) {
        try {
            Get-Item -Path $folderPattern -ErrorAction SilentlyContinue | ForEach-Object {
                Log-Message "Setting full permissions on $_" "Yellow"
                & icacls $_.FullName /grant:r "$($env:USERNAME):(OI)(CI)F" /Q
            }
        } catch {
            Log-Message "Warning: Could not set permissions on $folderPattern" "Yellow"
        }
    }
}

# Function to clean up problematic files that might interfere with the build
function Clean-ProblemFiles {
    Log-Message "Cleaning up potentially problematic files..." "Yellow"
    
    # Remove any .binaries.txt files that might be corrupted
    Get-ChildItem -Path "$ProjectRoot" -Filter "*.binaries.txt" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        Log-Message "Removing potentially corrupted file: $($_.FullName)" "Yellow"
        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
    }
    
    # Remove any empty folders in Intermediate and Binaries
    $emptyFolders = Get-ChildItem -Path "$ProjectRoot\Intermediate", "$ProjectRoot\Binaries" -Directory -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue).Count -eq 0 }
        
    foreach ($folder in $emptyFolders) {
        Log-Message "Removing empty folder: $($folder.FullName)" "Yellow"
        Remove-Item $folder.FullName -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# Function to create an environment batch file to properly set up environment variables
function Create-EnvironmentBatchFile {
    Log-Message "Creating environment setup batch file..." "Yellow"
    
    $batchFile = "$ProjectRoot\SetupBuildEnv.bat"
    
    @"
@echo off
REM This file is automatically generated to set up the correct environment for UBT
REM It should be called before running UBT commands

set UE_ENGINE_DIRECTORY=$($EnginePath.Replace('\', '\\'))
set UE_PROJECT_DIRECTORY=$($ProjectRoot.Replace('\', '\\'))
set UE_PROJECT_FILE=%UE_PROJECT_DIRECTORY%\Dreamer1.uproject
set UE_PROJECT_NAME=Dreamer1
set UE_PROJECT_PLATFORM=Win64
set UE_PROJECT_CONFIGURATION=Development
set DOTNET_CLI_TELEMETRY_OPTOUT=1
set DOTNET_NOLOGO=1
set DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
set DOTNET_ROOT=$($EnginePath.Replace('\', '\\'))\Engine\Binaries\ThirdParty\DotNet\Win64
set PATH=%DOTNET_ROOT%;%PATH%

echo Environment variables set for Unreal Build Tool
"@ | Out-File -FilePath $batchFile -Encoding ascii
    
    Log-Message "Created environment batch file: $batchFile" "Green"
    return $batchFile
}

# Function to try to fetch the targets with proper environment setup
function Fetch-Targets {
    param (
        [string]$EnvBatchFile
    )
    
    Log-Message "Attempting to fetch targets with proper environment setup..." "Cyan"
    
    # Create a temporary batch file to run the command
    $tempBatchFile = "$ProjectRoot\FetchTargets.bat"
    
    @"
@echo off
call "$EnvBatchFile"
"$EnginePath\Engine\Build\BatchFiles\Build.bat" -Mode=QueryTargets -Project="$ProjectPath" -TargetPlatform=Win64 -BuildConfiguration=Development > "$ProjectRoot\AvailableTargets.txt"
"@ | Out-File -FilePath $tempBatchFile -Encoding ascii
    
    # Run the batch file
    Log-Message "Running fetch targets batch file..." "Yellow"
    & cmd.exe /c $tempBatchFile
    
    # Check if we got results
    if (Test-Path "$ProjectRoot\AvailableTargets.txt") {
        $targets = Get-Content "$ProjectRoot\AvailableTargets.txt" -Raw
        Log-Message "Available targets:" "Green"
        Log-Message $targets "White"
        
        if ($targets -match "error|exception|failed") {
            Log-Message "WARNING: Errors detected in target fetch output" "Yellow"
        } else {
            Log-Message "Successfully fetched targets!" "Green"
        }
    } else {
        Log-Message "ERROR: Failed to fetch targets" "Red"
    }
    
    # Clean up
    Remove-Item $tempBatchFile -Force -ErrorAction SilentlyContinue
}

# Function to try rebuilding modules
function Rebuild-Modules {
    param (
        [string]$EnvBatchFile
    )
    
    Log-Message "Attempting to rebuild modules..." "Cyan"
    
    # Check for the Build.bat script
    $buildBat = "$EnginePath\Engine\Build\BatchFiles\Build.bat"
    if (-not (Test-Path $buildBat)) {
        Log-Message "ERROR: Could not find Build.bat at $buildBat" "Red"
        return
    }
    
    # Create a temporary batch file to rebuild modules
    $tempBatchFile = "$ProjectRoot\RebuildModules_Fix.bat"
    
    @"
@echo off
call "$EnvBatchFile"

REM Build editor target
echo Building Dreamer1Editor...
"$buildBat" Dreamer1Editor Win64 Development -Project="$ProjectPath" -WaitMutex

REM Build game target
echo Building Dreamer1...
"$buildBat" Dreamer1 Win64 Development -Project="$ProjectPath" -WaitMutex

REM Rebuild plugins
echo Building plugins...
"@ | Out-File -FilePath $tempBatchFile -Encoding ascii

    # Add plugin build commands if plugins exist
    $inEditorPluginPath = "$ProjectRoot\Plugins\InEditorCpp\InEditorCpp.uplugin"
    $imGuiPluginPath = "$ProjectRoot\Plugins\UnrealImGui-IMGUI_1.74\ImGui.uplugin"
    
    if (Test-Path $inEditorPluginPath) {
        @"
echo Building InEditorCpp plugin...
"$buildBat" InEditorCpp Win64 Development -Plugin="$inEditorPluginPath" -TargetType=Editor
"@ | Out-File -FilePath $tempBatchFile -Append -Encoding ascii
    }
    
    if (Test-Path $imGuiPluginPath) {
        @"
echo Building ImGui plugin...
"$buildBat" ImGui Win64 Development -Plugin="$imGuiPluginPath" -TargetType=Editor
"@ | Out-File -FilePath $tempBatchFile -Append -Encoding ascii
    }
    
    # Run the batch file
    Log-Message "Running module rebuild batch file..." "Yellow"
    & cmd.exe /c $tempBatchFile
    
    # Clean up
    # We'll keep this file for reference
    Log-Message "Module rebuild completed. The batch file is saved at $tempBatchFile for future use." "Green"
}

# Main execution sequence
Log-Message "Starting build fix process..." "Cyan"
Log-Message "Project path: $ProjectPath" "White"
Log-Message "Engine path: $EnginePath" "White"

# Step 1: Ensure required .NET assemblies are loaded
Ensure-RequiredAssemblies

# Step 2: Check .NET version
Ensure-DotNetVersion

# Step 3: Fix permissions
Fix-Permissions

# Step 4: Clean up problematic files
Clean-ProblemFiles

# Step 5: Create environment batch file
$envBatchFile = Create-EnvironmentBatchFile

# Step 6: Try to fetch targets
Fetch-Targets -EnvBatchFile $envBatchFile

# Step 7: Rebuild modules
Rebuild-Modules -EnvBatchFile $envBatchFile

# Completion
Log-Message "========================================================================" "Cyan"
Log-Message "                   BUILD FIX PROCESS COMPLETED                         " "Cyan"
Log-Message "========================================================================" "Cyan"
Log-Message "" "White"
Log-Message "If the target fetch was successful, the 'could not fetch all the available targets'" "White"
Log-Message "error should now be resolved. You can now try opening your project in Unreal Editor." "White"
Log-Message "" "White"
Log-Message "If you still encounter issues, please check the log file at:" "Yellow"
Log-Message "$LogFile" "Yellow"
Log-Message "" "White"
Log-Message "You can also try running the RebuildModules_Fix.bat script that was created." "White"
Log-Message "" "White"
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")