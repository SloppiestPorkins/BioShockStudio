using System.Text.RegularExpressions;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Export.Fbx;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using System.Text.Json;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers the material link: how a mesh names its shader, and what that shader binds.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed partial class MaterialTests(GameFixture game)
{
    /// <summary>A name the property walk invented, rather than one the name table really holds.</summary>
    [GeneratedRegex(@"\d{4,}$")]
    private static partial Regex InventedName();

    private static ObjectExport Mesh(BioShockPackage package, string name) => package.Exports
        .Where(e => e.ObjectName == name && package.GetClassName(e) == AssetClasses.SkeletalMesh)
        .MaxBy(e => e.SerialSize)!;

    [RequiresGameFact]
    public void Hands_ResolveToTheirOwnShaderAndItsThreeTextures()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var material = MaterialReader.ReadForMesh(package, Mesh(package, "NEWPlayerHands"));

        Assert.NotNull(material);
        Assert.Equal("NEWplayerHandsRimShader", material.Name);

        // The hands use a FacingShader, which has no plain Diffuse — its base colour is in the
        // facing and edge slots. A reader that only knew the Shader slots reports no diffuse here.
        Assert.Equal("FacingShader", material.ClassName);
        Assert.Equal("Hand_DIFF", material.DiffuseTexture);
        Assert.Equal("Hand_NORM", material.NormalTexture);
        Assert.Equal("Hand_SPEC", material.SpecularTexture);

        // These are exactly the three textures the asset context lists for the hands group.
        Assert.Equal(
            ["Hand_DIFF", "Hand_NORM", "Hand_SPEC"],
            material.Textures.Select(t => t.TextureName).Distinct().Order());
    }

    [RequiresGameFact]
    public void Pistol_ResolvesToItsShaderThroughTheReferenceInTheMeshPayload()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        var material = MaterialReader.ReadForMesh(package, Mesh(package, "WP_PistolMesh"));

        Assert.NotNull(material);
        Assert.Equal("PistolShader", material.Name);
        Assert.Equal("Pistol_DIFF", material.DiffuseTexture);
        Assert.Equal("Pistol_NORM", material.NormalTexture);
        Assert.Equal("WP_Pistol_Spec", material.SpecularTexture);
        Assert.False(material.Truncated);
    }

    [RequiresGameFact]
    public void Mesh_MaterialListIsAnArrayNotASingleReference()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);

        // The byte after the tag block was recorded as a fixed 1. It is an FCompactIndex count, and
        // meshes with two materials read 2 — reading it as part of the tag meant their second
        // material was never seen, and the mesh looked as though it had none.
        byte[] tommy = package.ReadExportData(Mesh(package, "TommyGunMESH"));
        var references = MaterialReader.ReadMeshMaterialReferences(tommy, package);
        Assert.Equal(2, references.Count);

        byte[] pistol = package.ReadExportData(Mesh(package, "WP_PistolMesh"));
        Assert.Single(MaterialReader.ReadMeshMaterialReferences(pistol, package));

        // Every weapon viewmodel in the script package now resolves a material, including the four
        // whose geometry this tool still cannot read.
        foreach (string name in new[] { "TommyGunMESH", "WP_GrenadeLauncherMesh", "PlasmidEquipMESH", "WP_CrossbowMesh" })
        {
            var material = MaterialReader.ReadForMesh(package, Mesh(package, name));
            Assert.NotNull(material);
            Assert.NotNull(material.DiffuseTexture);
        }
    }

    [RequiresGameFact]
    public void MeshReference_IsRejectedWhenItDoesNotNameAMaterial()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        // Every mesh that resolves must resolve to a material class, never to whatever object index
        // happened to follow the tag block.
        foreach (var mesh in package.Exports.Where(e => package.GetClassName(e) == AssetClasses.SkeletalMesh))
        {
            if (mesh.SerialSize <= 0) continue;
            var reference = MaterialReader.ReadMeshMaterialReference(package.ReadExportData(mesh), package);
            if (reference is null) continue;

            string className = reference.Value.IsExport
                ? package.GetClassName(package.Exports[reference.Value.ExportIndex])
                : package.Imports[reference.Value.ImportIndex].ClassName;
            Assert.True(MaterialReader.IsMaterialClass(className), $"{mesh.ObjectName} -> {className}");
        }
    }

    [RequiresGameFact]
    public void PropertyWalk_StopsRatherThanInventingNames()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        int decoded = 0, partial = 0;
        foreach (var export in package.Exports.Where(e => MaterialReader.IsMaterialClass(package.GetClassName(e))))
        {
            var material = MaterialReader.Read(package, export);
            if (material is null) continue;
            decoded++;
            if (material.Truncated) partial++;

            // A name ending in a long number is one the walk produced after losing alignment. The
            // reader must stop at that point, so none may appear in the result.
            foreach (string name in material.UnhandledProperties)
                Assert.False(InventedName().IsMatch(name), $"{export.ObjectName} yielded '{name}'");
            foreach (var texture in material.Textures)
                Assert.False(InventedName().IsMatch(texture.Slot), $"{export.ObjectName} yielded slot '{texture.Slot}'");
        }

        Assert.True(decoded > 400, $"only {decoded} materials decoded");
        // Some shaders do stop early; the point is that they say so. See docs/research/materials.md.
        Assert.True(partial < decoded / 2, $"{partial} of {decoded} materials were partial");
    }

    /// <summary>
    /// The export carries each binding's engine-facing intent, not just the pixels.
    /// </summary>
    /// <remarks>
    /// Gate 1 item 3. A PNG cannot say that a normal map is data rather than colour, or that a
    /// texture must clamp rather than wrap, so an importer that only reads the images gets both
    /// wrong. Intent is keyed by slot because the role belongs to the binding: the hands bind
    /// <c>Hand_DIFF</c> as both facing and edge diffuse, and the same image elsewhere is a mask.
    /// </remarks>
    [RequiresGameFact]
    public void Export_CarriesEachBindingsIntent()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-intent-{Guid.NewGuid():N}");

        try
        {
            var material = MaterialExporter.Resolve(package, Mesh(package, "NEWPlayerHands"), directory);
            Assert.NotNull(material);
            Assert.NotEmpty(material.TextureIntents);

            // Every slot that resolved to a file states what that file is for.
            foreach (string slot in material.Textures.Keys)
                Assert.True(material.TextureIntents.ContainsKey(slot), $"{slot} carries no intent");

            var diffuse = material.TextureIntents.First(p => p.Key.Contains("Diffuse", StringComparison.Ordinal));
            Assert.Equal(TextureUsage.BaseColor, diffuse.Value.Usage);
            Assert.Equal(TextureColourSpace.Srgb, diffuse.Value.ColourSpace);

            var normal = material.TextureIntents.First(p => p.Key.Contains("Normal", StringComparison.Ordinal));
            Assert.Equal(TextureUsage.NormalMap, normal.Value.Usage);

            // The whole point: the normal map must not be tagged as colour.
            Assert.Equal(TextureColourSpace.Linear, normal.Value.ColourSpace);

            // And it survives serialisation — an in-memory record no importer can read is no use.
            string json = JsonSerializer.Serialize(material);
            Assert.Contains("TextureIntents", json, StringComparison.Ordinal);
            Assert.Contains("Linear", json, StringComparison.Ordinal);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    [RequiresGameFact]
    public void Export_WritesTheTexturesAndPointsTheSceneAtThem()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-material-{Guid.NewGuid():N}");

        try
        {
            var material = MaterialExporter.Resolve(package, Mesh(package, "NEWPlayerHands"), directory);

            Assert.NotNull(material);
            Assert.NotNull(material.Diffuse);
            Assert.NotNull(material.NormalMap);
            Assert.NotNull(material.Specular);

            foreach (string file in material.Textures.Values.Distinct())
            {
                string path = Path.Combine(directory, file.Replace('/', Path.DirectorySeparatorChar));
                Assert.True(File.Exists(path), file);
                Assert.True(new FileInfo(path).Length > 0, file);
            }

            // The same image is bound to several slots; it must be written once and shared.
            Assert.Equal(3, material.Textures.Values.Distinct().Count());
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    [RequiresGameFact]
    public void Export_PreservesRawShaderValuesWithoutInventingABlendMode()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        // The map contains several materials with OutputBlending.  Select one through its mesh so
        // this verifies the same resolution/export path a user invokes, rather than a detached
        // material-reader result.
        var mesh = package.Exports
            .Where(e => package.GetClassName(e) == AssetClasses.StaticMesh)
            .FirstOrDefault(e => MaterialReader.ReadForMesh(package, e)?.OutputBlending is not null);
        Assert.NotNull(mesh);

        var source = MaterialReader.ReadForMesh(package, mesh!);
        var directory = Path.Combine(Path.GetTempPath(), $"bioshock-material-values-{Guid.NewGuid():N}");
        try
        {
            var exported = MaterialExporter.Resolve(package, mesh!, directory);

            Assert.NotNull(source);
            Assert.NotNull(exported);
            Assert.Equal(source!.OutputBlending, exported!.OutputBlending);
            Assert.Equal(source.SourceFile, exported.SourceFile);
            Assert.Equal(source.SourceExportIndex, exported.SourceExportIndex);
            Assert.Equal(source.EmissiveBrightness, exported.EmissiveBrightness);
            float[]? expectedEmissive = source.EmissiveColor is { } color
                ? [color.R / 255f, color.G / 255f, color.B / 255f, color.A / 255f]
                : null;
            Assert.Equal(expectedEmissive, exported.EmissiveColor);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    [RequiresGameFact]
    public void Fbx_CarriesTheMaterialAndItsTextureFiles()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-material-fbx-{Guid.NewGuid():N}");

        try
        {
            var meshExport = Mesh(package, "NEWPlayerHands");
            byte[] payload = package.ReadExportData(meshExport);

            var wrapper = package.Exports.First(e =>
                e.ObjectName == "UAPW_NEWPlayerHands"
                && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper);

            var scene = AnimationSceneExporter.Build(
                AnimationPackage.Load(package, wrapper),
                "Pistol",
                Core.Mesh.SkeletalMeshReader.ReadSockets(payload, package.Names),
                Core.Mesh.SkeletalMeshReader.ReadGeometry(payload),
                null,
                MaterialExporter.Resolve(package, meshExport, directory));

            using var stream = new MemoryStream();
            FbxWriter.Write(stream, FbxSceneBuilder.Build(
                scene, new FbxExportOptions { BaseDirectory = directory }));

            var roots = FbxTestReader.Read(stream.ToArray());
            var objects = roots.First(r => r.Name == "Objects");

            var fbxMaterial = Assert.Single(objects.FindAll("Material"));
            Assert.Equal("NEWplayerHandsRimShader", fbxMaterial.ObjectName);

            // Diffuse, normal and specular, each with the Video clip that names the file on disk.
            Assert.Equal(3, objects.FindAll("Texture").Count());
            Assert.Equal(3, objects.FindAll("Video").Count());

            foreach (var texture in objects.FindAll("Texture"))
            {
                string relative = (string)texture.Find("RelativeFilename")!.Properties[0];
                Assert.True(
                    File.Exists(Path.Combine(directory, relative.Replace('/', Path.DirectorySeparatorChar))), relative);
            }

            // The mesh has to actually reference the material, or it arrives untextured.
            long materialId = (long)fbxMaterial.Properties[0];
            var connections = roots.First(r => r.Name == "Connections");
            Assert.Contains(connections.FindAll("C"),
                c => (string)c.Properties[0] == "OO" && (long)c.Properties[1] == materialId);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }
}
