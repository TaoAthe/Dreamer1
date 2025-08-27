@echo off
:: RebuildModules_Simple.bat
:: Simple batch version that avoids PowerShell complexity

echo ========================================================================
echo                     SIMPLE MODULE REBUILD
echo ========================================================================
echo.
echo This script will rebuild Unreal Engine modules without complex PowerShell operations.
echo.

:: Set up paths
set "PROJECT_ROOT=%~dp0"
set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
set "PROJECT_PATH=%PROJECT_ROOT%\Dreamer1.uproject"

echo Project Root: %PROJECT_ROOT%
echo Project Path: %PROJECT_PATH%

:: Check if project file exists
if not exist "%PROJECT_PATH%" (
    echo ERROR: Project file not found at %PROJECT_PATH%
    pause
    exit /b 1
)

:: Get engine version from project file
echo.
echo Detecting Unreal Engine version...
for /f "tokens=2 delims=:, " %%a in ('type "%PROJECT_PATH%" ^| findstr "EngineAssociation"') do (
    set "ENGINE_VERSION=%%~a"
)
set "ENGINE_VERSION=%ENGINE_VERSION:"=%"
echo Engine Version: %ENGINE_VERSION%

:: Try to find engine
set "ENGINE_PATH="
if exist "C:\Program Files\Epic Games\UE_%ENGINE_VERSION%" (
    set "ENGINE_PATH=C:\Program Files\Epic Games\UE_%ENGINE_VERSION%"
) else if exist "C:\Epic Games\UE_%ENGINE_VERSION%" (
    set "ENGINE_PATH=C:\Epic Games\UE_%ENGINE_VERSION%"
) else if exist "C:\Program Files\Epic Games\UE_5.6" (
    set "ENGINE_PATH=C:\Program Files\Epic Games\UE_5.6"
) else if exist "C:\Program Files\Epic Games\UE_5.5" (
    set "ENGINE_PATH=C:\Program Files\Epic Games\UE_5.5"
)

if not defined ENGINE_PATH (
    echo ERROR: Could not find Unreal Engine installation.
    echo Please specify the engine path manually:
    set /p ENGINE_PATH=Engine path: 
)

if not exist "%ENGINE_PATH%" (
    echo ERROR: Engine path does not exist: %ENGINE_PATH%
    pause
    exit /b 1
)

echo Found Engine at: %ENGINE_PATH%

echo.
echo ========================================================================
echo STEP 1: Cleaning plugin directories
echo ========================================================================
echo.

:: Clean problematic plugin directories
set "PLUGINS_TO_CLEAN=%PROJECT_ROOT%\Plugins\InEditorCpp %PROJECT_ROOT%\Plugins\UnrealImGui-IMGUI_1.74"

for %%p in (%PLUGINS_TO_CLEAN%) do (
    if exist "%%p" (
        echo Cleaning plugin: %%p
        
        if exist "%%p\Binaries" (
            echo   Removing Binaries...
            rd /s /q "%%p\Binaries" 2>nul
        )
        
        if exist "%%p\Intermediate" (
            echo   Removing Intermediate...
            rd /s /q "%%p\Intermediate" 2>nul
        )
    ) else (
        echo Plugin not found: %%p
    )
)

echo.
echo ========================================================================
echo STEP 2: Cleaning project build files
echo ========================================================================
echo.

:: Clean project build files
if exist "%PROJECT_ROOT%\Binaries" (
    echo Cleaning project Binaries...
    rd /s /q "%PROJECT_ROOT%\Binaries" 2>nul
)

if exist "%PROJECT_ROOT%\Intermediate" (
    echo Cleaning project Intermediate...
    rd /s /q "%PROJECT_ROOT%\Intermediate" 2>nul
)

:: Remove solution and project files
echo Removing generated project files...
del "%PROJECT_ROOT%\*.sln" 2>nul
del "%PROJECT_ROOT%\*.vcxproj*" 2>nul

echo.
echo ========================================================================
echo STEP 3: Regenerating project files
echo ========================================================================
echo.

:: Try UnrealVersionSelector first
set "UVS_PATH=%ENGINE_PATH%\Engine\Binaries\Win64\UnrealVersionSelector.exe"
if exist "%UVS_PATH%" (
    echo Using UnrealVersionSelector to generate project files...
    "%UVS_PATH%" /projectfiles "%PROJECT_PATH%"
    
    if %ERRORLEVEL% EQU 0 (
        echo SUCCESS: Project files generated successfully!
    ) else (
        echo WARNING: UnrealVersionSelector returned error code %ERRORLEVEL%
    )
) else (
    echo WARNING: UnrealVersionSelector not found at %UVS_PATH%
)

:: Try UnrealBuildTool as fallback
set "UBT_PATH=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
if not exist "%UBT_PATH%" (
    set "UBT_PATH=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool.exe"
)

if exist "%UBT_PATH%" (
    echo.
    echo Using UnrealBuildTool as fallback...
    echo Command: "%UBT_PATH%" -projectfiles -project="%PROJECT_PATH%" -game -engine -progress
    
    "%UBT_PATH%" -projectfiles -project="%PROJECT_PATH%" -game -engine -progress
    
    if %ERRORLEVEL% EQU 0 (
        echo SUCCESS: UBT project file generation completed!
    ) else (
        echo WARNING: UBT returned error code %ERRORLEVEL%
    )
) else (
    echo ERROR: Could not find UnrealBuildTool at expected locations
    echo   - %ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe
    echo   - %ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool.exe
)

echo.
echo ========================================================================
echo STEP 4: Building editor target
echo ========================================================================
echo.

:: Try to build the editor target
if exist "%UBT_PATH%" (
    echo Building Dreamer1Editor target...
    echo Command: "%UBT_PATH%" Dreamer1Editor Win64 Development -Project="%PROJECT_PATH%" -WaitMutex
    
    "%UBT_PATH%" Dreamer1Editor Win64 Development -Project="%PROJECT_PATH%" -WaitMutex
    
    if %ERRORLEVEL% EQU 0 (
        echo SUCCESS: Editor target built successfully!
    ) else (
        echo WARNING: Editor build returned error code %ERRORLEVEL%
        echo This might be normal if there are minor issues.
    )
) else (
    echo Skipping editor build - UnrealBuildTool not found
)

echo.
echo ========================================================================
echo REBUILD COMPLETED
echo ========================================================================
echo.

echo Module rebuild process completed.
echo.
echo Next steps:
echo 1. Try opening the project in Unreal Engine
echo 2. If prompted to rebuild modules, accept the rebuild
echo 3. If errors persist, check the Engine logs for specific issues
echo.

pause