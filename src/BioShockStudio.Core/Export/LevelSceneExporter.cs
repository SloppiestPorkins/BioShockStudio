using System.Globalization;
using System.Numerics;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using BioShockStudio.Core.Level;

namespace BioShockStudio.Core.Export;

/// <summary>What a level extraction writes.</summary>
[Flags]
public enum LevelExportFormats
{
    None = 0,

    /// <summary>The scene as JSON: every instance, its transform, its materials, and the lights.</summary>
    SceneJson = 1,

    /// <summary>Wavefront OBJ — geometry only, but openable in anything.</summary>
    Obj = 2,

    All = SceneJson | Obj,
}

/// <summary>
/// Writes a <see cref="LevelScene"/> to disk.
/// </summary>
/// <remarks>
/// <para>
/// Two formats, for two different jobs. The <b>scene JSON</b> is the lossless hand-off: it keeps
/// instancing, so a mesh placed 300 times is one asset and 300 transforms, and it carries the
/// lights and the material references that OBJ cannot express. The <b>OBJ</b> bakes every instance
/// into world-space triangles — much larger, and lossy — and exists because a format anyone can
/// open in any tool is what actually gets a level looked at, which is this project's standing rule.
/// </para>
/// <para>
/// <b>OBJ is 1-based and this writer is where that goes wrong.</b> Vertex indices in OBJ start at 1,
/// and every instance appends to one shared vertex list, so the running offset has to be added per
/// instance. An off-by-one here produces a mesh that opens, has the right triangle count, and is
/// subtly wrong — so <c>LevelExportTests</c> reads the file back and compares triangles against the
/// scene rather than trusting the count.
/// </para>
/// </remarks>
public static class LevelSceneExporter
{
    private static readonly JsonSerializerOptions Options = new()
    {
        WriteIndented = false,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    private static readonly JsonSerializerOptions ReadableOptions = new(Options) { WriteIndented = true };

    /// <summary>Writes the requested formats into <paramref name="directory"/> and returns the paths.</summary>
    public static IReadOnlyList<string> Write(
        LevelScene scene, string directory, LevelExportFormats formats = LevelExportFormats.All,
        bool readable = false)
    {
        Directory.CreateDirectory(directory);
        var written = new List<string>();

        if (formats.HasFlag(LevelExportFormats.SceneJson))
        {
            string path = Path.Combine(directory, scene.PackageName + ".level.json");
            File.WriteAllText(path, JsonSerializer.Serialize(ToDocument(scene), readable ? ReadableOptions : Options));
            written.Add(path);
        }

        if (formats.HasFlag(LevelExportFormats.Obj))
        {
            string path = Path.Combine(directory, scene.PackageName + ".obj");
            File.WriteAllText(path, BuildObj(scene));
            written.Add(path);
        }

        return written;
    }

    /// <summary>The scene as a serialisable document.</summary>
    public static LevelDocument ToDocument(LevelScene scene) => new()
    {
        Package = scene.PackageName,
        Generator = "BioShockStudio",
        Basis = "right-handed, +X forward, +Y left, +Z up, centimetres",
        BoundsMin = ToArray(scene.Bounds.Min),
        BoundsMax = ToArray(scene.Bounds.Max),
        Assets = scene.Instances
            .GroupBy(i => i.Asset)
            .Select(g => new LevelAssetDocument
            {
                Key = g.Key.Key,
                Name = g.Key.ObjectName,
                Kind = g.First().Kind.ToString(),
                ExportIndex = g.Key.ExportIndex,
                Vertices = g.First().Geometry.Vertices.Select(v => ToArray(v.Position)).ToList(),
                Normals = g.First().Geometry.Vertices.Select(v => ToArray(v.Normal)).ToList(),
                Uvs = g.First().Geometry.Vertices.Select(v => new[] { v.Uv.X, v.Uv.Y }).ToList(),
                Indices = g.First().Geometry.Indices.ToList(),
                Sections = g.First().Geometry.Sections
                    .Select((s, index) => new LevelSectionDocument
                    {
                        FirstIndex = s.FirstIndex,
                        TriangleCount = s.TriangleCount,
                        Material = index < g.First().Materials.Count ? g.First().Materials[index]?.ObjectName : null,
                    })
                    .ToList(),
            })
            .ToList(),
        Instances = scene.Instances
            .Select(i => new LevelInstanceDocument
            {
                Asset = i.Asset.Key,
                Actor = i.Actor.ObjectName,
                Label = i.Label,
                Transform = ToArray(i.Transform),
            })
            .ToList(),
        Lights = scene.Lights
            .Select(l => new LevelLightDocument
            {
                Name = l.Source.ObjectName,
                ClassName = l.ClassName,
                Location = ToArray(l.Location),
                Color = l.Color is { } c ? [c.R, c.G, c.B, c.A] : null,
                Brightness = l.Brightness,
                Radius = l.Radius,
            })
            .ToList(),
        Skipped = scene.Skipped.Select(s => $"{s.Actor}: {s.Reason}").ToList(),
    };

    /// <summary>
    /// The scene as Wavefront OBJ, in world space.
    /// </summary>
    /// <remarks>
    /// Instancing is lost here — every placement is baked — which is exactly why the scene JSON
    /// exists beside it. Normals are transformed by the instance matrix too; for the rigid,
    /// uniformly-scaled placements a level uses this is correct, and a non-uniform scale would need
    /// the inverse transpose. No shipped level actor has been measured with one, so rather than
    /// silently applying the cheap rule this writes what it does and
    /// <c>LevelExportTests.NoLevelInstanceCarriesANonUniformScale</c> checks the assumption still
    /// holds — the check fails loudly if the game ever disagrees.
    /// </remarks>
    public static string BuildObj(LevelScene scene)
    {
        var builder = new StringBuilder();
        var culture = CultureInfo.InvariantCulture;

        builder.Append("# BioShockStudio level export: ").AppendLine(scene.PackageName);
        builder.AppendLine("# right-handed, +X forward, +Y left, +Z up, centimetres");
        builder.Append("# ").Append(scene.Instances.Count).Append(" instances, ")
               .Append(scene.TriangleCount).AppendLine(" triangles");

        int vertexOffset = 1;   // OBJ indices are 1-based.

        foreach (var instance in scene.Instances)
        {
            builder.Append("o ").Append(Sanitise(instance.Actor.ObjectName)).Append('_')
                   .Append(instance.Actor.ExportIndex).AppendLine();

            foreach (var vertex in instance.Geometry.Vertices)
            {
                var p = Vector3.Transform(vertex.Position, instance.Transform);
                builder.Append("v ").Append(p.X.ToString("0.####", culture)).Append(' ')
                       .Append(p.Y.ToString("0.####", culture)).Append(' ')
                       .Append(p.Z.ToString("0.####", culture)).AppendLine();
            }

            var indices = instance.Geometry.Indices;
            for (int i = 0; i + 2 < indices.Count; i += 3)
            {
                builder.Append("f ")
                       .Append(indices[i] + vertexOffset).Append(' ')
                       .Append(indices[i + 1] + vertexOffset).Append(' ')
                       .Append(indices[i + 2] + vertexOffset).AppendLine();
            }

            vertexOffset += instance.Geometry.Vertices.Count;
        }

        return builder.ToString();
    }

    private static string Sanitise(string name)
    {
        var builder = new StringBuilder(name.Length);
        foreach (char c in name) builder.Append(char.IsLetterOrDigit(c) || c is '_' or '-' ? c : '_');
        return builder.ToString();
    }

    private static float[] ToArray(Vector3 v) => [v.X, v.Y, v.Z];

    private static float[] ToArray(Matrix4x4 m) =>
    [
        m.M11, m.M12, m.M13, m.M14,
        m.M21, m.M22, m.M23, m.M24,
        m.M31, m.M32, m.M33, m.M34,
        m.M41, m.M42, m.M43, m.M44,
    ];
}

/// <summary>The level scene's serialised shape.</summary>
public sealed record LevelDocument
{
    public required string Package { get; init; }
    public required string Generator { get; init; }
    public required string Basis { get; init; }
    public required float[] BoundsMin { get; init; }
    public required float[] BoundsMax { get; init; }
    public required List<LevelAssetDocument> Assets { get; init; }
    public required List<LevelInstanceDocument> Instances { get; init; }
    public required List<LevelLightDocument> Lights { get; init; }

    /// <summary>Actors whose geometry did not decode. Written even when empty, so the file states it.</summary>
    public required List<string> Skipped { get; init; }
}

public sealed record LevelAssetDocument
{
    public required string Key { get; init; }
    public required string Name { get; init; }
    public required string Kind { get; init; }
    public required int ExportIndex { get; init; }
    public required List<float[]> Vertices { get; init; }
    public required List<float[]> Normals { get; init; }
    public required List<float[]> Uvs { get; init; }
    public required List<int> Indices { get; init; }
    public required List<LevelSectionDocument> Sections { get; init; }
}

public sealed record LevelSectionDocument
{
    public required int FirstIndex { get; init; }
    public required int TriangleCount { get; init; }
    public string? Material { get; init; }
}

public sealed record LevelInstanceDocument
{
    public required string Asset { get; init; }
    public required string Actor { get; init; }
    public string? Label { get; init; }
    public required float[] Transform { get; init; }
}

public sealed record LevelLightDocument
{
    public required string Name { get; init; }
    public required string ClassName { get; init; }
    public required float[] Location { get; init; }
    public int[]? Color { get; init; }
    public float? Brightness { get; init; }
    public float? Radius { get; init; }
}
