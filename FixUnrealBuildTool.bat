@echo off
REM This batch file runs the FixUnrealBuildTool.ps1 script with the appropriate PowerShell execution policy

echo ========================================================================
echo                     UNREAL BUILD TOOL FIX
echo ========================================================================
echo.
echo This script will attempt to fix the "could not fetch all the available
echo targets from the unreal build tool" error.
echo.
echo Please close Unreal Engine and Visual Studio before continuing.
echo.
pause

powershell -ExecutionPolicy Bypass -File "%~dp0FixUnrealBuildTool.ps1"

echo.
echo Script execution completed.
echo.
pause