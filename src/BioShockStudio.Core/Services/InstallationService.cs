using BioShockStudio.Core.Game;

namespace BioShockStudio.Core.Services;

/// <summary>One thing checked about a candidate install directory.</summary>
/// <param name="Name">What was checked, in the user's terms.</param>
/// <param name="Passed">Whether it was found.</param>
/// <param name="Detail">What was found, or what the user should do about it.</param>
/// <param name="Required">A failed required check means the install cannot be used at all.</param>
public sealed record InstallationCheck(string Name, bool Passed, string Detail, bool Required = true);

/// <summary>The result of validating a directory as a BioShock Remastered install.</summary>
public sealed record InstallationReport
{
    public required string Path { get; init; }
    public required IReadOnlyList<InstallationCheck> Checks { get; init; }

    /// <summary>Map packages found, without their extension.</summary>
    public required IReadOnlyList<string> Packages { get; init; }

    /// <summary>True when every required check passed.</summary>
    public bool IsUsable => Checks.All(c => c.Passed || !c.Required);

    /// <summary>The first thing that is wrong, phrased for the user, or null when nothing is.</summary>
    public string? Problem => Checks.FirstOrDefault(c => !c.Passed && c.Required)?.Detail;
}

/// <summary>
/// Finds and validates a BioShock Remastered installation.
/// </summary>
/// <remarks>
/// Validation reports every check rather than throwing on the first failure, because the useful
/// answer to "this folder does not work" is which part of it is missing. A directory that is missing
/// only the script package is still usable for everything except the first-person weapon viewmodels,
/// so that check is not required.
/// </remarks>
public sealed class InstallationService
{
    /// <summary>Auto-detects an install, or returns null. Never throws.</summary>
    public string? Detect()
    {
        try { return GameLocator.Find(); }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            return null;
        }
    }

    public InstallationReport Validate(string? path)
    {
        var checks = new List<InstallationCheck>();
        var packages = new List<string>();

        if (string.IsNullOrWhiteSpace(path))
        {
            checks.Add(new InstallationCheck("Game folder", false, "No folder chosen yet."));
            return new InstallationReport { Path = path ?? string.Empty, Checks = checks, Packages = packages };
        }

        bool exists = Directory.Exists(path);
        checks.Add(new InstallationCheck(
            "Game folder",
            exists,
            exists ? path : $"'{path}' does not exist."));

        if (!exists)
            return new InstallationReport { Path = path, Checks = checks, Packages = packages };

        string maps = GameLocator.MapsDirectory(path);
        bool isRoot = GameLocator.IsGameRoot(path);
        checks.Add(new InstallationCheck(
            "Game data",
            isRoot,
            isRoot
                ? "ContentBaked\\pc\\Maps found."
                : "This folder has no ContentBaked\\pc\\Maps. Choose the folder containing the game, "
                  + "usually ...\\steamapps\\common\\BioShock Remastered."));

        if (isRoot)
        {
            try
            {
                packages = GameLocator.EnumeratePackages(path)
                    .Select(System.IO.Path.GetFileNameWithoutExtension)
                    .Where(n => n is not null)
                    .Select(n => n!)
                    .ToList();
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
            {
                checks.Add(new InstallationCheck("Packages", false, $"Could not read {maps}: {ex.Message}"));
            }
        }

        if (isRoot && checks.All(c => c.Name != "Packages"))
        {
            checks.Add(new InstallationCheck(
                "Packages",
                packages.Count > 0,
                packages.Count > 0
                    ? $"{packages.Count} packages found."
                    : "No .bsm packages in ContentBaked\\pc\\Maps."));
        }

        // Not required: only the first-person weapon viewmodels live here, so everything else still
        // works without it.
        string? weapons = isRoot ? GameLocator.WeaponPackage(path) : null;
        checks.Add(new InstallationCheck(
            "Weapon viewmodels",
            weapons is not null,
            weapons is not null
                ? "ShockGame.U found."
                : "ShockGame.U not found. First-person weapon models will be unavailable; everything else works.",
            Required: false));

        return new InstallationReport { Path = path, Checks = checks, Packages = packages };
    }
}
