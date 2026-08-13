using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers animation sets — the game's own grouping of a character's animations.
/// </summary>
/// <remarks>
/// <c>AggressorBabyJane</c> is the case that needs it: five splicer meshes on one skeleton and 488
/// animations, which as a flat list is unusable. The sets come from the Havok root table's owner
/// column, so they are the game's grouping rather than one inferred from the names — though the
/// names corroborate it, with <c>ME_</c>, <c>PI_</c>, <c>SMG_</c> and <c>CR_</c> prefixes lining up
/// with Melee, Pistol, smg and Ceiling.
/// </remarks>
[Collection(GameCollection.Name)]
public sealed class AnimationSetTests(GameFixture game)
{
    private (MeshPreviewService Preview, CatalogEntry Entry) BabyJane()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(
            Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "7-Science.bsm"));
        var entry = AssetCatalogService.Catalogue(package, "7-Science")
            .Where(e => e.Group == "AggressorBabyJane")
            .MaxBy(e => e.SerialSize)!;

        return (new MeshPreviewService(catalog), entry);
    }

    [RequiresGameFact]
    public void BabyJaneAnimationsCarryTheirSet()
    {
        var (preview, entry) = BabyJane();
        var subject = preview.Load(entry);

        Assert.Equal(subject.Animations.Count, subject.AnimationSets.Count);
        Assert.All(subject.AnimationSets, a => Assert.False(string.IsNullOrWhiteSpace(a.Owner)));

        var owners = subject.AnimationSets.Select(a => a.Owner).Distinct().ToList();

        // The loadout and behaviour sets the game declares.
        foreach (string expected in new[] { "Melee", "Pistol", "smg", "Ceiling", "Assassin" })
            Assert.Contains(expected, owners);

        Assert.True(owners.Count >= 8, $"expected the full spread of sets, found {owners.Count}");
        Assert.True(subject.Animations.Count > 400, $"only {subject.Animations.Count} animations");
    }

    [RequiresGameFact]
    public void EachSetIsAMeaningfulSliceRatherThanEverything()
    {
        var (preview, entry) = BabyJane();
        var subject = preview.Load(entry);

        var bySet = subject.AnimationSets
            .GroupBy(a => a.Owner)
            .ToDictionary(g => g.Key, g => g.Count());

        // No set holds everything, and the big ones are real: the point of the grouping is that
        // choosing one leaves a list a person can read.
        Assert.All(bySet.Values, count => Assert.True(count < subject.Animations.Count));
        Assert.True(bySet["Melee"] > 50);
        Assert.True(bySet["Ceiling"] > 50);
    }

    [RequiresGameFact]
    public void TheNameOrderMatchesTheSetOrder()
    {
        var (preview, entry) = BabyJane();
        var subject = preview.Load(entry);

        // The two lists are parallel, so the UI can filter one by the other without a lookup.
        for (int i = 0; i < subject.Animations.Count; i++)
            Assert.Equal(subject.Animations[i], subject.AnimationSets[i].Name);
    }

    [RequiresGameFact]
    public void MeshVariantsAreOfferedAlongsideTheSets()
    {
        var (preview, entry) = BabyJane();
        var subject = preview.Load(entry);

        // Five splicer meshes share the one skeleton. Nothing in the data ties a mesh to a set —
        // the sets are loadouts, the meshes are outfits — so both are offered independently rather
        // than a pairing being invented.
        foreach (string mesh in new[] { "Agg_Doctor_Mesh", "Agg_Toasty_Mesh", "Agg_Waders_Mesh", "Agg_Rosebud_Mesh" })
            Assert.Contains(mesh, subject.Meshes);
    }

    [RequiresGameFact]
    public void AGroupWithOneSetStillReportsIt()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(game.LighthousePackage);
        var hands = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);

        var subject = new MeshPreviewService(catalog).Load(hands);

        Assert.Equal(130, subject.AnimationSets.Count);
        Assert.Contains("Pistol", subject.AnimationSets.Select(a => a.Owner));
    }
}
