using System.Text.Json;

namespace BioShockStudio.Core.Services;

/// <summary>What the application remembers between runs.</summary>
public sealed record AppSettings
{
    public string? GamePath { get; init; }
    public string? OutputDirectory { get; init; }

    public bool ExportSceneJson { get; init; } = true;
    public bool ExportFbx { get; init; } = true;
    public bool ExportPng { get; init; } = true;
    public bool ExportDds { get; init; }
    public bool PreservePackageStructure { get; init; } = true;
    public bool SkipExisting { get; init; }

    public bool ResearchMode { get; init; }
    public bool ShowTextures { get; init; } = true;
    public bool ShowShading { get; init; } = true;
    public bool ShowSkeleton { get; init; }
    public bool ShowSockets { get; init; }

    public double WindowWidth { get; init; }
    public double WindowHeight { get; init; }
}

/// <summary>
/// Loads and saves the application's settings.
/// </summary>
/// <remarks>
/// <para>
/// Re-picking a game folder and re-typing an output path on every launch is the kind of friction
/// that makes a tool feel unfinished. The file lives beside the user's other application data, not
/// in the repository or next to the executable, so a rebuilt or moved binary keeps them.
/// </para>
/// <para>
/// Nothing here is allowed to prevent the application starting: unreadable or corrupt settings fall
/// back to defaults rather than throwing, because a bad settings file should never be the reason a
/// tool will not open.
/// </para>
/// </remarks>
public sealed class SettingsService
{
    private static readonly JsonSerializerOptions Options = new() { WriteIndented = true };

    public string Path { get; }

    public SettingsService(string? path = null)
    {
        Path = path ?? System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "BioShockHavok",
            "settings.json");
    }

    public AppSettings Load()
    {
        try
        {
            if (!File.Exists(Path)) return new AppSettings();
            return JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(Path)) ?? new AppSettings();
        }
        catch (Exception ex) when (ex is IOException or JsonException or UnauthorizedAccessException)
        {
            return new AppSettings();
        }
    }

    /// <summary>Saves, returning false when it could not be written. Never throws.</summary>
    public bool Save(AppSettings settings)
    {
        try
        {
            string? directory = System.IO.Path.GetDirectoryName(Path);
            if (directory is not null) Directory.CreateDirectory(directory);

            File.WriteAllText(Path, JsonSerializer.Serialize(settings, Options));
            return true;
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            return false;
        }
    }
}
