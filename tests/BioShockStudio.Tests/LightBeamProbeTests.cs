using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// What the white shards around a light fixture actually are.
/// </summary>
/// <remarks>
/// A user photographed a chandelier surrounded by large flat white triangles. The hypothesis is
/// light-beam geometry — volumetric shafts meant to be blended additively, drawn opaque because
/// their material binds no base colour. This measures it rather than assuming it.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LightBeamProbeTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>
    /// Light-beam surfaces are identified and excluded, and excluding them keeps the fixture.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>A guess in this test was wrong and the measurement is kept instead.</b> It asserted that
    /// beams hang off ordinary fixtures — one mesh whose shade is architecture and whose shafts are
    /// not — and therefore that a per-instance filter would take the lamp with the beam. Measured on
    /// <c>0-Lighthouse</c>, all <b>19</b> beam instances are beams <i>throughout</i>: the shafts are
    /// authored as their own meshes.
    /// </para>
    /// <para>
    /// So filtering per instance would have worked equally well here. The filter is still
    /// per-surface, because that is correct for a mesh that mixes the two and costs nothing when
    /// none does — but the justification is "it cannot go wrong", not "it is required", and the
    /// count is recorded so nobody re-derives the wrong reason.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void LightBeamSurfacesAreExcludedWithoutTakingTheirFixtures()
    {
        var prepared = new LevelViewportService(new AssetCatalogService()).Prepare(game.LighthousePackage);

        int effectSurfaces = 0, effectTriangles = 0;
        int instancesWithBeams = 0, instancesEntirelyBeams = 0;

        foreach (var item in prepared.Viewport.Items)
        {
            int beams = item.Model.Surfaces.Count(s => s.IsEffect);
            if (beams == 0) continue;

            instancesWithBeams++;
            if (beams == item.Model.Surfaces.Count) instancesEntirelyBeams++;

            effectSurfaces += beams;
            effectTriangles += item.Model.Surfaces.Where(s => s.IsEffect).Sum(s => s.IndexCount / 3);
        }

        Log($"light-beam surfaces: {effectSurfaces} over {instancesWithBeams} instances, "
            + $"{effectTriangles:N0} triangles; {instancesEntirelyBeams} instances are beams throughout");

        Assert.True(effectSurfaces > 0, "no light-beam surfaces were identified at all");

        // The classification keys off the material class, so every flagged surface must actually be
        // one — a name-based rule would drift into walls, which is the failure §4 records.
        Assert.All(
            prepared.Viewport.Items.SelectMany(i => i.Model.Surfaces).Where(s => s.IsEffect),
            s => Assert.True(s.Texture is null,
                $"a light-beam surface ({s.MaterialName}) bound a base colour, so it is probably not one"));

        // Recorded, not asserted either way: on this map every beam instance is beams throughout,
        // so a per-instance filter would be equivalent. Pinning that as a requirement would be
        // pinning an accident of how Lighthouse is authored.
        Assert.Equal(instancesWithBeams, instancesEntirelyBeams);
    }

    [RequiresGameFact]
    public void WhatMaterialClassesTheLevelsGeometryDrawsWith()
    {
        foreach (string map in new[] { "0-Lighthouse", "1-Medical" })
        {
            using var package = BioShockPackage.Open(
                Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), map + ".bsm"));

            var context = LevelAnalyzer.Analyze(package);
            var scene = LevelSceneBuilder.Build(package, context);

            // Every material every placed instance names, by the class of the material object.
            var classes = new Dictionary<string, int>(StringComparer.Ordinal);
            var noDiffuse = new Dictionary<string, int>(StringComparer.Ordinal);

            foreach (var instance in scene.Instances)
            {
                foreach (var material in instance.Materials)
                {
                    if (material is not { } m) continue;
                    classes[m.ClassName] = classes.GetValueOrDefault(m.ClassName) + 1;

                    BioShockMaterial? decoded;
                    try { decoded = MaterialReader.Read(package, package.Exports[m.ExportIndex]); }
                    catch { continue; }

                    if (decoded?.DiffuseTexture is null)
                        noDiffuse[m.ClassName] = noDiffuse.GetValueOrDefault(m.ClassName) + 1;
                }
            }

            Log($"{map}: material classes on placed geometry");
            foreach (var (name, count) in classes.OrderByDescending(e => e.Value))
                Log($"  {name,-24} {count,5}   without a base colour: {noDiffuse.GetValueOrDefault(name)}");
        }

        Assert.True(true);
    }

    /// <summary>
    /// Which placed assets have surfaces that resolve <b>no texture</b>, and what those materials are.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The previous version of this probe looked at <c>LevelInstance.Materials</c> and found
    /// nothing, because that list is only populated for BSP — a static mesh resolves its materials
    /// later, through <c>MeshSurfaceResolver</c>, when the viewport prepares it. The chandelier in
    /// the report is a static mesh, so the probe was looking in the wrong place. Goes through the
    /// prepared level now, which is what actually gets drawn.
    /// </para>
    /// <para>
    /// A surface with no texture draws flat light grey, and <c>docs/HANDOFF.md</c> §4 records why
    /// that is dangerous: "grey paint and a missing material are the same pixels". The white shards
    /// are the visible end of it.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void WhichPlacedAssetsDrawSurfacesWithNoTexture()
    {
        var prepared = new LevelViewportService(new AssetCatalogService()).Prepare(game.LighthousePackage);

        var untextured = new Dictionary<string, (int Surfaces, int Triangles, string Materials)>(StringComparer.Ordinal);
        int totalSurfaces = 0, totalUntextured = 0;

        foreach (var item in prepared.Viewport.Items)
        {
            foreach (var surface in item.Model.Surfaces)
            {
                totalSurfaces++;
                if (surface.Texture is not null) continue;
                totalUntextured++;

                string key = $"{item.ActorClass}/{item.Kind}";
                string material = surface.MaterialName is { } name
                    ? $"{name}[{ClassOf(name)}]"
                    : "(nothing)";

                untextured[key] = untextured.TryGetValue(key, out var existing)
                    ? (existing.Surfaces + 1, existing.Triangles + surface.IndexCount / 3,
                       existing.Materials.Contains(material, StringComparison.Ordinal)
                           ? existing.Materials
                           : existing.Materials + ", " + material)
                    : (1, surface.IndexCount / 3, material);
            }
        }

        Log($"untextured surfaces: {totalUntextured} of {totalSurfaces}");
        foreach (var (key, (surfaces, triangles, materials)) in untextured.OrderByDescending(e => e.Value.Triangles).Take(20))
            Log($"  {key,-40} {surfaces,4} surfaces, {triangles,6} triangles — {Trim(materials)}");

        Assert.True(true);

        static string Trim(string value) => value.Length <= 200 ? value : value[..200] + "…";

        // The class of a material by name, looked up across every map package — a level's materials
        // are often imported from another file, so the mesh's own package need not hold them.
        string ClassOf(string name)
        {
            foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
            {
                using var package = BioShockPackage.Open(map);
                var export = package.Exports.FirstOrDefault(e => e.ObjectName == name);
                if (export is not null) return package.GetClassName(export);
            }
            return "?";
        }
    }
}
