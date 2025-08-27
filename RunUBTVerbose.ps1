# RunUBTVerbose.ps1
# This PowerShell script runs UnrealBuildTool with verbose logging and comprehensive diagnostics

param(
    [string]$Target = "Dreamer1Editor",
    [string]$Platform = "Win64", 
    [string]$Configuration = "Development"
)

# Enable strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue" # Continue on errors to capture all information

Write-Host "========================================================================"
Write-Host "                     VERBOSE UBT BUILD SCRIPT (PowerShell)"
Write-Host "========================================================================"
Write-Host ""

# Get the script directory (project root)
$ProjectRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ProjectPath = Join-Path $ProjectRoot "Dreamer1.uproject"

Write-Host "Project Root: $ProjectRoot"
Write-Host "Project Path: $ProjectPath"

if (-not (Test-Path $ProjectPath)) {
    Write-Host "ERROR: Could not find Dreamer1.uproject in $ProjectRoot" -ForegroundColor Red
    exit 1
}

# Get engine version from project file
try {
    $ProjectContent = Get-Content $ProjectPath -Raw | ConvertFrom-Json
    $EngineVersion = $ProjectContent.EngineAssociation
    Write-Host "Engine Version: $EngineVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to parse project file: $_" -ForegroundColor Red
    exit 1
}

# Find engine path
$EnginePath = $null
$RegistryPaths = @(
    "HKLM:\SOFTWARE\EpicGames\Unreal Engine\$EngineVersion",
    "HKCU:\SOFTWARE\EpicGames\Unreal Engine\$EngineVersion"
)

foreach ($RegPath in $RegistryPaths) {
    if (Test-Path $RegPath) {
        try {
            $EnginePath = (Get-ItemProperty -Path $RegPath -Name "InstalledDirectory" -ErrorAction SilentlyContinue).InstalledDirectory
            if ($EnginePath) {
                Write-Host "Found engine path in registry: $EnginePath" -ForegroundColor Green
                break
            }
        } catch {
            Write-Host "Warning: Could not read registry key $RegPath" -ForegroundColor Yellow
        }
    }
}

# If we couldn't find it in the registry, check common locations
if (-not $EnginePath -or -not (Test-Path $EnginePath)) {
    $PossiblePaths = @(
        "C:\Program Files\Epic Games\UE_$EngineVersion",
        "C:\Epic Games\UE_$EngineVersion",
        "C:\Program Files\Epic Games\UE_5.6",
        "C:\Program Files\Epic Games\UE_5.5",
        "C:\Program Files\Epic Games\UE_5.4"
    )
    
    foreach ($Path in $PossiblePaths) {
        if (Test-Path $Path) {
            $EnginePath = $Path
            Write-Host "Found engine at common location: $EnginePath" -ForegroundColor Green
            break
        }
    }
}

if (-not $EnginePath -or -not (Test-Path $EnginePath)) {
    Write-Host "ERROR: Could not locate Unreal Engine installation." -ForegroundColor Red
    Write-Host "Please specify the engine path manually:" -ForegroundColor Yellow
    $EnginePath = Read-Host "Engine path"
    
    if (-not (Test-Path $EnginePath)) {
        Write-Host "ERROR: Specified engine path does not exist." -ForegroundColor Red
        exit 1
    }
}

# Find UBT binary
$UbtPath = "$EnginePath\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
if (-not (Test-Path $UbtPath)) {
    $UbtPath = "$EnginePath\Engine\Binaries\DotNET\UnrealBuildTool.exe"
    if (-not (Test-Path $UbtPath)) {
        Write-Host "ERROR: Could not find UnrealBuildTool.exe" -ForegroundColor Red
        exit 1
    }
}

Write-Host "UBT Binary: $UbtPath" -ForegroundColor Green

# Set up .NET environment
$DotnetRoot = "$EnginePath\Engine\Binaries\ThirdParty\DotNet\Win64"
if (Test-Path $DotnetRoot) {
    $env:DOTNET_ROOT = $DotnetRoot
    $env:PATH = "$DotnetRoot;$env:PATH"
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = 1
    $env:DOTNET_NOLOGO = 1
    $env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = 1
    Write-Host "DOTNET_ROOT: $DotnetRoot" -ForegroundColor Green
}

# Create logs directory
$LogsDir = Join-Path $ProjectRoot "Logs"
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogsDir "UBT.log"
$TimestampedLog = Join-Path $LogsDir "UBT_$Timestamp.log"

Write-Host ""
Write-Host "========================================================================"
Write-Host "                      RUNNING UBT COMMANDS"
Write-Host "========================================================================"
Write-Host ""

Write-Host "Log file: $LogFile" -ForegroundColor Cyan
Write-Host "Timestamped log: $TimestampedLog" -ForegroundColor Cyan
Write-Host ""

# Function to run UBT command and capture output
function Invoke-UBTCommand {
    param(
        [string]$CommandName,
        [string[]]$Arguments,
        [string]$LogPath
    )
    
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host "Command: $CommandName" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    
    $FullCommand = "`"$UbtPath`" " + ($Arguments -join " ")
    Write-Host "Executing: $FullCommand" -ForegroundColor Cyan
    Write-Host ""
    
    # Create the command info
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $UbtPath
    $ProcessInfo.Arguments = $Arguments -join " "
    $ProcessInfo.RedirectStandardOutput = $true
    $ProcessInfo.RedirectStandardError = $true
    $ProcessInfo.UseShellExecute = $false
    $ProcessInfo.CreateNoWindow = $true
    $ProcessInfo.WorkingDirectory = $ProjectRoot
    
    # Start the process
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessInfo
    
    try {
        $Process.Start() | Out-Null
        
        # Read output
        $StdOut = $Process.StandardOutput.ReadToEnd()
        $StdErr = $Process.StandardError.ReadToEnd()
        
        $Process.WaitForExit()
        $ExitCode = $Process.ExitCode
        
        # Write to log file
        "=== $CommandName - $(Get-Date) ===" | Out-File -FilePath $LogPath -Append
        "Command: $FullCommand" | Out-File -FilePath $LogPath -Append
        "Exit Code: $ExitCode" | Out-File -FilePath $LogPath -Append
        "--- Standard Output ---" | Out-File -FilePath $LogPath -Append
        $StdOut | Out-File -FilePath $LogPath -Append
        "--- Standard Error ---" | Out-File -FilePath $LogPath -Append
        $StdErr | Out-File -FilePath $LogPath -Append
        "--- End of Command ---" | Out-File -FilePath $LogPath -Append
        "" | Out-File -FilePath $LogPath -Append
        
        # Display results
        Write-Host "Exit Code: $ExitCode" -ForegroundColor $(if ($ExitCode -eq 0) { "Green" } else { "Red" })
        
        if ($StdOut) {
            Write-Host "Standard Output:" -ForegroundColor Cyan
            Write-Host $StdOut
        }
        
        if ($StdErr) {
            Write-Host "Standard Error:" -ForegroundColor Red
            Write-Host $StdErr
        }
        
        Write-Host ""
        
        return @{
            ExitCode = $ExitCode
            StdOut = $StdOut
            StdErr = $StdErr
        }
        
    } catch {
        Write-Host "ERROR: Failed to execute command: $_" -ForegroundColor Red
        return @{
            ExitCode = -1
            StdOut = ""
            StdErr = $_.Exception.Message
        }
    } finally {
        if ($Process) {
            $Process.Dispose()
        }
    }
}

# Command 1: Query targets
$Result1 = Invoke-UBTCommand -CommandName "Query Targets" -Arguments @(
    "-Mode=QueryTargets",
    "-Project=`"$ProjectPath`"",
    "-TargetPlatform=$Platform",
    "-BuildConfiguration=$Configuration",
    "-Verbose",
    "-Log=`"$LogFile`""
) -LogPath $TimestampedLog

# Command 2: Generate project files
$Result2 = Invoke-UBTCommand -CommandName "Generate Project Files" -Arguments @(
    "-projectfiles",
    "-project=`"$ProjectPath`"",
    "-game",
    "-engine",
    "-progress",
    "-Verbose",
    "-Log=`"$LogFile`""
) -LogPath $TimestampedLog

# Command 3: Build target
$Result3 = Invoke-UBTCommand -CommandName "Build $Target" -Arguments @(
    $Target,
    $Platform,
    $Configuration,
    "-Project=`"$ProjectPath`"",
    "-WaitMutex",
    "-Verbose",
    "-Log=`"$LogFile`""
) -LogPath $TimestampedLog

# Command 4: List target files
$Result4 = Invoke-UBTCommand -CommandName "List Target Files" -Arguments @(
    "-Mode=ListTargetFiles",
    "-Project=`"$ProjectPath`"",
    "-Verbose",
    "-Log=`"$LogFile`""
) -LogPath $TimestampedLog

# Summary
Write-Host ""
Write-Host "========================================================================"
Write-Host "                           SUMMARY"
Write-Host "========================================================================"
Write-Host ""

Write-Host "Results Summary:" -ForegroundColor Cyan
Write-Host "  Query Targets:       Exit Code $($Result1.ExitCode)" -ForegroundColor $(if ($Result1.ExitCode -eq 0) { "Green" } else { "Red" })
Write-Host "  Generate Projects:   Exit Code $($Result2.ExitCode)" -ForegroundColor $(if ($Result2.ExitCode -eq 0) { "Green" } else { "Red" })
Write-Host "  Build $Target`:        Exit Code $($Result3.ExitCode)" -ForegroundColor $(if ($Result3.ExitCode -eq 0) { "Green" } else { "Red" })
Write-Host "  List Target Files:   Exit Code $($Result4.ExitCode)" -ForegroundColor $(if ($Result4.ExitCode -eq 0) { "Green" } else { "Red" })
Write-Host ""

# Analyze results
$HasErrors = $false

if ($Result1.ExitCode -ne 0) {
    Write-Host "WARNING: Query targets failed with exit code $($Result1.ExitCode)" -ForegroundColor Yellow
    $HasErrors = $true
}

if ($Result2.ExitCode -ne 0) {
    Write-Host "WARNING: Generate project files failed with exit code $($Result2.ExitCode)" -ForegroundColor Yellow
    $HasErrors = $true
}

if ($Result3.ExitCode -ne 0) {
    Write-Host "WARNING: Build failed with exit code $($Result3.ExitCode)" -ForegroundColor Yellow
    $HasErrors = $true
}

if ($Result4.ExitCode -ne 0) {
    Write-Host "WARNING: List target files failed with exit code $($Result4.ExitCode)" -ForegroundColor Yellow
    $HasErrors = $true
}

if (-not $HasErrors) {
    Write-Host "SUCCESS: All UBT commands completed successfully!" -ForegroundColor Green
} else {
    Write-Host "ISSUES DETECTED: One or more UBT commands failed. Check the logs for details." -ForegroundColor Red
}

Write-Host ""
Write-Host "Detailed logs have been saved to:" -ForegroundColor Cyan
Write-Host "  Main log: $LogFile" -ForegroundColor Cyan
Write-Host "  Timestamped log: $TimestampedLog" -ForegroundColor Cyan
Write-Host ""

# Offer to open the log file
Write-Host "Would you like to open the log file for review? (y/n): " -NoNewline -ForegroundColor Yellow
$Response = Read-Host

if ($Response -eq "y" -or $Response -eq "Y") {
    if (Test-Path $TimestampedLog) {
        Start-Process notepad $TimestampedLog
    }
}

Write-Host ""
Write-Host "Script completed." -ForegroundColor Green