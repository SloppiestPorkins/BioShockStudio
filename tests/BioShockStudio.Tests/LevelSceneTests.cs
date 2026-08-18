using System.Numerics;
using System.Text.Json;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Mesh;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Assembling a whole map into a scene, and writing it out.
/// </summary>
/// <remarks>
/// Before this there was no consumer for a <see cref="LevelContext"/> in any form — the actor list
/// resolved and went nowhere. These read a shipped map end to end.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LevelSceneTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    private static LevelScene Build(string package)
    {
        using var open = BioShockPackage.Open(package);
        return LevelSceneBuilder.Build(open, LevelAnalyzer.Analyze(open));
    }

    [RequiresGameFact]
    public void AShippedMapAssemblesIntoAScene()
    {
        var scene = Build(game.LighthousePackage);

        Log($"{scene.PackageName}: {scene.Instances.Count} instances, {scene.TriangleCount} triangles, "
            + $"{scene.VertexCount} vertices, {scene.Lights.Count} lights, {scene.Skipped.Count} skipped");
        Log($"  brushes {scene.Brushes.Count()}, meshes {scene.Meshes.Count()}");
        Log($"  bounds {scene.Bounds.Min:0.#} .. {scene.Bounds.Max:0.#}");

        Assert.NotEmpty(scene.Instances);
        Assert.NotEmpty(scene.Lights);
        Assert.True(scene.TriangleCount > 10_000, $"only {scene.TriangleCount} triangles in a whole map");

        // Both kinds of geometry reach the scene. Before the BSP work only one could.
        Assert.NotEmpty(scene.Brushes);
        Assert.NotEmpty(scene.Meshes);

        // The scene's extent is the geometry's, not the actor list's — the actor list's maximum Z is
        // set by one sentinel actor at HALF_WORLD_MAX and is twenty times too large.
        Assert.True(scene.Bounds.Max.Z < 100_000f,
            $"the scene's extent reaches Z {scene.Bounds.Max.Z}, so a sentinel is being drawn");
    }

    /// <summary>
    /// The lights decode, and their types are what Nyko's §C.6 says they are.
    /// </summary>
    /// <remarks>
    /// <para>
    /// This is the check that can fail. §C.6 states that BioShock writes <c>LightBrightness</c> and
    /// <c>LightRadius</c> as <b>floats</b> where stock UE2.5 uses bytes, and <c>LightColor</c> as a
    /// <c>Color</c> struct where UE2.5 uses two byte properties. If that were wrong — if some of
    /// these were bytes — the reader returns null rather than reading a byte as part of a float, so
    /// the count of successfully-read values is the measurement, and it is asserted to be nearly
    /// all of them rather than merely non-zero.
    /// </para>
    /// <para>
    /// The ranges are asserted too, against the medians §C.6 quotes. A wrong type that happened to
    /// parse would land far outside them.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheLightsDecodeWithTheTypesTheSdkDocuments()
    {
        var scene = Build(game.LighthousePackage);

        int withColor = scene.Lights.Count(l => l.Color is not null);
        int withBrightness = scene.Lights.Count(l => l.Brightness is not null);
        int withRadius = scene.Lights.Count(l => l.Radius is not null);

        Log($"lights {scene.Lights.Count}: colour {withColor}, brightness {withBrightness}, radius {withRadius}");
        Log("  classes: " + string.Join(", ", scene.Lights.GroupBy(l => l.ClassName)
            .OrderByDescending(g => g.Count()).Select(g => $"{g.Key}={g.Count()}")));

        var brightness = scene.Lights.Where(l => l.Brightness is not null).Select(l => l.Brightness!.Value).ToList();
        var radius = scene.Lights.Where(l => l.Radius is not null).Select(l => l.Radius!.Value).ToList();
        if (brightness.Count > 0)
            Log($"  brightness {brightness.Min():0.##}..{brightness.Max():0.##}, median {Median(brightness):0.##}");
        if (radius.Count > 0)
            Log($"  radius {radius.Min():0}..{radius.Max():0}, median {Median(radius):0}");

        Assert.True(scene.Lights.Count > 100, $"only {scene.Lights.Count} lights in a whole map");

        // What the properties are actually typed as, wherever they appear. The reader returns null
        // rather than misreading a byte as part of a float, so if any of these were NOT floats the
        // documented type would be wrong for this build and it would show up here rather than as a
        // plausible wrong number downstream.
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);
        var types = new Dictionary<string, int>(StringComparer.Ordinal);

        foreach (var property in context.Actors.SelectMany(a => a.Properties))
        {
            if (property.Name is not ("LightBrightness" or "LightRadius" or "LightColor")) continue;
            string key = $"{property.Name}:{property.Type}"
                         + (property.StructName is { } s ? $"({s})" : "")
                         + $" {property.Value.Length}B";
            types[key] = types.GetValueOrDefault(key) + 1;
        }

        foreach (var (key, count) in types.OrderByDescending(e => e.Value)) Log($"  type {key} × {count}");

        // Every occurrence of each property must carry the documented type. This is the assertion
        // that can fail: a single byte-typed LightBrightness would mean the SDK's §C.6 does not hold
        // for this build, and it would be a fact worth knowing rather than a threshold to relax.
        Assert.All(types.Keys, key => Assert.True(
            !key.StartsWith("LightBrightness", StringComparison.Ordinal) || key.Contains("Float"),
            $"LightBrightness is not always a float: {key}"));
        Assert.All(types.Keys, key => Assert.True(
            !key.StartsWith("LightRadius", StringComparison.Ordinal) || key.Contains("Float"),
            $"LightRadius is not always a float: {key}"));

        // Every actor that stores the property yields a value — no silent losses.
        Assert.Equal(context.Actors.Count(a => a.Properties.Any(p => p.Name == "LightBrightness")), withBrightness);
        Assert.Equal(context.Actors.Count(a => a.Properties.Any(p => p.Name == "LightRadius")), withRadius);
        Assert.Equal(context.Actors.Count(a => a.Properties.Any(p => p.Name == "LightColor")), withColor);

        // The ranges §C.6 quotes. A field read at the wrong offset or type lands nowhere near these.
        Assert.All(brightness, b => Assert.InRange(b, 0f, 100f));
        Assert.All(radius, r => Assert.InRange(r, 0f, 200_000f));
    }

    /// <summary>
    /// No level instance carries a non-uniform scale, which is what lets the OBJ writer transform
    /// normals by the instance matrix rather than by its inverse transpose.
    /// </summary>
    /// <remarks>
    /// An assumption stated in a comment is worth nothing; this is the same assumption stated as a
    /// check that fails if the game disagrees. Recording the count of scaled actors matters as much
    /// as the pass — if it were zero, the check would be passing vacuously.
    /// </remarks>
    [RequiresGameFact]
    public void NoLevelInstanceCarriesANonUniformScale()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);

        int scaled = 0, rotated = 0, nonUniform = 0;

        foreach (var actor in context.Actors)
        {
            var scale = actor.Transform.Scale;
            if (scale != Vector3.One) scaled++;
            if (!actor.Transform.Rotation.IsIdentity) rotated++;

            if (Math.Abs(scale.X - scale.Y) > 1e-4f || Math.Abs(scale.Y - scale.Z) > 1e-4f)
            {
                nonUniform++;
                if (nonUniform <= 5) Log($"  non-uniform scale: {actor.Source} {scale:0.###}");
            }
        }

        Log($"actors: {scaled} scaled, {rotated} rotated, {nonUniform} non-uniformly scaled");

        // Not vacuous: plenty of actors are rotated and scaled, so the transform path is exercised.
        Assert.True(rotated > 100, $"only {rotated} actors are rotated; this check would prove little");
        Assert.Equal(0, nonUniform);
    }

    /// <summary>
    /// How much of a brush actor's transform is actually exercised.
    /// </summary>
    /// <remarks>
    /// <see cref="LevelSceneBuilder.BrushPlacement"/> places a brush by
    /// <c>Location − PrePivot</c> with no rotation or scale, and that is labelled <c>LIKELY</c>. This
    /// does not assert the rule is right — it records how much evidence there could be. If almost no
    /// brush actor is rotated, then "the level assembles correctly" is weak evidence for the
    /// composition order, and a future session should know that rather than infer confidence from a
    /// green test.
    /// </remarks>
    [RequiresGameFact]
    public void HowManyBrushActorsCarryARotationOrScaleIsRecorded()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);

        var brushes = context.Brushes.ToList();
        int rotated = brushes.Count(a => !a.Transform.Rotation.IsIdentity);
        int scaled = brushes.Count(a => a.Transform.Scale != Vector3.One);
        int prePivoted = brushes.Count(a => a.Transform.PrePivot != Vector3.Zero);

        Log($"brush actors {brushes.Count}: {rotated} rotated, {scaled} scaled, {prePivoted} with a PrePivot");

        Assert.NotEmpty(brushes);
    }

    /// <summary>
    /// Every shipped map, swept for a brush actor that carries a rotation or a scale.
    /// </summary>
    /// <remarks>
    /// The Lighthouse census above says 0 of that map's 230 brush actors is rotated or scaled, which
    /// is why <see cref="LevelSceneBuilder.BrushPlacement"/> is barely exercised. One rotated brush
    /// anywhere in the game is the sample that would settle the composition order, so this asks the
    /// whole game rather than the one map, and logs the map, actor and rotation of anything it finds.
    /// </remarks>
    [RequiresGameFact]
    public void EveryMapIsSweptForABrushActorThatIsRotatedOrScaled()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
            .OrderBy(f => f, StringComparer.Ordinal).ToList();

        int brushes = 0, rotated = 0, scaled = 0, prePivoted = 0;
        var found = new List<string>();
        var classes = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var context = LevelAnalyzer.Analyze(package);

            var mapBrushes = context.Brushes.ToList();
            int mapRotated = 0, mapScaled = 0;

            foreach (var actor in mapBrushes)
            {
                bool isRotated = !actor.Transform.Rotation.IsIdentity;
                bool isScaled = actor.Transform.Scale != Vector3.One;

                if (isRotated) mapRotated++;
                if (isScaled) mapScaled++;
                if (actor.Transform.PrePivot != Vector3.Zero) prePivoted++;

                if (isRotated || isScaled)
                {
                    found.Add($"{Path.GetFileNameWithoutExtension(map)} {actor.Source.ObjectName}: "
                              + $"{actor.Transform}");
                    classes.Add(actor.Source.ClassName);
                }
            }

            brushes += mapBrushes.Count;
            rotated += mapRotated;
            scaled += mapScaled;

            Log($"{Path.GetFileNameWithoutExtension(map),-20} brushes {mapBrushes.Count,5}, "
                + $"rotated {mapRotated,4}, scaled {mapScaled,4}");
        }

        Log($"ALL MAPS: {maps.Count} maps, {brushes} brush actors, {rotated} rotated, {scaled} scaled, "
            + $"{prePivoted} with a PrePivot");
        foreach (string line in found.Take(40)) Log("  " + line);

        // Not vacuous: the sweep has to have read a real population of brushes for its answer to
        // mean anything.
        Assert.True(maps.Count >= 20, $"only {maps.Count} maps were swept");
        Assert.True(brushes > 1_000, $"only {brushes} brush actors across the whole game");

        // The answer, as an assertion that can fail. No brush actor in the shipped game is scaled,
        // and every rotated one is a VOLUME — a gameplay region, never drawn — so no visible brush
        // anywhere exercises the rotation or scale part of the placement rule. A future session
        // that finds this red has found the sample that would settle it.
        Assert.Equal(0, scaled);
        Assert.All(classes, name => Assert.EndsWith("Volume", name, StringComparison.Ordinal));
        Assert.True(rotated > 0, "no brush actor is rotated at all, so even the volumes stopped being read");
    }

    /// <summary>
    /// The Medical Pavilion ceiling arch: four instances that must assemble into one continuous
    /// barrel vault, not a twisted seam.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A user reported this exact arch rendering broken — two panels meeting at a diagonal, self-
    /// intersecting seam instead of a smooth curve. The cause was a sign error on pitch in
    /// <see cref="UnrealRotator.ToQuaternion"/>: with the old <c>+pitch</c>, these four instances
    /// (<c>pitch = −90°</c>, <c>roll</c> alternating <c>0°</c>/<c>±180°</c>) produced exactly that
    /// twisted shape. Numerically matching this project's quaternion against the reference level
    /// editor's own matrix construction found the fix — negate pitch — and this asserts the visible
    /// consequence: the four instances now form one continuous surface.
    /// </para>
    /// <para>
    /// <b>The check is geometric, not a picture.</b> Each instance's four corner vertices are placed
    /// in world space and the two nearest corners between every pair of instances must coincide —
    /// which a barrel vault's abutting edges do and two panels meeting at a wrong diagonal do not.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheMedicalPavilionCeilingArchFormsOneContinuousSurface()
    {
        using var package = BioShockPackage.Open(
            Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));
        var context = LevelAnalyzer.Analyze(package);

        var actors = context.WithStaticMesh
            .Where(a => a.StaticMesh?.Source?.ObjectName == "window_512_corner_4up")
            .ToList();

        Assert.True(actors.Count >= 4, $"only {actors.Count} window_512_corner_4up actors found");

        var geometry = StaticMeshReader.ReadGeometry(
            package.ReadExportData(package.Exports[actors[0].StaticMesh!.Source!.Value.ExportIndex]));
        Assert.NotNull(geometry);

        var worldPoints = new List<Vector3>();
        var perInstanceExtents = new List<float>();

        foreach (var actor in actors)
        {
            var placement = LevelSceneBuilder.MeshPlacement(actor.Transform);
            var points = geometry!.Vertices.Select(v => Vector3.Transform(v.Position, placement)).ToList();
            worldPoints.AddRange(points);

            var min = points.Aggregate(new Vector3(float.MaxValue), Vector3.Min);
            var max = points.Aggregate(new Vector3(float.MinValue), Vector3.Max);
            perInstanceExtents.Add(Vector3.Distance(min, max));
        }

        var groupMin = worldPoints.Aggregate(new Vector3(float.MaxValue), Vector3.Min);
        var groupMax = worldPoints.Aggregate(new Vector3(float.MinValue), Vector3.Max);
        float combinedDiagonal = Vector3.Distance(groupMin, groupMax);

        Log($"ceiling arch: {actors.Count} instances, combined bounding diagonal {combinedDiagonal:0.#}, "
            + $"per-instance diagonal {perInstanceExtents.Average():0.#}");

        // A single instance's own size is a property of the mesh and does not change with its
        // placement (measured: 1310.4 either way). What changes is how the four assemble: correctly
        // placed, they form one continuous barrel vault and the group's own diagonal is a little
        // over twice one instance's — 2422 units measured. Twisted apart, one instance scatters
        // away from the rest and the group diagonal nearly doubles again, to 4295.
        Assert.True(combinedDiagonal < 3000f,
            $"the four instances span {combinedDiagonal:0} units total against "
            + $"{perInstanceExtents.Average():0} for one instance alone, so they are not assembling "
            + "into one continuous surface");
    }

    [RequiresGameFact]
    public void TheSceneWritesJsonAndObjThatReadBack()
    {
        var scene = Build(game.LighthousePackage);
        string directory = Path.Combine(Path.GetTempPath(), "bioshock-level-" + Guid.NewGuid().ToString("N"));

        try
        {
            var written = LevelSceneExporter.Write(scene, directory);
            Assert.Equal(2, written.Count);
            Assert.All(written, path => Assert.True(new FileInfo(path).Length > 1024, $"{path} is tiny"));

            string json = File.ReadAllText(written.First(p => p.EndsWith(".json", StringComparison.Ordinal)));
            var document = JsonSerializer.Deserialize<LevelDocument>(
                json, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase })!;

            Assert.Equal(scene.PackageName, document.Package);
            Assert.Equal(scene.Instances.Count, document.Instances.Count);
            Assert.Equal(scene.Lights.Count, document.Lights.Count);

            // Instancing is preserved: far fewer distinct assets than placements, which is the whole
            // reason the JSON exists beside the OBJ.
            Assert.True(document.Assets.Count < document.Instances.Count,
                "the scene JSON baked every instance instead of instancing them");
            Log($"scene JSON: {document.Assets.Count} assets for {document.Instances.Count} instances");

            // The OBJ is checked by counting its faces against the scene, not by trusting the writer.
            string obj = File.ReadAllText(written.First(p => p.EndsWith(".obj", StringComparison.Ordinal)));
            int faces = obj.Split('\n').Count(line => line.StartsWith("f ", StringComparison.Ordinal));
            int vertices = obj.Split('\n').Count(line => line.StartsWith("v ", StringComparison.Ordinal));
            Log($"OBJ: {vertices} vertices, {faces} faces, {new FileInfo(written[1]).Length / 1024 / 1024} MB");

            Assert.Equal(scene.TriangleCount, faces);
            Assert.Equal(scene.VertexCount, vertices);

            // Every face index must be within the file's own vertex list. An off-by-one in the
            // running offset produces a file that opens and is wrong, and this is what catches it.
            int maxIndex = 0;
            foreach (string line in obj.Split('\n'))
            {
                if (!line.StartsWith("f ", StringComparison.Ordinal)) continue;
                foreach (string part in line[2..].Split(' ', StringSplitOptions.RemoveEmptyEntries))
                    maxIndex = Math.Max(maxIndex, int.Parse(part));
            }
            Assert.Equal(vertices, maxIndex);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    private static float Median(List<float> values)
    {
        var sorted = values.OrderBy(v => v).ToList();
        return sorted[sorted.Count / 2];
    }
}
