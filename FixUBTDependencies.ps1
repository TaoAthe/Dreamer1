# FixUBTDependencies.ps1
# This script directly fixes .NET dependencies for Unreal Build Tool
# to resolve the "could not fetch all available targets" error.

# Ensure we have admin rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Please run as administrator." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Create timestamp for log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "$PSScriptRoot\UBTDependencyFix_$timestamp.log"

# Function to log messages
function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Host $Message -ForegroundColor $Color
}

# Banner
Write-Host "========================================================================"
Write-Host "          UNREAL BUILD TOOL DEPENDENCY FIX"
Write-Host "========================================================================"
Write-Host ""

# Initialize log
"UBT Dependency Fix started at $(Get-Date)" | Out-File -FilePath $logFile

# Get the project path
$projectPath = "$PSScriptRoot\Dreamer1.uproject"
if (-not (Test-Path $projectPath)) {
    Write-Log "ERROR: Could not find Dreamer1.uproject in $PSScriptRoot" "Red"
    exit 1
}

# Get engine version from project
try {
    $projectContent = Get-Content $projectPath -Raw | ConvertFrom-Json
    $engineVersion = $projectContent.EngineAssociation
    Write-Log "Project uses engine version: $engineVersion" "Green"
} catch {
    Write-Log "ERROR: Failed to parse project file: $_" "Red"
    exit 1
}

# Find engine path
$enginePath = $null
$registryPaths = @(
    "HKLM:\SOFTWARE\EpicGames\Unreal Engine\$engineVersion",
    "HKCU:\SOFTWARE\EpicGames\Unreal Engine\$engineVersion"
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        try {
            $enginePath = (Get-ItemProperty -Path $regPath -Name "InstalledDirectory" -ErrorAction SilentlyContinue).InstalledDirectory
            if ($enginePath) {
                Write-Log "Found engine path in registry: $enginePath" "Green"
                break
            }
        } catch {
            Write-Log "Warning: Could not read registry key $regPath: $_" "Yellow"
        }
    }
}

# If we couldn't find it in the registry, check common locations
if (-not $enginePath -or -not (Test-Path $enginePath)) {
    $possiblePaths = @(
        "C:\Program Files\Epic Games\UE_$engineVersion",
        "C:\Epic Games\UE_$engineVersion",
        "C:\Program Files\Epic Games\UE_5.6",
        "C:\Program Files\Epic Games\UE_5.5",
        "C:\Program Files\Epic Games\UE_5.4"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $enginePath = $path
            Write-Log "Found engine at common location: $enginePath" "Green"
            break
        }
    }
}

if (-not $enginePath -or -not (Test-Path $enginePath)) {
    Write-Log "ERROR: Could not locate Unreal Engine installation." "Red"
    Write-Log "Please specify the engine path manually:" "Yellow"
    $enginePath = Read-Host "Engine path"
    
    if (-not (Test-Path $enginePath)) {
        Write-Log "ERROR: Specified engine path does not exist." "Red"
        exit 1
    }
}

# Step 1: Locate UnrealBuildTool
Write-Log "Step 1: Locating UnrealBuildTool..." "Cyan"

$ubtPath = "$enginePath\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
if (-not (Test-Path $ubtPath)) {
    $ubtPath = "$enginePath\Engine\Binaries\DotNET\UnrealBuildTool.exe"
    if (-not (Test-Path $ubtPath)) {
        # Search for UBT.exe
        Write-Log "Searching for UnrealBuildTool.exe in engine directory..." "Yellow"
        $searchResults = Get-ChildItem -Path $enginePath -Filter "UnrealBuildTool.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($searchResults) {
            $ubtPath = $searchResults.FullName
            Write-Log "Found UnrealBuildTool at: $ubtPath" "Green"
        } else {
            Write-Log "ERROR: Could not find UnrealBuildTool.exe in engine directory." "Red"
            exit 1
        }
    } else {
        Write-Log "Found UnrealBuildTool at: $ubtPath" "Green"
    }
} else {
    Write-Log "Found UnrealBuildTool at expected location: $ubtPath" "Green"
}

# Step 2: Create .NET assembly binding redirects
Write-Log "Step 2: Creating .NET assembly binding redirects..." "Cyan"

$ubtDirectory = [System.IO.Path]::GetDirectoryName($ubtPath)
$configPath = [System.IO.Path]::Combine($ubtDirectory, "UnrealBuildTool.exe.config")

$configContent = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      <dependentAssembly>
        <assemblyIdentity name="System.Runtime" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="System.Collections" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="System.IO" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="System.Xml" publicKeyToken="b77a5c561934e089" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="System.Xml.Linq" publicKeyToken="b77a5c561934e089" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="System.CodeDom" publicKeyToken="cc7b13ffcd2ddd51" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="System.IO.Compression" publicKeyToken="b77a5c561934e089" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="System.IO.Compression.FileSystem" publicKeyToken="b77a5c561934e089" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="System.Reflection" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="System.Threading" publicKeyToken="b03f5f7f11d50a3a" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-99.9.9.9" newVersion="4.0.0.0" />
      </dependentAssembly>
    </assemblyBinding>
    <loadFromRemoteSources enabled="true"/>
  </runtime>
  <startup>
    <supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.6.2" />
  </startup>
</configuration>
"@

Write-Log "Creating binding redirects at: $configPath" "Yellow"
$configContent | Out-File -FilePath $configPath -Encoding UTF8
Write-Log "Created binding redirects" "Green"

# Step 3: Set up .NET environment
Write-Log "Step 3: Setting up .NET environment..." "Cyan"

$dotnetRoot = "$enginePath\Engine\Binaries\ThirdParty\DotNet\Win64"
if (Test-Path $dotnetRoot) {
    Write-Log "Found .NET in Unreal Engine at: $dotnetRoot" "Green"
    # Set environment variables
    $env:DOTNET_ROOT = $dotnetRoot
    $env:PATH = "$dotnetRoot;$env:PATH"
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = 1
    $env:DOTNET_NOLOGO = 1
    $env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = 1
} else {
    Write-Log "WARNING: Could not find .NET in Unreal Engine. Using system .NET if available." "Yellow"
}

# Step 4: Copy required .NET assemblies
Write-Log "Step 4: Ensuring required .NET assemblies are available..." "Cyan"

# Create directories for assembly copying if needed
$dllFixDir = "$PSScriptRoot\UBT_DLL_Fix"
New-Item -ItemType Directory -Path $dllFixDir -Force | Out-Null

# Find the CodeDom assembly
$codeDomPath = $null
$possibleCodeDomPaths = @(
    "$dotnetRoot\sdk\6.0.100\ref\net6.0\System.CodeDom.dll",
    "$dotnetRoot\sdk\7.0.100\ref\net6.0\System.CodeDom.dll",
    "$dotnetRoot\sdk\5.0.100\ref\netcoreapp2.0\System.CodeDom.dll",
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.CodeDom.dll",
    "C:\Program Files\dotnet\packs\Microsoft.NETCore.App.Ref\6.0.0\ref\net6.0\System.CodeDom.dll"
)

foreach ($path in $possibleCodeDomPaths) {
    if (Test-Path $path) {
        $codeDomPath = $path
        Write-Log "Found System.CodeDom at: $codeDomPath" "Green"
        break
    }
}

if ($codeDomPath) {
    $destPath = Join-Path $ubtDirectory "System.CodeDom.dll"
    Write-Log "Copying System.CodeDom.dll to UBT directory..." "Yellow"
    Copy-Item -Path $codeDomPath -Destination $destPath -Force
    Write-Log "Copied System.CodeDom.dll to: $destPath" "Green"
}

# Step 5: Ensure registry entries are correct
Write-Log "Step 5: Ensuring registry entries are correct..." "Cyan"

$registryPaths = @(
    "HKLM:\SOFTWARE\EpicGames\Unreal Engine\$engineVersion",
    "HKCU:\SOFTWARE\EpicGames\Unreal Engine\$engineVersion"
)

foreach ($regPath in $registryPaths) {
    if (-not (Test-Path $regPath)) {
        try {
            Write-Log "Creating registry key: $regPath" "Yellow"
            New-Item -Path $regPath -Force | Out-Null
        } catch {
            Write-Log "WARNING: Could not create registry key: $_" "Yellow"
        }
    }
    
    try {
        Write-Log "Setting InstalledDirectory value to: $enginePath" "Yellow"
        Set-ItemProperty -Path $regPath -Name "InstalledDirectory" -Value $enginePath -Type String -Force
    } catch {
        Write-Log "WARNING: Could not set registry value: $_" "Yellow"
    }
}

# Step 6: Create a direct test for UBT
Write-Log "Step 6: Creating and running UBT test script..." "Cyan"

$ubtTestBat = "$PSScriptRoot\TestUBT.bat"
@"
@echo off
setlocal enabledelayedexpansion

echo Setting up UBT test environment...
set "UE_ENGINE_DIRECTORY=$($enginePath.Replace('\', '\\'))"
set "UE_PROJECT_PATH=$($projectPath.Replace('\', '\\'))"
set "DOTNET_ROOT=$($dotnetRoot.Replace('\', '\\'))"
set "PATH=%DOTNET_ROOT%;%PATH%"
set "DOTNET_CLI_TELEMETRY_OPTOUT=1"
set "DOTNET_NOLOGO=1"
set "DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1"

echo UBT environment setup:
echo Engine: %UE_ENGINE_DIRECTORY%
echo Project: %UE_PROJECT_PATH%
echo DOTNET_ROOT: %DOTNET_ROOT%
echo.

echo Testing UBT target fetching...
"$($ubtPath.Replace('\', '\\'))" -Mode=QueryTargets -Project="%UE_PROJECT_PATH%" -TargetPlatform=Win64 -BuildConfiguration=Development

echo.
echo UBT test completed.
pause
"@ | Out-File -FilePath $ubtTestBat -Encoding ascii

Write-Log "Created UBT test script at: $ubtTestBat" "Green"
Write-Log "Running UBT test script..." "Yellow"

Start-Process -FilePath $ubtTestBat -Wait

# Step 7: Verify fix
Write-Log "Step 7: Verifying fix..." "Cyan"

# Create a verification script that will run silently
$verifyScript = @"
& '$ubtPath' -Mode=QueryTargets -Project='$projectPath' -TargetPlatform=Win64 -BuildConfiguration=Development 2>&1 | Out-File -FilePath '$PSScriptRoot\ubt_verification.txt'
"@

$verifyScriptPath = "$PSScriptRoot\verify_ubt.ps1"
$verifyScript | Out-File -FilePath $verifyScriptPath -Encoding UTF8

# Run the verification script
Write-Log "Running verification..." "Yellow"
& powershell -ExecutionPolicy Bypass -File $verifyScriptPath

# Check the verification output
$verificationOutput = Get-Content -Path "$PSScriptRoot\ubt_verification.txt" -Raw -ErrorAction SilentlyContinue
if ($verificationOutput -match "could not fetch all.*targets") {
    Write-Log "WARNING: The target error still persists. Additional fixes may be needed." "Red"
    Write-Log "Please try running the DirectUBTFix.bat script for a more comprehensive fix." "Yellow"
} else {
    Write-Log "SUCCESS: The target error appears to be fixed!" "Green"
    Write-Log "You can now try opening your project in Unreal Engine." "Green"
}

# Final message
Write-Host ""
Write-Host "========================================================================"
Write-Host "          UBT DEPENDENCY FIX COMPLETED"
Write-Host "========================================================================"
Write-Host ""
Write-Host "The UBT dependency fix process has been completed."
Write-Host ""
Write-Host "If the verification showed success, you can now try opening your project"
Write-Host "in Unreal Engine. If the issue persists, please run the DirectUBTFix.bat"
Write-Host "script for a more comprehensive fix."
Write-Host ""
Write-Host "A log file has been created at:"
Write-Host "$logFile"
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")