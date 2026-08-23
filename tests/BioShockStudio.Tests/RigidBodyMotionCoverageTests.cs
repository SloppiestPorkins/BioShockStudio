using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Havok.Physics;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The rigid-body motion layout, checked against every ragdoll in the game rather than one
/// character.
/// </summary>
/// <remarks>
/// The offsets were found on <c>AggressorBabyJane</c>. This project has been bitten before by a
/// structure that held on one sample and was package-local, so the claim is only worth making if it
/// holds everywhere. The check is structural, not a fixed expectation: every body's basis must be a
/// proper rotation and every mass must be a round, positive number of kilograms.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class RigidBodyMotionCoverageTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void TheLayoutHoldsForEveryRagdollInTheGame()
    {
        int characters = 0, bodies = 0, properRotations = 0, roundMasses = 0, fixedBodies = 0;
        var failures = new List<string>();
        var massValues = new Dictionary<float, int>();
        var fixedOwners = new HashSet<string>(StringComparer.Ordinal);
        var fixedInCharacters = new HashSet<string>(StringComparer.Ordinal);

        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            BioShockPackage package;
            try { package = BioShockPackage.Open(file); }
            catch (Exception ex) when (ex is InvalidDataException or IOException) { continue; }

            using (package)
            {
                foreach (var wrapper in package.Exports
                             .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper))
                {
                    AnimationPackage pack;
                    try { pack = AnimationPackage.Load(package, wrapper); }
                    catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                                   or ArgumentOutOfRangeException or NotSupportedException)
                    {
                        continue;
                    }

                    var objects = pack.Packfile.EnumerateObjects().ToList();

                    var rigidBodies = objects
                        .Where(o => o.ClassName == HkpRigidBodyReader.ClassName)
                        .ToList();
                    if (rigidBodies.Count == 0) continue;

                    // NOT a character/prop discriminator: props carry hkaRagdollInstance too.
                    // Tried and disproved here — LoadRoomDoorAnim, SecurityCameraSmall,
                    // BlastDoorPost and SlotMachine_MESH all have one. Recorded rather than
                    // deleted, because "a ragdoll instance means a character" is an easy and wrong
                    // assumption to make twice.
                    bool hasRagdollInstance = objects.Any(o =>
                        o.ClassName == Core.Havok.Physics.HkaRagdollInstanceReader.ClassName);

                    characters++;

                    foreach (var body in rigidBodies)
                    {
                        var motion = HkpRigidBodyReader.ReadMotion(
                            pack.Packfile.ResolvedSections[body.SectionIndex], body.Offset);
                        if (motion is null) continue;

                        bodies++;

                        if (motion.IsProperRotation) properRotations++;
                        else if (failures.Count < 10)
                            failures.Add($"{wrapper.ObjectName}@{body.Offset}: det={motion.Determinant:F4}");

                        // "Round" means a clean authored value, not an integer. The first cut of
                        // this test required whole kilograms and reported 160 failures across the
                        // game — every one of which was 7.5, 1.5 or 0.2 kg. Those are authored
                        // numbers too (a flower vase weighs 0.2 kg), so the test was wrong, not the
                        // decode. A tenth of a kilogram is still a very strong check: a misread
                        // offset yields arbitrary reals, which do not land on 0.1 boundaries.
                        // A fixed body has infinite mass by design and has no authored figure to
                        // check. The first cut of this test counted those as failures; they are
                        // doors, wall-mounted cameras and a scripted set-piece, which is exactly
                        // what ought to be anchored. The test was wrong, not the decode — twice.
                        if (motion.IsFixed)
                        {
                            fixedBodies++;
                            fixedOwners.Add(wrapper.ObjectName);
                            if (hasRagdollInstance) fixedInCharacters.Add(wrapper.ObjectName);
                            continue;
                        }

                        float mass = motion.Mass;
                        if (mass > 0 && Math.Abs(mass * 10f - MathF.Round(mass * 10f)) < 0.02f)
                        {
                            roundMasses++;
                            massValues[MathF.Round(mass, 1)] = massValues.GetValueOrDefault(MathF.Round(mass, 1)) + 1;
                        }
                        else if (failures.Count < 10)
                        {
                            failures.Add($"{wrapper.ObjectName}@{body.Offset}: mass={mass:F4}");
                        }
                    }
                }
            }
        }

        Log($"{characters} ragdolls, {bodies} rigid bodies");
        Log($"  proper rotations: {properRotations}/{bodies}");
        Log($"  fixed bodies:     {fixedBodies} (infinite mass), owners: {string.Join(", ", fixedOwners)}");
        Log($"  round masses:     {roundMasses}/{bodies - fixedBodies} simulated");
        Log("  mass values seen:");
        foreach (var (mass, count) in massValues.OrderByDescending(p => p.Value))
            Log($"    {mass,8:F1} kg  x{count}");
        foreach (string line in failures) Log("    FAIL " + line);

        Assert.True(characters > 1, $"only {characters} ragdoll(s) found — this is the multi-sample check");
        Assert.True(bodies > 50, $"only {bodies} rigid bodies were read");

        // The layout holds everywhere, or it is not the layout.
        Assert.Equal(bodies, properRotations);
        Assert.Equal(bodies - fixedBodies, roundMasses);

        // Fixed bodies exist and are a small minority. Which rigs they belong to is logged rather
        // than asserted: by name they are all world-anchored props (doors, wall cameras, a blast
        // door post, a slot machine, a scripted plane crash), but this test has no structural way to
        // say "prop" — the obvious candidate, "has no hkaRagdollInstance", is false, since props
        // carry those too. Asserting the category would mean encoding a guess as a rule.
        Assert.True(fixedBodies > 0, "no fixed bodies found — the infinite-mass case has vanished");
        Assert.InRange(fixedBodies, 1, bodies / 10);

        // Whole kilograms still dominate by a wide margin, which is what an authored mass table
        // looks like: 5, 10, 1, 30, 20, 60, 50 are the commonest values in the game.
        Assert.True(massValues.ContainsKey(5f) && massValues.ContainsKey(10f));
    }
}
