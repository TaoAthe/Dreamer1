# Getting Started with Dreamer C++ IDE

This guide will help you get started with using the Dreamer C++ IDE plugin for Unreal Engine.

## Opening the C++ Editor

Once the plugin is installed and enabled, you can open the C++ Editor in two ways:

1. From the main menu: Window > C++ Editor
2. Using the keyboard shortcut: Ctrl+Shift+E

## Interface Overview

The C++ Editor interface consists of:

- **Toolbar**: Contains buttons for common actions like refreshing the file list and saving files
- **File Browser**: A tree view showing your project's source files organized by directories and modules
- **Code Editor**: The main editing area with syntax highlighting for C++ code

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

### Refreshing the File List

If you add new files to your project outside the editor, click the "Refresh" button in the toolbar to update the file browser.

## Integration with Unreal Build System

Future versions will include:
- Build button to compile your code
- Error display for compilation issues
- Live error checking as you type

## Tips for Efficient Workflow

- Use the C++ Editor for quick edits and tweaks
- For larger refactoring tasks, consider using your main IDE (Visual Studio, etc.)
- The plugin works well alongside Live Coding for testing changes without restarting the editor

## Troubleshooting

If you encounter any issues:
- Make sure the plugin is properly enabled in Edit > Plugins
- Restart the Unreal Editor if the C++ Editor doesn't appear
- Check that your project is set up for C++ development (has Source directory and .Build.cs files)