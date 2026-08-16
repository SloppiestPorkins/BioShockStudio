using System.Diagnostics;
using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// What it costs to draw a whole level, measured before anything is designed around it.
/// </summary>
/// <remarks>
/// <para>
/// The rasteriser is on the CPU and a level is 2.18 million triangles, so "can this be explored
/// interactively" is a measurement, not an opinion. The renderer projects <b>every</b> triangle
/// each frame and buckets them per band before any pixel is touched, so the cost of an off-screen
/// triangle is not zero — which means culling has to happen above the renderer, not inside it.
/// </para>
/// <para>
/// These are timings, not assertions about hardware. The only thing asserted is the <i>relationship</i>
/// the design depends on: that culling to what the camera can see is dramatically cheaper than
/// drawing everything. A threshold in milliseconds would be a test about the machine it ran on.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LevelViewportPerformanceTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    private const int Width = 960;
    private const int Height = 600;

    [RequiresGameFact]
    public void CullingToTheViewIsWhatMakesALevelDrawable()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var scene = LevelSceneBuilder.Build(package, LevelAnalyzer.Analyze(package));

        // Models are shared per asset and instances carry the transform, which is what the renderer
        // already supports for a two-rig first-person set.
        var models = new Dictionary<string, PreviewModel>(StringComparer.Ordinal);
        var instances = new List<PreviewInstance>();

        var built = Stopwatch.StartNew();
        foreach (var instance in scene.Instances)
        {
            if (!models.TryGetValue(instance.Asset.Key, out var model))
                models[instance.Asset.Key] = model = PreviewModel.Build(instance.Geometry, null);
            instances.Add(new PreviewInstance(model, null, instance.Transform));
        }
        built.Stop();

        Log($"built {models.Count} models for {instances.Count} instances in {built.ElapsedMilliseconds} ms");
        Log($"triangles {scene.TriangleCount:N0}, vertices {scene.VertexCount:N0}");

        var options = new RenderOptions { ShowSkeleton = false, ShowSockets = false, Textured = false };

        var centre = (scene.Bounds.Min + scene.Bounds.Max) * 0.5f;
        float radius = (scene.Bounds.Max - scene.Bounds.Min).Length() * 0.5f;

        // A camera STANDING INSIDE the level looking one way, which is what exploring it means —
        // and the case culling exists for. Framing the whole level from outside keeps every
        // instance by construction and measures nothing, which is what the first run of this test
        // did.
        var eye = centre;
        var look = eye + new Vector3(radius * 0.25f, 0, 0);
        var camera = new PreviewCamera
        {
            Target = look,
            Distance = (look - eye).Length(),
            Yaw = MathF.PI,
            Pitch = 0f,
        };

        // Everything.
        var all = Stopwatch.StartNew();
        SoftwareRenderer.Render(instances, camera, options, Width, Height);
        all.Stop();
        Log($"whole level, no culling: {all.ElapsedMilliseconds} ms for {instances.Count} instances");

        // Only what a frustum keeps. Bounding spheres per instance, tested against the view.
        var spheres = scene.Instances.Select(BoundingSphere).ToList();

        var culled = new List<PreviewInstance>();
        var cull = Stopwatch.StartNew();
        var viewProjection = ViewProjection(camera, radius);
        for (int i = 0; i < instances.Count; i++)
            if (Visible(spheres[i], viewProjection)) culled.Add(instances[i]);
        cull.Stop();

        int culledTriangles = 0;
        for (int i = 0; i < instances.Count; i++)
            if (Visible(spheres[i], viewProjection)) culledTriangles += scene.Instances[i].Geometry.TriangleCount;

        var drawn = Stopwatch.StartNew();
        SoftwareRenderer.Render(culled, camera, options, Width, Height);
        drawn.Stop();

        Log($"culling took {cull.ElapsedMilliseconds} ms and kept {culled.Count} of {instances.Count} instances "
            + $"({culledTriangles:N0} triangles)");
        Log($"culled draw: {drawn.ElapsedMilliseconds} ms");

        // Frustum culling alone is not enough — it keeps 883k triangles, because Rapture's backdrop
        // city is entirely in view and is most of the map's geometry. What actually bounds the
        // frame is a TRIANGLE BUDGET: sort what survives the frustum by how much of the screen it
        // can occupy (radius over distance) and take the most important until the budget is spent.
        // That degrades by dropping the least visible thing rather than by slowing down.
        var ranked = new List<(PreviewInstance Instance, int Triangles, float Importance)>();
        for (int i = 0; i < instances.Count; i++)
        {
            if (!Visible(spheres[i], viewProjection)) continue;
            float distance = MathF.Max(1f, Vector3.Distance(spheres[i].Centre, camera.Eye));
            ranked.Add((instances[i], scene.Instances[i].Geometry.TriangleCount, spheres[i].Radius / distance));
        }
        ranked.Sort((a, b) => b.Importance.CompareTo(a.Importance));

        foreach (int budget in new[] { 100_000, 250_000, 500_000 })
        {
            var kept = new List<PreviewInstance>();
            int total = 0;
            foreach (var (instance, triangles, _) in ranked)
            {
                if (total + triangles > budget && kept.Count > 0) continue;
                kept.Add(instance);
                total += triangles;
            }

            foreach (var (size, w, h) in new[] { ("full", Width, Height), ("half", Width / 2, Height / 2) })
            {
                var timer = Stopwatch.StartNew();
                SoftwareRenderer.Render(kept, camera, options, w, h);
                timer.Stop();
                Log($"budget {budget:N0} at {size} ({w}x{h}): {kept.Count} instances, {total:N0} triangles, "
                    + $"{timer.ElapsedMilliseconds} ms");
            }
        }

        // The relationship the viewport design rests on. Not a millisecond threshold — that would be
        // a test about this machine — but that culling is a real reduction rather than a rounding.
        Assert.True(culled.Count < instances.Count,
            "the frustum kept every instance, so this measurement says nothing");
        Assert.True(cull.ElapsedMilliseconds * 10 < all.ElapsedMilliseconds,
            $"culling ({cull.ElapsedMilliseconds} ms) costs a meaningful fraction of just drawing "
            + $"everything ({all.ElapsedMilliseconds} ms), so it is not worth doing");
    }

    private static (Vector3 Centre, float Radius) BoundingSphere(LevelInstance instance)
    {
        var min = new Vector3(float.MaxValue);
        var max = new Vector3(float.MinValue);
        foreach (var vertex in instance.Geometry.Vertices)
        {
            var world = Vector3.Transform(vertex.Position, instance.Transform);
            min = Vector3.Min(min, world);
            max = Vector3.Max(max, world);
        }
        var centre = (min + max) * 0.5f;
        return (centre, (max - min).Length() * 0.5f);
    }

    private static Matrix4x4 ViewProjection(PreviewCamera camera, float radius)
    {
        var view = Matrix4x4.CreateLookAt(camera.Eye, camera.Target, Vector3.UnitZ);
        var projection = Matrix4x4.CreatePerspectiveFieldOfView(
            camera.FieldOfView, (float)Width / Height, MathF.Max(1f, radius * 0.001f), radius * 8f);
        return view * projection;
    }

    /// <summary>Whether a sphere is inside the frustum, tested against its six planes.</summary>
    private static bool Visible((Vector3 Centre, float Radius) sphere, Matrix4x4 viewProjection)
    {
        // The frustum planes fall out of the rows of the view-projection matrix.
        Span<Vector4> planes =
        [
            new(viewProjection.M14 + viewProjection.M11, viewProjection.M24 + viewProjection.M21, viewProjection.M34 + viewProjection.M31, viewProjection.M44 + viewProjection.M41),
            new(viewProjection.M14 - viewProjection.M11, viewProjection.M24 - viewProjection.M21, viewProjection.M34 - viewProjection.M31, viewProjection.M44 - viewProjection.M41),
            new(viewProjection.M14 + viewProjection.M12, viewProjection.M24 + viewProjection.M22, viewProjection.M34 + viewProjection.M32, viewProjection.M44 + viewProjection.M42),
            new(viewProjection.M14 - viewProjection.M12, viewProjection.M24 - viewProjection.M22, viewProjection.M34 - viewProjection.M32, viewProjection.M44 - viewProjection.M42),
            new(viewProjection.M13, viewProjection.M23, viewProjection.M33, viewProjection.M43),
            new(viewProjection.M14 - viewProjection.M13, viewProjection.M24 - viewProjection.M23, viewProjection.M34 - viewProjection.M33, viewProjection.M44 - viewProjection.M43),
        ];

        foreach (var plane in planes)
        {
            var normal = new Vector3(plane.X, plane.Y, plane.Z);
            float length = normal.Length();
            if (length < 1e-9f) continue;
            if ((Vector3.Dot(normal, sphere.Centre) + plane.W) / length < -sphere.Radius) return false;
        }

        return true;
    }
}
