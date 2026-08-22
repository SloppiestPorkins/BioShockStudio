using System.Numerics;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Havok.Animation;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Havok root motion (<c>hkaAnimation::m_extractedMotion</c>) was undocumented and unread —
/// <c>AnimationAuditRow.WorstBlockSlack</c>'s own byte-layout doc comment already named the field at
/// <c>+24</c>, right between the track counts and the annotation array, but the reader jumped from
/// <c>+20</c> straight to <c>+28</c>. A whole-game census (<c>audit-animations</c>) found it is not a
/// theoretical field: 6,356 of 16,031 animations (39.6%) carry it. See
/// <c>docs/research/root-motion.md</c> for the full record.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class RootMotionTests(GameFixture game)
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

    private (Core.Assets.AnimationPackage Package, BioShockPackage Owner) Hands()
    {
        var package = BioShockPackage.Open(game.LighthousePackage);
        var wrapper = package.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper);
        return (Core.Assets.AnimationPackage.Load(package, wrapper), package);
    }

    /// <summary>
    /// The resolved target is a real, class-named object — read from the packfile's own virtual
    /// fixup table, not assumed from the SDK header alone — and its fields decode to the class's
    /// documented defaults and cross-validate against the owning animation's own duration.
    /// </summary>
    [RequiresGameFact]
    public void ExtractedMotionResolvesToADefaultAnimatedReferenceFrame()
    {
        var (pack, owner) = BabyJane();
        using (owner)
        {
            var animation = pack.Animations.First(a => a.Name == "Death_GrabHead");
            var section = pack.Packfile.ResolvedSections[animation.SectionIndex];
            var header = HkaSplineCompressedAnimationReader.Read(section, animation.Offset);

            Assert.True(header.HasExtractedMotion);

            var target = HkaDefaultAnimatedReferenceFrameReader.ResolveTarget(pack.Packfile, section, animation.Offset);
            Assert.NotNull(target);

            var obj = pack.Packfile.EnumerateObjects()
                .FirstOrDefault(o => o.SectionIndex == target.Value.Section.Index && o.Offset == target.Value.Offset);
            Assert.NotNull(obj);
            Assert.Equal(HkaDefaultAnimatedReferenceFrameReader.ClassName, obj!.ClassName);

            var frame = HkaDefaultAnimatedReferenceFrameReader.Read(target.Value.Section, target.Value.Offset);

            Assert.Equal(new Vector4(0, 0, 1, 0), frame.Up);
            Assert.Equal(new Vector4(1, 0, 0, 0), frame.Forward);
            Assert.Equal(header.Duration, frame.Duration, 3);
            Assert.Equal(header.NumFrames, frame.Samples.Count);
            Assert.Equal(Vector4.Zero, frame.Samples[0]);
        }
    }

    /// <summary>
    /// Multiple, independent animations agree: sample count tracks frame count exactly, and every
    /// curve starts at the origin ("motion represents the absolute offset from the start of the
    /// animation" per the SDK header). One agreeing sample proves nothing on its own.
    /// </summary>
    [RequiresGameFact]
    public void SampleCountTracksFrameCountAcrossSeveralAnimations()
    {
        var (pack, owner) = BabyJane();
        using (owner)
        {
            int checkedCount = 0;
            foreach (var animation in pack.Animations)
            {
                var section = pack.Packfile.ResolvedSections[animation.SectionIndex];
                var header = HkaSplineCompressedAnimationReader.Read(section, animation.Offset);
                if (!header.HasExtractedMotion) continue;

                var target = HkaDefaultAnimatedReferenceFrameReader.ResolveTarget(pack.Packfile, section, animation.Offset);
                Assert.NotNull(target);
                var frame = HkaDefaultAnimatedReferenceFrameReader.Read(target.Value.Section, target.Value.Offset);

                Assert.Equal(header.NumFrames, frame.Samples.Count);
                Assert.Equal(Vector4.Zero, frame.Samples[0]);

                checkedCount++;
                if (checkedCount >= 10) break;
            }

            Assert.True(checkedCount >= 10, $"only {checkedCount} extracted-motion animations found to cross-check");
        }
    }

    /// <summary>
    /// A control in the other direction: the stationary first-person hands rig carries no root
    /// motion on any of its 130 animations, which is what a viewmodel that never itself moves through
    /// the world should do.
    /// </summary>
    [RequiresGameFact]
    public void FirstPersonHandsCarryNoRootMotion()
    {
        var (pack, owner) = Hands();
        using (owner)
        {
            Assert.Equal(130, pack.Animations.Count);

            foreach (var animation in pack.Animations)
            {
                var section = pack.Packfile.ResolvedSections[animation.SectionIndex];
                var header = HkaSplineCompressedAnimationReader.Read(section, animation.Offset);
                Assert.False(header.HasExtractedMotion, $"{animation.Owner}/{animation.Name} unexpectedly carries root motion");
            }
        }
    }

    /// <summary>
    /// Beyond the one splicer this file otherwise tests: three more skeleton families
    /// (<c>GathererGirl</c>, both Big Daddy variants), 196 more root-motion animations, 0 sample-count
    /// mismatches. This is what actually settles the "Z and W are dead" hypothesis an earlier version
    /// of this reader's doc comment carried — they aren't. <c>GathererGirl</c> (a Little Sister who
    /// climbs into vents) carries real, growing Z displacement; all three characters carry real,
    /// growing W. Full values in <c>docs/research/root-motion.md</c>.
    /// </summary>
    [RequiresGameFact]
    public void ZAndWAreLiveOnOtherSkeletonFamilies()
    {
        (int WithMotion, int NonZeroZ, int NonZeroW) Census(BioShockPackage package, string wrapperName)
        {
            var wrapper = package.Exports
                .Where(e => e.ObjectName == wrapperName && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
                .MaxBy(e => e.SerialSize)!;
            var pack = Core.Assets.AnimationPackage.Load(package, wrapper);

            int withMotion = 0, nonZeroZ = 0, nonZeroW = 0;
            foreach (var animation in pack.Animations)
            {
                var section = pack.Packfile.ResolvedSections[animation.SectionIndex];
                var header = HkaSplineCompressedAnimationReader.Read(section, animation.Offset);
                if (!header.HasExtractedMotion) continue;
                withMotion++;

                var target = HkaDefaultAnimatedReferenceFrameReader.ResolveTarget(pack.Packfile, section, animation.Offset);
                if (target is null) continue;
                var frame = HkaDefaultAnimatedReferenceFrameReader.Read(target.Value.Section, target.Value.Offset);

                Assert.Equal(header.NumFrames, frame.Samples.Count);
                foreach (var s in frame.Samples)
                {
                    if (MathF.Abs(s.Z) > 0.0001f) nonZeroZ++;
                    if (MathF.Abs(s.W) > 0.0001f) nonZeroW++;
                }
            }
            return (withMotion, nonZeroZ, nonZeroW);
        }

        using var medical = BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));
        using var lighthouse = BioShockPackage.Open(game.LighthousePackage);

        var gatherer = Census(medical, "UAPW_GathererGirl");
        var rosie = Census(lighthouse, "UAPW_ProtectorRosie");
        var bouncer = Census(medical, "UAPW_NewProtectorBouncer");

        Assert.True(gatherer.WithMotion > 0 && rosie.WithMotion > 0 && bouncer.WithMotion > 0);

        // W (yaw) is live on all three - the field is exercised, not structurally unused.
        Assert.True(gatherer.NonZeroW > 0 && rosie.NonZeroW > 0 && bouncer.NonZeroW > 0);

        // Z (vertical) is live on at least one - the Little Sister climbing into vents.
        Assert.True(gatherer.NonZeroZ > 0);
    }
}
