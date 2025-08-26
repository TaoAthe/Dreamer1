# Dreamer1 Unreal Project

This repository contains the Dreamer1 Unreal Engine project, which includes a custom C++ editor plugin called InEditorCpp that provides additional functionality to the editor.

## Features

- InEditorCpp plugin with ImGui integration for custom editor UI
- clangd language service support for improved C++ editing
- ImGuiColorTextEdit third-party dependency for code editing capabilities

## Plugin Structure

The main plugin (InEditorCpp) includes:
- Core editor integration
- ImGui-based UI elements (when ImGui is available)
- Text editing capabilities

## Development Setup

### Requirements
- Unreal Engine (compatible version)
- Visual Studio or other compatible C++ IDE
- Git LFS (for large binary files)

### Getting Started
1. Clone this repository
2. Open the Dreamer1.uproject file with Unreal Engine
3. If prompted to rebuild modules, select Yes

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the terms specified in the LICENSE file.