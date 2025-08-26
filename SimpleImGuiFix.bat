@echo off
echo Simple ImGui plugin fix for UE 5.6...

set PROJECT_PATH=C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Dreamer1.uproject

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

rem Clean ImGui plugin build artifacts
echo Cleaning ImGui plugin build artifacts...
if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Binaries" (
    echo Removing ImGui binaries...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Binaries"
)
if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Intermediate" (
    echo Removing ImGui intermediate files...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Intermediate"
)

rem Simplest approach: Use UE4Editor directly to compile the plugin
echo Starting Unreal Editor to compile the plugin...
"%ENGINE_PATH%\Engine\Binaries\Win64\UnrealEditor.exe" "%PROJECT_PATH%" -skipcompile

echo.
echo Plugin fix attempt completed.
echo Now try opening your project normally in the Unreal Editor.
echo When prompted to rebuild modules, select "Yes".
pause