using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Diagnostics;

/// <summary>One container family required by the UE5 export path, measured from real package bytes.</summary>
public sealed record Ue5ContainerCoverage(string Family, int Found, int Decoded, int NoGeometry, int Failed)
{
    public int Accounted => Decoded + NoGeometry + Failed;
}

/// <summary>One concrete export blocking complete UE5 container coverage.</summary>
public sealed record Ue5CoverageFailure(
    string Family, string Package, string ObjectName, string ClassName, string Reason);

/// <summary>
/// Whole-game decode baseline for the UE5 programme. This deliberately reports failure counts
/// rather than treating a parsable export table as proof that an asset is ready to import.
/// </summary>
public sealed record Ue5CoverageReport
{
    public required int Packages { get; init; }
    public required int PackageFailures { get; init; }
    public required IReadOnlyList<Ue5ContainerCoverage> Containers { get; init; }
    public required IReadOnlyList<Ue5CoverageFailure> Failures { get; init; }

    public static Ue5CoverageReport Build(string gameRoot, IProgress<string>? progress = null)
    {
        int packages = 0, packageFailures = 0;
        var failures = new List<Ue5CoverageFailure>();
        var counters = new Dictionary<string, (int Found, int Decoded, int NoGeometry, int Failed)>(StringComparer.Ordinal)
        {
            ["StaticMesh geometry"] = default,
            ["SkeletalMesh geometry"] = default,
            ["Texture headers"] = default,
            ["Rendered material defaults"] = default,
        };

        foreach (string file in Core.Game.GameLocator.EnumeratePackages(gameRoot))
        {
            try
            {
                using var package = BioShockPackage.Open(file);
                packages++;
                progress?.Report(Path.GetFileName(file));

                foreach (var export in package.Exports)
                {
                    if (export.SerialSize <= 0) continue;
                    string className = package.GetClassName(export);

                    if (className == AssetClasses.StaticMesh)
                        Count("StaticMesh geometry", package, export,
                            () => StaticMeshReader.ReadGeometry(package.ReadExportData(export)) is not null);
                    else if (className == AssetClasses.SkeletalMesh)
                        CountSkeletal(package, export);
                    else if (className == TextureReader.ClassName)
                        Count("Texture headers", package, export,
                            () => TextureReader.ReadHeader(package, export) is not null);
                    else if (className.EndsWith("Shader", StringComparison.Ordinal)
                             || className == "MaterialSwitch")
                        Count("Rendered material defaults", package, export,
                            () => MaterialReader.Read(package, export) is not null);
                }
            }
            catch (Exception ex) when (ex is IOException or InvalidDataException or ArgumentOutOfRangeException)
            {
                packageFailures++;
            }
        }

        return new Ue5CoverageReport
        {
            Packages = packages,
            PackageFailures = packageFailures,
            Containers = counters
                .Select(pair => new Ue5ContainerCoverage(pair.Key, pair.Value.Found, pair.Value.Decoded,
                    pair.Value.NoGeometry, pair.Value.Failed))
                .ToList(),
            Failures = failures,
        };

        void Count(string family, BioShockPackage package, ObjectExport export, Func<bool> decode)
        {
            var count = counters[family];
            count.Found++;
            try
            {
                if (decode()) count.Decoded++;
                else
                {
                    count.Failed++;
                    failures.Add(new Ue5CoverageFailure(family, Path.GetFileName(package.FilePath), export.ObjectName,
                        package.GetClassName(export), "reader returned no usable container"));
                }
            }
            catch (Exception ex) when (ex is IOException or InvalidDataException or ArgumentOutOfRangeException)
            {
                count.Failed++;
                failures.Add(new Ue5CoverageFailure(family, Path.GetFileName(package.FilePath), export.ObjectName,
                    package.GetClassName(export), ex.Message));
            }
            counters[family] = count;
        }

        void CountSkeletal(BioShockPackage package, ObjectExport export)
        {
            const string family = "SkeletalMesh geometry";
            var count = counters[family];
            count.Found++;
            try
            {
                if (SkeletalMeshReader.ReadGeometry(package.ReadExportData(export)) is not null)
                    count.Decoded++;
                else
                    // A rig with no vertex chain is valid game data: animated door leaves can be
                    // BSP level geometry, attached at its decoded sockets. It is not an unread
                    // skeletal vertex format. SkeletalMeshGeometryTests holds the complete set.
                    count.NoGeometry++;
            }
            catch (Exception ex) when (ex is IOException or InvalidDataException or ArgumentOutOfRangeException)
            {
                count.Failed++;
                failures.Add(new Ue5CoverageFailure(family, Path.GetFileName(package.FilePath), export.ObjectName,
                    package.GetClassName(export), ex.Message));
            }
            counters[family] = count;
        }
    }
}
