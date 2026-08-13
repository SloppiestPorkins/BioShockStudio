using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Which weapon animation plays with which hand animation.
/// <para>
/// The rule used to be "the frame counts match exactly", and the shipped data disproves it: a weapon
/// rig is authored sparsely, so one performance is 2 frames on one rig and 22 on the other. The
/// invariant that holds is the duration.
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
public sealed class AnimationPairingTests(GameFixture game)
{
    [Fact]
    public void DurationDecidesThePairing()
    {
        // The pairing this rule exists to reject, and the one it must keep. Both are real: the
        // hands' FireLauncher is 1.433s, the weapon's FireLast 0.70s and its Fire 1.433s.
        Assert.False(AnimationPairing.PlaysTogether(1.433f, 0.70f));
        Assert.True(AnimationPairing.PlaysTogether(1.433f, 1.433f));

        // Real pairings that the old frame-count rule threw away.
        Assert.True(AnimationPairing.PlaysTogether(3.067f, 3.00f));   // crossbow reload, 93 vs 91 frames
        Assert.True(AnimationPairing.PlaysTogether(0.70f, 0.70f));    // FireLastLauncher, 22 vs 2 frames
        Assert.True(AnimationPairing.PlaysTogether(0.233f, 0.233f));  // EquipLauncher, 8 vs 2 frames
        Assert.True(AnimationPairing.PlaysTogether(2.00f, 2.20f));    // zoomed fire, 9.1% apart

        // The gap the tolerance sits in: everything correct is within 10%, the rejection is 51%.
        Assert.InRange(AnimationPairing.DurationTolerance, 0.10f, 0.50f);
    }

    [Fact]
    public void TheNameOnlyBreaksTiesAmongCandidatesThatAgreeOnDuration()
    {
        (string, float)[] weapon = [("Fire", 1.433f), ("FireLast", 0.70f), ("Reload", 4.00f)];

        // Name alone prefers FireLast — it shares six characters with FireLauncher against Fire's
        // four. Duration removes it from the running first, which is the whole point.
        Assert.Equal("Fire", AnimationPairing.Counterpart("FireLauncher", 1.433f, weapon));
        Assert.Equal("FireLast", AnimationPairing.Counterpart("FireLastLauncher", 0.70f, weapon));
        Assert.Equal("Reload", AnimationPairing.Counterpart("ReloadLauncher", 4.00f, weapon));

        // A short match is still rejected rather than guessed at.
        Assert.Null(AnimationPairing.Counterpart("X", 1.433f, weapon));
    }

    [Fact]
    public void TheAttachmentIsSampledByNormalisedTime()
    {
        // A 2-frame weapon animation against a 22-frame hands animation: the weapon must run from
        // its first key to its last across the host's span, not sit on frame 0 and then read off the
        // end of its own track.
        Assert.Equal(0, AnimationPairing.AttachmentFrame(22, 2, 0));
        Assert.Equal(1, AnimationPairing.AttachmentFrame(22, 2, 21));
        Assert.Equal(0, AnimationPairing.AttachmentFrame(22, 2, 10));

        // Equal lengths must be the identity, or every already-correct pairing changes.
        for (int f = 0; f < 55; f++) Assert.Equal(f, AnimationPairing.AttachmentFrame(55, 55, f));

        // Near-equal lengths stay in step and never run past the end.
        Assert.Equal(90, AnimationPairing.AttachmentFrame(93, 91, 92));
        Assert.Equal(0, AnimationPairing.AttachmentFrame(1, 1, 0));
    }

    [RequiresGameFact]
    public void TheRealCrossbowAndLauncherPairAsMeasured()
    {
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
        var crossbow = Load(game.WeaponPackage, "UAPW_WP_Crossbow");
        var launcher = Load(game.WeaponPackage, "UAPW_WP_GrenadeLauncher");

        // Read the durations from the game rather than restating them, so this fails if the
        // premise ever stops being true of the shipped data.
        var weaponCrossbow = crossbow.Animations.Select(a => (a.Name, a.Duration)).ToList();
        var weaponLauncher = launcher.Animations.Select(a => (a.Name, a.Duration)).ToList();

        Assert.Equal("Reload", Pair(hands, "ReloadCrossbow", weaponCrossbow));
        Assert.Equal("Fire", Pair(hands, "FireCrossbow", weaponCrossbow));

        // The launcher is the case that motivated all of this.
        Assert.Equal("Fire", Pair(hands, "FireLauncher", weaponLauncher));
        Assert.Equal("FireLast", Pair(hands, "FireLastLauncher", weaponLauncher));
        Assert.Equal("Reload", Pair(hands, "ReloadLauncher", weaponLauncher));
    }

    [RequiresGameFact]
    public void FrameCountsAloneWouldStillRejectThosePairings()
    {
        // States the premise of the change as a test: these pair on duration and would not on
        // frames. If the data ever changes, this says so rather than the rule quietly over-fitting.
        var hands = Load(game.LighthousePackage, "UAPW_NEWPlayerHands");
        var crossbow = Load(game.WeaponPackage, "UAPW_WP_Crossbow");
        var launcher = Load(game.WeaponPackage, "UAPW_WP_GrenadeLauncher");

        Assert.NotEqual(
            hands.Find("ReloadCrossbow")!.FrameCount, crossbow.Find("Reload")!.FrameCount);
        Assert.NotEqual(
            hands.Find("FireLastLauncher")!.FrameCount, launcher.Find("FireLast")!.FrameCount);
        Assert.NotEqual(
            hands.Find("EquipLauncher")!.FrameCount, launcher.Find("Equip")!.FrameCount);
    }

    private static string? Pair(
        AnimationPackage hands, string name, IReadOnlyList<(string Name, float Duration)> candidates)
    {
        var animation = hands.Find(name);
        Assert.NotNull(animation);
        return AnimationPairing.Counterpart(name, animation.Duration, candidates);
    }

    private static AnimationPackage Load(string packagePath, string objectName)
    {
        using var package = BioShockPackage.Open(packagePath);
        var export = package.Exports
            .Where(e => e.ObjectName == objectName
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize);

        Assert.True(export is not null, $"{objectName} not found in {Path.GetFileName(packagePath)}");
        return AnimationPackage.Load(package, export!);
    }
}
