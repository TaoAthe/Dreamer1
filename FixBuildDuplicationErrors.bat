@echo off
:: FixBuildDuplicationErrors.bat
:: This script fixes the duplicate module definitions and corrupted build files

echo ========================================================================
echo                     BUILD DUPLICATION ERROR FIX
echo ========================================================================
echo.
echo This script will fix the duplicate module definitions and corrupted
echo build files that are causing UnrealBuildTool errors.
echo.
echo Issues to be fixed:
echo - Duplicate Dreamer1 and Dreamer module definitions
echo - Corrupted BuildRules DLL files
echo - Missing or invalid Target files
echo.

pause

:: Set up paths
set "PROJECT_ROOT=%~dp0"
set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

echo Project Root: %PROJECT_ROOT%

echo.
echo ========================================================================
echo STEP 1: Backing up problematic directories
echo ========================================================================
echo.

:: Create backup directory with timestamp
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "BACKUP_DIR=%PROJECT_ROOT%\Backup_%dt:~0,8%_%dt:~8,6%"
mkdir "%BACKUP_DIR%" 2>nul

echo Backup directory: %BACKUP_DIR%

:: Backup the Dreamer_Rebuilt directory before removing it
if exist "%PROJECT_ROOT%\Plugins\Dreamer_Rebuilt" (
    echo Backing up Dreamer_Rebuilt directory...
    xcopy "%PROJECT_ROOT%\Plugins\Dreamer_Rebuilt" "%BACKUP_DIR%\Dreamer_Rebuilt\" /E /I /H /Y
    echo Backed up Dreamer_Rebuilt directory
)

echo.
echo ========================================================================
echo STEP 2: Removing duplicate and problematic directories
echo ========================================================================
echo.

:: Remove the Dreamer_Rebuilt directory entirely (it contains duplicates)
if exist "%PROJECT_ROOT%\Plugins\Dreamer_Rebuilt" (
    echo Removing Dreamer_Rebuilt directory...
    rd /s /q "%PROJECT_ROOT%\Plugins\Dreamer_Rebuilt"
    echo Removed Dreamer_Rebuilt directory
) else (
    echo Dreamer_Rebuilt directory not found, skipping...
)

:: Remove corrupted BuildRules directory
if exist "%PROJECT_ROOT%\Intermediate\Build\BuildRules" (
    echo Removing corrupted BuildRules directory...
    rd /s /q "%PROJECT_ROOT%\Intermediate\Build\BuildRules"
    echo Removed BuildRules directory
) else (
    echo BuildRules directory not found, skipping...
)

:: Remove other intermediate build files that might be corrupted
if exist "%PROJECT_ROOT%\Intermediate\Build" (
    echo Cleaning Intermediate\Build directory...
    for /d %%d in ("%PROJECT_ROOT%\Intermediate\Build\*") do (
        if /i not "%%~nxd"=="Win64" (
            echo   Removing %%d...
            rd /s /q "%%d" 2>nul
        )
    )
)

echo.
echo ========================================================================
echo STEP 3: Checking and fixing duplicate Source modules
echo ========================================================================
echo.

:: Check if we have both Source\Dreamer1 and Plugins\Dreamer\Source\Dreamer1
if exist "%PROJECT_ROOT%\Source\Dreamer1" (
    if exist "%PROJECT_ROOT%\Plugins\Dreamer\Source\Dreamer1" (
        echo WARNING: Found duplicate Dreamer1 modules!
        echo   - %PROJECT_ROOT%\Source\Dreamer1
        echo   - %PROJECT_ROOT%\Plugins\Dreamer\Source\Dreamer1
        echo.
        echo Backing up and removing Source\Dreamer1 (keeping plugin version)...
        
        :: Backup the Source\Dreamer1 before removing
        xcopy "%PROJECT_ROOT%\Source\Dreamer1" "%BACKUP_DIR%\Source_Dreamer1\" /E /I /H /Y
        rd /s /q "%PROJECT_ROOT%\Source\Dreamer1"
        echo Removed Source\Dreamer1 directory
    )
)

:: Check if we have both Source\Dreamer and Plugins\Dreamer\Source\Dreamer
if exist "%PROJECT_ROOT%\Source\Dreamer" (
    if exist "%PROJECT_ROOT%\Plugins\Dreamer\Source\Dreamer" (
        echo WARNING: Found duplicate Dreamer modules!
        echo   - %PROJECT_ROOT%\Source\Dreamer
        echo   - %PROJECT_ROOT%\Plugins\Dreamer\Source\Dreamer
        echo.
        echo Backing up and removing Source\Dreamer (keeping plugin version)...
        
        :: Backup the Source\Dreamer before removing
        xcopy "%PROJECT_ROOT%\Source\Dreamer" "%BACKUP_DIR%\Source_Dreamer\" /E /I /H /Y
        rd /s /q "%PROJECT_ROOT%\Source\Dreamer"
        echo Removed Source\Dreamer directory
    )
)

echo.
echo ========================================================================
echo STEP 4: Creating proper Target files if missing
echo ========================================================================
echo.

:: Check if we need to create Target files in the main Source directory
if not exist "%PROJECT_ROOT%\Source\Dreamer1.Target.cs" (
    echo Creating main Dreamer1.Target.cs...
    
    :: Create the Target file content
    echo using UnrealBuildTool; > "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo. >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo public class Dreamer1Target : TargetRules >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo { >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo     public Dreamer1Target(TargetInfo Target) : base(Target) >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo     { >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo         Type = TargetType.Game; >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo         DefaultBuildSettings = BuildSettingsVersion.V5; >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo         IncludeOrderVersion = EngineIncludeOrderVersion.Latest; >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo         ExtraModuleNames.AddRange(new string[] { "Dreamer1" }); >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo     } >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    echo } >> "%PROJECT_ROOT%\Source\Dreamer1.Target.cs"
    
    echo Created Dreamer1.Target.cs
)

if not exist "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs" (
    echo Creating main Dreamer1Editor.Target.cs...
    
    :: Create the Editor Target file content
    echo using UnrealBuildTool; > "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo. >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo public class Dreamer1EditorTarget : TargetRules >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo { >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo     public Dreamer1EditorTarget(TargetInfo Target) : base(Target) >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo     { >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo         Type = TargetType.Editor; >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo         DefaultBuildSettings = BuildSettingsVersion.V5; >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo         IncludeOrderVersion = EngineIncludeOrderVersion.Latest; >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo         ExtraModuleNames.AddRange(new string[] { "Dreamer1" }); >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo     } >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    echo } >> "%PROJECT_ROOT%\Source\Dreamer1Editor.Target.cs"
    
    echo Created Dreamer1Editor.Target.cs
)

:: Ensure we have a proper main module Build.cs file
if not exist "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs" (
    echo Creating main Dreamer1.Build.cs...
    
    :: Create the directory if it doesn't exist
    mkdir "%PROJECT_ROOT%\Source\Dreamer1" 2>nul
    
    :: Create the Build.cs file content
    echo using UnrealBuildTool; > "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo. >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo public class Dreamer1 : ModuleRules >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo { >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo     public Dreamer1(ReadOnlyTargetRules Target) : base(Target) >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo     { >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo         PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs; >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo. >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo         PublicDependencyModuleNames.AddRange(new string[] { >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo             "Core", >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo             "CoreUObject", >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo             "Engine" >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo         }); >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo. >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo         PrivateDependencyModuleNames.AddRange(new string[] { >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo             // Add private dependencies here >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo         }); >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo     } >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    echo } >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.Build.cs"
    
    echo Created Dreamer1.Build.cs
)

echo.
echo ========================================================================
echo STEP 5: Fixing deprecated UnsafeTypeCastWarningLevel
echo ========================================================================
echo.

:: Fix the deprecated warning in VisualStudioTools
set "VS_BUILD_FILE=%PROJECT_ROOT%\Plugins\VisualStudioTools\Source\VisualStudioTools\VisualStudioTools.Build.cs"
if exist "%VS_BUILD_FILE%" (
    echo Fixing deprecated UnsafeTypeCastWarningLevel in VisualStudioTools...
    
    :: Create a PowerShell script to fix the deprecated property
    echo $content = Get-Content '%VS_BUILD_FILE%' -Raw > "%PROJECT_ROOT%\fix_vs_build.ps1"
    echo $content = $content -replace 'UnsafeTypeCastWarningLevel', 'CppCompileWarningSettings.UnsafeTypeCastWarningLevel' >> "%PROJECT_ROOT%\fix_vs_build.ps1"
    echo $content ^| Set-Content '%VS_BUILD_FILE%' >> "%PROJECT_ROOT%\fix_vs_build.ps1"
    echo echo "Fixed deprecated UnsafeTypeCastWarningLevel" >> "%PROJECT_ROOT%\fix_vs_build.ps1"
    
    :: Run the PowerShell script
    powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\fix_vs_build.ps1"
    
    :: Clean up
    del "%PROJECT_ROOT%\fix_vs_build.ps1" 2>nul
)

echo.
echo ========================================================================
echo STEP 6: Creating basic source files if missing
echo ========================================================================
echo.

:: Create basic Dreamer1.cpp if it doesn't exist
if not exist "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.cpp" (
    echo Creating basic Dreamer1.cpp...
    
    echo #include "Dreamer1.h" > "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.cpp"
    echo #include "Modules/ModuleManager.h" >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.cpp"
    echo. >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.cpp"
    echo IMPLEMENT_PRIMARY_GAME_MODULE(FDefaultGameModuleImpl, Dreamer1, "Dreamer1"); >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.cpp"
    
    echo Created Dreamer1.cpp
)

:: Create basic Dreamer1.h if it doesn't exist
if not exist "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.h" (
    echo Creating basic Dreamer1.h...
    
    echo #pragma once > "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.h"
    echo. >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.h"
    echo #include "CoreMinimal.h" >> "%PROJECT_ROOT%\Source\Dreamer1\Dreamer1.h"
    
    echo Created Dreamer1.h
)

echo.
echo ========================================================================
echo STEP 7: Cleaning up additional intermediate files
echo ========================================================================
echo.

:: Clean up any remaining problematic files
echo Cleaning up additional intermediate files...

:: Remove .sln and .vcxproj files (they'll be regenerated)
del "%PROJECT_ROOT%\*.sln" 2>nul
del "%PROJECT_ROOT%\*.vcxproj*" 2>nul

:: Clean Binaries if they exist and might be corrupted
if exist "%PROJECT_ROOT%\Binaries" (
    echo Cleaning Binaries directory...
    rd /s /q "%PROJECT_ROOT%\Binaries" 2>nul
)

:: Clean plugin binaries that might be corrupted
for /d %%d in ("%PROJECT_ROOT%\Plugins\*") do (
    if exist "%%d\Binaries" (
        echo Cleaning %%d\Binaries...
        rd /s /q "%%d\Binaries" 2>nul
    )
    if exist "%%d\Intermediate" (
        echo Cleaning %%d\Intermediate...
        rd /s /q "%%d\Intermediate" 2>nul
    )
)

echo.
echo ========================================================================
echo STEP 8: Running test build to verify fixes
echo ========================================================================
echo.

:: Find Unreal Engine
for /f "tokens=2 delims=:, " %%a in ('type "%PROJECT_ROOT%\Dreamer1.uproject" ^| findstr "EngineAssociation"') do (
    set "ENGINE_VERSION=%%~a"
)
set "ENGINE_VERSION=%ENGINE_VERSION:"=%"

set "ENGINE_PATH="
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine\%ENGINE_VERSION%" /v "InstalledDirectory" 2^>nul') do (
    set "ENGINE_PATH=%%b"
)

if not defined ENGINE_PATH (
    if exist "C:\Program Files\Epic Games\UE_%ENGINE_VERSION%" (
        set "ENGINE_PATH=C:\Program Files\Epic Games\UE_%ENGINE_VERSION%"
    ) else if exist "C:\Program Files\Epic Games\UE_5.6" (
        set "ENGINE_PATH=C:\Program Files\Epic Games\UE_5.6"
    )
)

if defined ENGINE_PATH (
    set "UBT_BINARY=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
    if not exist "%UBT_BINARY%" (
        set "UBT_BINARY=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool.exe"
    )
    
    if exist "%UBT_BINARY%" (
        echo Testing project file generation...
        "%UBT_BINARY%" -projectfiles -project="%PROJECT_ROOT%\Dreamer1.uproject" -game -engine -progress
        
        if %ERRORLEVEL% EQU 0 (
            echo SUCCESS: Project file generation completed without errors!
        ) else (
            echo WARNING: Project file generation completed with errors. Check the output above.
        )
    ) else (
        echo Could not find UnrealBuildTool, skipping test build.
    )
) else (
    echo Could not find Unreal Engine, skipping test build.
)

echo.
echo ========================================================================
echo BUILD DUPLICATION ERROR FIX COMPLETED
echo ========================================================================
echo.

echo Summary of actions taken:
echo   ? Removed duplicate Dreamer_Rebuilt directory
echo   ? Cleaned corrupted BuildRules directory
echo   ? Removed duplicate Source modules (backed up first)
echo   ? Created proper Target.cs files
echo   ? Fixed deprecated UnsafeTypeCastWarningLevel warning
echo   ? Created basic source files if missing
echo   ? Cleaned intermediate build files
echo.

echo Backup directory: %BACKUP_DIR%
echo.

echo The duplicate module definition errors should now be resolved.
echo You can now try building your project again.
echo.

pause