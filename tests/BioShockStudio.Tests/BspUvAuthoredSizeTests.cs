using BioShockStudio.Core.Export;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Pins the Remaster BSP UV divisor rule: world-units-per-repeat =
/// <c>AuthoredTextureSize / |TextureU|</c> for the three Medical materials measured against the
/// live game on 7 Oct 2026 (floor 2× vs divide-by-original; wall trim placement; ceiling period).
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class BspUvAuthoredSizeTests(GameFixture game)
{
    private const string OriginalTextureDir =
        @"G:\SteamLibrary\steamapps\common\Bioshock\Builds\Release\UmodelExport\1-Medical\Texture";

    private static readonly (string Shader, float ExpectedPeriod)[] MedicalExpected =
    [
        ("Bathroom_Tile_BW_Diffuse_shader", 256f),
        ("Medical_ceilling_Diffuse_shader", 256f),
        ("med_wall_public_shader", 768f),
    ];

    [RequiresGameFact]
    public void MedicalMaterialsWorldUnitsPerRepeatMatchRemasterRule()
    {
        if (!Directory.Exists(OriginalTextureDir))
            return;

        string? previousDir = Environment.GetEnvironmentVariable("BIOSHOCK_ORIGINAL_TEXTURE_DIR");
        string? previousScale = Environment.GetEnvironmentVariable("BIOSHOCK_BSP_UV_AUTHORED_SCALE");
        try
        {
            Environment.SetEnvironmentVariable("BIOSHOCK_ORIGINAL_TEXTURE_DIR", OriginalTextureDir);
            Environment.SetEnvironmentVariable("BIOSHOCK_BSP_UV_AUTHORED_SCALE", null); // default = 2

            using var package = BioShockPackage.Open(game.MedicalPackage);
            var model = ModelReader.BuiltWorld(package);
            Assert.NotNull(model);
            var world = BspWorldReader.Read(package, package.Exports[model!.Source.ExportIndex]);
            Assert.NotNull(world);

            foreach (var (shaderName, expectedPeriod) in MedicalExpected)
            {
                int exportIdx = IndexOf(package, shaderName);
                var export = package.Exports[exportIdx];
                var materialId = new SourceId(
                    Path.GetFileNameWithoutExtension(package.FilePath) ?? "1-Medical",
                    exportIdx,
                    package.GetClassName(export),
                    export.ObjectName);

                var size = LevelSceneExporter.AuthoredTextureSize(package, materialId);
                Assert.NotNull(size);

                float uMed = MedianTextureU(world!, exportIdx + 1);
                Assert.True(uMed > 1e-3f, $"|TextureU| median for {shaderName} is {uMed}");

                float period = size!.Value.Width / uMed;
                Assert.InRange(period, expectedPeriod - 0.5f, expectedPeriod + 0.5f);

                Environment.SetEnvironmentVariable("BIOSHOCK_BSP_UV_AUTHORED_SCALE", "1");
                var legacy = LevelSceneExporter.AuthoredTextureSize(package, materialId);
                Assert.NotNull(legacy);
                Assert.Equal(size.Value.Width / 2, legacy!.Value.Width);
                Environment.SetEnvironmentVariable("BIOSHOCK_BSP_UV_AUTHORED_SCALE", null);
            }
        }
        finally
        {
            Environment.SetEnvironmentVariable("BIOSHOCK_ORIGINAL_TEXTURE_DIR", previousDir);
            Environment.SetEnvironmentVariable("BIOSHOCK_BSP_UV_AUTHORED_SCALE", previousScale);
        }
    }

    [RequiresGameFact]
    public void AuthoredSizeUsesOriginalDiffuseNotShippedUpscaleWhenDirSet()
    {
        if (!Directory.Exists(OriginalTextureDir)) return;

        string? previousDir = Environment.GetEnvironmentVariable("BIOSHOCK_ORIGINAL_TEXTURE_DIR");
        string? previousScale = Environment.GetEnvironmentVariable("BIOSHOCK_BSP_UV_AUTHORED_SCALE");
        try
        {
            Environment.SetEnvironmentVariable("BIOSHOCK_ORIGINAL_TEXTURE_DIR", OriginalTextureDir);
            Environment.SetEnvironmentVariable("BIOSHOCK_BSP_UV_AUTHORED_SCALE", "2");

            using var package = BioShockPackage.Open(game.MedicalPackage);
            int exportIdx = IndexOf(package, "Bathroom_Tile_BW_Diffuse_shader");
            var export = package.Exports[exportIdx];
            var id = new SourceId("1-Medical", exportIdx, package.GetClassName(export), export.ObjectName);

            // Original PNG 512; remaster USize 2048; rule → 1024.
            Assert.Equal((1024, 1024), LevelSceneExporter.AuthoredTextureSize(package, id));

            var mat = MaterialReader.Read(package, export);
            Assert.Equal("Bathroom_Tile_BW_dirt", mat?.DiffuseTexture);
            var tex = package.Exports
                .Where(e => e.ObjectName == mat!.DiffuseTexture && package.GetClassName(e) == TextureReader.ClassName)
                .MaxBy(e => e.SerialSize);
            Assert.NotNull(tex);
            var header = TextureReader.ReadHeader(package, tex!);
            Assert.Equal(2048, header?.Width);
        }
        finally
        {
            Environment.SetEnvironmentVariable("BIOSHOCK_ORIGINAL_TEXTURE_DIR", previousDir);
            Environment.SetEnvironmentVariable("BIOSHOCK_BSP_UV_AUTHORED_SCALE", previousScale);
        }
    }

    private static float MedianTextureU(BspWorld world, int matRef)
    {
        var uMags = new List<float>();
        foreach (var surface in world.Surfaces)
        {
            if (surface.Material.Value != matRef || !surface.IsDrawn) continue;
            if (surface.TextureU < 0 || surface.TextureU >= world.Vectors.Count) continue;
            uMags.Add(world.Vectors[surface.TextureU].Length());
        }
        Assert.NotEmpty(uMags);
        uMags.Sort();
        return uMags[uMags.Count / 2];
    }

    private static int IndexOf(BioShockPackage package, string objectName)
    {
        for (int i = 0; i < package.Exports.Count; i++)
            if (package.Exports[i].ObjectName == objectName) return i;
        throw new InvalidOperationException($"missing {objectName}");
    }
}
