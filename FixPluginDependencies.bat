@echo off
:: FixPluginDependencies.bat
:: This script fixes plugin dependencies, particularly for InEditorCpp and SourceCodeAccess

echo ========================================================================
echo                    PLUGIN DEPENDENCY FIX
echo ========================================================================
echo.
echo This script will fix plugin dependencies, particularly for:
echo  - InEditorCpp
echo  - SourceCodeAccess
echo.
echo Please close Unreal Engine and Visual Studio before continuing.
echo.
pause

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

echo.
echo ========================================================================
echo STEP 2: Checking Source Code Access Plugins
echo ========================================================================
echo.

:: Check for source code access plugins
echo Checking for source code access plugins...

set "SOURCE_CODE_ACCESS_DIR=%ENGINE_PATH%\Engine\Plugins\Developer"
set "VS_SOURCE_CODE_ACCESS_FOUND=0"
set "VS_CODE_SOURCE_CODE_ACCESS_FOUND=0"

if exist "%SOURCE_CODE_ACCESS_DIR%\VisualStudioSourceCodeAccess" (
    echo Found VisualStudioSourceCodeAccess plugin
    set "VS_SOURCE_CODE_ACCESS_FOUND=1"
)

if exist "%SOURCE_CODE_ACCESS_DIR%\VisualStudioCodeSourceCodeAccess" (
    echo Found VisualStudioCodeSourceCodeAccess plugin
    set "VS_CODE_SOURCE_CODE_ACCESS_FOUND=1"
)

:: Create a PowerShell script to fix the plugin references
echo Creating PowerShell fix script...

echo $projectFile = Get-Content "%PROJECT_PATH%" -Raw ^| ConvertFrom-Json > "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
echo $dreamerPluginPath = "%PROJECT_ROOT%\Plugins\Dreamer\Dreamer.uplugin" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
echo $dreamerPluginFile = Get-Content $dreamerPluginPath -Raw ^| ConvertFrom-Json >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"

:: Check VisualStudioSourceCodeAccess plugin
if %VS_SOURCE_CODE_ACCESS_FOUND% EQU 1 (
    echo echo "Updating plugin references to use VisualStudioSourceCodeAccess..." >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo # Update project file >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $hasVSSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $hasSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo foreach ($plugin in $projectFile.Plugins) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "VisualStudioSourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $hasVSSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "SourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $hasSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Enabled = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo if (-not $hasVSSourceCodeAccess) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $newPlugin = @{ >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Name = "VisualStudioSourceCodeAccess" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $projectFile.Plugins += $newPlugin >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     echo "Added VisualStudioSourceCodeAccess plugin to project file" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo # Update Dreamer plugin file >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $dreamerHasVSSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $dreamerHasSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo foreach ($plugin in $dreamerPluginFile.Plugins) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "VisualStudioSourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $dreamerHasVSSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "SourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $dreamerHasSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Name = "VisualStudioSourceCodeAccess" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo if (-not $dreamerHasVSSourceCodeAccess -and -not $dreamerHasSourceCodeAccess) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $newPlugin = @{ >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Name = "VisualStudioSourceCodeAccess" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $dreamerPluginFile.Plugins += $newPlugin >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     echo "Added VisualStudioSourceCodeAccess plugin to Dreamer plugin file" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
) else if %VS_CODE_SOURCE_CODE_ACCESS_FOUND% EQU 1 (
    echo echo "Updating plugin references to use VisualStudioCodeSourceCodeAccess..." >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo # Update project file >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $hasVSCodeSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $hasSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo foreach ($plugin in $projectFile.Plugins) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "VisualStudioCodeSourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $hasVSCodeSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "SourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $hasSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Enabled = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo if (-not $hasVSCodeSourceCodeAccess) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $newPlugin = @{ >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Name = "VisualStudioCodeSourceCodeAccess" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $projectFile.Plugins += $newPlugin >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     echo "Added VisualStudioCodeSourceCodeAccess plugin to project file" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo # Update Dreamer plugin file >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $dreamerHasVSCodeSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $dreamerHasSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo foreach ($plugin in $dreamerPluginFile.Plugins) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "VisualStudioCodeSourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $dreamerHasVSCodeSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "SourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $dreamerHasSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Name = "VisualStudioCodeSourceCodeAccess" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo if (-not $dreamerHasVSCodeSourceCodeAccess -and -not $dreamerHasSourceCodeAccess) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $newPlugin = @{ >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Name = "VisualStudioCodeSourceCodeAccess" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $dreamerPluginFile.Plugins += $newPlugin >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     echo "Added VisualStudioCodeSourceCodeAccess plugin to Dreamer plugin file" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
) else (
    echo echo "No source code access plugins found in the engine. Using NullSourceCodeAccess as fallback..." >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo # Update project file >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $hasNullSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $hasSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo foreach ($plugin in $projectFile.Plugins) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "NullSourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $hasNullSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "SourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $hasSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Enabled = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo if (-not $hasNullSourceCodeAccess) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $newPlugin = @{ >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Name = "NullSourceCodeAccess" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $projectFile.Plugins += $newPlugin >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     echo "Added NullSourceCodeAccess plugin to project file" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo # Update Dreamer plugin file >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $dreamerHasNullSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo $dreamerHasSourceCodeAccess = $false >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo foreach ($plugin in $dreamerPluginFile.Plugins) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "NullSourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $dreamerHasNullSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     if ($plugin.Name -eq "SourceCodeAccess") { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $dreamerHasSourceCodeAccess = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         $plugin.Name = "NullSourceCodeAccess" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    
    echo if (-not $dreamerHasNullSourceCodeAccess -and -not $dreamerHasSourceCodeAccess) { >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $newPlugin = @{ >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Name = "NullSourceCodeAccess" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo         Enabled = $true >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     $dreamerPluginFile.Plugins += $newPlugin >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo     echo "Added NullSourceCodeAccess plugin to Dreamer plugin file" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
    echo } >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
)

echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
echo # Save changes >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
echo $projectFile ^| ConvertTo-Json -Depth 10 ^| Set-Content "%PROJECT_PATH%" >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
echo $dreamerPluginFile ^| ConvertTo-Json -Depth 10 ^| Set-Content $dreamerPluginPath >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
echo. >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
echo echo "Plugin references updated successfully." >> "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"

:: Run the PowerShell script
echo Running PowerShell fix script...
powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"

echo.
echo ========================================================================
echo STEP 3: Checking InEditorCpp Plugin
echo ========================================================================
echo.

:: Check for InEditorCpp plugin
echo Checking for InEditorCpp plugin...

set "INEDITOR_CPP_FOUND=0"
if exist "%PROJECT_ROOT%\Plugins\InEditorCpp" (
    echo Found InEditorCpp plugin in project
    set "INEDITOR_CPP_FOUND=1"
)

if %INEDITOR_CPP_FOUND% EQU 0 (
    echo WARNING: InEditorCpp plugin not found in project.
    echo Would you like to create a stub InEditorCpp plugin? (y/n)
    set /p CREATE_STUB=
    if /i "%CREATE_STUB%"=="y" (
        echo Creating stub InEditorCpp plugin...
        mkdir "%PROJECT_ROOT%\Plugins\InEditorCpp" 2>nul
        
        :: Create a PowerShell script to create the stub plugin
        echo $stubPluginContent = @" > "%PROJECT_ROOT%\Temp_Create_Stub.ps1"
echo {
echo   "FileVersion": 3,
echo   "Version": 1,
echo   "VersionName": "1.0",
echo   "FriendlyName": "InEditorCpp",
echo   "Description": "Stub plugin to satisfy dependencies",
echo   "Category": "Editor",
echo   "CreatedBy": "Plugin Dependency Fix",
echo   "CreatedByURL": "",
echo   "DocsURL": "",
echo   "MarketplaceURL": "",
echo   "SupportURL": "",
echo   "CanContainContent": false,
echo   "IsBetaVersion": false,
echo   "IsExperimentalVersion": false,
echo   "Installed": true,
echo   "Modules": [
echo     {
echo       "Name": "InEditorCpp",
echo       "Type": "Editor",
echo       "LoadingPhase": "Default"
echo     }
echo   ]
echo }
echo "@ >> "%PROJECT_ROOT%\Temp_Create_Stub.ps1"
        echo. >> "%PROJECT_ROOT%\Temp_Create_Stub.ps1"
        echo $stubPluginContent ^| Set-Content "%PROJECT_ROOT%\Plugins\InEditorCpp\InEditorCpp.uplugin" >> "%PROJECT_ROOT%\Temp_Create_Stub.ps1"
        echo. >> "%PROJECT_ROOT%\Temp_Create_Stub.ps1"
        echo echo "Created stub InEditorCpp plugin" >> "%PROJECT_ROOT%\Temp_Create_Stub.ps1"
        
        :: Run the PowerShell script
        powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\Temp_Create_Stub.ps1"
    )
)

echo.
echo ========================================================================
echo PLUGIN DEPENDENCY FIX COMPLETED
echo ========================================================================
echo.
echo The plugin dependency fix process has been completed.
echo.
echo You can now try opening your project in Unreal Engine.
echo.
pause

:: Clean up temporary files
if exist "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1" (
    del "%PROJECT_ROOT%\Temp_Fix_Plugins.ps1"
)
if exist "%PROJECT_ROOT%\Temp_Create_Stub.ps1" (
    del "%PROJECT_ROOT%\Temp_Create_Stub.ps1"
)