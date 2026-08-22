using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Every drawn compiled-world surface, followed down the material chain: does it name a material,
/// does that material resolve, and does the resolved material bind a base colour?
/// </summary>
/// <remarks>
/// <para>
/// <b>Gate 0 item 2 says to resolve the remaining blocky/flat BSP surfaces "as material/shader-chain
/// failures, not by shrinking UVs or tinting base colour". This measures that chain.</b> The only
/// coverage that existed was <c>LevelTextureTests</c> — one map, asserting that more than <i>half</i>
/// its surfaces bind a texture, which cannot tell a healthy level from one that has quietly lost a
/// fifth of its paint.
/// </para>
/// <para>
/// <b>Deliberately stops at the material, not the decoded pixels.</b> An earlier version of this
/// census went through <see cref="LevelViewportService"/> and therefore decoded every texture in
/// every map: 18 GB of memory and over twenty minutes, which is exactly the kind of test that stops
/// being run. The question item 2 asks is about the chain — reference to material to bound texture —
/// and the chain can be walked without turning any of it into pixels. Whether the pixels then decode
/// is a texture question, already covered by the texture diagnostics and by
/// <c>LevelTextureTests</c>'s end-to-end check; whether the geometry reaches the screen at all is
/// <c>BspWorldCoverageTests</c>.
/// </para>
/// <para>
/// <b>Compiled world only.</b> The source brushes are CSG input that the viewer also draws, and
/// <c>docs/research/bsp.md</c> already establishes that 17,802 of 93,264 brush polygons carry
/// neither texture axes nor a material — content, not a decode gap. Pooling the two hides whichever
/// is actually at fault.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BspSurfaceCensusTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void TheCompiledWorldsMaterialChainIsCensused()
    {
        // Registered exactly as the application does before it draws anything
        // (MainViewModel.OpenInstall). Without it ExternalMaterials is null and every material named
        // by an import resolves to nothing, so the census would measure a worse level than the app
        // draws — which is how the first run of this test reported no change from a fix that works.
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        var external = catalog.ExternalMaterials;
        Assert.NotNull(external);

        long polygons = 0, namedNothing = 0, byExport = 0, byImport = 0;
        long unresolved = 0, noBaseColour = 0, noBaseColourByDesign = 0, withBaseColour = 0;
        int mapsRead = 0;
        var perMap = new List<string>();

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(map);
            var built = ModelReader.BuiltWorld(package);
            if (built is null) continue;

            BspWorld? world;
            try { world = BspWorldReader.Read(package, package.Exports[built.Source.ExportIndex]); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (world is null || world.PolygonCount == 0) continue;

            mapsRead++;
            long mapPolygons = 0, mapUnresolved = 0, mapNoColour = 0, mapImports = 0;

            // One decode per distinct reference: a map names a few hundred materials across tens of
            // thousands of polygons.
            var resolved = new Dictionary<int, BioShockMaterial?>();

            foreach (var node in world.Nodes)
            {
                if (!node.IsPolygon) continue;
                if (node.Surface < 0 || node.Surface >= world.Surfaces.Count) continue;
                var surface = world.Surfaces[node.Surface];
                if (!surface.IsDrawn) continue;

                polygons++;
                mapPolygons++;

                var reference = surface.Material;
                if (reference.IsNull) { namedNothing++; continue; }
                if (reference.IsExport) byExport++; else { byImport++; mapImports++; }

                if (!resolved.TryGetValue(reference.Value, out var material))
                    resolved[reference.Value] = material = Resolve(package, reference, external);

                if (material is null) { unresolved++; mapUnresolved++; continue; }

                if (material.DiffuseTexture is { Length: > 0 }) { withBaseColour++; continue; }

                if (UnpaintedMaterials.HasNoBaseColourByDesign(material.ClassName)) noBaseColourByDesign++;
                else { noBaseColour++; mapNoColour++; }
            }

            perMap.Add($"  {Path.GetFileNameWithoutExtension(map),-24} {mapPolygons,6:N0} drawn, "
                       + $"{mapImports,5:N0} by import, {mapUnresolved,5:N0} unresolved, "
                       + $"{mapNoColour,5:N0} no base colour");
        }

        Log($"compiled-world material chain: {mapsRead} maps, {polygons:N0} drawn polygons");
        Log($"  reference:  {namedNothing:N0} name nothing, {byExport:N0} by export, {byImport:N0} by import");
        Log($"  resolution: {unresolved:N0} unresolved");
        Log($"  colour:     {withBaseColour:N0} bind a base colour, "
            + $"{noBaseColourByDesign:N0} unpainted by design, {noBaseColour:N0} neither");
        foreach (string line in perMap) Log(line);

        // Coverage before conclusions: an empty census must not read as a clean bill of health.
        Assert.True(mapsRead >= 20, $"only {mapsRead} compiled worlds were read");
        Assert.True(polygons > 50_000, $"only {polygons} drawn polygons were examined");

        // What the measurements established, as assertions that can fail.
        //
        // Not one drawn compiled-world surface in the shipped game omits its material — so a grey
        // BSP surface is always this project failing to follow a reference that is present, never
        // absent data. That is the opposite of the source brushes, where 17,802 polygons genuinely
        // name nothing, and it is why item 2's "material-chain failure" framing was the right one.
        Assert.Equal(0, namedNothing);

        // Imports are a real and substantial part of that population, which is what makes the
        // external lookup load-bearing rather than a nicety.
        Assert.True(byImport > 1_000,
            $"only {byImport} drawn polygons name their material by import, so this census would not "
            + "notice the external lookup regressing");

        // Every reference resolves — by export or by import. Before the BSP path gained the same
        // IExternalMaterialSource branch the mesh path already had, every imported reference
        // resolved to null and drew untextured.
        Assert.Equal(0, unresolved);
    }

    /// <summary>
    /// The same question asked of the <b>application's own path</b>, on one map, so the census above
    /// is not merely marking its own homework.
    /// </summary>
    /// <remarks>
    /// <b>The census walks the chain with its own copy of the resolution rule, which proves the rule
    /// and not the wiring.</b> A private helper in <see cref="LevelViewportService"/> could still be
    /// unreachable, called with the wrong list, or fed a material list that dropped its imports
    /// before it got there — and every assertion above would stay green. This drives
    /// <c>Prepare</c> exactly as the application does and asserts the compiled world's surfaces come
    /// back naming materials. One map, because this path decodes textures and the whole game costs
    /// twenty minutes and 18 GB.
    /// </remarks>
    /// <remarks>
    /// <b><c>1-Medical</c>, not <c>0-Lighthouse</c>, and the choice is the point.</b> This was first
    /// written against the Lighthouse — the fixture's default map, and the one every other level test
    /// uses — where it passed. It would have passed before the fix too: the Lighthouse's compiled
    /// world names almost nothing by import, so it cannot exercise the branch under test at all.
    /// <c>1-Medical</c> carries 248 imported references. Picking the convenient map is how a test
    /// ends up asserting something true and irrelevant.
    /// </remarks>
    [RequiresGameFact]
    public void TheApplicationsOwnPathResolvesTheCompiledWorldsMaterials()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        string map = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        var level = new LevelViewportService(catalog).Prepare(map);

        var surfaces = level.Viewport.Items
            .Where(i => i.Kind == LevelGeometryKind.BuiltWorld)
            .SelectMany(i => i.Model.Surfaces)
            .ToList();

        int named = surfaces.Count(s => s.MaterialName is not null);
        int textured = surfaces.Count(s => s.Texture is not null);

        Log($"{level.Scene.PackageName} compiled world through the app's path: {surfaces.Count} surfaces, "
            + $"{named} name a material, {textured} carry a decoded texture");

        Assert.NotEmpty(surfaces);

        // Every compiled-world surface in the shipped game names a material (asserted above over all
        // 21 maps), so every surface the app builds must come back with one. A null here means the
        // reference was lost between the BSP and the resolver — which is exactly what happened to
        // imports before the BSP path gained the external lookup.
        Assert.Equal(surfaces.Count, named);
    }

    private static BioShockMaterial? Resolve(
        BioShockPackage package, PackageIndex reference, IExternalMaterialSource? external)
    {
        try
        {
            if (reference.IsExport)
                return MaterialReader.Read(package, package.Exports[reference.ExportIndex]);

            if (external is not null && reference.IsImport)
            {
                var import = package.Imports[reference.ImportIndex];
                var outer = import.Outer;
                string group =
                    outer.IsImport && outer.ImportIndex < package.Imports.Count
                        ? package.Imports[outer.ImportIndex].ObjectName
                        : outer.IsExport && outer.ExportIndex < package.Exports.Count
                            ? package.Exports[outer.ExportIndex].ObjectName
                            : string.Empty;
                return external.Find(import.ObjectName, group);
            }
        }
        catch (Exception ex) when (ex is IOException or InvalidDataException
                                       or ArgumentOutOfRangeException or IndexOutOfRangeException)
        {
        }

        return null;
    }
}
