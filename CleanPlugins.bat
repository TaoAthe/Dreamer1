@echo off
echo Cleaning plugin build artifacts...

if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp\Binaries" (
    echo Removing InEditorCpp binaries...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp\Binaries"
)
if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp\Intermediate" (
    echo Removing InEditorCpp intermediate files...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\InEditorCpp\Intermediate"
)
if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Binaries" (
    echo Removing ImGui binaries...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Binaries"
)
if exist "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Intermediate" (
    echo Removing ImGui intermediate files...
    rmdir /s /q "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74\Intermediate"
)

echo.
echo Cleanup completed. You can now try opening the project again.
echo When prompted to rebuild modules, select "Yes".
pause