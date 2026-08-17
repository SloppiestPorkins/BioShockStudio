using System.Numerics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The BSP brush container — <c>Model</c> / <c>Polys</c> — read from shipped bytes.
/// </summary>
/// <remarks>
/// <para>
/// This is the container 230 actors in <c>0-Lighthouse</c> reference and nothing decoded, and the
/// same one <c>AtlasLabsDoorAnim</c> ships in place of a drawable mesh (HANDOFF §6.2).
/// </para>
/// <para>
/// <b>The load-bearing assertion is arithmetic.</b> Every <c>Polys</c> export must be consumed to
/// its exact final byte. A wrong field list cannot land on the boundary across hundreds of
/// independent exports with differing polygon counts, vertex counts and sizes — every surplus or
/// missing byte accumulates and the walk lands short or long. That is what makes this a decode
/// rather than a fit, and it is a test that can fail: adding or removing one field from
/// <see cref="PolysReader"/> makes it fail on the first export.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BspGeometryTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>
    /// Every <c>Polys</c> export in every shipped map walks to its exact end.
    /// </summary>
    /// <remarks>
    /// Swept across all the map packages rather than proved on one, because "a structure that works
    /// in one package may be package-local" has already happened here — HANDOFF §7 rule 3, and the
    /// reason all 21 packages are required to consume to the byte.
    /// </remarks>
    [RequiresGameFact]
    public void EveryPolysExportInEveryMapWalksToItsExactEnd()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();
        Assert.NotEmpty(maps);

        int packagesWithBrushes = 0, exports = 0, polygons = 0, vertices = 0;
        int withActor = 0, withMaterial = 0, withItemName = 0;
        var materialClasses = new Dictionary<string, int>(StringComparer.Ordinal);
        var failures = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var found = PolysReader.Enumerate(package).ToList();
            if (found.Count == 0) continue;
            packagesWithBrushes++;

            int inThisMap = 0;
            foreach (var export in found)
            {
                BspPolys polys;
                try { polys = PolysReader.Read(package, export); }
                catch (Exception ex) { failures.Add(ex.Message); continue; }

                exports++;
                inThisMap += polys.Polygons.Count;
                polygons += polys.Polygons.Count;
                vertices += polys.VertexCount;
                withActor += polys.Polygons.Count(p => !p.Actor.IsNull);
                withMaterial += polys.Polygons.Count(p => !p.Material.IsNull);
                withItemName += polys.Polygons.Count(p => p.ItemName != "None");

                // What the non-null field resolves to is what says it is the material and not the
                // actor: both are object references and both are plausible on a brush polygon, so
                // the class of the target is the discriminator, exactly as elsewhere in this project.
                foreach (var polygon in polys.Polygons)
                {
                    if (polygon.Material.IsNull) continue;
                    string className = ClassOf(package, polygon.Material);
                    materialClasses[className] = materialClasses.GetValueOrDefault(className) + 1;
                }
            }

            Log($"{Path.GetFileNameWithoutExtension(map),-24} {found.Count,4} Polys, {inThisMap,6} polygons");
        }

        Log($"maps with brushes: {packagesWithBrushes} of {maps.Count}");
        Log($"Polys exports read: {exports}, polygons {polygons}, vertices {vertices}");
        Log($"polygons naming an Actor: {withActor}, a Material: {withMaterial}, an ItemName: {withItemName}");
        foreach (var (className, count) in materialClasses.OrderByDescending(e => e.Value))
            Log($"    material field resolves to {className}: {count}");
        foreach (string failure in failures.Take(20)) Log("  FAILED " + failure);

        Assert.True(failures.Count == 0,
            $"{failures.Count} of {failures.Count + exports} Polys exports did not walk to their exact end:"
            + Environment.NewLine + string.Join(Environment.NewLine, failures.Take(10)));

        Assert.True(exports > 1000, $"only {exports} Polys exports were read across {maps.Count} maps");
    }

    /// <summary>
    /// The Newell normal of a polygon: twice its vector area, pointing along its winding. Robust
    /// where a single cross product is not, because every edge contributes.
    /// </summary>
    private static Vector3 Newell(IReadOnlyList<Vector3> vertices)
    {
        var normal = Vector3.Zero;
        for (int i = 0; i < vertices.Count; i++)
        {
            var current = vertices[i];
            var next = vertices[(i + 1) % vertices.Count];
            normal.X += (current.Y - next.Y) * (current.Z + next.Z);
            normal.Y += (current.Z - next.Z) * (current.X + next.X);
            normal.Z += (current.X - next.X) * (current.Y + next.Y);
        }
        return normal;
    }

    /// <summary>The class of a reference's target, or why it has none.</summary>
    private static string ClassOf(BioShockPackage package, PackageIndex index)
    {
        if (index.IsExport)
            return index.ExportIndex < package.Exports.Count
                ? package.GetClassName(package.Exports[index.ExportIndex])
                : "(export out of range)";
        if (index.IsImport)
            return index.ImportIndex < package.Imports.Count
                ? "import:" + package.Imports[index.ImportIndex].ClassName
                : "(import out of range)";
        return "(null)";
    }

    /// <summary>
    /// What one shipped map holds, pinned so the figures in the handoff cannot go stale silently.
    /// </summary>
    [RequiresGameFact]
    public void LighthouseHoldsTheBrushesItsActorsReference()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var polys = PolysReader.Enumerate(package).Select(e => PolysReader.Read(package, e)).ToList();

        Assert.Equal(285, polys.Count);
        Assert.Equal(1_717, polys.Sum(p => p.Polygons.Count));
        Assert.Equal(6_884, polys.Sum(p => p.VertexCount));

        // Every polygon is a real polygon with a unit normal, which no count-based check would see.
        foreach (var polygon in polys.SelectMany(p => p.Polygons))
        {
            Assert.True(polygon.Vertices.Count >= 3);
            Assert.True(Math.Abs(polygon.Normal.Length() - 1f) < 1e-3f,
                $"a polygon's normal is not unit length: {polygon.Normal} in {polygon.ItemName}");
        }
    }

    /// <summary>
    /// BSP winds the opposite way from the game's meshes, and the triangles this reader emits are
    /// corrected for it.
    /// </summary>
    /// <remarks>
    /// <para>
    /// This is the check <c>docs/research/ANIMATION_COORDINATE_SYSTEM.md</c> §6 makes on mesh
    /// triangles, applied to a container it was never applied to — and the answer came out the
    /// other way, which is why it is measured over the whole game rather than reasoned about. The
    /// game's *meshes* are front-face clockwise, so the basis reflection alone brings their winding
    /// and their normals into agreement and the index buffer must be left alone. Its *BSP* is the
    /// opposite, unanimously.
    /// </para>
    /// <para>
    /// <b>Both halves are asserted here on purpose.</b> The first pins the reason — the shipped
    /// order disagrees, so there is something to correct — and the second pins the correction. A
    /// test that only checked the output would still pass if someone "fixed" this by negating the
    /// normal instead, which would light every brush inside out while every count stayed green.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void BspWindsOppositeToTheMeshesAndTheEmittedTrianglesCorrectForIt()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int shippedAgree = 0, shippedDisagree = 0;
        int emittedAgree = 0, emittedDisagree = 0;
        int degenerate = 0;

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            foreach (var export in PolysReader.Enumerate(package))
            {
                foreach (var polygon in PolysReader.Read(package, export).Polygons)
                {
                    // Orientation is measured with the Newell normal over the whole polygon, not
                    // with the cross product of the first three vertices. Measuring it the second
                    // way first put 4 of 93,264 polygons on the wrong side of the answer — all of
                    // them slivers whose first three vertices are nearly collinear, so the probe was
                    // reading its own numerical noise rather than the polygon's winding. Newell
                    // sums every edge, so a sliver contributes proportionally to its area.
                    var shipped = Newell(polygon.Vertices);
                    if (shipped.Length() < 1e-3f) { degenerate++; continue; }
                    if (Vector3.Dot(Vector3.Normalize(shipped), polygon.Normal) > 0) shippedAgree++;
                    else shippedDisagree++;

                    // What the reader actually hands a consumer: the fan, reassembled and measured
                    // the same way, so the two counts are directly comparable.
                    var fan = polygon.Triangles().ToList();
                    var emitted = Vector3.Zero;
                    foreach (var (a, b, c) in fan) emitted += Vector3.Cross(b - a, c - a);
                    if (emitted.Length() < 1e-3f) continue;
                    if (Vector3.Dot(Vector3.Normalize(emitted), polygon.Normal) > 0) emittedAgree++;
                    else emittedDisagree++;
                }
            }
        }

        Log($"shipped order vs normal: {shippedAgree} agree, {shippedDisagree} disagree, {degenerate} degenerate");
        Log($"emitted triangles vs normal: {emittedAgree} agree, {emittedDisagree} disagree");

        Assert.True(shippedAgree + shippedDisagree > 50_000, "too few polygons to draw a conclusion from");

        // The reason the reversal exists. If this ever comes out the other way the convention has
        // changed and Triangles() must stop reversing, not be left to compensate for nothing.
        Assert.Equal(0, shippedAgree);

        // The correction itself.
        Assert.Equal(0, emittedDisagree);
        Assert.True(emittedAgree > 50_000);
    }

    /// <summary>
    /// The second object reference on a polygon is its material, established by what it resolves to.
    /// </summary>
    /// <remarks>
    /// The arithmetic that settles the record's layout constrains the size of the
    /// <c>Actor</c>/<c>Material</c>/<c>ItemName</c> group but not the sequence within it, since the
    /// first reference is null everywhere. The class of the target is the discriminator — the same
    /// rule that keeps a <c>TextureRotator</c> from being bound as a texture in
    /// <c>MaterialReader</c> — and it can fail: a wrong order would resolve these to actors.
    /// </remarks>
    [RequiresGameFact]
    public void EveryMaterialAPolygonNamesResolvesToAMaterialClass()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var known = new HashSet<string>(StringComparer.Ordinal)
        {
            "Shader", "FacingShader", "FluidShader", "FluidSurfaceShader", "PlantShader",
            "LightBeamShader", "LayeredShader", "MaterialSwitch", "MaterialSequence",
            "Texture", "Cubemap", "TexEnvMap", "Combiner", "FinalBlend",
        };

        int checked_ = 0;
        foreach (var export in PolysReader.Enumerate(package))
        {
            foreach (var polygon in PolysReader.Read(package, export).Polygons)
            {
                Assert.True(polygon.Actor.IsNull,
                    $"a polygon named an Actor ({polygon.Actor}); the field order this reader assumes no longer holds");

                if (polygon.Material.IsNull) continue;
                string className = ClassOf(package, polygon.Material).Replace("import:", string.Empty);
                Assert.Contains(className, known);
                checked_++;
            }
        }

        Log($"polygons whose material resolved to a known material class: {checked_}");
        Assert.True(checked_ > 500, $"only {checked_} polygons named a material, too few to conclude from");
    }

    /// <summary>
    /// How many brush polygons carry no texture axes, and therefore have no UV at all.
    /// </summary>
    /// <remarks>
    /// A polygon's UV is <c>dot(v − Base, TextureU/V)</c>. A zero axis is not a small UV, it is no
    /// parameterisation: every vertex collapses to the same coordinate on that axis, and whatever is
    /// bound is sampled at a single texel. This was recorded as uncounted in <c>bsp.md</c> §6 —
    /// "how much of the brush set has no UV at all is unknown" — so this counts it, and counts how
    /// many of those name a material, because a polygon with no texture is entitled to no axes.
    /// </remarks>
    [RequiresGameFact]
    public void HowManyBrushPolygonsCarryNoTextureAxesIsCounted()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int polygons = 0, noU = 0, noV = 0, noneAtAll = 0, noneAndTextured = 0;
        var examples = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);

            foreach (var export in PolysReader.Enumerate(package))
            {
                foreach (var polygon in PolysReader.Read(package, export).Polygons)
                {
                    polygons++;

                    bool flatU = polygon.TextureU.LengthSquared() < 1e-12f;
                    bool flatV = polygon.TextureV.LengthSquared() < 1e-12f;
                    if (flatU) noU++;
                    if (flatV) noV++;
                    if (!flatU && !flatV) continue;

                    noneAtAll++;
                    if (!polygon.Material.IsNull)
                    {
                        noneAndTextured++;
                        if (examples.Count < 10)
                            examples.Add($"{Path.GetFileNameWithoutExtension(map)} {export.ObjectName} "
                                         + $"'{polygon.ItemName}' U {polygon.TextureU:0.##} V {polygon.TextureV:0.##}");
                    }
                }
            }
        }

        Log($"brush polygons {polygons}: {noU} with no TextureU, {noV} with no TextureV, "
            + $"{noneAtAll} missing at least one ({100.0 * noneAtAll / polygons:0.###}%), "
            + $"of which {noneAndTextured} name a material");
        foreach (string line in examples) Log("  " + line);

        Assert.True(polygons > 50_000, $"only {polygons} brush polygons were read");

        // The two axes are always absent together — a polygon never carries half a parameterisation.
        Assert.Equal(noU, noV);

        // And nothing that is textured is missing them: every one of the 17,802 names no material,
        // so the brush set has no polygon that would be drawn with a collapsed UV. This is the
        // assertion that would fail if the missing axes were a decode gap rather than content.
        Assert.Equal(0, noneAndTextured);
    }

    /// <summary>
    /// What sits at the extremes of the level's measured bounds.
    /// </summary>
    /// <remarks>
    /// The first Phase 2 measurement reported bounds reaching <c>Z = 262144</c>, which is exactly
    /// 2^18 — Unreal's <c>HALF_WORLD_MAX</c>. That makes "a placed actor happens to be there" much
    /// less likely than "something is parked at the world boundary", and an exporter that sized a
    /// scene from the raw extents would size it from a sentinel. This names what is actually there.
    /// </remarks>
    [RequiresGameFact]
    public void TheLevelsExtentIsSetByOneActorAtTheEngineWorldBoundary()
    {
        var context = LevelAnalyzer.Analyze(game.LighthousePackage);
        var placed = context.Actors.Where(a => a.Transform.Present.Contains("Location")).ToList();
        Assert.NotEmpty(placed);

        var (min, max) = LevelAnalyzer.Bounds(placed);
        Log($"bounds min {min:0.#} max {max:0.#}");

        // Unreal's world-extent constant. An actor at it is at the edge of what the engine can
        // address, which is a placement no level designer makes by hand.
        const float halfWorldMax = 262_144f;
        var atTheBoundary = placed
            .Where(a => Math.Abs(a.Transform.Location.X) >= halfWorldMax
                        || Math.Abs(a.Transform.Location.Y) >= halfWorldMax
                        || Math.Abs(a.Transform.Location.Z) >= halfWorldMax)
            .ToList();

        foreach (var actor in atTheBoundary)
            Log($"  at the boundary: {actor.Source.ClassName} {actor.Source.ObjectName} at {actor.Transform.Location:0.#}");

        Assert.Single(atTheBoundary);
        Assert.Equal("Script", atTheBoundary[0].Source.ClassName);
        Assert.Equal(halfWorldMax, atTheBoundary[0].Transform.Location.Z);

        // And the level without it is a room-sized box rather than an engine-sized one, which is the
        // fact an exporter needs: the extents are set by a sentinel, not by the playable space.
        var (_, realMax) = LevelAnalyzer.Bounds(placed.Except(atTheBoundary));
        Log($"bounds excluding the boundary actor: max {realMax:0.#}");
        Assert.True(realMax.Z < 100_000f,
            $"excluding the boundary actor the level still reaches Z {realMax.Z}, so it is not one outlier");
    }
}
