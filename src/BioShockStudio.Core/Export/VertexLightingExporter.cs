using System.Globalization;
using System.Numerics;
using System.Text.Json;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Export;

/// <summary>
/// Evaluates per-vertex baked lighting on static mesh actors and writes a JSON handoff.
/// </summary>
/// <remarks>
/// Shading matches <see cref="BakedLightMapExporter"/> / the SDK guide: stored luminance
/// (falloff × cone × visibility) × light colour × brightness × N·L. The bake omits N·L; this
/// exporter applies it from the mesh's authored normals and the light's location.
/// </remarks>
public static class VertexLightingExporter
{
    /// <summary>
    /// Fallback global scale when a map has no lit vertices to measure. Same role as
    /// <see cref="BakedLightMapExporter.GlobalScale"/>.
    /// </summary>
    public const float GlobalScale = BakedLightMapExporter.GlobalScale;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public sealed record InstanceExport(
        string Key,
        string Actor,
        string Mesh,
        int VertexCount,
        IReadOnlyList<string> Lights,
        float AverageR,
        float AverageG,
        float AverageB,
        IReadOnlyList<float> VerticesRgb);

    public sealed record SkippedInstance(string Actor, string Reason);

    public sealed record ExportSummary(
        string Package,
        float Scale,
        bool AppliesNDotL,
        string LuminanceLayout,
        int InstanceCount,
        int LitInstanceCount,
        int PoolBase,
        IReadOnlyList<InstanceExport> Instances,
        IReadOnlyList<SkippedInstance> Skipped);

    public sealed record ExportResult(ExportSummary Summary, string Path);

    /// <summary>Exports evaluated per-vertex RGB for every live <c>StaticMeshInstance</c>.</summary>
    public static ExportResult Export(BioShockPackage package, string outputPath)
    {
        var context = LevelAnalyzer.Analyze(package);
        var scene = LevelSceneBuilder.Build(package, context);
        var lightsByExport = scene.Lights.ToDictionary(l => l.Source.ExportIndex);

        var live = StaticMeshInstanceReader.EnumerateLive(package, context);
        var skipped = new List<SkippedInstance>();
        var decoded = new List<(LevelActor Actor, StaticMeshInstance Instance)>();
        foreach (var (actor, instance) in live)
        {
            if (instance is null)
            {
                skipped.Add(new SkippedInstance(actor.Source.ObjectName, "StaticMeshInstance body did not parse"));
                continue;
            }

            decoded.Add((actor, instance));
        }

        int poolBase = 0;
        byte[] levelData = [];
        if (decoded.Count > 0)
        {
            if (StaticMeshInstanceReader.LocateLuminancePool(
                    package, decoded.Select(x => x.Instance).ToList()) is not { } pool)
                throw new InvalidDataException($"{context.PackageName}: luminance pool not located in Level.");
            (poolBase, levelData) = pool;
        }

        var meshCache = new Dictionary<int, MeshGeometry?>();
        MeshGeometry? MeshOf(PackageIndex mesh)
        {
            if (!mesh.IsExport) return null;
            if (!meshCache.TryGetValue(mesh.ExportIndex, out var geom))
            {
                geom = StaticMeshReader.ReadGeometry(
                    package.ReadExportData(package.Exports[mesh.ExportIndex]));
                meshCache[mesh.ExportIndex] = geom;
            }
            return geom;
        }

        var unscaled = new List<(LevelActor Actor, StaticMeshInstance Instance, Vector3[] Rgb)>();
        foreach (var (actor, instance) in decoded)
        {
            var geom = MeshOf(instance.Mesh);
            // A few StaticMeshInstance exports point at meshes StaticMeshReader cannot decode yet
            // (e.g. some vending shells). The instance still decodes; skip RGB evaluation for those.
            if (geom is null)
            {
                skipped.Add(new SkippedInstance(actor.Source.ObjectName, "StaticMesh geometry did not decode"));
                continue;
            }

            if (geom.Vertices.Count != instance.VertexCount)
            {
                skipped.Add(new SkippedInstance(
                    actor.Source.ObjectName,
                    $"mesh vertex count {geom.Vertices.Count} != instance {instance.VertexCount}"));
                continue;
            }

            var rgb = new Vector3[instance.VertexCount];
            var world = LevelSceneBuilder.MeshPlacement(actor.Transform);
            foreach (var layer in instance.Layers)
            {
                if (!StaticMeshInstanceReader.TryReadLuminances(
                        levelData, poolBase, layer, instance.VertexCount,
                        out var s0, out var s1, out var s2))
                {
                    throw new InvalidDataException(
                        $"{actor.Source.Key}: luminance slice out of range at pool+{layer.PoolOffset}.");
                }

                float[][] slots = [s0, s1, s2];
                int slotCount = Math.Min(3, layer.Lights.Count);
                for (int slot = 0; slot < slotCount; slot++)
                {
                    var reference = layer.Lights[slot];
                    if (!reference.IsExport
                        || !lightsByExport.TryGetValue(reference.ExportIndex, out var light))
                        continue;

                    var colour = (light.Color?.ToVector() ?? Vector3.One) * (light.Brightness ?? 1f);
                    for (int v = 0; v < instance.VertexCount; v++)
                    {
                        float lum = slots[slot][v];
                        if (lum <= 0f) continue;
                        var worldPos = Vector3.Transform(geom.Vertices[v].Position, world);
                        var worldN = Vector3.Normalize(Vector3.TransformNormal(geom.Vertices[v].Normal, world));
                        if (worldN.LengthSquared() < 1e-8f) continue;
                        var toLight = light.Location - worldPos;
                        float distance = toLight.Length();
                        if (distance < 1e-3f) continue;
                        float facing = MathF.Max(0f, Vector3.Dot(worldN, toLight / distance));
                        rgb[v] += colour * (lum * facing);
                    }
                }
            }

            unscaled.Add((actor, instance, rgb));
        }

        float scale = ChooseScale(unscaled.SelectMany(x => x.Rgb));
        var instances = new List<InstanceExport>(unscaled.Count);
        int lit = 0;
        foreach (var (actor, instance, rgb) in unscaled)
        {
            var scaled = new float[rgb.Length * 3];
            var sum = Vector3.Zero;
            int nonzero = 0;
            for (int v = 0; v < rgb.Length; v++)
            {
                var c = rgb[v] * scale;
                scaled[v * 3] = c.X;
                scaled[v * 3 + 1] = c.Y;
                scaled[v * 3 + 2] = c.Z;
                sum += c;
                if (c.X > 1e-6f || c.Y > 1e-6f || c.Z > 1e-6f) nonzero++;
            }

            // Brief / Fast tests: "some non-zero light" means any lit vertex, not a majority.
            if (nonzero > 0) lit++;
            float inv = rgb.Length == 0 ? 0f : 1f / rgb.Length;
            string meshName = instance.Mesh.IsExport && instance.Mesh.ExportIndex < package.Exports.Count
                ? package.Exports[instance.Mesh.ExportIndex].ObjectName
                : string.Empty;
            var lightNames = instance.Layers
                .SelectMany(l => l.Lights)
                .Where(r => r.IsExport && r.ExportIndex < package.Exports.Count)
                .Select(r => package.Exports[r.ExportIndex].ObjectName)
                .Distinct(StringComparer.Ordinal)
                .ToList();

            instances.Add(new InstanceExport(
                actor.Source.Key,
                actor.Source.ObjectName,
                meshName,
                instance.VertexCount,
                lightNames,
                sum.X * inv,
                sum.Y * inv,
                sum.Z * inv,
                scaled));
        }

        var summary = new ExportSummary(
            context.PackageName,
            scale,
            AppliesNDotL: true,
            LuminanceLayout: "byte[4]=[pad,L0,L1,L2] at Level pool (PageIndex*262144+PageOffset)",
            instances.Count,
            lit,
            poolBase,
            instances,
            skipped);

        string json = JsonSerializer.Serialize(new
        {
            package = summary.Package,
            scale = summary.Scale,
            appliesNDotL = summary.AppliesNDotL,
            luminanceLayout = summary.LuminanceLayout,
            instanceCount = summary.InstanceCount,
            litInstanceCount = summary.LitInstanceCount,
            poolBase = summary.PoolBase,
            skipped = skipped.Select(s => new { actor = s.Actor, reason = s.Reason }),
            instances = instances.Select(i => new
            {
                i.Key,
                i.Actor,
                i.Mesh,
                i.VertexCount,
                lights = i.Lights,
                averageRgb = new[] { i.AverageR, i.AverageG, i.AverageB },
                verticesRgb = i.VerticesRgb,
            }),
        }, JsonOptions);

        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(outputPath))!);
        File.WriteAllText(outputPath, json);
        Console.Error.WriteLine(
            $"vertex lighting: scale={scale.ToString("0.###", CultureInfo.InvariantCulture)} "
            + $"instances={instances.Count} lit={lit} skipped={skipped.Count} poolBase={poolBase}");
        return new ExportResult(summary, outputPath);
    }

    private static float ChooseScale(IEnumerable<Vector3> colours)
    {
        var peaks = new List<float>();
        foreach (var c in colours)
        {
            float peak = MathF.Max(c.X, MathF.Max(c.Y, c.Z));
            if (peak > 1e-6f) peaks.Add(peak);
        }

        if (peaks.Count == 0) return GlobalScale;
        peaks.Sort();
        float p75 = peaks[(int)((peaks.Count - 1) * 0.75)];
        if (p75 < 1e-6f) return GlobalScale;
        return Math.Clamp(0.65f / p75, 0.25f, 8f);
    }
}
