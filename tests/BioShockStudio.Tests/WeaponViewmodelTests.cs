using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class WeaponViewmodelTests(GameFixture game)
{
    private static ObjectExport Find(BioShockPackage package, string group, string className) =>
        package.Exports
            .Where(e => string.Equals(AssetContextResolver.TopLevelGroup(package, e), group, StringComparison.OrdinalIgnoreCase)
                        && package.GetClassName(e) == className)
            .MaxBy(e => e.SerialSize)!;

    [RequiresGameFact]
    public void ScriptPackage_ParsesByteExact()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);

        // ShockGame.U is a 92 MB Unreal package, same format as the maps.
        Assert.Equal(new FileInfo(game.WeaponPackage).Length, package.ExportTableEnd);
        Assert.True(package.Exports.Count > 10_000);
    }

    [RequiresGameFact]
    public void WeaponViewmodelsLiveInTheScriptPackage()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);

        // Every first-person weapon is an animated skeletal mesh here, not in the map packages —
        // the map WP_* groups hold only ammo and pickup meshes.
        foreach (string weapon in new[] { "Pistol", "Shotgun", "TommyGun", "Crossbow", "ChemicalThrower", "GrenadeLauncher" })
        {
            var mesh = Find(package, "WP_" + weapon, AssetClasses.SkeletalMesh);
            Assert.NotNull(mesh);
            Assert.True(mesh.SerialSize > 100_000, $"{weapon} mesh is implausibly small");
        }
    }

    [RequiresGameFact]
    public void PistolHasItsOwnSkeletonRootedAtTheHandSocket()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        var wrapper = Find(package, "WP_Pistol", AssetClasses.AnimationPackageWrapper);
        var pistol = AnimationPackage.Load(package, wrapper);

        // The weapon is not a static prop: it has a rig whose root bone is the socket the hands
        // attach it to, and moving parts below it.
        Assert.Equal(8, pistol.Skeleton.BoneCount);
        Assert.Equal("R_grip", pistol.Skeleton.Bones[0].Name);
        Assert.True(pistol.Skeleton.Bones[0].IsRoot);

        var names = pistol.Skeleton.Bones.Select(b => b.Name).ToList();
        foreach (string part in new[] { "pistol_body", "hammer", "trigger", "barrel", "drum" })
            Assert.Contains(part, names);
    }

    [RequiresGameFact]
    public void HandSocketMatchesTheWeaponSkeletonRoot()
    {
        using var handsPackage = BioShockPackage.Open(game.LighthousePackage);
        var handsMesh = handsPackage.Exports
            .Where(e => e.ObjectName == "NEWPlayerHands" && handsPackage.GetClassName(e) == AssetClasses.SkeletalMesh)
            .MaxBy(e => e.SerialSize)!;
        var sockets = SkeletalMeshReader.ReadSockets(handsPackage.ReadExportData(handsMesh), handsPackage.Names);

        string socketBone = sockets.First(s => s.Name == "Pistol").BoneName;

        using var weaponPackage = BioShockPackage.Open(game.WeaponPackage);
        var pistol = AnimationPackage.Load(weaponPackage, Find(weaponPackage, "WP_Pistol", AssetClasses.AnimationPackageWrapper));

        // This is the link that makes the weapon attach correctly: the hands' Pistol socket names
        // bone R_Grip, and the pistol's own skeleton is rooted at a bone of the same name.
        Assert.Equal(socketBone, pistol.Skeleton.Bones[0].Name, ignoreCase: true);
    }

    [RequiresGameFact]
    public void WeaponAnimationsAreFrameSynchronisedWithTheHandAnimations()
    {
        using var handsPackage = BioShockPackage.Open(game.LighthousePackage);
        var handsWrapper = handsPackage.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && handsPackage.GetClassName(e) == AssetClasses.AnimationPackageWrapper);
        var hands = AnimationPackage.Load(handsPackage, handsWrapper);

        using var weaponPackage = BioShockPackage.Open(game.WeaponPackage);
        var pistol = AnimationPackage.Load(weaponPackage, Find(weaponPackage, "WP_Pistol", AssetClasses.AnimationPackageWrapper));

        // The weapon animation and the hand animation for the same action have identical timing,
        // which is what lets them play together as one motion.
        foreach (var (weaponName, handName) in new[]
        {
            ("FastReload", "FastReloadPistol"),
            ("FireSingle", "FireSinglePistol"),
        })
        {
            var weaponAnimation = pistol.Find(weaponName);
            var handAnimation = hands.Find(handName);

            Assert.NotNull(weaponAnimation);
            Assert.NotNull(handAnimation);
            Assert.Equal(handAnimation!.FrameCount, weaponAnimation!.FrameCount);
            Assert.Equal(handAnimation.Duration, weaponAnimation.Duration, 3);
        }
    }

    [RequiresGameFact]
    public void PistolMeshDecodesAndIsSkinnedToItsOwnRig()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        var mesh = Find(package, "WP_Pistol", AssetClasses.SkeletalMesh);

        var geometry = SkeletalMeshReader.ReadGeometry(package.ReadExportData(mesh));
        Assert.NotNull(geometry);
        Assert.Equal(3736, geometry!.Vertices.Count);
        Assert.Equal(4865, geometry.TriangleCount);

        // Skinned to the weapon's own 8-bone rig, so the drum and hammer animate.
        Assert.All(geometry.BoneMap, index => Assert.InRange(index, 0, 7));
        Assert.All(geometry.Vertices, v => Assert.NotEmpty(v.Influences));
    }

    [RequiresGameFact]
    public void PistolAnimationsDecodeToRealMotion()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        var pistol = AnimationPackage.Load(package, Find(package, "WP_Pistol", AssetClasses.AnimationPackageWrapper));

        var reload = pistol.Find("FastReload")!;
        var decoded = pistol.Decode(reload);

        Assert.Equal(reload.FrameCount, decoded.FrameCount);

        // BioShock's pistol is a top-break revolver: the reload hinges the barrel assembly open
        // rather than swinging a cylinder out, so it is the barrel that has to move.
        int barrel = pistol.Skeleton.Bones.First(b => b.Name == "barrel").OriginalBoneIndex;
        var track = decoded.Tracks.First(t => t.TargetBoneIndex == barrel);

        float maxAngle = 0f;
        foreach (var rotation in track.Rotations)
        {
            float dot = MathF.Abs(System.Numerics.Quaternion.Dot(track.Rotations[0], rotation));
            maxAngle = MathF.Max(maxAngle, 2f * MathF.Acos(MathF.Min(1f, dot)));
        }

        // Measured: the barrel hinges roughly 105 degrees open at the midpoint of the reload.
        Assert.True(maxAngle > 1.5f, $"barrel only hinges {maxAngle * 180f / MathF.PI:0.#} degrees");

        // And it returns to where it started, because the animation loops back to the closed pose.
        float endDot = MathF.Abs(System.Numerics.Quaternion.Dot(track.Rotations[0], track.Rotations[^1]));
        Assert.True(endDot > 0.99f, "barrel does not return to the closed pose");
    }
}
