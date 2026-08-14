using System.Numerics;
using System.Text;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Skeleton;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Scratch probe: across every skeleton the game ships, is each arm pair a mirror or a translated
/// duplicate? Writes to <c>BIOSHOCK_ARMPROBE</c> and does nothing otherwise.
/// </summary>
[Collection(GameCollection.Name)]
public sealed class ArmChainProbeTests(GameFixture game)
{
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
        sb.AppendLine("Every skeleton with both clavicles and both upper arms. For the UpperArm pair:");
        sb.AppendLine("  mirror    = right bone's global rotation against the left's, reflected in the");
        sb.AppendLine("              plane whose normal is the clavicle axis. ~2.0 on a Biped.");
        sb.AppendLine("  duplicate = right against the left unchanged. ~0 means the arm was copied,");
        sb.AppendLine("              not mirrored, and the two chains have no left/right distinction.");
        sb.AppendLine();

        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var duplicates = new List<string>();
        int mirrors = 0, total = 0;

        foreach (string map in Directory.GetFiles(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(p => p))
        {
            using var package = BioShockPackage.Open(map);
            foreach (var export in package.Exports
                         .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper))
            {
                if (!seen.Add(export.ObjectName)) continue;

                AnimationPackage pack;
                try { pack = AnimationPackage.Load(package, export); } catch { continue; }
                var s = pack.Skeleton;

                int lc = Index(s, "Bip01_L_Clavicle"), rc = Index(s, "Bip01_R_Clavicle");
                int lu = Index(s, "Bip01_L_UpperArm"), ru = Index(s, "Bip01_R_UpperArm");
                if (lc < 0 || rc < 0 || lu < 0 || ru < 0) continue;

                var g = s.ComputeGlobalTransforms();

                // The clavicle axis, which is the head's lateral axis at dot 1.00 on every rig that
                // has both, and is available on far more of them.
                var separation = g[lc].Translation - g[rc].Translation;
                if (separation.Length() < 1f) continue;
                var lateral = Vector3.Normalize(separation);
                var (lx, ly, lz) = Axes(g[lu]);
                var (rx, ry, rz) = Axes(g[ru]);
                Vector3 Reflect(Vector3 v) => v - 2f * Vector3.Dot(v, lateral) * lateral;

                float duplicate = (lx - rx).Length() + (ly - ry).Length() + (lz - rz).Length();
                float mirror = (Reflect(lx) - rx).Length() + (Reflect(ly) - ry).Length() + (Reflect(lz) - rz).Length();
                float lateralGap = Vector3.Dot(g[lu].Translation - g[ru].Translation, lateral);

                total++;
                if (duplicate < mirror) duplicates.Add(
                    $"    {export.ObjectName,-36} duplicate {duplicate,6:0.###}  mirror {mirror,6:0.###}" +
                    $"  lateral gap {lateralGap,8:0.00}   [{Path.GetFileNameWithoutExtension(map)}]");
                else mirrors++;
            }
        }

        sb.AppendLine($"  skeletons with clavicles and upper arms   : {total}");
        sb.AppendLine($"  arm pair is a MIRROR                      : {mirrors}");
        sb.AppendLine($"  arm pair is a DUPLICATE                   : {duplicates.Count}");
        sb.AppendLine();
        foreach (string line in duplicates) sb.AppendLine(line);

        File.WriteAllText(target, sb.ToString());
    }
}
