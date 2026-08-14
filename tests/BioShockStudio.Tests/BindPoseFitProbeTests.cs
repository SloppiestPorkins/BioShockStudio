using System.Text;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Havok.Detection;
using BioShockStudio.Core.Havok.Packfile;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Scratch: which Havok classes does each rig's packfile carry? A class the first-person package has
/// and the characters do not — or the reverse — would be a decode-level explanation, which is the
/// only shape a real fix can take. Writes to <c>BIOSHOCK_FITPROBE</c>.
/// </summary>
[Collection(GameCollection.Name)]
public sealed class BindPoseFitProbeTests(GameFixture game)
{
    [RequiresGameFact]
    public void Probe()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_FITPROBE");
        if (string.IsNullOrWhiteSpace(target)) return;

        var sb = new StringBuilder();
        var sets = new Dictionary<string, HashSet<string>>();

        void Classes(string packagePath, string objectName)
        {
            using var package = BioShockPackage.Open(packagePath);
            var export = package.Exports
                .Where(e => e.ObjectName == objectName
                            && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
                .MaxBy(e => e.SerialSize);
            if (export is null) return;

            byte[] payload = package.ReadExportData(export);
            var packfile = HavokPackfile.Parse(payload, HavokDetector.FindFirst(payload)!.Value.Offset);

            var names = new HashSet<string>(StringComparer.Ordinal);
            foreach (var o in packfile.EnumerateObjects()) names.Add(o.ClassName);
            sets[objectName] = names;

            sb.AppendLine($"=== {objectName}: {names.Count} distinct classes, {packfile.ResolvedSections.Count} sections ===");
            foreach (string n in names.OrderBy(x => x)) sb.AppendLine("    " + n);
            sb.AppendLine();
        }

        string maps = Core.Game.GameLocator.MapsDirectory(game.RequireRoot);
        Classes(game.LighthousePackage, "UAPW_NEWPlayerHands");
        Classes(Path.Combine(maps, "7-Gauntlet.bsm"), "UAPW_AggressorBabyJane");
        Classes(Path.Combine(maps, "7-Gauntlet.bsm"), "UAPW_GathererGirl");

        if (sets.Count > 1 && sets.TryGetValue("UAPW_NEWPlayerHands", out var hands))
        {
            foreach (var (name, set) in sets.Where(kv => kv.Key != "UAPW_NEWPlayerHands"))
            {
                sb.AppendLine($"in {name} but NOT in the hands: {string.Join(", ", set.Except(hands).OrderBy(x => x))}");
                sb.AppendLine($"in the hands but NOT in {name}: {string.Join(", ", hands.Except(set).OrderBy(x => x))}");
                sb.AppendLine();
            }
        }

        File.WriteAllText(target, sb.ToString());
    }
}
