using System.Text.RegularExpressions;

namespace BioShockStudio.Core.Game;

/// <summary>Locates a BioShock 1 Remastered installation.</summary>
public static partial class GameLocator
{
    private const string SteamAppFolder = "BioShock Remastered";

    /// <summary>Environment variable that overrides auto-detection.</summary>
    public const string PathOverrideVariable = "BIOSHOCK_REMASTERED_PATH";

    /// <summary>Returns the install root, or null if the game cannot be found.</summary>
    public static string? Find()
    {
        string? overridePath = Environment.GetEnvironmentVariable(PathOverrideVariable);
        if (!string.IsNullOrWhiteSpace(overridePath) && IsGameRoot(overridePath))
            return overridePath;

        foreach (string library in EnumerateSteamLibraries())
        {
            string candidate = Path.Combine(library, "steamapps", "common", SteamAppFolder);
            if (IsGameRoot(candidate)) return candidate;
        }

        return null;
    }

    public static bool IsGameRoot(string path) =>
        Directory.Exists(Path.Combine(path, "ContentBaked", "pc", "Maps"));

    /// <summary>The directory holding the shipped <c>.bsm</c> packages.</summary>
    public static string MapsDirectory(string gameRoot) =>
        Path.Combine(gameRoot, "ContentBaked", "pc", "Maps");

    /// <summary>The directory holding the bulk content chunks.</summary>
    public static string BulkContentDirectory(string gameRoot) =>
        Path.Combine(gameRoot, "ContentBaked", "pc", "BulkContent");

    /// <summary>
    /// Shipped packages excluding the per-language duplicates, which are localisation-only variants
    /// of the same maps.
    /// </summary>
    public static IEnumerable<string> EnumeratePackages(string gameRoot)
    {
        string maps = MapsDirectory(gameRoot);
        if (!Directory.Exists(maps)) yield break;

        foreach (string file in Directory.EnumerateFiles(maps, "*.bsm").Order())
        {
            if (!LocalizedSuffix().IsMatch(Path.GetFileNameWithoutExtension(file)))
                yield return file;
        }
    }

    private static IEnumerable<string> EnumerateSteamLibraries()
    {
        var roots = new List<string>();
        foreach (string steam in new[]
        {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Steam"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "Steam"),
        })
        {
            if (!Directory.Exists(steam)) continue;
            roots.Add(steam);

            string vdf = Path.Combine(steam, "steamapps", "libraryfolders.vdf");
            if (!File.Exists(vdf)) continue;

            foreach (Match match in LibraryPath().Matches(File.ReadAllText(vdf)))
                roots.Add(match.Groups[1].Value.Replace("\\\\", "\\"));
        }
        return roots.Distinct();
    }

    [GeneratedRegex(@"_(chn|deu|esp|fra|ita|jpn|int)$", RegexOptions.IgnoreCase)]
    private static partial Regex LocalizedSuffix();

    [GeneratedRegex("\"path\"\\s*\"([^\"]+)\"")]
    private static partial Regex LibraryPath();
}
