using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Which triangles a mesh draws with which material.
/// </summary>
/// <remarks>
/// The section table said which triangles belonged to which run; nothing consumed it, so a mesh
/// naming three materials was textured from the first and the other two were dropped. These tests
/// hold the pairing — the Nth section uses the Nth entry of the object's <c>Materials</c> array —
/// against real shipped bytes.
/// </remarks>
[Collection(GameCollection.Name)]
public sealed class MeshSurfaceTests(GameFixture game)
{
    private string Map(string name) =>
        Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), name + ".bsm");

    private (BioShockPackage Package, ObjectExport Export, MeshGeometry Geometry) Open(string map, string mesh)
    {
        var package = BioShockPackage.Open(Map(map));
        var export = package.Exports
            .Where(e => package.GetClassName(e) == "StaticMesh"
                        && string.Equals(e.ObjectName, mesh, StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);
        Assert.True(export is not null, $"{mesh} is not in {map}");

        var geometry = StaticMeshReader.ReadGeometry(package.ReadExportData(export!));
        Assert.True(geometry is not null, $"{mesh} produced no geometry");
        return (package, export!, geometry!);
    }

    /// <summary>
    /// Two meshes whose runs are named, checked material by material and range by range.
    /// </summary>
    /// <remarks>
    /// Both are asymmetric assemblies of unlike parts, which is what makes them worth pinning: the
    /// Bathysphere is a metal hull with a small glass port, and getting the order wrong glazes the
    /// hull and plates the window.
    /// </remarks>
    [RequiresGameFact]
    public void SurfacesPairEachSectionWithItsOwnMaterial()
    {
        var expected = new Dictionary<(string Map, string Mesh), (string Material, int Faces)[]>
        {
            [("0-Lighthouse", "bat_vehicle")] = [("Bathysphere_mat", 8200), ("BathysphereLight_mat", 88)],
            [("0-Lighthouse", "CityGate")] = [("Granite_L", 560), ("Gate_Light", 64), ("C_Gate", 1776)],
        };

        foreach (var ((map, mesh), runs) in expected)
        {
            var (package, export, geometry) = Open(map, mesh);
            using (package)
            {
                var surfaces = MeshSurfaceResolver.Resolve(package, export, geometry);

                Assert.Equal(runs.Length, surfaces.Count);

                int covered = 0;
                for (int i = 0; i < runs.Length; i++)
                {
                    var surface = surfaces[i];
                    Assert.Equal(i, surface.Slot);
                    Assert.Equal(covered, surface.FirstIndex);
                    Assert.Equal(runs[i].Faces, surface.TriangleCount);

                    Assert.True(surface.Material is not null,
                        $"{mesh} slot {i} resolved no material at all");
                    Assert.Equal(runs[i].Material, surface.Material!.Name);

                    covered += surface.IndexCount;
                }

                // The runs must account for the whole mesh, or triangles vanish from the export.
                Assert.Equal(geometry.Indices.Count, covered);

                // The point of the whole exercise: these are genuinely different materials.
                Assert.Equal(runs.Length, surfaces.Select(s => s.Material!.Name).Distinct().Count());
            }
        }
    }

    /// <summary>
    /// An empty material slot keeps its position, so the sections after it are not shifted onto the
    /// wrong material.
    /// </summary>
    /// <remarks>
    /// <c>ad_01</c> declares two <c>FStaticMeshMaterial</c> elements and the second's <c>Material</c>
    /// is an <c>Object</c> property with an implicit size and a null reference — a real, declared,
    /// empty slot. Compacting the list to the one material that resolves would leave one slot for
    /// two sections. Forty such slots ship across the game.
    /// </remarks>
    [RequiresGameFact]
    public void AnEmptyMaterialSlotIsKeptRatherThanClosedUp()
    {
        var (package, export, geometry) = Open("3-Arcadia", "ad_01");
        using (package)
        {
            byte[] payload = package.ReadExportData(export);

            var slots = MaterialReader.ReadMeshMaterialSlots(payload, package);
            Assert.Equal(2, slots.Count);
            Assert.True(slots[0].IsExport, "the first slot should name a material");
            Assert.True(slots[1].IsNull, "the second slot is empty in the shipped bytes");

            // The compacting reader still reports only what resolves, so callers that want materials
            // rather than slots are unaffected.
            Assert.Single(MaterialReader.ReadMeshMaterialReferences(payload, package));

            var surfaces = MeshSurfaceResolver.Resolve(package, export, geometry);
            Assert.Equal(2, surfaces.Count);
            Assert.NotNull(surfaces[0].Material);
            Assert.Null(surfaces[1].Material);
        }
    }

    /// <summary>
    /// A material named by an import resolves, and so does its texture.
    /// </summary>
    /// <remarks>
    /// <para>
    /// 432 material slots across the game are imports and <b>not one resolves inside its own
    /// package</b>. They are the shared shaders: every <c>WP_AI_*</c> weapon an NPC carries points at
    /// the viewmodel's shader in <c>ShockGame.U</c>, the ammo pickups likewise, and all 108
    /// security-camera slots point at <c>cam_smallcam_shader</c> in <c>ShockAI.U</c>. Every one of
    /// those meshes drew flat grey.
    /// </para>
    /// <para>
    /// Resolving the material is only half of it: <b>the textures live with the material, not with
    /// the mesh</b>, so a caller looking beside the mesh still finds nothing. The material carries
    /// the file it came from for exactly this reason.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void AMaterialNamedByImportResolvesWithItsTexture()
    {
        var external = new Core.Services.PackageMaterialSource(game.RequireRoot);

        var (package, export, geometry) = Open("1-Medical", "WP_AI_Pistol");
        using (package)
        {
            byte[] payload = package.ReadExportData(export);

            // The premise: this mesh names its material by import, not by export.
            var slots = MaterialReader.ReadMeshMaterialSlots(payload, package);
            Assert.Contains(slots, s => s.IsImport);

            // Without a source for imports it is unresolved, and that is what drew grey.
            var without = MeshSurfaceResolver.Resolve(package, export, geometry);
            Assert.All(without, s => Assert.Null(s.Material));

            var with = MeshSurfaceResolver.Resolve(package, export, geometry, external);
            var material = with.Select(s => s.Material).FirstOrDefault(m => m is not null);

            Assert.True(material is not null, "the imported material still does not resolve");
            Assert.Equal("PistolShader", material!.Name);

            // It must say where it came from, or its textures cannot be found.
            Assert.False(string.IsNullOrEmpty(material.SourceFile));
            Assert.NotEqual(package.FilePath, material.SourceFile);
            Assert.Equal("Pistol_DIFF", material.DiffuseTexture);

            // And the texture must actually be there and decode.
            using var source = BioShockPackage.Open(material.SourceFile!);
            var texture = source.Exports
                .Where(e => string.Equals(e.ObjectName, material.DiffuseTexture, StringComparison.OrdinalIgnoreCase)
                            && source.GetClassName(e) == Core.Textures.TextureReader.ClassName)
                .MaxBy(e => e.SerialSize);

            Assert.True(texture is not null, "the material's diffuse is not in the package it came from");
            var decoded = Core.Textures.TextureReader.Read(source, texture!, null);
            Assert.True(decoded is not null && decoded.Mips.Count > 0, "the diffuse did not decode");
        }
    }

    /// <summary>
    /// Game-wide: the imported materials resolve, rather than a handful that happened to be checked.
    /// </summary>
    [RequiresGameFact]
    public void ImportedMaterialsResolveGameWide()
    {
        var external = new Core.Services.PackageMaterialSource(game.RequireRoot);

        int imports = 0, resolved = 0;
        var unresolved = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

        foreach (string map in Directory.GetFiles(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
        {
            using var package = BioShockPackage.Open(map);

            foreach (var export in package.Exports)
            {
                string className = package.GetClassName(export);
                if (!MeshGeometryReader.IsMeshClass(className) || export.SerialSize <= 0) continue;

                byte[] payload;
                MeshGeometry? geometry;
                try
                {
                    payload = package.ReadExportData(export);
                    geometry = MeshGeometryReader.Read(className, payload);
                }
                catch { continue; }
                if (geometry is null) continue;

                if (!MaterialReader.ReadMeshMaterialSlots(payload, package).Any(s => s.IsImport)) continue;

                foreach (var surface in MeshSurfaceResolver.Resolve(package, export, geometry, external))
                {
                    if (!surface.MaterialReference.IsImport) continue;
                    imports++;

                    if (surface.Material is not null) resolved++;
                    else
                    {
                        string name = package.Imports[surface.MaterialReference.ImportIndex].ObjectName;
                        unresolved[name] = unresolved.GetValueOrDefault(name) + 1;
                    }
                }
            }
        }

        Assert.True(imports > 400, $"only {imports} imported slots found — the sweep is not covering the game");

        // Two names never resolve, and both for the same understood reason: they are `Texture`
        // exports, not shaders. In Unreal's class tree `Texture` derives from `Material`, so a
        // material slot may legitimately name a texture directly — `PlaneLight` names Engine's
        // `DefaultTexture`, and one mesh names `Ghost_Emissive` in ShockGame. This resolver returns
        // only real shader classes, so those surfaces stay unresolved and say so rather than being
        // handed a texture dressed up as a material. Named here rather than hidden behind a
        // tolerance, so a new unresolved name fails this test instead of blending in.
        string[] knownTextures = ["DefaultTexture", "Ghost_Emissive"];

        var stubborn = unresolved
            .Where(kv => !knownTextures.Contains(kv.Key, StringComparer.OrdinalIgnoreCase))
            .ToList();

        Assert.True(stubborn.Count == 0,
            $"{stubborn.Sum(kv => kv.Value)} imported materials do not resolve: "
            + string.Join(", ", stubborn.Select(kv => $"{kv.Key} x{kv.Value}")));

        // Everything else must resolve — that is 427 of 432 slots.
        Assert.True(resolved >= imports - 8, $"only {resolved} of {imports} imported materials resolved");
    }

    /// <summary>
    /// Game-wide: every static mesh declares exactly as many sections as material slots.
    /// </summary>
    /// <remarks>
    /// This is the evidence the pairing rests on, and it is not circular. The section table is read
    /// backwards from the geometry block that the geometry search located; the <c>Materials</c> array
    /// is read forwards as an ordinary tagged property from the start of the payload. Neither reader
    /// consults the other, and across all 8,668 shipped static meshes the two counts agree with no
    /// exceptions. Two independent decodes agreeing that many times is not a coincidence.
    /// </remarks>
    [RequiresGameFact]
    public void EveryStaticMeshHasAsManySectionsAsMaterialSlots()
    {
        int meshes = 0, multiSection = 0, mismatched = 0;
        var examples = new List<string>();

        foreach (string map in Directory.GetFiles(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
        {
            using var package = BioShockPackage.Open(map);

            foreach (var export in package.Exports.Where(e =>
                         package.GetClassName(e) == "StaticMesh" && e.SerialSize > 0))
            {
                byte[] payload;
                MeshGeometry? geometry;
                try
                {
                    payload = package.ReadExportData(export);
                    geometry = StaticMeshReader.ReadGeometry(payload);
                }
                catch { continue; }
                if (geometry is null || geometry.Sections.Count == 0) continue;

                meshes++;
                if (geometry.Sections.Count > 1) multiSection++;

                int slots = MaterialReader.ReadMeshMaterialSlots(payload, package).Count;
                if (slots == geometry.Sections.Count) continue;

                mismatched++;
                if (examples.Count < 10)
                {
                    examples.Add($"{Path.GetFileNameWithoutExtension(map)}/{export.ObjectName}: "
                                 + $"{geometry.Sections.Count} sections, {slots} slots");
                }
            }
        }

        Assert.True(meshes > 8_000, $"only {meshes} meshes read — the sweep is not covering the game");

        // The whole point is the meshes with more than one run; a pass with none would be vacuous.
        Assert.True(multiSection > 1_000, $"only {multiSection} meshes have more than one section");

        Assert.True(mismatched == 0,
            $"{mismatched} of {meshes} meshes disagree: {string.Join("; ", examples)}");
    }

    /// <summary>
    /// A mesh with several runs must not resolve them all to one material — which is exactly what
    /// the tool did before, and it looked like a texture bug rather than a missing feature.
    /// </summary>
    [RequiresGameFact]
    public void MultiMaterialMeshesResolveDistinctMaterialsGameWide()
    {
        int multi = 0, allSlotsSame = 0, distinctResolved = 0;

        foreach (string map in Directory.GetFiles(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
        {
            using var package = BioShockPackage.Open(map);

            foreach (var export in package.Exports.Where(e =>
                         package.GetClassName(e) == "StaticMesh" && e.SerialSize > 0))
            {
                byte[] payload;
                MeshGeometry? geometry;
                try
                {
                    payload = package.ReadExportData(export);
                    geometry = StaticMeshReader.ReadGeometry(payload);
                }
                catch { continue; }
                if (geometry is null || geometry.Sections.Count < 2) continue;

                multi++;
                var slots = MaterialReader.ReadMeshMaterialSlots(payload, package);
                var named = slots.Where(s => !s.IsNull).ToList();
                if (named.Count < 2) continue;

                if (named.Distinct().Count() == 1) allSlotsSame++;
                else distinctResolved++;
            }
        }

        Assert.True(multi > 1_000, $"only {multi} multi-section meshes found");

        // Most multi-run meshes genuinely name different shaders. A handful naming the same one
        // twice is legitimate authoring, so this is a proportion rather than an absolute.
        Assert.True(distinctResolved > multi / 2,
            $"only {distinctResolved} of {multi} multi-run meshes name more than one distinct material "
            + $"({allSlotsSame} name the same one for every run)");
    }
}
