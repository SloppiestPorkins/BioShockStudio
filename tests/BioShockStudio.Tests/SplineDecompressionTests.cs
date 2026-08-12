using System.Numerics;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
public sealed class SplineDecompressionTests(GameFixture game)
{
    private static AnimationPackage Load(string file, string objectName)
    {
        using var package = BioShockPackage.Open(file);
        var export = package.Exports.First(e =>
            e.ObjectName == objectName && package.GetClassName(e) == "AnimationPackageWrapper");
        return AnimationPackage.Load(package, export);
    }

    private AnimationPackage Hands() => Load(game.LighthousePackage, "UAPW_NEWPlayerHands");

    [RequiresGameFact]
    public void EveryAnimationInTheHandsPackage_Decodes()
    {
        var hands = Hands();
        var failures = new List<string>();

        foreach (var animation in hands.Animations)
        {
            try
            {
                var decoded = hands.Decode(animation);
                if (decoded.FrameCount != animation.FrameCount)
                    failures.Add($"{animation.Name}: {decoded.FrameCount} frames, expected {animation.FrameCount}");
                if (decoded.Tracks.Count != animation.TransformTrackCount)
                    failures.Add($"{animation.Name}: {decoded.Tracks.Count} tracks, expected {animation.TransformTrackCount}");
            }
            catch (Exception ex)
            {
                failures.Add($"{animation.Name}: {ex.Message}");
            }
        }

        Assert.Empty(failures);
    }

    [RequiresGameFact]
    public void DecodedRotations_AreUnitQuaternions()
    {
        var hands = Hands();

        foreach (var animation in hands.ForOwner("Pistol"))
        {
            var decoded = hands.Decode(animation);
            foreach (var track in decoded.Tracks)
            {
                foreach (var rotation in track.Rotations)
                {
                    Assert.Equal(1f, rotation.Length(), 3);
                }
            }
        }
    }

    [RequiresGameFact]
    public void DecodedTracks_AreContinuousAcrossFrames()
    {
        var hands = Hands();
        var deltas = new List<float>();

        foreach (var animation in hands.ForOwner("Pistol"))
        {
            var decoded = hands.Decode(animation);
            foreach (var track in decoded.Tracks)
            {
                for (int frame = 1; frame < decoded.FrameCount; frame++)
                    deltas.Add(MathF.Abs(Quaternion.Dot(track.Rotations[frame - 1], track.Rotations[frame])));
            }
        }

        // A wrong bit layout in the packed quaternion produces pervasive frame-to-frame popping, so
        // the shape of this distribution is a real correctness check. The single worst transition in
        // the whole pistol set is a fast wrist motion during the reload, not decoder noise.
        Assert.True(deltas.Count > 10_000);
        Assert.True(deltas.Min() > 0.7f, $"worst continuity {deltas.Min():0.###}");
        Assert.True(deltas.Count(d => d > 0.99f) > deltas.Count * 0.99,
            $"only {deltas.Count(d => d > 0.99f)}/{deltas.Count} transitions are smooth");
    }

    [RequiresGameFact]
    public void StaticChannels_HoldTheSameValueOnEveryFrame()
    {
        var hands = Hands();
        var animation = hands.Find("EquipPistol")!;
        var decoded = hands.Decode(animation);

        // EquipPistol stores most translations statically; those must not drift frame to frame.
        int staticTracks = 0;
        foreach (var track in decoded.Tracks)
        {
            bool constant = track.Translations.All(t => t == track.Translations[0]);
            if (constant) staticTracks++;
        }

        Assert.True(staticTracks > decoded.Tracks.Count / 2,
            $"expected most translation channels to be constant, got {staticTracks}/{decoded.Tracks.Count}");
    }

    [RequiresGameFact]
    public void DecodedTranslations_MatchTheSkeletonBoneLengths()
    {
        var hands = Hands();
        var animation = hands.Find("FidgetPistol")!;
        var decoded = hands.Decode(animation);

        // Bone lengths are rigid: an animated bone's local translation should stay close to its
        // reference-pose translation. This catches dequantisation range errors, which would scale
        // the skeleton rather than merely rotate it.
        int checkedBones = 0;
        foreach (var track in decoded.Tracks)
        {
            if (track.TargetBoneIndex < 0) continue;
            var bone = hands.Skeleton.Bones[track.TargetBoneIndex];
            if (bone.IsRoot) continue;

            float referenceLength = bone.LocalTranslation.Length();
            if (referenceLength < 0.01f) continue;

            float animatedLength = track.Translations[0].Length();
            Assert.InRange(animatedLength, referenceLength * 0.5f, referenceLength * 2f);
            checkedBones++;
        }

        Assert.True(checkedBones > 20, $"only checked {checkedBones} bones");
    }

    [RequiresGameFact]
    public void EveryTrack_ResolvesToADistinctBone()
    {
        var hands = Hands();
        var decoded = hands.Decode(hands.Find("FireSinglePistol")!);

        var bones = decoded.Tracks.Select(t => t.TargetBoneIndex).ToList();
        Assert.DoesNotContain(-1, bones);
        Assert.Equal(bones.Count, bones.Distinct().Count());
    }

    [RequiresGameFact]
    public void ThirdPersonCharacterAnimations_AlsoDecode()
    {
        var character = Load(game.LighthousePackage, "UAPW_AggressorBabyJane");
        var failures = new List<string>();

        foreach (var animation in character.Animations)
        {
            try { character.Decode(animation); }
            catch (Exception ex) { failures.Add($"{animation.Name}: {ex.Message}"); }
        }

        Assert.Empty(failures);
    }
}
