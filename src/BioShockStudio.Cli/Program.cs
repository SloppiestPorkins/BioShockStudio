using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Havok.Detection;
using BioShockStudio.Core.Havok.Packfile;
using BioShockStudio.Core.Packages;

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
        "skeleton" => Skeleton(root, args),
        "animations" => Animations(root, args),
        "export-blender" => ExportBlender(root, args),
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
          export-blender <package> <object> <out-dir> [owner]
                                        Write scene JSON for the Blender importer.

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
    var scene = AnimationSceneExporter.Build(animationPackage, owner);

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

static string ResolvePackage(string root, string name)
{
    if (File.Exists(name)) return name;
    string candidate = Path.Combine(GameLocator.MapsDirectory(root), Path.ChangeExtension(name, ".bsm"));
    if (File.Exists(candidate)) return candidate;
    throw new FileNotFoundException($"Package '{name}' not found.");
}
