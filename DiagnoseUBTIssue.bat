@echo off
REM This batch file runs the DiagnoseUBTIssue.ps1 script with the appropriate PowerShell execution policy

echo ========================================================================
echo                     UBT ERROR DIAGNOSTIC TOOL
echo ========================================================================
echo.
echo This script will diagnose the "could not fetch all the available
echo targets from the unreal build tool" error and create fix scripts.
echo.
echo Please close Unreal Engine and Visual Studio before continuing.
echo.
pause

powershell -ExecutionPolicy Bypass -File "%~dp0DiagnoseUBTIssue.ps1"

echo.
echo Diagnostic completed. Please run the recommended fix scripts.
echo.
pause