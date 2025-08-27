# RebuildModules_Fixed.ps1
# Fixed version of the Rebuild Unreal Engine modules script

Write-Host "========================================================================"
Write-Host "                     REBUILD MODULES (FIXED VERSION)"
Write-Host "========================================================================"
Write-Host ""

# Enable better error handling
$ErrorActionPreference = "Continue"

$ProjectPath = "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Dreamer1.uproject"

Write-Host "Rebuilding Unreal Engine modules..." -ForegroundColor Cyan
Write-Host "Project Path: $ProjectPath" -ForegroundColor White

# Check if project file exists
if (-not (Test-Path $ProjectPath)) {
    Write-Host "ERROR: Project file not found at $ProjectPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Get the Unreal Engine version from the project file
try {
    $ProjectJson = Get-Content $ProjectPath -Raw | ConvertFrom-Json
    $EngineVersion = $ProjectJson.EngineAssociation
    Write-Host "Detected Engine Version: $EngineVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to parse project file: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Try to locate the engine
Write-Host "Locating Unreal Engine installation..." -ForegroundColor Yellow

$EnginePaths = @(
    "C:\Program Files\Epic Games\UE_$EngineVersion",
    "C:\Program Files\Epic Games\UE_${EngineVersion}EA", 
    "C:\Program Files\Epic Games\UE_${EngineVersion}-release",
    "C:\Epic Games\UE_$EngineVersion"
)

$EnginePath = $null
foreach ($Path in $EnginePaths) {
    if (Test-Path $Path) {
        $EnginePath = $Path
        Write-Host "Found engine at: $Path" -ForegroundColor Green
        break
    }
}

if (-not $EnginePath) {
    Write-Host "Could not find Unreal Engine path automatically." -ForegroundColor Red
    Write-Host "Please enter your UE installation path manually:" -ForegroundColor Yellow
    $EnginePath = Read-Host "Engine Path"
    
    if (-not (Test-Path $EnginePath)) {
        Write-Host "ERROR: Specified engine path does not exist." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host "Using Engine Path: $EnginePath" -ForegroundColor Green

# Clean Binaries and Intermediate directories for problematic plugins
Write-Host ""
Write-Host "Cleaning plugin directories..." -ForegroundColor Yellow

$PluginsToClean = @(
    "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp",
    "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74"
)

foreach ($PluginPath in $PluginsToClean) {
    if (Test-Path $PluginPath) {
        Write-Host "Processing plugin: $PluginPath" -ForegroundColor Cyan
        
        if (Test-Path "$PluginPath\Binaries") {
            Write-Host "  Cleaning Binaries..." -ForegroundColor Gray
            Remove-Item -Path "$PluginPath\Binaries" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        if (Test-Path "$PluginPath\Intermediate") {
            Write-Host "  Cleaning Intermediate..." -ForegroundColor Gray
            Remove-Item -Path "$PluginPath\Intermediate" -Recurse -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "Plugin not found: $PluginPath" -ForegroundColor Yellow
    }
}

# Check for required .NET dependencies (FIXED VERSION)
Write-Host ""
Write-Host "Checking for required .NET dependencies..." -ForegroundColor Yellow

try {
    # Fixed: Proper PowerShell syntax for checking loaded assemblies
    $loadedAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies()
    $systemCodeDomLoaded = $false
    
    foreach ($assembly in $loadedAssemblies) {
        if ($assembly.GetName().Name -eq "System.CodeDom") {
            $systemCodeDomLoaded = $true
            break
        }
    }
    
    if (-not $systemCodeDomLoaded) {
        Write-Host "System.CodeDom not loaded. This might cause build issues." -ForegroundColor Yellow
        Write-Host "Attempting to load System.CodeDom..." -ForegroundColor Cyan
        
        try {
            Add-Type -AssemblyName "System.CodeDom"
            Write-Host "Successfully loaded System.CodeDom" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Could not load System.CodeDom: $_" -ForegroundColor Yellow
            Write-Host "Using alternative build method to avoid System.CodeDom dependency issues." -ForegroundColor Cyan
        }
    } else {
        Write-Host "System.CodeDom is already loaded" -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Error checking .NET dependencies: $_" -ForegroundColor Yellow
}

# Check for the UnrealVersionSelector executable
Write-Host ""
Write-Host "Checking for UnrealVersionSelector..." -ForegroundColor Yellow

$UvsPath = "$EnginePath\Engine\Binaries\Win64\UnrealVersionSelector.exe"
if (Test-Path $UvsPath) {
    Write-Host "Found UnrealVersionSelector at: $UvsPath" -ForegroundColor Green
    Write-Host "Using UnrealVersionSelector to rebuild the project..." -ForegroundColor Cyan
    
    try {
        # Use UnrealVersionSelector to generate project files
        Write-Host "Generating project files..." -ForegroundColor Cyan
        & $UvsPath /projectfiles "$ProjectPath"
        
        # Try using the Engine's batch files directly
        $BuildBat = "$EnginePath\Engine\Build\BatchFiles\Build.bat"
        if (Test-Path $BuildBat) {
            Write-Host "Using Build.bat to build Development Editor..." -ForegroundColor Cyan
            & cmd /c "`"$BuildBat`" Dreamer1Editor Win64 Development -Project=`"$ProjectPath`" -WaitMutex -FromMsBuild"
        } else {
            Write-Host "Warning: Build.bat not found at expected location" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error running UnrealVersionSelector: $_" -ForegroundColor Red
    }
} else {
    Write-Host "WARNING: UnrealVersionSelector not found. Falling back to alternative methods." -ForegroundColor Yellow
    
    # Try to use the Engine's batch files directly
    $RunUatBat = "$EnginePath\Engine\Build\BatchFiles\RunUAT.bat"
    if (Test-Path $RunUatBat) {
        Write-Host "Found RunUAT.bat, using it for plugin compilation..." -ForegroundColor Cyan
        
        # Try to find plugin files
        $InEditorPluginPath = Get-ChildItem -Path "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp" -Filter "*.uplugin" -ErrorAction SilentlyContinue | Select-Object -First 1
        $ImGuiPluginPath = Get-ChildItem -Path "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74" -Filter "*.uplugin" -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($InEditorPluginPath) {
            Write-Host "Building InEditorCpp plugin..." -ForegroundColor Cyan
            try {
                & cmd /c "`"$RunUatBat`" BuildPlugin -Plugin=`"$($InEditorPluginPath.FullName)`" -Package=`"C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\BuiltPlugins\InEditorCpp`" -Rocket"
            } catch {
                Write-Host "Error building InEditorCpp plugin: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "WARNING: Could not find InEditorCpp.uplugin" -ForegroundColor Yellow
        }
        
        if ($ImGuiPluginPath) {
            Write-Host "Building ImGui plugin..." -ForegroundColor Cyan
            try {
                & cmd /c "`"$RunUatBat`" BuildPlugin -Plugin=`"$($ImGuiPluginPath.FullName)`" -Package=`"C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\BuiltPlugins\ImGui`" -Rocket"
            } catch {
                Write-Host "Error building ImGui plugin: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "WARNING: Could not find ImGui.uplugin" -ForegroundColor Yellow
        }
    } else {
        Write-Host "ERROR: Cannot find appropriate build tools." -ForegroundColor Red
        Write-Host "Please try rebuilding the project from the Unreal Editor." -ForegroundColor Yellow
    }
}

# Try using UnrealBuildTool directly as a last resort
Write-Host ""
Write-Host "Attempting direct UnrealBuildTool usage..." -ForegroundColor Yellow

$UbtPaths = @(
    "$EnginePath\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe",
    "$EnginePath\Engine\Binaries\DotNET\UnrealBuildTool.exe"
)

$UbtPath = $null
foreach ($Path in $UbtPaths) {
    if (Test-Path $Path) {
        $UbtPath = $Path
        break
    }
}

if ($UbtPath) {
    Write-Host "Found UnrealBuildTool at: $UbtPath" -ForegroundColor Green
    
    try {
        Write-Host "Generating project files with UBT..." -ForegroundColor Cyan
        & $UbtPath -projectfiles -project="$ProjectPath" -game -engine -progress
        
        Write-Host "Building Dreamer1Editor with UBT..." -ForegroundColor Cyan
        & $UbtPath Dreamer1Editor Win64 Development -Project="$ProjectPath" -WaitMutex
    } catch {
        Write-Host "Error running UnrealBuildTool directly: $_" -ForegroundColor Red
    }
} else {
    Write-Host "ERROR: Could not find UnrealBuildTool.exe" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================================================"
Write-Host "                     REBUILD PROCESS COMPLETED"
Write-Host "========================================================================"
Write-Host ""

Write-Host "Build process completed. Check the output above for any errors." -ForegroundColor Cyan
Write-Host "You can now try opening the project again." -ForegroundColor Green
Write-Host ""
Write-Host "NOTE: If you still see rebuilding errors in Unreal Editor, please accept the rebuild prompt" -ForegroundColor Yellow
Write-Host "when the engine offers it. This is often the most reliable way to rebuild modules." -ForegroundColor Yellow

Write-Host ""
Read-Host "Press Enter to exit"