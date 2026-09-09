using UnrealBuildTool;

public class BioShockRuntime : ModuleRules
{
    public BioShockRuntime(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        PublicDependencyModuleNames.AddRange(new[]
        {
            "Core",
            "CoreUObject",
            "Engine",
            "InputCore",
            "UMG",
            "Slate",
            "SlateCore",
            "AIModule",
            "NavigationSystem",
            "Niagara",
        });
        PrivateDependencyModuleNames.AddRange(new[]
        {
            "AssetRegistry", "Json", "JsonUtilities",
            "SlateRHIRenderer", "RenderCore", // FWidgetRenderer + FlushRenderingCommands — HUD-overlay capture
        });
    }
}
