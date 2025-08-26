@echo off
echo Fixing ImGui plugin for UE 5.6...

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

rem Find UE installation
set PROJECT_PATH=C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Dreamer1.uproject
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

rem Run the game launcher which may help with plugin regeneration
echo Opening game launcher to recompile the plugin...
start "" "%ENGINE_PATH%\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" "%PROJECT_PATH%" -run=CompileAllBlueprints -buildmode=Build -SkipCompile -NoSave

echo.
echo Fix process completed.
echo You should now be able to open the project in Unreal Editor.
echo When prompted to rebuild modules, select "Yes".
pause