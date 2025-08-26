using UnrealBuildTool;

public class InEditorCppTests : ModuleRules
{
    public InEditorCppTests(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        bLegacyPublicIncludePaths = false;
        
        PublicDependencyModuleNames.AddRange(new string[] {
            "Core",
            "CoreUObject",
            "Engine",
            "InputCore",
            "Slate",
            "SlateCore",
            "InEditorCpp"  // Our main plugin module
        });

        PrivateDependencyModuleNames.AddRange(new string[] {
            "ImGui",       // Will use mGui for ImGui integration
            "Projects",
            "DesktopPlatform"
        });

        // Add test framework dependencies
        PrivateDependencyModuleNames.AddRange(new string[] {
            "AutomationController",
            "FunctionalTesting"
        });
    }
}
