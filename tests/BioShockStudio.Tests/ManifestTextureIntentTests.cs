using System.Text.Json;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The UE5 manifest carries each texture's intent.
/// </summary>
/// <remarks>
/// <para>
/// <b>Written because a real UE5 import proved the gap that unit tests could not.</b> The texture
/// intent was already exported in the scene JSON, and tested there. But `ue5_manifest.json` is a
/// separate document, and it is the one `tools/ue5/import_bioshock.py` reads - so the importer had
/// no way to know a normal map is not colour. Both documents were individually correct; the gap was
/// only visible by running the pipeline end to end.
/// </para>
/// <para>
/// Verified in UE5.7 on 23 Aug 2026: `Hand_NORM` and `Pistol_NORM` import with `sRGB=false` and
/// `TC_NORMALMAP`, the diffuse and specular maps with `sRGB=true` and `TC_DEFAULT`.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class ManifestTextureIntentTests(GameFixture game)
{
    [RequiresGameFact]
    public void TheManifestStatesColourSpaceAndUsagePerBinding()
    {
        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-manifest-{Guid.NewGuid():N}");

        try
        {
            using var package = BioShockPackage.Open(game.LighthousePackage);

            var wrapper = package.Exports.First(e => e.ObjectName == "UAPW_NEWPlayerHands"
                && package.GetClassName(e) == Core.Assets.AssetClasses.AnimationPackageWrapper);
            var meshExport = package.Exports
                .Where(e => e.ObjectName == "NEWPlayerHands"
                            && package.GetClassName(e) == Core.Assets.AssetClasses.SkeletalMesh)
                .MaxBy(e => e.SerialSize)!;

            byte[] payload = package.ReadExportData(meshExport);
            var animations = Core.Assets.AnimationPackage.Load(package, wrapper);

            // The material is what carries the texture intent, so the scene has to be built the way
            // the CLI builds it - with the material resolved - not the bare geometry-only way.
            var material = MaterialExporter.Resolve(package, meshExport, directory);

            var scene = AnimationSceneExporter.Build(
                animations,
                "Pistol",
                Core.Mesh.SkeletalMeshReader.ReadSockets(payload, package.Names),
                Core.Mesh.SkeletalMeshReader.ReadGeometry(payload),
                new Dictionary<string, IReadOnlyList<Core.Assets.AnimationEvent>>(StringComparer.Ordinal),
                material);

            var manifest = FbxExporter.Write(scene, directory);

            var rig = manifest.Rigs[0];
            Assert.NotEmpty(rig.Textures);

            // A normal map must not arrive as colour - the whole point of carrying intent.
            var normal = rig.Textures.First(t => t.Usage == "NormalMap");
            Assert.Equal("Linear", normal.ColourSpace);

            // ...and a base colour must.
            var baseColour = rig.Textures.First(t => t.Usage == "BaseColor");
            Assert.Equal("Srgb", baseColour.ColourSpace);

            // Every entry is complete enough for an importer to act on without guessing.
            foreach (var texture in rig.Textures)
            {
                Assert.False(string.IsNullOrEmpty(texture.File));
                Assert.False(string.IsNullOrEmpty(texture.Slot));
                Assert.False(string.IsNullOrEmpty(texture.Material));
                Assert.Contains(texture.ColourSpace, new[] { "Srgb", "Linear" });
                Assert.Contains(texture.AddressU, new[] { "Wrap", "Clamp" });
                Assert.Contains(texture.AddressV, new[] { "Wrap", "Clamp" });
            }

            // It survives serialisation, since the importer reads the file and not the record.
            string json = File.ReadAllText(Path.Combine(directory, FbxExporter.ManifestFileName));
            using var document = JsonDocument.Parse(json);
            var textures = document.RootElement.GetProperty("rigs")[0].GetProperty("textures");
            Assert.True(textures.GetArrayLength() > 0);
            Assert.Contains("Linear", json, StringComparison.Ordinal);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }
}
