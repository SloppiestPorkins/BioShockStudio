using System.Numerics;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Skeleton;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Which side of the body each hand is on — the Phase 1 first-person blocker.
/// <para>
/// The lateral axis is taken from the <b>head bone</b>, which the arms do not drive:
/// </para>
/// <code>
/// left = the head bone's local +Z, in skeleton space
/// side = dot(L_Hand - R_Hand, left)
/// </code>
/// <para>
/// <c>CONFIRMED_BYTES</c> that this is a game-wide Biped convention rather than one character's
/// quirk: on every shipped character that has a <c>Bip01_Head</c> and feet, world left (+Y after
/// conversion) is the head's local +Z at <b>dot 1.00</b>, and that axis coincides with the
/// character's own clavicle axis at <b>dot 1.00</b>. Two independent references, every character,
/// no exceptions.
/// </para>
/// <para>
/// <b>Two earlier metrics were wrong and are pinned as invalid below, because both read green on
/// data that is not.</b>
/// </para>
/// <list type="bullet">
/// <item>
/// The <i>body frame</i> (<c>up × forward</c> with <c>forward = shoulders → hands</c>) fed the hands
/// into the axis that judged them. It calls a proven character's hands swapped on 2,415 of her
/// 7,982 frames.
/// </item>
/// <item>
/// The <i>arm-root axis</i> (<c>L_UpperArm − R_UpperArm</c>) took the upper arms as the reference —
/// but on this rig the upper arms are themselves on the wrong sides, so it defines the fault as
/// correct. In the first-person bind pose that axis is the rig's <b>forward</b> direction: the
/// 51.89 cm it measured is a front-to-back separation, and the two hands sit at the same lateral
/// position to within 0.01 cm.
/// </item>
/// </list>
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

        // World left is +Y after conversion — proven from anatomy in ANIMATION_COORDINATE_SYSTEM.md.
        Assert.True(Vector3.Dot(left, new Vector3(0f, 1f, 0f)) > 0.99f,
            $"the head's +Z is {left} and should be world left");

        var clavicles = Vector3.Normalize(
            At(jane.Skeleton, globals, "Bip01_L_Clavicle") - At(jane.Skeleton, globals, "Bip01_R_Clavicle"));
        Assert.True(Vector3.Dot(left, clavicles) > 0.99f,
            "the head's lateral axis and the clavicle axis must agree");

        Assert.True(HandSide(jane.Skeleton, globals) > 0f, "her bind pose should put each hand on its own side");
    }

    /// <summary>The first metric this file used, pinned as invalid so it is not reinstated.</summary>
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

        Assert.True(wrong > frames / 5,
            $"the old body-frame metric called only {wrong} of {frames} proven-correct frames swapped");
    }

    /// <summary>
    /// The second metric this file used, pinned as invalid. In the first-person bind pose the
    /// arm-root axis is the rig's forward direction, so the "hand separation" it measured is
    /// front-to-back and carries no side information at all.
    /// </summary>
    [RequiresGameFact]
    public void TheArmRootAxisIsNotTheLateralAxisOnTheFirstPersonRig()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
        var globals = hands.Skeleton.ComputeGlobalTransforms();

        var armRoots = Vector3.Normalize(
            At(hands.Skeleton, globals, "Bip01_L_UpperArm") - At(hands.Skeleton, globals, "Bip01_R_UpperArm"));

        Assert.True(MathF.Abs(Vector3.Dot(armRoots, ViewLeft(hands.Skeleton, globals))) < 0.05f,
            "the arm-root axis is nearly perpendicular to the lateral axis; if that has changed, the " +
            "reasoning in this file's summary needs revisiting rather than this test deleting");
    }

    /// <summary>
    /// The bind pose separates the hands front-to-back, not laterally — 0.01 cm apart on the lateral
    /// axis. So it can neither pass nor fail a side test, and the old claim that it was "correct" was
    /// never a result.
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
    /// <b>KNOWN FAILING — this is the Phase 1 blocker, deliberately left visible.</b>
    /// <para>
    /// In the player's own view frame the first-person arm chains cross the midline. The clavicles
    /// are on the correct sides (±8.65 cm); everything from the upper arm down is on the wrong one.
    /// <c>FidgetCrossbow</c> frame 0: <c>L_Clavicle +8.65</c>, <c>L_UpperArm −18.76</c>,
    /// <c>L_Forearm −30.49</c>, <c>L_Hand −49.59</c>.
    /// </para>
    /// <para>
    /// Do not make this pass by converting the animation again, by negating one bone's Y, or by
    /// fitting a rotation at the chain root. See <c>docs/research/FIRST_PERSON_ANIMATION.md</c> §8c
    /// of the handoff for the changes already known to satisfy a sign test while being wrong.
    /// </para>
    /// </summary>
    [RequiresGameFact(Skip = "Phase 1 blocker: the first-person arm chains cross the midline at the upper arm. See docs/research/FIRST_PERSON_ANIMATION.md")]
    public void FirstPersonAnimationsKeepTheHandsOnTheCorrectSides()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");

        foreach (var animation in hands.Animations.Take(20))
        {
            var decoded = hands.Decode(animation);
            var pose = PoseAt(hands.Skeleton, decoded, 0);
            float side = HandSide(hands.Skeleton, pose);

            Assert.True(side > 0f, $"{animation.Name}: hands are swapped ({side:0.##} cm)");
        }
    }

    /// <summary>
    /// Localises the blocker, and stays green so the localisation cannot rot: the clavicles are on
    /// the correct sides and the chain crosses the midline at the upper arm.
    /// </summary>
    [RequiresGameFact]
    public void TheChainCrossesTheMidlineAtTheUpperArm()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
        var s = hands.Skeleton;
        var decoded = hands.Decode(hands.Find("FidgetCrossbow")!);
        var g = PoseAt(s, decoded, 0);
        var left = ViewLeft(s, g);

        float Side(string bone) => Vector3.Dot(At(s, g, bone) - At(s, g, "Bip01_Head"), left);

        Assert.True(Side("Bip01_L_Clavicle") > 5f, $"L_Clavicle at {Side("Bip01_L_Clavicle"):0.##}, expected the left");
        Assert.True(Side("Bip01_R_Clavicle") < -5f, $"R_Clavicle at {Side("Bip01_R_Clavicle"):0.##}, expected the right");

        Assert.True(Side("Bip01_L_UpperArm") < 0f,
            $"L_UpperArm at {Side("Bip01_L_UpperArm"):0.##}; if it is no longer on the wrong side the " +
            "blocker may be fixed — un-skip FirstPersonAnimationsKeepTheHandsOnTheCorrectSides");
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
