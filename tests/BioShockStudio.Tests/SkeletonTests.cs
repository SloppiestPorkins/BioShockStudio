using BioShockStudio.Core.Havok.Detection;
using BioShockStudio.Core.Havok.Packfile;
using BioShockStudio.Core.Havok.Skeleton;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Skeleton;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
public sealed class SkeletonTests(GameFixture game)
{
    private BioShockSkeleton HandSkeleton()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && package.GetClassName(e) == "AnimationPackageWrapper");
        byte[] payload = package.ReadExportData(export);

        var packfile = HavokPackfile.Parse(payload, HavokDetector.FindFirst(payload)!.Value.Offset);
        var skeletonObject = packfile.EnumerateObjects().Single(o => o.ClassName == HkaSkeletonReader.ClassName);
        var section = packfile.ResolvedSections[skeletonObject.SectionIndex];

        return HkaSkeletonReader.Read(section, skeletonObject.Offset);
    }

    [RequiresGameFact]
    public void HandsPackage_ContainsExactlyOneSharedSkeleton()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && package.GetClassName(e) == "AnimationPackageWrapper");
        byte[] payload = package.ReadExportData(export);
        var packfile = HavokPackfile.Parse(payload, HavokDetector.FindFirst(payload)!.Value.Offset);

        // One skeleton shared by every weapon's animations, living in __data__ alongside the root.
        var skeletons = packfile.EnumerateObjects().Where(o => o.ClassName == "hkaSkeleton").ToList();
        Assert.Single(skeletons);
        Assert.Equal("__data__", skeletons[0].SectionTag);
    }

    [RequiresGameFact]
    public void HandSkeleton_DecodesToKnownBones()
    {
        var skeleton = HandSkeleton();

        Assert.Equal("Bip01 Spine", skeleton.Name);
        Assert.Equal(47, skeleton.BoneCount);

        Assert.Equal("Bip01_Spine", skeleton.Bones[0].Name);
        Assert.True(skeleton.Bones[0].IsRoot);
        Assert.Equal("Bip01_L_Hand", skeleton.Bones[6].Name);
        Assert.Equal("Bip01_R_Hand", skeleton.Bones[27].Name);
    }

    [RequiresGameFact]
    public void HandSkeleton_HierarchyIsParentFirstAndSingleRooted()
    {
        var skeleton = HandSkeleton();

        Assert.Single(skeleton.Bones.Where(b => b.IsRoot));

        for (int i = 0; i < skeleton.BoneCount; i++)
        {
            int parent = skeleton.Bones[i].ParentIndex;
            Assert.InRange(parent, -1, i - 1);
        }
    }

    [RequiresGameFact]
    public void HandSkeleton_HasCompleteFingerChainsOnBothHands()
    {
        var skeleton = HandSkeleton();

        foreach (string side in new[] { "L", "R" })
        {
            foreach (string finger in new[] { "Thumb", "Index", "Middle", "Ring", "Pinky" })
            {
                for (int joint = 1; joint <= 3; joint++)
                {
                    string name = $"kBone_{side}_{finger}{joint}";
                    Assert.NotNull(skeleton.FindBone(name));
                }
            }
        }

        // Each finger's root parents to the hand, and subsequent joints chain off the previous one.
        var hand = skeleton.FindBone("Bip01_R_Hand")!;
        var index1 = skeleton.FindBone("kBone_R_Index1")!;
        var index2 = skeleton.FindBone("kBone_R_Index2")!;
        Assert.Equal(hand.OriginalBoneIndex, index1.ParentIndex);
        Assert.Equal(index1.OriginalBoneIndex, index2.ParentIndex);
    }

    [RequiresGameFact]
    public void HandSkeleton_ExposesWeaponAttachmentSockets()
    {
        var skeleton = HandSkeleton();

        // These are the attachment points required by the sockets requirement: the weapon grip and
        // the left-hand IK target that holds the off hand onto the weapon.
        var grip = skeleton.FindBone("R_grip");
        var ikTarget = skeleton.FindBone("IKbindLhandDummy");

        Assert.NotNull(grip);
        Assert.NotNull(ikTarget);

        // Both hang off the right hand, which is the weapon-holding hand.
        int rightHand = skeleton.FindBone("Bip01_R_Hand")!.OriginalBoneIndex;
        Assert.Equal(rightHand, grip!.ParentIndex);
        Assert.Equal(rightHand, ikTarget!.ParentIndex);
    }

    [RequiresGameFact]
    public void HandSkeleton_ReferencePoseComposesAndInverts()
    {
        var skeleton = HandSkeleton();

        var global = skeleton.ComputeGlobalTransforms();
        Assert.Equal(skeleton.BoneCount, global.Length);

        var inverse = skeleton.ComputeInverseBindTransforms();
        Assert.Equal(skeleton.BoneCount, inverse.Length);

        // A bind matrix times its inverse must be the identity, within float tolerance.
        for (int i = 0; i < global.Length; i++)
        {
            var product = global[i] * inverse[i];
            Assert.Equal(1f, product.M11, 3);
            Assert.Equal(1f, product.M22, 3);
            Assert.Equal(1f, product.M33, 3);
            Assert.Equal(0f, product.M41, 3);
        }
    }

    [RequiresGameFact]
    public void HandSkeleton_BonesKeepTheirOriginalIndex()
    {
        var skeleton = HandSkeleton();

        // Havok animation tracks address bones by index, so array position and OriginalBoneIndex
        // must never diverge.
        for (int i = 0; i < skeleton.BoneCount; i++)
            Assert.Equal(i, skeleton.Bones[i].OriginalBoneIndex);
    }
}
