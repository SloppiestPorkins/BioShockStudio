using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The per-asset inspector: what an asset is, and where it lives.
/// </summary>
/// <remarks>
/// <para>
/// The details panel could already show an asset's fields, its relationships and its diagnostics,
/// but not a coherent answer to the two questions a user asks first. Each reader decided for itself
/// what to state — a texture gave its group, a mesh its group and class, an animation neither — so
/// the answer depended on which branch produced the row rather than on the asset.
/// </para>
/// <para>
/// Both blocks are built from the catalogue row in one place, which is what these tests pin: every
/// kind answers both questions, and an asset that fails to read still says what and where it is
/// rather than showing only an error.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class AssetInspectorTests(GameFixture game)
{
    private (AssetCatalogService Catalog, IReadOnlyList<CatalogEntry> Entries) Lighthouse()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(game.LighthousePackage);
        return (catalog, AssetCatalogService.Catalogue(package, "0-Lighthouse"));
    }

    private static string? Value(IReadOnlyList<DetailField> fields, string label) =>
        fields.FirstOrDefault(f => f.Label == label)?.Value;

    /// <summary>
    /// Every kind of asset answers "what is this" and "where is it".
    /// </summary>
    /// <remarks>
    /// One representative of each category the browser offers, because the fault this replaces was
    /// precisely that some kinds answered and others did not.
    /// </remarks>
    [RequiresGameFact]
    public void EveryKindOfAssetStatesWhatItIsAndWhereItIs()
    {
        var (catalog, entries) = Lighthouse();
        var details = new AssetDetailsService(catalog);

        var kinds = new[]
        {
            AssetCategory.Textures, AssetCategory.Materials, AssetCategory.StaticMeshes,
            AssetCategory.SkeletalMeshes, AssetCategory.Animations, AssetCategory.FirstPerson,
        };

        var missing = new List<string>();

        foreach (var kind in kinds)
        {
            var entry = entries.FirstOrDefault(e => e.Category == kind);
            if (entry is null) continue;   // this package does not ship one; not this test's business

            var described = details.Describe(entry);

            if (described.Identity.Count == 0) missing.Add($"{kind}: no identity");
            if (described.Location.Count == 0) missing.Add($"{kind}: no location");

            // The two facts every kind must state, whatever it is.
            if (Value(described.Identity, "Name") is not { Length: > 0 }) missing.Add($"{kind}: no Name");
            if (Value(described.Identity, "Kind") is not { Length: > 0 }) missing.Add($"{kind}: no Kind");
            if (Value(described.Identity, "Class") != entry.ClassName) missing.Add($"{kind}: wrong Class");
            if (Value(described.Location, "Read from") != entry.Package) missing.Add($"{kind}: wrong package");
        }

        Assert.True(missing.Count == 0,
            "these asset kinds do not answer what they are or where they live:"
            + Environment.NewLine + string.Join(Environment.NewLine, missing));
    }

    /// <summary>
    /// An asset several maps embed says so, and names the others.
    /// </summary>
    /// <remarks>
    /// This is the field that earns its place in the panel. A row's reported package is one of many
    /// — <c>NEWPlayerHands</c> is in all twenty maps — and treating the reported one as the only one
    /// has already produced a click that silently did nothing, on <c>Cheese_Mould_Normal</c>. A user
    /// who cannot see the rest of the list has no way to know that happened.
    /// </remarks>
    [RequiresGameFact]
    public void AnAssetInSeveralPackagesSaysWhichOnes()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        catalog.BuildAsync(game.RequireRoot).GetAwaiter().GetResult();

        var shared = catalog.Entries.FirstOrDefault(e => e.PackageCount > 1);
        Assert.True(shared is not null, "no collapsed row carries more than one package");

        var described = new AssetDetailsService(catalog).Describe(shared!);

        string? alsoIn = Value(described.Location, "Also in");
        Assert.True(alsoIn is { Length: > 0 },
            $"{shared!.Name} is in {shared.PackageCount} packages and the panel does not say so");

        // It names them rather than only counting them, and the count agrees with the row.
        Assert.Contains(shared.PackageCount.ToString(), alsoIn!, StringComparison.Ordinal);

        // A single-package asset must not claim otherwise.
        var only = catalog.Entries.First(e => e.PackageCount == 1);
        Assert.Null(Value(new AssetDetailsService(catalog).Describe(only).Location, "Also in"));
    }

    /// <summary>
    /// An asset that cannot be read still says what and where it is.
    /// </summary>
    /// <remarks>
    /// A panel that shows only an error when a decode fails throws away the part it does know. The
    /// identity and location come from the catalogue row, which is already in hand, so they survive
    /// a reader that throws.
    /// </remarks>
    [RequiresGameFact]
    public void AnUnreadableAssetStillStatesItsIdentity()
    {
        var (catalog, entries) = Lighthouse();

        // A row pointing at an export index the package does not have: the readers cannot resolve it,
        // which is the failure path without needing a corrupt asset to exist.
        var broken = entries.First(e => e.Category == AssetCategory.Textures) with
        {
            ExportIndex = int.MaxValue,
            ObjectName = "this-object-does-not-exist",
        };

        var described = new AssetDetailsService(catalog).Describe(broken);

        Assert.NotNull(described.Problem);
        Assert.NotEmpty(described.Identity);
        Assert.NotEmpty(described.Location);
        Assert.Equal(broken.Name, Value(described.Identity, "Name"));
        Assert.Equal(broken.Package, Value(described.Location, "Read from"));
    }
}
