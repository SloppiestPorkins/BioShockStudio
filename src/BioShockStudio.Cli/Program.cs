using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Diagnostics;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Havok.Detection;
using BioShockStudio.Core.Havok.Packfile;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;

if (args.Length == 0)
{
    Usage();
    return 1;
}

string? root = GameLocator.Find();
if (root is null)
{
    Console.Error.WriteLine(
        $"BioShock 1 Remastered not found. Set {GameLocator.PathOverrideVariable} to the install directory.");
    return 2;
}

try
{
    return args[0].ToLowerInvariant() switch
    {
        "scan" => Scan(root),
        "assets" => Assets(root, args),
        "inspect" => Inspect(root, args),
        "havok" => Havok(root, args),
        "properties" => Properties(root, args),
        "materials" => Materials(root, args),
        "skeleton" => Skeleton(root, args),
        "animations" => Animations(root, args),
        "export-blender" => ExportBlender(root, args),
        "export-fbx" => ExportFbx(root, args),
        "meshes" => Meshes(root, args),
        "context" => Context(root, args),
        "characters" => Characters(root, args),
        "textures" => Textures(root, args),
        "export-textures" => ExportTextures(root, args),
        "animation" => AnimationInspect(root, args),
        "export-firstperson" => ExportFirstPerson(root, args),
        "audit-animations" => AuditAnimations(root, args),
        "diagnose" => Diagnose(root, args),
        "names" => Names(root, args),
        _ => Usage(),
    };
}
catch (Exception ex)
{
    Console.Error.WriteLine($"error: {ex.Message}");
    return 1;
}

static int Usage()
{
    Console.WriteLine("""
        bioshock-tool <command>

          scan                          Parse every shipped package and report table integrity.
          assets [--class C] [pattern]  List indexed assets, optionally filtered.
          inspect <package> [pattern]   Show a package's header, imports and exports.
          havok <package> <object>      Parse the Havok packfiles inside an export's payload.
          skeleton <package> <object>   Show the skeleton of an AnimationPackageWrapper.
          animations <package> <object> [owner]
                                        List decoded animations, optionally for one weapon.
          meshes <package>              Report which SkeletalMeshes decode to geometry.
          materials <package> [pattern] Resolve each SkeletalMesh's material and its textures.
          properties <package> <object|--class C> [n]
                                        Dump an export's Unreal property list and what follows it.
          context <package> <group>     Show an asset group and everything it owns.
          characters <package>          List animated character assets in a package.
          textures <package> [pattern]  List textures with format and size.
          export-textures <package> <out-dir> [pattern]
                                        Write textures as PNG (and DDS when compressed).
          animation inspect <package> <object> <animation>
                                        Dump an animation's tracks, samples and events.
          export-blender <package> <object> <out-dir> [owner]
                                        Write scene JSON for the Blender importer.
          export-fbx <package> <object> <out-dir> [owner]
                                        Write FBX (mesh, skeleton, one file per animation) plus a
                                        manifest for the Unreal importer.
          audit-animations [out.csv]    Decode every animation in the game and report coverage.
          diagnose [package] [--animations] [--code C] [--out report.csv]
                                        Report every asset this tool knows is broken or degraded,
                                        with the evidence. One package, or the whole game.
          export-firstperson <weapon> <out-dir> [--fbx] [--preview=<animation>]
                                        Assemble the hands, the weapon and both animation sets.
                                        --preview also writes a mesh-plus-animation file to look at.

        Set BIOSHOCK_REMASTERED_PATH to override game auto-detection.
        """);
    return 0;
}

static int Scan(string root)
{
    Console.WriteLine($"game: {root}");
    var index = AssetIndex.Build(root);

    int ok = 0;
    foreach (var p in index.Packages)
    {
        if (p.Error is not null)
        {
            Console.WriteLine($"  FAIL  {p.PackageName}: {p.Error}");
            continue;
        }
        if (!p.TableEndMatchesFileLength)
        {
            Console.WriteLine($"  WARN  {p.PackageName}: export table did not end on EOF");
            continue;
        }
        ok++;
        Console.WriteLine(
            $"  ok    {p.PackageName,-24} names={p.NameCount,-7} imports={p.ImportCount,-6} exports={p.ExportCount}");
    }

    Console.WriteLine($"\n{ok}/{index.Packages.Count} packages parsed byte-exact; {index.Assets.Count} exports indexed.");

    Console.WriteLine("\nclasses relevant to the animation pipeline:");
    foreach (string cls in AssetClasses.Interesting.Order())
        Console.WriteLine($"  {index.Assets.Count(a => a.ClassName == cls),8}  {cls}");

    return 0;
}

static int Assets(string root, string[] args)
{
    string? className = null;
    string? pattern = null;
    for (int i = 1; i < args.Length; i++)
    {
        if (args[i] == "--class" && i + 1 < args.Length) className = args[++i];
        else pattern = args[i];
    }

    var index = AssetIndex.Build(root, AssetClasses.Interesting);
    var results = index.Search(pattern ?? string.Empty, className).ToList();

    foreach (var a in results.OrderBy(a => a.ClassName).ThenBy(a => a.ObjectName))
        Console.WriteLine($"{a.ClassName,-32} {a.ObjectName,-42} {a.SerialSize,10}  {a.PackageName}");

    Console.WriteLine($"\n{results.Count} matches.");
    return 0;
}

static int Inspect(string root, string[] args)
{
    if (args.Length < 2) { Console.Error.WriteLine("usage: inspect <package> [pattern]"); return 1; }

    string file = ResolvePackage(root, args[1]);
    string? pattern = args.Length > 2 ? args[2] : null;

    using var package = BioShockPackage.Open(file);
    var s = package.Summary;
    Console.WriteLine($"{Path.GetFileName(file)}");
    Console.WriteLine($"  version {s.FileVersion}/{s.LicenseeVersion}  flags 0x{s.PackageFlags:X8}  guid {s.Guid}");
    Console.WriteLine($"  names {s.NameCount}  imports {s.ImportCount}  exports {s.ExportCount}");
    Console.WriteLine($"  export table ends at {package.ExportTableEnd} (file length {new FileInfo(file).Length})");

    Console.WriteLine("\nexports:");
    foreach (var e in package.Exports)
    {
        if (pattern is not null && !e.ObjectName.Contains(pattern, StringComparison.OrdinalIgnoreCase)) continue;
        Console.WriteLine(
            $"  [{e.Index,6}] {package.GetClassName(e),-32} {e.ObjectName,-42} size={e.SerialSize,-9} off={e.SerialOffset}");
    }
    return 0;
}

static int Havok(string root, string[] args)
{
    if (args.Length < 3) { Console.Error.WriteLine("usage: havok <package> <object>"); return 1; }

    string file = ResolvePackage(root, args[1]);
    using var package = BioShockPackage.Open(file);

    // Object names repeat within a package (a Package object and the asset it holds share a name),
    // so pick the largest payload with that name.
    var export = package.Exports
        .Where(e => string.Equals(e.ObjectName, args[2], StringComparison.OrdinalIgnoreCase))
        .MaxBy(e => e.SerialSize);
    if (export is null) { Console.Error.WriteLine($"object '{args[2]}' not found in {Path.GetFileName(file)}"); return 1; }

    byte[] payload = package.ReadExportData(export);
    Console.WriteLine($"{package.GetClassName(export)} {export.ObjectName}: {payload.Length} bytes");

    var hits = HavokDetector.FindAll(payload).ToList();
    Console.WriteLine($"{hits.Count} Havok packfile(s) embedded.\n");

    foreach (var hit in hits)
    {
        var hk = HavokPackfile.Parse(payload, hit.Offset);
        Console.WriteLine($"  @{hit.Offset,-10} {hk.Header.ContentsVersion}  fileVersion={hk.Header.FileVersion}  " +
                          $"sections={hk.Header.NumSections}  dataStart={hk.Header.AbsoluteDataStart}  size={hk.TotalSize}");
        Console.WriteLine($"    root class: {hk.ContentsClassName ?? "<unresolved>"}");
        foreach (var section in hk.Sections)
            Console.WriteLine($"    section {section.SectionTag,-16} data={section.DataSize,-8} " +
                              $"local={section.LocalFixupsSize,-7} global={section.GlobalFixupsSize,-7} " +
                              $"virtual={section.VirtualFixupsSize}");
        if (hk.ClassNames.Count > 0)
            Console.WriteLine($"    classes: {string.Join(", ", hk.ClassNames.Values.Distinct().Order())}");
        Console.WriteLine();
    }
    return 0;
}

/// <summary>
/// Dumps an export's Unreal property list and the first bytes of whatever follows it. This is the
/// reconnaissance command: it is how an unparsed class is looked at before anything is written.
/// </summary>
static int Properties(string root, string[] args)
{
    if (args.Length < 3) { Console.Error.WriteLine("usage: properties <package> <object|--class C> [limit]"); return 1; }

    using var package = BioShockPackage.Open(ResolvePackage(root, args[1]));

    bool byClass = args[2] == "--class";
    string selector = byClass ? args[3] : args[2];
    string? limitArgument = args.ElementAtOrDefault(byClass ? 4 : 3);
    int limit = int.TryParse(limitArgument, out int parsed) ? parsed : 1;

    var matches = (byClass
            ? package.Exports.Where(e => package.GetClassName(e) == selector)
            : package.Exports.Where(e => e.ObjectName.Contains(selector, StringComparison.OrdinalIgnoreCase)))
        .OrderByDescending(e => e.SerialSize).Take(limit).ToList();

    foreach (var export in matches)
    {
        byte[] payload = package.ReadExportData(export);
        Console.WriteLine($"\n{package.GetClassName(export)} {export.ObjectName}  " +
                          $"[{export.Index}] {payload.Length} bytes  outer={DescribeReference(package, export.OuterIndex.Value)}");

        int end;
        List<UnrealProperty> properties;
        try { properties = UnrealPropertyReader.Read(payload, package.Names, out end); }
        catch (Exception ex) { Console.WriteLine($"  property list unreadable: {ex.Message}"); continue; }

        foreach (var property in properties)
        {
            string value = property.Type switch
            {
                UnrealPropertyType.Object or UnrealPropertyType.Class =>
                    DescribeReference(package, ReadCompact(property.Value)),
                UnrealPropertyType.Int => property.AsInt().ToString(),
                UnrealPropertyType.Float => property.AsFloat().ToString("0.####"),
                UnrealPropertyType.Byte => property.AsByte().ToString(),
                UnrealPropertyType.Bool => "true",
                UnrealPropertyType.Name => NameOf(package, property.Value),
                _ => Convert.ToHexString(property.Value.Take(24).ToArray()),
            };
            Console.WriteLine($"  {property.Name,-28} {property.Type,-8} {property.StructName,-16} {value}");
        }

        int tail = Math.Min(64, payload.Length - end);
        if (tail > 0)
            Console.WriteLine($"  +{end} trailing {payload.Length - end} bytes: " +
                              Convert.ToHexString(payload.AsSpan(end, tail)));
    }

    Console.WriteLine($"\n{matches.Count} shown.");
    return 0;
}

/// <summary>Resolves an FCompactIndex package reference: positive is an export, negative an import.</summary>
static string DescribeReference(BioShockPackage package, int reference)
{
    var index = new PackageIndex(reference);
    if (index.IsNull) return "<none>";
    if (index.IsExport)
    {
        var export = package.Exports[index.ExportIndex];
        return $"export {package.GetClassName(export)} '{export.ObjectName}'";
    }
    var import = package.Imports[index.ImportIndex];
    return $"import {import.ClassName} '{import.ObjectName}'";
}

static int ReadCompact(byte[] value)
{
    int offset = 0;
    byte b = value[offset++];
    bool negative = (b & 0x80) != 0;
    int result = b & 0x3F;
    if ((b & 0x40) != 0)
    {
        int shift = 6;
        while (offset < value.Length)
        {
            byte c = value[offset++];
            result |= (c & 0x7F) << shift;
            shift += 7;
            if ((c & 0x80) == 0) break;
        }
    }
    return negative ? -result : result;
}

static string NameOf(BioShockPackage package, byte[] value)
{
    int offset = 0;
    byte b = value[offset++];
    int index = b & 0x3F;
    if ((b & 0x40) != 0)
    {
        int shift = 6;
        while (offset < value.Length)
        {
            byte c = value[offset++];
            index |= (c & 0x7F) << shift;
            shift += 7;
            if ((c & 0x80) == 0) break;
        }
    }
    return index >= 0 && index < package.Names.Count ? package.Names[index].Name : $"<name {index}>";
}

static AnimationPackage LoadAnimationPackage(string root, string packageName, string objectName)
{
    using var package = BioShockPackage.Open(ResolvePackage(root, packageName));
    var export = package.Exports
        .Where(e => string.Equals(e.ObjectName, objectName, StringComparison.OrdinalIgnoreCase)
                    && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
        .MaxBy(e => e.SerialSize)
        ?? throw new FileNotFoundException($"No AnimationPackageWrapper named '{objectName}' in {packageName}.");

    return AnimationPackage.Load(package, export);
}

/// <summary>
/// Finds the SkeletalMesh that goes with an AnimationPackageWrapper. The wrappers are named
/// UAPW_&lt;MeshName&gt;, which is a convention rather than a reference, so a miss is reported as
/// "no sockets" rather than treated as an error.
/// </summary>
static (IReadOnlyList<MeshSocket> Sockets, MeshGeometry? Geometry, SceneMaterial? Material) ResolveMesh(
    string root, string packageName, string wrapperName, string? outputDirectory = null)
{
    string meshName = wrapperName.StartsWith("UAPW_", StringComparison.OrdinalIgnoreCase)
        ? wrapperName["UAPW_".Length..]
        : wrapperName;

    using var package = BioShockPackage.Open(ResolvePackage(root, packageName));
    var export = package.Exports
        .Where(e => string.Equals(e.ObjectName, meshName, StringComparison.OrdinalIgnoreCase)
                    && package.GetClassName(e) == AssetClasses.SkeletalMesh)
        .MaxBy(e => e.SerialSize);

    if (export is null) return ([], null, null);

    byte[] payload = package.ReadExportData(export);
    // Textures are only written when there is somewhere to put them; listing commands resolve the
    // mesh without wanting a directory full of PNGs as a side effect.
    var material = outputDirectory is null ? null : MaterialExporter.Resolve(package, export, outputDirectory);

    return (SkeletalMeshReader.ReadSockets(payload, package.Names), SkeletalMeshReader.ReadGeometry(payload), material);
}

/// <summary>
/// Reads each animation's event track from its SharedSkeletonAnimationMetadata sibling. Names are
/// matched case-insensitively: the Havok root table and the Unreal objects disagree on casing.
/// </summary>
static IReadOnlyDictionary<string, IReadOnlyList<AnimationEvent>> ResolveEvents(
    string root, string packageName, AnimationPackage animationPackage)
{
    using var package = BioShockPackage.Open(ResolvePackage(root, packageName));

    var metadata = package.Exports
        .Where(e => package.GetClassName(e) == AnimationMetadataReader.ClassName)
        .GroupBy(e => e.ObjectName, StringComparer.OrdinalIgnoreCase)
        .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

    var result = new Dictionary<string, IReadOnlyList<AnimationEvent>>(StringComparer.Ordinal);
    foreach (var animation in animationPackage.Animations)
    {
        if (!metadata.TryGetValue(AnimationMetadataReader.ObjectPrefix + animation.Name, out var export)) continue;
        var events = AnimationMetadataReader.ReadEvents(package, export, animation.Duration);
        if (events.Count > 0) result[animation.Name] = events;
    }
    return result;
}

static int Skeleton(string root, string[] args)
{
    if (args.Length < 3) { Console.Error.WriteLine("usage: skeleton <package> <object>"); return 1; }

    var animationPackage = LoadAnimationPackage(root, args[1], args[2]);
    var skeleton = animationPackage.Skeleton;

    Console.WriteLine($"{skeleton.Name} — {skeleton.BoneCount} bones (from {skeleton.SourceSection}+{skeleton.SourceOffset})");
    foreach (string line in skeleton.DescribeHierarchy()) Console.WriteLine(line);
    return 0;
}

static int Animations(string root, string[] args)
{
    if (args.Length < 3) { Console.Error.WriteLine("usage: animations <package> <object> [owner]"); return 1; }

    var animationPackage = LoadAnimationPackage(root, args[1], args[2]);
    string? owner = args.Length > 3 ? args[3] : null;

    var selected = (owner is null ? animationPackage.Animations : animationPackage.ForOwner(owner))
        .OrderBy(a => a.Owner).ThenBy(a => a.Name).ToList();

    Console.WriteLine($"{animationPackage.ObjectName}: {animationPackage.Animations.Count} animations, " +
                      $"skeleton '{animationPackage.Skeleton.Name}' with {animationPackage.Skeleton.BoneCount} bones");
    Console.WriteLine($"owners: {string.Join(", ", animationPackage.Owners)}\n");

    Console.WriteLine($"{"owner",-18} {"name",-30} {"secs",6} {"frames",7} {"fps",7} {"tracks",7}  section");
    foreach (var a in selected)
    {
        Console.WriteLine($"{a.Owner,-18} {a.Name,-30} {a.Duration,6:0.00} {a.FrameCount,7} " +
                          $"{a.FrameRate,7:0.00} {a.TransformTrackCount,7}  {a.SectionTag}");
    }

    if (animationPackage.Failures.Count > 0)
    {
        Console.WriteLine($"\n{animationPackage.Failures.Count} undecoded:");
        foreach (var failure in animationPackage.Failures) Console.WriteLine($"  {failure}");
    }

    Console.WriteLine($"\n{selected.Count} shown, {animationPackage.Animations.Count} decoded, " +
                      $"{animationPackage.Failures.Count} unsupported.");
    return 0;
}

/// <summary>
/// Decodes every animation the game ships and reports the coverage. Writes a CSV of every row when
/// given a path, so a regression can be diffed rather than argued about.
/// </summary>
static int AuditAnimations(string root, string[] args)
{
    string? csvPath = args.Length > 1 ? args[1] : null;

    Console.WriteLine("auditing every animation in every shipped package. this takes a few minutes.\n");
    var report = AnimationAudit.Run(root, message => Console.Error.WriteLine($"  {message}"));

    Console.WriteLine($"\npackages          {report.PackageCount}");
    Console.WriteLine($"animation packages {report.WrapperCount}");
    Console.WriteLine($"skeletons         {report.SkeletonCount}");
    Console.WriteLine($"animations        {report.Total}\n");

    foreach (var status in new[]
             {
                 AnimationStatus.Playable, AnimationStatus.Partial,
                 AnimationStatus.Unsupported, AnimationStatus.Failed,
             })
    {
        int count = report.Count(status);
        double share = report.Total == 0 ? 0 : 100.0 * count / report.Total;
        Console.WriteLine($"  {status,-12} {count,6}  {share,5:0.0}%");
    }

    Console.WriteLine($"\nexportable        {report.Decoded} ({(report.Total == 0 ? 0 : 100.0 * report.Decoded / report.Total):0.0}%)");
    Console.WriteLine($"tracks bound to no bone  {report.UnboundTracks}");
    Console.WriteLine($"animations with events   {report.WithEvents} ({report.TotalEvents} events)");

    // Decoding without throwing is not the same as decoding correctly. These two checks are what
    // separate the two: a block walk that does not consume its block has lost alignment, and a bone
    // that teleports between consecutive frames is a decode fault rather than a performance.
    Console.WriteLine($"\nblock walks that left the block unconsumed  {report.IncompleteBlocks}");
    foreach (float threshold in new[] { 10f, 25f, 50f, 100f })
        Console.WriteLine($"  animations with a bone jumping >= {threshold,3:0} cm in one frame  {report.Discontinuous(threshold)}");

    // A skeleton is rigid, so a bone sitting on its parent is provably a decode fault — unlike a
    // large frame step, which a snappy performance can produce honestly. This is the check that
    // would have caught the arms-inside-the-chest fire animations; see docs/HANDOFF.md §6.0c.
    Console.WriteLine($"\nanimations folding a bone into its parent    {report.WithCollapsedBones()}");
    foreach (int bones in new[] { 5, 10, 20 })
        Console.WriteLine($"  animations folding >= {bones,2} bones in one frame      {report.WithCollapsedBones(bones)}");

    var collapses = report.Rows
        .Where(r => r.WorstCollapsedBones > 0)
        .OrderByDescending(r => r.WorstCollapsedBones)
        .Take(15)
        .ToList();

    if (collapses.Count > 0)
    {
        Console.WriteLine("\nworst collapses:");
        foreach (var r in collapses)
        {
            Console.WriteLine($"  {r.WorstCollapsedBones,3} bones  {r.Wrapper}/{r.Name} " +
                              $"({r.TrackCount} tracks) frame {r.WorstCollapseFrame} e.g. {r.WorstCollapseBone}");
        }
    }

    var worst = report.Rows.OrderByDescending(r => r.WorstFrameStep).Take(15).ToList();
    Console.WriteLine("\nlargest single-frame bone jumps:");
    foreach (var r in worst)
    {
        Console.WriteLine($"  {r.WorstFrameStep,8:0.0} cm ({r.WorstFrameStepRatio,5:0.0}x mean)  " +
                          $"{r.Wrapper}/{r.Name} frame {r.WorstFrameStepFrame} bone {r.WorstFrameStepBone}");
    }

    if (report.PackageFailures.Count > 0)
    {
        Console.WriteLine($"\n{report.PackageFailures.Count} animation packages would not load:");
        foreach (var (package, wrapper, reason) in report.PackageFailures.Take(20))
            Console.WriteLine($"  {package}/{wrapper}: {reason}");
        if (report.PackageFailures.Count > 20)
            Console.WriteLine($"  ... and {report.PackageFailures.Count - 20} more");
    }

    // Group the problems by reason: one cause usually accounts for many rows, and the count is what
    // says whether it is worth chasing.
    var problems = report.Rows
        .Where(r => r.Status is not AnimationStatus.Playable)
        .GroupBy(r => r.Reason)
        .OrderByDescending(g => g.Count())
        .ToList();

    if (problems.Count > 0)
    {
        Console.WriteLine($"\nwhy the rest are not playable, by cause:");
        foreach (var group in problems.Take(25))
            Console.WriteLine($"  {group.Count(),6}  {group.Key}");
    }

    if (csvPath is not null)
    {
        using var writer = new StreamWriter(csvPath);
        writer.WriteLine("package,wrapper,owner,name,status,compression,skeleton,bones,frames,fps,tracks,boundTracks,events,blockSlack,blocksComplete,worstStep,worstStepRatio,worstStepBone,worstStepFrame,reason");
        foreach (var r in report.Rows)
        {
            writer.WriteLine($"{Csv(r.Package)},{Csv(r.Wrapper)},{Csv(r.Owner)},{Csv(r.Name)},{r.Status}," +
                             $"{Csv(r.Compression)},{Csv(r.SkeletonName)},{r.BoneCount},{r.FrameCount}," +
                             $"{r.FrameRate:0.00},{r.TrackCount},{r.BoundTrackCount},{r.EventCount}," +
                             $"{r.WorstBlockSlack},{r.BlocksLookComplete},{r.WorstFrameStep:0.00},{r.WorstFrameStepRatio:0.0}," +
                             $"{Csv(r.WorstFrameStepBone)},{r.WorstFrameStepFrame},{Csv(r.Reason)}");
        }
        Console.WriteLine($"\nwrote {csvPath}");
    }

    return 0;

    static string Csv(string value) =>
        value.Contains(',') || value.Contains('"')
            ? '"' + value.Replace("\"", "\"\"") + '"'
            : value;
}

/// <summary>
/// The health report — every diagnostic the tool can produce, with its evidence.
/// </summary>
/// <remarks>
/// The animation half is opt-in because it decodes all 16,031 animations and costs minutes; the
/// summary always states what was examined, so a short run cannot be mistaken for a clean game.
/// </remarks>
static int Diagnose(string root, string[] args)
{
    string? packageName = null, codeFilter = null, csvPath = null;
    bool animations = false;

    for (int i = 1; i < args.Length; i++)
    {
        string arg = args[i];
        if (arg == "--animations") animations = true;
        else if (arg == "--code" && i + 1 < args.Length) codeFilter = args[++i];
        else if (arg == "--out" && i + 1 < args.Length) csvPath = args[++i];
        else if (!arg.StartsWith("--", StringComparison.Ordinal)) packageName = arg;
    }

    // The same two sources the exporter uses. Without them every import-named shader and every
    // stripped texture would be reported as a fault the export pipeline does not actually have.
    var external = new PackageMaterialSource(root);
    var bulk = BulkTextureCatalog.Load(root);

    var report = DiagnosticReport.Empty;

    if (packageName is not null)
    {
        string file = GameLocator.EnumeratePackages(root)
                          .Concat(GameLocator.EnumerateScriptPackages(root))
                          .FirstOrDefault(p => string.Equals(
                              Path.GetFileNameWithoutExtension(p), packageName,
                              StringComparison.OrdinalIgnoreCase))
                      ?? throw new FileNotFoundException($"no shipped package named '{packageName}'");

        using var package = BioShockPackage.Open(file);
        report = AssetDiagnostics.ScanPackage(package, packageName, external, bulk);
    }
    else
    {
        Console.WriteLine("scanning every mesh, material and texture in the game. this takes a while.\n");
        report = AssetDiagnostics.Run(root, external, bulk, m => Console.Error.WriteLine($"  {m}"));
    }

    if (animations)
    {
        Console.WriteLine("\ndecoding every animation in the game. this takes a few minutes.\n");
        report = report.Merge(AssetDiagnostics.FromAnimationAudit(
            AnimationAudit.Run(root, m => Console.Error.WriteLine($"  {m}"))));
    }

    var rows = report.Diagnostics
        .Where(d => codeFilter is null || string.Equals(d.Code, codeFilter, StringComparison.OrdinalIgnoreCase))
        .OrderByDescending(d => d.Severity)
        .ThenBy(d => d.Code, StringComparer.Ordinal)
        .ThenBy(d => d.Package, StringComparer.OrdinalIgnoreCase)
        .ThenBy(d => d.Asset, StringComparer.OrdinalIgnoreCase)
        .ToList();

    Console.WriteLine();
    Console.WriteLine(report.Summarise());

    if (codeFilter is not null)
    {
        Console.WriteLine($"\n{rows.Count:N0} matching '{codeFilter}':\n");
        foreach (var diagnostic in rows.Take(200))
        {
            Console.WriteLine(diagnostic.ToReport());
            Console.WriteLine();
        }
        if (rows.Count > 200) Console.WriteLine($"... and {rows.Count - 200:N0} more");
    }
    else if (rows.Count > 0)
    {
        // One worked example per code, so the report shows what the evidence looks like rather than
        // only how many there are. --code lists them all.
        Console.WriteLine("\none example of each:\n");
        foreach (var group in rows.GroupBy(d => d.Code, StringComparer.Ordinal))
        {
            Console.WriteLine(group.First().ToReport());
            Console.WriteLine();
        }
    }

    if (csvPath is not null)
    {
        using var writer = new StreamWriter(csvPath);
        writer.WriteLine("code,severity,subsystem,package,group,asset,class,exportIndex,summary,evidence,reference");
        foreach (var d in rows)
        {
            writer.WriteLine($"{DiagnoseCsv(d.Code)},{d.Severity},{d.Subsystem},{DiagnoseCsv(d.Package)}," +
                             $"{DiagnoseCsv(d.Group)},{DiagnoseCsv(d.Asset)},{DiagnoseCsv(d.ClassName)}," +
                             $"{d.ExportIndex},{DiagnoseCsv(d.Summary)},{DiagnoseCsv(d.Evidence)}," +
                             $"{DiagnoseCsv(d.Reference)}");
        }
        Console.WriteLine($"wrote {csvPath}");
    }

    return 0;
}

static string DiagnoseCsv(string value) =>
    value.Contains(',') || value.Contains('"') || value.Contains('\n')
        ? '"' + value.Replace("\"", "\"\"").Replace("\r", " ").Replace("\n", " ") + '"'
        : value;

/// <summary>
/// Prints entries from a package's name table, by index range or by pattern.
/// </summary>
/// <remarks>
/// A research tool. Several of this game's binary blobs hold what look like name-table indices —
/// <c>EventResponse_SoundEffectsSubsystem.Specification</c> is the current example — and the only way
/// to test that reading is to resolve the index and see whether the answer is meaningful.
/// </remarks>
static int Names(string root, string[] args)
{
    if (args.Length < 2) { Console.Error.WriteLine("usage: names <package> [pattern | index [count]]"); return 1; }

    string file = GameLocator.EnumeratePackages(root)
                      .Concat(GameLocator.EnumerateScriptPackages(root))
                      .FirstOrDefault(p => string.Equals(
                          Path.GetFileNameWithoutExtension(p), args[1], StringComparison.OrdinalIgnoreCase))
                  ?? throw new FileNotFoundException($"no shipped package named '{args[1]}'");

    using var package = BioShockPackage.Open(file);
    Console.WriteLine($"{args[1]}: {package.Names.Count} names");

    if (args.Length < 3) return 0;

    if (int.TryParse(args[2], out int index))
    {
        int count = args.Length > 3 && int.TryParse(args[3], out int c) ? c : 1;
        for (int i = index; i < index + count && i < package.Names.Count; i++)
            if (i >= 0) Console.WriteLine($"  [{i,6}] {package.Names[i].Name}");
        return 0;
    }

    for (int i = 0; i < package.Names.Count; i++)
    {
        if (package.Names[i].Name.Contains(args[2], StringComparison.OrdinalIgnoreCase))
            Console.WriteLine($"  [{i,6}] {package.Names[i].Name}");
    }

    return 0;
}

static int Textures(string root, string[] args)
{
    if (args.Length < 2) { Console.Error.WriteLine("usage: textures <package> [pattern]"); return 1; }

    using var package = BioShockPackage.Open(ResolvePackage(root, args[1]));
    string? pattern = args.Length > 2 ? args[2] : null;

    int decoded = 0, failed = 0;
    foreach (var export in package.Exports.Where(e => package.GetClassName(e) == TextureReader.ClassName))
    {
        if (pattern is not null && !export.ObjectName.Contains(pattern, StringComparison.OrdinalIgnoreCase)) continue;

        var texture = TextureReader.Read(package, export);
        if (texture is null) { failed++; continue; }
        decoded++;
        Console.WriteLine($"  {texture.Name,-40} {texture.Format,-6} {texture.Width,5}x{texture.Height,-5} " +
                          $"mips={texture.Mips.Count,-3} {export.SerialSize,10}");
    }

    Console.WriteLine($"\n{decoded} decoded, {failed} not understood.");
    return 0;
}

static int ExportTextures(string root, string[] args)
{
    if (args.Length < 3) { Console.Error.WriteLine("usage: export-textures <package> <out-dir> [pattern]"); return 1; }

    using var package = BioShockPackage.Open(ResolvePackage(root, args[1]));
    string outputDirectory = args[2];
    string? pattern = args.Length > 3 ? args[3] : null;
    Directory.CreateDirectory(outputDirectory);

    int written = 0, failed = 0;
    foreach (var export in package.Exports.Where(e => package.GetClassName(e) == TextureReader.ClassName))
    {
        if (pattern is not null && !export.ObjectName.Contains(pattern, StringComparison.OrdinalIgnoreCase)) continue;

        BioShockTexture? texture;
        try { texture = TextureReader.Read(package, export); }
        catch (Exception ex) { Console.Error.WriteLine($"  {export.ObjectName}: {ex.Message}"); failed++; continue; }
        if (texture is null) { failed++; continue; }

        // Object names repeat within a package, so the group disambiguates the file name.
        string group = AssetContextResolver.TopLevelGroup(package, export);
        string stem = group == texture.Name ? texture.Name : $"{group}.{texture.Name}";
        stem = string.Concat(stem.Split(Path.GetInvalidFileNameChars()));

        var top = texture.Mips[0];
        byte[] rgba = BlockCompression.Decode(texture.Format, top.Data, top.Width, top.Height);
        PngWriter.Write(Path.Combine(outputDirectory, stem + ".png"), rgba, top.Width, top.Height);

        // DDS keeps the shipped compression and the whole mip chain.
        if (texture.Format != BioShockTextureFormat.Rgba8)
            DdsWriter.Write(Path.Combine(outputDirectory, stem + ".dds"), texture);

        written++;
    }

    Console.WriteLine($"wrote {written} textures to {outputDirectory}; {failed} not understood.");
    return 0;
}

static int Characters(string root, string[] args)
{
    if (args.Length < 2) { Console.Error.WriteLine("usage: characters <package>"); return 1; }

    using var package = BioShockPackage.Open(ResolvePackage(root, args[1]));
    var entries = CharacterCatalog.Find(package);

    Console.WriteLine($"{"group",-28} {"animation package",-30} {"anims",6} {"textures",9} {"mesh bytes",11}  meshes");
    foreach (var entry in entries)
    {
        Console.WriteLine($"{entry.Group,-28} {entry.AnimationPackageObject,-30} {entry.AnimationCount,6} " +
                          $"{entry.TextureCount,9} {entry.LargestMeshSize,11}  {string.Join(", ", entry.Meshes.Take(3))}");
    }

    Console.WriteLine($"\n{entries.Count} animated assets.");
    return 0;
}

static int Context(string root, string[] args)
{
    if (args.Length < 3) { Console.Error.WriteLine("usage: context <package> <group>"); return 1; }

    using var package = BioShockPackage.Open(ResolvePackage(root, args[1]));
    var context = AssetContextResolver.Resolve(package, args[2]);

    if (context.Members.Count == 0)
    {
        Console.Error.WriteLine($"No asset group named '{args[2]}'. Try: context {args[1]} --list");
        return 1;
    }

    Console.WriteLine($"{context.Name} ({context.PackageName}): {context.Members.Count} objects");
    foreach (var group in context.Members.GroupBy(e => package.GetClassName(e)).OrderByDescending(g => g.Count()))
    {
        Console.WriteLine($"\n{group.Key} x{group.Count()}");
        foreach (var member in group.OrderByDescending(e => e.SerialSize).Take(8))
            Console.WriteLine($"      {member.ObjectName,-44} {member.SerialSize,10}");
        if (group.Count() > 8) Console.WriteLine($"      ... {group.Count() - 8} more");
    }
    return 0;
}

static int AnimationInspect(string root, string[] args)
{
    if (args.Length < 5 || !string.Equals(args[1], "inspect", StringComparison.OrdinalIgnoreCase))
    {
        Console.Error.WriteLine("usage: animation inspect <package> <object> <animation>");
        return 1;
    }

    using var package = BioShockPackage.Open(ResolvePackage(root, args[2]));
    var export = package.Exports
        .Where(e => string.Equals(e.ObjectName, args[3], StringComparison.OrdinalIgnoreCase)
                    && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
        .MaxBy(e => e.SerialSize)
        ?? throw new FileNotFoundException($"No AnimationPackageWrapper named '{args[3]}'.");

    var animationPackage = AnimationPackage.Load(package, export);
    var animation = animationPackage.Find(args[4])
        ?? throw new FileNotFoundException($"No animation named '{args[4]}'.");

    var decoded = animationPackage.Decode(animation);
    var skeleton = animationPackage.Skeleton;

    Console.WriteLine($"{animation.Name}  (owner {animation.Owner})");
    Console.WriteLine($"  duration {animation.Duration:0.###}s  frames {animation.FrameCount}  " +
                      $"{animation.FrameRate:0.##} fps  compression {animation.Compression}");
    Console.WriteLine($"  skeleton '{skeleton.Name}' with {skeleton.BoneCount} bones, " +
                      $"{animation.TransformTrackCount} transform tracks");
    Console.WriteLine($"  section {animation.SectionTag}  offset {animation.Offset}");

    int last = decoded.FrameCount - 1;
    Console.WriteLine($"\n{"bone",-24} {"frame",5}  {"local translation",-30} local rotation");
    foreach (var track in decoded.Tracks.Take(6))
    {
        string bone = track.TargetBoneIndex >= 0 ? skeleton.Bones[track.TargetBoneIndex].Name : "<unbound>";
        foreach (int frame in new[] { 0, last / 2, last }.Distinct())
        {
            var t = track.Translations[frame];
            var r = track.Rotations[frame];
            Console.WriteLine($"  {bone,-24} {frame,5}  ({t.X,8:0.##},{t.Y,8:0.##},{t.Z,8:0.##})      " +
                              $"({r.X,6:0.###},{r.Y,6:0.###},{r.Z,6:0.###},{r.W,6:0.###})");
        }
    }
    if (decoded.Tracks.Count > 6) Console.WriteLine($"  ... {decoded.Tracks.Count - 6} more tracks");

    var metadataExport = package.Exports.FirstOrDefault(e =>
        string.Equals(e.ObjectName, AnimationMetadataReader.ObjectPrefix + animation.Name, StringComparison.OrdinalIgnoreCase));
    var events = metadataExport is null
        ? []
        : AnimationMetadataReader.ReadEvents(package, metadataExport, animation.Duration);

    Console.WriteLine($"\nevents: {events.Count}");
    foreach (var animationEvent in events)
        Console.WriteLine($"      {animationEvent.Time,7:0.###}s  {animationEvent.EventName,-28} {animationEvent.NotifyClass}");

    string group = AssetContextResolver.TopLevelGroup(package, export);
    var context = AssetContextResolver.Resolve(package, group);
    Console.WriteLine($"\nowner group: {group}");
    Console.WriteLine($"      meshes:   {string.Join(", ", context.OfClass(package, AssetClasses.SkeletalMesh).Select(e => e.ObjectName))}");
    Console.WriteLine($"      textures: {string.Join(", ", context.OfClass(package, "Texture").Select(e => e.ObjectName).Take(6))}");
    Console.WriteLine($"      attachments: {string.Join(", ", context.OfClass(package, AssetClasses.StaticMesh).Select(e => e.ObjectName))}");
    return 0;
}

/// <summary>
/// Reports the material each SkeletalMesh resolves to, and the textures that material binds. This
/// is the coverage check for the mesh-to-material link, so it reports misses as well as hits.
/// </summary>
static int Materials(string root, string[] args)
{
    if (args.Length < 2) { Console.Error.WriteLine("usage: materials <package> [pattern]"); return 1; }

    using var package = BioShockPackage.Open(ResolvePackage(root, args[1]));
    string? pattern = args.Length > 2 ? args[2] : null;

    var meshes = package.Exports
        .Where(e => package.GetClassName(e) == AssetClasses.SkeletalMesh && e.SerialSize > 0)
        .Where(e => pattern is null || e.ObjectName.Contains(pattern, StringComparison.OrdinalIgnoreCase))
        .OrderByDescending(e => e.SerialSize)
        .ToList();

    int resolved = 0, textured = 0;
    foreach (var mesh in meshes)
    {
        var material = MaterialReader.ReadForMesh(package, mesh);
        if (material is null)
        {
            Console.WriteLine($"  --    {mesh.ObjectName,-36} no material reference");
            continue;
        }

        resolved++;
        if (material.Textures.Count > 0) textured++;
        Console.WriteLine($"  ok    {mesh.ObjectName,-36} {material.ClassName} {material.Name}" +
                          (material.Truncated ? "  (partial)" : string.Empty));
        foreach (var texture in material.Textures)
            Console.WriteLine($"          {texture.Slot,-18} {texture.TextureName}{(texture.IsExternal ? "  (external)" : string.Empty)}");
        if (material.UnhandledProperties.Count > 0)
            Console.WriteLine($"          uninterpreted: {string.Join(", ", material.UnhandledProperties.Distinct())}");
    }

    Console.WriteLine();
    Console.WriteLine($"{resolved}/{meshes.Count} SkeletalMeshes resolve to a material; {textured} bind at least one texture.");

    var materials = package.Exports.Where(e => MaterialReader.IsMaterialClass(package.GetClassName(e))).ToList();
    var decoded = materials.Select(e => MaterialReader.Read(package, e)).Where(m => m is not null).ToList();
    int partial = decoded.Count(m => m!.Truncated);
    Console.WriteLine($"{decoded.Count}/{materials.Count} material objects in the package decode, " +
                      $"{partial} of them only partly.");
    return 0;
}

static int Meshes(string root, string[] args)
{
    if (args.Length < 2) { Console.Error.WriteLine("usage: meshes <package>"); return 1; }

    using var package = BioShockPackage.Open(ResolvePackage(root, args[1]));
    var meshes = package.Exports.Where(e => package.GetClassName(e) == AssetClasses.SkeletalMesh).ToList();

    int decoded = 0, sockets = 0;
    long vertices = 0, triangles = 0;

    foreach (var export in meshes.OrderByDescending(e => e.SerialSize))
    {
        byte[] payload = export.SerialSize > 0 ? package.ReadExportData(export) : [];
        MeshGeometry? geometry = null;
        int socketCount = 0;

        if (payload.Length >= 128)
        {
            try { geometry = SkeletalMeshReader.ReadGeometry(payload); } catch { /* reported below */ }
            try { socketCount = SkeletalMeshReader.ReadSockets(payload, package.Names).Count; } catch { /* ditto */ }
        }

        if (geometry is not null)
        {
            decoded++;
            vertices += geometry.Vertices.Count;
            triangles += geometry.TriangleCount;
        }
        if (socketCount > 0) sockets++;

        Console.WriteLine(geometry is null
            ? $"  --    {export.ObjectName,-36} {export.SerialSize,10}  no geometry"
            : $"  ok    {export.ObjectName,-36} {export.SerialSize,10}  {geometry.Vertices.Count,7} verts " +
              $"{geometry.TriangleCount,7} tris  bones={geometry.BoneMap.Count,-4} sockets={socketCount}");
    }

    Console.WriteLine();
    Console.WriteLine($"{decoded}/{meshes.Count} SkeletalMeshes decoded to geometry " +
                      $"({vertices} vertices, {triangles} triangles); {sockets} declare sockets.");
    return 0;
}

static int ExportBlender(string root, string[] args)
{
    if (args.Length < 4)
    {
        Console.Error.WriteLine("usage: export-blender <package> <object> <output-dir> [owner]");
        return 1;
    }

    string outputDirectory = args[3];
    string? owner = args.Length > 4 ? args[4] : null;
    Directory.CreateDirectory(outputDirectory);

    var animationPackage = LoadAnimationPackage(root, args[1], args[2]);
    var (sockets, geometry, material) = ResolveMesh(root, args[1], args[2], outputDirectory);
    if (sockets.Count > 0) Console.WriteLine($"resolved {sockets.Count} sockets from the companion SkeletalMesh");
    if (material is not null) Console.WriteLine($"resolved material {material.ClassName} {material.Name} " +
                                                $"with {material.Textures.Count} texture bindings");
    if (geometry is not null)
        Console.WriteLine($"resolved mesh: {geometry.Vertices.Count} vertices, {geometry.TriangleCount} triangles");

    var events = ResolveEvents(root, args[1], animationPackage);
    if (events.Count > 0)
        Console.WriteLine($"resolved events for {events.Count} animations");

    var scene = AnimationSceneExporter.Build(animationPackage, owner, sockets, geometry, events, material);

    string suffix = owner is null ? string.Empty : "_" + owner;
    string scenePath = Path.Combine(outputDirectory, $"{animationPackage.ObjectName}{suffix}.json");
    AnimationSceneExporter.WriteJson(scene, scenePath);

    Console.WriteLine($"wrote {scenePath}");
    Console.WriteLine($"  {scene.Bones.Count} bones, {scene.Animations.Count} animations, {scene.Failures.Count} undecoded");

    string blendPath = Path.Combine(outputDirectory, $"{animationPackage.ObjectName}{suffix}.blend");
    string script = Path.Combine(AppContext.BaseDirectory, "tools", "blender", "import_bioshock_scene.py");
    if (!File.Exists(script)) script = Path.Combine("tools", "blender", "import_bioshock_scene.py");

    Console.WriteLine("\nTo build the .blend, run:");
    Console.WriteLine($"  blender --background --python \"{Path.GetFullPath(script)}\" -- \"{scenePath}\" \"{blendPath}\"");
    return 0;
}

/// <summary>
/// Writes the same scene as <c>export-blender</c> in FBX, for Unreal or any DCC that reads FBX.
/// </summary>
static int ExportFbx(string root, string[] args)
{
    if (args.Length < 4)
    {
        Console.Error.WriteLine("usage: export-fbx <package> <object> <output-dir> [owner]");
        return 1;
    }

    string outputDirectory = args[3];
    string? owner = args.Length > 4 ? args[4] : null;

    Directory.CreateDirectory(outputDirectory);
    var animationPackage = LoadAnimationPackage(root, args[1], args[2]);
    var (sockets, geometry, material) = ResolveMesh(root, args[1], args[2], outputDirectory);
    var events = ResolveEvents(root, args[1], animationPackage);
    var scene = AnimationSceneExporter.Build(animationPackage, owner, sockets, geometry, events, material);

    return WriteFbx(scene, outputDirectory);
}

static int WriteFbx(AnimationScene scene, string outputDirectory, string? preview = null)
{
    var manifest = FbxExporter.Write(scene, outputDirectory, previewAnimation: preview);

    foreach (var rig in manifest.Rigs)
    {
        string attached = rig.AttachedTo is null
            ? string.Empty
            : $"  attached to {rig.AttachedTo.Host}'s '{rig.AttachedTo.Socket}' socket on {rig.AttachedTo.Bone}";
        Console.WriteLine($"{rig.Name}: {rig.BoneCount} bones, {rig.VertexCount} vertices, " +
                          $"{rig.Sockets.Count} sockets, {rig.Animations.Count} animations{attached}");
        Console.WriteLine($"  {Path.Combine(outputDirectory, rig.Mesh)}");
        if (rig.Preview is not null)
            Console.WriteLine($"  {Path.Combine(outputDirectory, rig.Preview)}  (mesh + animation, for viewing)");
        int notified = rig.Animations.Count(a => a.Notifies.Count > 0);
        if (notified > 0) Console.WriteLine($"  {notified} animations carry notifies (manifest only; FBX has no place for them)");
        if (rig.Undecoded > 0) Console.WriteLine($"  {rig.Undecoded} animations did not decode and were not written");
    }

    Console.WriteLine($"\nmanifest: {Path.Combine(outputDirectory, FbxExporter.ManifestFileName)}");
    Console.WriteLine("To import into Unreal, run this inside the editor's Python console:");
    Console.WriteLine($"  import_bioshock.main(r\"{Path.GetFullPath(outputDirectory)}\", \"/Game/BioShock\")");
    return 0;
}

/// <summary>
/// Builds a complete first-person setup: the player hands, the weapon that attaches to them, and
/// both animation sets.
/// <para>
/// The relationship comes from the data. The hands mesh declares a socket named after the weapon
/// (<c>Pistol</c>) bound to <c>R_Grip</c>; the weapon's own skeleton, in ShockGame.U, is rooted at a
/// bone of the same name; and the weapon's animations are frame-identical to the hands' matching
/// animations.
/// </para>
/// </summary>
static int ExportFirstPerson(string root, string[] args)
{
    var positional = args.Skip(1).Where(a => !a.StartsWith("--", StringComparison.Ordinal)).ToList();
    bool asFbx = args.Contains("--fbx", StringComparer.OrdinalIgnoreCase);
    string? preview = args.FirstOrDefault(a => a.StartsWith("--preview=", StringComparison.OrdinalIgnoreCase))
        ?["--preview=".Length..];

    if (positional.Count < 2)
    {
        Console.Error.WriteLine("usage: export-firstperson <weapon> <out-dir> [--fbx]");
        return 1;
    }

    string weapon = positional[0];
    string outputDirectory = positional[1];
    Directory.CreateDirectory(outputDirectory);

    string weaponPackagePath = GameLocator.WeaponPackage(root)
        ?? throw new FileNotFoundException("ShockGame.U not found; it holds the first-person weapon viewmodels.");

    var hands = LoadAnimationPackage(root, "0-Lighthouse", "UAPW_NEWPlayerHands");
    var (sockets, geometry, material) = ResolveMesh(root, "0-Lighthouse", "UAPW_NEWPlayerHands", outputDirectory);
    var handEvents = ResolveEvents(root, "0-Lighthouse", hands);
    var scene = AnimationSceneExporter.Build(hands, weapon, sockets, geometry, handEvents, material);

    var socket = sockets.FirstOrDefault(s => string.Equals(s.Name, weapon, StringComparison.OrdinalIgnoreCase));
    if (socket is null)
    {
        Console.Error.WriteLine($"The hands declare no socket named '{weapon}'. Available: " +
                                string.Join(", ", sockets.Select(s => s.Name)));
        return 1;
    }

    Console.WriteLine($"hands:  {scene.Bones.Count} bones, {scene.Animations.Count} '{weapon}' animations, " +
                      $"{scene.Sockets.Count} sockets");
    Console.WriteLine($"socket: '{socket.Name}' attaches to bone '{socket.BoneName}'");

    using var weaponPackage = BioShockPackage.Open(weaponPackagePath);
    string group = "WP_" + weapon;

    var weaponWrapper = weaponPackage.Exports
        .Where(e => IsInGroup(weaponPackage, e, group)
                    && weaponPackage.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
        .MaxBy(e => e.SerialSize);

    var weaponMeshExport = weaponPackage.Exports
        .Where(e => IsInGroup(weaponPackage, e, group)
                    && weaponPackage.GetClassName(e) == AssetClasses.SkeletalMesh)
        .MaxBy(e => e.SerialSize);

    if (weaponWrapper is null || weaponMeshExport is null)
    {
        Console.Error.WriteLine($"No animated weapon found in group '{group}' of ShockGame.U.");
        return 1;
    }

    var weaponAnimations = AnimationPackage.Load(weaponPackage, weaponWrapper);
    byte[] weaponPayload = weaponPackage.ReadExportData(weaponMeshExport);
    var weaponGeometry = SkeletalMeshReader.ReadGeometry(weaponPayload);
    var weaponSockets = SkeletalMeshReader.ReadSockets(weaponPayload, weaponPackage.Names);
    var weaponMaterial = MaterialExporter.Resolve(weaponPackage, weaponMeshExport, outputDirectory);
    var weaponScene = AnimationSceneExporter.Build(
        weaponAnimations, null, weaponSockets, weaponGeometry, null, weaponMaterial);

    if (weaponMaterial is not null)
        Console.WriteLine($"weapon material: {weaponMaterial.Name} with {weaponMaterial.Textures.Count} texture bindings");
    Console.WriteLine($"weapon: {weaponMeshExport.ObjectName}, {weaponScene.Bones.Count} bones " +
                      $"(root '{weaponAnimations.Skeleton.Bones[0].Name}'), " +
                      $"{weaponScene.Animations.Count} animations, {weaponGeometry?.Vertices.Count ?? 0} vertices");

    scene = scene with
    {
        Attachments =
        [
            new SceneAttachment
            {
                SocketName = socket.Name,
                SocketBone = socket.BoneName,
                Scene = weaponScene,
            },
        ],
    };

    if (asFbx)
    {
        Console.WriteLine();
        return WriteFbx(scene, outputDirectory, preview);
    }

    string scenePath = Path.Combine(outputDirectory, $"{weapon}_FirstPerson.json");
    AnimationSceneExporter.WriteJson(scene, scenePath);
    Console.WriteLine($"wrote {scenePath}");

    string blendPath = Path.Combine(outputDirectory, $"{weapon}_FirstPerson.blend");
    string script = Path.GetFullPath(Path.Combine("tools", "blender", "import_bioshock_scene.py"));
    Console.WriteLine("To build the .blend, run:");
    Console.WriteLine($"  blender --background --python \"{script}\" -- \"{scenePath}\" \"{blendPath}\"");
    return 0;
}

static bool IsInGroup(BioShockPackage package, ObjectExport export, string group) =>
    string.Equals(AssetContextResolver.TopLevelGroup(package, export), group, StringComparison.OrdinalIgnoreCase);

static string ResolvePackage(string root, string name)
{
    if (File.Exists(name)) return name;
    string candidate = Path.Combine(GameLocator.MapsDirectory(root), Path.ChangeExtension(name, ".bsm"));
    if (File.Exists(candidate)) return candidate;
    throw new FileNotFoundException($"Package '{name}' not found.");
}
