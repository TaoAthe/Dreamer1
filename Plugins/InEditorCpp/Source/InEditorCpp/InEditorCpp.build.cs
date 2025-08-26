/*
 * File: /Source/InEditorCpp/InEditorCpp.Build.cs
 * 
 * Purpose: Build Configuration
 * Defines the build configuration for the native C++ editor plugin, including:
 * - ImGui integration
 * - clangd language service support
 * - Module dependencies and includes
 * - Third-party library management
 */

using UnrealBuildTool;
using System.IO;
using System;

public class InEditorCpp : ModuleRules
{
    public InEditorCpp(ReadOnlyTargetRules Target) : base(Target)
    {
        // Editor-only module configuration
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        PrivatePCHHeaderFile = "Private/InEditorCppPrivatePCH.h";
        
        // Modern C++ support
        bLegacyPublicIncludePaths = false;
        CppStandard = CppStandardVersion.Cpp17;

        // Core dependencies
        PublicDependencyModuleNames.AddRange(new[] {
            "Core",
            "CoreUObject",
            "Engine",
            "Slate",
            "SlateCore",
            "ApplicationCore",
            "InputCore"
        });

        // Editor and tool dependencies
        PrivateDependencyModuleNames.AddRange(new[] {
            "UnrealEd",
            "LevelEditor",
            "EditorStyle",
            "Projects",
            "DesktopPlatform",
            "Json",
            "JsonUtilities",
            "ToolMenus",
            "WorkspaceMenuStructure"
        });
        
        // ImGui dependency
        bool imguiFound = false;
        
        if (Target.Platform == UnrealTargetPlatform.Win64)
        {
            // Check if ImGui module exists and add it as dependency
            if (ModuleExists("ImGui"))
            {
                PrivateDependencyModuleNames.Add("ImGui");
                PublicDefinitions.Add("WITH_IMGUI=1");
                imguiFound = true;
                Console.WriteLine("ImGui module found and added as dependency");
            }
            // Check if mGui module exists and add it as dependency
            else if (ModuleExists("mGui"))
            {
                PrivateDependencyModuleNames.Add("mGui");
                PublicDefinitions.Add("WITH_IMGUI=1");
                imguiFound = true;
                Console.WriteLine("mGui module found and added as dependency");
            }
            else
            {
                // Fall back to a dummy implementation when ImGui is not available
                PublicDefinitions.Add("WITH_IMGUI=0");
                Console.WriteLine("No ImGui module found. Plugin will load with limited functionality.");
            }
            
            PublicDefinitions.Add("WITH_CLANGD_SERVICE=1");
        }
        
        // Add ImGuiColorTextEdit third-party dependency
        string ThirdPartyPath = Path.Combine(PluginDirectory, "ThirdParty");
        string TextEditorPath = Path.Combine(ThirdPartyPath, "ImGuiColorTextEdit");
        
        // Make sure the directory exists
        if (!Directory.Exists(ThirdPartyPath))
        {
            Directory.CreateDirectory(ThirdPartyPath);
        }
        
        if (!Directory.Exists(TextEditorPath))
        {
            Directory.CreateDirectory(TextEditorPath);
        }
        
        // Always include this path, it will contain our fallback implementation if needed
        PublicIncludePaths.Add(TextEditorPath);
        Console.WriteLine("Using TextEditor from: " + TextEditorPath);
    }
    
    private bool ModuleExists(string ModuleName)
    {
        // Helper method to check if a module exists
        foreach (string IncludePath in Target.AdditionalPluginDirectories)
        {
            string PotentialPath = Path.Combine(IncludePath, ModuleName);
            if (Directory.Exists(PotentialPath))
            {
                Console.WriteLine($"Found {ModuleName} in {PotentialPath}");
                return true;
            }
            
            string ThirdPartyPath = Path.Combine(IncludePath, ModuleName, "Source", "ThirdParty");
            if (Directory.Exists(ThirdPartyPath))
            {
                Console.WriteLine($"Found {ModuleName} ThirdParty in {ThirdPartyPath}");
                return true;
            }
        }
        
        // Check engine plugins
        string EnginePath = Target.RelativeEnginePath;
        string EnginePluginPath = Path.Combine(EnginePath, "Plugins");
        if (Directory.Exists(EnginePluginPath))
        {
            string PotentialPath = Path.Combine(EnginePluginPath, ModuleName);
            if (Directory.Exists(PotentialPath))
            {
                Console.WriteLine($"Found {ModuleName} in engine plugins: {PotentialPath}");
                return true;
            }
        }
        
        // Check project plugins
        string ProjectPluginPath = Path.GetFullPath(Path.Combine(PluginDirectory, "..", "..", "Plugins"));
        if (Directory.Exists(ProjectPluginPath))
        {
            // Check direct path
            string PotentialPath = Path.Combine(ProjectPluginPath, ModuleName);
            if (Directory.Exists(PotentialPath))
            {
                Console.WriteLine($"Found {ModuleName} in project plugins: {PotentialPath}");
                return true;
            }
            
            // Check all subdirectories for the module
            try
            {
                foreach (string subDir in Directory.GetDirectories(ProjectPluginPath))
                {
                    if (Path.GetFileName(subDir).Contains(ModuleName))
                    {
                        Console.WriteLine($"Found {ModuleName} in project plugins subdirectory: {subDir}");
                        return true;
                    }
                    
                    // Check Source folder if it exists
                    string sourcePath = Path.Combine(subDir, "Source", ModuleName);
                    if (Directory.Exists(sourcePath))
                    {
                        Console.WriteLine($"Found {ModuleName} in project plugin source: {sourcePath}");
                        return true;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error checking project plugins: {ex.Message}");
            }
        }
        
        // Check in the current plugin directory
        string CurrentPluginPath = PluginDirectory;
        if (Directory.Exists(CurrentPluginPath))
        {
            // Check parent directory (may contain other plugins)
            string ParentPath = Path.GetFullPath(Path.Combine(CurrentPluginPath, ".."));
            if (Directory.Exists(ParentPath))
            {
                foreach (string subDir in Directory.GetDirectories(ParentPath))
                {
                    if (Path.GetFileName(subDir).Contains(ModuleName))
                    {
                        Console.WriteLine($"Found {ModuleName} in parent directory: {subDir}");
                        return true;
                    }
                }
            }
        }
        
        Console.WriteLine($"Module {ModuleName} not found");
        return false;
    }
}
