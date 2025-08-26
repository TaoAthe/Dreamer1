# Dreamer1 Unreal Project - Manual Rebuild Guide

This guide provides detailed instructions for rebuilding the Dreamer1 project from source and managing your work both locally and with GitHub.

## Rebuilding the Project

### Option 1: Use the ManualRebuild.bat Script (Recommended)

1. Close Unreal Engine and Visual Studio
2. Run `ManualRebuild.bat` as administrator
3. When Unreal Engine launches, select "Yes" to rebuild modules

This script performs a complete rebuild process:
- Cleans all intermediate files
- Fixes ImGui plugin compatibility issues
- Regenerates project files
- Builds plugins and main project
- Launches Unreal Engine

### Option 2: Manual Rebuild Steps

If the script doesn't work, follow these steps manually:

1. **Clean Intermediate Files**
   - Delete the following directories:
     - Binaries/
     - Intermediate/
     - Saved/Temp/
     - .vs/
     - All plugin Binaries/ and Intermediate/ folders

2. **Fix ImGui Plugin**
   - Ensure `UnrealClasses.h` exists in `Plugins/UnrealImGui-IMGUI_1.74/Source/ImGui/Private/`
   - Verify `ImGui.uplugin` uses "Type": "DeveloperTool" instead of "Type": "Developer"
   - Update includes in WorldContext.cpp and WorldContext.h to use modern paths

3. **Regenerate Project Files**
   - Right-click on `Dreamer1.uproject` and select "Generate Visual Studio project files"

4. **Open in Unreal Editor**
   - Double-click on `Dreamer1.uproject`
   - When prompted to rebuild modules, select "Yes"

## Working with Git and GitHub

### Repository Information

This project is connected to GitHub at: https://github.com/TaoAthe/Dreamer1.git

### Basic Git Commands

#### Check Status
```
cd "C:\Users\Sarah\Documents\Unreal Projects\Dreamer1"
git status
```

#### Commit Changes
```
git add .
git commit -m "Description of changes"
```

#### Push to GitHub
```
git push
```

#### Get Latest Changes
```
git pull
```

### Typical Workflow

1. **Before Starting Work**
   ```
   git pull
   ```
   This ensures you have the latest code from the repository.

2. **While Working**
   Make changes to your project files locally.

3. **After Completing Changes**
   ```
   git add .
   git commit -m "Describe what you changed"
   git push
   ```
   This saves your changes and uploads them to GitHub.

### Resolving Conflicts

If you encounter merge conflicts:

1. Open the conflicted files
2. Look for sections marked with `<<<<<<< HEAD`, `=======`, and `>>>>>>> branch`
3. Edit the files to resolve conflicts
4. Save the files
5. `git add .` the resolved files
6. `git commit` to complete the merge

## Plugins in this Project

### InEditorCpp
Your custom editor plugin that provides in-editor C++ functionality.

### UnrealImGui-IMGUI_1.74
Provides ImGui integration for creating custom UI in the Unreal Editor.

## Troubleshooting

### "Dreamer1 could not be compiled"
- Run the `ManualRebuild.bat` script
- Make sure Visual Studio has the necessary workloads installed:
  - Game development with C++
  - .NET desktop development

### "The following modules are missing or built with a different engine version"
- Select "Yes" to rebuild modules
- If that fails, run `ManualRebuild.bat`

### Git Issues
- Check that you're on the right branch: `git branch`
- Verify remote repository: `git remote -v`
- Ensure you have the latest changes: `git pull`

## Need More Help?

Refer to these resources:
- [Unreal Engine Documentation](https://docs.unrealengine.com/)
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Help](https://help.github.com/)