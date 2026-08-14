using System.Numerics;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Skeleton;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Which side of the body each hand is on — the Phase 1 first-person blocker, now fixed.
/// <para>
/// The cause was in the spline decompressor, not in the rig: a channel component that is neither
/// static nor spline is Havok's <b>identity</b>, and this reader filled it from the bound bone's
/// reference pose. See <c>SplineDecompressor</c> and
/// <c>docs/research/FIRST_PERSON_ANIMATION.md</c>.
/// </para>
/// <para>
/// The lateral axis is taken from the <b>head bone</b>, which the arms do not drive.
/// <c>CONFIRMED_BYTES</c>: on every shipped character with a <c>Bip01_Head</c> and feet, world left
/// (+Y after conversion) is the head's local +Z at dot 1.00, and that axis coincides with the
/// character's own clavicle axis at dot 1.00.
/// </para>
/// <para>
/// <b>Two earlier metrics are pinned as invalid below</b>, because both read green on data that was
/// not: the body frame (<c>up × forward</c> with <c>forward = shoulders → hands</c>) judges the
/// hands with an axis built from the hands, and the arm-root axis
/// (<c>L_UpperArm − R_UpperArm</c>) took as its reference the very bones that were misplaced.
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
public sealed class FirstPersonHandTests(GameFixture game)
{
    private static int IndexOf(BioShockSkeleton skeleton, string name)
    {
        for (int i = 0; i < skeleton.Bones.Count; i++)
            if (string.Equals(skeleton.Bones[i].Name, name, StringComparison.OrdinalIgnoreCase)) return i;
        return -1;
    }

    /// <summary>The rig's lateral axis, from a bone the arms do not drive.</summary>
    private static Vector3 ViewLeft(BioShockSkeleton skeleton, Matrix4x4[] globals)
    {
        int head = IndexOf(skeleton, "Bip01_Head");
        Assert.True(head >= 0, $"{skeleton.Name} has no Bip01_Head to take a view frame from");
        var m = globals[head];
        return Vector3.Normalize(new Vector3(m.M31, m.M32, m.M33));
    }

    private static Vector3 At(BioShockSkeleton skeleton, Matrix4x4[] globals, string name)
    {
        int i = IndexOf(skeleton, name);
        if (i < 0) throw new InvalidOperationException($"{name} is not on this skeleton");
        return globals[i].Translation;
    }

    /// <summary>Signed lateral offset of the left hand from the right. Positive is correct.</summary>
    private static float HandSide(BioShockSkeleton skeleton, Matrix4x4[] globals) =>
        Vector3.Dot(
            At(skeleton, globals, "Bip01_L_Hand") - At(skeleton, globals, "Bip01_R_Hand"),
            ViewLeft(skeleton, globals));

    private AnimationPackage Load(string packagePath, string objectName)
    {
        using var package = BioShockPackage.Open(packagePath);
        var export = package.Exports
            .Where(e => e.ObjectName == objectName
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize);

        Assert.True(export is not null, $"{objectName} not found");
        return AnimationPackage.Load(package, export!);
    }

    private string Gauntlet => Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "7-Gauntlet.bsm");

    /// <summary>
    /// Calibration. The head's +Z must be the lateral axis on a character whose left and right are
    /// independently proven from world anatomy, and it must agree with her own clavicle axis.
    /// </summary>
    [RequiresGameFact]
    public void TheHeadBoneCarriesTheRigsLateralAxis()
    {
        var jane = Load(Gauntlet, "UAPW_AggressorBabyJane");
        var globals = jane.Skeleton.ComputeGlobalTransforms();
        var left = ViewLeft(jane.Skeleton, globals);

        Assert.True(Vector3.Dot(left, new Vector3(0f, 1f, 0f)) > 0.99f,
            $"the head's +Z is {left} and should be world left");

        var clavicles = Vector3.Normalize(
            At(jane.Skeleton, globals, "Bip01_L_Clavicle") - At(jane.Skeleton, globals, "Bip01_R_Clavicle"));
        Assert.True(Vector3.Dot(left, clavicles) > 0.99f,
            "the head's lateral axis and the clavicle axis must agree");

        Assert.True(HandSide(jane.Skeleton, globals) > 0f, "her bind pose should put each hand on its own side");
    }

    /// <summary>
    /// The first metric this file used, pinned as invalid so it is not reinstated. It still reports
    /// hundreds of a proven character's frames as swapped, on a decode that is now correct.
    /// </summary>
    [RequiresGameFact]
    public void TheOldBodyFrameMetricIsNotAValidSideTest()
    {
        var rosie = Load(Gauntlet, "UAPW_ProtectorRosie");
        var skeleton = rosie.Skeleton;

        int frames = 0, wrong = 0;
        foreach (var animation in rosie.Animations)
        {
            var decoded = rosie.Decode(animation);
            for (int frame = 0; frame < decoded.FrameCount; frame++)
            {
                var g = PoseAt(skeleton, decoded, frame);
                var up = Vector3.Normalize(At(skeleton, g, "Bip01_Neck") - At(skeleton, g, "Bip01_Spine"));
                var forward = (At(skeleton, g, "Bip01_L_Hand") + At(skeleton, g, "Bip01_R_Hand")) * 0.5f
                              - (At(skeleton, g, "Bip01_L_Clavicle") + At(skeleton, g, "Bip01_R_Clavicle")) * 0.5f;
                forward -= up * Vector3.Dot(forward, up);
                var left = Vector3.Normalize(Vector3.Cross(up, Vector3.Normalize(forward)));

                frames++;
                if (Vector3.Dot(At(skeleton, g, "Bip01_L_Hand") - At(skeleton, g, "Bip01_R_Hand"), left) < 0f) wrong++;
            }
        }

        Assert.True(wrong > 100,
            $"the old body-frame metric called only {wrong} of {frames} proven-correct frames swapped; " +
            "if it has become reliable, this guard should be revisited rather than deleted");
    }

    /// <summary>
    /// The second metric this file used, pinned as invalid. On the first-person rig the arm-root
    /// axis is not the lateral axis — it was the rig's forward direction.
    /// </summary>
    [RequiresGameFact]
    public void TheArmRootAxisIsNotTheLateralAxisOnTheFirstPersonRig()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
        var globals = hands.Skeleton.ComputeGlobalTransforms();

        var armRoots = Vector3.Normalize(
            At(hands.Skeleton, globals, "Bip01_L_UpperArm") - At(hands.Skeleton, globals, "Bip01_R_UpperArm"));

        Assert.True(MathF.Abs(Vector3.Dot(armRoots, ViewLeft(hands.Skeleton, globals))) < 0.05f,
            "the bind pose's arm-root axis is nearly perpendicular to the lateral axis; if that has " +
            "changed, the reasoning in this file's summary needs revisiting rather than this test deleting");
    }

    /// <summary>
    /// The bind pose separates the hands front-to-back, not laterally, so it can neither pass nor
    /// fail a side test. It is an authoring pose and the animations do not build on it.
    /// </summary>
    [RequiresGameFact]
    public void TheFirstPersonBindPoseSeparatesTheHandsFrontToBack()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
        var globals = hands.Skeleton.ComputeGlobalTransforms();

        Assert.True(MathF.Abs(HandSide(hands.Skeleton, globals)) < 1f,
            $"the bind pose's lateral hand separation is {HandSide(hands.Skeleton, globals):0.###} cm");
    }

    /// <summary>
    /// <b>The former Phase 1 blocker.</b> Every frame of every first-person animation, on the rig's
    /// own lateral axis.
    /// </summary>
    [RequiresGameFact]
    public void FirstPersonAnimationsKeepTheHandsOnTheCorrectSides()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");

        int frames = 0, crossed = 0;
        float deepest = float.MaxValue;
        string deepestAt = "";

        foreach (var animation in hands.Animations)
        {
            var decoded = hands.Decode(animation);
            for (int frame = 0; frame < decoded.FrameCount; frame++)
            {
                float side = HandSide(hands.Skeleton, PoseAt(hands.Skeleton, decoded, frame));
                frames++;
                if (side < 0f) crossed++;
                if (side < deepest) { deepest = side; deepestAt = $"{animation.Owner}/{animation.Name}[{frame}]"; }
            }
        }

        Assert.True(frames > 5_000, $"only {frames} frames swept");

        // Before the fix this was 3,384 of 5,984. What is left is real, transient crossing — a hand
        // reaching over during a reload — not a swap.
        Assert.True(crossed * 50 < frames,
            $"the hands are on the wrong side in {crossed} of {frames} frames; deepest {deepest:0.##} at {deepestAt}");
    }

    /// <summary>
    /// The arm roots are symmetric, which is what the fix restored. Before it, the reference pose's
    /// Y and Z were injected into every frame and put each root 93 cm from its clavicle.
    /// </summary>
    [RequiresGameFact]
    public void TheArmRootsAreSymmetricUnderAnimation()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
        var s = hands.Skeleton;
        var decoded = hands.Decode(hands.Find("FidgetCrossbow")!);

        Vector3 Local(string bone)
        {
            int b = IndexOf(s, bone);
            return decoded.Tracks.First(t => t.TargetBoneIndex == b).Translations[0];
        }

        var left = Local("Bip01_L_UpperArm");
        var right = Local("Bip01_R_UpperArm");

        Assert.Equal(left.X, right.X, 3);
        Assert.True(MathF.Abs(left.Y) < 0.01f && MathF.Abs(left.Z) < 0.01f, $"L_UpperArm local is {left}");
        Assert.True(MathF.Abs(right.Y) < 0.01f && MathF.Abs(right.Z) < 0.01f, $"R_UpperArm local is {right}");

        // A shoulder offset, not the 93 cm the reference-pose fallback produced.
        Assert.InRange(left.Length(), 10f, 30f);
    }

    /// <summary>The left hand reaches the weapon, which it never did before the fix.</summary>
    [RequiresGameFact]
    public void TheLeftHandReachesTheWeapon()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
        var s = hands.Skeleton;
        int lh = IndexOf(s, "Bip01_L_Hand"), grip = IndexOf(s, "R_grip");

        float best = float.MaxValue;
        foreach (var animation in hands.Animations)
        {
            var decoded = hands.Decode(animation);
            for (int frame = 0; frame < decoded.FrameCount; frame++)
            {
                var g = PoseAt(s, decoded, frame);
                best = MathF.Min(best, (g[lh].Translation - g[grip].Translation).Length());
            }
        }

        Assert.True(best < 8f, $"the left hand never gets closer than {best:0.##} cm to the weapon grip");
    }

    /// <summary>Composes an animation's frame onto the skeleton, parent before child.</summary>
    private static Matrix4x4[] PoseAt(BioShockSkeleton skeleton, Core.Animation.DecodedAnimation animation, int frame)
    {
        var byBone = new Core.Animation.DecodedTrack?[skeleton.BoneCount];
        foreach (var track in animation.Tracks)
            if (track.TargetBoneIndex >= 0 && track.TargetBoneIndex < skeleton.BoneCount)
                byBone[track.TargetBoneIndex] = track;

        var globals = new Matrix4x4[skeleton.BoneCount];
        for (int b = 0; b < skeleton.BoneCount; b++)
        {
            var bone = skeleton.Bones[b];
            var track = byBone[b];

            var t = track is not null && frame < track.Translations.Length ? track.Translations[frame] : bone.LocalTranslation;
            var r = track is not null && frame < track.Rotations.Length ? track.Rotations[frame] : bone.LocalRotation;
            var s = track is not null && frame < track.Scales.Length ? track.Scales[frame] : bone.LocalScale;

            var local = Matrix4x4.CreateScale(s) * Matrix4x4.CreateFromQuaternion(r) * Matrix4x4.CreateTranslation(t);
            globals[b] = bone.ParentIndex >= 0 && bone.ParentIndex < b
                ? local * globals[bone.ParentIndex]
                : local;
        }

        return globals;
    }
}
