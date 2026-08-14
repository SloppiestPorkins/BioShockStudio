using System.Numerics;
using System.Text;
using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Havok.Animation.SplineCompression;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Scratch probe: which bones on a CHARACTER does the identity fallback move, and is the result
/// more or less plausible? Writes to <c>BIOSHOCK_IMPACT</c>.
/// </summary>
[Collection(GameCollection.Name)]
public sealed class FallbackImpactProbeTests(GameFixture game)
{
    private AnimationPackage Load(string packagePath, string objectName)
    {
        using var package = BioShockPackage.Open(packagePath);
        var export = package.Exports
            .Where(e => e.ObjectName == objectName
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize);
        return AnimationPackage.Load(package, export!);
    }

    private static ReferenceTransform[] Legacy(AnimationPackage pack, BioShockAnimation animation)
    {
        var legacy = new ReferenceTransform[animation.TransformTrackCount];
        for (int t = 0; t < legacy.Length; t++)
        {
            int bone = animation.Binding.BoneForTrack(t);
            legacy[t] = bone >= 0 && bone < pack.Skeleton.BoneCount
                ? GameBasis.ToGameBasis(new ReferenceTransform(
                    pack.Skeleton.Bones[bone].LocalTranslation,
                    pack.Skeleton.Bones[bone].LocalRotation,
                    pack.Skeleton.Bones[bone].LocalScale))
                : ReferenceTransform.Identity;
        }
        return legacy;
    }

    [RequiresGameFact]
    public void Probe()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_IMPACT");
        if (string.IsNullOrWhiteSpace(target)) return;

        var sb = new StringBuilder();
        string maps = Core.Game.GameLocator.MapsDirectory(game.RequireRoot);

        sb.AppendLine("Which bones move, and what their bind translation looks like. A bone can only");
        sb.AppendLine("move if its track omits a component whose bind value is non-zero there — so the");
        sb.AppendLine("bind translation column is the whole explanation.");
        sb.AppendLine();

        void Study(string packagePath, string name)
        {
            AnimationPackage pack;
            try { pack = Load(packagePath, name); } catch { return; }

            var moved = new Dictionary<string, (float Worst, Vector3 Bind, int Count)>();
            var culprits = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (var animation in pack.Animations)
            {
                DecodedAnimation nu, old;
                try
                {
                    SplineDecompressor.LegacyReferencePose = [];
                    nu = pack.Decode(animation);
                    SplineDecompressor.LegacyReferencePose = Legacy(pack, animation);
                    old = pack.Decode(animation);
                }
                catch { continue; }
                finally { SplineDecompressor.LegacyReferencePose = []; }

                for (int i = 0; i < nu.Tracks.Count && i < old.Tracks.Count; i++)
                {
                    var a = nu.Tracks[i];
                    if (a.TargetBoneIndex < 0 || a.TargetBoneIndex >= pack.Skeleton.BoneCount) continue;
                    float d = (a.Translations[0] - old.Tracks[i].Translations[0]).Length();
                    if (d <= 0.01f) continue;

                    var bone = pack.Skeleton.Bones[a.TargetBoneIndex];
                    var prior = moved.GetValueOrDefault(bone.Name);
                    moved[bone.Name] = (MathF.Max(prior.Worst, d), bone.LocalTranslation, prior.Count + 1);
                    if (d > 5f) culprits.Add($"{animation.Owner}/{animation.Name}");
                }
            }

            sb.AppendLine($"=== {name}: {moved.Count} distinct bones move ===");
            foreach (var (bone, v) in moved.OrderByDescending(kv => kv.Value.Worst).Take(14))
                sb.AppendLine($"    {bone,-26} worst {v.Worst,8:0.00} cm in {v.Count,5} animations" +
                              $"   bind t=({v.Bind.X,8:0.##},{v.Bind.Y,8:0.##},{v.Bind.Z,8:0.##}) len {v.Bind.Length(),7:0.##}");
            sb.AppendLine($"    animations responsible for a move over 5 cm: {culprits.Count}");
            foreach (string c in culprits.Take(12)) sb.AppendLine($"        {c}");
            sb.AppendLine();
        }

        Study(Path.Combine(maps, "7-Gauntlet.bsm"), "UAPW_AggressorBabyJane");
        Study(Path.Combine(maps, "7-Gauntlet.bsm"), "UAPW_ProtectorRosie");
        Study(Path.Combine(maps, "7-Gauntlet.bsm"), "UAPW_GathererGirl");
        Study(game.LighthousePackage, "UAPW_NEWPlayerHands");

        File.WriteAllText(target, sb.ToString());
    }
}
