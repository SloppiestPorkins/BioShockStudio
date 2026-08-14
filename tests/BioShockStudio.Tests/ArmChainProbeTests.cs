using System.Numerics;
using System.Text;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Skeleton;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Scratch probe for the first-person arm chain. Writes to <c>BIOSHOCK_ARMPROBE</c> and does
/// nothing otherwise.
/// </summary>
[Collection(GameCollection.Name)]
public sealed class ArmChainProbeTests(GameFixture game)
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

    private static int Index(BioShockSkeleton s, string name)
    {
        for (int i = 0; i < s.Bones.Count; i++)
            if (string.Equals(s.Bones[i].Name, name, StringComparison.OrdinalIgnoreCase)) return i;
        return -1;
    }

    private static (Vector3 X, Vector3 Y, Vector3 Z) Axes(Matrix4x4 m) => (
        Vector3.Normalize(new Vector3(m.M11, m.M12, m.M13)),
        Vector3.Normalize(new Vector3(m.M21, m.M22, m.M23)),
        Vector3.Normalize(new Vector3(m.M31, m.M32, m.M33)));

    [RequiresGameFact]
    public void Probe()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_ARMPROBE");
        if (string.IsNullOrWhiteSpace(target)) return;

        var sb = new StringBuilder();
        sb.AppendLine("Are the two arm chains a MIRROR of each other, or a translated DUPLICATE?");
        sb.AppendLine("For each pair, the global rotation of the right bone is compared against");
        sb.AppendLine("  duplicate : the left bone's own global rotation, unchanged");
        sb.AppendLine("  mirror    : the left bone's global rotation reflected in the lateral plane");
        sb.AppendLine("Whichever is near zero is how the rig is built. A real Biped is a mirror.");
        sb.AppendLine();

        void Study(string package, string name)
        {
            var pack = Load(package, name);
            var s = pack.Skeleton;
            int head = Index(s, "Bip01_Head");
            if (head < 0) { sb.AppendLine($"=== {name}: no head ==="); return; }

            var g = s.ComputeGlobalTransforms();
            var (_, _, lateral) = Axes(g[head]);

            sb.AppendLine($"=== {name} ===  lateral axis ({lateral.X:0.00},{lateral.Y:0.00},{lateral.Z:0.00})");

            foreach (string part in new[] { "Clavicle", "UpperArm", "Forearm", "Hand" })
            {
                int l = Index(s, "Bip01_L_" + part), r = Index(s, "Bip01_R_" + part);
                if (l < 0 || r < 0) continue;

                var (lx, ly, lz) = Axes(g[l]);
                var (rx, ry, rz) = Axes(g[r]);

                // Reflection in the plane whose normal is the lateral axis: v -> v - 2(v.n)n.
                Vector3 Reflect(Vector3 v) => v - 2f * Vector3.Dot(v, lateral) * lateral;

                float duplicate = (lx - rx).Length() + (ly - ry).Length() + (lz - rz).Length();
                float mirror = (Reflect(lx) - rx).Length() + (Reflect(ly) - ry).Length() + (Reflect(lz) - rz).Length();

                // And how far apart are they along each axis?
                var delta = g[l].Translation - g[r].Translation;
                float along = Vector3.Dot(delta, lateral);

                sb.AppendLine($"  {part,-9} duplicate {duplicate,7:0.###}   mirror {mirror,7:0.###}" +
                              $"    L-R lateral {along,8:0.00}   |L-R| {delta.Length(),8:0.00}");
            }
            sb.AppendLine();
        }

        void StudyAnimated(string package, string name, string[] animations)
        {
            var pack = Load(package, name);
            var s = pack.Skeleton;
            int head = Index(s, "Bip01_Head");
            if (head < 0) return;

            foreach (string animationName in animations)
            {
                var found = pack.Find(animationName);
                if (found is null) continue;
                var decoded = pack.Decode(found);

                var byBone = new Core.Animation.DecodedTrack?[s.BoneCount];
                foreach (var t in decoded.Tracks)
                    if (t.TargetBoneIndex >= 0) byBone[t.TargetBoneIndex] = t;

                var g = new Matrix4x4[s.BoneCount];
                for (int i = 0; i < s.BoneCount; i++)
                {
                    var bone = s.Bones[i];
                    var t = byBone[i];
                    var local = Matrix4x4.CreateScale(t is not null && t.Scales.Length > 0 ? t.Scales[0] : bone.LocalScale)
                                * Matrix4x4.CreateFromQuaternion(t is not null && t.Rotations.Length > 0 ? t.Rotations[0] : bone.LocalRotation)
                                * Matrix4x4.CreateTranslation(t is not null && t.Translations.Length > 0 ? t.Translations[0] : bone.LocalTranslation);
                    g[i] = bone.ParentIndex >= 0 && bone.ParentIndex < i ? local * g[bone.ParentIndex] : local;
                }

                var (_, _, lateral) = Axes(g[head]);
                sb.AppendLine($"=== {name} / {animationName} frame 0 ===");
                foreach (string part in new[] { "Clavicle", "UpperArm", "Forearm", "Hand" })
                {
                    int l = Index(s, "Bip01_L_" + part), r = Index(s, "Bip01_R_" + part);
                    if (l < 0 || r < 0) continue;
                    var (lx, ly, lz) = Axes(g[l]);
                    var (rx, ry, rz) = Axes(g[r]);
                    Vector3 Reflect(Vector3 v) => v - 2f * Vector3.Dot(v, lateral) * lateral;
                    float duplicate = (lx - rx).Length() + (ly - ry).Length() + (lz - rz).Length();
                    float mirror = (Reflect(lx) - rx).Length() + (Reflect(ly) - ry).Length() + (Reflect(lz) - rz).Length();
                    var delta = g[l].Translation - g[r].Translation;
                    sb.AppendLine($"  {part,-9} duplicate {duplicate,7:0.###}   mirror {mirror,7:0.###}" +
                                  $"    L-R lateral {Vector3.Dot(delta, lateral),8:0.00}   |L-R| {delta.Length(),8:0.00}");
                }
                sb.AppendLine();
            }
        }

        Study(game.LighthousePackage, "UAPW_NEWPlayerHands");
        StudyAnimated(game.LighthousePackage, "UAPW_NEWPlayerHands", ["FidgetCrossbow", "FidgetPistol"]);
        StudyAnimated(Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "7-Gauntlet.bsm"),
            "UAPW_AggressorBabyJane", ["Fidget_Burning"]);
        string gauntlet = Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "7-BossFight.bsm");
        Study(Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "7-Gauntlet.bsm"), "UAPW_AggressorBabyJane");
        Study(Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "7-Gauntlet.bsm"), "UAPW_GathererGirl");
        _ = gauntlet;

        File.WriteAllText(target, sb.ToString());
    }
}
