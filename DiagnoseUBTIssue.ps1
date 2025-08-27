# DiagnoseUBTIssue.ps1
# This script specifically diagnoses the "could not fetch all available targets" UBT error
# by examining the environment and creating detailed diagnostics

# Enable strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "               UNREAL BUILD TOOL DIAGNOSTIC SCRIPT                     " -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Create a timestamp for log files
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir = "$PSScriptRoot\UBT_Diagnostics_$timestamp"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

# Function to write to log and console
function Write-Log {
    param (
        [string]$Message,
        [string]$LogFile,
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append
    Write-Host $Message -ForegroundColor $Color
}

# Main diagnostic log
$mainLog = "$logDir\main_diagnostic.log"
"UBT Diagnostic started at $(Get-Date)" | Out-File -FilePath $mainLog

# Get the project path
$projectPath = "$PSScriptRoot\Dreamer1.uproject"
if (-not (Test-Path $projectPath)) {
    Write-Log "ERROR: Could not find Dreamer1.uproject" $mainLog "Red"
    exit 1
}

# Read the engine association from the project file
$engineAssociation = "Unknown"
try {
    $projectContent = Get-Content $projectPath -Raw | ConvertFrom-Json
    $engineAssociation = $projectContent.EngineAssociation
    Write-Log "Engine association: $engineAssociation" $mainLog "Green"
} catch {
    Write-Log "ERROR: Failed to read engine association from project file: $_" $mainLog "Red"
}

# Find the engine path
$enginePath = $null
$registryPaths = @(
    "HKLM:\SOFTWARE\EpicGames\Unreal Engine\$engineAssociation",
    "HKCU:\SOFTWARE\EpicGames\Unreal Engine\$engineAssociation"
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        try {
            $enginePath = (Get-ItemProperty -Path $regPath -Name "InstalledDirectory" -ErrorAction SilentlyContinue).InstalledDirectory
            if ($enginePath) {
                Write-Log "Found engine path in registry: $enginePath" $mainLog "Green"
                break
            }
        } catch {
            Write-Log "Warning: Could not read registry key $regPath: $_" $mainLog "Yellow"
        }
    }
}

# If we couldn't find it in the registry, check common locations
if (-not $enginePath -or -not (Test-Path $enginePath)) {
    $possiblePaths = @(
        "C:\Program Files\Epic Games\UE_$engineAssociation",
        "C:\Epic Games\UE_$engineAssociation",
        "C:\Program Files\Epic Games\UE_5.6",
        "C:\Program Files\Epic Games\UE_5.5",
        "C:\Program Files\Epic Games\UE_5.4"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $enginePath = $path
            Write-Log "Found engine at common location: $enginePath" $mainLog "Green"
            break
        }
    }
}

if (-not $enginePath -or -not (Test-Path $enginePath)) {
    Write-Log "ERROR: Could not locate Unreal Engine installation" $mainLog "Red"
    exit 1
}

# Check for UnrealBuildTool executable
$ubtPath = "$enginePath\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
if (-not (Test-Path $ubtPath)) {
    Write-Log "ERROR: UnrealBuildTool.exe not found at expected path: $ubtPath" $mainLog "Red"
    
    # Check if it might be in a different location based on UE version
    $alternativePaths = @(
        "$enginePath\Engine\Binaries\DotNET\UnrealBuildTool.exe",
        "$enginePath\Engine\Source\Programs\UnrealBuildTool\bin\Release\UnrealBuildTool.exe"
    )
    
    $found = $false
    foreach ($altPath in $alternativePaths) {
        if (Test-Path $altPath) {
            $ubtPath = $altPath
            $found = $true
            Write-Log "Found UnrealBuildTool at alternative location: $ubtPath" $mainLog "Yellow"
            break
        }
    }
    
    if (-not $found) {
        Write-Log "CRITICAL ERROR: Could not find UnrealBuildTool.exe in any expected location" $mainLog "Red"
        
        # Search for it
        Write-Log "Searching for UnrealBuildTool.exe in engine directory..." $mainLog "Yellow"
        $searchResults = Get-ChildItem -Path $enginePath -Filter "UnrealBuildTool.exe" -Recurse -ErrorAction SilentlyContinue
        if ($searchResults) {
            Write-Log "Found potential UnrealBuildTool.exe locations:" $mainLog "Green"
            foreach ($result in $searchResults) {
                Write-Log "  $($result.FullName)" $mainLog "Green"
            }
            $ubtPath = $searchResults[0].FullName
        } else {
            Write-Log "No UnrealBuildTool.exe found in engine directory" $mainLog "Red"
        }
    }
}

# Check .NET version
$dotnetLog = "$logDir\dotnet_info.log"
"Dotnet information:" | Out-File -FilePath $dotnetLog
Write-Log "Checking .NET configuration..." $mainLog "Yellow"

try {
    $dotnetOutput = & dotnet --info
    $dotnetOutput | Out-File -FilePath $dotnetLog -Append
    Write-Log "Found .NET installed" $mainLog "Green"
} catch {
    Write-Log "WARNING: dotnet command failed: $_" $mainLog "Yellow"
}

# Check if the engine has its own .NET version
$engineDotNetPath = "$enginePath\Engine\Binaries\ThirdParty\DotNet\Win64"
if (Test-Path $engineDotNetPath) {
    Write-Log "Engine has embedded .NET at: $engineDotNetPath" $mainLog "Green"
    Get-ChildItem -Path $engineDotNetPath -Directory | ForEach-Object {
        Write-Log "  $($_.Name)" $mainLog "Cyan"
    }
} else {
    Write-Log "WARNING: Engine does not have embedded .NET at expected path" $mainLog "Yellow"
}

# Check for MSBuild
$msBuildLog = "$logDir\msbuild_info.log"
"MSBuild information:" | Out-File -FilePath $msBuildLog
Write-Log "Checking MSBuild configuration..." $mainLog "Yellow"

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $vswhereOutput = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
    $vswhereOutput | Out-File -FilePath $msBuildLog -Append
    
    if ($vswhereOutput) {
        $msBuildPath = Join-Path $vswhereOutput "MSBuild\Current\Bin\MSBuild.exe"
        if (Test-Path $msBuildPath) {
            Write-Log "Found MSBuild at: $msBuildPath" $mainLog "Green"
        } else {
            Write-Log "WARNING: MSBuild not found at expected path: $msBuildPath" $mainLog "Yellow"
        }
    } else {
        Write-Log "WARNING: Visual Studio with MSBuild not found" $mainLog "Yellow"
    }
} else {
    Write-Log "WARNING: vswhere.exe not found, can't locate Visual Studio" $mainLog "Yellow"
}

# Check for compiler
$compilerLog = "$logDir\compiler_info.log"
"Compiler information:" | Out-File -FilePath $compilerLog
Write-Log "Checking compiler configuration..." $mainLog "Yellow"

$cl = Get-Command cl -ErrorAction SilentlyContinue
if ($cl) {
    & cl 2>&1 | Out-File -FilePath $compilerLog -Append
    Write-Log "C++ compiler found in PATH" $mainLog "Green"
} else {
    Write-Log "WARNING: C++ compiler (cl.exe) not found in PATH" $mainLog "Yellow"
}

# Try to run UBT diagnostics
$ubtDiagnosticLog = "$logDir\ubt_diagnostic.log"
"UBT Diagnostic output:" | Out-File -FilePath $ubtDiagnosticLog
Write-Log "Running UnrealBuildTool diagnostics..." $mainLog "Yellow"

# Create a batch file to run UBT with proper environment
$ubtDiagnosticBat = "$logDir\run_ubt_diagnostic.bat"
@"
@echo off
setlocal enabledelayedexpansion

REM Set environment variables
set "UE_ENGINE_DIRECTORY=$($enginePath.Replace('\', '\\'))"
set "UE_PROJECT_PATH=$($projectPath.Replace('\', '\\'))"
set "PATH=%UE_ENGINE_DIRECTORY%\Engine\Binaries\ThirdParty\DotNet\Win64;%PATH%"
set "DOTNET_ROOT=%UE_ENGINE_DIRECTORY%\Engine\Binaries\ThirdParty\DotNet\Win64"

REM Run UBT in diagnostic mode
echo Running UBT diagnostics...
"$($ubtPath.Replace('\', '\\'))" -Mode=QueryTargets -Project="$($projectPath.Replace('\', '\\'))" -TargetPlatform=Win64 -BuildConfiguration=Development -Verbose

REM Run UBT to list target files
echo.
echo Listing target files...
"$($ubtPath.Replace('\', '\\'))" -Mode=ListTargetFiles -Project="$($projectPath.Replace('\', '\\'))" -TargetPlatform=Win64 -BuildConfiguration=Development -Verbose

REM Run UBT to list build options
echo.
echo Listing build options...
"$($ubtPath.Replace('\', '\\'))" -ListBuildOptions
"@ | Out-File -FilePath $ubtDiagnosticBat -Encoding ascii

Write-Log "Running UBT diagnostics batch file: $ubtDiagnosticBat" $mainLog "Yellow"
$ubtOutput = & cmd.exe /c $ubtDiagnosticBat 2>&1
$ubtOutput | Out-File -FilePath $ubtDiagnosticLog -Append

# Check for specific errors in UBT output
if ($ubtOutput -match "could not fetch all.*targets") {
    Write-Log "DETECTED TARGET ERROR: The 'could not fetch all available targets' error was reproduced" $mainLog "Red"
    
    # Look for more specific error indications
    if ($ubtOutput -match "System\.IO\.FileNotFoundException") {
        Write-Log "ISSUE: FileNotFoundException detected - likely missing a required DLL or assembly" $mainLog "Red"
    }
    
    if ($ubtOutput -match "System\.Reflection\.ReflectionTypeLoadException") {
        Write-Log "ISSUE: ReflectionTypeLoadException detected - likely assembly loading or version mismatch issue" $mainLog "Red"
    }
    
    if ($ubtOutput -match "Could not load file or assembly") {
        Write-Log "ISSUE: Assembly loading error detected - missing dependencies" $mainLog "Red"
        
        # Extract the specific assembly name
        if ($ubtOutput -match "Could not load file or assembly '([^']+)'") {
            $missingAssembly = $matches[1]
            Write-Log "Missing assembly: $missingAssembly" $mainLog "Red"
        }
    }
} else {
    Write-Log "UBT diagnostic run completed without detecting the target error" $mainLog "Green"
}

# Check target files
$targetFilesLog = "$logDir\target_files.log"
"Target files:" | Out-File -FilePath $targetFilesLog
Write-Log "Examining target files..." $mainLog "Yellow"

$targetPaths = @(
    "$PSScriptRoot\Intermediate\Build\BuildRules",
    "$enginePath\Engine\Intermediate\Build\BuildRules"
)

foreach ($path in $targetPaths) {
    if (Test-Path $path) {
        Write-Log "Found target path: $path" $mainLog "Green"
        Get-ChildItem -Path $path -Recurse -Filter "*.targets" | ForEach-Object {
            Write-Log "  $($_.FullName)" $mainLog "Cyan"
            "$($_.FullName)" | Out-File -FilePath $targetFilesLog -Append
        }
    } else {
        Write-Log "Target path not found: $path" $mainLog "Yellow"
    }
}

# Gather plugin information
$pluginLog = "$logDir\plugin_info.log"
"Plugin information:" | Out-File -FilePath $pluginLog
Write-Log "Examining plugins..." $mainLog "Yellow"

$pluginPaths = @(
    "$PSScriptRoot\Plugins"
)

foreach ($path in $pluginPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse -Filter "*.uplugin" | ForEach-Object {
            Write-Log "Found plugin: $($_.FullName)" $mainLog "Green"
            "$($_.FullName)" | Out-File -FilePath $pluginLog -Append
            
            try {
                $pluginContent = Get-Content $_.FullName -Raw | ConvertFrom-Json
                "Plugin Name: $($pluginContent.FriendlyName)" | Out-File -FilePath $pluginLog -Append
                "Modules:" | Out-File -FilePath $pluginLog -Append
                foreach ($module in $pluginContent.Modules) {
                    "  - $($module.Name) (Type: $($module.Type), Loading Phase: $($module.LoadingPhase))" | Out-File -FilePath $pluginLog -Append
                }
                
                "Dependencies:" | Out-File -FilePath $pluginLog -Append
                if ($pluginContent.Plugins) {
                    foreach ($dependency in $pluginContent.Plugins) {
                        "  - $($dependency.Name) (Enabled: $($dependency.Enabled))" | Out-File -FilePath $pluginLog -Append
                    }
                } else {
                    "  None specified" | Out-File -FilePath $pluginLog -Append
                }
                "" | Out-File -FilePath $pluginLog -Append
            } catch {
                "Error parsing plugin file: $_" | Out-File -FilePath $pluginLog -Append
            }
        }
    }
}

# Create an enhanced fix script based on diagnostic findings
$enhancedFixBat = "$logDir\EnhancedFix.bat"
@"
@echo off
setlocal enabledelayedexpansion

echo ========================================================================
echo                  ENHANCED UBT TARGET ERROR FIX
echo ========================================================================
echo.
echo This script implements additional fixes for the "could not fetch all 
echo available targets" error based on diagnostic results.
echo.

REM Set paths
set "UE_ENGINE_DIRECTORY=$($enginePath.Replace('\', '\\'))"
set "UE_PROJECT_PATH=$($projectPath.Replace('\', '\\'))"
set "PROJECT_ROOT=$($PSScriptRoot.Replace('\', '\\'))"

echo Engine directory: %UE_ENGINE_DIRECTORY%
echo Project path: %UE_PROJECT_PATH%
echo.

REM Clean target-related files that may be corrupted
echo ========================================================================
echo STEP 1: Cleaning potentially corrupted target files
echo ========================================================================
echo.

if exist "%PROJECT_ROOT%\Intermediate\Build\BuildRules" (
    echo Removing BuildRules directory...
    rd /s /q "%PROJECT_ROOT%\Intermediate\Build\BuildRules"
)

if exist "%PROJECT_ROOT%\Plugins\*\Intermediate\Build\BuildRules" (
    echo Removing plugin BuildRules directories...
    for /d %%d in ("%PROJECT_ROOT%\Plugins\*") do (
        if exist "%%d\Intermediate\Build\BuildRules" (
            echo Cleaning %%d\Intermediate\Build\BuildRules
            rd /s /q "%%d\Intermediate\Build\BuildRules"
        )
    )
)

REM Clean .binaries.txt files which may contain incorrect data
echo Removing .binaries.txt files...
del /s /q "%PROJECT_ROOT%\*.binaries.txt" 2>nul

REM Fix .NET references
echo ========================================================================
echo STEP 2: Setting up .NET environment
echo ========================================================================
echo.

set "DOTNET_ROOT=%UE_ENGINE_DIRECTORY%\Engine\Binaries\ThirdParty\DotNet\Win64"
set "PATH=%DOTNET_ROOT%;%PATH%"
set "DOTNET_CLI_TELEMETRY_OPTOUT=1"
set "DOTNET_NOLOGO=1"

echo .NET root set to: %DOTNET_ROOT%
echo.

REM Run visual studio installer repair if needed
echo ========================================================================
echo STEP 3: Checking Visual Studio components
echo ========================================================================
echo.

where /q vswhere
if %ERRORLEVEL% EQU 0 (
    echo Found vswhere, checking Visual Studio installation...
    for /f "usebackq tokens=*" %%i in (`vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
        set "VS_PATH=%%i"
    )
    
    if defined VS_PATH (
        echo Found Visual Studio at: %VS_PATH%
    ) else (
        echo WARNING: Visual Studio with MSBuild not found!
        echo This may cause issues with the Unreal Build Tool.
    )
) else (
    echo WARNING: vswhere not found, cannot verify Visual Studio installation.
)

REM Generate project files
echo ========================================================================
echo STEP 4: Regenerating project files
echo ========================================================================
echo.

if exist "%UE_ENGINE_DIRECTORY%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" (
    echo Using UnrealBuildTool to generate project files...
    "%UE_ENGINE_DIRECTORY%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" -projectfiles -project="%UE_PROJECT_PATH%" -game -engine -progress
) else (
    echo WARNING: UnrealBuildTool.exe not found at expected location.
    
    if exist "%UE_ENGINE_DIRECTORY%\Engine\Binaries\Win64\UnrealVersionSelector.exe" (
        echo Using UnrealVersionSelector as fallback...
        "%UE_ENGINE_DIRECTORY%\Engine\Binaries\Win64\UnrealVersionSelector.exe" /projectfiles "%UE_PROJECT_PATH%"
    ) else (
        echo ERROR: Could not find tools to regenerate project files.
    )
)

REM Fix plugin loading order
echo ========================================================================
echo STEP 5: Verifying plugin dependencies
echo ========================================================================
echo.

REM Create dummy SourceCodeAccess plugin if missing
if not exist "%PROJECT_ROOT%\Plugins\SourceCodeAccess" (
    echo SourceCodeAccess plugin directory not found in project, checking if it needs to be added...
    
    REM Check if any plugin depends on SourceCodeAccess
    set NEEDS_SOURCE_ACCESS=0
    for /d %%d in ("%PROJECT_ROOT%\Plugins\*") do (
        findstr /i "SourceCodeAccess" "%%d\*.uplugin" >nul 2>&1
        if not errorlevel 1 (
            set NEEDS_SOURCE_ACCESS=1
            echo Found dependency on SourceCodeAccess in %%d
        )
    )
    
    if !NEEDS_SOURCE_ACCESS! EQU 1 (
        echo Adding SourceCodeAccess reference to project file...
        
        REM Using PowerShell to modify the uproject file
        powershell -Command "& {
            \$projectFile = Get-Content '%UE_PROJECT_PATH%' -Raw | ConvertFrom-Json
            \$hasSourceCodeAccess = \$false
            foreach (\$plugin in \$projectFile.Plugins) {
                if (\$plugin.Name -eq 'SourceCodeAccess') {
                    \$hasSourceCodeAccess = \$true
                    \$plugin.Enabled = \$true
                    break
                }
            }
            if (-not \$hasSourceCodeAccess) {
                \$newPlugin = @{
                    Name = 'SourceCodeAccess'
                    Enabled = \$true
                }
                \$projectFile.Plugins += \$newPlugin
            }
            \$projectFile | ConvertTo-Json -Depth 10 | Set-Content '%UE_PROJECT_PATH%'
        }"
    )
    )
)

REM Run UBT with diagnostic mode
echo ========================================================================
echo STEP 6: Running UBT diagnostic mode
echo ========================================================================
echo.

if exist "%UE_ENGINE_DIRECTORY%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" (
    echo Running UBT in diagnostic mode...
    "%UE_ENGINE_DIRECTORY%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" -Mode=QueryTargets -Project="%UE_PROJECT_PATH%" -TargetPlatform=Win64 -BuildConfiguration=Development -Verbose
)

REM Try building the project
echo ========================================================================
echo STEP 7: Attempting to build project
echo ========================================================================
echo.

if exist "%UE_ENGINE_DIRECTORY%\Engine\Build\BatchFiles\Build.bat" (
    echo Building project...
    call "%UE_ENGINE_DIRECTORY%\Engine\Build\BatchFiles\Build.bat" Dreamer1Editor Win64 Development -Project="%UE_PROJECT_PATH%" -WaitMutex
)

echo.
echo ========================================================================
echo                  FIX PROCEDURE COMPLETE
echo ========================================================================
echo.
echo If you still encounter the "could not fetch all the available targets"
echo error, please review the diagnostic logs in:
echo %PROJECT_ROOT%\UBT_Diagnostics_$timestamp
echo.
pause
"@ | Out-File -FilePath $enhancedFixBat -Encoding ascii

Write-Log "Created enhanced fix script at: $enhancedFixBat" $mainLog "Green"

# Create a copy of the enhanced fix script in the project root
Copy-Item -Path $enhancedFixBat -Destination "$PSScriptRoot\EnhancedUBTFix.bat" -Force
Write-Log "Copied enhanced fix script to: $PSScriptRoot\EnhancedUBTFix.bat" $mainLog "Green"

# Create a targeted fix specifically for the target error
$targetFixPs1 = "$PSScriptRoot\FixUBTTargetError.ps1"
@"
# FixUBTTargetError.ps1
# This script specifically targets the "could not fetch all available targets" error

# Get script directory
\$scriptDir = Split-Path -Parent -Path \$MyInvocation.MyCommand.Definition

# Check if running as admin
\$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not \$isAdmin) {
    Write-Host "This script should be run as administrator. Please restart with admin privileges." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    \$null = \$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Function to write output with timestamp
function Write-Output-Timestamped {
    param (
        [string]\$Message,
        [string]\$Color = "White"
    )
    
    \$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[\$timestamp] \$Message" -ForegroundColor \$Color
}

Write-Output-Timestamped "Starting UBT Target Error Fix..." "Cyan"

# Get project path
\$projectPath = Join-Path \$scriptDir "Dreamer1.uproject"
if (-not (Test-Path \$projectPath)) {
    Write-Output-Timestamped "ERROR: Could not find Dreamer1.uproject" "Red"
    exit 1
}

# Get engine path from project
try {
    \$projectJson = Get-Content \$projectPath -Raw | ConvertFrom-Json
    \$engineVersion = \$projectJson.EngineAssociation
    Write-Output-Timestamped "Project uses engine version: \$engineVersion" "Green"
    
    # Look for engine in registry
    \$registryPath = "HKLM:\\SOFTWARE\\EpicGames\\Unreal Engine\\\$engineVersion"
    if (Test-Path \$registryPath) {
        \$enginePath = (Get-ItemProperty -Path \$registryPath -Name "InstalledDirectory").InstalledDirectory
        Write-Output-Timestamped "Found engine at: \$enginePath" "Green"
    } else {
        # Try common locations
        \$commonPaths = @(
            "C:\\Program Files\\Epic Games\\UE_\$engineVersion",
            "C:\\Epic Games\\UE_\$engineVersion"
        )
        
        foreach (\$path in \$commonPaths) {
            if (Test-Path \$path) {
                \$enginePath = \$path
                Write-Output-Timestamped "Found engine at: \$enginePath" "Green"
                break
            }
        }
    }
} catch {
    Write-Output-Timestamped "ERROR: Failed to parse project file or find engine: \$_" "Red"
    exit 1
}

if (-not \$enginePath -or -not (Test-Path \$enginePath)) {
    Write-Output-Timestamped "ERROR: Could not locate engine installation" "Red"
    exit 1
}

Write-Output-Timestamped "Step 1: Cleaning potentially corrupted files..." "Yellow"

# Clean BuildRules directories
\$buildRulesPaths = @(
    "\$scriptDir\\Intermediate\\Build\\BuildRules",
    "\$scriptDir\\Plugins\\*\\Intermediate\\Build\\BuildRules"
)

foreach (\$path in \$buildRulesPaths) {
    Get-Item -Path \$path -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output-Timestamped "Removing: \$_" "Yellow"
        Remove-Item -Path \$_ -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Clean binaries.txt files
Get-ChildItem -Path \$scriptDir -Filter "*.binaries.txt" -Recurse -File | ForEach-Object {
    Write-Output-Timestamped "Removing: \$(\$_.FullName)" "Yellow"
    Remove-Item -Path \$_.FullName -Force
}

Write-Output-Timestamped "Step 2: Setting up .NET environment..." "Yellow"

# Set environment variables
\$env:DOTNET_ROOT = "\$enginePath\\Engine\\Binaries\\ThirdParty\\DotNet\\Win64"
\$env:PATH = "\$env:DOTNET_ROOT;\$env:PATH"
\$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "1"
\$env:DOTNET_CLI_TELEMETRY_OPTOUT = "1"
\$env:DOTNET_NOLOGO = "1"

Write-Output-Timestamped "Step 3: Verifying plugin dependencies..." "Yellow"

# Ensure SourceCodeAccess plugin is referenced
\$projectContent = Get-Content \$projectPath -Raw | ConvertFrom-Json
\$hasSourceCodeAccess = \$false

foreach (\$plugin in \$projectContent.Plugins) {
    if (\$plugin.Name -eq "SourceCodeAccess") {
        \$hasSourceCodeAccess = \$true
        if (-not \$plugin.Enabled) {
            Write-Output-Timestamped "Enabling SourceCodeAccess plugin..." "Yellow"
            \$plugin.Enabled = \$true
        }
        break
    }
}

if (-not \$hasSourceCodeAccess) {
    Write-Output-Timestamped "Adding SourceCodeAccess plugin reference..." "Yellow"
    \$newPlugin = @{
        Name = "SourceCodeAccess"
        Enabled = \$true
    }
    
    # Convert to proper PSObject for adding to array
    \$newPluginObj = New-Object PSObject -Property \$newPlugin
    
    # Add to plugins array
    if (\$null -eq \$projectContent.Plugins) {
        \$projectContent | Add-Member -MemberType NoteProperty -Name "Plugins" -Value @(\$newPluginObj)
    } else {
        \$projectContent.Plugins += \$newPluginObj
    }
    
    # Save changes
    \$projectContent | ConvertTo-Json -Depth 10 | Set-Content \$projectPath
}

Write-Output-Timestamped "Step 4: Running registry fix..." "Yellow"

# This addresses a common issue with UBT not finding the right registry keys
\$unrealRegistryKeys = @(
    "HKLM:\\SOFTWARE\\EpicGames\\Unreal Engine",
    "HKCU:\\SOFTWARE\\EpicGames\\Unreal Engine"
)

foreach (\$key in \$unrealRegistryKeys) {
    if (Test-Path \$key) {
        \$versionKey = Join-Path \$key \$engineVersion
        if (-not (Test-Path \$versionKey)) {
            try {
                Write-Output-Timestamped "Creating registry key: \$versionKey" "Yellow"
                New-Item -Path \$versionKey -Force | Out-Null
                New-ItemProperty -Path \$versionKey -Name "InstalledDirectory" -Value \$enginePath -PropertyType String -Force | Out-Null
            } catch {
                Write-Output-Timestamped "WARNING: Could not create registry key: \$_" "Yellow"
            }
        } else {
            # Ensure the InstalledDirectory value is correct
            Set-ItemProperty -Path \$versionKey -Name "InstalledDirectory" -Value \$enginePath -Type String -Force
        }
    }
}

Write-Output-Timestamped "Step 5: Creating UBT batch file..." "Yellow"

# Create a batch file that properly sets up the environment for UBT
\$ubtBatchFile = "\$scriptDir\\RunUBT.bat"
@"
@echo off
setlocal enabledelayedexpansion

REM Set up environment for UBT
set "UE_ENGINE_DIRECTORY=\$(\$enginePath.Replace('\', '\\'))"
set "UE_PROJECT_PATH=\$(\$projectPath.Replace('\', '\\'))"
set "DOTNET_ROOT=%UE_ENGINE_DIRECTORY%\\Engine\\Binaries\\ThirdParty\\DotNet\\Win64"
set "PATH=%DOTNET_ROOT%;%PATH%"
set "DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1"
set "DOTNET_CLI_TELEMETRY_OPTOUT=1"
set "DOTNET_NOLOGO=1"
set "UBT_BINARY=%UE_ENGINE_DIRECTORY%\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.exe"

echo UBT Environment Setup:
echo Engine: %UE_ENGINE_DIRECTORY%
echo Project: %UE_PROJECT_PATH%
echo DOTNET_ROOT: %DOTNET_ROOT%
echo.

REM Clear UBT build rules caches
if exist "\$(\$scriptDir.Replace('\', '\\'))\\Intermediate\\Build\\BuildRules" (
    echo Removing BuildRules directory...
    rd /s /q "\$(\$scriptDir.Replace('\', '\\'))\\Intermediate\\Build\\BuildRules"
)

REM Run UBT to generate project files
echo Generating project files...
"%UBT_BINARY%" -projectfiles -project="%UE_PROJECT_PATH%" -game -engine -progress

REM Try to fetch targets
echo Attempting to fetch targets...
"%UBT_BINARY%" -Mode=QueryTargets -Project="%UE_PROJECT_PATH%" -TargetPlatform=Win64 -BuildConfiguration=Development -Verbose

REM Try a build
echo Attempting to build project...
"%UE_ENGINE_DIRECTORY%\\Engine\\Build\\BatchFiles\\Build.bat" Dreamer1Editor Win64 Development -Project="%UE_PROJECT_PATH%" -WaitMutex

echo.
echo UBT operations completed.
pause
"@ | Out-File -FilePath \$ubtBatchFile -Encoding ascii

Write-Output-Timestamped "Created UBT batch file: \$ubtBatchFile" "Green"
Write-Output-Timestamped "Running UBT batch file..." "Yellow"

# Execute the batch file
Start-Process cmd.exe -ArgumentList "/c `"\$ubtBatchFile`"" -Wait

Write-Output-Timestamped "Step 6: Verification..." "Yellow"

# Now run a final check to see if the issue is fixed
\$ubtExe = "\$enginePath\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.exe"
if (Test-Path \$ubtExe) {
    try {
        \$targetOutput = & \$ubtExe -Mode=QueryTargets -Project=\$projectPath -TargetPlatform=Win64 -BuildConfiguration=Development 2>&1
        \$hasError = \$targetOutput -match "could not fetch all.*targets"
        
        if (\$hasError) {
            Write-Output-Timestamped "WARNING: The target error still persists." "Red"
            Write-Output-Timestamped "Please try rebuilding your project with the EnhancedUBTFix.bat script." "Yellow"
        } else {
            Write-Output-Timestamped "Success! The target error appears to be fixed." "Green"
        }
    } catch {
        Write-Output-Timestamped "ERROR: Failed to run UBT verification: \$_" "Red"
    }
} else {
    Write-Output-Timestamped "WARNING: Could not find UBT executable for verification" "Yellow"
}

Write-Output-Timestamped "UBT Target Error Fix completed." "Cyan"
Write-Output-Timestamped "Please try opening your project in Unreal Engine now." "Green"
Write-Host "Press any key to exit..."
\$null = \$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@ | Out-File -FilePath $targetFixPs1 -Encoding utf8

# Create the batch wrapper for the targeted fix
$targetFixBat = "$PSScriptRoot\FixUBTTargetError.bat"
@"
@echo off
REM Run the PowerShell script with admin privileges
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File ""%~dp0FixUBTTargetError.ps1""' -Verb RunAs"
"@ | Out-File -FilePath $targetFixBat -Encoding ascii

Write-Log "Created targeted fix scripts: $targetFixPs1 and $targetFixBat" $mainLog "Green"

# Summary
Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "                     DIAGNOSTIC SUMMARY                               " -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Diagnostic logs saved to: $logDir" -ForegroundColor Green
Write-Host ""
Write-Host "Two fix scripts have been created:" -ForegroundColor Yellow
Write-Host "1. EnhancedUBTFix.bat - A comprehensive fix based on diagnostic results" -ForegroundColor Yellow
Write-Host "2. FixUBTTargetError.bat - A targeted fix specifically for the target error" -ForegroundColor Yellow
Write-Host ""
Write-Host "Please try running the FixUBTTargetError.bat script first." -ForegroundColor Green
Write-Host "If that doesn't resolve the issue, run EnhancedUBTFix.bat for a more thorough fix." -ForegroundColor Green
Write-Host ""
Write-Host "Diagnostic completed. Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")