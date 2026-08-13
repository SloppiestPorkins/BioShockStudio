using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Services;

/// <summary>A decoded animation with the timing needed to play it back.</summary>
public sealed record PreviewAnimation(string Name, DecodedAnimation Decoded, int FrameCount, float FrameDuration)
{
    public float Duration => FrameCount <= 1 ? 0f : (FrameCount - 1) * FrameDuration;
    public float FrameRate => FrameDuration > 0f ? 1f / FrameDuration : 0f;
}

/// <summary>Everything the preview needs for one asset.</summary>
/// <param name="Meshes">
/// Every skeletal mesh in this asset's group, largest first.
/// </param>
/// <param name="SelectedMesh">Which of them <paramref name="Model"/> was built from.</param>
/// <remarks>
/// A group is often more than one mesh. <c>AggressorBabyJane</c> carries the doctor, the corpse and
/// the Lady Smith splicer variants on one skeleton, and showing only the largest hides the rest.
/// </remarks>
public sealed record PreviewSubject(
    PreviewModel Model,
    IReadOnlyList<string> Animations,
    string? Problem,
    IReadOnlyList<string> Meshes = null!,
    string? SelectedMesh = null)
{
    public IReadOnlyList<string> Meshes { get; init; } = Meshes ?? [];
}

/// <summary>
/// Loads assets for the 3D preview.
/// </summary>
/// <remarks>
/// Everything here comes from the same readers the exporters use. The preview is not a second,
/// looser interpretation of the data: if the viewport shows a mesh deforming correctly, that is the
/// geometry, skinning and animation the FBX will contain.
/// </remarks>
public sealed class MeshPreviewService(AssetCatalogService catalog)
{
    /// <summary>
    /// Loads the model for an asset, resolving its group when a mesh or animation is selected.
    /// </summary>
    /// <param name="meshName">
    /// Which mesh of the group to build, when it holds several. Null takes the largest, which is
    /// usually the one the asset is named after.
    /// </param>
    public PreviewSubject Load(CatalogEntry entry, string? meshName = null, CancellationToken cancellation = default)
    {
        using var package = BioShockPackage.Open(catalog.PackageFile(entry.Package));
        cancellation.ThrowIfCancellationRequested();

        var siblings = MeshesInGroup(package, entry.Group);
        var meshExport = FindMesh(package, entry, meshName, siblings);
        bool isStatic = meshExport is not null && package.GetClassName(meshExport) == AssetClasses.StaticMesh;

        // A static mesh is not bound to the group's skeleton — it is a prop that hangs off a socket
        // on it. Drawing the two together in one space would imply a binding the data does not
        // state, so the prop is shown on its own.
        var wrapper = isStatic ? null : FindAnimationPackage(package, entry.Group);

        MeshGeometry? geometry = null;
        IReadOnlyList<MeshSocket> sockets = [];
        PreviewImage? texture = null;
        PreviewImage? normalMap = null;
        PreviewImage? specularMap = null;
        string? problem = null;

        if (meshExport is not null)
        {
            byte[] payload = package.ReadExportData(meshExport);
            string className = package.GetClassName(meshExport);
            geometry = MeshGeometryReader.Read(className, payload);

            // Only a skeletal mesh carries a socket table; a static one is what hangs off a socket.
            if (className == AssetClasses.SkeletalMesh)
                sockets = SkeletalMeshReader.ReadSockets(payload, package.Names);

            if (geometry is null)
            {
                problem = "This mesh uses a geometry layout this tool does not read yet, so only its "
                          + "skeleton can be shown.";
            }

            (texture, normalMap, specularMap) = LoadMaps(package, meshExport);
        }
        else
        {
            problem = "No mesh was found for this asset.";
        }

        cancellation.ThrowIfCancellationRequested();

        AnimationPackage? animations = null;
        if (wrapper is not null)
        {
            try { animations = AnimationPackage.Load(package, wrapper); }
            catch (Exception ex) { problem ??= $"Animations could not be read: {ex.Message}"; }
        }

        var model = PreviewModel.Build(geometry, animations?.Skeleton, sockets, texture, normalMap, specularMap);

        var names = animations is null
            ? []
            : animations.Animations.OrderBy(a => a.Owner).ThenBy(a => a.Name).Select(a => a.Name).ToList();

        if (!model.HasGeometry && model.Bones.Count == 0)
            problem ??= "There is nothing here that can be drawn.";

        return new PreviewSubject(
            model, names, problem,
            siblings.Select(e => e.ObjectName).ToList(),
            meshExport?.ObjectName);
    }

    /// <summary>
    /// Every mesh in a group, largest first, without duplicate names.
    /// </summary>
    /// <remarks>
    /// Both classes, because a group is often both: <c>NewProtectorBouncer</c> is a skeletal body
    /// plus the three static meshes its sockets name — the drill, its cage and the backpack.
    /// </remarks>
    private static List<ObjectExport> MeshesInGroup(BioShockPackage package, string group) =>
        package.Exports
            .Where(e => MeshGeometryReader.IsMeshClass(package.GetClassName(e))
                        && e.SerialSize > 0
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), group,
                            StringComparison.OrdinalIgnoreCase))
            .GroupBy(e => e.ObjectName, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.MaxBy(e => e.SerialSize)!)
            .OrderByDescending(e => e.SerialSize)
            .ToList();

    /// <summary>
    /// Loads an attachment named by a socket — a first-person weapon — as its own model.
    /// </summary>
    /// <remarks>
    /// It stays a separate model. The host's socket-bone transform is applied when it is drawn, so
    /// the two skeletons are never merged.
    /// </remarks>
    public PreviewSubject LoadAttachment(AttachmentCandidate candidate, CancellationToken cancellation = default)
    {
        using var package = BioShockPackage.Open(catalog.PackageFile(candidate.Package));
        cancellation.ThrowIfCancellationRequested();

        var meshExport = package.Exports
            .Where(e => MeshGeometryReader.IsMeshClass(package.GetClassName(e))
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), candidate.Group,
                            StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        MeshGeometry? geometry = null;
        IReadOnlyList<MeshSocket> sockets = [];
        PreviewImage? texture = null;
        PreviewImage? normalMap = null;
        PreviewImage? specularMap = null;
        string? problem = null;

        if (meshExport is null)
        {
            problem = $"No mesh was found in '{candidate.Group}'.";
        }
        else
        {
            byte[] payload = package.ReadExportData(meshExport);
            string className = package.GetClassName(meshExport);
            geometry = MeshGeometryReader.Read(className, payload);
            if (className == AssetClasses.SkeletalMesh)
                sockets = SkeletalMeshReader.ReadSockets(payload, package.Names);
            (texture, normalMap, specularMap) = LoadMaps(package, meshExport);
            if (geometry is null) problem = $"'{candidate.MeshObject}' uses a geometry layout this tool does not read yet.";
        }

        AnimationPackage? animations = null;
        var wrapper = FindAnimationPackage(package, candidate.Group);
        if (wrapper is not null)
        {
            try { animations = AnimationPackage.Load(package, wrapper); }
            catch (Exception ex) { problem ??= $"Its animations could not be read: {ex.Message}"; }
        }

        var model = PreviewModel.Build(geometry, animations?.Skeleton, sockets, texture, normalMap, specularMap);
        var names = animations is null ? [] : animations.Animations.Select(a => a.Name).Distinct().Order().ToList();

        return new PreviewSubject(model, names, problem, [candidate.MeshObject], candidate.MeshObject);
    }

    /// <summary>Decodes an attachment's animation, which lives in its own package.</summary>
    public PreviewAnimation? LoadAttachmentAnimation(AttachmentCandidate candidate, string animationName)
    {
        using var package = BioShockPackage.Open(catalog.PackageFile(candidate.Package));

        var wrapper = FindAnimationPackage(package, candidate.Group);
        if (wrapper is null) return null;

        var animations = AnimationPackage.Load(package, wrapper);
        var animation = animations.Find(animationName);
        if (animation is null) return null;

        return new PreviewAnimation(
            animation.Name, animations.Decode(animation), animation.FrameCount, animation.FrameDuration);
    }

    /// <summary>Decodes one animation for playback, or null when it is not in this asset's package.</summary>
    public PreviewAnimation? LoadAnimation(CatalogEntry entry, string animationName)
    {
        using var package = BioShockPackage.Open(catalog.PackageFile(entry.Package));

        var wrapper = FindAnimationPackage(package, entry.Group);
        if (wrapper is null) return null;

        var animations = AnimationPackage.Load(package, wrapper);
        var animation = animations.Find(animationName);
        if (animation is null) return null;

        return new PreviewAnimation(
            animation.Name, animations.Decode(animation), animation.FrameCount, animation.FrameDuration);
    }

    private static ObjectExport? FindMesh(
        BioShockPackage package, CatalogEntry entry, string? meshName, List<ObjectExport> siblings)
    {
        if (meshName is not null)
        {
            var chosen = siblings.FirstOrDefault(e =>
                string.Equals(e.ObjectName, meshName, StringComparison.OrdinalIgnoreCase));
            if (chosen is not null) return chosen;
        }

        if (entry.Category == AssetCategory.SkeletalMeshes || entry.Category == AssetCategory.StaticMeshes)
        {
            var direct = package.Exports
                .Where(e => e.ObjectName == entry.ObjectName && package.GetClassName(e) == entry.ClassName)
                .MaxBy(e => e.SerialSize);
            if (direct is not null) return direct;
        }

        return siblings.FirstOrDefault();
    }

    private static ObjectExport? FindAnimationPackage(BioShockPackage package, string group) =>
        package.Exports
            .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), group,
                            StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

    /// <summary>
    /// The mesh's base colour, normal and specular maps, at a size cheap to sample per pixel.
    /// </summary>
    /// <remarks>
    /// Resolved through the material, so a <c>FacingShader</c> yields its facing diffuse rather than
    /// nothing. A mesh with no resolvable material simply draws in flat grey; a material that binds
    /// only some of the three gets only those.
    /// </remarks>
    private static (PreviewImage? Diffuse, PreviewImage? Normal, PreviewImage? Specular) LoadMaps(
        BioShockPackage package, ObjectExport meshExport)
    {
        var material = MaterialReader.ReadForMesh(package, meshExport);
        if (material is null) return (null, null, null);

        return (
            LoadTexture(package, material.DiffuseTexture),
            LoadTexture(package, material.NormalTexture),
            LoadTexture(package, material.SpecularTexture));
    }

    private static PreviewImage? LoadTexture(BioShockPackage package, string? name)
    {
        if (name is null) return null;

        var export = package.Exports
            .Where(e => e.ObjectName == name && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize);
        if (export is null) return null;

        BioShockTexture? texture;
        try { texture = TextureReader.Read(package, export); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }

        if (texture is null || texture.Mips.Count == 0) return null;

        // A 512-square mip is ample for a viewport and keeps the whole model's texture in cache.
        int index = 0;
        for (int i = 0; i < texture.Mips.Count; i++)
        {
            if (Math.Max(texture.Mips[i].Width, texture.Mips[i].Height) <= 512) { index = i; break; }
            index = i;
        }

        var mip = texture.Mips[index];
        return new PreviewImage(mip.Width, mip.Height, BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height));
    }
}
