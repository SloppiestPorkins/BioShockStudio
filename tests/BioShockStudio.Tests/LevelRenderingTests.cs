using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Drawing a whole assembled level.
/// </summary>
/// <remarks>
/// <para>
/// <b>This is the evidence <c>ActorTransform.ToMatrix</c> has been waiting for.</b> That method
/// composes pre-pivot, scale, rotation and translation in Unreal's order and is labelled
/// <c>LIKELY</c> in its own remarks — "inherited rather than inferred from BioShock's bytes … not
/// yet checked against a rendered level, which is the evidence that would raise it to CONFIRMED".
/// A level is the first thing this project has built that composes actor transforms at all.
/// </para>
/// <para>
/// <c>BIOSHOCK_LEVEL_SNAPSHOT=/tmp/level.png</c> writes the images out.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LevelRenderingTests(GameFixture game)
{
    private const int Width = 900;
    private const int Height = 600;

    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    private static void Snapshot(PreviewImage image, string suffix)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_LEVEL_SNAPSHOT") is not { Length: > 0 } path) return;
        string directory = Path.GetDirectoryName(path) ?? ".";
        Directory.CreateDirectory(directory);
        PngWriter.Write(
            Path.Combine(directory, $"{Path.GetFileNameWithoutExtension(path)}_{suffix}.png"),
            image.Rgba, image.Width, image.Height);
    }

    /// <summary>
    /// Flattens a scene into one mesh in world space, which is what the preview rasteriser draws.
    /// </summary>
    /// <remarks>
    /// Baking is right here and wrong in the exporter: the rasteriser has no instancing, and a
    /// picture is a one-off. <see cref="Core.Export.LevelSceneExporter"/> keeps the instancing.
    /// </remarks>
    private static MeshGeometry Flatten(LevelScene scene, Func<LevelInstance, bool>? filter = null)
    {
        var vertices = new List<MeshVertex>();
        var indices = new List<int>();

        foreach (var instance in scene.Instances)
        {
            if (filter is not null && !filter(instance)) continue;

            int start = vertices.Count;
            foreach (var vertex in instance.Geometry.Vertices)
            {
                vertices.Add(vertex with
                {
                    Position = Vector3.Transform(vertex.Position, instance.Transform),
                    Normal = Vector3.TransformNormal(vertex.Normal, instance.Transform),
                });
            }
            foreach (int index in instance.Geometry.Indices) indices.Add(start + index);
        }

        return new MeshGeometry
        {
            Vertices = vertices,
            Indices = indices,
            BoneMap = [],
            SkinnedVertexCount = 0,
            RigidVertexCount = vertices.Count,
        };
    }

    private static LevelScene Build(string package)
    {
        using var open = BioShockPackage.Open(package);
        return LevelSceneBuilder.Build(open, LevelAnalyzer.Analyze(open));
    }

    private static double Coverage(PreviewImage image, byte background = 32)
    {
        int drawn = 0;
        for (int i = 0; i < image.Rgba.Length; i += 4)
        {
            if (image.Rgba[i] != background || image.Rgba[i + 1] != background || image.Rgba[i + 2] != background)
                drawn++;
        }
        return (double)drawn / (image.Width * image.Height);
    }

    [RequiresGameFact]
    public void AWholeLevelDraws()
    {
        var scene = Build(game.LighthousePackage);

        foreach (var (name, filter) in new (string, Func<LevelInstance, bool>?)[]
                 {
                     ("all", null),
                     ("brushes", i => i.Kind == LevelGeometryKind.Brush),
                     ("meshes", i => i.Kind != LevelGeometryKind.Brush),
                 })
        {
            var geometry = Flatten(scene, filter);
            var model = PreviewModel.Build(geometry, null);

            foreach (float angle in new[] { 0.6f, 2.2f })
            {
                var image = SoftwareRenderer.Render(
                    model,
                    PreviewCamera.Frame(model.Centre, model.Radius).Orbit(angle, 0.45f),
                    new RenderOptions { ShowSkeleton = false, ShowSockets = false },
                    Width, Height);

                Snapshot(image, $"{name}_{angle:0.0}");
                double coverage = Coverage(image);
                Log($"{name} at {angle:0.0}: {geometry.TriangleCount} triangles, coverage {coverage:P1}");
                Assert.True(coverage > 0.02, $"the {name} view drew almost nothing ({coverage:P2})");
            }
        }
    }

    /// <summary>
    /// The level's brushes assemble into a connected space rather than a heap at the origin.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The check that can fail, and the one a picture cannot make precisely. If
    /// <see cref="LevelSceneBuilder.BrushPlacement"/> were wrong — if the placement ignored the
    /// actor's location, say — every brush would sit on top of every other at the origin, and the
    /// distribution of brush centres would collapse. So this measures the spread of the placed
    /// brushes against the spread of the actor locations they came from: they have to agree.
    /// </para>
    /// <para>
    /// <b>It is deliberately a comparison, not a threshold.</b> A hardcoded "the level is at least N
    /// units across" would pass on a wrong rule that happened to scatter things.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void ThePlacedBrushesSpanTheSameSpaceAsTheirActors()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = LevelAnalyzer.Analyze(package);
        var scene = LevelSceneBuilder.Build(package, context);

        var brushInstances = scene.Brushes.ToList();
        Assert.NotEmpty(brushInstances);

        // Where the actors say the brushes are.
        var actorPositions = context.Brushes
            .Where(a => a.Transform.Present.Contains("Location"))
            .Select(a => Core.Coordinates.GameBasis.Convert(a.Transform.Location))
            .ToList();

        // Where the placed geometry actually ended up.
        var placedCentres = brushInstances
            .Select(i =>
            {
                var sum = Vector3.Zero;
                foreach (var v in i.Geometry.Vertices) sum += Vector3.Transform(v.Position, i.Transform);
                return sum / i.Geometry.Vertices.Count;
            })
            .ToList();

        var actorExtent = Extent(actorPositions);
        var placedExtent = Extent(placedCentres);

        Log($"brush actor extent {actorExtent:0.#}, placed brush extent {placedExtent:0.#}");

        // The placed geometry must span the same order of space as the actors that placed it. A
        // brush is up to a few thousand units across, so the two extents differ a little; a factor
        // of two either way would mean the placement rule is not carrying the location.
        Assert.True(placedExtent.Length() > actorExtent.Length() * 0.5,
            $"the placed brushes span {placedExtent.Length():0} against the actors' {actorExtent.Length():0} — "
            + "the placement is collapsing them");
        Assert.True(placedExtent.Length() < actorExtent.Length() * 2.0,
            $"the placed brushes span {placedExtent.Length():0} against the actors' {actorExtent.Length():0} — "
            + "the placement is scattering them");

        static Vector3 Extent(List<Vector3> points)
        {
            var min = new Vector3(float.MaxValue);
            var max = new Vector3(float.MinValue);
            foreach (var p in points) { min = Vector3.Min(min, p); max = Vector3.Max(max, p); }
            return max - min;
        }
    }
}
