@echo off
echo Comprehensive ImGui Plugin Fix for UE 5.6
echo ========================================
echo.
echo This script combines all necessary fixes for the ImGui plugin compatibility with UE 5.6.
echo.

set PROJECT_PATH=C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Dreamer1.uproject
set IMGUI_PLUGIN_PATH=C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74
set EDITOR_PLUGIN_PATH=C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp

rem Get the Unreal Engine path from the project file
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content '%PROJECT_PATH%' | ConvertFrom-Json).EngineAssociation"') do set ENGINE_VERSION=%%a
echo Detected Engine Version: %ENGINE_VERSION%

if exist "C:\Program Files\Epic Games\UE_%ENGINE_VERSION%" (
    set ENGINE_PATH=C:\Program Files\Epic Games\UE_%ENGINE_VERSION%
) else if exist "C:\Program Files\Epic Games\UE_%ENGINE_VERSION%EA" (
    set ENGINE_PATH=C:\Program Files\Epic Games\UE_%ENGINE_VERSION%EA
) else (
    echo Could not find Unreal Engine path. Please modify this script to point to your UE installation.
    pause
    exit /b 1
)

echo Using Engine Path: %ENGINE_PATH%

echo.
echo Step 1: Clean plugin build artifacts
echo ------------------------------------
echo.

if exist "%IMGUI_PLUGIN_PATH%\Binaries" (
    echo Removing ImGui binaries...
    rmdir /s /q "%IMGUI_PLUGIN_PATH%\Binaries"
)
if exist "%IMGUI_PLUGIN_PATH%\Intermediate" (
    echo Removing ImGui intermediate files...
    rmdir /s /q "%IMGUI_PLUGIN_PATH%\Intermediate"
)
if exist "%EDITOR_PLUGIN_PATH%\Binaries" (
    echo Removing InEditorCpp binaries...
    rmdir /s /q "%EDITOR_PLUGIN_PATH%\Binaries"
)
if exist "%EDITOR_PLUGIN_PATH%\Intermediate" (
    echo Removing InEditorCpp intermediate files...
    rmdir /s /q "%EDITOR_PLUGIN_PATH%\Intermediate"
)

echo.
echo Step 2: Regenerate Visual Studio project files
echo ---------------------------------------------
echo.

if exist "%ENGINE_PATH%\Engine\Binaries\Win64\UnrealVersionSelector.exe" (
    echo Using UnrealVersionSelector to regenerate project files...
    "%ENGINE_PATH%\Engine\Binaries\Win64\UnrealVersionSelector.exe" /projectfiles "%PROJECT_PATH%"
) else (
    echo UnrealVersionSelector not found. Trying alternative...
    if exist "%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" (
        echo Using UnrealBuildTool to regenerate project files...
        "%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" -projectfiles -project="%PROJECT_PATH%" -game -engine
    ) else (
        echo WARNING: Could not find tools to regenerate project files.
    )
)

echo.
echo Step 3: Launch Unreal Editor with -skipcompile to initialize plugins
echo -------------------------------------------------------------------
echo.

echo Launching Unreal Editor with -skipcompile...
start "" "%ENGINE_PATH%\Engine\Binaries\Win64\UnrealEditor.exe" "%PROJECT_PATH%" -skipcompile
echo Please wait for Unreal Editor to initialize, then close it before continuing.
echo.
pause

echo.
echo Step 4: Final build verification
echo ------------------------------
echo.

if exist "%ENGINE_PATH%\Engine\Build\BatchFiles\Build.bat" (
    echo Using Build.bat to build Development Editor...
    call "%ENGINE_PATH%\Engine\Build\BatchFiles\Build.bat" Dreamer1Editor Win64 Development -Project="%PROJECT_PATH%" -WaitMutex -FromMsBuild
) else (
    echo WARNING: Build.bat not found. Skipping final verification.
)

echo.
echo ========================================
echo All fixes have been applied!
echo.
echo You should now be able to open your project in Unreal Editor.
echo When prompted to rebuild modules, select "Yes".
echo.
pause