@echo off
echo Rebuilding Unreal Engine modules...

set PROJECT_PATH=C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Dreamer1.uproject

rem Get the Unreal Engine path from the project file
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content '%PROJECT_PATH%' | ConvertFrom-Json).EngineAssociation"') do set ENGINE_VERSION=%%a

rem Check if we got a version number or a GUID
echo Detected Engine Version: %ENGINE_VERSION%

rem Try to locate the engine
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

rem Clean problematic plugin build artifacts
echo Cleaning plugin build artifacts...
if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp\Binaries" (
    echo Removing InEditorCpp binaries...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp\Binaries"
)
if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp\Intermediate" (
    echo Removing InEditorCpp intermediate files...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp\Intermediate"
)
if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Binaries" (
    echo Removing ImGui binaries...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Binaries"
)
if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Intermediate" (
    echo Removing ImGui intermediate files...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Intermediate"
)

rem Remove any temporary build files from previous attempts
if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\BuiltPlugins" (
    echo Removing previous BuiltPlugins directory...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\BuiltPlugins"
)

rem Check for the specific plugin files
set IN_EDITOR_UPLUGIN=
set IMGUI_UPLUGIN=

for /r "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp" %%f in (*.uplugin) do (
    echo Found InEditorCpp plugin: %%f
    set IN_EDITOR_UPLUGIN=%%f
)

for /r "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74" %%f in (*.uplugin) do (
    echo Found ImGui plugin: %%f
    set IMGUI_UPLUGIN=%%f
)

rem Try to build using the Visual Studio developer command prompt
where /q devenv
if %ERRORLEVEL% EQU 0 (
    echo Using Visual Studio to build the project...
    echo Generating project files...
    "%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" -projectfiles -project="%PROJECT_PATH%" -game -engine
    
    echo Opening the solution in Visual Studio...
    for /r "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1" %%f in (Dreamer1.sln) do (
        devenv "%%f" /Build "Development Editor|x64"
    )
)

rem Check for the UnrealVersionSelector executable as a fallback
set UVS_PATH=%ENGINE_PATH%\Engine\Binaries\Win64\UnrealVersionSelector.exe
if exist "%UVS_PATH%" (
    echo Found UnrealVersionSelector at: %UVS_PATH%
    echo Using UnrealVersionSelector to rebuild the project...
    
    rem Use UnrealVersionSelector to generate project files
    "%UVS_PATH%" /projectfiles "%PROJECT_PATH%"
    
    rem Try calling directly with Build.bat which has proper environment setup
    if exist "%ENGINE_PATH%\Engine\Build\BatchFiles\Build.bat" (
        echo Using Build.bat to build Development Editor...
        call "%ENGINE_PATH%\Engine\Build\BatchFiles\Build.bat" Dreamer1Editor Win64 Development -Project="%PROJECT_PATH%" -WaitMutex -FromMsBuild
    )
) else (
    echo WARNING: UnrealVersionSelector not found. Falling back to alternative methods.
)

rem Try directly compiling the plugins using Unreal's MSBuild command
echo Trying direct plugin compilation with MSBuild...
if exist "%ENGINE_PATH%\Engine\Build\BatchFiles\MSBuild.bat" (
    echo Found MSBuild.bat, using it for plugin compilation...
    
    rem Compile InEditorCpp plugin
    if defined IN_EDITOR_UPLUGIN (
        echo Compiling InEditorCpp plugin with MSBuild...
        call "%ENGINE_PATH%\Engine\Build\BatchFiles\MSBuild.bat" "%IN_EDITOR_UPLUGIN%" /target:Build /property:Configuration=Development /property:Platform=Win64
    ) else (
        echo WARNING: Could not find InEditorCpp.uplugin
    )
    
    rem Compile ImGui plugin
    if defined IMGUI_UPLUGIN (
        echo Compiling ImGui plugin with MSBuild...
        call "%ENGINE_PATH%\Engine\Build\BatchFiles\MSBuild.bat" "%IMGUI_UPLUGIN%" /target:Build /property:Configuration=Development /property:Platform=Win64
    ) else (
        echo WARNING: Could not find ImGui.uplugin
    )
)

rem As a last resort, try using RunUAT.bat
if exist "%ENGINE_PATH%\Engine\Build\BatchFiles\RunUAT.bat" (
    echo Using RunUAT.bat to build the plugins...
    
    if defined IN_EDITOR_UPLUGIN (
        echo Building InEditorCpp plugin...
        call "%ENGINE_PATH%\Engine\Build\BatchFiles\RunUAT.bat" BuildPlugin -Plugin="%IN_EDITOR_UPLUGIN%" -Package="C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\BuiltPlugins\InEditorCpp" -Rocket
    ) else (
        echo WARNING: Could not find InEditorCpp.uplugin
    )
    
    if defined IMGUI_UPLUGIN (
        echo Building ImGui plugin...
        call "%ENGINE_PATH%\Engine\Build\BatchFiles\RunUAT.bat" BuildPlugin -Plugin="%IMGUI_UPLUGIN%" -Package="C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\BuiltPlugins\ImGui" -Rocket
    ) else (
        echo WARNING: Could not find ImGui.uplugin
    )
) else (
    echo ERROR: Cannot find appropriate build tools. Please rebuild the project from the Unreal Editor.
)

echo.
echo Build process completed. Check the output for any errors.
echo You can now try opening the project again.
echo.
echo NOTE: If you still see rebuilding errors in Unreal Editor, please accept the rebuild prompt
echo when the engine offers it. This is often the most reliable way to rebuild modules.
pause