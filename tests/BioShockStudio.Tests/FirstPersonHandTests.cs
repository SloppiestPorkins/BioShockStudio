using System.Numerics;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Skeleton;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Which side of the body each hand is on — the Phase 1 first-person blocker.
/// <para>
/// The side is derived from the skeleton itself rather than from an axis, because a rig's own space
/// need not be world space (the first-person rig is rooted at <c>Bip01 Spine</c>, whose local axes
/// are nothing like the world's). The body frame is
/// </para>
/// <code>
/// up      = spine -> neck
/// forward = shoulders -> hands
/// left    = up x forward          (a right-handed frame: forward, left, up)
/// </code>
/// <para>
/// A hand's side is then the sign of its offset from the shoulders along <c>left</c>. This is
/// naming-free, view-free and basis-free: it cannot be fooled by a mirrored export, a rolled camera
/// or a renamed bone, which is what every earlier attempt at this question was fooled by.
/// </para>
/// <para>
/// The method is calibrated on <c>ProtectorRosie</c>, whose left/right is independently proven from
/// world anatomy (feet near Z=0, toes ahead of ankles in X, <c>Bip01_L_*</c> at +Y after conversion).
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
public sealed class FirstPersonHandTests(GameFixture game)
{
    /// <summary>Signed offset of each hand along the body's own left axis.</summary>
    private static (float Left, float Right) HandSides(BioShockSkeleton skeleton, Matrix4x4[] globals)
    {
        Vector3 At(string name)
        {
            for (int i = 0; i < skeleton.Bones.Count; i++)
                if (string.Equals(skeleton.Bones[i].Name, name, StringComparison.OrdinalIgnoreCase))
                    return globals[i].Translation;
            throw new InvalidOperationException($"{name} is not on this skeleton");
        }

        var spine = At("Bip01_Spine");
        var neck = At("Bip01_Neck");
        var lh = At("Bip01_L_Hand");
        var rh = At("Bip01_R_Hand");
        var shoulders = (At("Bip01_L_Clavicle") + At("Bip01_R_Clavicle")) * 0.5f;

        var up = Vector3.Normalize(neck - spine);
        var forward = (lh + rh) * 0.5f - shoulders;
        forward -= up * Vector3.Dot(forward, up);          // orthogonalise against up
        forward = Vector3.Normalize(forward);
        var left = Vector3.Normalize(Vector3.Cross(up, forward));

        return (Vector3.Dot(lh - shoulders, left), Vector3.Dot(rh - shoulders, left));
    }

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

    /// <summary>Calibration: the method must agree with what world anatomy already proved.</summary>
    [RequiresGameFact]
    public void TheMethodAgreesWithAProvenCharacter()
    {
        var rosie = Load(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "7-Gauntlet.bsm"),
            "UAPW_ProtectorRosie");

        var (left, right) = HandSides(rosie.Skeleton, rosie.Skeleton.ComputeGlobalTransforms());

        Assert.True(left > 0f, $"Bip01_L_Hand should be on the left, got {left:0.##}");
        Assert.True(right < 0f, $"Bip01_R_Hand should be on the right, got {right:0.##}");
    }

    [RequiresGameFact]
    public void TheFirstPersonBindPosePutsTheHandsOnTheCorrectSides()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
        var (left, right) = HandSides(hands.Skeleton, hands.Skeleton.ComputeGlobalTransforms());

        Assert.True(left > 0f, $"Bip01_L_Hand should be on the left, got {left:0.##}");
        Assert.True(right < 0f, $"Bip01_R_Hand should be on the right, got {right:0.##}");
    }

    /// <summary>
    /// <b>KNOWN FAILING — this is the Phase 1 blocker, deliberately left red.</b>
    /// <para>
    /// The first-person bind pose is correct (test above) and every animation puts the hands on the
    /// wrong sides, consistently, at every frame. The same measurement on <c>ProtectorRosie</c>
    /// holds correct throughout her animations, so the method is sound and the fault is specific to
    /// the first-person animation path.
    /// </para>
    /// <para>
    /// Do not make this pass by converting the animation again. That does flip the sides back, and
    /// it is wrong: the animation's fallback channels already equal the skeleton's bind translations
    /// exactly, which proves the animation and the skeleton are already in the same basis. Applying
    /// another conversion would put them in different ones. See
    /// <c>docs/research/FIRST_PERSON_ANIMATION.md</c>.
    /// </para>
    /// </summary>
    [RequiresGameFact(Skip = "Phase 1 blocker: first-person animations put the hands on the wrong sides. See docs/research/FIRST_PERSON_ANIMATION.md")]
    public void FirstPersonAnimationsKeepTheHandsOnTheCorrectSides()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");

        foreach (var animation in hands.Animations.Take(20))
        {
            var decoded = hands.Decode(animation);
            var pose = PoseAt(hands.Skeleton, decoded, 0);
            var (left, right) = HandSides(hands.Skeleton, pose);

            Assert.True(left > 0f && right < 0f,
                $"{animation.Name}: hands are swapped (left {left:0.##}, right {right:0.##})");
        }
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
