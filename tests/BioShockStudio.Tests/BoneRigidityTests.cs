using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Diagnostics;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// A skeleton is rigid: a bone keeps its distance from its parent whatever the pose.
/// </summary>
/// <remarks>
/// <para>
/// The audit reported all 16,031 animations playable while several folded a splicer's arms into his
/// chest, because it checked for NaN, zero frames and unbound tracks and never for a bone leaving
/// its parent. A user found it by looking at <c>PI_Fire_B</c>; nothing in the numbers said so.
/// </para>
/// <para>
/// These tests hold both directions against real shipped bytes — the check fires on the known-bad
/// animations and stays silent on a known-good one from the same rig and the same animation set.
/// A check that only ever reads zero is worth nothing.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class BoneRigidityTests(GameFixture game)
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

    private (int Count, int Frame, string Bone) Measure(Core.Assets.AnimationPackage pack, string name)
    {
        var animation = pack.Animations.First(a => string.Equals(a.Name, name, StringComparison.OrdinalIgnoreCase));
        return AnimationAudit.WorstCollapse(pack.Skeleton, pack.Decode(animation));
    }

    /// <summary>
    /// The 54-track fire animations fold half the driven skeleton into itself on frame 0.
    /// </summary>
    /// <remarks>
    /// Recorded as a measurement, not as an accepted state: see <c>docs/HANDOFF.md</c> §6.0c. If a
    /// future decode change fixes them these numbers drop, and this test should be updated to the
    /// new evidence rather than deleted.
    /// </remarks>
    [RequiresGameFact]
    public void TheFireAnimationsFoldBonesIntoTheirParents()
    {
        var (pack, owner) = BabyJane();
        using (owner)
        {
            foreach (string name in new[] { "PI_Fire", "PI_Fire_B", "PI_fire_C" })
            {
                var (count, frame, bone) = Measure(pack, name);

                Assert.True(count >= 20,
                    $"{name} folds only {count} bones — if the decode was fixed, update §6.0c and this test");
                Assert.Equal(0, frame);
                Assert.False(string.IsNullOrEmpty(bone));
            }

            // The smg clip is the same shape, less severe.
            var smg = Measure(pack, "smg_fire");
            Assert.True(smg.Count >= 10, $"smg_fire folds only {smg.Count} bones");
        }
    }

    /// <summary>
    /// A healthy animation on the same rig folds nothing — so the check is measuring the animation,
    /// not the skeleton or the measurement itself.
    /// </summary>
    [RequiresGameFact]
    public void AHealthyAnimationOnTheSameRigFoldsNothing()
    {
        var (pack, owner) = BabyJane();
        using (owner)
        {
            // Same character, same Pistol set, and a full 73 tracks against the fire clips' 54.
            var (count, _, _) = Measure(pack, "PI_AttackMelee_A");
            Assert.Equal(0, count);

            var animation = pack.Animations.First(a => a.Name == "PI_AttackMelee_A");
            Assert.Equal(pack.Skeleton.BoneCount, pack.Decode(animation).Tracks.Count);
        }
    }

    /// <summary>
    /// The whole game: the fault is contained, and the check does not fire indiscriminately.
    /// </summary>
    /// <remarks>
    /// If a decode change makes this number climb, something that used to be right has broken; if it
    /// falls to zero the fault is fixed and §6.0c can be closed. Either way the number is the point.
    /// </remarks>
    [RequiresGameFact]
    public void MostAnimationsKeepTheirBonesWhereTheyBelong()
    {
        int animations = 0, folding = 0, severe = 0;

        // One package is enough to be representative and keeps the test quick; the CLI audit sweeps
        // the whole game.
        using var package = BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));

        foreach (var wrapper in package.Exports.Where(e =>
                     package.GetClassName(e) == AssetClasses.AnimationPackageWrapper && e.SerialSize > 0))
        {
            Core.Assets.AnimationPackage pack;
            try { pack = Core.Assets.AnimationPackage.Load(package, wrapper); }
            catch { continue; }

            foreach (var animation in pack.Animations)
            {
                Core.Animation.DecodedAnimation decoded;
                try { decoded = pack.Decode(animation); }
                catch { continue; }

                animations++;
                var (count, _, _) = AnimationAudit.WorstCollapse(pack.Skeleton, decoded);
                if (count > 0) folding++;
                if (count >= 20) severe++;
            }
        }

        // 1-Medical carries 990; anything far below that means the sweep stopped early.
        Assert.True(animations > 900, $"only {animations} animations swept");

        // The check fires — otherwise it proves nothing.
        Assert.True(severe > 0, "the known-bad fire animations were not detected");

        // And it does not fire on the bulk of the game.
        Assert.True(folding < animations / 20,
            $"{folding} of {animations} animations fold a bone — that is too many to be the known fault");
    }
}
