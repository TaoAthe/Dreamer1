# Getting Started with Dreamer C++ IDE

This guide will help you get started with using the Dreamer C++ IDE plugin for Unreal Engine.

## Opening the C++ Editor

Once the plugin is installed and enabled, you can open the C++ Editor in two ways:

1. From the main menu: Window > C++ Editor
2. Using the keyboard shortcut: Ctrl+Shift+E

## Interface Overview

The C++ Editor interface consists of:

- **Toolbar**: Contains buttons for common actions like building, refreshing the file list, and saving files
- **File Browser**: A tree view showing your project's source files organized by directories and modules
- **Code Editor**: The main editing area with syntax highlighting for C++ code
- **Build Error List**: A separate panel showing compilation errors and warnings

## Basic Usage

### Browsing Files

The file browser on the left side of the editor shows all C++ files in your project, organized into:
- Source: Your project's main source code
- Plugins: Source code from all plugins in your project

Click on directories to expand/collapse them, and click on individual files to open them in the editor.

### Editing Code

- Click on a file in the file browser to open it in the editor
- Edit the code as you would in any text editor
- Syntax highlighting will make it easier to read and write C++ code
- Click the "Save" button in the toolbar to save your changes

### Building Your Code

The plugin now includes full integration with Unreal's build system:

1. Click the "Build" button in the toolbar to compile your code
2. A progress bar will show the build status
3. When complete, any errors or warnings will be displayed in the Build Errors panel
4. Click on an error to navigate directly to the problematic code
5. Error locations are also highlighted directly in the code editor

You can access the Build Errors panel by:
- Clicking the "Errors" button in the toolbar
- Using the keyboard shortcut: Ctrl+Shift+L
- From the main menu: Window > Build Errors

### Refreshing the File List

If you add new files to your project outside the editor, click the "Refresh" button in the toolbar to update the file browser.

## Tips for Efficient Workflow

- Use the C++ Editor for quick edits and tweaks
- The build integration lets you compile without switching applications
- Click directly on build errors to jump to the problematic code
- For larger refactoring tasks, consider using your main IDE (Visual Studio, etc.)
- The plugin works well alongside Live Coding for testing changes without restarting the editor

## Troubleshooting

If you encounter any issues:
- Make sure the plugin is properly enabled in Edit > Plugins
- Restart the Unreal Editor if the C++ Editor doesn't appear
- Check that your project is set up for C++ development (has Source directory and .Build.cs files)
- If builds fail without clear errors, check the Output Log in Unreal Editor for more details

## Coming Soon

Future updates will include:
- Code completion and IntelliSense-like features
- Debugging integration
- Go-to-definition and find references functionality
- Multi-tab editing support