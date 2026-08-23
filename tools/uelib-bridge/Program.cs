using System;
using System.IO;
using System.Linq;
using UELib;
using UELib.Core;

// Usage:
//   dotnet run --project tools/uelib-bridge -- <out-dir> <package-name.U> [scripts-dir]
//   dotnet run --project tools/uelib-bridge -- --schema <out-file.json> <package-name.U> [scripts-dir]
//
// The default mode decompiles to one .uc per class, for reading. --schema emits the class
// hierarchy, variable declarations and defaultproperties as JSON, for the UE5 port's data layer --
// see docs/UE5_FULL_PORT_PLAN.md for why those two halves are treated differently.
if (args.Length < 2)
{
    Console.Error.WriteLine("usage: <out-dir> <package-name.U> [scripts-dir]");
    Console.Error.WriteLine("       --schema <out-file.json> <package-name.U> [scripts-dir]");
    return 1;
}

bool schemaMode = args[0] == "--schema";
if (schemaMode)
{
    if (args.Length < 3)
    {
        Console.Error.WriteLine("usage: --schema <out-file.json> <package-name.U> [scripts-dir]");
        return 1;
    }

    string schemaScripts = args.Length > 3 ? args[3] : FindScriptsDirectory();
    if (schemaScripts is null)
    {
        Console.Error.WriteLine("Could not auto-detect a BioShock Remastered install. Pass scripts-dir explicitly.");
        return 1;
    }

    return BioShockStudio.UELibBridge.SchemaExport.Run(args[1], args[2], schemaScripts);
}

string outDir = args[0];
string packageName = args[1];
string scriptsDir = args.Length > 2 ? args[2] : FindScriptsDirectory();

if (scriptsDir is null)
{
    Console.Error.WriteLine("Could not auto-detect a BioShock Remastered install. Pass scripts-dir explicitly.");
    return 1;
}

Directory.CreateDirectory(outDir);
string packagePath = Path.Combine(scriptsDir, packageName);
Console.WriteLine($"Loading {packagePath}...");

var package = UnrealLoader.LoadPackage(packagePath, FileAccess.Read);
package.InitializePackage();

int classCount = 0, ok = 0, failed = 0;
foreach (var obj in package.Objects)
{
    if ((int)obj <= 0) continue; // imports
    if (obj is not UClass cls) continue;

    classCount++;
    try
    {
        string decompiled = cls.Decompile();
        File.WriteAllText(Path.Combine(outDir, cls.Name + ".uc"), decompiled);
        ok++;
    }
    catch (Exception ex)
    {
        failed++;
        Console.WriteLine($"[FAIL] {cls.Name}: {ex.Message}");
    }
}

Console.WriteLine($"{packageName}: {classCount} classes, {ok} decompiled, {failed} failed.");
return 0;

static string? FindScriptsDirectory()
{
    string[] roots =
    [
        @"C:\Program Files (x86)\Steam\steamapps\common\BioShock Remastered",
        @"D:\SteamLibrary\steamapps\common\BioShock Remastered",
        @"E:\SteamLibrary\steamapps\common\BioShock Remastered",
        @"F:\SteamLibrary\steamapps\common\BioShock Remastered",
        @"G:\SteamLibrary\steamapps\common\BioShock Remastered",
    ];

    foreach (string root in roots)
    {
        string candidate = Path.Combine(root, "Build", "Final", "BakedScripts", "pc");
        if (Directory.Exists(candidate)) return candidate;
    }

    return null;
}
