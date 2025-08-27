@echo off
:: RunUBTVerbose.bat
:: This script runs UnrealBuildTool with verbose logging to help diagnose build issues

echo ========================================================================
echo                     VERBOSE UBT BUILD SCRIPT
echo ========================================================================
echo.
echo This script will run UnrealBuildTool with verbose logging enabled.
echo The log will be saved to UBT.log for detailed analysis.
echo.

:: Set up paths
set "PROJECT_ROOT=%~dp0"
set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
set "PROJECT_PATH=%PROJECT_ROOT%\Dreamer1.uproject"

echo Project Root: %PROJECT_ROOT%
echo Project Path: %PROJECT_PATH%

:: Find Unreal Engine path
echo.
echo ========================================================================
echo STEP 1: Locating Unreal Engine
echo ========================================================================
echo.

:: Get engine association from .uproject file
for /f "tokens=2 delims=:, " %%a in ('type "%PROJECT_PATH%" ^| findstr "EngineAssociation"') do (
    set "ENGINE_VERSION=%%~a"
)

:: Remove quotes if present
set "ENGINE_VERSION=%ENGINE_VERSION:"=%"
echo Engine Version: %ENGINE_VERSION%

:: Try to find engine in registry
set "ENGINE_PATH="
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine\%ENGINE_VERSION%" /v "InstalledDirectory" 2^>nul') do (
    set "ENGINE_PATH=%%b"
)

if not defined ENGINE_PATH (
    :: Try common locations
    if exist "C:\Program Files\Epic Games\UE_%ENGINE_VERSION%" (
        set "ENGINE_PATH=C:\Program Files\Epic Games\UE_%ENGINE_VERSION%"
    ) else if exist "C:\Epic Games\UE_%ENGINE_VERSION%" (
        set "ENGINE_PATH=C:\Epic Games\UE_%ENGINE_VERSION%"
    ) else if exist "C:\Program Files\Epic Games\UE_5.6" (
        set "ENGINE_PATH=C:\Program Files\Epic Games\UE_5.6"
    ) else if exist "C:\Program Files\Epic Games\UE_5.5" (
        set "ENGINE_PATH=C:\Program Files\Epic Games\UE_5.5"
    ) else if exist "C:\Program Files\Epic Games\UE_5.4" (
        set "ENGINE_PATH=C:\Program Files\Epic Games\UE_5.4"
    )
)

if not defined ENGINE_PATH (
    echo ERROR: Could not locate Unreal Engine installation.
    echo Please specify the engine path manually:
    set /p ENGINE_PATH=Engine path: 
)

if not exist "%ENGINE_PATH%" (
    echo ERROR: Specified engine path does not exist.
    pause
    exit /b 1
)

echo Found Engine at: %ENGINE_PATH%

:: Set UBT path
set "UBT_BINARY=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
if not exist "%UBT_BINARY%" (
    set "UBT_BINARY=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool.exe"
)

if not exist "%UBT_BINARY%" (
    echo ERROR: Could not find UnrealBuildTool.exe
    pause
    exit /b 1
)

echo UBT Binary: %UBT_BINARY%

echo.
echo ========================================================================
echo STEP 2: Setting up environment
echo ========================================================================
echo.

:: Set up .NET environment
set "DOTNET_ROOT=%ENGINE_PATH%\Engine\Binaries\ThirdParty\DotNet\Win64"
set "PATH=%DOTNET_ROOT%;%PATH%"
set "DOTNET_CLI_TELEMETRY_OPTOUT=1"
set "DOTNET_NOLOGO=1"
set "DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1"

echo DOTNET_ROOT: %DOTNET_ROOT%

echo.
echo ========================================================================
echo STEP 3: Running UBT with Verbose Logging
echo ========================================================================
echo.

:: Create log directory if it doesn't exist
if not exist "%PROJECT_ROOT%\Logs" (
    mkdir "%PROJECT_ROOT%\Logs"
)

set "LOG_FILE=%PROJECT_ROOT%\Logs\UBT.log"
set "TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMPED_LOG=%PROJECT_ROOT%\Logs\UBT_%TIMESTAMP%.log"

echo Log file: %LOG_FILE%
echo Timestamped log: %TIMESTAMPED_LOG%

echo.
echo Running UBT commands with verbose logging...
echo.

:: Command 1: Query targets with verbose logging
echo ----------------------------------------
echo Command 1: Querying available targets
echo ----------------------------------------
echo "%UBT_BINARY%" -Mode=QueryTargets -Project="%PROJECT_PATH%" -TargetPlatform=Win64 -BuildConfiguration=Development -Verbose -Log="%LOG_FILE%"
echo.

"%UBT_BINARY%" -Mode=QueryTargets -Project="%PROJECT_PATH%" -TargetPlatform=Win64 -BuildConfiguration=Development -Verbose -Log="%LOG_FILE%" > "%TIMESTAMPED_LOG%" 2>&1
set "QUERY_RESULT=%ERRORLEVEL%"

echo Query targets result: %QUERY_RESULT%
echo.

:: Command 2: Generate project files with verbose logging
echo ----------------------------------------
echo Command 2: Generating project files
echo ----------------------------------------
echo "%UBT_BINARY%" -projectfiles -project="%PROJECT_PATH%" -game -engine -progress -Verbose -Log="%LOG_FILE%"
echo.

"%UBT_BINARY%" -projectfiles -project="%PROJECT_PATH%" -game -engine -progress -Verbose -Log="%LOG_FILE%" >> "%TIMESTAMPED_LOG%" 2>&1
set "PROJECTFILES_RESULT=%ERRORLEVEL%"

echo Generate project files result: %PROJECTFILES_RESULT%
echo.

:: Command 3: Build with verbose logging
echo ----------------------------------------
echo Command 3: Building Dreamer1Editor
echo ----------------------------------------
echo "%UBT_BINARY%" Dreamer1Editor Win64 Development -Project="%PROJECT_PATH%" -WaitMutex -Verbose -Log="%LOG_FILE%"
echo.

"%UBT_BINARY%" Dreamer1Editor Win64 Development -Project="%PROJECT_PATH%" -WaitMutex -Verbose -Log="%LOG_FILE%" >> "%TIMESTAMPED_LOG%" 2>&1
set "BUILD_RESULT=%ERRORLEVEL%"

echo Build result: %BUILD_RESULT%
echo.

:: Command 4: List build options for diagnostics
echo ----------------------------------------
echo Command 4: Listing build options
echo ----------------------------------------
echo "%UBT_BINARY%" -ListBuildOptions -Verbose -Log="%LOG_FILE%"
echo.

"%UBT_BINARY%" -ListBuildOptions -Verbose -Log="%LOG_FILE%" >> "%TIMESTAMPED_LOG%" 2>&1
set "LISTOPTIONS_RESULT=%ERRORLEVEL%"

echo List build options result: %LISTOPTIONS_RESULT%
echo.

echo.
echo ========================================================================
echo VERBOSE UBT BUILD COMPLETED
echo ========================================================================
echo.

echo Results Summary:
echo   Query Targets:       Exit Code %QUERY_RESULT%
echo   Generate Projects:   Exit Code %PROJECTFILES_RESULT%
echo   Build Editor:        Exit Code %BUILD_RESULT%
echo   List Build Options:  Exit Code %LISTOPTIONS_RESULT%
echo.

if %QUERY_RESULT% NEQ 0 (
    echo WARNING: Query targets failed with exit code %QUERY_RESULT%
)

if %PROJECTFILES_RESULT% NEQ 0 (
    echo WARNING: Generate project files failed with exit code %PROJECTFILES_RESULT%
)

if %BUILD_RESULT% NEQ 0 (
    echo WARNING: Build failed with exit code %BUILD_RESULT%
)

if %LISTOPTIONS_RESULT% NEQ 0 (
    echo WARNING: List build options failed with exit code %LISTOPTIONS_RESULT%
)

echo.
echo Detailed logs have been saved to:
echo   Main log: %LOG_FILE%
echo   Timestamped log: %TIMESTAMPED_LOG%
echo.

:: Open the log file in notepad for immediate review
if exist "%TIMESTAMPED_LOG%" (
    echo Opening log file for review...
    start notepad "%TIMESTAMPED_LOG%"
)

echo.
echo Script completed. Press any key to exit.
pause