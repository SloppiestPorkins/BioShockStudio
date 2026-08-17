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

/// <summary>One animation and the set it belongs to.</summary>
/// <param name="Owner">
/// The set name Havok's own root table gives it — <c>Melee</c>, <c>Pistol</c>, <c>Ceiling</c>. These
/// are behaviour and loadout sets, not mesh variants: any of a group's meshes can play any of them.
/// </param>
public readonly record struct AnimationSetEntry(string Name, string Owner, int FrameCount);

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

    /// <summary>
    /// Every animation with the set it belongs to, in the same order as <see cref="Animations"/>.
    /// </summary>
    /// <remarks>
    /// <c>AggressorBabyJane</c> carries 488 animations across ten sets — <c>Melee</c> (105),
    /// <c>Ceiling</c> (99), <c>Pistol</c> (93), <c>smg</c> (91), <c>Assassin</c> (27) and five
    /// smaller scripted ones. A flat list of 488 names is not usable.
    /// </remarks>
    public IReadOnlyList<AnimationSetEntry> AnimationSets { get; init; } = [];
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
        using var package = BioShockPackage.Open(catalog.PackageFile(BestPackage(entry, meshName)));
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
        IReadOnlyList<PreviewSurface> surfaces = [];
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
                // Deliberately does not claim an unsupported format. The 18 exports that reach this
                // are four door rigs carrying no vertex data at all — see docs/research/skeletalmesh.md
                // — and telling the user their file is unreadable would be a wrong diagnosis.
                problem = "No vertex data was found in this mesh. Its skeleton, sockets and animations "
                          + "are shown; the geometry they move may be supplied elsewhere.";
            }

            surfaces = LoadSurfaces(package, meshExport, geometry);

            // A run whose slot names no material is the honest remaining gap: it draws grey. The
            // multi-material warning this replaced is gone because each run now takes its own.
            int untextured = surfaces.Count(s => s.Texture is null);
            if (untextured > 0 && surfaces.Count > 1)
            {
                problem ??= $"{untextured} of this mesh's {surfaces.Count} material slots resolve no "
                            + "texture, so those parts draw untextured.";
            }
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

        var model = PreviewModel.Build(geometry, animations?.Skeleton, sockets, surfaces);

        var ordered = animations is null
            ? []
            : animations.Animations.OrderBy(a => a.Owner).ThenBy(a => a.Name).ToList();

        var names = ordered.Select(a => a.Name).ToList();
        var sets = ordered.Select(a => new AnimationSetEntry(a.Name, a.Owner, a.FrameCount)).ToList();

        if (!model.HasGeometry && model.Bones.Count == 0)
            problem ??= "There is nothing here that can be drawn.";

        return new PreviewSubject(
            model, names, problem,
            siblings.Select(e => e.ObjectName).ToList(),
            meshExport?.ObjectName)
        {
            AnimationSets = sets,
        };
    }

    /// <summary>
    /// Every mesh in a group, largest first, without duplicate names.
    /// </summary>
    /// <remarks>
    /// Both classes, because a group is often both: <c>NewProtectorBouncer</c> is a skeletal body
    /// plus the three static meshes its sockets name — the drill, its cage and the backpack.
    /// </remarks>
    private static List<ObjectExport> MeshesInGroup(BioShockPackage package, string group)
    {
        var members = package.Exports
            .Where(e => MeshGeometryReader.IsMeshClass(package.GetClassName(e))
                        && e.SerialSize > 0
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), group,
                            StringComparison.OrdinalIgnoreCase))
            .ToList();

        // A weapon's upgrade tiers are part of the weapon, but two of the thirteen the game ships —
        // SG_UpgradeB and XB_UpgradeB_Mesh, the two that carry their own rig — sit in a group of
        // their own, so resolving by group alone offered upgrades for four weapons and not the
        // other two. See Assets/WeaponUpgrades.cs.
        foreach (var upgrade in WeaponUpgrades.For(package, group))
        {
            if (string.Equals(upgrade.Group, group, StringComparison.OrdinalIgnoreCase)) continue;

            var export = package.Exports
                .Where(e => string.Equals(e.ObjectName, upgrade.MeshObject, StringComparison.OrdinalIgnoreCase)
                            && package.GetClassName(e) == upgrade.ClassName)
                .MaxBy(e => e.SerialSize);

            if (export is not null) members.Add(export);
        }

        return members
            .GroupBy(e => e.ObjectName, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.MaxBy(e => e.SerialSize)!)
            .OrderByDescending(e => e.SerialSize)
            .ToList();
    }

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

        // A static attachment shares its group with its host, so the largest mesh in that group is
        // the host's own body. The candidate names the one that was actually matched.
        var inGroup = package.Exports
            .Where(e => MeshGeometryReader.IsMeshClass(package.GetClassName(e))
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), candidate.Group,
                            StringComparison.OrdinalIgnoreCase))
            .ToList();

        var meshExport = inGroup
            .Where(e => string.Equals(e.ObjectName, candidate.MeshObject, StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize)
            ?? inGroup.MaxBy(e => e.SerialSize);

        MeshGeometry? geometry = null;
        IReadOnlyList<MeshSocket> sockets = [];
        IReadOnlyList<PreviewSurface> surfaces = [];
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
            surfaces = LoadSurfaces(package, meshExport, geometry);
            if (geometry is null) problem = $"No vertex data was found in '{candidate.MeshObject}'.";
        }

        AnimationPackage? animations = null;

        // A static prop shares its host's group, so looking up "the group's animation package" would
        // hand it the host's skeleton and imply it were skinned to it. It has none of its own.
        var wrapper = candidate.IsStatic ? null : FindAnimationPackage(package, candidate.Group);
        if (wrapper is not null)
        {
            try { animations = AnimationPackage.Load(package, wrapper); }
            catch (Exception ex) { problem ??= $"Its animations could not be read: {ex.Message}"; }
        }

        var model = PreviewModel.Build(geometry, animations?.Skeleton, sockets, surfaces);

        var ordered = animations is null
            ? []
            : animations.Animations
                .GroupBy(a => a.Name, StringComparer.OrdinalIgnoreCase)
                .Select(g => g.First())
                .OrderBy(a => a.Name, StringComparer.OrdinalIgnoreCase)
                .ToList();

        return new PreviewSubject(
            model,
            ordered.Select(a => a.Name).ToList(),
            problem,
            [candidate.MeshObject],
            candidate.MeshObject)
        {
            AnimationSets = ordered.Select(a => new AnimationSetEntry(a.Name, a.Owner, a.FrameCount)).ToList(),
        };
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

    /// <summary>
    /// Which of a row's packages to read it from.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>A catalogue row spans packages, and they do not all carry the same thing.</b> Every map
    /// embeds its own copy of what it uses, so a collapsed row lists twenty — and a <i>group</i> row
    /// is only as complete as the map it is read from. <c>AggressorBabyJane</c> owns thirteen meshes
    /// across the game, but the package its row resolves to holds exactly one of them,
    /// <c>CorpseMale</c>. Selecting the character showed a corpse, and no amount of choosing better
    /// among that package's meshes could fix it: there was only ever one to choose.
    /// </para>
    /// <para>
    /// So the package is chosen too. A package carrying a mesh whose name shares more with the row's
    /// wins; the row's own package is the fallback and the tie-break, so nothing changes for the
    /// overwhelming majority of rows where it already holds the right mesh.
    /// </para>
    /// <para>
    /// <b>Bounded deliberately.</b> It opens the row's other packages only when the default is
    /// unrelated to the row's name, and stops at the first clear improvement — a row that already
    /// matches costs one package open, exactly as before.
    /// </para>
    /// </remarks>
    private string BestPackage(CatalogEntry entry, string? meshName)
    {
        // An explicit mesh request, or a row that is itself a mesh, is already unambiguous.
        if (meshName is not null || entry.Packages.Count <= 1) return entry.Package;
        if (entry.ClassName is AssetClasses.SkeletalMesh or AssetClasses.StaticMesh) return entry.Package;

        int best = Score(entry.Package);
        if (best > 0) return entry.Package;

        foreach (string candidate in entry.Packages)
        {
            if (string.Equals(candidate, entry.Package, StringComparison.OrdinalIgnoreCase)) continue;
            if (Score(candidate) > 0) return candidate;
        }

        return entry.Package;

        int Score(string packageName)
        {
            try
            {
                using var package = BioShockPackage.Open(catalog.PackageFile(packageName));
                return MeshesInGroup(package, entry.Group)
                    .Select(e => SharedNameLength(entry.Name, e.ObjectName))
                    .DefaultIfEmpty(0)
                    .Max() >= 4 ? 1 : 0;
            }
            catch (Exception ex) when (ex is IOException or InvalidDataException)
            {
                return 0;
            }
        }
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

        // Keyed on what the row *is*, not which bucket it is shown in: a splicer variant is a
        // SkeletalMesh row filed under Characters, and it must still load its own mesh rather than
        // the largest of the thirteen that share its rig.
        if (entry.ClassName is AssetClasses.SkeletalMesh or AssetClasses.StaticMesh)
        {
            var direct = package.Exports
                .Where(e => e.ObjectName == entry.ObjectName && package.GetClassName(e) == entry.ClassName)
                .MaxBy(e => e.SerialSize);
            if (direct is not null) return direct;
        }

        // A group row — a character, not one of its meshes. AggressorBabyJane owns thirteen, and
        // this used to return siblings.FirstOrDefault(): whichever the package happened to store
        // first, which is CorpseMale. Selecting "AggressorBabyJane" showed a corpse.
        //
        // Ordered by how much of its name the mesh shares with the row, then by size. That picks
        // Agg_BabyJane over CorpseMale on the strength of the eight characters they have in common,
        // and falls back to the largest mesh when nothing shares anything — which is the old
        // behaviour for every group whose meshes are named unrelatedly, minus the arbitrariness of
        // storage order.
        //
        // A name heuristic, and it is confined to a presentation choice on purpose: it decides which
        // of a group's own meshes to show FIRST, never what an asset is. The user can pick any of
        // the thirteen, and PreviewSubject.SelectedMesh reports which one is showing.
        return siblings
            .OrderByDescending(e => SharedNameLength(entry.Name, e.ObjectName))
            .ThenByDescending(e => e.SerialSize)
            .FirstOrDefault();
    }

    /// <summary>The length of the longest run of characters two names have in common.</summary>
    /// <remarks>
    /// Case-insensitive and cheap — asset names are short. Used only to rank a group's own meshes
    /// for display, never to decide identity.
    /// </remarks>
    private static int SharedNameLength(string a, string b)
    {
        if (a.Length == 0 || b.Length == 0) return 0;

        var previous = new int[b.Length + 1];
        int best = 0;

        for (int i = 1; i <= a.Length; i++)
        {
            var current = new int[b.Length + 1];
            for (int j = 1; j <= b.Length; j++)
            {
                if (char.ToUpperInvariant(a[i - 1]) != char.ToUpperInvariant(b[j - 1])) continue;
                current[j] = previous[j - 1] + 1;
                if (current[j] > best) best = current[j];
            }
            previous = current;
        }

        return best;
    }

    private static ObjectExport? FindAnimationPackage(BioShockPackage package, string group) =>
        package.Exports
            .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), group,
                            StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

    /// <summary>
    /// The mesh's drawable runs, each with the maps its own material binds, at a size cheap to
    /// sample per pixel.
    /// </summary>
    /// <remarks>
    /// Which triangles use which material comes from <see cref="MeshSurfaceResolver"/> — the one
    /// place that pairs a section with a material — so the viewport and the exporters cannot
    /// disagree. Resolved through the material, so a <c>FacingShader</c> yields its facing diffuse
    /// rather than nothing. A run whose slot names no material draws flat grey rather than borrowing
    /// a neighbour's texture.
    /// </remarks>
    private IReadOnlyList<PreviewSurface> LoadSurfaces(
        BioShockPackage package, ObjectExport meshExport, MeshGeometry? geometry)
    {
        if (geometry is null || geometry.Indices.Count < 3) return [];

        var surfaces = MeshSurfaceResolver.Resolve(package, meshExport, geometry, catalog.ExternalMaterials);
        if (surfaces.Count == 0) return [];

        // One decode per texture, however many runs bind it: the Bathysphere's hull material appears
        // on two of its three sections.
        var images = new Dictionary<string, PreviewImage?>(StringComparer.OrdinalIgnoreCase);

        // A material read from another package brings its textures with it: the shared shaders and
        // their images both live in the script packages, and 427 imported materials name a diffuse
        // that is in none of the meshes' own packages. Looking beside the mesh finds nothing.
        var borrowed = new Dictionary<string, BioShockPackage>(StringComparer.OrdinalIgnoreCase);

        PreviewImage? Image(BioShockMaterial? material, string? name)
        {
            if (material is null || name is null) return null;

            string key = $"{material.SourceFile}|{name}";
            if (images.TryGetValue(key, out var cached)) return cached;

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

            return images[key] = LoadTexture(source, name);
        }

        try
        {
            return [.. surfaces.Select(s => new PreviewSurface(
                s.FirstIndex,
                s.IndexCount,
                s.Material?.Name,
                Image(s.Material, s.Material?.DiffuseTexture),
                Image(s.Material, s.Material?.NormalTexture),
                Image(s.Material, s.Material?.SpecularTexture)))];
        }
        finally
        {
            foreach (var opened in borrowed.Values) opened?.Dispose();
        }
    }

    /// <summary>
    /// Largest mip edge the preview will decode. Not a quality ceiling on the tool — the extractor
    /// writes the whole chain — but the point past which a viewport cannot show the difference and
    /// the renderer pays for it on every sample.
    /// </summary>
    private const int MaximumPreviewTexture = 1024;

    private PreviewImage? LoadTexture(BioShockPackage package, string? name)
    {
        if (name is null) return null;

        var export = package.Exports
            .Where(e => e.ObjectName == name && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize);
        if (export is null) return null;

        BioShockTexture? texture;
        try { texture = TextureReader.Read(package, export, catalog.Bulk); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }

        if (texture is null || texture.Mips.Count == 0) return null;

        // A 512-square cap was cheap and visibly soft — the shipped art is mostly 1024 and 2048 —
        // and the full 2048 is more texels than a viewport this size can show, at four times the
        // memory and a cache miss per sample. 1024 is the point where more stops being visible.
        // Extraction is unaffected: it writes every mip the texture has.
        int index = 0;
        for (int i = 0; i < texture.Mips.Count; i++)
        {
            if (Math.Max(texture.Mips[i].Width, texture.Mips[i].Height) <= MaximumPreviewTexture) { index = i; break; }
            index = i;
        }

        var mip = texture.Mips[index];
        return new PreviewImage(mip.Width, mip.Height, BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height));
    }
}
