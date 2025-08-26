@echo off
echo Deep cleaning Unreal project...
echo.
echo This script will remove all intermediate and build files
echo to allow for a completely fresh rebuild.
echo.
pause

set PROJECT_ROOT=C:\Users\Sarah\Documents\Unreal Projects\Dreamer1

echo Removing Intermediate directory...
if exist "%PROJECT_ROOT%\Intermediate" rmdir /s /q "%PROJECT_ROOT%\Intermediate"

echo Removing Saved\Temp directory...
if exist "%PROJECT_ROOT%\Saved\Temp" rmdir /s /q "%PROJECT_ROOT%\Saved\Temp"

echo Removing Binaries directory...
if exist "%PROJECT_ROOT%\Binaries" rmdir /s /q "%PROJECT_ROOT%\Binaries"

echo Removing DerivedDataCache directory...
if exist "%PROJECT_ROOT%\DerivedDataCache" rmdir /s /q "%PROJECT_ROOT%\DerivedDataCache"

echo Removing Build directory...
if exist "%PROJECT_ROOT%\Build" rmdir /s /q "%PROJECT_ROOT%\Build"

echo Removing plugin intermediate files...
for /d %%d in ("%PROJECT_ROOT%\Plugins\*") do (
    if exist "%%d\Intermediate" (
        echo Removing Intermediate from %%~nxd...
        rmdir /s /q "%%d\Intermediate"
    )
    if exist "%%d\Binaries" (
        echo Removing Binaries from %%~nxd...
        rmdir /s /q "%%d\Binaries"
    )
)

echo Removing Visual Studio files...
if exist "%PROJECT_ROOT%\*.sln" del /f "%PROJECT_ROOT%\*.sln"
if exist "%PROJECT_ROOT%\*.suo" del /f "%PROJECT_ROOT%\*.suo"
if exist "%PROJECT_ROOT%\*.sdf" del /f "%PROJECT_ROOT%\*.sdf"
if exist "%PROJECT_ROOT%\*.opensdf" del /f "%PROJECT_ROOT%\*.opensdf"
if exist "%PROJECT_ROOT%\*.VC.db" del /f "%PROJECT_ROOT%\*.VC.db"
if exist "%PROJECT_ROOT%\*.VC.opendb" del /f "%PROJECT_ROOT%\*.VC.opendb"

if exist "%PROJECT_ROOT%\.vs" rmdir /s /q "%PROJECT_ROOT%\.vs"

echo.
echo Deep clean completed. Now you can:
echo 1. Right-click on your .uproject file
echo 2. Select "Generate Visual Studio project files"
echo 3. Open the project in Unreal Editor
echo.
pause