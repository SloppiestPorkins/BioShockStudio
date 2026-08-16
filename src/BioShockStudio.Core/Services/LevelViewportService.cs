using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Services;

/// <summary>A level prepared for drawing, with how it was put together.</summary>
public sealed record PreparedLevel
{
    public required LevelScene Scene { get; init; }
    public required LevelViewport Viewport { get; init; }

    /// <summary>Where the camera starts: inside the level, at the densest part of it.</summary>
    public required GhostCamera Start { get; init; }

    public required int TexturesLoaded { get; init; }
    public required int SurfacesWithoutTexture { get; init; }
    public required int TotalSurfaces { get; init; }

    public string TextureSummary =>
        $"{TexturesLoaded:N0} textures over {TotalSurfaces - SurfacesWithoutTexture:N0} of {TotalSurfaces:N0} surfaces";
}

/// <summary>
/// Turns a level into something drawable: geometry, materials and textures, ready for a viewport.
/// </summary>
/// <remarks>
/// <para>
/// <b>Textures are resolved per asset, not per instance.</b> A map places the same mesh hundreds of
/// times and every placement shares the asset's surfaces, so the work — and the memory — is bounded
/// by the 401 distinct assets in a map rather than its 1,141 placements.
/// </para>
/// <para>
/// <b>A level's textures are capped much smaller than an asset preview's.</b> The preview caps at
/// 1024 because it is looking at one thing closely; a level holds hundreds at once and the sum is
/// what matters. At 256 the whole of <c>0-Lighthouse</c> fits in a fraction of the memory and the
/// difference is invisible at the distances a level is viewed from.
/// </para>
/// </remarks>
public sealed class LevelViewportService(AssetCatalogService catalog)
{
    /// <summary>
    /// The largest texture edge kept for a level. See the class remarks — this is deliberately
    /// smaller than <c>MeshPreviewService</c>'s cap.
    /// </summary>
    public const int MaximumTexture = 256;

    public PreparedLevel Prepare(string packageFile, IProgress<string>? progress = null)
    {
        using var package = BioShockPackage.Open(packageFile);

        progress?.Report("Reading actors…");
        var context = LevelAnalyzer.Analyze(package);

        progress?.Report("Assembling geometry…");
        var scene = LevelSceneBuilder.Build(package, context);

        progress?.Report("Resolving materials…");
        var models = new Dictionary<string, PreviewModel>(StringComparer.Ordinal);
        var textures = new Dictionary<string, PreviewImage?>(StringComparer.OrdinalIgnoreCase);
        var borrowed = new Dictionary<string, BioShockPackage>(StringComparer.OrdinalIgnoreCase);

        int totalSurfaces = 0, withoutTexture = 0;
        var items = new List<ViewportItem>(scene.Instances.Count);

        try
        {
            foreach (var instance in scene.Instances)
            {
                if (!models.TryGetValue(instance.Asset.Key, out var model))
                {
                    var surfaces = Surfaces(package, instance, textures, borrowed);
                    totalSurfaces += surfaces.Count;
                    withoutTexture += surfaces.Count(s => s.Texture is null);
                    models[instance.Asset.Key] = model = PreviewModel.Build(instance.Geometry, null, null, surfaces);

                    if (models.Count % 50 == 0) progress?.Report($"{models.Count} assets prepared…");
                }

                var (centre, radius) = LevelViewport.BoundsOf(instance.Geometry.Vertices, instance.Transform);
                items.Add(new ViewportItem(model, instance.Transform, centre, radius));
            }
        }
        finally
        {
            foreach (var opened in borrowed.Values) opened?.Dispose();
        }

        return new PreparedLevel
        {
            Scene = scene,
            Viewport = new LevelViewport(items),
            Start = StartingCamera(items),
            TexturesLoaded = textures.Values.Count(t => t is not null),
            SurfacesWithoutTexture = withoutTexture,
            TotalSurfaces = totalSurfaces,
        };
    }

    /// <summary>
    /// Where to put the camera when a level opens.
    /// </summary>
    /// <remarks>
    /// <b>The middle of the bounding box is the wrong answer</b> — a map's box is mostly empty and
    /// its centre is usually inside a wall or out over the ocean. This uses the median of the
    /// instance centres instead, which lands where the geometry actually is, and lifts the camera
    /// clear of the floor.
    /// </remarks>
    private static GhostCamera StartingCamera(IReadOnlyList<ViewportItem> items)
    {
        if (items.Count == 0) return new GhostCamera();

        var xs = items.Select(i => i.Centre.X).Order().ToList();
        var ys = items.Select(i => i.Centre.Y).Order().ToList();
        var zs = items.Select(i => i.Centre.Z).Order().ToList();

        return new GhostCamera
        {
            Position = new Vector3(xs[xs.Count / 2], ys[ys.Count / 2], zs[zs.Count / 2] + 200f),
            Yaw = 0f,
            Pitch = -0.15f,
        };
    }

    /// <summary>
    /// The surfaces one asset draws with: the section list paired with its materials, and each
    /// material's base colour decoded.
    /// </summary>
    /// <remarks>
    /// A brush's materials come from its own polygons — <see cref="BspGeometry.Materials"/> — and a
    /// static mesh's from <see cref="MeshSurfaceResolver"/>, which is the one place in the project
    /// that pairs a section with a material. Neither path invents one: a surface whose slot resolves
    /// to nothing gets a null texture and draws untextured, which is the honest signal.
    /// </remarks>
    private IReadOnlyList<PreviewSurface> Surfaces(
        BioShockPackage package,
        LevelInstance instance,
        Dictionary<string, PreviewImage?> textures,
        Dictionary<string, BioShockPackage> borrowed)
    {
        var geometry = instance.Geometry;
        if (geometry.Indices.Count < 3) return [];

        if (instance.Kind == LevelGeometryKind.Brush)
        {
            var result = new List<PreviewSurface>();
            for (int i = 0; i < geometry.Sections.Count; i++)
            {
                var section = geometry.Sections[i];
                var material = i < instance.Materials.Count ? instance.Materials[i] : null;
                var decoded = material is null ? null : ReadMaterial(package, material.Value);

                result.Add(new PreviewSurface(
                    section.FirstIndex, section.IndexCount, decoded?.Name,
                    Image(package, decoded, decoded?.DiffuseTexture, textures, borrowed),
                    null, null));
            }
            return result;
        }

        var export = package.Exports[instance.Asset.ExportIndex];
        var surfaces = MeshSurfaceResolver.Resolve(package, export, geometry, catalog.ExternalMaterials);

        return [.. surfaces.Select(s => new PreviewSurface(
            s.FirstIndex, s.IndexCount, s.Material?.Name,
            Image(package, s.Material, s.Material?.DiffuseTexture, textures, borrowed),
            null, null))];
    }

    private static BioShockMaterial? ReadMaterial(BioShockPackage package, SourceId material)
    {
        try { return MaterialReader.Read(package, package.Exports[material.ExportIndex]); }
        catch (Exception ex) when (ex is IOException or InvalidDataException or ArgumentOutOfRangeException)
        {
            return null;
        }
    }

    /// <summary>
    /// Decodes a material's base colour, once per texture however many surfaces bind it.
    /// </summary>
    /// <remarks>
    /// A material read from another package brings its textures with it — the shared shaders and
    /// their images both live in the script packages — so looking only beside the mesh finds
    /// nothing for 427 imported materials. The borrowed packages are opened once and closed by the
    /// caller.
    /// </remarks>
    private PreviewImage? Image(
        BioShockPackage package,
        BioShockMaterial? material,
        string? name,
        Dictionary<string, PreviewImage?> textures,
        Dictionary<string, BioShockPackage> borrowed)
    {
        if (material is null || name is null) return null;

        string key = $"{material.SourceFile}|{name}";
        if (textures.TryGetValue(key, out var cached)) return cached;

        var source = package;
        if (material.SourceFile is { } file
            && !string.Equals(file, package.FilePath, StringComparison.OrdinalIgnoreCase))
        {
            if (!borrowed.TryGetValue(file, out var opened))
            {
                try { opened = BioShockPackage.Open(file); }
                catch (Exception ex) when (ex is IOException or InvalidDataException) { opened = null!; }
                borrowed[file] = opened!;
            }
            if (opened is not null) source = opened;
        }

        return textures[key] = Decode(source, name);
    }

    private PreviewImage? Decode(BioShockPackage package, string name)
    {
        var export = package.Exports
            .Where(e => e.ObjectName == name && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize);
        if (export is null) return null;

        BioShockTexture? texture;
        try { texture = TextureReader.Read(package, export, catalog.Bulk); }
        catch (Exception ex) when (ex is IOException or InvalidDataException or NotSupportedException)
        {
            return null;
        }

        if (texture is null || texture.Mips.Count == 0) return null;

        // The largest mip within the cap, so a 2048 texture costs what a 256 does.
        int index = 0;
        for (int i = 0; i < texture.Mips.Count; i++)
        {
            if (Math.Max(texture.Mips[i].Width, texture.Mips[i].Height) <= MaximumTexture) { index = i; break; }
            index = i;
        }

        var mip = texture.Mips[index];
        try
        {
            var rgba = BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height);
            return rgba is null ? null : new PreviewImage(mip.Width, mip.Height, rgba);
        }
        catch (Exception ex) when (ex is NotSupportedException or InvalidDataException
                                       or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }
    }
}
