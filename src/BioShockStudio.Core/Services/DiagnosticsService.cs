using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Diagnostics;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Services;

/// <summary>
/// Runs the diagnostic checks against what the catalogue has loaded, at the scope the caller asks
/// for.
/// </summary>
/// <remarks>
/// <para>
/// The checks themselves are in <see cref="AssetDiagnostics"/>, which knows nothing about the
/// catalogue. This class exists so a caller — the Problems panel, the health report, the CLI — asks
/// for "this asset", "this package" or "everything" without having to open packages or find the
/// external material source and the bulk texture catalogue itself. Getting those two wrong is what
/// would make the panel report faults the exporter does not have.
/// </para>
/// <para>
/// A per-asset scan is cheap enough to run on selection; a whole-game scan is not, and is a job the
/// caller drives on a background thread with progress.
/// </para>
/// </remarks>
public sealed class DiagnosticsService(AssetCatalogService catalog)
{
    /// <summary>
    /// Everything wrong with one catalogue entry's own asset — its mesh, its materials or its
    /// texture, whichever it is.
    /// </summary>
    /// <remarks>
    /// Animation is not covered here: an animation's faults are found by decoding the whole wrapper,
    /// which is <see cref="AnimationAudit"/>'s job. <see cref="ScanAnimations"/> does that for the
    /// whole game.
    /// </remarks>
    public DiagnosticReport ScanAsset(CatalogEntry entry, CancellationToken cancellation = default)
    {
        using var package = BioShockPackage.Open(catalog.PackageFile(entry.Package));

        var found = new List<Diagnostic>();
        var coverage = new DiagnosticCoverage { Packages = 1 };

        foreach (int index in ExportsFor(package, entry))
        {
            cancellation.ThrowIfCancellationRequested();

            var kind = AssetDiagnostics.ScanExport(
                package, entry.Package, index, catalog.ExternalMaterials, catalog.Bulk, found);

            coverage = kind switch
            {
                DiagnosticSubsystem.Geometry => coverage with { Meshes = coverage.Meshes + 1 },
                DiagnosticSubsystem.Materials => coverage with { Materials = coverage.Materials + 1 },
                DiagnosticSubsystem.Textures => coverage with { Textures = coverage.Textures + 1 },
                _ => coverage,
            };
        }

        return new DiagnosticReport { Diagnostics = found, Coverage = coverage };
    }

    /// <summary>
    /// Which exports one catalogue row is about.
    /// </summary>
    /// <remarks>
    /// A leaf row — a mesh, a material, a texture — is one export. A group row is a character, weapon
    /// or prop, and what a user means by "what is wrong with the Bouncer" is everything the group
    /// draws with: its meshes, the props on its sockets and their materials. Scanning the whole
    /// package instead would be correct and far too slow to run on a selection change.
    /// </remarks>
    private static IEnumerable<int> ExportsFor(BioShockPackage package, CatalogEntry entry)
    {
        // Keyed by reference, not by value: ObjectExport is a record, and two exports of the same
        // object in one package would compare equal and collapse onto one index.
        var byIdentity = new Dictionary<ObjectExport, int>(ReferenceEqualityComparer.Instance);
        for (int i = 0; i < package.Exports.Count; i++) byIdentity[package.Exports[i]] = i;

        if (entry.ExportIndex >= 0 && entry.ExportIndex < package.Exports.Count
            && IsCheckable(package, package.Exports[entry.ExportIndex]))
        {
            yield return entry.ExportIndex;
            yield break;
        }

        if (entry.Group.Length == 0) yield break;

        var context = AssetContextResolver.Resolve(package, entry.Group);
        foreach (var member in context.Members)
        {
            if (!IsCheckable(package, member)) continue;
            if (byIdentity.TryGetValue(member, out int index)) yield return index;
        }
    }

    private static bool IsCheckable(BioShockPackage package, ObjectExport export)
    {
        if (export.SerialSize <= 0) return false;
        string className = package.GetClassName(export);
        return Core.Mesh.MeshGeometryReader.IsMeshClass(className)
               || Core.Materials.MaterialReader.IsMaterialClass(className)
               || className == Core.Textures.TextureReader.ClassName;
    }

    /// <summary>Everything wrong with the meshes, materials and textures of one package.</summary>
    public DiagnosticReport ScanPackage(
        string packageName, CancellationToken cancellation = default, Action<string>? progress = null)
    {
        using var package = BioShockPackage.Open(catalog.PackageFile(packageName));

        return AssetDiagnostics.ScanPackage(
            package, packageName, catalog.ExternalMaterials, catalog.Bulk, cancellation,
            progress is null
                ? null
                : (done, total) => progress($"{packageName}  ·  {done:N0} / {total:N0} exports"));
    }

    /// <summary>
    /// Every mesh, material and texture in the install. Minutes, not seconds — drive it from a
    /// background thread and show <paramref name="progress"/>.
    /// </summary>
    public DiagnosticReport ScanEverything(
        string gameRoot, Action<string>? progress = null, CancellationToken cancellation = default) =>
        AssetDiagnostics.Run(gameRoot, catalog.ExternalMaterials, catalog.Bulk, progress, cancellation);

    /// <summary>
    /// The animation half — a whole-game decode. This is <see cref="AnimationAudit"/> translated into
    /// diagnostics, and it is the expensive one.
    /// </summary>
    public static DiagnosticReport ScanAnimations(string gameRoot, Action<string>? progress = null) =>
        AssetDiagnostics.FromAnimationAudit(AnimationAudit.Run(gameRoot, progress));
}
