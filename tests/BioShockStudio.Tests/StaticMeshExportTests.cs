using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Export.Fbx;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers the boneless export path — a <c>StaticMesh</c> travelling to a scene and an FBX with no
/// skeleton at all.
/// </summary>
/// <remarks>
/// The thing worth asserting is the absence: no bones, no skin deformer, no animation stack. An
/// export that invented a root joint would look more like the skinned files and would be wrong.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class StaticMeshExportTests(GameFixture game)
{
    private AnimationScene DrillScene()
    {
        string file = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        using var package = BioShockPackage.Open(file);

        var export = package.Exports
            .Where(e => e.ObjectName == "ConeDrill" && package.GetClassName(e) == AssetClasses.StaticMesh)
            .MaxBy(e => e.SerialSize)!;

        var geometry = StaticMeshReader.ReadGeometry(package.ReadExportData(export))!;
        return AnimationSceneExporter.BuildStatic("1-Medical", export.ObjectName, geometry);
    }

    [RequiresGameFact]
    public void StaticScene_CarriesTheMeshAndNothingElse()
    {
        var scene = DrillScene();

        Assert.NotNull(scene.Mesh);
        Assert.Equal(561 * 3, scene.Mesh.Positions.Length);
        Assert.Equal(1686, scene.Mesh.Triangles.Length);
        Assert.Empty(scene.Bones);
        Assert.Empty(scene.Animations);
        Assert.Empty(scene.Sockets);
        Assert.Empty(scene.Failures);
    }

    [RequiresGameFact]
    public void StaticScene_HasNoSkinInfluences()
    {
        var scene = DrillScene();

        // Every vertex carries zero influences, so the flat influence lists are empty rather than
        // padded with a bone that does not exist.
        Assert.All(scene.Mesh!.InfluenceCounts, c => Assert.Equal(0, c));
        Assert.Empty(scene.Mesh.InfluenceBones);
        Assert.Empty(scene.Mesh.InfluenceWeights);
    }

    [RequiresGameFact]
    public void StaticFbx_WritesAMeshWithNoSkeletonOrDeformer()
    {
        using var stream = new MemoryStream();
        FbxWriter.Write(stream, FbxSceneBuilder.Build(DrillScene(), new FbxExportOptions()));
        var roots = FbxTestReader.Read(stream.ToArray());

        var objects = roots.First(r => r.Name == "Objects");

        var geometries = objects.FindAll("Geometry").ToList();
        Assert.Single(geometries);

        // A static prop has no joints and nothing to deform it.
        Assert.Empty(objects.FindAll("Model").Where(m => m.SubClass == "LimbNode"));
        Assert.Empty(objects.FindAll("Deformer"));
        Assert.Empty(objects.FindAll("AnimationStack"));

        // But it is still a real mesh: one model node holding the geometry.
        Assert.Single(objects.FindAll("Model").Where(m => m.SubClass == "Mesh"));
    }

    [RequiresGameFact]
    public void StaticFbx_RoundTripsVertexPositions()
    {
        var scene = DrillScene();

        using var stream = new MemoryStream();
        FbxWriter.Write(stream, FbxSceneBuilder.Build(scene, new FbxExportOptions()));
        var roots = FbxTestReader.Read(stream.ToArray());

        var geometry = roots.First(r => r.Name == "Objects").FindAll("Geometry").First();
        var vertices = geometry.Find("Vertices")!.Properties[0] as double[];

        Assert.NotNull(vertices);
        Assert.Equal(scene.Mesh!.Positions.Length, vertices.Length);

        // The writer scales into the export's units; what matters here is that nothing was dropped
        // or reordered on the way out.
        Assert.All(vertices, v => Assert.True(double.IsFinite(v)));
    }

    [RequiresGameFact]
    public void AStaticMeshExportsItsMaterialAndTextures()
    {
        string file = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        using var package = BioShockPackage.Open(file);

        var export = package.Exports
            .Where(e => e.ObjectName == "ConeDrill" && package.GetClassName(e) == AssetClasses.StaticMesh)
            .MaxBy(e => e.SerialSize)!;

        string directory = Path.Combine(Path.GetTempPath(), "bioshock-static-export-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);

        try
        {
            var geometry = StaticMeshReader.ReadGeometry(package.ReadExportData(export))!;
            var material = MaterialExporter.Resolve(package, export, directory);

            // Static meshes used to export with no material at all, because the reference was looked
            // for in the skeletal tag block rather than in the Materials property.
            Assert.NotNull(material);

            var scene = AnimationSceneExporter.BuildStatic("1-Medical", export.ObjectName, geometry, material);
            Assert.NotNull(scene.Material);

            FbxExporter.Write(scene, directory);

            Assert.True(File.Exists(Path.Combine(directory, "ConeDrill.fbx")));
            Assert.NotEmpty(Directory.GetFiles(directory, "*.png", SearchOption.AllDirectories));
        }
        finally
        {
            try { Directory.Delete(directory, recursive: true); } catch { /* best effort */ }
        }
    }

    [RequiresGameFact]
    public void ExportNamesDropTheAnimationPackagePrefix()
    {
        var scene = DrillScene();
        string directory = Path.Combine(Path.GetTempPath(), "bioshock-name-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);

        try
        {
            // A rig's scene is built from the wrapper export, whose name carries the game's internal
            // UAPW_ prefix. Files someone else opens should be named after the asset.
            var prefixed = scene with { SourceObject = "UAPW_ConeDrill" };
            var manifest = FbxExporter.Write(prefixed, directory);

            Assert.Equal("ConeDrill", manifest.Rigs[0].Name);
            Assert.Equal("UAPW_ConeDrill", manifest.Rigs[0].SourceObject);
            Assert.Equal("ConeDrill.fbx", manifest.Rigs[0].Mesh);
            Assert.True(File.Exists(Path.Combine(directory, "ConeDrill.fbx")));
        }
        finally
        {
            try { Directory.Delete(directory, recursive: true); } catch { /* best effort */ }
        }
    }
}
