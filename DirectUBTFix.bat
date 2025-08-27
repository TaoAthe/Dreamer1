@echo off
:: DirectUBTFix.bat
:: This script specifically targets the "could not fetch all available targets" error
:: with a direct, focused approach based on the most common root causes.

echo ========================================================================
echo                DIRECT FIX FOR UBT TARGET ERROR
echo ========================================================================
echo.
echo This script will perform targeted fixes for the "could not fetch all the
echo available targets from the unreal build tool" error.
echo.
echo Please close Unreal Engine and Visual Studio before continuing.
echo.
pause

:: Create a timestamp for log file
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "TIMESTAMP=%dt:~0,8%_%dt:~8,6%"
set "LOG_FILE=%~dp0DirectUBTFix_%TIMESTAMP%.log"

echo Starting Direct UBT Fix at %date% %time% > "%LOG_FILE%"

:: Get project path
set "PROJECT_ROOT=%~dp0"
set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
set "PROJECT_PATH=%PROJECT_ROOT%\Dreamer1.uproject"

echo Project Root: %PROJECT_ROOT% >> "%LOG_FILE%"
echo Project Path: %PROJECT_PATH% >> "%LOG_FILE%"

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
echo Engine Version: %ENGINE_VERSION% >> "%LOG_FILE%"

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
    echo Failed to locate Unreal Engine >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo Found Engine at: %ENGINE_PATH% >> "%LOG_FILE%"
echo Found Unreal Engine at: %ENGINE_PATH%

echo.
echo ========================================================================
echo STEP 2: Applying Critical Fixes
echo ========================================================================
echo.

:: 1. Fix #1: Remove potentially corrupted build files
echo Removing potentially corrupted build files...
echo Removing potentially corrupted build files... >> "%LOG_FILE%"

if exist "%PROJECT_ROOT%\Intermediate\Build\BuildRules" (
    echo Removing BuildRules directory...
    rd /s /q "%PROJECT_ROOT%\Intermediate\Build\BuildRules"
    echo Removed BuildRules directory >> "%LOG_FILE%"
)

:: Remove any .binaries.txt files
echo Removing .binaries.txt files...
del /s /q "%PROJECT_ROOT%\*.binaries.txt" 2>nul
echo Removed .binaries.txt files >> "%LOG_FILE%"

:: 2. Fix #2: Recreate project cache files
echo Recreating project cache files...
echo Recreating project cache files... >> "%LOG_FILE%"

if exist "%PROJECT_ROOT%\Saved\Config" (
    echo Removing cached configurations...
    rd /s /q "%PROJECT_ROOT%\Saved\Config"
    echo Removed cached configurations >> "%LOG_FILE%"
)

:: 3. Fix #3: Verify plugins are correctly referenced in project file
echo Checking plugin references in project file...
echo Checking plugin references in project file... >> "%LOG_FILE%"

:: Create a temporary directory for plugin fixes
mkdir "%PROJECT_ROOT%\Temp_Plugin_Fix" 2>nul

:: Extract the Plugins section from the uproject file
type "%PROJECT_PATH%" | findstr /C:"Plugins" /C:"Name" /C:"Enabled" > "%PROJECT_ROOT%\Temp_Plugin_Fix\plugins_section.txt"

:: Check for the required plugins
set FOUND_SOURCE_ACCESS=0
set FOUND_VS_TOOLS=0
set FOUND_IN_EDITOR_CPP=0

findstr /C:"SourceCodeAccess" "%PROJECT_ROOT%\Temp_Plugin_Fix\plugins_section.txt" >nul 2>&1
if not errorlevel 1 set FOUND_SOURCE_ACCESS=1

findstr /C:"VisualStudioTools" "%PROJECT_ROOT%\Temp_Plugin_Fix\plugins_section.txt" >nul 2>&1
if not errorlevel 1 set FOUND_VS_TOOLS=1

findstr /C:"InEditorCpp" "%PROJECT_ROOT%\Temp_Plugin_Fix\plugins_section.txt" >nul 2>&1
if not errorlevel 1 set FOUND_IN_EDITOR_CPP=1

echo Found SourceCodeAccess: %FOUND_SOURCE_ACCESS% >> "%LOG_FILE%"
echo Found VisualStudioTools: %FOUND_VS_TOOLS% >> "%LOG_FILE%"
echo Found InEditorCpp: %FOUND_IN_EDITOR_CPP% >> "%LOG_FILE%"

:: Create a PowerShell script to fix the project file
echo Creating PowerShell fix script...
echo Creating PowerShell fix script... >> "%LOG_FILE%"

echo $projectFile = Get-Content "%PROJECT_PATH%" -Raw ^| ConvertFrom-Json > "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
echo $needsSave = $false >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"

if %FOUND_SOURCE_ACCESS% EQU 0 (
    echo echo "Adding SourceCodeAccess plugin..." >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
    echo $sourceCodePlugin = @{ Name = "SourceCodeAccess"; Enabled = $true } >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
    echo $projectFile.Plugins += $sourceCodePlugin >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
    echo $needsSave = $true >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
)

if %FOUND_VS_TOOLS% EQU 0 (
    echo echo "Adding VisualStudioTools plugin..." >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
    echo $vsToolsPlugin = @{ Name = "VisualStudioTools"; Enabled = $true; SupportedTargetPlatforms = @("Win64") } >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
    echo $projectFile.Plugins += $vsToolsPlugin >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
    echo $needsSave = $true >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
)

if %FOUND_IN_EDITOR_CPP% EQU 0 (
    echo echo "Adding InEditorCpp plugin..." >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
    echo $inEditorPlugin = @{ Name = "InEditorCpp"; Enabled = $true } >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
    echo $projectFile.Plugins += $inEditorPlugin >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
    echo $needsSave = $true >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
)

echo if ($needsSave) { >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
echo     $projectFile ^| ConvertTo-Json -Depth 10 ^| Set-Content "%PROJECT_PATH%" >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
echo     echo "Updated project file with missing plugins." >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
echo } else { >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
echo     echo "Project file already has all required plugins." >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"
echo } >> "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1"

:: Run the PowerShell script
echo Running PowerShell fix script...
powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\Temp_Plugin_Fix\fix_project.ps1" >> "%LOG_FILE%" 2>&1

:: 4. Fix #4: Create registry entries if missing
echo Creating/updating registry entries...
echo Creating/updating registry entries... >> "%LOG_FILE%"

reg add "HKLM\SOFTWARE\EpicGames\Unreal Engine\%ENGINE_VERSION%" /v "InstalledDirectory" /t REG_SZ /d "%ENGINE_PATH%" /f >> "%LOG_FILE%" 2>&1
reg add "HKCU\SOFTWARE\EpicGames\Unreal Engine\%ENGINE_VERSION%" /v "InstalledDirectory" /t REG_SZ /d "%ENGINE_PATH%" /f >> "%LOG_FILE%" 2>&1

:: 5. Fix #5: Fix dotnet environment
echo Setting up .NET environment...
echo Setting up .NET environment... >> "%LOG_FILE%"

set "DOTNET_ROOT=%ENGINE_PATH%\Engine\Binaries\ThirdParty\DotNet\Win64"
set "PATH=%DOTNET_ROOT%;%PATH%"
set "DOTNET_CLI_TELEMETRY_OPTOUT=1"
set "DOTNET_NOLOGO=1"
set "DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1"

echo DOTNET_ROOT set to: %DOTNET_ROOT% >> "%LOG_FILE%"

echo.
echo ========================================================================
echo STEP 3: Performing Direct Build Tool Repair
echo ========================================================================
echo.

:: Create a special batch file that properly sets up the environment for UBT
echo Creating special UBT environment...
echo Creating special UBT environment... >> "%LOG_FILE%"

:: Find UBT binary
set "UBT_BINARY=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
if not exist "%UBT_BINARY%" (
    set "UBT_BINARY=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool.exe"
)

echo UBT binary: %UBT_BINARY% >> "%LOG_FILE%"

:: Create a special environment batch file
echo @echo off > "%PROJECT_ROOT%\RepairUBT.bat"
echo setlocal enabledelayedexpansion >> "%PROJECT_ROOT%\RepairUBT.bat"
echo. >> "%PROJECT_ROOT%\RepairUBT.bat"
echo echo Setting up environment for Unreal Build Tool... >> "%PROJECT_ROOT%\RepairUBT.bat"
echo. >> "%PROJECT_ROOT%\RepairUBT.bat"
echo set "UE_ENGINE_DIRECTORY=%ENGINE_PATH%" >> "%PROJECT_ROOT%\RepairUBT.bat"
echo set "UE_PROJECT_PATH=%PROJECT_PATH%" >> "%PROJECT_ROOT%\RepairUBT.bat"
echo set "UE_PROJECT_NAME=Dreamer1" >> "%PROJECT_ROOT%\RepairUBT.bat"
echo set "DOTNET_ROOT=%DOTNET_ROOT%" >> "%PROJECT_ROOT%\RepairUBT.bat"
echo set "PATH=%%DOTNET_ROOT%%;%%PATH%%" >> "%PROJECT_ROOT%\RepairUBT.bat"
echo set "DOTNET_CLI_TELEMETRY_OPTOUT=1" >> "%PROJECT_ROOT%\RepairUBT.bat"
echo set "DOTNET_NOLOGO=1" >> "%PROJECT_ROOT%\RepairUBT.bat"
echo set "DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1" >> "%PROJECT_ROOT%\RepairUBT.bat"
echo. >> "%PROJECT_ROOT%\RepairUBT.bat"
echo echo Environment set up. Running UBT to regenerate project files... >> "%PROJECT_ROOT%\RepairUBT.bat"
echo. >> "%PROJECT_ROOT%\RepairUBT.bat"
echo "%UBT_BINARY%" -projectfiles -project="%%UE_PROJECT_PATH%%" -game -engine -progress >> "%PROJECT_ROOT%\RepairUBT.bat"
echo. >> "%PROJECT_ROOT%\RepairUBT.bat"
echo echo Attempting to fetch targets... >> "%PROJECT_ROOT%\RepairUBT.bat"
echo. >> "%PROJECT_ROOT%\RepairUBT.bat"
echo "%UBT_BINARY%" -Mode=QueryTargets -Project="%%UE_PROJECT_PATH%%" -TargetPlatform=Win64 -BuildConfiguration=Development >> "%PROJECT_ROOT%\RepairUBT.bat"
echo. >> "%PROJECT_ROOT%\RepairUBT.bat"
echo echo Building project... >> "%PROJECT_ROOT%\RepairUBT.bat"
echo. >> "%PROJECT_ROOT%\RepairUBT.bat"
echo "%ENGINE_PATH%\Engine\Build\BatchFiles\Build.bat" Dreamer1Editor Win64 Development -Project="%%UE_PROJECT_PATH%%" -WaitMutex >> "%PROJECT_ROOT%\RepairUBT.bat"
echo. >> "%PROJECT_ROOT%\RepairUBT.bat"
echo echo Repair completed. >> "%PROJECT_ROOT%\RepairUBT.bat"
echo pause >> "%PROJECT_ROOT%\RepairUBT.bat"

echo Created RepairUBT.bat >> "%LOG_FILE%"

:: 6. Fix #6: Create DLL bypass for UBT
echo Setting up DLL bypass for UBT...
echo Setting up DLL bypass for UBT... >> "%LOG_FILE%"

:: Create a special bypass for common UBT DLL loading issues
mkdir "%PROJECT_ROOT%\FixDLLs" 2>nul

:: Create PowerShell script to create assembly binding redirects
echo Creating assembly binding redirects...
echo $content = @" > "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo ^<?xml version="1.0" encoding="utf-8"?^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo ^<configuration^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo   ^<runtime^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo     ^<assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1"^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^<dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<assemblyIdentity name="System.Runtime" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^</dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^<dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<assemblyIdentity name="System.Collections" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^</dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^<dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<assemblyIdentity name="System.IO" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^</dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^<dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<assemblyIdentity name="System.Xml" publicKeyToken="b77a5c561934e089" culture="neutral" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^</dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^<dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<assemblyIdentity name="System.Xml.Linq" publicKeyToken="b77a5c561934e089" culture="neutral" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^</dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^<dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<assemblyIdentity name="System.CodeDom" publicKeyToken="cc7b13ffcd2ddd51" culture="neutral" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo         ^<bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" /^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo       ^</dependentAssembly^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo     ^</assemblyBinding^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo   ^</runtime^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo ^</configuration^> >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo "@ >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo. >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo # Save to UBT directory >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo $ubtDirectory = [System.IO.Path]::GetDirectoryName('%UBT_BINARY%') >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo $configPath = [System.IO.Path]::Combine($ubtDirectory, "UnrealBuildTool.exe.config") >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo Write-Host "Creating binding redirects at: $configPath" >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo $content | Out-File -FilePath $configPath -Encoding UTF8 >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"
echo Write-Host "Created binding redirects" >> "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1"

:: Run the PowerShell script
echo Running PowerShell binding redirects script...
powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\FixDLLs\create_binding_redirects.ps1" >> "%LOG_FILE%" 2>&1

echo.
echo ========================================================================
echo STEP 4: Executing Repair
echo ========================================================================
echo.

echo Running RepairUBT.bat...
echo Running RepairUBT.bat... >> "%LOG_FILE%"
call "%PROJECT_ROOT%\RepairUBT.bat" >> "%LOG_FILE%" 2>&1

echo.
echo ========================================================================
echo STEP 5: Final Verification
echo ========================================================================
echo.

:: Create a verification script to check if the error is fixed
echo @echo off > "%PROJECT_ROOT%\Verify_Fix.bat"
echo setlocal enabledelayedexpansion >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo echo Verifying if the target error is fixed... >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo set "UE_ENGINE_DIRECTORY=%ENGINE_PATH%" >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo set "UE_PROJECT_PATH=%PROJECT_PATH%" >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo set "DOTNET_ROOT=%DOTNET_ROOT%" >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo set "PATH=%%DOTNET_ROOT%%;%%PATH%%" >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo set "DOTNET_CLI_TELEMETRY_OPTOUT=1" >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo set "DOTNET_NOLOGO=1" >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo set "DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1" >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo "%UBT_BINARY%" -Mode=QueryTargets -Project="%%UE_PROJECT_PATH%%" -TargetPlatform=Win64 -BuildConfiguration=Development > "%PROJECT_ROOT%\target_verification.txt" 2>&1 >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo findstr /C:"could not fetch all" "%PROJECT_ROOT%\target_verification.txt" >nul 2>&1 >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo if not errorlevel 1 ( >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo     echo. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo     echo ERROR: The target error still persists. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo     echo Please run the DiagnoseUBTIssue.bat script for more detailed diagnostics. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo     echo. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo ) else ( >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo     echo. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo     echo SUCCESS: The target error appears to be fixed! >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo     echo You can now try opening your project in Unreal Engine. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo     echo. >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo ) >> "%PROJECT_ROOT%\Verify_Fix.bat"
echo pause >> "%PROJECT_ROOT%\Verify_Fix.bat"

echo Created verification script
echo Created verification script >> "%LOG_FILE%"

:: Run the verification script
echo Running verification...
call "%PROJECT_ROOT%\Verify_Fix.bat" >> "%LOG_FILE%" 2>&1

:: Clean up temporary files
if exist "%PROJECT_ROOT%\Temp_Plugin_Fix" (
    rd /s /q "%PROJECT_ROOT%\Temp_Plugin_Fix"
)

echo.
echo ========================================================================
echo DIRECT FIX COMPLETED
echo ========================================================================
echo.
echo The direct fix process has been completed. 
echo.
echo If the verification showed success, you can now try opening your project
echo in Unreal Engine. If the issue persists, please run the DiagnoseUBTIssue.bat
echo script for more detailed diagnostics.
echo.
echo A log file has been created at:
echo %LOG_FILE%
echo.
pause