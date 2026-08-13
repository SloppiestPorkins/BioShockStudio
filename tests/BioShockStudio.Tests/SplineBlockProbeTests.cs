using System.Numerics;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Scratch probe: what the shipped data says about a field before code is written for it.</summary>
[Collection(GameCollection.Name)]
public sealed class SplineBlockProbeTests(GameFixture game)
{
    private static readonly string LogPath =
        Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") ?? Path.Combine(Path.GetTempPath(), "probe.txt");

    private static void Log(string line) => File.AppendAllText(LogPath, line + Environment.NewLine);

    /// <summary>
    /// Does Havok's per-bone translation lock ever contradict the animation?
    /// <para>
    /// <c>LockTranslation</c> is decoded and stored and nothing reads it. Before writing code that
    /// honours it, this measures whether honouring it would change any pose: a locked bone whose
    /// animation drives a translation different from its reference pose is the only case where it
    /// could matter.
    /// </para>
    /// </summary>
    [RequiresGameFact]
    public void Print_TranslationLockEvidence()
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is null) return;

        int packages = 0, wrappers = 0, bones = 0, locked = 0;
        int lockedDriven = 0, unlockedDriven = 0, animations = 0;
        float worstLockedDelta = 0f;
        string worstWhere = "";

        foreach (string path in GameLocator.EnumeratePackages(game.RequireRoot)
                     .Concat(GameLocator.EnumerateScriptPackages(game.RequireRoot)))
        {
            packages++;
            using var package = BioShockPackage.Open(path);
            foreach (var export in package.Exports.Where(e =>
                         package.GetClassName(e) == AssetClasses.AnimationPackageWrapper))
            {
                AnimationPackage animationPackage;
                try { animationPackage = AnimationPackage.Load(package, export); }
                catch { continue; }

                wrappers++;
                bones += animationPackage.Skeleton.BoneCount;
                locked += animationPackage.Skeleton.Bones.Count(b => b.LockTranslation);

                foreach (var animation in animationPackage.Animations)
                {
                    Core.Animation.DecodedAnimation decoded;
                    try { decoded = animationPackage.Decode(animation); }
                    catch { continue; }

                    animations++;
                    foreach (var track in decoded.Tracks)
                    {
                        int index = track.TargetBoneIndex;
                        if (index < 0 || index >= animationPackage.Skeleton.BoneCount) continue;

                        var bone = animationPackage.Skeleton.Bones[index];
                        float delta = 0f;
                        foreach (var t in track.Translations)
                            delta = MathF.Max(delta, Vector3.Distance(t, bone.LocalTranslation));

                        if (delta <= 0.01f) continue;

                        if (bone.LockTranslation)
                        {
                            lockedDriven++;
                            if (delta > worstLockedDelta)
                            {
                                worstLockedDelta = delta;
                                worstWhere = $"{animationPackage.ObjectName}/{animation.Name} bone {bone.Name}";
                            }
                        }
                        else unlockedDriven++;
                    }
                }
            }
        }

        Log($"packages={packages} wrappers={wrappers} animations={animations}");
        Log($"bones={bones}, of which LockTranslation is set on {locked} ({100.0 * locked / Math.Max(1, bones):0.0}%)");
        Log($"tracks whose translation differs from the reference pose:");
        Log($"    on a LOCKED bone   {lockedDriven}");
        Log($"    on an unlocked bone {unlockedDriven}");
        Log($"worst locked-bone delta {worstLockedDelta:0.###} cm  ({worstWhere})");
    }
}
