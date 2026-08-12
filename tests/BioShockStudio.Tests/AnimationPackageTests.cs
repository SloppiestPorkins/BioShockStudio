using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
public sealed class AnimationPackageTests(GameFixture game)
{
    private AnimationPackage Hands()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && package.GetClassName(e) == "AnimationPackageWrapper");
        return AnimationPackage.Load(package, export);
    }

    [RequiresGameFact]
    public void HandsPackage_DecodesEveryAnimation()
    {
        var hands = Hands();

        // The root table lists 130 animations, which is also the total number of
        // hkaAnimationBinding objects across the ten content sections.
        Assert.Equal(130, hands.Animations.Count);
        Assert.Empty(hands.Failures);
    }

    [RequiresGameFact]
    public void HandsPackage_GroupsAnimationsByWeapon()
    {
        var hands = Hands();

        var counts = hands.Animations
            .GroupBy(a => a.Owner)
            .ToDictionary(g => g.Key, g => g.Count());

        Assert.Equal(10, counts["Pistol"]);
        Assert.Equal(8, counts["Shotgun"]);
        Assert.Equal(10, counts["TommyGun"]);
        Assert.Equal(9, counts["Wrench"]);
        Assert.Equal(13, counts["Crossbow"]);
        Assert.Equal(12, counts["GrenadeLauncher"]);
        Assert.Equal(10, counts["ChemicalThrower"]);
        Assert.Equal(57, counts["Default"]);

        // Owner names are untruncated even where the 19-byte section tag is not.
        Assert.Contains("ChemicalThrower", counts.Keys);
        Assert.Contains("GrenadeLauncher", counts.Keys);
    }

    [RequiresGameFact]
    public void PistolAnimations_CoverTheRequiredWeaponStates()
    {
        var pistol = Hands().ForOwner("Pistol").Select(a => a.Name).ToHashSet(StringComparer.Ordinal);

        foreach (string required in new[]
        {
            "EquipPistol",          // draw
            "UnequipPistol",        // holster
            "FireSinglePistol",     // fire
            "FastReloadPistol",     // reload
            "FidgetPistol",         // idle
            "EmptyFidgetPistol",    // idle, empty
            "ZoomingInPistol",
            "ZoomingOutPistol",
            "ZoomedInFidgetPistol",
            "ZoomedInFireSinglePistol",
        })
        {
            Assert.Contains(required, pistol);
        }
    }

    [RequiresGameFact]
    public void PistolAnimations_HaveConsistentTiming()
    {
        foreach (var animation in Hands().ForOwner("Pistol"))
        {
            Assert.Equal(CompressionKind.Spline, animation.Compression);
            Assert.True(animation.FrameCount > 0, $"{animation.Name} has no frames");

            // Duration is the span between the first and last frame. Three independently stored
            // fields agreeing is what validates the header layout.
            Assert.Equal((animation.FrameCount - 1) * animation.FrameDuration, animation.Duration, 3);

            // Frame rate is close to 30 but not fixed: ZoomedInFidgetPistol is 29.94 and
            // ZoomingOutPistol is 27.02. Authored timing therefore has to be carried through export
            // rather than resampled to a nominal rate.
            Assert.InRange(animation.FrameRate, 20f, 31f);
        }
    }

    [RequiresGameFact]
    public void PistolAnimations_HaveDistinctAuthoredFrameRates()
    {
        var rates = Hands().ForOwner("Pistol").Select(a => MathF.Round(a.FrameRate, 2)).Distinct().ToList();

        // More than one rate in a single weapon's set is the concrete reason resampling to a
        // nominal 30 fps would corrupt playback.
        Assert.True(rates.Count > 1, $"expected varying frame rates, got {string.Join(", ", rates)}");
    }

    [RequiresGameFact]
    public void EveryAnimation_BindsOneTrackPerSkeletonBone()
    {
        var hands = Hands();
        int boneCount = hands.Skeleton.BoneCount;

        foreach (var animation in hands.Animations)
        {
            Assert.Equal(animation.TransformTrackCount, animation.Binding.TrackCount);

            foreach (short bone in animation.Binding.TransformTrackToBoneIndex)
                Assert.InRange(bone, 0, boneCount - 1);
        }
    }

    [RequiresGameFact]
    public void BindingResolvesTracksToBonesByIndexNotName()
    {
        var hands = Hands();
        var fire = hands.Find("FireSinglePistol");
        Assert.NotNull(fire);

        var binding = fire!.Binding;

        // The hands skeleton is fully animated: 47 tracks onto 47 bones, one apiece.
        Assert.Equal(hands.Skeleton.BoneCount, binding.TrackCount);
        Assert.Equal(binding.TrackCount, binding.TransformTrackToBoneIndex.Distinct().Count());

        // Round-tripping a bone through the binding must land back on the same bone, which is the
        // property the exporters depend on.
        var rightHand = hands.Skeleton.FindBone("Bip01_R_Hand")!;
        int track = binding.TrackForBone(rightHand.OriginalBoneIndex);
        Assert.True(track >= 0);
        Assert.Equal(rightHand.OriginalBoneIndex, binding.BoneForTrack(track));
    }

    [RequiresGameFact]
    public void ThirdPersonPackage_AlsoDecodes()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports.First(e =>
            e.ObjectName == "UAPW_AggressorBabyJane" && package.GetClassName(e) == "AnimationPackageWrapper");
        var character = AnimationPackage.Load(package, export);

        Assert.NotEmpty(character.Animations);
        Assert.Empty(character.Failures);

        // A third-person character has one owner group, not per-weapon ones.
        Assert.Single(character.Owners);
    }
}
