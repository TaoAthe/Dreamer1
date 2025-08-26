@echo off
echo Fixing WorldContext.cpp compilation error...

set PLUGIN_DIR=C:\Users\Sarah\Documents\Unreal Projects\Dreamer1\Plugins\UnrealImGui-IMGUI_1.74

echo Examining for WorldContext.cpp...
for /r "%PLUGIN_DIR%" %%f in (WorldContext.cpp) do (
    echo Found WorldContext.cpp at: %%f
    
    rem Create a backup of the file
    copy "%%f" "%%f.bak"
    
    rem Fix the includes in the file
    powershell -Command "(Get-Content -Path '%%f') -replace '#include \"VersionCompatibility.h\"', '#include \"VersionCompatibility.h\"%0A#include \"UnrealClasses.h\"' | Set-Content -Path '%%f'"
)

echo.
echo Fix attempt completed for WorldContext.cpp.
echo Now try running the RebuildModules.bat script or opening your project in Unreal Editor.
pause