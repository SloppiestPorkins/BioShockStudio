using UnrealBuildTool;

public class BioShockImportTools : ModuleRules
{
    public BioShockImportTools(ReadOnlyTargetRules Target) : base(Target)
    {
        PrivateDependencyModuleNames.AddRange(new[] { "Core", "CoreUObject", "Engine", "UnrealEd" });
    }
}
