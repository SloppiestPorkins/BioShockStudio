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

    /// <summary>
    /// The two <c>hkaSkeletonMapper</c>s on this character are near-exact inverses of each other —
    /// the same bone correspondence read in both directions for all but one entry, which is a strong
    /// internal cross-check for a bone-index mapping (a data-entry mistake in one direction would not
    /// generally also produce a coherent inverse in the other). The one exception is understood, not
    /// a reader bug — see <c>HkaSkeletonMapperReader</c>'s own doc comment.
    /// </summary>
    [RequiresGameFact]
    public void SkeletonMappersAreNearExactInversesOfEachOther()
    {
        var (pack, owner) = BabyJane();
        using (owner)
        {
            var mapperObjects = pack.Packfile.EnumerateObjects()
                .Where(o => o.ClassName == HkaSkeletonMapperReader.ClassName)
                .ToList();
            Assert.Equal(2, mapperObjects.Count);

            var mappers = mapperObjects
                .Select(o => HkaSkeletonMapperReader.Read(pack.Packfile, pack.Packfile.ResolvedSections[o.SectionIndex], o.Offset))
                .ToList();

            var seventyThreeToSeventeen = mappers.Single(m => m.SimpleMappings.Any() && m.SimpleMappings[0].BoneA > 16);
            var seventeenToSeventyThree = mappers.Single(m => m != seventyThreeToSeventeen);

            Assert.NotEmpty(seventyThreeToSeventeen.SimpleMappings);

            // The two directions are not the same size (21 vs 29 on this character), and are not a
            // strict subset of one another either - one entry in the 73-to-17 direction (bone 4 to
            // ragdoll bone 1) has no reverse counterpart, plausibly because ragdoll bone 1 is one of
            // the 17-to-73 mapper's 42 counted-but-undecoded "unmapped bones" instead of a simple
            // mapping. What holds, and is the real cross-check: the large majority still agree
            // exactly in both directions - not a coincidence at this rate.
            var forward = seventyThreeToSeventeen.SimpleMappings.ToHashSet();
            var reversed = seventeenToSeventyThree.SimpleMappings.Select(m => ((short)m.BoneB, (short)m.BoneA)).ToHashSet();
            int agreeing = forward.Count(pair => reversed.Contains(pair));
            Assert.True(agreeing >= forward.Count - 2,
                $"only {agreeing} of {forward.Count} forward mappings have an exact reverse counterpart");

            // Bone indices stay inside each skeleton's own real bone count.
            var boneCounts = pack.Packfile.EnumerateObjects()
                .Where(o => o.ClassName == "hkaSkeleton")
                .Select(o => Core.Havok.Skeleton.HkaSkeletonReader.Read(pack.Packfile.ResolvedSections[o.SectionIndex], o.Offset).BoneCount)
                .ToHashSet();
            Assert.Contains(73, boneCounts);
            Assert.Contains(17, boneCounts);

            foreach (var (boneA, boneB) in seventyThreeToSeventeen.SimpleMappings)
            {
                Assert.InRange(boneA, (short)0, (short)72);
                Assert.InRange(boneB, (short)0, (short)16);
            }
        }
    }

    /// <summary>
    /// Every rigid body's shape pointer resolves to a real <c>hkpCapsuleShape</c> — held across the
    /// whole set, not one example.
    /// </summary>
    [RequiresGameFact]
    public void EveryRigidBodyPointsAtARealCapsuleShape()
    {
        var (pack, owner) = BabyJane();
        using (owner)
        {
            var capsules = pack.Packfile.EnumerateObjects()
                .Where(o => o.ClassName == HkpCapsuleShapeReader.ClassName)
                .Select(o => (o.SectionIndex, o.Offset))
                .ToHashSet();
            var bodies = pack.Packfile.EnumerateObjects().Where(o => o.ClassName == HkpRigidBodyReader.ClassName).ToList();

            Assert.Equal(17, bodies.Count);

            foreach (var bodyObject in bodies)
            {
                var section = pack.Packfile.ResolvedSections[bodyObject.SectionIndex];
                var shape = HkpRigidBodyReader.ReadShape(pack.Packfile, section, bodyObject.Offset);
                Assert.NotNull(shape);
                Assert.Contains((shape!.Value.Section.Index, shape.Value.Offset), capsules);
            }
        }
    }

    /// <summary>
    /// Every constraint's data pointer resolves to a real <c>hkpRagdollConstraintData</c>, and both
    /// entity pointers resolve to real <c>hkpRigidBody</c> objects — held across the whole set, and
    /// the resulting graph is a coherent hierarchy, not a coincidence: rigid body 0 (the pelvis) is
    /// one of the two entities on several constraints, the shape a root-radiating skeletal hierarchy
    /// produces.
    /// </summary>
    [RequiresGameFact]
    public void EveryConstraintConnectsTwoRealRigidBodiesToRealConstraintData()
    {
        var (pack, owner) = BabyJane();
        using (owner)
        {
            var bodies = pack.Packfile.EnumerateObjects()
                .Where(o => o.ClassName == HkpRigidBodyReader.ClassName)
                .Select(o => (o.SectionIndex, o.Offset))
                .ToHashSet();
            var constraintData = pack.Packfile.EnumerateObjects()
                .Where(o => o.ClassName == "hkpRagdollConstraintData")
                .Select(o => (o.SectionIndex, o.Offset))
                .ToHashSet();
            var constraints = pack.Packfile.EnumerateObjects().Where(o => o.ClassName == HkpConstraintInstanceReader.ClassName).ToList();

            Assert.Equal(16, constraints.Count);

            int pelvisConnections = 0;
            var pelvis = bodies.OrderBy(b => b.Offset).First(); // rigid body 0, per docs/research/havok-physics.md
            foreach (var constraintObject in constraints)
            {
                var section = pack.Packfile.ResolvedSections[constraintObject.SectionIndex];
                var constraint = HkpConstraintInstanceReader.Read(pack.Packfile, section, constraintObject.Offset);

                Assert.NotNull(constraint.Data);
                Assert.Contains((constraint.Data!.Value.Section.Index, constraint.Data.Value.Offset), constraintData);

                Assert.NotNull(constraint.EntityA);
                Assert.Contains((constraint.EntityA!.Value.Section.Index, constraint.EntityA.Value.Offset), bodies);

                Assert.NotNull(constraint.EntityB);
                Assert.Contains((constraint.EntityB!.Value.Section.Index, constraint.EntityB.Value.Offset), bodies);

                if ((constraint.EntityA.Value.Section.Index, constraint.EntityA.Value.Offset) == pelvis ||
                    (constraint.EntityB.Value.Section.Index, constraint.EntityB.Value.Offset) == pelvis)
                {
                    pelvisConnections++;
                }
            }

            // A root-radiating hierarchy connects several joints directly to the root; a coincidence
            // would not.
            Assert.True(pelvisConnections >= 3, $"only {pelvisConnections} constraints touch the pelvis body");
        }
    }
}
