@echo off
setlocal enabledelayedexpansion

echo ========================================================================
echo                MANUAL REBUILD FOR DREAMER1 UNREAL PROJECT
echo ========================================================================
echo.
echo This script will completely rebuild your project from source
echo using step-by-step manual methods to ensure maximum compatibility.
echo.
echo PLEASE CLOSE UNREAL ENGINE AND VISUAL STUDIO BEFORE CONTINUING
echo.
pause

set PROJECT_ROOT=C:\Users\Sarah\Documents\Unreal Projects\Dreamer1
set PROJECT_PATH=%PROJECT_ROOT%\Dreamer1.uproject
set LOG_FILE=%PROJECT_ROOT%\manual_rebuild_log.txt

echo Starting rebuild process at %date% %time% > %LOG_FILE%
echo Working directory: %PROJECT_ROOT% >> %LOG_FILE%

rem Get Unreal Engine version
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content '%PROJECT_PATH%' | ConvertFrom-Json).EngineAssociation"') do set ENGINE_VERSION=%%a
echo Detected Engine Version: %ENGINE_VERSION%
echo Detected Engine Version: %ENGINE_VERSION% >> %LOG_FILE%

if exist "C:\Program Files\Epic Games\UE_%ENGINE_VERSION%" (
    set ENGINE_PATH=C:\Program Files\Epic Games\UE_%ENGINE_VERSION%
) else if exist "C:\Program Files\Epic Games\UE_%ENGINE_VERSION%EA" (
    set ENGINE_PATH=C:\Program Files\Epic Games\UE_%ENGINE_VERSION%EA
) else (
    echo ERROR: Could not find Unreal Engine path.
    echo ERROR: Could not find Unreal Engine path. >> %LOG_FILE%
    pause
    exit /b 1
)

echo Using Engine Path: %ENGINE_PATH%
echo Using Engine Path: %ENGINE_PATH% >> %LOG_FILE%

echo.
echo ========================================================================
echo STEP 1: CLEAN ALL INTERMEDIATE FILES
echo ========================================================================
echo.
echo This step removes all generated files for a clean rebuild.
echo.

echo Cleaning project binaries and intermediate files... >> %LOG_FILE%

rem Remove project intermediate files
if exist "%PROJECT_ROOT%\Binaries" (
    echo Removing Binaries directory...
    rmdir /s /q "%PROJECT_ROOT%\Binaries"
    echo Removed Binaries directory >> %LOG_FILE%
)

if exist "%PROJECT_ROOT%\Intermediate" (
    echo Removing Intermediate directory...
    rmdir /s /q "%PROJECT_ROOT%\Intermediate"
    echo Removed Intermediate directory >> %LOG_FILE%
)

if exist "%PROJECT_ROOT%\Saved\Temp" (
    echo Removing Saved\Temp directory...
    rmdir /s /q "%PROJECT_ROOT%\Saved\Temp"
    echo Removed Saved\Temp directory >> %LOG_FILE%
)

if exist "%PROJECT_ROOT%\DerivedDataCache" (
    echo Removing DerivedDataCache directory...
    rmdir /s /q "%PROJECT_ROOT%\DerivedDataCache"
    echo Removed DerivedDataCache directory >> %LOG_FILE%
)

if exist "%PROJECT_ROOT%\Build" (
    echo Removing Build directory...
    rmdir /s /q "%PROJECT_ROOT%\Build"
    echo Removed Build directory >> %LOG_FILE%
)

if exist "%PROJECT_ROOT%\BuiltPlugins" (
    echo Removing BuiltPlugins directory...
    rmdir /s /q "%PROJECT_ROOT%\BuiltPlugins"
    echo Removed BuiltPlugins directory >> %LOG_FILE%
)

echo Cleaning plugin intermediate files... >> %LOG_FILE%

rem Clean all plugins
for /d %%d in ("%PROJECT_ROOT%\Plugins\*") do (
    echo Processing plugin: %%~nxd
    
    if exist "%%d\Intermediate" (
        echo   Removing Intermediate from %%~nxd...
        rmdir /s /q "%%d\Intermediate"
        echo   Removed Intermediate from %%~nxd >> %LOG_FILE%
    )
    
    if exist "%%d\Binaries" (
        echo   Removing Binaries from %%~nxd...
        rmdir /s /q "%%d\Binaries"
        echo   Removed Binaries from %%~nxd >> %LOG_FILE%
    )
    
    if exist "%%d\Build" (
        echo   Removing Build from %%~nxd...
        rmdir /s /q "%%d\Build"
        echo   Removed Build from %%~nxd >> %LOG_FILE%
    )
)

echo Removing Visual Studio files...
if exist "%PROJECT_ROOT%\*.sln" del /f "%PROJECT_ROOT%\*.sln"
if exist "%PROJECT_ROOT%\*.suo" del /f "%PROJECT_ROOT%\*.suo"
if exist "%PROJECT_ROOT%\*.sdf" del /f "%PROJECT_ROOT%\*.sdf"
if exist "%PROJECT_ROOT%\*.opensdf" del /f "%PROJECT_ROOT%\*.opensdf"
if exist "%PROJECT_ROOT%\*.VC.db" del /f "%PROJECT_ROOT%\*.VC.db"
if exist "%PROJECT_ROOT%\*.VC.opendb" del /f "%PROJECT_ROOT%\*.VC.opendb"
if exist "%PROJECT_ROOT%\.vs" rmdir /s /q "%PROJECT_ROOT%\.vs"
echo Removed Visual Studio files >> %LOG_FILE%

echo.
echo ========================================================================
echo STEP 2: FIX IMGUI PLUGIN ISSUES
echo ========================================================================
echo.
echo This step ensures the ImGui plugin is compatible with UE 5.6.
echo.

echo Fixing ImGui plugin issues... >> %LOG_FILE%

rem Verify UnrealClasses.h exists
if not exist "%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\UnrealClasses.h" (
    echo Creating missing UnrealClasses.h file...
    
    if not exist "%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private" (
        mkdir "%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private"
    )
    
    (
        echo // Distributed under the MIT License (MIT) (see accompanying LICENSE file)
        echo.
        echo #pragma once
        echo.
        echo // This file includes the basic Unreal Engine classes needed by the ImGui plugin
        echo.
        echo #include "CoreMinimal.h"
        echo #include "UObject/Object.h"
        echo #include "UObject/Class.h"
        echo #include "UObject/Package.h"
        echo #include "UObject/ScriptMacros.h"
        echo #include "Containers/Array.h"
        echo #include "Containers/Map.h"
        echo #include "Containers/UnrealString.h"
        echo #include "HAL/PlatformTime.h"
        echo #include "HAL/PlatformFilemanager.h"
        echo #include "HAL/PlatformFile.h"
        echo #include "Misc/Paths.h"
        echo #include "Misc/ConfigCacheIni.h"
        echo #include "Delegates/Delegate.h"
        echo #include "GameFramework/InputSettings.h"
        echo.
        echo // Include platform-specific headers
        echo #if PLATFORM_WINDOWS
        echo #include "Windows/WindowsHWrapper.h"
        echo #endif
    ) > "%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\UnrealClasses.h"
    
    echo Created UnrealClasses.h >> %LOG_FILE%
)

rem Check and fix ImGui.uplugin module type
echo Checking ImGui.uplugin module type...
powershell -Command "(Get-Content '%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\ImGui.uplugin') -replace '\"Type\": \"Developer\"', '\"Type\": \"DeveloperTool\"' | Set-Content '%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\ImGui.uplugin'"
echo Fixed ImGui.uplugin module type >> %LOG_FILE%

echo.
echo ========================================================================
echo STEP 3: VERIFY CRITICAL FILES
echo ========================================================================
echo.
echo This step ensures all critical files have correct includes and formats.
echo.

echo Verifying critical files... >> %LOG_FILE%

rem Fix WorldContext.cpp if it exists
if exist "%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\Utilities\WorldContext.cpp" (
    echo Fixing WorldContext.cpp...
    
    powershell -Command "(Get-Content '%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\Utilities\WorldContext.cpp') | ForEach-Object { 
        if ($_ -match '#include \"ImGuiPrivatePCH.h\"') {
            \"// Distributed under the MIT License (MIT) (see accompanying LICENSE file)`r`n`r`n#include `\"ImGuiPrivatePCH.h`\"`r`n#include `\"WorldContext.h`\"`r`n`r`n// Include engine headers needed for GEngine and World Context`r`n#include `\"Engine/Engine.h`\"`r`n#include `\"Engine/World.h`\"\"
        } else {
            $_
        }
    } | Set-Content '%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\Utilities\WorldContext.cpp.new'"
    
    move /y "%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\Utilities\WorldContext.cpp.new" "%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\Utilities\WorldContext.cpp"
    echo Fixed WorldContext.cpp >> %LOG_FILE%
)

rem Fix WorldContext.h if it exists
if exist "%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\Utilities\WorldContext.h" (
    echo Fixing WorldContext.h...
    
    powershell -Command "(Get-Content '%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\Utilities\WorldContext.h') | ForEach-Object { 
        if ($_ -match '#include <Core.h>') {
            \"// Distributed under the MIT License (MIT) (see accompanying LICENSE file)`r`n`r`n#pragma once`r`n`r`n#include `\"CoreMinimal.h`\"`r`n#include `\"Engine/Engine.h`\"`r`n#include `\"Engine/GameInstance.h`\"`r`n#include `\"Engine/GameViewportClient.h`\"\"
        } elseif ($_ -match '#include <Engine.h>') {
            \"\"
        } else {
            $_
        }
    } | Set-Content '%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\Utilities\WorldContext.h.new'"
    
    move /y "%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\Utilities\WorldContext.h.new" "%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\Source\ImGui\Private\Utilities\WorldContext.h"
    echo Fixed WorldContext.h >> %LOG_FILE%
)

echo.
echo ========================================================================
echo STEP 4: REGENERATE PROJECT FILES
echo ========================================================================
echo.
echo This step regenerates the Visual Studio project files.
echo.

echo Regenerating project files... >> %LOG_FILE%

if exist "%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" (
    echo Using UnrealBuildTool to regenerate project files...
    "%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" -projectfiles -project="%PROJECT_PATH%" -game -engine -progress
    echo Regenerated project files using UnrealBuildTool >> %LOG_FILE%
) else (
    echo WARNING: UnrealBuildTool.exe not found, trying alternative method...
    echo WARNING: UnrealBuildTool.exe not found >> %LOG_FILE%
    
    if exist "%ENGINE_PATH%\Engine\Binaries\Win64\UnrealVersionSelector.exe" (
        echo Using UnrealVersionSelector to regenerate project files...
        "%ENGINE_PATH%\Engine\Binaries\Win64\UnrealVersionSelector.exe" /projectfiles "%PROJECT_PATH%"
        echo Regenerated project files using UnrealVersionSelector >> %LOG_FILE%
    ) else (
        echo ERROR: Could not find tools to regenerate project files.
        echo ERROR: Could not find tools to regenerate project files >> %LOG_FILE%
        echo Please right-click on your .uproject file and select "Generate Visual Studio project files" manually.
    )
)

echo.
echo ========================================================================
echo STEP 5: BUILD PLUGINS MANUALLY
echo ========================================================================
echo.
echo This step builds the plugins using the engine's build tools.
echo.

echo Building plugins manually... >> %LOG_FILE%

if exist "%ENGINE_PATH%\Engine\Build\BatchFiles\Build.bat" (
    echo Building ImGui plugin...
    call "%ENGINE_PATH%\Engine\Build\BatchFiles\Build.bat" ImGui Win64 Development -Plugin="%PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74\ImGui.uplugin" -TargetType=Editor
    echo Built ImGui plugin >> %LOG_FILE%
    
    echo Building InEditorCpp plugin...
    call "%ENGINE_PATH%\Engine\Build\BatchFiles\Build.bat" InEditorCpp Win64 Development -Plugin="%PROJECT_ROOT%\Plugins\InEditorCpp\InEditorCpp.uplugin" -TargetType=Editor
    echo Built InEditorCpp plugin >> %LOG_FILE%
) else (
    echo WARNING: Build.bat not found.
    echo WARNING: Build.bat not found >> %LOG_FILE%
)

echo.
echo ========================================================================
echo STEP 6: BUILD MAIN PROJECT
echo ========================================================================
echo.
echo This step builds the main project.
echo.

echo Building main project... >> %LOG_FILE%

if exist "%ENGINE_PATH%\Engine\Build\BatchFiles\Build.bat" (
    echo Building Dreamer1Editor...
    call "%ENGINE_PATH%\Engine\Build\BatchFiles\Build.bat" Dreamer1Editor Win64 Development -Project="%PROJECT_PATH%" -WaitMutex
    echo Built Dreamer1Editor >> %LOG_FILE%
) else (
    echo WARNING: Build.bat not found.
    echo WARNING: Build.bat not found >> %LOG_FILE%
)

echo.
echo ========================================================================
echo STEP 7: ATTEMPT TO LAUNCH PROJECT
echo ========================================================================
echo.
echo This step attempts to launch the project with the Unreal Editor.
echo.

echo Attempting to launch project... >> %LOG_FILE%

if exist "%ENGINE_PATH%\Engine\Binaries\Win64\UnrealEditor.exe" (
    echo Launching Unreal Editor...
    echo Please answer YES when prompted to rebuild modules.
    
    rem Launch asynchronously, don't wait for completion
    start "" "%ENGINE_PATH%\Engine\Binaries\Win64\UnrealEditor.exe" "%PROJECT_PATH%"
    echo Launched Unreal Editor >> %LOG_FILE%
) else (
    echo WARNING: UnrealEditor.exe not found.
    echo WARNING: UnrealEditor.exe not found >> %LOG_FILE%
    echo Please open the project manually.
)

echo.
echo ========================================================================
echo REBUILD PROCESS COMPLETE
echo ========================================================================
echo.
echo If you answered YES to rebuild modules when prompted by Unreal Editor,
echo your project should now be working correctly.
echo.
echo If you still encounter issues, please check the log file at:
echo %LOG_FILE%
echo.
pause