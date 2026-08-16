using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Services;

/// <summary>One map the tool can extract, as the window lists it.</summary>
public sealed record LevelEntry(string Name, string File, long SizeBytes)
{
    public string SizeDisplay => $"{SizeBytes / 1024.0 / 1024.0:0.#} MB";
}

/// <summary>What a level turned out to contain, in the user's terms.</summary>
public sealed record LevelSummary
{
    public required string Name { get; init; }
    public required int Actors { get; init; }
    public required int Instances { get; init; }
    public required int Brushes { get; init; }
    public required int Meshes { get; init; }

    /// <summary>Triangles in the compiled world — the level's own architecture. 0 if it has none.</summary>
    public required int WorldTriangles { get; init; }
    public required int Lights { get; init; }
    public required int Triangles { get; init; }
    public required int Skipped { get; init; }
    public required string Bounds { get; init; }

    /// <summary>Actor classes with no geometry, largest first — what a level holds besides geometry.</summary>
    public required IReadOnlyList<(string ClassName, int Count)> WithoutGeometry { get; init; }
}

/// <summary>
/// Reads and extracts whole levels, for the window and the command line alike.
/// </summary>
/// <remarks>
/// The window holds no format knowledge — <c>docs/HANDOFF.md</c> §3 — so everything the Level tab
/// needs is here, and can be tested without a window.
/// </remarks>
public sealed class LevelService
{
    /// <summary>
    /// The maps in an install, largest first.
    /// </summary>
    /// <remarks>
    /// Every <c>.bsm</c> in the maps folder is offered. Nothing filters by name: which packages hold
    /// a level is decided by what is in them, and a map with no actors reports zero rather than
    /// being hidden by a guess about its filename.
    /// </remarks>
    public IReadOnlyList<LevelEntry> Levels(string gameRoot)
    {
        string directory = GameLocator.MapsDirectory(gameRoot);
        if (!Directory.Exists(directory)) return [];

        return Directory.GetFiles(directory, "*.bsm")
            .Select(f => new LevelEntry(Path.GetFileNameWithoutExtension(f), f, new FileInfo(f).Length))
            .OrderByDescending(e => e.SizeBytes)
            .ToList();
    }

    /// <summary>Analyses and assembles one map.</summary>
    public LevelScene Load(string packageFile, IProgress<string>? progress = null)
    {
        using var package = BioShockPackage.Open(packageFile);
        progress?.Report("Reading actors…");
        var context = LevelAnalyzer.Analyze(package, progress);
        progress?.Report("Assembling geometry…");
        return LevelSceneBuilder.Build(package, context, progress);
    }

    /// <summary>Analyses a map and describes it, without keeping the geometry.</summary>
    public LevelSummary Describe(string packageFile, IProgress<string>? progress = null)
    {
        using var package = BioShockPackage.Open(packageFile);
        var context = LevelAnalyzer.Analyze(package, progress);
        var scene = LevelSceneBuilder.Build(package, context, progress);
        return Describe(context, scene);
    }

    public static LevelSummary Describe(LevelContext context, LevelScene scene) => new()
    {
        Name = scene.PackageName,
        Actors = context.Actors.Count,
        Instances = scene.Instances.Count,
        Brushes = scene.Brushes.Count(),
        Meshes = scene.Meshes.Count(),
        WorldTriangles = scene.World.Sum(i => i.Geometry.TriangleCount),
        Lights = scene.Lights.Count,
        Triangles = scene.TriangleCount,
        Skipped = scene.Skipped.Count,
        Bounds = $"{scene.Bounds.Min:0} … {scene.Bounds.Max:0}",
        WithoutGeometry = context.ClassesWithoutGeometry
            .OrderByDescending(e => e.Value)
            .Take(12)
            .Select(e => (e.Key, e.Value))
            .ToList(),
    };

    /// <summary>
    /// Extracts one map to a directory and returns what it wrote.
    /// </summary>
    /// <remarks>
    /// Each level goes in its own subdirectory. A level export is several files that belong
    /// together and are named after the map, so writing them all into one folder would interleave
    /// maps and make it unclear which OBJ went with which scene.
    /// </remarks>
    public IReadOnlyList<string> Extract(
        string packageFile, string outputDirectory, LevelExportFormats formats, bool readable = false,
        IProgress<string>? progress = null)
    {
        var scene = Load(packageFile, progress);
        string directory = Path.Combine(outputDirectory, scene.PackageName);
        progress?.Report($"Writing {scene.Instances.Count:N0} instances…");
        return LevelSceneExporter.Write(scene, directory, formats, readable);
    }
}
