using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// A texture name is not unique across bulk-content groups, and the duplicates are different art —
/// not copies. Resolving one without its group put another group's texture on 340 of the game's
/// 30,831 texture exports.
/// </summary>
/// <remarks>
/// The visible case was the final boss: <c>Atlas_MESH</c> drew black with white streaks over it,
/// because <c>Atlas_Diffuse</c> resolved to the <c>Gen_Graffiti</c> group's "ATLAS IS WATCHING" wall
/// decal rather than to the <c>Atlas</c> group's skin. Both are 2048x2048 DXT1 in the same chunk,
/// 2.8 MB apart, so every size and format check passed on the wrong texture.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BulkTextureGroupTests(GameFixture game)
{
    private string BossFight => Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "7-BossFight.bsm");

    /// <summary>The catalogue really does hold different art under one name.</summary>
    [RequiresGameFact]
    public void ATextureNameCanNameDifferentArtInDifferentGroups()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        var bulk = catalog.Bulk;
        Assert.True(bulk is not null, "no BulkContent beside this install");

        var entries = bulk!.Entries
            .Where(e => string.Equals(e.Texture, "Atlas_Diffuse", StringComparison.OrdinalIgnoreCase))
            .ToList();

        Assert.Equal(2, entries.Count);
        Assert.Contains(entries, e => e.Group == "Atlas");
        Assert.Contains(entries, e => e.Group == "Gen_Graffiti");

        // Same chunk, different bytes — which is why nothing size-based could have caught this.
        Assert.Single(entries.Select(e => e.Chunk).Distinct());
        Assert.Equal(2, entries.Select(e => e.Offset).Distinct().Count());
    }

    /// <summary>The boss's skin must come from his own group, not from the graffiti.</summary>
    [RequiresGameFact]
    public void TheBossResolvesHisOwnSkinAndNotTheGraffitiThatSharesItsName()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        Assert.True(catalog.Bulk is not null, "no BulkContent beside this install");

        using var package = BioShockPackage.Open(BossFight);
        var export = package.Exports.First(e =>
            package.GetClassName(e) == "Texture"
            && string.Equals(e.ObjectName, "Atlas_Diffuse", StringComparison.OrdinalIgnoreCase));

        // The package states the group itself, in the export's outer.
        Assert.Equal("Atlas", package.ResolveName(export.OuterIndex));

        var resolved = TextureReader.Read(package, export, catalog.Bulk);
        var skin = TextureReader.Read(package, export, catalog.Bulk, "Atlas");
        var graffiti = TextureReader.Read(package, export, catalog.Bulk, "Gen_Graffiti");

        Assert.NotNull(resolved);
        Assert.NotNull(skin);
        Assert.NotNull(graffiti);

        // All three are 2048x2048 DXT1: the dimensions never distinguished them.
        Assert.Equal(2048, resolved!.Width);
        Assert.Equal(2048, graffiti!.Width);

        Assert.Equal(skin!.Mips[0].Data, resolved.Mips[0].Data);
        Assert.NotEqual(graffiti.Mips[0].Data, resolved.Mips[0].Data);
    }

    /// <summary>
    /// Game-wide: no texture whose outer names a catalogue group may resolve to a different one.
    /// </summary>
    [RequiresGameFact]
    public void NoTextureResolvesToAGroupOtherThanItsOwn()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        var bulk = catalog.Bulk;
        Assert.True(bulk is not null, "no BulkContent beside this install");

        int checkedTextures = 0, matched = 0;
        var wrong = new List<string>();

        foreach (string map in Directory.GetFiles(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
        {
            using var package = BioShockPackage.Open(map);
            foreach (var export in package.Exports.Where(e => package.GetClassName(e) == "Texture"))
            {
                string outer = package.ResolveName(export.OuterIndex);
                var own = bulk!.Find(export.ObjectName, outer);
                if (own is null || !string.Equals(own.Group, outer, StringComparison.OrdinalIgnoreCase)) continue;

                checkedTextures++;
                var chosen = bulk.Find(export.ObjectName, outer);
                if ((chosen!.Chunk, chosen.Offset) == (own.Chunk, own.Offset)) matched++;
                else if (wrong.Count < 10)
                    wrong.Add($"{export.ObjectName} in {Path.GetFileNameWithoutExtension(map)}: " +
                              $"took {chosen.Group}, own group is {outer}");
            }
        }

        Assert.True(checkedTextures > 20_000, $"only {checkedTextures} textures had a resolvable group");
        Assert.True(wrong.Count == 0, string.Join("; ", wrong));
        Assert.Equal(checkedTextures, matched);
    }
}
