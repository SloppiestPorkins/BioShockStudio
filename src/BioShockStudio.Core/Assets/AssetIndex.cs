using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Assets;

/// <summary>One export, recorded with the package it came from.</summary>
public sealed record AssetRecord
{
    public required string PackageFile { get; init; }
    public required string PackageName { get; init; }
    public required int ExportIndex { get; init; }
    public required string ObjectName { get; init; }
    public required string ClassName { get; init; }
    public required int SerialSize { get; init; }
    public required int SerialOffset { get; init; }

    public override string ToString() => $"{ClassName} {ObjectName} ({PackageName})";
}

/// <summary>Classes that matter to the skeletal-mesh/animation pipeline.</summary>
public static class AssetClasses
{
    public const string SkeletalMesh = "SkeletalMesh";
    public const string StaticMesh = "StaticMesh";
    public const string AnimationPackageWrapper = "AnimationPackageWrapper";
    public const string SharedSkeletonAnimationMetadata = "SharedSkeletonAnimationMetadata";
    public const string HkMeshProxy = "HkMeshProxy";

    public static readonly IReadOnlySet<string> Interesting = new HashSet<string>(StringComparer.Ordinal)
    {
        SkeletalMesh, StaticMesh, AnimationPackageWrapper, SharedSkeletonAnimationMetadata, HkMeshProxy,
    };
}

/// <summary>
/// A flat index of every export in every shipped package.
/// <para>
/// Building it reads only the package tables, never the payloads, so a full-game index over ~4.8 GB
/// of packages costs a few seconds and a modest amount of memory.
/// </para>
/// </summary>
public sealed class AssetIndex
{
    public IReadOnlyList<AssetRecord> Assets { get; }
    public IReadOnlyList<PackageScanResult> Packages { get; }

    private AssetIndex(List<AssetRecord> assets, List<PackageScanResult> packages)
    {
        Assets = assets;
        Packages = packages;
    }

    /// <summary>
    /// Indexes every package under the install.
    /// <paramref name="classFilter"/> limits which classes are retained; null keeps everything.
    /// </summary>
    public static AssetIndex Build(string gameRoot, IReadOnlySet<string>? classFilter = null)
    {
        var assets = new List<AssetRecord>();
        var packages = new List<PackageScanResult>();

        foreach (string file in GameLocator.EnumeratePackages(gameRoot))
        {
            string packageName = Path.GetFileNameWithoutExtension(file);
            try
            {
                using var package = BioShockPackage.Open(file);
                foreach (var export in package.Exports)
                {
                    string className = package.GetClassName(export);
                    if (classFilter is not null && !classFilter.Contains(className)) continue;

                    assets.Add(new AssetRecord
                    {
                        PackageFile = file,
                        PackageName = packageName,
                        ExportIndex = export.Index,
                        ObjectName = export.ObjectName,
                        ClassName = className,
                        SerialSize = export.SerialSize,
                        SerialOffset = export.SerialOffset,
                    });
                }

                packages.Add(new PackageScanResult
                {
                    PackageFile = file,
                    PackageName = packageName,
                    NameCount = package.Summary.NameCount,
                    ImportCount = package.Summary.ImportCount,
                    ExportCount = package.Summary.ExportCount,
                    TableEndMatchesFileLength = package.ExportTableEnd == new FileInfo(file).Length,
                    Error = null,
                });
            }
            catch (Exception ex)
            {
                // Rule 23: one unsupported package must never abort the scan.
                packages.Add(new PackageScanResult
                {
                    PackageFile = file,
                    PackageName = packageName,
                    NameCount = 0,
                    ImportCount = 0,
                    ExportCount = 0,
                    TableEndMatchesFileLength = false,
                    Error = ex.Message,
                });
            }
        }

        return new AssetIndex(assets, packages);
    }

    public IEnumerable<AssetRecord> Search(string pattern, string? className = null)
    {
        foreach (var asset in Assets)
        {
            if (className is not null && !string.Equals(asset.ClassName, className, StringComparison.OrdinalIgnoreCase))
                continue;
            if (asset.ObjectName.Contains(pattern, StringComparison.OrdinalIgnoreCase))
                yield return asset;
        }
    }
}

public sealed record PackageScanResult
{
    public required string PackageFile { get; init; }
    public required string PackageName { get; init; }
    public required int NameCount { get; init; }
    public required int ImportCount { get; init; }
    public required int ExportCount { get; init; }

    /// <summary>
    /// True when the export table consumed the file exactly. This is the strongest available
    /// whole-file check that the table layout is right.
    /// </summary>
    public required bool TableEndMatchesFileLength { get; init; }

    public required string? Error { get; init; }
}
