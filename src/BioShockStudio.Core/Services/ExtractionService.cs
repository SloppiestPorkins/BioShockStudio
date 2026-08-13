using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Services;

/// <summary>What an extraction writes.</summary>
[Flags]
public enum ExportFormats
{
    None = 0,

    /// <summary>The intermediate scene JSON the Blender importer reads.</summary>
    SceneJson = 1,

    /// <summary>Binary FBX: mesh and skeleton, one file per animation, plus the Unreal manifest.</summary>
    Fbx = 2,

    /// <summary>Textures as PNG.</summary>
    Png = 4,

    /// <summary>Textures as DDS, keeping the shipped compression and the whole mip chain.</summary>
    Dds = 8,
}

public sealed record ExtractionOptions
{
    public required string OutputDirectory { get; init; }
    public ExportFormats Formats { get; init; } = ExportFormats.SceneJson | ExportFormats.Png;

    /// <summary>Mirror the game's package layout under the output directory.</summary>
    public bool PreservePackageStructure { get; init; } = true;

    /// <summary>Leave an asset alone when its output is already there.</summary>
    public bool SkipExisting { get; init; }
}

/// <summary>Live counters while an extraction runs.</summary>
public sealed record ExtractionProgress(
    int Completed, int Total, string Current, int Succeeded, int Failed, int Skipped);

/// <summary>What happened to one asset.</summary>
public sealed record ExtractionResult(CatalogEntry Entry, ExtractionOutcome Outcome, string? Message, string? Output);

public enum ExtractionOutcome { Succeeded, Failed, Skipped }

/// <summary>The whole job's outcome, including every failure and why.</summary>
public sealed record ExtractionReport
{
    public required IReadOnlyList<ExtractionResult> Results { get; init; }
    public required bool Cancelled { get; init; }

    public int Succeeded => Results.Count(r => r.Outcome == ExtractionOutcome.Succeeded);
    public int Failed => Results.Count(r => r.Outcome == ExtractionOutcome.Failed);
    public int Skipped => Results.Count(r => r.Outcome == ExtractionOutcome.Skipped);

    public IEnumerable<ExtractionResult> Failures => Results.Where(r => r.Outcome == ExtractionOutcome.Failed);
}

/// <summary>
/// Runs extraction jobs: one asset, a selection, a category or a whole package.
/// </summary>
/// <remarks>
/// <para>
/// One bad asset never ends a job. Every item is caught individually and recorded with the reason,
/// so a bulk run over a package with four unreadable meshes still writes the other fifty and can
/// tell the user exactly which four failed and why.
/// </para>
/// <para>
/// Cancellation is cooperative and checked between assets, so a cancelled job leaves finished files
/// intact and never a half-written one.
/// </para>
/// </remarks>
public sealed class ExtractionService(AssetCatalogService catalog)
{
    public async Task<ExtractionReport> RunAsync(
        IReadOnlyList<CatalogEntry> entries,
        ExtractionOptions options,
        IProgress<ExtractionProgress>? progress = null,
        CancellationToken cancellation = default)
    {
        var results = new List<ExtractionResult>();
        bool cancelled = false;

        await Task.Run(() =>
        {
            Directory.CreateDirectory(options.OutputDirectory);

            // Assets are grouped by package so each one is opened once rather than per asset.
            foreach (var byPackage in entries.GroupBy(e => e.Package, StringComparer.OrdinalIgnoreCase))
            {
                if (cancellation.IsCancellationRequested) { cancelled = true; return; }

                BioShockPackage? package = null;
                try
                {
                    package = BioShockPackage.Open(catalog.PackageFile(byPackage.Key));
                }
                catch (Exception ex)
                {
                    foreach (var entry in byPackage)
                        results.Add(new ExtractionResult(entry, ExtractionOutcome.Failed, ex.Message, null));
                    continue;
                }

                using (package)
                {
                    foreach (var entry in byPackage)
                    {
                        if (cancellation.IsCancellationRequested) { cancelled = true; return; }

                        progress?.Report(new ExtractionProgress(
                            results.Count, entries.Count, entry.Name,
                            results.Count(r => r.Outcome == ExtractionOutcome.Succeeded),
                            results.Count(r => r.Outcome == ExtractionOutcome.Failed),
                            results.Count(r => r.Outcome == ExtractionOutcome.Skipped)));

                        results.Add(ExtractOne(package, entry, options, cancellation));
                    }
                }
            }
        }, cancellation).ConfigureAwait(false);

        progress?.Report(new ExtractionProgress(
            results.Count, entries.Count, string.Empty,
            results.Count(r => r.Outcome == ExtractionOutcome.Succeeded),
            results.Count(r => r.Outcome == ExtractionOutcome.Failed),
            results.Count(r => r.Outcome == ExtractionOutcome.Skipped)));

        return new ExtractionReport { Results = results, Cancelled = cancelled };
    }

    private ExtractionResult ExtractOne(
        BioShockPackage package, CatalogEntry entry, ExtractionOptions options, CancellationToken cancellation)
    {
        try
        {
            string directory = DirectoryFor(entry, options);

            if (options.SkipExisting && Directory.Exists(directory) && Directory.EnumerateFileSystemEntries(directory).Any())
                return new ExtractionResult(entry, ExtractionOutcome.Skipped, "Output already exists.", directory);

            string? output = entry.Category switch
            {
                AssetCategory.Textures => ExtractTexture(package, entry, options, directory),
                AssetCategory.Materials => ExtractMaterialTextures(package, entry, options, directory),
                AssetCategory.SkeletalMeshes or AssetCategory.StaticMeshes or AssetCategory.Animations
                    => ExtractGroup(package, entry, options, directory, cancellation),
                _ => ExtractGroup(package, entry, options, directory, cancellation),
            };

            return output is null
                ? new ExtractionResult(entry, ExtractionOutcome.Skipped, "Nothing to write for this asset.", null)
                : new ExtractionResult(entry, ExtractionOutcome.Succeeded, null, output);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            return new ExtractionResult(entry, ExtractionOutcome.Failed, ex.Message, null);
        }
    }

    private static string DirectoryFor(CatalogEntry entry, ExtractionOptions options)
    {
        string category = entry.Category switch
        {
            AssetCategory.FirstPerson => "FirstPerson",
            AssetCategory.Characters => "Characters",
            AssetCategory.Weapons => "Weapons",
            AssetCategory.Props => "Props",
            AssetCategory.Textures => "Textures",
            AssetCategory.Materials => "Materials",
            _ => "Meshes",
        };

        string root = options.PreservePackageStructure
            ? Path.Combine(options.OutputDirectory, category, entry.Package)
            : Path.Combine(options.OutputDirectory, category);

        bool perAsset = entry.Category is not (AssetCategory.Textures or AssetCategory.Materials);
        return perAsset ? Path.Combine(root, Sanitise(entry.Group)) : root;
    }

    private static string? ExtractTexture(
        BioShockPackage package, CatalogEntry entry, ExtractionOptions options, string directory)
    {
        if ((options.Formats & (ExportFormats.Png | ExportFormats.Dds)) == 0) return null;

        var export = package.Exports
            .Where(e => e.ObjectName == entry.ObjectName && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize)
            ?? throw new FileNotFoundException($"'{entry.ObjectName}' is not in {entry.Package}.");

        var texture = TextureReader.Read(package, export)
            ?? throw new InvalidDataException("This texture's format is not understood.");

        Directory.CreateDirectory(directory);

        // Object names repeat within a package, so the group disambiguates the file name.
        string stem = Sanitise(entry.Group == texture.Name ? texture.Name : $"{entry.Group}.{texture.Name}");

        if (options.Formats.HasFlag(ExportFormats.Png))
        {
            var top = texture.Mips[0];
            PngWriter.Write(
                Path.Combine(directory, stem + ".png"),
                BlockCompression.Decode(texture.Format, top.Data, top.Width, top.Height), top.Width, top.Height);
        }

        if (options.Formats.HasFlag(ExportFormats.Dds) && texture.Format != BioShockTextureFormat.Rgba8)
            DdsWriter.Write(Path.Combine(directory, stem + ".dds"), texture);

        return directory;
    }

    private static string? ExtractMaterialTextures(
        BioShockPackage package, CatalogEntry entry, ExtractionOptions options, string directory)
    {
        if ((options.Formats & ExportFormats.Png) == 0) return null;

        var export = package.Exports
            .Where(e => e.ObjectName == entry.ObjectName && package.GetClassName(e) == entry.ClassName)
            .MaxBy(e => e.SerialSize)
            ?? throw new FileNotFoundException($"'{entry.ObjectName}' is not in {entry.Package}.");

        var material = MaterialReader.Read(package, export)
            ?? throw new InvalidDataException("This material could not be read.");

        Directory.CreateDirectory(directory);
        int written = 0;

        foreach (var binding in material.Textures.DistinctBy(t => t.TextureName, StringComparer.OrdinalIgnoreCase))
        {
            var textureExport = package.Exports
                .Where(e => e.ObjectName == binding.TextureName && package.GetClassName(e) == TextureReader.ClassName)
                .MaxBy(e => e.SerialSize);
            if (textureExport is null) continue;

            var texture = TextureReader.Read(package, textureExport);
            if (texture is null || texture.Mips.Count == 0) continue;

            var top = texture.Mips[0];
            PngWriter.Write(
                Path.Combine(directory, Sanitise(texture.Name) + ".png"),
                BlockCompression.Decode(texture.Format, top.Data, top.Width, top.Height), top.Width, top.Height);
            written++;
        }

        if (written == 0) throw new InvalidDataException("None of this material's textures could be decoded.");
        return directory;
    }

    /// <summary>
    /// Extracts a whole animated asset: skeleton, animations, mesh, sockets, events and material.
    /// </summary>
    /// <remarks>
    /// A mesh or an animation selected on its own extracts its group, because neither is usable
    /// alone — an animation without its skeleton is a list of numbers, and a skinned mesh without
    /// its bones has nothing to deform it.
    /// </remarks>
    private static string? ExtractGroup(
        BioShockPackage package,
        CatalogEntry entry,
        ExtractionOptions options,
        string directory,
        CancellationToken cancellation)
    {
        if ((options.Formats & (ExportFormats.SceneJson | ExportFormats.Fbx)) == 0) return null;

        var wrapper = package.Exports
            .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), entry.Group,
                            StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        // A static mesh is complete on its own: it has no skeleton to export against, and demanding
        // one turned every prop into a failure that read like a parsing problem.
        if (entry.ClassName == AssetClasses.StaticMesh)
            return ExtractStaticMesh(package, entry, options, directory);

        if (wrapper is null)
            throw new InvalidDataException(
                $"'{entry.Group}' has no animation package, so there is no skeleton to export against.");

        var animations = AnimationPackage.Load(package, wrapper);
        cancellation.ThrowIfCancellationRequested();

        var meshExport = package.Exports
            .Where(e => package.GetClassName(e) == AssetClasses.SkeletalMesh
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), entry.Group,
                            StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        IReadOnlyList<MeshSocket> sockets = [];
        MeshGeometry? geometry = null;
        SceneMaterial? material = null;

        Directory.CreateDirectory(directory);

        if (meshExport is not null)
        {
            byte[] payload = package.ReadExportData(meshExport);
            sockets = SkeletalMeshReader.ReadSockets(payload, package.Names);
            geometry = SkeletalMeshReader.ReadGeometry(payload);
            material = MaterialExporter.Resolve(package, meshExport, directory);
        }

        var events = new Dictionary<string, IReadOnlyList<AnimationEvent>>(StringComparer.Ordinal);
        var metadata = package.Exports
            .Where(e => package.GetClassName(e) == AnimationMetadataReader.ClassName)
            .GroupBy(e => e.ObjectName, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

        foreach (var animation in animations.Animations)
        {
            if (!metadata.TryGetValue(AnimationMetadataReader.ObjectPrefix + animation.Name, out var export)) continue;
            var track = AnimationMetadataReader.ReadEvents(package, export, animation.Duration);
            if (track.Count > 0) events[animation.Name] = track;
        }

        cancellation.ThrowIfCancellationRequested();
        var scene = AnimationSceneExporter.Build(animations, null, sockets, geometry, events, material);

        if (options.Formats.HasFlag(ExportFormats.SceneJson))
            AnimationSceneExporter.WriteJson(scene, Path.Combine(directory, Sanitise(entry.Group) + ".json"));

        if (options.Formats.HasFlag(ExportFormats.Fbx))
            FbxExporter.Write(scene, directory);

        return directory;
    }

    /// <summary>
    /// Extracts a single static mesh: geometry and material, no skeleton and no animations.
    /// </summary>
    private static string? ExtractStaticMesh(
        BioShockPackage package, CatalogEntry entry, ExtractionOptions options, string directory)
    {
        var export = package.Exports
            .Where(e => e.ObjectName == entry.ObjectName
                        && package.GetClassName(e) == AssetClasses.StaticMesh)
            .MaxBy(e => e.SerialSize)
            ?? throw new InvalidDataException($"'{entry.ObjectName}' is not in this package.");

        var geometry = StaticMeshReader.ReadGeometry(package.ReadExportData(export))
            ?? throw new InvalidDataException(
                $"'{entry.ObjectName}' uses a static-mesh layout this tool does not read yet. "
                + "See docs/research/staticmesh.md.");

        Directory.CreateDirectory(directory);
        var material = MaterialExporter.Resolve(package, export, directory);
        var scene = AnimationSceneExporter.BuildStatic(entry.Package, export.ObjectName, geometry, material);

        if (options.Formats.HasFlag(ExportFormats.SceneJson))
            AnimationSceneExporter.WriteJson(scene, Path.Combine(directory, Sanitise(export.ObjectName) + ".json"));

        if (options.Formats.HasFlag(ExportFormats.Fbx))
            FbxExporter.Write(scene, directory);

        return directory;
    }

    private static string Sanitise(string name) => string.Concat(name.Split(Path.GetInvalidFileNameChars()));
}
