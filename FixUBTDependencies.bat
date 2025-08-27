@echo off
REM This batch file runs the FixUBTDependencies.ps1 script with admin privileges

echo ========================================================================
echo                  UBT DEPENDENCY FIX
echo ========================================================================
echo.
echo This script will fix .NET dependencies for Unreal Build Tool to resolve
echo the "could not fetch all the available targets" error.
echo.
echo Please close Unreal Engine and Visual Studio before continuing.
echo.
echo This script requires administrator privileges and will prompt for elevation.
echo.
pause

powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0FixUBTDependencies.ps1\"' -Verb RunAs"

echo.
echo If a User Account Control prompt appeared, please accept it to continue.
echo.
pause