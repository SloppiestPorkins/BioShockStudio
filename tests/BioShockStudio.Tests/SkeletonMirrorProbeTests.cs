using System.Numerics;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Havok.Detection;
using BioShockStudio.Core.Havok.Packfile;
using BioShockStudio.Core.Havok.Skeleton;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Reads the raw <c>hkQsTransform</c> bytes for the bones that break the rig's mirror symmetry, so
/// the question "does the file say this, or do we decode it wrongly?" is answered from the bytes
/// rather than from the decoder's own output.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class SkeletonMirrorProbeTests(GameFixture game)
{
    private static readonly string LogPath =
        Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") ?? Path.Combine(Path.GetTempPath(), "mirror.txt");

    private static void Log(string line) => File.AppendAllText(LogPath, line + Environment.NewLine);

    [RequiresGameFact]
    public void Print_RawReferencePoseForTheArmChain()
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is null) return;

        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper);

        byte[] payload = package.ReadExportData(export);
        var packfile = HavokPackfile.Parse(payload, HavokDetector.FindFirst(payload)!.Value.Offset);
        var skeletonObject = packfile.EnumerateObjects().Single(o => o.ClassName == HkaSkeletonReader.ClassName);
        var section = packfile.ResolvedSections[skeletonObject.SectionIndex];

        // The decoder's own view, for comparison.
        var skeleton = HkaSkeletonReader.Read(section, skeletonObject.Offset);

        Log("bone                    raw translation                 raw rotation                          raw scale");
        for (int i = 0; i < skeleton.BoneCount; i++)
        {
            string n = skeleton.Bones[i].Name;
            if (!n.Contains("UpperArm", StringComparison.OrdinalIgnoreCase)
                && !n.Contains("Clavicle", StringComparison.OrdinalIgnoreCase)
                && !n.Contains("Forearm", StringComparison.OrdinalIgnoreCase)) continue;

            var b = skeleton.Bones[i];
            Log($"[{i,2}] {n,-22} t=({b.LocalTranslation.X,9:0.###},{b.LocalTranslation.Y,9:0.###},{b.LocalTranslation.Z,9:0.###})  " +
                $"q=({b.LocalRotation.X,+8:0.####},{b.LocalRotation.Y,+8:0.####},{b.LocalRotation.Z,+8:0.####},{b.LocalRotation.W,+8:0.####})  " +
                $"s=({b.LocalScale.X:0.###},{b.LocalScale.Y:0.###},{b.LocalScale.Z:0.###})  parent={b.ParentIndex}");
        }

        // Does the *name array* line up with the *pose array*? If a bone's transform were read from
        // the wrong slot, the name would still look right while the numbers came from a neighbour.
        Log("");
        Log("parent chain sanity — each arm bone's parent, by name:");
        foreach (var b in skeleton.Bones)
        {
            if (!b.Name.Contains("UpperArm", StringComparison.OrdinalIgnoreCase)
                && !b.Name.Contains("Clavicle", StringComparison.OrdinalIgnoreCase)) continue;
            string parent = b.ParentIndex >= 0 ? skeleton.Bones[b.ParentIndex].Name : "(root)";
            Log($"    {b.Name,-22} parent {parent}");
        }

        // The mirror test, restated on the decoder's output so the log is self-contained.
        Log("");
        Log("Z=0 mirror check (t -> (x,y,-z), q -> (-x,-y,z,w)):");
        foreach (var left in skeleton.Bones.Where(b => b.Name.Contains("_L_", StringComparison.OrdinalIgnoreCase)))
        {
            var right = skeleton.FindBone(left.Name.Replace("_L_", "_R_", StringComparison.OrdinalIgnoreCase));
            if (right is null) continue;

            var expectedT = new Vector3(left.LocalTranslation.X, left.LocalTranslation.Y, -left.LocalTranslation.Z);
            float dt = Vector3.Distance(expectedT, right.LocalTranslation);
            if (dt > 0.5f)
                Log($"    BREAKS  {left.Name,-22} expected t=({expectedT.X:0.##},{expectedT.Y:0.##},{expectedT.Z:0.##}) " +
                    $"actual=({right.LocalTranslation.X:0.##},{right.LocalTranslation.Y:0.##},{right.LocalTranslation.Z:0.##}) err {dt:0.##}");
        }
    }
}
