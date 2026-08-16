using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Services;

/// <summary>A labelled fact about an asset.</summary>
public sealed record DetailField(string Label, string Value);

/// <summary>
/// A related asset.
/// </summary>
/// <param name="Confidence">
/// How the relationship was established. <c>Confirmed</c> means the game data states it — an outer
/// chain, a socket, a material reference. <c>Heuristic</c> means this tool inferred it. Never blank:
/// an inferred relationship shown as a fact is how a plausible wrong answer gets believed.
/// </param>
public sealed record RelatedAsset(
    string Name, string Detail, AssetCategory? Category, string Confidence = "Confirmed");

/// <summary>A named list of related assets, for the details panel and the relationship tree.</summary>
public sealed record DetailSection(string Title, IReadOnlyList<RelatedAsset> Items);

/// <summary>Everything the details panel shows for one selected asset.</summary>
public sealed record AssetDetails
{
    public required string Title { get; init; }
    public required string Subtitle { get; init; }
    public required IReadOnlyList<DetailField> Fields { get; init; }
    public required IReadOnlyList<DetailSection> Sections { get; init; }

    /// <summary>
    /// What this asset is, in the user's terms and in the game's.
    /// </summary>
    /// <remarks>
    /// Filled in one place for every asset kind rather than by each branch, because each branch used
    /// to decide for itself and the answer was inconsistent: a texture said its group, a mesh said
    /// its group and class, an animation said neither. "What is this" is the first question the panel
    /// exists to answer and it should not depend on which reader happened to produce the row.
    /// </remarks>
    public IReadOnlyList<DetailField> Identity { get; init; } = [];

    /// <summary>
    /// Where the asset lives: the package it is read from, every other package that carries it, and
    /// its export index.
    /// </summary>
    /// <remarks>
    /// <b>The package count is load-bearing, not trivia.</b> Every map embeds its own copy of what it
    /// uses, so a row's reported package is one of many — 71,106 rows collapse to 14,378 assets, and
    /// <c>NEWPlayerHands</c> is in all twenty maps. A user looking at "0-Lighthouse" and wondering
    /// why an asset is not in the map they are editing needs to see the rest of the list, and
    /// matching on the reported package alone has already produced a click that silently did nothing.
    /// </remarks>
    public IReadOnlyList<DetailField> Location { get; init; } = [];

    /// <summary>Technical facts, shown only in research mode.</summary>
    public required IReadOnlyList<DetailField> Research { get; init; }

    /// <summary>Set when the asset could not be read; the panel shows this instead of pretending.</summary>
    public string? Problem { get; init; }
}

/// <summary>
/// Resolves the details and relationships of one selected asset, on demand.
/// </summary>
/// <remarks>
/// Called when the selection changes, never while browsing, so it is free to open the package and
/// decode what it needs. Everything it reports comes from the extraction libraries; nothing is
/// re-parsed here.
/// </remarks>
public sealed class AssetDetailsService(AssetCatalogService catalog)
{
    public AssetDetails Describe(CatalogEntry entry, CancellationToken cancellation = default)
    {
        AssetDetails details;

        try
        {
            using var package = BioShockPackage.Open(catalog.PackageFile(entry.Package));
            cancellation.ThrowIfCancellationRequested();

            details = entry.Category switch
            {
                AssetCategory.Textures => DescribeTexture(package, entry),
                AssetCategory.Materials => DescribeMaterial(package, entry),
                AssetCategory.SkeletalMeshes or AssetCategory.StaticMeshes => DescribeMesh(package, entry),
                AssetCategory.Animations => DescribeAnimation(package, entry),
                _ => DescribeGroup(package, entry),
            };
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            details = Failed(entry, ex.Message);
        }

        // Identity and location come from the catalogue row, so an asset that could not be read
        // still says what and where it is instead of showing only an error.
        return details with { Identity = IdentityOf(entry), Location = LocationOf(entry) };
    }

    /// <summary>What the asset is — the user's word for it, and the game's.</summary>
    private static IReadOnlyList<DetailField> IdentityOf(CatalogEntry entry)
    {
        var fields = new List<DetailField>
        {
            new("Name", entry.Name),
            new("Kind", Describe(entry.Category)),

            // The Unreal class, always. It is what every resolver keys off — a row's bucket is a
            // presentation choice and its class is what it actually is — and the two differ: a
            // splicer variant is a SkeletalMesh filed under Characters.
            new("Class", entry.ClassName),
        };

        if (entry.ObjectName.Length > 0 && !string.Equals(entry.ObjectName, entry.Name, StringComparison.Ordinal))
            fields.Add(new DetailField("Object", entry.ObjectName));

        if (entry.Group.Length > 0) fields.Add(new DetailField("Group", entry.Group));

        // An animation belongs to the rig it was authored for, which is not always its group.
        if (entry.OwnerGroup is { Length: > 0 } owner && !string.Equals(owner, entry.Group, StringComparison.Ordinal))
            fields.Add(new DetailField("Belongs to", owner));

        return fields;
    }

    /// <summary>Where the asset is: the copy being read, and every other copy of it.</summary>
    private static IReadOnlyList<DetailField> LocationOf(CatalogEntry entry)
    {
        var fields = new List<DetailField> { new("Read from", entry.Package) };

        if (entry.PackageCount > 1)
        {
            var others = entry.Packages
                .Where(p => !string.Equals(p, entry.Package, StringComparison.OrdinalIgnoreCase))
                .ToList();

            fields.Add(new DetailField(
                "Also in",
                others.Count == 0
                    ? $"{entry.PackageCount} packages"
                    : $"{string.Join(", ", others)}  ({entry.PackageCount} in total)"));
        }

        if (entry.ExportIndex >= 0) fields.Add(new DetailField("Export", entry.ExportIndex.ToString()));
        fields.Add(new DetailField("Payload", Size(entry.SerialSize)));

        return fields;
    }

    /// <summary>The category in the user's terms, matching the browser's own labels.</summary>
    private static string Describe(AssetCategory category) => category switch
    {
        AssetCategory.FirstPerson => "First-person rig",
        AssetCategory.Characters => "Character",
        AssetCategory.Weapons => "Weapon",
        AssetCategory.Props => "Prop",
        AssetCategory.SkeletalMeshes => "Skeletal mesh",
        AssetCategory.StaticMeshes => "Static mesh",
        AssetCategory.Animations => "Animation",
        AssetCategory.Textures => "Texture",
        AssetCategory.Materials => "Material",
        _ => category.ToString(),
    };

    private static AssetDetails Failed(CatalogEntry entry, string problem) => new()
    {
        Title = entry.Name,
        Subtitle = entry.Package,
        Fields = [],
        Sections = [],
        Research = [],
        Problem = problem,
    };

    // ------------------------------------------------------------------ characters, weapons, props

    private static AssetDetails DescribeGroup(BioShockPackage package, CatalogEntry entry)
    {
        var context = AssetContextResolver.Resolve(package, entry.Group);
        var fields = new List<DetailField>();
        var sections = new List<DetailSection>();
        var research = new List<DetailField>();

        var wrapper = package.Exports
            .Where(e => e.ObjectName == entry.ObjectName
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize);

        // Both mesh classes: a character group holds its skeletal body and the static props its
        // sockets name, and the details panel should account for all of them.
        var meshExports = context.WhereClass(package, MeshGeometryReader.IsMeshClass).ToList();
        var meshExport = meshExports
            .OrderByDescending(e => package.GetClassName(e) == AssetClasses.SkeletalMesh)
            .ThenByDescending(e => e.SerialSize)
            .FirstOrDefault();

        string? problem = null;

        if (wrapper is not null)
        {
            AnimationPackage? animations = null;
            try { animations = AnimationPackage.Load(package, wrapper); }
            catch (Exception ex) { problem = $"Animations could not be read: {ex.Message}"; }

            if (animations is not null)
            {
                fields.Add(new DetailField("Skeleton", $"{animations.Skeleton.Name} · {animations.Skeleton.BoneCount} bones"));
                fields.Add(new DetailField("Animations", animations.Animations.Count.ToString()));
                var owners = animations.Owners.ToList();
                if (owners.Count > 1) fields.Add(new DetailField("Animation sets", string.Join(", ", owners)));

                // One section per set when there is more than one. AggressorBabyJane has 488
                // animations across ten sets; a single list of that length hides its own structure.
                var sets = animations.Animations
                    .GroupBy(a => a.Owner, StringComparer.Ordinal)
                    .OrderByDescending(g => g.Count())
                    .ToList();

                foreach (var set in sets)
                {
                    string title = sets.Count > 1 ? $"Animations — {set.Key} ({set.Count()})" : "Animations";
                    sections.Add(new DetailSection(title, set
                        .OrderBy(a => a.Name, StringComparer.OrdinalIgnoreCase)
                        .Select(a => new RelatedAsset(
                            a.Name,
                            $"{a.Duration:0.00}s · {a.FrameCount} frames · {a.FrameRate:0.##} fps",
                            AssetCategory.Animations))
                        .ToList()));
                }

                if (animations.Failures.Count > 0)
                {
                    fields.Add(new DetailField("Undecoded animations", animations.Failures.Count.ToString()));
                }

                research.Add(new DetailField("Havok section", string.Join(", ",
                    animations.Animations.Select(a => a.SectionTag).Distinct().Take(6))));
            }
        }

        if (meshExport is not null)
        {
            byte[] payload = package.ReadExportData(meshExport);
            string className = package.GetClassName(meshExport);
            var geometry = MeshGeometryReader.Read(className, payload);
            var sockets = className == AssetClasses.SkeletalMesh
                ? SkeletalMeshReader.ReadSockets(payload, package.Names)
                : [];

            fields.Add(new DetailField("Mesh", geometry is null
                ? $"{meshExport.ObjectName} — geometry format not supported"
                : $"{meshExport.ObjectName} · {geometry.Vertices.Count:N0} vertices · {geometry.TriangleCount:N0} triangles"
                  + (geometry.IsSkinned ? string.Empty : " · static, no skeleton")));

            // Saying what is left behind, rather than exporting one set and implying there was one.
            if (geometry is { ExtraUvStreamCount: > 0 })
            {
                research.Add(new DetailField("Extra UV streams",
                    $"{geometry.ExtraUvStreamCount} not carried into the export"));
            }

            if (sockets.Count > 0)
            {
                sections.Add(new DetailSection("Sockets", sockets
                    .Select(s => new RelatedAsset(s.Name, $"on bone {s.BoneName}", null))
                    .ToList()));
            }

            var material = MaterialReader.ReadForMesh(package, meshExport);
            if (material is not null) sections.Add(MaterialSection(material));

            // A mesh can name more than one material, and which triangles use the second is not yet
            // known — so only the first is applied and the panel says so rather than showing a
            // confidently wrong surface.
            var allMaterials = MaterialReader.ReadMeshMaterialReferences(payload, package);
            if (allMaterials.Count > 1)
            {
                problem ??= $"This mesh declares {allMaterials.Count} materials. Only the first is applied, "
                            + "because which triangles use which is not yet decoded, so parts of it are "
                            + "textured wrongly. See docs/research/materials.md.";
            }
        }

        if (meshExports.Count > 1)
        {
            sections.Add(new DetailSection("Meshes", meshExports
                .OrderByDescending(e => e.SerialSize)
                .Select(e => package.GetClassName(e) == AssetClasses.StaticMesh
                    ? new RelatedAsset(e.ObjectName, $"{Size(e.SerialSize)} · static", AssetCategory.StaticMeshes)
                    : new RelatedAsset(e.ObjectName, Size(e.SerialSize), AssetCategory.SkeletalMeshes))
                .ToList()));
        }

        var textures = context.OfClass(package, TextureReader.ClassName).ToList();
        if (textures.Count > 0)
        {
            sections.Add(new DetailSection("Textures", textures
                .OrderByDescending(e => e.SerialSize)
                .Select(e => new RelatedAsset(e.ObjectName, Size(e.SerialSize), AssetCategory.Textures))
                .ToList()));
        }

        var attachments = context.OfClass(package, AssetClasses.StaticMesh).ToList();
        if (attachments.Count > 0)
        {
            // These line up with sockets on the skeleton — the hands' CS_photo with the CSphoto
            // socket — but the group only proves they belong together, not what attaches where.
            sections.Add(new DetailSection("Attachments", attachments
                .Select(e => new RelatedAsset(e.ObjectName, Size(e.SerialSize), AssetCategory.StaticMeshes, "Confirmed"))
                .ToList()));
        }

        research.Add(new DetailField("Group members", context.Members.Count.ToString()));
        research.Add(new DetailField("Animation package", entry.ObjectName));

        return new AssetDetails
        {
            Title = entry.Name,
            Subtitle = $"{entry.Category} · {entry.Package}",
            Fields = fields,
            Sections = sections,
            Research = research,
            Problem = problem,
        };
    }

    // ------------------------------------------------------------------ leaves

    private static AssetDetails DescribeTexture(BioShockPackage package, CatalogEntry entry)
    {
        var export = Export(package, entry);
        var texture = TextureReader.Read(package, export);

        if (texture is null)
            return Failed(entry, "This texture's format is not understood, so it cannot be shown or extracted.");

        return new AssetDetails
        {
            Title = texture.Name,
            Subtitle = $"Texture · {entry.Package}",
            Fields =
            [
                new DetailField("Format", texture.Format.ToString()),
                new DetailField("Size", $"{texture.Width} × {texture.Height}"),
                new DetailField("Mips", texture.Mips.Count.ToString()),
                new DetailField("Group", entry.Group),
            ],
            Sections = [],
            Research =
            [
                new DetailField("Export index", export.Index.ToString()),
                new DetailField("Payload", Size(export.SerialSize)),
            ],
        };
    }

    private static AssetDetails DescribeMaterial(BioShockPackage package, CatalogEntry entry)
    {
        var export = Export(package, entry);
        var material = MaterialReader.Read(package, export);

        if (material is null) return Failed(entry, "This material could not be read.");

        var fields = new List<DetailField> { new("Shader type", material.ClassName) };
        if (material.Glossiness is { } gloss) fields.Add(new DetailField("Glossiness", $"{gloss:0.##}"));
        if (material.SpecularBrightness is { } spec) fields.Add(new DetailField("Specular brightness", $"{spec:0.##}"));
        if (material.TwoSided) fields.Add(new DetailField("Two sided", "yes"));
        if (material.Masked) fields.Add(new DetailField("Masked", "yes"));

        return new AssetDetails
        {
            Title = material.Name,
            Subtitle = $"{material.ClassName} · {entry.Package}",
            Fields = fields,
            Sections = [MaterialSection(material)],
            Research =
            [
                new DetailField("Export index", export.Index.ToString()),
                new DetailField("Uninterpreted properties",
                    material.UnhandledProperties.Count == 0
                        ? "none"
                        : string.Join(", ", material.UnhandledProperties.Distinct())),
            ],
            // Half the shaders in the larger packages stop early; saying so is the point.
            Problem = material.Truncated
                ? "Only part of this shader could be read, so some settings are missing. "
                  + "See docs/research/materials.md."
                : null,
        };
    }

    /// <summary>
    /// Lists a material's texture bindings under the slot names the shader really uses.
    /// </summary>
    /// <remarks>
    /// A <c>FacingShader</c> has no <c>Diffuse</c> — its base colour is <c>FacingDiffuse</c> and
    /// <c>EdgeDiffuse</c> — so the slots are shown as they are rather than mapped onto a generic
    /// diffuse/normal/specular model that would misrepresent the source.
    /// </remarks>
    private static DetailSection MaterialSection(BioShockMaterial material) =>
        new($"Material — {material.Name}", material.Textures.Count == 0
            ? [new RelatedAsset("(no textures bound)", material.ClassName, null)]
            : material.Textures
                .Select(t => new RelatedAsset(t.TextureName, t.Slot + (t.IsExternal ? " · in another package" : ""),
                    AssetCategory.Textures))
                .ToList());

    private static AssetDetails DescribeMesh(BioShockPackage package, CatalogEntry entry)
    {
        var export = Export(package, entry);
        byte[] payload = package.ReadExportData(export);

        var fields = new List<DetailField>();
        var sections = new List<DetailSection>();
        string? problem = null;

        var geometry = MeshGeometryReader.Read(entry.ClassName, payload);

        if (geometry is not null)
        {
            fields.Add(new DetailField("Vertices", $"{geometry.Vertices.Count:N0}"));
            fields.Add(new DetailField("Triangles", $"{geometry.TriangleCount:N0}"));
            fields.Add(new DetailField("Bones used",
                geometry.IsSkinned ? geometry.BoneMap.Count.ToString() : "none — static mesh"));
            if (geometry.ExtraUvStreamCount > 0)
                fields.Add(new DetailField("Extra UV streams", geometry.ExtraUvStreamCount.ToString()));
        }
        else if (MeshGeometryReader.IsMeshClass(entry.ClassName))
        {
            string note = entry.ClassName == AssetClasses.StaticMesh ? "staticmesh" : "skeletalmesh";
            problem = "No vertex data was found in this mesh, so it has no geometry to show or "
                      + $"export. See docs/research/{note}.md — every shipped StaticMesh decodes, and "
                      + "the SkeletalMesh exports that reach this carry no vertices rather than an "
                      + "unread format.";
        }

        var sockets = entry.ClassName == AssetClasses.SkeletalMesh
            ? SkeletalMeshReader.ReadSockets(payload, package.Names)
            : [];
        if (sockets.Count > 0)
        {
            sections.Add(new DetailSection("Sockets",
                sockets.Select(s => new RelatedAsset(s.Name, $"on bone {s.BoneName}", null)).ToList()));
        }

        var material = MaterialReader.ReadForMesh(package, export);
        if (material is not null) sections.Add(MaterialSection(material));
        else fields.Add(new DetailField("Material", "not resolved"));

        fields.Add(new DetailField("Group", entry.Group));

        return new AssetDetails
        {
            Title = entry.Name,
            Subtitle = $"{entry.ClassName} · {entry.Package}",
            Fields = fields,
            Sections = sections,
            Research =
            [
                new DetailField("Export index", export.Index.ToString()),
                new DetailField("Payload", Size(export.SerialSize)),
            ],
            Problem = problem,
        };
    }

    private static AssetDetails DescribeAnimation(BioShockPackage package, CatalogEntry entry)
    {
        var fields = new List<DetailField> { new("Group", entry.Group) };
        var sections = new List<DetailSection>();
        string? problem = null;

        var wrapper = package.Exports
            .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), entry.Group,
                            StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        if (wrapper is null)
        {
            problem = "This animation's package could not be found, so its timing cannot be read.";
        }
        else
        {
            var animations = AnimationPackage.Load(package, wrapper);
            var animation = animations.Find(entry.Name);

            if (animation is null)
            {
                problem = "This animation did not decode.";
            }
            else
            {
                fields.Add(new DetailField("Skeleton", $"{animations.Skeleton.Name} · {animations.Skeleton.BoneCount} bones"));
                fields.Add(new DetailField("Duration", $"{animation.Duration:0.000} s"));
                fields.Add(new DetailField("Frames", animation.FrameCount.ToString()));
                fields.Add(new DetailField("Frame rate", $"{animation.FrameRate:0.##} fps"));
                fields.Add(new DetailField("Tracks", animation.TransformTrackCount.ToString()));
                if (animation.Owner.Length > 0) fields.Add(new DetailField("Set", animation.Owner));
            }
        }

        var metadata = package.Exports.FirstOrDefault(e =>
            string.Equals(e.ObjectName, entry.ObjectName, StringComparison.OrdinalIgnoreCase));
        if (metadata is not null)
        {
            var events = AnimationMetadataReader.ReadEvents(package, metadata, 0f);
            if (events.Count > 0)
            {
                sections.Add(new DetailSection("Events", events
                    .Select(e => new RelatedAsset(e.EventName, $"{e.Time:0.000}s · {e.NotifyClass}", null))
                    .ToList()));
            }
        }

        return new AssetDetails
        {
            Title = entry.Name,
            Subtitle = $"Animation · {entry.Group} · {entry.Package}",
            Fields = fields,
            Sections = sections,
            Research = [new DetailField("Metadata object", entry.ObjectName)],
            Problem = problem,
        };
    }

    private static ObjectExport Export(BioShockPackage package, CatalogEntry entry) =>
        entry.ExportIndex >= 0 && entry.ExportIndex < package.Exports.Count
            ? package.Exports[entry.ExportIndex]
            : package.Exports
                  .Where(e => e.ObjectName == entry.ObjectName && package.GetClassName(e) == entry.ClassName)
                  .MaxBy(e => e.SerialSize)
              ?? throw new FileNotFoundException($"'{entry.ObjectName}' is no longer in {entry.Package}.");

    private static string Size(int bytes) => bytes >= 1024 * 1024
        ? $"{bytes / (1024.0 * 1024.0):0.#} MB"
        : $"{Math.Max(1, bytes / 1024)} KB";
}
