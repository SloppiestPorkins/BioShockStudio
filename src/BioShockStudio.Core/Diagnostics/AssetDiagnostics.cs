using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Diagnostics;

/// <summary>Which part of the pipeline a diagnostic came from.</summary>
public enum DiagnosticSubsystem
{
    Package,
    Geometry,
    Materials,
    Textures,
    Animation,
}

/// <summary>
/// How badly the asset is affected. Deliberately three levels, and deliberately not
/// error/warning/info: the distinction that matters here is whether the asset comes out at all.
/// </summary>
public enum DiagnosticSeverity
{
    /// <summary>Worth knowing, not a fault — something the export cannot carry.</summary>
    Note,

    /// <summary>The asset comes out, but wrong or incomplete. This is the dangerous class.</summary>
    Degraded,

    /// <summary>The asset cannot be produced at all.</summary>
    Broken,
}

/// <summary>
/// One thing this tool knows is wrong with one asset.
/// </summary>
/// <remarks>
/// <para>
/// Every field except <see cref="Reference"/> is required, because the point of this record is that a
/// report can be acted on without the session that produced it. <see cref="Evidence"/> is the
/// measurement — counts, names, sizes — and is separate from <see cref="Summary"/>, which is the
/// user's-terms statement. A summary alone is an opinion; the evidence is what makes it checkable.
/// </para>
/// <para>
/// Nothing here judges whether an asset <i>looks</i> right. Each code below can only be true of a
/// result that is broken or incomplete, on the same rule as <see cref="AnimationAudit"/>.
/// </para>
/// </remarks>
public sealed record Diagnostic
{
    /// <summary>Stable slug — <c>mesh-no-geometry</c>. Kept stable so reports compare across sessions.</summary>
    public required string Code { get; init; }

    public required DiagnosticSubsystem Subsystem { get; init; }
    public required DiagnosticSeverity Severity { get; init; }

    public required string Package { get; init; }

    /// <summary>The asset group — the character, weapon or prop this belongs to. May be empty.</summary>
    public required string Group { get; init; }

    public required string Asset { get; init; }
    public required string ClassName { get; init; }

    /// <summary>What is wrong, in the user's terms.</summary>
    public required string Summary { get; init; }

    /// <summary>What was measured. Names, counts and sizes — never an interpretation.</summary>
    public required string Evidence { get; init; }

    /// <summary>Where the format is documented, when it is.</summary>
    public string Reference { get; init; } = string.Empty;

    /// <summary>Export index within the package, or -1 when the entry is not one export.</summary>
    public int ExportIndex { get; init; } = -1;

    /// <summary>
    /// The whole entry as text, for the "Copy Diagnostic" button and for a report to a future
    /// session. One diagnostic is self-contained: it names the asset, the package and the evidence.
    /// </summary>
    public string ToReport()
    {
        var lines = new List<string>
        {
            $"[{Code}] {Severity} · {Subsystem}",
            $"  asset:    {Asset} ({ClassName})",
            $"  package:  {Package}" + (Group.Length > 0 ? $" · group {Group}" : string.Empty)
                + (ExportIndex >= 0 ? $" · export {ExportIndex}" : string.Empty),
            $"  summary:  {Summary}",
            $"  evidence: {Evidence}",
        };

        if (Reference.Length > 0) lines.Add($"  see:      {Reference}");
        return string.Join(Environment.NewLine, lines);
    }

    public override string ToString() => $"{Code} {Package}/{Asset}: {Evidence}";
}

/// <summary>
/// How much was looked at. Without this an empty report is ambiguous — it could mean nothing is
/// wrong or that nothing was examined, and those are opposite conclusions.
/// </summary>
public sealed record DiagnosticCoverage
{
    public int Packages { get; init; }
    public int Meshes { get; init; }
    public int Materials { get; init; }
    public int Textures { get; init; }
    public int Animations { get; init; }

    public static DiagnosticCoverage operator +(DiagnosticCoverage a, DiagnosticCoverage b) => new()
    {
        Packages = a.Packages + b.Packages,
        Meshes = a.Meshes + b.Meshes,
        Materials = a.Materials + b.Materials,
        Textures = a.Textures + b.Textures,
        Animations = a.Animations + b.Animations,
    };

    public int Assets => Meshes + Materials + Textures + Animations;
}

/// <summary>Everything one scan found, plus what it looked at.</summary>
public sealed record DiagnosticReport
{
    public required IReadOnlyList<Diagnostic> Diagnostics { get; init; }
    public required DiagnosticCoverage Coverage { get; init; }

    public int Count(DiagnosticSeverity severity) => Diagnostics.Count(d => d.Severity == severity);

    /// <summary>Distinct assets carrying at least one diagnostic.</summary>
    public int AffectedAssets => Diagnostics
        .Select(d => $"{d.Package}/{d.Asset}")
        .Distinct(StringComparer.OrdinalIgnoreCase)
        .Count();

    /// <summary>Diagnostics grouped by code, worst severity first then commonest.</summary>
    public IReadOnlyList<(string Code, DiagnosticSeverity Severity, int Count)> ByCode() => Diagnostics
        .GroupBy(d => d.Code, StringComparer.Ordinal)
        .Select(g => (Code: g.Key, Severity: g.Max(d => d.Severity), Count: g.Count()))
        .OrderByDescending(x => x.Severity)
        .ThenByDescending(x => x.Count)
        .ThenBy(x => x.Code, StringComparer.Ordinal)
        .ToList();

    public DiagnosticReport Merge(DiagnosticReport other) => new()
    {
        Diagnostics = [.. Diagnostics, .. other.Diagnostics],
        Coverage = Coverage + other.Coverage,
    };

    /// <summary>
    /// The health report — the same data summarised. Always states coverage, so a clean report
    /// cannot be confused with an empty one.
    /// </summary>
    public string Summarise()
    {
        var lines = new List<string>
        {
            $"Examined {Coverage.Assets:N0} assets in {Coverage.Packages:N0} package(s): "
                + $"{Coverage.Meshes:N0} meshes, {Coverage.Materials:N0} materials, "
                + $"{Coverage.Textures:N0} textures, {Coverage.Animations:N0} animations.",
        };

        if (Diagnostics.Count == 0)
        {
            lines.Add("No diagnostics. Every check ran and none fired.");
            return string.Join(Environment.NewLine, lines);
        }

        lines.Add($"{Diagnostics.Count:N0} diagnostic(s) on {AffectedAssets:N0} asset(s) — "
                  + $"{Count(DiagnosticSeverity.Broken):N0} broken, "
                  + $"{Count(DiagnosticSeverity.Degraded):N0} degraded, "
                  + $"{Count(DiagnosticSeverity.Note):N0} note.");
        lines.Add(string.Empty);

        foreach (var (code, severity, count) in ByCode())
            lines.Add($"  {count,7:N0}  {severity,-8}  {code}");

        return string.Join(Environment.NewLine, lines);
    }

    public static readonly DiagnosticReport Empty =
        new() { Diagnostics = [], Coverage = new DiagnosticCoverage() };
}

/// <summary>The stable diagnostic codes. Referenced by tests and by the UI's filter.</summary>
public static class DiagnosticCodes
{
    public const string PackageUnreadable = "package-unreadable";

    public const string MeshNoGeometry = "mesh-no-geometry";
    public const string MeshUnreadable = "mesh-unreadable";
    public const string MeshUvOutOfRange = "mesh-uv-out-of-range";
    public const string MeshSlotUnresolved = "mesh-material-slot-unresolved";
    public const string MeshNoDiffuse = "mesh-no-diffuse";
    public const string MeshNoSections = "mesh-materials-without-sections";

    public const string MaterialUnreadable = "material-unreadable";
    public const string MaterialTruncated = "material-truncated";

    public const string TextureUndecodable = "texture-undecodable";
    public const string TextureMipsUnrecovered = "texture-mips-unrecovered";

    public const string AnimationPackageFailed = "animation-package-failed";
    public const string AnimationFailed = "animation-failed";
    public const string AnimationUnsupported = "animation-unsupported";
    public const string AnimationPartial = "animation-partial";
    public const string AnimationBlockSlack = "animation-block-not-consumed";
    public const string AnimationBonesCollapse = "animation-bones-collapse";
}

/// <summary>
/// Aggregates what the extraction libraries already measure into one list of faults, each carrying
/// its own evidence.
/// </summary>
/// <remarks>
/// <para>
/// <b>Why this is in Core and not in a view model.</b> Every fault found in the last two sessions was
/// found by a human looking at the viewport — grey security cameras, an armless splicer, a misaligned
/// prop — and in all three cases the tool already held the evidence and never surfaced it. The
/// aggregation is therefore a tested service the CLI, the health report and the Problems panel all
/// call, rather than something the window works out for itself.
/// </para>
/// <para>
/// It re-parses nothing. Every check calls the same reader the export pipeline calls, with the same
/// arguments, so a diagnostic describes what an extraction would actually produce rather than what a
/// second implementation thinks it would.
/// </para>
/// </remarks>
public static class AssetDiagnostics
{
    /// <summary>
    /// A UV outside this is not a parameterisation, it is a misread stream. The two known offenders
    /// decode to around 6e36; shipped UVs run within a few tens of tiles.
    /// </summary>
    private const float MaximumPlausibleUv = 1e4f;

    /// <summary>
    /// Scans every package the game ships. <paramref name="progress"/> is called once per package.
    /// </summary>
    /// <remarks>
    /// Animation is <b>not</b> included: <see cref="AnimationAudit"/> is its own whole-game sweep and
    /// costs minutes, so a caller decides whether to pay for it and merges
    /// <see cref="FromAnimationAudit"/> in. The coverage figures say which sweeps actually ran.
    /// </remarks>
    public static DiagnosticReport Run(
        string gameRoot,
        IExternalMaterialSource? external = null,
        BulkTextureCatalog? bulk = null,
        Action<string>? progress = null,
        CancellationToken cancellation = default)
    {
        var report = DiagnosticReport.Empty;

        var files = Game.GameLocator.EnumeratePackages(gameRoot)
            .Concat(Game.GameLocator.EnumerateScriptPackages(gameRoot));

        foreach (string file in files)
        {
            cancellation.ThrowIfCancellationRequested();
            string name = Path.GetFileNameWithoutExtension(file);

            BioShockPackage package;
            try
            {
                package = BioShockPackage.Open(file);
            }
            catch (Exception ex) when (ex is InvalidDataException or IOException)
            {
                // A package that will not open is itself a diagnostic, and a silent skip here would
                // make the coverage figures a lie.
                report = report.Merge(new DiagnosticReport
                {
                    Diagnostics =
                    [
                        new Diagnostic
                        {
                            Code = DiagnosticCodes.PackageUnreadable,
                            Subsystem = DiagnosticSubsystem.Package,
                            Severity = DiagnosticSeverity.Broken,
                            Package = name,
                            Group = string.Empty,
                            Asset = name,
                            ClassName = "Package",
                            Summary = "This package could not be opened, so nothing in it was examined.",
                            Evidence = $"{ex.GetType().Name}: {ex.Message}",
                            Reference = "docs/research/packages.md",
                        },
                    ],
                    Coverage = new DiagnosticCoverage { Packages = 1 },
                });
                continue;
            }

            using (package)
            {
                report = report.Merge(ScanPackage(package, name, external, bulk, cancellation));
            }

            progress?.Invoke($"{name}: {report.Diagnostics.Count:N0} diagnostics so far");
        }

        return report;
    }

    /// <summary>
    /// Scans one open package. <paramref name="external"/> and <paramref name="bulk"/> should be the
    /// same objects the export pipeline uses, or the scan will report faults the pipeline does not
    /// have.
    /// </summary>
    public static DiagnosticReport ScanPackage(
        BioShockPackage package,
        string packageName,
        IExternalMaterialSource? external = null,
        BulkTextureCatalog? bulk = null,
        CancellationToken cancellation = default,
        Action<int, int>? progress = null)
    {
        var found = new List<Diagnostic>();
        int meshes = 0, materials = 0, textures = 0;

        for (int index = 0; index < package.Exports.Count; index++)
        {
            cancellation.ThrowIfCancellationRequested();

            // A package is minutes' work — every texture in it is decoded — so a caller driving this
            // from a window has to be able to say how far in it is.
            if (progress is not null && index % 256 == 0) progress(index, package.Exports.Count);

            switch (ScanExport(package, packageName, index, external, bulk, found))
            {
                case DiagnosticSubsystem.Geometry: meshes++; break;
                case DiagnosticSubsystem.Materials: materials++; break;
                case DiagnosticSubsystem.Textures: textures++; break;
            }
        }

        return new DiagnosticReport
        {
            Diagnostics = found,
            Coverage = new DiagnosticCoverage
            {
                Packages = 1,
                Meshes = meshes,
                Materials = materials,
                Textures = textures,
            },
        };
    }

    /// <summary>
    /// Scans one export, appending to <paramref name="found"/>, and returns which kind of asset it
    /// turned out to be — or null when it is not one this checks.
    /// </summary>
    /// <remarks>
    /// Public so a caller can check one selected asset without paying for its whole package. The
    /// per-export path and the whole-package path are the same code, so the two cannot report
    /// different things about the same asset.
    /// </remarks>
    public static DiagnosticSubsystem? ScanExport(
        BioShockPackage package,
        string packageName,
        int index,
        IExternalMaterialSource? external,
        BulkTextureCatalog? bulk,
        List<Diagnostic> found)
    {
        if (index < 0 || index >= package.Exports.Count) return null;

        var export = package.Exports[index];
        if (export.SerialSize <= 0) return null;

        string className = package.GetClassName(export);

        if (MeshGeometryReader.IsMeshClass(className))
        {
            ScanMesh(package, packageName, export, index, className, external, found);
            return DiagnosticSubsystem.Geometry;
        }

        // Checked before IsMaterialClass: a Texture export is unambiguously a texture asset for
        // sweep purposes. IsMaterialClass also answers true for "Texture" — a Texture named directly
        // in a mesh's material slot is itself a material there — but that is a different question
        // (what a *slot* resolves to) from what *this export itself* is. Checking materials first
        // swallowed every Texture export into the Materials bucket and left the sweep reporting zero
        // textures examined.
        if (className == TextureReader.ClassName)
        {
            ScanTexture(package, packageName, export, index, className, bulk, found);
            return DiagnosticSubsystem.Textures;
        }

        if (MaterialReader.IsMaterialClass(className))
        {
            ScanMaterial(package, packageName, export, index, className, found);
            return DiagnosticSubsystem.Materials;
        }

        return null;
    }

    // ------------------------------------------------------------------------------------ meshes

    private static void ScanMesh(
        BioShockPackage package, string packageName, ObjectExport export, int index, string className,
        IExternalMaterialSource? external, List<Diagnostic> found)
    {
        // A mesh produces diagnostics from two subsystems — the geometry reader and the material
        // resolver — so each check states which it came from rather than it being derived from the
        // code's spelling.
        Diagnostic Row(string code, DiagnosticSubsystem subsystem, DiagnosticSeverity severity,
            string summary, string evidence, string reference) => new()
        {
            Code = code,
            Subsystem = subsystem,
            Severity = severity,
            Package = packageName,
            Group = AssetContextResolver.TopLevelGroup(package, export),
            Asset = export.ObjectName,
            ClassName = className,
            Summary = summary,
            Evidence = evidence,
            Reference = reference,
            ExportIndex = index,
        };

        byte[] payload;
        MeshGeometry? geometry;

        try
        {
            payload = package.ReadExportData(export);
            geometry = MeshGeometryReader.Read(className, payload);
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException or IOException)
        {
            found.Add(Row(DiagnosticCodes.MeshUnreadable, DiagnosticSubsystem.Geometry, DiagnosticSeverity.Broken,
                "This mesh could not be read at all, so it cannot be shown or exported.",
                $"{className}, {export.SerialSize:N0} byte payload; reader threw {ex.GetType().Name}: {ex.Message}",
                "docs/research/skeletalmesh.md, docs/research/staticmesh.md"));
            return;
        }

        string note = className == AssetClasses.StaticMesh ? "staticmesh" : "skeletalmesh";

        if (geometry is null || geometry.Vertices.Count == 0)
        {
            found.Add(Row(DiagnosticCodes.MeshNoGeometry, DiagnosticSubsystem.Geometry, DiagnosticSeverity.Broken,
                "No vertex data was found in this mesh, so it has no geometry to show or export.",
                $"{className}, {export.SerialSize:N0} byte payload, reader returned "
                + (geometry is null ? "nothing" : "0 vertices"),
                $"docs/research/{note}.md"));
            return;
        }

        // A UV of 6e36 is not a texture coordinate. Two meshes in the game do this and everything
        // else about them decodes, which is exactly the shape of fault a render does not show.
        int badUvs = 0;
        float worstUv = 0f;
        foreach (var vertex in geometry.Vertices)
        {
            float worst = MathF.Max(MathF.Abs(vertex.Uv.X), MathF.Abs(vertex.Uv.Y));
            if (float.IsFinite(worst) && worst <= MaximumPlausibleUv) continue;
            badUvs++;
            if (!float.IsFinite(worst)) worstUv = float.PositiveInfinity;
            else if (worst > worstUv) worstUv = worst;
        }

        if (badUvs > 0)
        {
            found.Add(Row(DiagnosticCodes.MeshUvOutOfRange, DiagnosticSubsystem.Geometry, DiagnosticSeverity.Degraded,
                "This mesh's texture coordinates are not usable, so it will be textured wrongly.",
                $"{badUvs:N0} of {geometry.Vertices.Count:N0} vertices carry a UV component of "
                + $"{worstUv:0.###e+0}; the plausible bound is {MaximumPlausibleUv:0.###e+0}",
                $"docs/research/{note}.md"));
        }

        IReadOnlyList<MeshSurface> surfaces;
        IReadOnlyList<PackageIndex> slots;

        try
        {
            slots = MaterialReader.ReadMeshMaterialSlots(payload, package);
            surfaces = MeshSurfaceResolver.Resolve(package, slots, geometry, external);
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            found.Add(Row(DiagnosticCodes.MeshSlotUnresolved, DiagnosticSubsystem.Materials, DiagnosticSeverity.Degraded,
                "This mesh's material list could not be read, so it draws untextured.",
                $"{ex.GetType().Name}: {ex.Message}",
                "docs/research/materials.md"));
            return;
        }

        var unresolved = surfaces.Where(s => s.Material is null).ToList();
        if (unresolved.Count > 0)
        {
            int triangles = unresolved.Sum(s => s.TriangleCount);
            found.Add(Row(DiagnosticCodes.MeshSlotUnresolved, DiagnosticSubsystem.Materials, DiagnosticSeverity.Degraded,
                $"{unresolved.Count} of this mesh's {surfaces.Count} surface(s) have no material, "
                + "so those triangles draw untextured.",
                $"{triangles:N0} of {geometry.TriangleCount:N0} triangles; "
                + string.Join(", ", unresolved.Select(s => $"slot {s.Slot} {Describe(package, s.MaterialReference)}")),
                "docs/research/materials.md"));
        }

        var resolved = surfaces.Where(s => s.Material is not null).Select(s => s.Material!).ToList();
        if (resolved.Count > 0 && resolved.TrueForAll(m => m.DiffuseTexture is null))
        {
            found.Add(Row(DiagnosticCodes.MeshNoDiffuse, DiagnosticSubsystem.Materials, DiagnosticSeverity.Degraded,
                "This mesh resolves its material but the material binds no base colour texture, "
                + "so it draws flat.",
                string.Join(", ", resolved
                    .Select(m => $"{m.ClassName} {m.Name} ({m.Textures.Count} texture slot(s))")
                    .Distinct(StringComparer.Ordinal)),
                "docs/research/materials.md"));
        }

        // A skeletal mesh has no section table — the table belongs to the StaticMesh container — so
        // one naming several materials draws entirely in one of them. Reported as a Note because it
        // is a known limit of what is decoded, not a fault in this asset.
        int named = slots.Count(s => !s.IsNull);
        if (className == AssetClasses.SkeletalMesh && named > 1)
        {
            found.Add(Row(DiagnosticCodes.MeshNoSections, DiagnosticSubsystem.Materials, DiagnosticSeverity.Note,
                $"This mesh names {named} materials, but a skeletal mesh carries no table saying "
                + "which triangles use which, so all of it draws in one.",
                $"{named} non-null material slots; {geometry.TriangleCount:N0} triangles in "
                + $"{surfaces.Count} surface(s)",
                "docs/HANDOFF.md item 6 under NEXT CLAUDE SESSION"));
        }
    }

    /// <summary>What a material slot points at, said plainly enough to act on.</summary>
    private static string Describe(BioShockPackage package, PackageIndex reference)
    {
        if (reference.IsNull) return "names nothing";

        if (reference.IsImport && reference.ImportIndex < package.Imports.Count)
        {
            var import = package.Imports[reference.ImportIndex];
            return $"imports '{import.ObjectName}' ({import.ClassName}) and it did not resolve";
        }

        if (reference.IsExport && reference.ExportIndex < package.Exports.Count)
        {
            var target = package.Exports[reference.ExportIndex];
            return $"names '{target.ObjectName}' ({package.GetClassName(target)}) and it did not decode";
        }

        return $"holds reference {reference.Value}, which is outside this package's tables";
    }

    // --------------------------------------------------------------------------------- materials

    private static void ScanMaterial(
        BioShockPackage package, string packageName, ObjectExport export, int index, string className,
        List<Diagnostic> found)
    {
        Diagnostic Row(string code, DiagnosticSeverity severity, string summary, string evidence) => new()
        {
            Code = code,
            Subsystem = DiagnosticSubsystem.Materials,
            Severity = severity,
            Package = packageName,
            Group = AssetContextResolver.TopLevelGroup(package, export),
            Asset = export.ObjectName,
            ClassName = className,
            Summary = summary,
            Evidence = evidence,
            Reference = "docs/research/materials.md",
            ExportIndex = index,
        };

        BioShockMaterial? material;
        try
        {
            material = MaterialReader.Read(package, export);
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException or IOException)
        {
            found.Add(Row(DiagnosticCodes.MaterialUnreadable, DiagnosticSeverity.Broken,
                "This material could not be read, so anything using it draws untextured.",
                $"{className}, {export.SerialSize:N0} byte payload; reader threw "
                + $"{ex.GetType().Name}: {ex.Message}"));
            return;
        }

        if (material is null)
        {
            found.Add(Row(DiagnosticCodes.MaterialUnreadable, DiagnosticSeverity.Broken,
                "This material could not be read, so anything using it draws untextured.",
                $"{className}, {export.SerialSize:N0} byte payload, reader returned nothing"));
            return;
        }

        if (material.Truncated)
        {
            found.Add(Row(DiagnosticCodes.MaterialTruncated, DiagnosticSeverity.Degraded,
                "Only part of this material could be read, so some of its settings are missing.",
                $"{material.ClassName}, property walk stopped before the terminator; "
                + $"{material.Textures.Count} texture slot(s) read"
                + (material.UnhandledProperties.Count > 0
                    ? $"; uninterpreted: {string.Join(", ", material.UnhandledProperties.Distinct().Take(8))}"
                    : string.Empty)));
        }
    }

    // ---------------------------------------------------------------------------------- textures

    private static void ScanTexture(
        BioShockPackage package, string packageName, ObjectExport export, int index, string className,
        BulkTextureCatalog? bulk, List<Diagnostic> found)
    {
        Diagnostic Row(string code, DiagnosticSeverity severity, string summary, string evidence) => new()
        {
            Code = code,
            Subsystem = DiagnosticSubsystem.Textures,
            Severity = severity,
            Package = packageName,
            Group = AssetContextResolver.TopLevelGroup(package, export),
            Asset = export.ObjectName,
            ClassName = className,
            Summary = summary,
            Evidence = evidence,
            Reference = "docs/research/bulkcontent.md",
            ExportIndex = index,
        };

        BioShockTexture? texture;
        try
        {
            texture = TextureReader.Read(package, export, bulk);
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException or IOException)
        {
            found.Add(Row(DiagnosticCodes.TextureUndecodable, DiagnosticSeverity.Broken,
                "This texture could not be decoded, so it cannot be shown or written out.",
                $"{export.SerialSize:N0} byte payload; reader threw {ex.GetType().Name}: {ex.Message}"));
            return;
        }

        if (texture is null)
        {
            // "Would not decode" is a symptom. The reader knows which of its own preconditions
            // failed — an undeclared format ordinal, a missing property, no mip chain — and that is
            // the part a future session can act on.
            found.Add(Row(DiagnosticCodes.TextureUndecodable, DiagnosticSeverity.Broken,
                "This texture could not be decoded, so it cannot be shown or written out.",
                $"{export.SerialSize:N0} byte payload; {TextureReader.DescribeFailure(package, export)}"));
            return;
        }

        // The package ships the bottom of the mip chain for most of the game; the top lives in
        // BulkContent. Without the missing levels the asset is not wrong, it is small — and it looks
        // merely blurry rather than broken, which is why this needs saying.
        if (!texture.IsComplete)
        {
            found.Add(Row(DiagnosticCodes.TextureMipsUnrecovered, DiagnosticSeverity.Degraded,
                "Only the small end of this texture was found, so it will be exported blurry.",
                $"declared {texture.DeclaredWidth}×{texture.DeclaredHeight}, recovered "
                + $"{texture.Width}×{texture.Height} from {texture.Mips.Count} mip(s); "
                + $"StrippedNumMips {texture.StrippedMipCount}"
                + (bulk is null ? "; no bulk catalogue was supplied" : string.Empty)));
        }
    }

    // --------------------------------------------------------------------------------- animation

    /// <summary>
    /// Turns an animation audit into diagnostics. Kept separate from the package scan because the
    /// audit is a whole-game sweep in its own right and costs minutes; a caller that has already run
    /// it should not run it twice.
    /// </summary>
    public static DiagnosticReport FromAnimationAudit(AnimationAuditReport audit)
    {
        var found = new List<Diagnostic>();

        foreach (var (package, wrapper, reason) in audit.PackageFailures)
        {
            found.Add(new Diagnostic
            {
                Code = DiagnosticCodes.AnimationPackageFailed,
                Subsystem = DiagnosticSubsystem.Animation,
                Severity = DiagnosticSeverity.Broken,
                Package = package,
                Group = wrapper,
                Asset = wrapper,
                ClassName = AssetClasses.AnimationPackageWrapper,
                Summary = "This animation package would not load, so none of its animations are available.",
                Evidence = reason,
                Reference = "docs/research/animationpackage.md",
            });
        }

        foreach (var row in audit.Rows)
        {
            Diagnostic Row(string code, DiagnosticSeverity severity, string summary, string evidence,
                string reference = "docs/research/havok-compression.md") => new()
            {
                Code = code,
                Subsystem = DiagnosticSubsystem.Animation,
                Severity = severity,
                Package = row.Package,
                Group = row.Wrapper,
                Asset = row.Name,
                ClassName = AssetClasses.AnimationPackageWrapper,
                Summary = summary,
                Evidence = evidence,
                Reference = reference,
            };

            string where = $"{row.SkeletonName}, {row.TrackCount} tracks over {row.BoneCount} bones, "
                           + $"{row.FrameCount} frames at {row.FrameRate:0.##} fps";

            switch (row.Status)
            {
                case AnimationStatus.Failed or AnimationStatus.PackageFailed:
                    found.Add(Row(DiagnosticCodes.AnimationFailed, DiagnosticSeverity.Broken,
                        "This animation did not decode, so it cannot be played or exported.",
                        $"{row.Reason}; {where}"));
                    break;

                case AnimationStatus.Unsupported:
                    found.Add(Row(DiagnosticCodes.AnimationUnsupported, DiagnosticSeverity.Note,
                        "This animation uses a compression form this tool does not implement.",
                        $"{row.Reason}; {where}"));
                    break;

                case AnimationStatus.Partial:
                    found.Add(Row(DiagnosticCodes.AnimationPartial, DiagnosticSeverity.Degraded,
                        "This animation decoded, but something about it is not fit to play.",
                        $"{row.Reason}; {where}"));
                    break;
            }

            // Only an animation that actually decoded has a block walk to judge. One that failed, or
            // whose compression is not implemented, never walked a block, and reporting its default
            // "incomplete" as a decode fault would blame the reader twice for one thing.
            if (row.Status is AnimationStatus.Playable or AnimationStatus.Partial
                && !row.BlocksLookComplete)
            {
                found.Add(Row(DiagnosticCodes.AnimationBlockSlack, DiagnosticSeverity.Broken,
                    "This animation's compressed data was not read to the end, so tracks after the "
                    + "break are decoded from the wrong place.",
                    $"worst block left {row.WorstBlockSlack} bytes unread against a 16-byte pad; {where}"));
            }

            // A rigid skeleton cannot fold a bone into its parent. This is the check the audit did
            // not have when a user photographed an armless splicer, and the whole reason it exists.
            if (row.WorstCollapsedBones > 0)
            {
                found.Add(Row(DiagnosticCodes.AnimationBonesCollapse, DiagnosticSeverity.Degraded,
                    $"{row.WorstCollapsedBones} bone(s) sit on top of their parent in this animation "
                    + "— a limb folded into the body.",
                    $"worst at frame {row.WorstCollapseFrame}"
                    + (row.WorstCollapseBone.Length > 0 ? $", first {row.WorstCollapseBone}" : string.Empty)
                    + $"; {where}",
                    "docs/HANDOFF.md §6.0c"));
            }
        }

        return new DiagnosticReport
        {
            Diagnostics = found,
            Coverage = new DiagnosticCoverage
            {
                Packages = audit.PackageCount,
                Animations = audit.Total,
            },
        };
    }
}
