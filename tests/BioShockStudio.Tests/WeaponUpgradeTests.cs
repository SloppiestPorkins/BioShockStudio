using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Every player weapon's upgrade tiers, including the two that hide in their own group.
/// </summary>
/// <remarks>
/// The game ships thirteen upgrade meshes across six weapons, named with a two-letter weapon prefix.
/// Eleven sit in their weapon's own group, so anything resolving by group found them; the other two
/// — <c>SG_UpgradeB</c> and <c>XB_UpgradeB_Mesh</c>, the two with their own rig — did not, which is
/// why upgrades appeared on some weapons and not others.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class WeaponUpgradeTests(GameFixture game)
{
    private BioShockPackage Weapons() =>
        BioShockPackage.Open(Core.Game.GameLocator.WeaponPackage(game.RequireRoot)!);

    /// <summary>All six weapons have upgrades, and the counts are the game's.</summary>
    [RequiresGameFact]
    public void EveryPlayerWeaponHasItsUpgradeTiers()
    {
        using var package = Weapons();

        var expected = new Dictionary<string, string[]>
        {
            ["WP_Pistol"] = ["PI_UpgradeA", "PI_UpgradeB", "PI_UpgradeBalt"],
            ["WP_Shotgun"] = ["SG_UpgradeA", "SG_UpgradeB"],
            ["WP_TommyGun"] = ["TG_upgradeA", "TG_upgradeB"],
            ["WP_Crossbow"] = ["XB_UpgradeA", "XB_UpgradeB_Mesh"],
            ["WP_ChemicalThrower"] = ["CT_UpgradeA", "CT_UpgradeB"],
            ["WP_GrenadeLauncher"] = ["GL_UpgradeA", "GL_UpgradeB"],
        };

        int total = 0;

        foreach (var (weapon, meshes) in expected)
        {
            var found = WeaponUpgrades.For(package, weapon);
            total += found.Count;

            Assert.Equal(
                meshes.OrderBy(m => m, StringComparer.OrdinalIgnoreCase),
                found.Select(u => u.MeshObject).OrderBy(m => m, StringComparer.OrdinalIgnoreCase));
        }

        Assert.Equal(13, total);
    }

    /// <summary>
    /// The two that used to be missed are the ones outside their weapon's group, and they are the
    /// ones with their own skeleton.
    /// </summary>
    [RequiresGameFact]
    public void TheUpgradesWithTheirOwnRigLiveOutsideTheWeaponsGroup()
    {
        using var package = Weapons();

        var shotgun = WeaponUpgrades.For(package, "WP_Shotgun").Single(u => u.Tier == "B");
        var crossbow = WeaponUpgrades.For(package, "WP_Crossbow").Single(u => u.Tier == "B");

        foreach (var upgrade in new[] { shotgun, crossbow })
        {
            Assert.True(upgrade.IsSkeletal, $"{upgrade.MeshObject} was expected to carry its own rig");
            Assert.False(string.Equals("WP_Shotgun", upgrade.Group, StringComparison.OrdinalIgnoreCase));
            Assert.False(string.Equals("WP_Crossbow", upgrade.Group, StringComparison.OrdinalIgnoreCase));
        }

        // And the in-group ones are static parts bolted to the weapon.
        Assert.All(WeaponUpgrades.For(package, "WP_Pistol"), u => Assert.False(u.IsSkeletal));
    }

    /// <summary>A name that is not an upgrade is not claimed as one.</summary>
    [RequiresGameFact]
    public void OnlyRealUpgradeNamesResolve()
    {
        Assert.Null(WeaponUpgrades.WeaponFor("WP_PistolMesh"));
        Assert.Null(WeaponUpgrades.WeaponFor("PI_AmmoType"));
        Assert.Null(WeaponUpgrades.WeaponFor("TG_AmmoModel"));
        Assert.Null(WeaponUpgrades.WeaponFor("shotgun_shell"));

        // An upgrade-shaped name with no known weapon prefix is not attributed to a weapon.
        Assert.Null(WeaponUpgrades.WeaponFor("ZZ_UpgradeA"));

        Assert.Equal("WP_Pistol", WeaponUpgrades.WeaponFor("PI_UpgradeA"));
        Assert.Equal("WP_Crossbow", WeaponUpgrades.WeaponFor("XB_UpgradeB_Mesh"));

        // A weapon with no upgrade tiers claims none.
        using var package = Weapons();
        Assert.Empty(WeaponUpgrades.For(package, "WP_Wrench"));
    }

    /// <summary>
    /// The preview offers them: selecting the shotgun lists its second-tier upgrade, which used to
    /// be invisible because it is in another group.
    /// </summary>
    [RequiresGameFact]
    public void ThePreviewOffersEveryUpgradeAsASelectableMesh()
    {
        var catalog = new Core.Services.AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = Weapons();

        foreach (var (weapon, expected) in new[]
                 {
                     ("WP_Shotgun", "SG_UpgradeB"),
                     ("WP_Crossbow", "XB_UpgradeB_Mesh"),
                     ("WP_Pistol", "PI_UpgradeA"),
                 })
        {
            var entry = Core.Services.AssetCatalogService.Catalogue(package, "ShockGame")
                .Where(e => e.Group == weapon)
                .MaxBy(e => e.SerialSize);
            if (entry is null) continue;

            var subject = new Core.Services.MeshPreviewService(catalog).Load(entry);
            Assert.Contains(expected, subject.Meshes);
        }
    }
}
