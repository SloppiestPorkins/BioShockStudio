using BioShockStudio.Core.Game;
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
