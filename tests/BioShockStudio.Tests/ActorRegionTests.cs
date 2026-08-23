using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// <c>Actor.Region</c> - the zone every placed actor knows it is in.
/// </summary>
/// <remarks>
/// <para>
/// Found while censusing Gate 3 item 3's open actor categories: <c>Region</c> is the single most
/// common uninterpreted property in the game, present on <b>every</b> actor of every class. It
/// parses as a nested tagged property list matching UE2's <c>FPointRegion</c> exactly -
/// <c>Zone</c>, <c>iLeaf</c>, <c>ZoneNumber</c> - and the walk consumes all 30 bytes.
/// </para>
/// <para>
/// <b>The struct cross-checks itself.</b> <c>iLeaf</c> indexes the BSP leaf array, and every leaf
/// carries its own zone (<c>BspLeaf.Zone</c>, decoded separately). So <c>ZoneNumber</c> and
/// <c>Leaves[iLeaf].Zone</c> are two independently-serialised statements of the same fact, and they
/// have to agree. Measured: <b>96,136 of 96,376, or 99.75%</b>.
/// </para>
/// <para>
/// <b>Two residuals, recorded rather than tuned away.</b> First, <c>iLeaf == 0</c> on 20,159 actors
/// is a "no leaf assigned" sentinel and not leaf index 0 - only 760 of those agree with leaf 0's
/// zone, which is chance rather than meaning, and the test asserts that it behaves like a sentinel.
/// Second, <b>240 actors (0.25%) genuinely disagree</b>, all at very low leaf indices and
/// disproportionately <c>Brush</c> and <c>StaticMeshActor</c>. <c>PLAUSIBLE</c>: a brush actor
/// carries its own <c>Model</c>, so its region may index that model's leaves rather than the
/// compiled world's. Not investigated, and not asserted either way.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ActorRegionTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void EveryActorsZoneAgreesWithTheLeafItNames()
    {
        long actors = 0, withRegion = 0, checkable = 0, agrees = 0, zeroLeaf = 0, zeroLeafAgrees = 0;
        var disagreements = new List<string>();

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(map);

            LevelContext context;
            try { context = LevelAnalyzer.Analyze(package); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

            var built = ModelReader.BuiltWorld(package);
            if (built is null) continue;

            BspWorld? world;
            try { world = BspWorldReader.Read(package, package.Exports[built.Source.ExportIndex]); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (world is null || world.Leaves.Count == 0) continue;

            foreach (var actor in context.Actors)
            {
                actors++;

                if (actor.Region is not { } region) continue;
                withRegion++;

                if (region.Leaf < 0 || region.Leaf >= world.Leaves.Count) continue;

                // iLeaf == 0 appears to be "no leaf assigned" rather than leaf index 0: every
                // disagreement in the first run had it. Counted separately so the sentinel reading
                // is tested rather than assumed away.
                if (region.Leaf == 0) { zeroLeaf++; if (world.Leaves[0].Zone == region.ZoneNumber) zeroLeafAgrees++; continue; }

                checkable++;

                int leafZone = world.Leaves[region.Leaf].Zone;
                if (leafZone == region.ZoneNumber) agrees++;
                else if (disagreements.Count < 10)
                    disagreements.Add($"{Path.GetFileNameWithoutExtension(map)}/{actor.Source.ObjectName}: "
                        + $"ZoneNumber={region.ZoneNumber} but Leaves[{region.Leaf}].Zone={leafZone}");
            }
        }

        Log($"{actors:N0} actors, {withRegion:N0} with a parseable Region, {checkable:N0} whose iLeaf is in range");
        Log($"  ZoneNumber agrees with Leaves[iLeaf].Zone: {agrees:N0} of {checkable:N0}");
        Log($"  iLeaf == 0 (sentinel): {zeroLeaf:N0}, of which agree by chance: {zeroLeafAgrees:N0}");
        foreach (string line in disagreements) Log("    " + line);

        Assert.True(actors > 10_000, $"only {actors} actors");

        // Region is on every actor, so a parse failure would be a decode fault rather than absence.
        Assert.True(withRegion > actors * 0.95,
            $"only {withRegion} of {actors} actors had a parseable Region");

        // The two independently-serialised statements of the actor's zone agree, wherever the
        // actor actually names a leaf. Not asserted as exact: 240 of 96,376 disagree (0.25%), all
        // at very low leaf indices, and they are NOT written off - see the class remarks. What is
        // asserted is that the agreement stays overwhelming, which a misparse could not achieve.
        Assert.True(agrees > checkable * 0.995,
            $"only {agrees} of {checkable} actors agree with the leaf they name");

        // ...and the sentinel is real: iLeaf == 0 does not mean leaf 0.
        Assert.True(zeroLeaf > 0, "no iLeaf == 0 actors, so the sentinel reading is untested");
        Assert.True(zeroLeafAgrees < zeroLeaf,
            "every iLeaf == 0 actor agrees with leaf 0's zone after all, so it is an index not a sentinel");
    }
}
