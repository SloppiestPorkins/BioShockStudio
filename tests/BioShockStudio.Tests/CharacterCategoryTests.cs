using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Havok.Detection;
using BioShockStudio.Core.Havok.Packfile;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// What the browser calls a character, and what a character is offered to hold.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class CharacterCategoryTests(GameFixture game)
{
    private string Map(string name) =>
        Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), name + ".bsm");

    /// <summary>
    /// The ragdoll probe reads a bounded prefix rather than the whole payload. That is only sound
    /// while the class table stays inside the bound, so it is checked against a full packfile parse
    /// on every wrapper the game ships.
    /// </summary>
    [RequiresGameFact]
    public void TheRagdollProbeAgreesWithAFullClassTableWalk()
    {
        int wrappers = 0, positive = 0;

        foreach (string map in Directory.GetFiles(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
        {
            using var package = BioShockPackage.Open(map);
            foreach (var character in CharacterCatalog.Find(package))
            {
                var export = package.Exports
                    .Where(e => e.ObjectName == character.AnimationPackageObject
                                && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
                    .MaxBy(e => e.SerialSize);
                if (export is null) continue;

                bool parsed;
                try
                {
                    byte[] payload = package.ReadExportData(export);
                    var location = HavokDetector.FindFirst(payload);
                    if (location is null) continue;
                    parsed = HavokPackfile.Parse(payload, location.Value.Offset)
                        .EnumerateObjects().Any(o => o.ClassName == "hkaRagdollInstance");
                }
                catch { continue; }

                wrappers++;
                if (parsed) positive++;

                Assert.True(character.HasRagdoll == parsed,
                    $"{character.Group} in {Path.GetFileNameWithoutExtension(map)}: prefix probe said " +
                    $"{character.HasRagdoll}, the class table says {parsed}");
            }
        }

        Assert.True(wrappers > 500, $"only {wrappers} wrappers checked");
        Assert.True(positive > 100, $"only {positive} carried a ragdoll; the check would pass vacuously");
    }

    /// <summary>
    /// The security devices are characters. They were filed as props because they have two to six
    /// animations each and the old rule wanted twenty.
    /// </summary>
    [RequiresGameFact]
    public void SecurityTurretsAndBotsAreCharacters()
    {
        using var package = BioShockPackage.Open(Map("1-Medical"));
        var rows = AssetCatalogService.Catalogue(package, "1-Medical").ToList();

        foreach (string name in new[] { "SecurityBot", "TurretMachineGun", "TurretGrenadeLauncher" })
        {
            var row = rows.FirstOrDefault(r => r.Name == name);
            Assert.True(row is not null, $"{name} is not in the catalogue at all");
            Assert.Equal(AssetCategory.Characters, row!.Category);
            Assert.Contains("ragdoll", row.Detail, StringComparison.OrdinalIgnoreCase);
        }
    }

    /// <summary>
    /// A group holding several meshes is several characters sharing one rig. Each gets its own row
    /// carrying the group, so the shared animation package resolves; the group does not also get a
    /// row of its own that stands for none of them.
    /// </summary>
    [RequiresGameFact]
    public void EachSplicerVariantIsItsOwnCharacter()
    {
        using var package = BioShockPackage.Open(Map("ChallengeRoomCombat"));
        var rows = AssetCatalogService.Catalogue(package, "ChallengeRoomCombat")
            .Where(r => r.Group.Equals("AggressorBabyJane", StringComparison.OrdinalIgnoreCase))
            .ToList();

        var variants = rows.Where(r => r.Category == AssetCategory.Characters).ToList();
        Assert.True(variants.Count >= 6, $"only {variants.Count} splicer variants are characters");

        // Each one names its own mesh and carries the rig it shares.
        foreach (var variant in variants)
        {
            Assert.Equal(AssetClasses.SkeletalMesh, variant.ClassName);
            Assert.Equal("AggressorBabyJane", variant.OwnerGroup);
            Assert.Contains("shares", variant.Detail, StringComparison.OrdinalIgnoreCase);
        }

        // Named individually rather than all called after the rig.
        Assert.True(variants.Select(v => v.Name).Distinct().Count() == variants.Count,
            "the variants do not have distinct names");
        Assert.Contains(variants, v => v.Name.Contains("BabyJane", StringComparison.OrdinalIgnoreCase));

        // And the rig itself is not offered as a fourteenth character standing for none of them.
        Assert.DoesNotContain(rows, r =>
            r.Category == AssetCategory.Characters && r.ClassName == AssetClasses.AnimationPackageWrapper);
    }

    /// <summary>
    /// A splicer's mesh loads its own geometry, not the largest of the thirteen sharing its rig.
    /// </summary>
    [RequiresGameFact]
    public void ASplicerVariantLoadsItsOwnMesh()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(Map("ChallengeRoomCombat"));
        var variants = AssetCatalogService.Catalogue(package, "ChallengeRoomCombat")
            .Where(r => r.Category == AssetCategory.Characters && r.ClassName == AssetClasses.SkeletalMesh)
            .Where(r => r.Group.Equals("AggressorBabyJane", StringComparison.OrdinalIgnoreCase))
            .OrderBy(r => r.SerialSize)
            .ToList();

        Assert.True(variants.Count >= 2, "need at least two variants to tell them apart");

        // The smallest variant must not come back as the biggest one's geometry.
        var smallest = variants[0];
        var largest = variants[^1];

        var loadedSmall = new MeshPreviewService(catalog).Load(smallest);
        Assert.True(loadedSmall.Model.HasGeometry, $"{smallest.Name} produced no geometry");

        var loadedLarge = new MeshPreviewService(catalog).Load(largest);
        Assert.NotEqual(loadedLarge.Model.Vertices.Count, loadedSmall.Model.Vertices.Count);
    }

    /// <summary>
    /// An NPC carries <c>WP_AI_*</c>, a static mesh. The player's viewmodel of the same weapon is a
    /// different asset and must not be offered to an NPC on a name match alone.
    /// </summary>
    [RequiresGameFact]
    public void AnNpcIsOfferedTheNpcWeaponAndNotThePlayersViewmodel()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        var context = new AssetContextService(catalog);

        using var package = BioShockPackage.Open(Map("ChallengeRoomCombat"));
        var splicer = AssetCatalogService.Catalogue(package, "ChallengeRoomCombat")
            .First(r => r.Category == AssetCategory.Characters
                        && r.Name.Contains("BabyJane", StringComparison.OrdinalIgnoreCase));

        var attachments = context.Attachments(splicer);

        var pistol = attachments.FirstOrDefault(a => a.Socket.Equals("Pistol", StringComparison.OrdinalIgnoreCase));
        Assert.True(pistol is not null, "the splicer's Pistol socket resolved to nothing");
        Assert.Equal("WP_AI_Pistol", pistol!.MeshObject);
        Assert.True(pistol.IsNpcWeapon);

        Assert.Contains(attachments, a => a.MeshObject == "WP_AI_smg");

        // Nothing from the player's arsenal.
        Assert.DoesNotContain(attachments, a =>
            a.MeshObject.StartsWith("WP_", StringComparison.OrdinalIgnoreCase) && !a.IsNpcWeapon);
    }

    /// <summary>The first-person hands still get the player's viewmodels, on the stated relationship.</summary>
    [RequiresGameFact]
    public void TheFirstPersonHandsStillResolveTheirViewmodels()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(game.LighthousePackage);
        var hands = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .First(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);

        var attachments = new AssetContextService(catalog).Attachments(hands);

        Assert.Contains(attachments, a => a.Socket == "Pistol" && a.Confidence == "Confirmed");
        Assert.True(attachments.Count(a => a.Confidence == "Confirmed") >= 5,
            "the hands should still confirm most of the arsenal by root bone");
    }
}
