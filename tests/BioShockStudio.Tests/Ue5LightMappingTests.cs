using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// What the UE5 light importer is allowed to assume about a level manifest.
/// </summary>
/// <remarks>
/// Phase 1.4. <c>import_level.py</c> maps <c>LightBrightness</c> onto intensity as a scale (no
/// <c>* 1000</c>) and <c>LightRadius</c> onto attenuation radius in centimetres. That mapping is
/// only honest if the manifest still carries those fields as authored, and if some lights still
/// omit a radius — those must not acquire a guessed one.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class Ue5LightMappingTests(GameFixture game)
{
    [RequiresGameFact]
    public void LighthouseLightsExportAuthoredBrightnessAndRadius()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var document = LevelSceneExporter.ToDocument(
            LevelSceneBuilder.Build(package, LevelAnalyzer.Analyze(package)), includeGeometry: false);

        Assert.True(document.Lights.Count > 100, $"only {document.Lights.Count} lights");

        int withRadius = document.Lights.Count(light => light.Radius is > 0);
        int withoutRadius = document.Lights.Count(light => light.Radius is null or <= 0);
        int withBrightness = document.Lights.Count(light => light.Brightness is > 0);

        Assert.True(withRadius > 100, $"only {withRadius} lights stated a usable radius");
        Assert.True(withoutRadius > 0,
            "every light stated a radius, so the importer's drop-if-unknown path is unexercised");
        Assert.True(withBrightness > 100, $"only {withBrightness} lights stated a brightness");
        Assert.All(
            document.Lights.Where(light => light.Brightness is not null),
            light => Assert.InRange(light.Brightness!.Value, 0f, 8f));
    }
}
