using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Turning a name into a browsable catalogue row — the one navigation rule.
/// </summary>
/// <remarks>
/// <para>
/// The Problems panel and the details panel's relationship list both navigate by name. The rule
/// lived in the view model first and was already duplicated once, which is how two callers end up
/// disagreeing about which asset a click opens. <see cref="AssetCatalogService.Resolve"/> is now the
/// single implementation and these tests are on it rather than on the window.
/// </para>
/// <para>
/// The case that matters is the one that has already been got wrong on real data: a row's reported
/// <c>Package</c> is not the only package it is in.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class AssetNavigationTests(GameFixture game)
{
    private AssetCatalogService Loaded()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        catalog.BuildAsync(game.RequireRoot).GetAwaiter().GetResult();
        return catalog;
    }

    [RequiresGameFact]
    public void AKnownAssetResolvesToItsRow()
    {
        var catalog = Loaded();

        var hands = catalog.Resolve("NEWPlayerHands");
        Assert.True(hands is not null, "NEWPlayerHands did not resolve to a catalogue row");
        Assert.Equal("NEWPlayerHands", hands!.Name, ignoreCase: true);
    }

    /// <summary>
    /// An asset several maps embed resolves through the package it was referenced from, not only
    /// through the one the collapsed row happens to report.
    /// </summary>
    /// <remarks>
    /// This is the failure that reached a render: <c>Cheese_Mould_Normal</c> is raised as a
    /// diagnostic in <c>0-Lighthouse</c> and listed by the catalogue under another map, so matching
    /// on name <b>and</b> reported package found nothing and the click silently did nothing.
    /// </remarks>
    [RequiresGameFact]
    public void AnAssetSeveralMapsEmbedResolvesFromAnyOfThem()
    {
        var catalog = Loaded();

        var shared = catalog.Entries.FirstOrDefault(e => e.Packages.Count > 1);
        Assert.True(shared is not null, "no collapsed row carries more than one package");

        foreach (string package in shared!.Packages)
        {
            var resolved = catalog.Resolve(shared.Name, package);
            Assert.True(resolved is not null,
                $"{shared.Name} did not resolve when referenced from {package}, though the row lists "
                + $"it: {string.Join(", ", shared.Packages)}");
        }
    }

    /// <summary>The copy in the referenced package wins when the catalogue lists one.</summary>
    [RequiresGameFact]
    public void ThePreferredPackageWinsWhenThereIsAChoice()
    {
        var catalog = Loaded();

        // A name with rows under more than one reported package — the only case where the preference
        // can be observed at all.
        var group = catalog.Entries
            .GroupBy(e => e.Name, StringComparer.OrdinalIgnoreCase)
            .FirstOrDefault(g => g.Select(e => e.Package)
                .Distinct(StringComparer.OrdinalIgnoreCase).Count() > 1);

        if (group is null) return;   // nothing in this install exercises the preference

        foreach (var entry in group)
        {
            var resolved = catalog.Resolve(entry.Name, entry.Package);
            Assert.True(resolved is not null);
            Assert.True(
                string.Equals(resolved!.Package, entry.Package, StringComparison.OrdinalIgnoreCase)
                || resolved.Packages.Contains(entry.Package, StringComparer.OrdinalIgnoreCase),
                $"resolving {entry.Name} from {entry.Package} returned the copy in "
                + $"{resolved.Package}, which does not carry that package");
        }
    }

    /// <summary>
    /// A name the catalogue does not list resolves to nothing rather than to something else.
    /// </summary>
    /// <remarks>
    /// The panel lists rows that are not assets — sockets, bones, "(no textures bound)" — and a
    /// resolver that returned a near match for those would open the wrong asset, which is worse than
    /// a click that reports it cannot.
    /// </remarks>
    [RequiresGameFact]
    public void AnUnknownNameResolvesToNothing()
    {
        var catalog = Loaded();

        Assert.Null(catalog.Resolve("(no textures bound)"));
        Assert.Null(catalog.Resolve("this-asset-does-not-exist-1234"));
        Assert.Null(catalog.Resolve(""));
        Assert.Null(catalog.Resolve("   "));
    }

    /// <summary>A category filter restricts the answer rather than being ignored.</summary>
    [RequiresGameFact]
    public void ACategoryFilterIsHonoured()
    {
        var catalog = Loaded();

        var texture = catalog.Entries.First(e => e.Category == AssetCategory.Textures);

        Assert.Equal(AssetCategory.Textures,
            catalog.Resolve(texture.Name, texture.Package, AssetCategory.Textures)?.Category);

        // The same name asked for as an animation must not come back as the texture.
        var wrong = catalog.Resolve(texture.Name, texture.Package, AssetCategory.Animations);
        Assert.True(wrong is null || wrong.Category == AssetCategory.Animations);
    }
}
