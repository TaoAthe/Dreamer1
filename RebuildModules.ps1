# Rebuild Unreal Engine modules using PowerShell
Write-Host "Rebuilding Unreal Engine modules..." -ForegroundColor Cyan

$ProjectPath = "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Dreamer1.uproject"

# Get the Unreal Engine version from the project file
$ProjectJson = Get-Content $ProjectPath | ConvertFrom-Json
$EngineVersion = $ProjectJson.EngineAssociation
Write-Host "Detected Engine Version: $EngineVersion" -ForegroundColor Green

# Try to locate the engine
$EnginePaths = @(
    "C:\Program Files\Epic Games\UE_$EngineVersion",
    "C:\Program Files\Epic Games\UE_${EngineVersion}EA",
    "C:\Program Files\Epic Games\UE_${EngineVersion}-release"
)

$EnginePath = $null
foreach ($Path in $EnginePaths) {
    if (Test-Path $Path) {
        $EnginePath = $Path
        break
    }
}

if (-not $EnginePath) {
    Write-Host "Could not find Unreal Engine path. Please modify this script with your UE installation path." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Using Engine Path: $EnginePath" -ForegroundColor Green

# Clean Binaries and Intermediate directories for problematic plugins
$PluginsToClean = @(
    "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp",
    "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74"
)

foreach ($PluginPath in $PluginsToClean) {
    if (Test-Path "$PluginPath\Binaries") {
        Write-Host "Cleaning Binaries in $PluginPath" -ForegroundColor Yellow
        Remove-Item -Path "$PluginPath\Binaries" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    if (Test-Path "$PluginPath\Intermediate") {
        Write-Host "Cleaning Intermediate in $PluginPath" -ForegroundColor Yellow
        Remove-Item -Path "$PluginPath\Intermediate" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Try to ensure System.CodeDom is available
Write-Host "Checking for required .NET dependencies..." -ForegroundColor Yellow
if (-not [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq "System.CodeDom" }) {
    Write-Host "System.CodeDom not loaded. This might cause build issues." -ForegroundColor Yellow
    Write-Host "Using alternative build method to avoid System.CodeDom dependency issues." -ForegroundColor Cyan
}

# Check for the UnrealVersionSelector executable
$UvsPath = "$EnginePath\Engine\Binaries\Win64\UnrealVersionSelector.exe"
if (Test-Path $UvsPath) {
    Write-Host "Found UnrealVersionSelector at: $UvsPath" -ForegroundColor Green
    Write-Host "Using UnrealVersionSelector to rebuild the project..." -ForegroundColor Cyan
    
    # Use UnrealVersionSelector to generate project files
    & $UvsPath /projectfiles "$ProjectPath"
    
    # Try using the Engine's batch files directly
    $BuildBat = "$EnginePath\Engine\Build\BatchFiles\Build.bat"
    if (Test-Path $BuildBat) {
        Write-Host "Using Build.bat to build Development Editor..." -ForegroundColor Cyan
        & cmd /c """$BuildBat"" Dreamer1Editor Win64 Development -Project=""$ProjectPath"" -WaitMutex -FromMsBuild"
    }
} else {
    Write-Host "WARNING: UnrealVersionSelector not found. Falling back to alternative methods." -ForegroundColor Yellow
    
    # Try to use the Engine's batch files directly
    $RunUatBat = "$EnginePath\Engine\Build\BatchFiles\RunUAT.bat"
    if (Test-Path $RunUatBat) {
        $InEditorPluginPath = Resolve-Path "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp\*.uplugin" -ErrorAction SilentlyContinue
        $ImGuiPluginPath = Resolve-Path "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\*.uplugin" -ErrorAction SilentlyContinue
        
        if ($InEditorPluginPath) {
            Write-Host "Building InEditorCpp plugin..." -ForegroundColor Cyan
            & cmd /c """$RunUatBat"" BuildPlugin -Plugin=""$InEditorPluginPath"" -Package=""$ProjectPath\..\BuiltPlugins\InEditorCpp"" -Rocket"
        } else {
            Write-Host "WARNING: Could not find InEditorCpp.uplugin" -ForegroundColor Yellow
        }
        
        if ($ImGuiPluginPath) {
            Write-Host "Building ImGui plugin..." -ForegroundColor Cyan
            & cmd /c """$RunUatBat"" BuildPlugin -Plugin=""$ImGuiPluginPath"" -Package=""$ProjectPath\..\BuiltPlugins\ImGui"" -Rocket"
        } else {
            Write-Host "WARNING: Could not find ImGui.uplugin" -ForegroundColor Yellow
        }
    } else {
        Write-Host "ERROR: Cannot find appropriate build tools. Please rebuild the project from the Unreal Editor." -ForegroundColor Red
    }
}

Write-Host "Build process completed. Check the output for any errors." -ForegroundColor Cyan
Write-Host "You can now try opening the project again." -ForegroundColor Green
Write-Host ""
Write-Host "NOTE: If you still see rebuilding errors in Unreal Editor, please accept the rebuild prompt" -ForegroundColor Yellow
Write-Host "when the engine offers it. This is often the most reliable way to rebuild modules." -ForegroundColor Yellow
Read-Host "Press Enter to exit"