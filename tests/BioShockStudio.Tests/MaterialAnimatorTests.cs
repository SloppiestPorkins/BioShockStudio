using System.Text.Json;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// UV and colour animators — Gate 1 item 4's "panners/rotators".
/// </summary>
/// <remarks>
/// The finding worth pinning is that <b>the reference projects do not describe these</b>. UModel
/// documents UE2's `TexPanner` (`PanDirection`, `PanRate`) and `TexRotator` (`TexRotationType`,
/// `UOffset`/`VOffset`, an oscillation triple). This game ships neither name nor either layout: it
/// ships `TexturePanner` (`UPan`/`VPan`/`PanTime`), `TextureRotator` (`Rotation`/`Duration`/
/// `UCenter`/`VCenter`), `TextureScalar` and `ColorCycle`. Decoding by the reference layout would
/// have produced confident nonsense, which is exactly what the project's "read the references, then
/// check them against the bytes" rule exists to catch.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class MaterialAnimatorTests(GameFixture game)
{
    private static List<BioShockMaterial> Materials(BioShockPackage package)
    {
        var result = new List<BioShockMaterial>();
        foreach (var export in package.Exports)
        {
            if (!MaterialReader.IsMaterialClass(package.GetClassName(export))) continue;

            BioShockMaterial? material;
            try { material = MaterialReader.Read(package, export); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (material is not null) result.Add(material);
        }
        return result;
    }

    [RequiresGameFact]
    public void PannersDecodeTheirScrollRate()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var panners = Materials(package)
            .SelectMany(m => m.Animators)
            .Where(a => a.Kind == MaterialAnimatorKind.Panner)
            .ToList();

        Assert.NotEmpty(panners);
        Assert.All(panners, a => Assert.Equal("TexturePanner", a.ClassName));

        // A panner that scrolls in neither axis would be pointless; most declare at least one.
        Assert.Contains(panners, a => a.PanU is not null || a.PanV is not null);
        Assert.Contains(panners, a => a.PanU is not 0f or null);

        // The slot says what is being animated — that is the whole value of keeping it.
        Assert.All(panners, a => Assert.False(string.IsNullOrEmpty(a.Slot)));
    }

    [RequiresGameFact]
    public void RotatorsDecodeThreeRotationComponents()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var rotators = Materials(package)
            .SelectMany(m => m.Animators)
            .Where(a => a.Kind == MaterialAnimatorKind.Rotator)
            .ToList();

        Assert.NotEmpty(rotators);
        Assert.All(rotators, a => Assert.Equal("TextureRotator", a.ClassName));

        // Rotation is three int32 and is read whole or not at all.
        var withRotation = rotators.Where(a => a.Rotation is not null).ToList();
        Assert.NotEmpty(withRotation);
        Assert.All(withRotation, a => Assert.Equal(3, a.Rotation!.Length));

        // Not converted to degrees: whether these are Unreal rotator units is PLAUSIBLE only, and a
        // wrong conversion would be invisible here and obvious on screen.
        Assert.Contains(withRotation, a => a.Rotation!.Any(c => c != 0));
    }

    /// <summary>
    /// An animator binding no longer lands in the uninterpreted pile.
    /// </summary>
    /// <remarks>
    /// This is the regression that matters: before, every animator binding was reported as an
    /// unhandled property, which is indistinguishable from a property the reader does not
    /// understand at all.
    /// </remarks>
    [RequiresGameFact]
    public void AnimatorBindingsAreNoLongerReportedAsUninterpreted()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var animated = Materials(package).Where(m => m.Animators.Count > 0).ToList();
        Assert.NotEmpty(animated);

        foreach (var material in animated)
            foreach (var animator in material.Animators)
                Assert.DoesNotContain(animator.Slot, material.UnhandledProperties);
    }

    /// <summary>
    /// A `MaterialSequence` bound to a slot now reaches the material.
    /// </summary>
    /// <remarks>
    /// <c>MaterialSequenceReader</c> has decoded these for a long time and
    /// <c>MaterialClassTests</c> covers the reader directly. What was missing was anything calling
    /// it from the material walk, so a sequence binding was reported as an unknown property — the
    /// same wiring gap as the animators, and the same shape as the roadmap entry that called this
    /// undecoded when the decoder already existed.
    /// </remarks>
    [RequiresGameFact]
    public void ASequenceBoundToASlotReachesTheMaterial()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var withSequences = Materials(package).Where(m => m.Sequences.Count > 0).ToList();
        Assert.NotEmpty(withSequences);

        foreach (var material in withSequences)
        {
            foreach (var bound in material.Sequences)
            {
                Assert.False(string.IsNullOrEmpty(bound.Slot));

                // ...and it is no longer reported as a property the reader does not understand.
                Assert.DoesNotContain(bound.Slot, material.UnhandledProperties);
            }
        }

        // At least one carries real timeline items rather than an empty shell.
        Assert.Contains(withSequences.SelectMany(m => m.Sequences), b => b.Sequence.Items.Count > 0);
    }

    /// <summary>
    /// Placed level materials keep the animators already on <see cref="SceneMaterial"/>, so a UE5
    /// importer can see that a surface moved without inventing panner units.
    /// </summary>
    [RequiresGameFact]
    public void LighthouseLevelManifestCarriesPlacedMaterialAnimators()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var scene = LevelSceneBuilder.Build(package, LevelAnalyzer.Analyze(package));

        string directory = Path.Combine(Path.GetTempPath(), "bioshock-level-animators-" + Guid.NewGuid().ToString("N"));
        try
        {
            LevelSceneExporter.Write(scene, directory, LevelExportFormats.Ue5Manifest, readable: false, package);
            string json = File.ReadAllText(Path.Combine(directory, scene.PackageName + ".ue5-level.json"));
            var document = JsonSerializer.Deserialize<LevelDocument>(
                json, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase })!;

            Assert.NotEmpty(document.Materials);
            var withAnimators = document.Materials.Where(m => m.Animators.Count > 0).ToList();
            Assert.True(withAnimators.Count > 0,
                "0-Lighthouse placed materials carried no animators; the package itself has panners, so the copy onto LevelMaterialDocument dropped them");
            Assert.Contains(withAnimators.SelectMany(m => m.Animators),
                a => a.Kind == MaterialAnimatorKind.Panner && (a.PanU is not null || a.PanV is not null));
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    /// <summary>
    /// All four animator classes are recognised, and nothing else claims to be one.
    /// </summary>
    [RequiresGameFact]
    public void OnlyTheFourKnownClassesAreAnimators()
    {
        Assert.True(MaterialAnimatorReader.IsAnimatorClass("TexturePanner"));
        Assert.True(MaterialAnimatorReader.IsAnimatorClass("TextureRotator"));
        Assert.True(MaterialAnimatorReader.IsAnimatorClass("TextureScalar"));
        Assert.True(MaterialAnimatorReader.IsAnimatorClass("ColorCycle"));

        // UE2's names, which this game does not ship. If one of these ever starts matching, the
        // census was wrong about which classes exist.
        Assert.False(MaterialAnimatorReader.IsAnimatorClass("TexPanner"));
        Assert.False(MaterialAnimatorReader.IsAnimatorClass("TexRotator"));

        Assert.False(MaterialAnimatorReader.IsAnimatorClass("Texture"));
        Assert.False(MaterialAnimatorReader.IsAnimatorClass("Shader"));
    }
}
