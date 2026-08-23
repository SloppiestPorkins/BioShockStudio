using System.Numerics;
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
        int unitTimeFactor = 0, zeroVelocity = 0;
        var frictions = new Dictionary<float, int>();
        var restitutions = new Dictionary<float, int>();
        var dampings = new Dictionary<float, int>();
        var movers = new List<string>();
        var movingRigs = new HashSet<string>(StringComparer.Ordinal);
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

                        // The derived half of the block. TimeFactor is the load-bearing one: 1.0
                        // is Havok's default, and a wrong offset does not read exactly 1.0 out of a
                        // 16-bit half on every body in the game.
                        if (Math.Abs(motion.TimeFactor - 1f) < 0.001f) unitTimeFactor++;
                        if (motion.LinearVelocity == Vector3.Zero && motion.AngularVelocity == Vector3.Zero)
                            zeroVelocity++;
                        else
                        {
                            movingRigs.Add(wrapper.ObjectName);
                            if (movers.Count < 8)
                                movers.Add($"{wrapper.ObjectName}: lin={motion.LinearVelocity.Length():F4} "
                                    + $"ang={motion.AngularVelocity.Length():F4}");
                        }

                        frictions[MathF.Round(motion.Friction, 3)] =
                            frictions.GetValueOrDefault(MathF.Round(motion.Friction, 3)) + 1;
                        restitutions[MathF.Round(motion.Restitution, 3)] =
                            restitutions.GetValueOrDefault(MathF.Round(motion.Restitution, 3)) + 1;
                        dampings[MathF.Round(motion.AngularDamping, 4)] =
                            dampings.GetValueOrDefault(MathF.Round(motion.AngularDamping, 4)) + 1;

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
        Log($"  timeFactor == 1.0:  {unitTimeFactor}/{bodies}");
        Log($"  zero velocities:    {zeroVelocity}/{bodies}");
        Log("  non-zero velocity bodies:");
        foreach (string m in movers) Log("    " + m);
        Log("  friction values:");
        foreach (var (v, c) in frictions.OrderByDescending(x => x.Value)) Log($"    {v,7:F3}  x{c}");
        Log("  restitution values:");
        foreach (var (v, c) in restitutions.OrderByDescending(x => x.Value)) Log($"    {v,7:F3}  x{c}");
        Log("  angular damping values:");
        foreach (var (v, c) in dampings.OrderByDescending(x => x.Value)) Log($"    {v,7:F4}  x{c}");
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

        // The derived fields. TimeFactor at exactly 1.0 everywhere is what confirms both the offset
        // and the hkHalf decode; if this drops, the motion block has shifted.
        Assert.Equal(bodies, unitTimeFactor);

        // Authored data: the overwhelming majority are at rest, and every exception belongs to one
        // single rig. That is what says this is a property of that asset rather than a misread — a
        // wrong offset would scatter non-zero values across unrelated rigs.
        Assert.True(zeroVelocity > bodies * 0.9, $"only {zeroVelocity} of {bodies} bodies are at rest");
        Assert.True(movingRigs.Count == 1,
            "non-zero velocities are spread across several rigs, which a baked-in simulation state "
            + "would not be: " + string.Join(", ", movingRigs));

        // Friction and restitution are authored constants, not a continuum. A misaligned read would
        // give hundreds of distinct reals rather than a handful of round ones.
        Assert.True(frictions.Count <= 12, $"{frictions.Count} distinct friction values — too many to be authored");
        Assert.True(restitutions.Count <= 12, $"{restitutions.Count} distinct restitution values");
        Assert.All(frictions.Keys, f => Assert.InRange(f, 0f, 2f));
        Assert.All(restitutions.Keys, r => Assert.InRange(r, 0f, 2f));

        // Whole kilograms still dominate by a wide margin, which is what an authored mass table
        // looks like: 5, 10, 1, 30, 20, 60, 50 are the commonest values in the game.
        Assert.True(massValues.ContainsKey(5f) && massValues.ContainsKey(10f));
    }
}
