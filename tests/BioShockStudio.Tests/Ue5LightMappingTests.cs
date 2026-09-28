using System.Linq;
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

    /// <summary>
    /// W-BUG-01: spot/sun/directional aim needs the light actor's own rotation on the manifest.
    /// Round-trips a known non-identity rotator from Medical (same key in actors[] and lights[]).
    /// </summary>
    [RequiresGameFact]
    public void MedicalLightExportsActorRotation()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var scene = LevelSceneBuilder.Build(package, LevelAnalyzer.Analyze(package));
        var document = LevelSceneExporter.ToDocument(scene, includeGeometry: false);

        // DefaultSecurityCameraSpotlight3 in 1-Medical — package rotator yaw 16384 (90°).
        var light = Assert.Single(
            document.Lights, l => l.Name == "DefaultSecurityCameraSpotlight3");
        Assert.Equal(3, light.Rotation.Length);
        Assert.Equal(new[] { 0, 16384, 0 }, light.Rotation);

        // Spot-shaped lights (effect 2 per the Medical census / importer mapping) must carry a
        // rotator so the UE5 SpotLight can aim; at least one must be non-identity.
        var spots = document.Lights.Where(l => l.Effect == 2).ToList();
        Assert.True(spots.Count > 50, $"only {spots.Count} effect=2 lights");
        Assert.Contains(spots, l => l.Rotation[0] != 0 || l.Rotation[1] != 0 || l.Rotation[2] != 0);
    }
}
