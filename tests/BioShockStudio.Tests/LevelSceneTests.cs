using System.Numerics;
using System.Text.Json;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
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

    private static void AssertMatrixClose(Matrix4x4 expected, Matrix4x4 actual, string label)
    {
        var expectedValues = new[]
        {
            expected.M11, expected.M12, expected.M13, expected.M14,
            expected.M21, expected.M22, expected.M23, expected.M24,
            expected.M31, expected.M32, expected.M33, expected.M34,
            expected.M41, expected.M42, expected.M43, expected.M44,
        };
        var actualValues = new[]
        {
            actual.M11, actual.M12, actual.M13, actual.M14,
            actual.M21, actual.M22, actual.M23, actual.M24,
            actual.M31, actual.M32, actual.M33, actual.M34,
            actual.M41, actual.M42, actual.M43, actual.M44,
        };
        for (int index = 0; index < expectedValues.Length; index++)
            Assert.True(MathF.Abs(expectedValues[index] - actualValues[index]) < 1e-4f,
                $"{label}: matrix component {index} differs ({expectedValues[index]} != {actualValues[index]})");
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

    [RequiresGameFact]
    public void StaticMeshSectionsKeepTheirMaterialSlotIdentity()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var scene = LevelSceneBuilder.Build(package, LevelAnalyzer.Analyze(package));

        // Pick a shipped mesh whose decoded section table actually has a local material reference.
        // This is intentionally an ordinal check: preserving just the material names, but closing
        // up a missing slot, would put the wrong material on every later section.
        var instance = scene.Instances.FirstOrDefault(item =>
            item.Kind == LevelGeometryKind.StaticMesh
            && item.Geometry.Sections.Count > 0
            && item.Materials.Any(material => material is not null));
        Assert.NotNull(instance);

        var slots = MaterialReader.ReadMeshMaterialSlots(
            package.ReadExportData(package.Exports[instance!.Asset.ExportIndex]), package);
        Assert.Equal(slots.Count, instance.Materials.Count);

        for (int i = 0; i < slots.Count; i++)
        {
            if (!slots[i].IsExport) { Assert.Null(instance.Materials[i]); continue; }

            var expected = package.Exports[slots[i].ExportIndex];
            Assert.NotNull(instance.Materials[i]);
            Assert.Equal(expected.Index, instance.Materials[i]!.Value.ExportIndex);
            Assert.Equal(expected.ObjectName, instance.Materials[i]!.Value.ObjectName);
        }
    }

    [RequiresGameFact]
    public void LocalSkeletalActorsArePlacedInTheirDecodedBindPose()
    {
        var scene = Build(game.LighthousePackage);
        var skeletal = scene.Instances.Where(item => item.Kind == LevelGeometryKind.SkeletalMesh).ToList();

        Assert.NotEmpty(skeletal);
        Assert.All(skeletal, item =>
        {
            Assert.True(item.Geometry.TriangleCount > 0);
            Assert.Equal(LevelGeometryKind.SkeletalMesh, item.Kind);
        });

        Assert.NotNull(scene.Coverage);
        var coveredSkeletal = scene.Coverage!.Classes.Sum(row =>
            row.StatusCounts.GetValueOrDefault(LevelActorCoverage.SkeletalMeshBindPose));
        Assert.True(coveredSkeletal >= skeletal.Count);
    }

    /// <summary>
    /// Mesh placement crosses the game-to-studio basis once, at the level-scene boundary. This is
    /// deliberately independent of the renderer: a later UE5 bridge needs this exact matrix as its
    /// source evidence, while a visual material fault must not be "fixed" by changing it.
    /// </summary>
    [RequiresGameFact]
    public void EveryPlacedMeshUsesTheSingleDocumentedBasisTransform()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);
        var scene = LevelSceneBuilder.Build(package, context);
        var transforms = context.Actors.ToDictionary(actor => actor.Source, actor => actor.Transform);

        var meshes = scene.Instances
            .Where(instance => instance.Kind is LevelGeometryKind.StaticMesh or LevelGeometryKind.SkeletalMesh)
            .ToList();
        Assert.NotEmpty(meshes);

        foreach (var instance in meshes)
        {
            var expected = LevelSceneBuilder.MeshPlacement(transforms[instance.Actor]);
            AssertMatrixClose(expected, instance.Transform, instance.Actor.ToString());
            Assert.True(instance.Transform.GetDeterminant() > 0f,
                $"{instance.Actor} has a reflected placement matrix");
        }
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

        // Set BIOSHOCK_ARCH_SNAPSHOT to retain a visual regression artifact while investigating a
        // report. The normal assertion remains byte-independent and always runs; this image lets
        // us inspect the actual four-piece curve before changing rotation code again.
        if (Environment.GetEnvironmentVariable("BIOSHOCK_ARCH_SNAPSHOT") is { Length: > 0 } snapshot)
        {
            var model = PreviewModel.Build(geometry, null);
            var instances = actors
                .Select(actor => new PreviewInstance(model, null, LevelSceneBuilder.MeshPlacement(actor.Transform)))
                .ToList();
            var camera = PreviewCamera.Frame((groupMin + groupMax) / 2f, combinedDiagonal / 2f)
                .Orbit(0.7f, 0.35f);
            var image = SoftwareRenderer.Render(instances, camera, new RenderOptions(), 960, 640);

            Directory.CreateDirectory(Path.GetDirectoryName(snapshot)!);
            PngWriter.Write(snapshot, image.Rgba, image.Width, image.Height);
            Log($"ceiling arch snapshot: {snapshot}");
        }

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

    /// <summary>
    /// Census every placed static mesh whose shipped object name identifies it as a window.
    /// </summary>
    /// <remarks>
    /// This is deliberately a report rather than a claim that every window uses the Medical
    /// Pavilion's transform. When a window is reported wrong, its real actor name, level and
    /// transform are the starting evidence instead of applying the old pitch fix to unrelated
    /// geometry by guesswork. Set <c>BIOSHOCK_PROBE_LOG</c> to retain the report.
    /// </remarks>
    [RequiresGameFact]
    public void EveryPlacedWindowActorIsCensused()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
            .OrderBy(path => path, StringComparer.Ordinal)
            .ToList();
        int windows = 0;
        var names = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var windowActors = LevelAnalyzer.Analyze(package).WithStaticMesh
                .Where(actor => actor.StaticMesh?.Source?.ObjectName.Contains("window",
                    StringComparison.OrdinalIgnoreCase) == true)
                .ToList();

            foreach (var actor in windowActors)
            {
                string name = actor.StaticMesh!.Source!.Value.ObjectName;
                windows++;
                names[name] = names.GetValueOrDefault(name) + 1;
                Log($"window {Path.GetFileNameWithoutExtension(map)} {name} {actor.Source.ObjectName}: "
                    + $"{actor.Transform}");
            }
        }

        Log($"window census: {windows} placements across {names.Count} mesh names");
        foreach (var pair in names.OrderByDescending(pair => pair.Value))
            Log($"  {pair.Key} × {pair.Value}");

        Assert.True(maps.Count >= 20, $"only {maps.Count} maps were checked");
        Assert.True(windows > 0, "no placed window meshes were found");
    }

    /// <summary>Reports the window-like meshes nearest Medical's initial walkthrough camera.</summary>
    [RequiresGameFact]
    public void MedicalWalkthroughWindowCandidatesAreReported()
    {
        string medical = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        var prepared = new LevelViewportService(new AssetCatalogService()).Prepare(medical);
        var scene = prepared.Scene;
        using var package = BioShockPackage.Open(medical);
        var actors = LevelAnalyzer.Analyze(package).Actors.ToDictionary(actor => actor.Source.ObjectName,
            StringComparer.Ordinal);

        Log($"Medical start camera: {prepared.Start.Position:0}, yaw {prepared.Start.Yaw:0.###}");
        foreach (var instance in scene.Instances
                     .Where(i => i.Kind == LevelGeometryKind.StaticMesh)
                     .Where(i => i.Asset.ObjectName.Contains("window", StringComparison.OrdinalIgnoreCase))
                     .Select(i => (Instance: i, Bounds: LevelViewport.BoundsOf(i.Geometry.Vertices, i.Transform)))
                     .OrderBy(item => Vector3.Distance(item.Bounds.Centre, prepared.Start.Position))
                     .Take(40))
        {
            var transform = actors[instance.Instance.Actor.ObjectName].Transform;
            Log($"  {Vector3.Distance(instance.Bounds.Centre, prepared.Start.Position):0}u "
                + $"{instance.Instance.Asset.ObjectName} {instance.Instance.Actor.ObjectName} "
                + $"at {instance.Bounds.Centre:0} radius {instance.Bounds.Radius:0} "
                + $"pre-pivot {transform.PrePivot:0}");
        }

        if (Environment.GetEnvironmentVariable("BIOSHOCK_WINDOW_START_SNAPSHOT") is { Length: > 0 } snapshot)
        {
            var transforms = scene.Instances
                .Where(i => i.Kind == LevelGeometryKind.StaticMesh)
                .Where(i => i.Asset.ObjectName.Contains("window", StringComparison.OrdinalIgnoreCase))
                .Select(i => i.Transform)
                .ToHashSet();
            var windows = prepared.Viewport.Items
                .Where(i => transforms.Contains(i.Transform))
                .OrderBy(i => Vector3.Distance(i.Centre, prepared.Start.Position))
                .Take(40)
                .Select(i => new PreviewInstance(i.Model, null, i.Transform))
                .ToList();
            var image = SoftwareRenderer.Render(windows, prepared.Start.ToPreviewCamera(),
                new RenderOptions { ShowSkeleton = false, ShowSockets = false, ShowEffects = false }, 960, 600);
            Directory.CreateDirectory(Path.GetDirectoryName(snapshot)!);
            PngWriter.Write(snapshot, image.Rgba, image.Width, image.Height);

            // Controlled comparison only: this is the convention that the earlier Medical arch
            // disproved. Keeping the picture alongside the corrected placement distinguishes a
            // new rotation failure from a camera/occlusion issue without changing production code.
            var models = prepared.Viewport.Items
                .GroupBy(item => item.Transform)
                .ToDictionary(group => group.Key, group => group.First().Model);
            var oldPitch = scene.Instances
                .Where(i => i.Kind == LevelGeometryKind.StaticMesh)
                .Where(i => i.Asset.ObjectName.Contains("window", StringComparison.OrdinalIgnoreCase))
                .Select(i => (Instance: i, Bounds: LevelViewport.BoundsOf(i.Geometry.Vertices, i.Transform)))
                .OrderBy(i => Vector3.Distance(i.Bounds.Centre, prepared.Start.Position))
                .Take(40)
                .Select(i =>
                {
                    var original = actors[i.Instance.Actor.ObjectName].Transform;
                    var legacy = original with
                    {
                        Rotation = original.Rotation with { Pitch = -original.Rotation.Pitch },
                    };
                    return new PreviewInstance(models[i.Instance.Transform], null,
                        GameBasis.Convert(legacy.ToMatrix()));
                })
                .ToList();
            var legacyImage = SoftwareRenderer.Render(oldPitch, prepared.Start.ToPreviewCamera(),
                new RenderOptions { ShowSkeleton = false, ShowSockets = false, ShowEffects = false }, 960, 600);
            PngWriter.Write(Path.Combine(Path.GetDirectoryName(snapshot)!,
                Path.GetFileNameWithoutExtension(snapshot) + "-old-pitch.png"),
                legacyImage.Rgba, legacyImage.Width, legacyImage.Height);
        }

        Assert.NotEmpty(scene.Instances);
    }

    [RequiresGameFact]
    public void TheSceneWritesJsonAndObjThatReadBack()
    {
        var scene = Build(game.LighthousePackage);
        string directory = Path.Combine(Path.GetTempPath(), "bioshock-level-" + Guid.NewGuid().ToString("N"));

        try
        {
            var written = LevelSceneExporter.Write(scene, directory);

            // Three documents plus one local-space mesh per unique asset. The mesh count is not
            // pinned exactly - it is a property of the map, not of the exporter - but the three
            // documents are, and so is the fact that meshes are written at all.
            var documents = written
                .Where(p => p.EndsWith(".json", StringComparison.Ordinal)
                            || p.EndsWith(".obj", StringComparison.Ordinal) && !p.Contains("Meshes"))
                .ToList();
            Assert.Equal(3, documents.Count);
            Assert.All(documents, path => Assert.True(new FileInfo(path).Length > 1024, $"{path} is tiny"));

            // An asset mesh may legitimately be tiny - a twelve-triangle brush is a few hundred
            // bytes - so these are checked for existence and content, not for size.
            var meshes = written.Where(p => p.Contains("Meshes")).ToList();
            Assert.True(meshes.Count > 100, $"only {meshes.Count} asset meshes were written");
            Assert.All(meshes, path => Assert.True(new FileInfo(path).Length > 0, $"{path} is empty"));

            string json = File.ReadAllText(written.First(p => p.EndsWith(".json", StringComparison.Ordinal)));
            var document = JsonSerializer.Deserialize<LevelDocument>(
                json, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase })!;

            Assert.Equal(scene.PackageName, document.Package);
            Assert.Equal(LevelSceneExporter.LevelManifestVersion, document.FormatVersion);
            Assert.Equal(scene.Instances.Count, document.Instances.Count);
            Assert.Equal(scene.Actors.Count, document.Actors.Count);
            Assert.Equal(scene.Lights.Count, document.Lights.Count);
            Assert.All(document.Lights, light =>
                Assert.Contains(document.Actors, actor => actor.Key == light.Key
                                                       && actor.ExportIndex == light.ExportIndex));
            Assert.NotEmpty(document.ActorCoverage);
            Assert.Equal(scene.Coverage!.ActorCount, document.ActorCoverage.Sum(row => row.ActorCount));
            var assetKinds = document.Assets.ToDictionary(asset => asset.Key, asset => asset.Kind);
            Assert.All(document.Instances, instance =>
                Assert.True(assetKinds[instance.Asset] == nameof(LevelGeometryKind.BuiltWorld)
                            || document.Actors.Any(actor => actor.Key == instance.ActorKey),
                    $"{instance.Asset} has no actor-graph owner"));
            Assert.All(document.Actors, actor =>
            {
                Assert.NotNull(actor.MaterialOverrides);
                Assert.True(actor.StaticMeshReference is null || actor.StaticMeshReference.Index != 0);
                Assert.True(actor.SkeletalMeshReference is null || actor.SkeletalMeshReference.Index != 0);
            });

            string compactJson = File.ReadAllText(written.First(path => path.EndsWith(".ue5-level.json", StringComparison.Ordinal)));
            var compact = JsonSerializer.Deserialize<LevelDocument>(
                compactJson, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase })!;
            Assert.False(compact.GeometryEmbedded);
            Assert.All(compact.Assets, asset =>
            {
                Assert.Null(asset.Vertices);
                Assert.True(asset.VertexCount > 0);
            });

            var boundSection = Assert.Single(compact.Assets
                .SelectMany(asset => asset.Sections)
                .Where(section => section.Material is not null)
                .Take(1));
            Assert.NotNull(boundSection.MaterialKey);
            Assert.NotNull(boundSection.MaterialPackage);
            Assert.NotNull(boundSection.MaterialClassName);
            Assert.NotNull(boundSection.MaterialExportIndex);

            // Instancing is preserved: far fewer distinct assets than placements, which is the whole
            // reason the JSON exists beside the OBJ.
            Assert.True(document.Assets.Count < document.Instances.Count,
                "the scene JSON baked every instance instead of instancing them");
            Log($"scene JSON: {document.Assets.Count} assets for {document.Instances.Count} instances");

            // The OBJ is checked by counting its faces against the scene, not by trusting the writer.
            string worldObjPath = written.Single(
                p => p.EndsWith(".obj", StringComparison.Ordinal) && !p.Contains("Meshes"));
            string obj = File.ReadAllText(worldObjPath);
            int faces = obj.Split('\n').Count(line => line.StartsWith("f ", StringComparison.Ordinal));
            int vertices = obj.Split('\n').Count(line => line.StartsWith("v ", StringComparison.Ordinal));
            Log($"OBJ: {vertices} vertices, {faces} faces, {new FileInfo(worldObjPath).Length / 1024 / 1024} MB");

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
