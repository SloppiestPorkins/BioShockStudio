using BioShockStudio.Core.Export;
using BioShockStudio.Core.Export.Fbx;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// A multi-material mesh must reach FBX as several materials with a per-polygon assignment.
/// </summary>
/// <remarks>
/// The exporter used to declare one material and <c>AllSame</c> mapping, so the Bathysphere's window
/// and lamps arrived painted in hull metal. Nothing about that is visible in a count — the mesh is
/// whole and every polygon has a material — so this reads the written bytes back and checks which
/// material each polygon actually names.
/// <para>
/// The written file has also been round-tripped through Blender's own FBX importer:
/// <c>CityGate</c> imports as three slots in scene order with 0 of 2,400 faces in the wrong one.
/// That cannot run in this suite, which must not require Blender, so it is recorded here and in
/// <c>docs/research/fbx.md</c>.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
public sealed class FbxMaterialTests(GameFixture game)
{
    private AnimationScene BuildScene(string map, string mesh, string outputDirectory)
    {
        using var package = BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), map + ".bsm"));

        var export = package.Exports
            .Where(e => package.GetClassName(e) == "StaticMesh"
                        && string.Equals(e.ObjectName, mesh, StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);
        Assert.True(export is not null, $"{mesh} is not in {map}");

        var geometry = StaticMeshReader.ReadGeometry(package.ReadExportData(export!));
        Assert.True(geometry is not null, $"{mesh} produced no geometry");

        var (materials, triangleMaterials) =
            MaterialExporter.ResolveSurfaces(package, export!, geometry!, outputDirectory);

        return AnimationSceneExporter.BuildStatic(map, mesh, geometry!, null, materials, triangleMaterials);
    }

    /// <summary>
    /// <c>CityGate</c> — granite, lamp columns and the gate itself — writes three materials and
    /// names the right one per polygon.
    /// </summary>
    [RequiresGameFact]
    public void AMultiMaterialMeshWritesAMaterialPerPolygon()
    {
        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-fbx-mat-{Guid.NewGuid():N}");
        Directory.CreateDirectory(directory);

        try
        {
            var scene = BuildScene("0-Lighthouse", "CityGate", directory);

            Assert.Equal(3, scene.Materials.Count);
            Assert.Equal(["Granite_L", "Gate_Light", "C_Gate"], scene.Materials.Select(m => m.Name));

            int faces = scene.Mesh!.Triangles.Length / 3;
            Assert.Equal(faces, scene.Mesh.TriangleMaterials.Length);

            using var stream = new MemoryStream();
            FbxWriter.Write(stream, FbxSceneBuilder.Build(scene, new FbxExportOptions()));
            var roots = FbxTestReader.Read(stream.ToArray());

            var objects = roots.First(r => r.Name == "Objects");

            // Every material reaches the file, under its own name.
            var written = objects.FindAll("Material").Select(m => m.ObjectName).ToList();
            foreach (var material in scene.Materials) Assert.Contains(material.Name, written);

            var geometry = objects.FindAll("Geometry").First(g => g.Find("Vertices") is not null);
            var layer = geometry.Find("LayerElementMaterial");
            Assert.True(layer is not null, "the geometry declares no material layer");

            // "AllSame" is what painted the whole mesh in one material.
            Assert.Equal("ByPolygon", (string)layer!.Find("MappingInformationType")!.Properties[0]);

            var indices = (int[])layer.Find("Materials")!.Properties[0];
            Assert.Equal(faces, indices.Length);

            // The assignment must be the scene's, polygon for polygon.
            for (int i = 0; i < faces; i++)
            {
                int expected = Math.Max(0, scene.Mesh.TriangleMaterials[i]);
                Assert.True(indices[i] == expected,
                    $"polygon {i} names material {indices[i]}, expected {expected}");
            }

            // Non-vacuous: all three slots are actually used, so a file that quietly collapsed to
            // one cannot pass.
            Assert.Equal(3, indices.Distinct().Count());
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    /// <summary>
    /// A mesh with one material keeps the cheaper <c>AllSame</c> mapping rather than writing an
    /// index per polygon that says the same thing.
    /// </summary>
    [RequiresGameFact]
    public void ASingleMaterialMeshStillWritesAllSame()
    {
        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-fbx-mat-{Guid.NewGuid():N}");
        Directory.CreateDirectory(directory);

        try
        {
            var scene = BuildScene("1-Medical", "ConeDrill", directory);
            Assert.Single(scene.Materials);

            using var stream = new MemoryStream();
            FbxWriter.Write(stream, FbxSceneBuilder.Build(scene, new FbxExportOptions()));
            var roots = FbxTestReader.Read(stream.ToArray());

            var geometry = roots.First(r => r.Name == "Objects")
                .FindAll("Geometry").First(g => g.Find("Vertices") is not null);

            var layer = geometry.Find("LayerElementMaterial")!;
            Assert.Equal("AllSame", (string)layer.Find("MappingInformationType")!.Properties[0]);
            Assert.Equal([0], (int[])layer.Find("Materials")!.Properties[0]);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }
}
