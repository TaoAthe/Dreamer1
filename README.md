# Dreamer1 Unreal Project

This repository contains the Dreamer1 Unreal Engine project, which includes a custom C++ editor plugin called Dreamer that provides an integrated development environment within the Unreal Editor.

## Features

- **Dreamer Plugin**: Integrated C++ development environment within Unreal Editor
  - Code editing with syntax highlighting
  - File browser for project navigation
  - Build system integration
  - Error reporting and navigation
  
- **Visual Studio Tools Integration**: Enhanced IDE support
  - Improved debugging capabilities
  - Breakpoint management
  - Project configuration

- **ImGui Integration**: Custom editor UI for code editing and visualization

## Plugin Structure

The main plugins in this project include:

- **Dreamer**: Core C++ IDE functionality
  - Editor integration
  - Build system
  - Code editing

- **VisualStudioTools**: Microsoft's official VS integration for Unreal Engine
  - Enhanced debugging
  - Better project integration

## Development Setup

### Requirements
- Unreal Engine 5.6 or later
- Visual Studio 2022 or later with these workloads:
  - Game development with C++
  - .NET desktop development
- Git LFS (for large binary files)

### Getting Started
1. Clone this repository
2. Open the Dreamer1.uproject file with Unreal Engine
3. If prompted to rebuild modules, select Yes
4. If you encounter build issues, use the included rebuild scripts:
   - ManualRebuild.bat: Full rebuild of the project
   - FixUnrealBuildTool.bat: Fix issues with the Unreal Build Tool
   - FixImGui.bat: Fix ImGui plugin issues
   - DeepClean.bat: Clean intermediate files

### Troubleshooting Build Issues

If you encounter the "could not fetch all available targets from the unreal build tool" error:

1. **Diagnose the Issue**:
   - Run `DiagnoseUBTIssue.bat` to identify the specific cause
   - The script will create targeted fix scripts based on its findings

2. **Fix the Issue**:
   - Run `FixUBTTargetError.bat` for a targeted fix
   - If that doesn't resolve the issue, run `EnhancedUBTFix.bat` (created by the diagnostic script)

These scripts address common issues like:
- Missing .NET dependencies
- Corrupted build rule files
- Plugin dependency problems
- Environment configuration issues

## Documentation

- **REBUILD_GUIDE.md**: Detailed instructions for rebuilding the project
- **Plugins/Dreamer/Documentation/**:
  - GettingStarted.md: Guide for using the Dreamer IDE
  - DevelopmentLog.md: History of development and feature implementation
  - BuildSystemIntegration.md: Technical details of the build system
- **TODO.md**: Current status and future development plans

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the terms specified in the LICENSE file.