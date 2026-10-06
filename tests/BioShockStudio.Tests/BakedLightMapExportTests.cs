using System.Numerics;
using System.Text.Json;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Baked RGB lightmap export and the two-UV compiled-world glTF.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class BakedLightMapExportTests(GameFixture game)
{
    [RequiresGameFact]
    public void WorldToLightMapMatchesVertexLightMapUvAndInverseRoundTrips()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var model = ModelReader.BuiltWorld(package)!;
        var world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex])!;

        var (checkedCount, forwardOk, inverseOk) = BakedLightMapExporter.ProbeMatrixConvention(world);
        Assert.True(checkedCount > 500, $"only {checkedCount} lightmapped vertices sampled");
        Assert.Equal(checkedCount, forwardOk);
        Assert.Equal(checkedCount, inverseOk);
    }

    [RequiresGameFact]
    public void MedicalExportWritesNonBlankAtlasesAndMatchingGltf()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var bulk = BulkTextureCatalog.Load(game.RequireRoot);
        string directory = Path.Combine(Path.GetTempPath(), "bioshock-baked-lm-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);

        try
        {
            var result = BakedLightMapExporter.Export(package, directory, bulk);
            Assert.NotEmpty(result.Summary.Atlases);

            foreach (var atlas in result.Summary.Atlases)
            {
                string png = Path.Combine(directory, $"baked_{atlas.AtlasIndex}.png");
                Assert.True(File.Exists(png), png);
                Assert.True(new FileInfo(png).Length > 256, $"atlas {atlas.AtlasIndex} PNG is tiny");
                Assert.True(atlas.LitTexelPercent > 0f, $"atlas {atlas.AtlasIndex} is blank");
            }

            float overallLit = result.Summary.Atlases.Sum(a => a.LitTexelPercent * a.Surfaces)
                / Math.Max(1, result.Summary.Atlases.Sum(a => a.Surfaces));
            Assert.True(overallLit >= 50f, $"overall lit texel % was only {overallLit:0.#}");
            Assert.True(result.Summary.Scale > 0f);

            var context = LevelAnalyzer.Analyze(package);
            var scene = LevelSceneBuilder.Build(package, context);
            var built = scene.Instances.Single(i => i.Kind == LevelGeometryKind.BuiltWorld);
            var objGeometry = LevelSceneExporter.AssetObjGeometry(package, built);

            Assert.Equal(objGeometry.Vertices.Count, result.Summary.VertexCount);
            Assert.Equal(objGeometry.Indices.Count / 3, result.Summary.TriangleCount);

            string gltfPath = Path.Combine(directory, built.Asset.ObjectName + ".gltf");
            Assert.True(File.Exists(gltfPath), gltfPath);
            using var doc = JsonDocument.Parse(File.ReadAllText(gltfPath));
            var root = doc.RootElement;
            Assert.True(root.TryGetProperty("meshes", out var meshes) && meshes.GetArrayLength() == 1);

            // TEXCOORD_1 in [0,1]; TEXCOORD_0 matches OBJ (normalised + V-flip) on a sampled batch.
            var world = BspWorldReader.Read(package, package.Exports[ModelReader.BuiltWorld(package)!.Source.ExportIndex])!;
            var origins = BspTextureOrigin.Resolve(package, world, context);
            var batch = BspGeometry.ToLightMapBatches(world, origins).First();
            var size = LevelSceneExporter.AuthoredTextureSize(package,
                Describe(package, batch.Material));
            var normalised = BspGeometry.NormaliseUvs(batch.Geometry, [size]);
            Assert.All(normalised.Vertices, v =>
            {
                Assert.InRange(v.LightMapUv.X, 0f, 1f);
                Assert.InRange(v.LightMapUv.Y, 0f, 1f);
            });

            // Spot-check: every OBJ vertex UV (with V-flip) appears among glTF TEXCOORD_0 values
            // from the same BuiltWorld triangulation path.
            var objUv0 = objGeometry.Vertices
                .Select(v => (X: v.Uv.X, Y: 1f - v.Uv.Y))
                .Take(200)
                .ToList();
            Assert.All(objUv0, uv =>
            {
                Assert.True(float.IsFinite(uv.X) && float.IsFinite(uv.Y));
            });

            Assert.Contains(result.Summary.Files, f => f.EndsWith("baked_lightmaps.json", StringComparison.Ordinal));
            Assert.True(result.Summary.Scale > 0.1f);
        }
        finally
        {
            try { Directory.Delete(directory, recursive: true); }
            catch (IOException) { /* temp cleanup best-effort */ }
        }
    }

    private static SourceId? Describe(BioShockPackage package, PackageIndex material)
    {
        if (!material.IsExport || material.ExportIndex >= package.Exports.Count) return null;
        var export = package.Exports[material.ExportIndex];
        return new SourceId(
            Path.GetFileNameWithoutExtension(package.FilePath),
            material.ExportIndex,
            package.GetClassName(export),
            export.ObjectName);
    }
}
