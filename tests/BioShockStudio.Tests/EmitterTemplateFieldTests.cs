using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Pins the widened <see cref="EmitterTemplateData"/> fields against real bytes. Only the four
/// fields (<c>Material</c>, <c>MaxParticles</c>, <c>ParticlesPerSecond</c>,
/// <c>InitialParticlesPerSecond</c>) were previously typed; this exercises the rest of
/// docs/research/effects.md §5, including that an unserialised property returns null rather than a
/// class-default guess, and the three curve arrays (<c>SizeScale</c>/<c>ColorScale</c>/
/// <c>VelocityScale</c>) added in the same pass.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class EmitterTemplateFieldTests(GameFixture game)
{
    [RequiresGameFact]
    public void ASpriteEmitterTemplateDecodesItsRangesFlagsAndByteEnums()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);

        var actor = context.Actors.Single(a => a.Source.ExportIndex == 9616);
        var template = Assert.Single(actor.Emitters!.Templates, t => t.Source.Source?.ExportIndex == 25099);

        Assert.Equal("SpriteEmitter4", template.Source.ObjectName);
        Assert.Equal("CannonSmoke_Shader", template.Material?.ObjectName);
        Assert.Equal(2f, template.ParticlesPerSecond);
        Assert.Equal(2f, template.InitialParticlesPerSecond);
        Assert.False(template.AutomaticInitialSpawning);
        Assert.False(template.RespawnDeadParticles);

        Assert.Equal(new FloatRange(5, 5), template.LifetimeRange);
        Assert.Equal(new AxisRange(new(10, 20), new(100, 100), new(100, 100)), template.StartSizeRange);
        Assert.True(template.UniformSize);
        Assert.True(template.UseSizeScale);
        Assert.False(template.UseRegularSizeScale);

        Assert.Equal(new AxisRange(new(0, 5), new(-5, 5), new(10, 20)), template.StartVelocityRange);
        Assert.Equal(new AxisRange(new(-15, 15), new(-15, 15), new(0, 0)), template.StartLocationRange);
        Assert.Equal(new System.Numerics.Vector3(15, 0, 0), template.StartLocationOffset);

        Assert.Equal(new AxisRange(new(-180, 180), new(0, 0), new(0, 0)), template.StartSpinRange);
        Assert.Equal(new AxisRange(new(0.01f, 0.05f), new(0, 0), new(0, 0)), template.SpinsPerSecondRange);
        Assert.True(template.SpinParticles);
        Assert.True(template.UseColorScale);

        Assert.Equal(
            new List<FloatCurveKey> { new(0, 3), new(0.4f, 3), new(1, 3) },
            template.SizeScale!.ToList());
        Assert.Equal(
            new List<ColorCurveKey>
            {
                new(0, new(255, 255, 255, 0)),
                new(0.1f, new(255, 255, 255, 30)),
                new(0.2f, new(255, 255, 255, 30)),
                new(1, new(255, 255, 255, 0)),
            },
            template.ColorScale!.ToList());
        Assert.Equal(
            new List<VectorCurveKey>
            {
                new(0, new(1, 1, 1)),
                new(0.5f, new(1, 1, 1)),
                new(1, new(1.5f, 1.5f, 1.5f)),
            },
            template.VelocityScale!.ToList());

        // Byte enums: values only, meaning UNKNOWN (docs/research/effects.md §6). Not asserted as
        // "the wind-smoke blend mode" or similar — that would promote a guess to a fact.
        Assert.Equal((byte)1, template.Blending);
        Assert.Equal((byte)1, template.CoordinateSystem);
        Assert.Equal(2, template.TextureUSubdivisions);
        Assert.Equal(1, template.TextureVSubdivisions);

        // Fields this specific template does not serialise (UE2 writes only non-defaults) must
        // read null, not a fabricated class-default value.
        Assert.Null(template.MaxParticles);
        Assert.Null(template.Acceleration);
        Assert.Null(template.StartLocationShape);

        Assert.True(template.PropertiesComplete);
    }

    [RequiresGameFact]
    public void AMeshEmitterTemplateExportsItsStaticMeshAsTheVisualInsteadOfASprite()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);

        var actor = context.Actors.Single(a => a.Source.ExportIndex == 3316);
        var template = Assert.Single(actor.Emitters!.Templates, t => t.Source.Source?.ExportIndex == 6014);

        Assert.Equal("MeshEmitter", template.Source.ClassName);
        Assert.Equal("debris_planechunkAA", template.StaticMesh?.ObjectName);
    }

    [RequiresGameFact]
    public void ARibbonEmitterTemplateDecodesItsSegmentCurves()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);

        var actor = context.Actors.Single(a => a.Source.ExportIndex == 14378);
        var template = Assert.Single(actor.Emitters!.Templates, t => t.Source.Source?.ExportIndex == 32856);

        Assert.Equal("RibbonEmitter", template.Source.ClassName);
        Assert.Equal(
            new List<FloatCurveKey> { new(0, 3), new(0.1f, 1), new(0.7f, 0.75f), new(1, 0.75f) },
            template.SegmentSizeScale!.ToList());
        Assert.Equal(
            new List<ColorCurveKey>
            {
                new(0, new(255, 255, 255, 255)),
                new(0.01f, new(255, 255, 255, 255)),
                new(1, new(255, 255, 255, 255)),
            },
            template.SegmentColorScale!.ToList());
        Assert.True(template.PropertiesComplete);
    }

    [RequiresGameFact]
    public void TheWidenedFieldsReachTheLevelSceneExportManifest()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var context = LevelAnalyzer.Analyze(package);
        var document = LevelSceneExporter.ToDocument(LevelSceneBuilder.Build(package, context), includeGeometry: false);

        var actor = Assert.Single(document.Actors, a => a.ExportIndex == 9616);
        var template = Assert.Single(actor.Emitters!.Templates, t => t.Source?.ObjectName == "SpriteEmitter4");

        Assert.Equal(new[] { 5f, 5f }, template.LifetimeRange);
        Assert.Equal(new[] { 10f, 20f, 100f, 100f, 100f, 100f }, template.StartSizeRange);
        Assert.True(template.UniformSize);
        Assert.Equal((byte)1, template.Blending);
        Assert.Null(template.MaxParticles);

        var sizeKey = Assert.Single(template.SizeScale!, k => k.RelativeTime == 0.4f);
        Assert.Equal(3f, sizeKey.Value);
        var colorKey = Assert.Single(template.ColorScale!, k => k.RelativeTime == 0.1f);
        Assert.Equal(new byte[] { 255, 255, 255, 30 }, colorKey.Color);
    }
}
