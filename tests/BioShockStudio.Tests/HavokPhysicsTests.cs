using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Havok.Physics;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The start of Havok collision/ragdoll decoding (Gate 2 item 3 of <c>docs/ROADMAP.md</c>) — a whole
/// area of shipped data (rigid bodies, collision shapes, ragdoll constraints) that had never been
/// read before, only detected by class-name presence (<c>CharacterCatalog.DeclaresRagdoll</c>). See
/// <c>docs/research/havok-physics.md</c> for the full census and scoped plan for what remains.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class HavokPhysicsTests(GameFixture game)
{
    private (Core.Assets.AnimationPackage Package, BioShockPackage Owner) BabyJane()
    {
        var package = BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));

        var wrapper = package.Exports
            .Where(e => e.ObjectName == "UAPW_AggressorBabyJane"
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize)!;

        return (Core.Assets.AnimationPackage.Load(package, wrapper), package);
    }

    /// <summary>
    /// Every capsule's radius agrees with both end-vertices' W component — the SDK's own description
    /// of the vertices as spheres, not plain points — and every decoded radius and length is a
    /// plausible human-body proportion in metres. Held across the whole set, not one example: 17 of
    /// 17 on this character's ragdoll.
    /// </summary>
    [RequiresGameFact]
    public void EveryCapsuleShapeDecodesToAPlausibleBodyProportion()
    {
        var (pack, owner) = BabyJane();
        using (owner)
        {
            var capsules = pack.Packfile.EnumerateObjects()
                .Where(o => o.ClassName == HkpCapsuleShapeReader.ClassName)
                .ToList();

            Assert.Equal(17, capsules.Count);

            foreach (var capsuleObject in capsules)
            {
                var section = pack.Packfile.ResolvedSections[capsuleObject.SectionIndex];
                var capsule = HkpCapsuleShapeReader.Read(section, capsuleObject.Offset);

                // Havok's redundant per-vertex radius storage (hkSphere) must agree with the base
                // hkpConvexShape::m_radius field, or the offsets are wrong.
                float vertexAW = section.ReadSingle(capsuleObject.Offset + 32 + 12);
                float vertexBW = section.ReadSingle(capsuleObject.Offset + 48 + 12);
                Assert.Equal(capsule.Radius, vertexAW, 4);
                Assert.Equal(capsule.Radius, vertexBW, 4);

                // Metres, not centimetres: this rig's mesh/animation data (the same character) uses
                // bone lengths and offsets one to three orders of magnitude larger.
                Assert.InRange(capsule.Radius, 0.01f, 1.0f);
                Assert.InRange(capsule.Length, 0f, 2.0f);
            }
        }
    }

    /// <summary>
    /// <c>hkaRagdollInstance</c> ties the whole ragdoll together, and its own counts agree with what
    /// the whole-packfile census finds independently — the object graph is internally consistent, not
    /// just individually plausible.
    /// </summary>
    [RequiresGameFact]
    public void RagdollInstanceCountsAgreeWithTheWholePackfileCensus()
    {
        var (pack, owner) = BabyJane();
        using (owner)
        {
            var ragdollObject = pack.Packfile.EnumerateObjects().Single(o => o.ClassName == HkaRagdollInstanceReader.ClassName);
            var section = pack.Packfile.ResolvedSections[ragdollObject.SectionIndex];
            var ragdoll = HkaRagdollInstanceReader.Read(pack.Packfile, section, ragdollObject.Offset);

            int rigidBodyCount = pack.Packfile.EnumerateObjects().Count(o => o.ClassName == HkpRigidBodyClassName);
            int constraintCount = pack.Packfile.EnumerateObjects().Count(o => o.ClassName == HkpConstraintInstanceClassName);

            Assert.Equal(rigidBodyCount, ragdoll.RigidBodies.Count);
            Assert.Equal(constraintCount, ragdoll.Constraints.Count);
            Assert.Equal(17, ragdoll.RigidBodies.Count);
            Assert.Equal(16, ragdoll.Constraints.Count);

            // Every resolved rigid-body location is a real hkpRigidBody, not a dangling offset.
            var rigidBodyLocations = pack.Packfile.EnumerateObjects()
                .Where(o => o.ClassName == HkpRigidBodyClassName)
                .Select(o => (o.SectionIndex, o.Offset))
                .ToHashSet();
            foreach (var (bodySection, bodyOffset) in ragdoll.RigidBodies)
                Assert.Contains((bodySection.Index, bodyOffset), rigidBodyLocations);

            // The bone-to-rigid-body map is a valid index into RigidBodies for every entry.
            Assert.NotEmpty(ragdoll.BoneToRigidBodyMap);
            foreach (int index in ragdoll.BoneToRigidBodyMap)
                Assert.InRange(index, 0, ragdoll.RigidBodies.Count - 1);

            Assert.NotNull(ragdoll.Skeleton);
            var skeletonObject = pack.Packfile.EnumerateObjects()
                .FirstOrDefault(o => o.SectionIndex == ragdoll.Skeleton!.Value.Section.Index && o.Offset == ragdoll.Skeleton.Value.Offset);
            Assert.Equal("hkaSkeleton", skeletonObject?.ClassName);
        }
    }

    private const string HkpRigidBodyClassName = "hkpRigidBody";
    private const string HkpConstraintInstanceClassName = "hkpConstraintInstance";
}
