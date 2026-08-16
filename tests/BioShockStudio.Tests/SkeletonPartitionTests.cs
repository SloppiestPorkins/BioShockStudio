using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Havok.Animation;
using BioShockStudio.Core.Havok.Objects;
using BioShockStudio.Core.Havok.Skeleton;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Do the shipped skeletons and bindings use Havok's <b>partitions</b>?
/// </summary>
/// <remarks>
/// <para>
/// A partition is a named contiguous bone range on an <c>hkaSkeleton</c>, and an
/// <c>hkaAnimationBinding</c> can record which partitions its animation is sampled against. Both
/// fields were documented in this project's own header comments and never read.
/// </para>
/// <para>
/// The question is <c>docs/HANDOFF.md</c> §6.0c's: four fire animations on
/// <c>AggressorBabyJane</c> drive bones 3..56 of 73 — contiguous, ascending, a subset — and collapse
/// 25 of them onto their parents on frame 0. A contiguous named bone range is exactly what a
/// partition is, so "these are partial-body clips" is a hypothesis worth *measuring* before it is
/// worth arguing about.
/// </para>
/// <para>
/// <b>These tests record what the game contains. They do not assert a theory.</b> Whatever they
/// report is written into §6.0c so the next session starts from a fact rather than from this
/// paragraph.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class SkeletonPartitionTests(GameFixture game)
{
    private (AnimationPackage Pack, BioShockPackage Owner) Open(string map, string wrapper)
    {
        var package = BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), map + ".bsm"));

        var export = package.Exports
            .Where(e => e.ObjectName == wrapper
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize)!;

        return (AnimationPackage.Load(package, export), package);
    }

    /// <summary>Every <c>hkaSkeleton</c> in a wrapper, with the partitions it declares.</summary>
    private static List<(string Name, int Bones, int Partitions)> Skeletons(AnimationPackage pack)
    {
        var found = new List<(string, int, int)>();

        foreach (var obj in pack.Packfile.EnumerateObjects())
        {
            if (obj.ClassName != HkaSkeletonReader.ClassName) continue;

            var section = pack.Packfile.ResolvedSections[obj.SectionIndex];
            var skeleton = HkaSkeletonReader.Read(section, obj.Offset);
            var partitions = HkaSkeletonReader.ReadPartitions(section, obj.Offset);

            found.Add((skeleton.Name, skeleton.BoneCount, partitions.Count));
        }

        return found;
    }

    /// <summary>
    /// Does the rig whose fire animations collapse declare any partitions?
    /// </summary>
    [RequiresGameFact]
    public void TheSkeletonBehindTheFireAnimationsIsMeasuredForPartitions()
    {
        var (pack, owner) = Open("1-Medical", "UAPW_AggressorBabyJane");
        using (owner)
        {
            var skeletons = Skeletons(pack);
            Assert.NotEmpty(skeletons);

            string measured = string.Join("; ",
                skeletons.Select(s => $"{s.Name} {s.Bones} bones, {s.Partitions} partitions"));

            // Measured: six skeletons in this wrapper — three copies of Bip01 (73 bones) and three
            // ragdolls (17) — and NOT ONE declares a partition. So the rig whose fire animations
            // collapse has no partitions for an animation to be sampled against, and the
            // partial-body reading of §6.0c is dead on the skeleton side alone.
            Assert.All(skeletons, s => Assert.Equal(0, s.Partitions));

            Assert.Contains(skeletons, s => s.Bones == 73);
            Assert.True(skeletons.Count >= 2, measured);
        }
    }

    /// <summary>
    /// Do the four collapsing fire animations' bindings carry partition indices?
    /// </summary>
    /// <remarks>
    /// A control is included deliberately. <c>PI_AttackMelee_A</c> is a healthy 73-track animation on
    /// the same rig and in the same set; if it carries the same partition data as the broken ones,
    /// partitions cannot be what distinguishes them, and this line of enquiry is closed by
    /// measurement rather than by opinion.
    /// </remarks>
    [RequiresGameFact]
    public void TheFireAnimationBindingsAreMeasuredForPartitionIndices()
    {
        var (pack, owner) = Open("1-Medical", "UAPW_AggressorBabyJane");
        using (owner)
        {
            // Bindings are enumerated from the packfile rather than looked up by animation name:
            // BioShockAnimation records where the *animation* object is, not its binding, and the
            // 54-track clips are identifiable by their own track count anyway.
            int bindings = 0, withPartitions = 0, partialBindings = 0, partialWithPartitions = 0;

            foreach (var obj in pack.Packfile.EnumerateObjects())
            {
                if (obj.ClassName != HkaAnimationBindingReader.ClassName) continue;

                var section = pack.Packfile.ResolvedSections[obj.SectionIndex];
                var binding = HkaAnimationBindingReader.Read(section, obj.Offset);
                var indices = HkaAnimationBindingReader.ReadPartitionIndices(section, obj.Offset);

                bindings++;
                bool partial = binding.TrackCount > 0 && binding.TrackCount < pack.Skeleton.BoneCount;
                if (partial) partialBindings++;

                if (indices.Length > 0)
                {
                    withPartitions++;
                    if (partial) partialWithPartitions++;
                }

                // A partition index indexes the skeleton's partition array. Whatever the count, the
                // values have to be small and non-negative, or the field is not what the offset says.
                foreach (short index in indices)
                    Assert.InRange(index, (short)0, (short)64);
            }

            Assert.True(bindings > 0, "no hkaAnimationBinding objects were found");

            string measured =
                $"{bindings} bindings, {withPartitions} with partition indices; "
                + $"{partialBindings} drive a subset of the {pack.Skeleton.BoneCount} bones, "
                + $"{partialWithPartitions} of those carry partition indices";

            // Measured on the shipped rig: 457 bindings, NOT ONE carrying a partition index — and
            // only 9 of the 457 drive a subset of the bones at all. Partitions are therefore not
            // what distinguishes the collapsing fire clips from the healthy ones, and §6.0c can
            // strike the idea on evidence. This test exists to keep that answer true: if a future
            // change starts reporting partitions here, the elimination no longer holds.
            Assert.Equal(0, withPartitions);
            Assert.Equal(0, partialWithPartitions);

            Assert.True(bindings > 400, measured);
            Assert.True(partialBindings > 0,
                "no binding drives a subset of the skeleton, so the 54-track clips are not being "
                + "seen at all: " + measured);
        }
    }
}
