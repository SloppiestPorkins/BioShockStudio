using System.Text.Json;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Export;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers <see cref="NamedAssetExporter"/> — the stand-in mesh path that searches every shipped
/// package by object name (maps + script packages).
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class NamedAssetExportTests(GameFixture game)
{
    [RequiresGameFact]
    public void Export_WritesStaticObjAndSkeletalRigFromIndex()
    {
        string dir = Path.Combine(Path.GetTempPath(), "bioshock-named-assets-" + Guid.NewGuid().ToString("N"));
        try
        {
            var result = NamedAssetExporter.Export(
                game.RequireRoot, dir, ["Cam_Beam", "SecBot_MG", "NullSkeletalMesh"]);

            Assert.Equal("exported", result.Reports.Single(r => r.Name == "Cam_Beam").Status);
            Assert.Equal("exported", result.Reports.Single(r => r.Name == "SecBot_MG").Status);
            Assert.Equal("skipped", result.Reports.Single(r => r.Name == "NullSkeletalMesh").Status);

            var cam = result.Document.Assets.Single(a => a.Name == "Cam_Beam");
            Assert.Equal(AssetClasses.StaticMesh, cam.Kind);
            Assert.False(string.IsNullOrEmpty(cam.File));
            string objPath = Path.Combine(dir, cam.File!.Replace('/', Path.DirectorySeparatorChar));
            Assert.True(File.Exists(objPath));
            // Same header / coordinate convention as LevelSceneExporter.WriteLocalAssetObj.
            string objText = File.ReadAllText(objPath);
            Assert.Contains("BioShockStudio asset mesh:", objText, StringComparison.Ordinal);
            Assert.Contains("+X forward", objText, StringComparison.Ordinal);
            if (cam.Sections.Count > 1)
                Assert.True(File.Exists(Path.ChangeExtension(objPath, ".mtl")));

            var bot = result.Document.Assets.Single(a => a.Name == "SecBot_MG");
            Assert.Equal(AssetClasses.SkeletalMesh, bot.Kind);
            Assert.Equal("Rigs/SecBot_MG", bot.File);
            Assert.True(Directory.Exists(Path.Combine(dir, "Rigs", "SecBot_MG")));
            Assert.True(File.Exists(Path.Combine(dir, "Rigs", "SecBot_MG", FbxExporter.ManifestFileName)));

            Assert.True(File.Exists(result.ManifestPath));
            using var doc = JsonDocument.Parse(File.ReadAllText(result.ManifestPath));
            Assert.True(doc.RootElement.TryGetProperty("assets", out _));
            Assert.True(doc.RootElement.TryGetProperty("materials", out _));
            Assert.True(doc.RootElement.TryGetProperty("textures", out _));
        }
        finally
        {
            if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        }
    }

    [RequiresGameFact]
    public void PickCanonical_PrefersScriptPackageOnSizeTie()
    {
        var map = new AssetRecord
        {
            PackageFile = @"G:\maps\1-Medical.bsm",
            PackageName = "1-Medical",
            ExportIndex = 1,
            ObjectName = "Cam_Beam",
            ClassName = AssetClasses.StaticMesh,
            SerialSize = 100,
            SerialOffset = 0,
        };
        var script = new AssetRecord
        {
            PackageFile = @"G:\scripts\ShockGame.U",
            PackageName = "ShockGame",
            ExportIndex = 2,
            ObjectName = "Cam_Beam",
            ClassName = AssetClasses.StaticMesh,
            SerialSize = 100,
            SerialOffset = 0,
        };

        Assert.Same(script, NamedAssetExporter.PickCanonical([map, script]));
    }
}
