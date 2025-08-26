@echo off
echo Rebuilding Dreamer Plugin...

set UE_ENGINE_DIR=C:\Program Files\Epic Games\UE_5.6
set PROJECT_PATH=C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Dreamer1.uproject

echo Cleaning previous build...
rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\Dreamer\Binaries" 2>nul
rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\Dreamer\Intermediate" 2>nul

echo Generating project files...
"%UE_ENGINE_DIR%\Engine\Binaries\Win64\UnrealVersionSelector.exe" /projectfiles "%PROJECT_PATH%"

echo Building plugin...
"%UE_ENGINE_DIR%\Engine\Build\BatchFiles\RunUAT.bat" BuildPlugin -Plugin="C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\Dreamer\Dreamer.uplugin" -Package="C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\Dreamer_Rebuilt" -Rocket

echo Copying rebuilt files...
xcopy /E /I /Y "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\Dreamer_Rebuilt\Binaries" "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\Dreamer\Binaries"
xcopy /E /I /Y "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\Dreamer_Rebuilt\Intermediate" "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\Dreamer\Intermediate"

echo Plugin rebuild complete. You can now test the plugin in Unreal Engine.
pause