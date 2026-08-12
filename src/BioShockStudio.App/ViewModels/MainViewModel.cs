using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace BioShockStudio.App.ViewModels;

/// <summary>One row in the asset browser.</summary>
public sealed class AssetRow
{
    public required string Category { get; init; }
    public required string Name { get; init; }
    public required string Detail { get; init; }
    public required string Package { get; init; }

    /// <summary>Asset group this belongs to, used when extracting.</summary>
    public required string Group { get; init; }

    public required string ObjectName { get; init; }
}

public partial class MainViewModel : ViewModelBase
{
    private CancellationTokenSource? _cancellation;
    private List<AssetRow> _allAssets = [];

    [ObservableProperty] private string _gamePath = "";
    [ObservableProperty] private string _status = "Locate your BioShock Remastered installation to begin.";
    [ObservableProperty] private string _outputDirectory =
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "BioShockExtract");
    [ObservableProperty] private string _search = "";
    [ObservableProperty] private string _selectedPackage = "";
    [ObservableProperty] private string _selectedCategory = "All";
    [ObservableProperty] private AssetRow? _selectedAsset;
    [ObservableProperty] private double _progress;
    [ObservableProperty] private string _progressText = "";
    [ObservableProperty] private bool _isBusy;
    [ObservableProperty] private string _log = "";

    public ObservableCollection<string> Packages { get; } = [];
    public ObservableCollection<AssetRow> Assets { get; } = [];
    public ObservableCollection<string> Categories { get; } =
        ["All", "Characters", "First-Person", "Weapons", "Textures"];

    public MainViewModel()
    {
        string? found = GameLocator.Find();
        if (found is not null)
        {
            GamePath = found;
            LoadPackages();
        }
    }

    partial void OnSearchChanged(string value) => ApplyFilter();
    partial void OnSelectedCategoryChanged(string value) => ApplyFilter();

    partial void OnSelectedPackageChanged(string value)
    {
        if (!string.IsNullOrEmpty(value)) _ = LoadAssetsAsync(value);
    }

    [RelayCommand]
    private void Detect()
    {
        string? found = GameLocator.Find();
        if (found is null)
        {
            Status = "Could not find BioShock Remastered. Enter the install folder manually.";
            return;
        }
        GamePath = found;
        LoadPackages();
    }

    [RelayCommand]
    private void UsePath()
    {
        if (!GameLocator.IsGameRoot(GamePath))
        {
            Status = $"'{GamePath}' does not look like a BioShock Remastered install (no ContentBaked\\pc\\Maps).";
            return;
        }
        LoadPackages();
    }

    private void LoadPackages()
    {
        Packages.Clear();
        foreach (string file in GameLocator.EnumeratePackages(GamePath))
            Packages.Add(Path.GetFileNameWithoutExtension(file));

        // The weapon viewmodels live in a script package, not a map.
        string? weapons = GameLocator.WeaponPackage(GamePath);
        if (weapons is not null) Packages.Add(Path.GetFileNameWithoutExtension(weapons));

        Status = $"Found {Packages.Count} packages. Pick one to browse.";
        if (Packages.Count > 0) SelectedPackage = Packages.Contains("0-Lighthouse") ? "0-Lighthouse" : Packages[0];
    }

    private string ResolvePackagePath(string name)
    {
        string mapped = Path.Combine(GameLocator.MapsDirectory(GamePath), name + ".bsm");
        if (File.Exists(mapped)) return mapped;

        string? weapons = GameLocator.WeaponPackage(GamePath);
        if (weapons is not null && Path.GetFileNameWithoutExtension(weapons) == name) return weapons;

        throw new FileNotFoundException($"Package '{name}' not found.");
    }

    private async Task LoadAssetsAsync(string packageName)
    {
        IsBusy = true;
        Status = $"Reading {packageName}…";

        try
        {
            var rows = await Task.Run(() =>
            {
                var result = new List<AssetRow>();
                using var package = BioShockPackage.Open(ResolvePackagePath(packageName));

                foreach (var character in CharacterCatalog.Find(package))
                {
                    // Props and doors also have animation packages; the split is by substance, not name.
                    bool isCharacter = character.AnimationCount >= 20 && character.LargestMeshSize > 200_000;
                    string category = character.Group.Contains("PlayerHands", StringComparison.OrdinalIgnoreCase)
                        ? "First-Person"
                        : character.Group.StartsWith("WP_", StringComparison.OrdinalIgnoreCase)
                            ? "Weapons"
                            : isCharacter ? "Characters" : "Props";

                    result.Add(new AssetRow
                    {
                        Category = category,
                        Name = character.Group,
                        Detail = $"{character.AnimationCount} animations · {character.Meshes.Count} mesh(es) · " +
                                 $"{character.TextureCount} textures",
                        Package = packageName,
                        Group = character.Group,
                        ObjectName = character.AnimationPackageObject,
                    });
                }

                foreach (var export in package.Exports.Where(e => package.GetClassName(e) == TextureReader.ClassName))
                {
                    var texture = TextureReader.Read(package, export);
                    if (texture is null) continue;
                    result.Add(new AssetRow
                    {
                        Category = "Textures",
                        Name = texture.Name,
                        Detail = $"{texture.Format} · {texture.Width}x{texture.Height} · {texture.Mips.Count} mips",
                        Package = packageName,
                        Group = AssetContextResolver.TopLevelGroup(package, export),
                        ObjectName = texture.Name,
                    });
                }

                return result;
            });

            _allAssets = rows;
            ApplyFilter();
            Status = $"{packageName}: {rows.Count} assets.";
        }
        catch (Exception ex)
        {
            Status = $"Could not read {packageName}: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
        }
    }

    private void ApplyFilter()
    {
        Assets.Clear();
        IEnumerable<AssetRow> query = _allAssets;

        if (SelectedCategory != "All")
            query = query.Where(a => a.Category == SelectedCategory);

        if (!string.IsNullOrWhiteSpace(Search))
            query = query.Where(a => a.Name.Contains(Search, StringComparison.OrdinalIgnoreCase));

        foreach (var row in query.OrderBy(a => a.Category).ThenBy(a => a.Name).Take(2000))
            Assets.Add(row);
    }

    [RelayCommand]
    private void Cancel() => _cancellation?.Cancel();

    [RelayCommand]
    private async Task ExtractSelectedAsync()
    {
        if (SelectedAsset is null) { Status = "Select an asset first."; return; }
        await ExtractAsync([SelectedAsset]);
    }

    [RelayCommand]
    private async Task ExtractVisibleAsync() => await ExtractAsync(Assets.ToList());

    private async Task ExtractAsync(IReadOnlyList<AssetRow> rows)
    {
        if (rows.Count == 0) { Status = "Nothing to extract."; return; }

        _cancellation = new CancellationTokenSource();
        var token = _cancellation.Token;
        IsBusy = true;
        Progress = 0;
        Log = "";

        int done = 0, failed = 0, skipped = 0;

        try
        {
            await Task.Run(() =>
            {
                using var package = BioShockPackage.Open(ResolvePackagePath(rows[0].Package));

                foreach (var row in rows)
                {
                    token.ThrowIfCancellationRequested();

                    try
                    {
                        if (row.Category == "Textures") ExtractTexture(package, row);
                        else ExtractAnimatedAsset(package, row);
                        done++;
                    }
                    catch (Exception ex)
                    {
                        failed++;
                        Append($"{row.Name}: {ex.Message}");
                    }

                    int processed = done + failed + skipped;
                    Progress = processed * 100.0 / rows.Count;
                    ProgressText = $"{processed} / {rows.Count}  ·  {done} ok  ·  {failed} failed";
                }
            }, token);

            Status = $"Extracted {done} of {rows.Count} to {OutputDirectory}. {failed} failed.";
        }
        catch (OperationCanceledException)
        {
            Status = $"Cancelled after {done} of {rows.Count}.";
        }
        catch (Exception ex)
        {
            Status = $"Extraction failed: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
            _cancellation = null;
        }
    }

    private void ExtractTexture(BioShockPackage package, AssetRow row)
    {
        var export = package.Exports
            .Where(e => e.ObjectName == row.ObjectName && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize) ?? throw new InvalidOperationException("texture not found");

        var texture = TextureReader.Read(package, export) ?? throw new InvalidOperationException("format not understood");

        string directory = Path.Combine(OutputDirectory, "Textures", row.Package);
        Directory.CreateDirectory(directory);

        string stem = Sanitise(row.Group == texture.Name ? texture.Name : $"{row.Group}.{texture.Name}");
        var top = texture.Mips[0];

        PngWriter.Write(Path.Combine(directory, stem + ".png"),
            BlockCompression.Decode(texture.Format, top.Data, top.Width, top.Height), top.Width, top.Height);

        if (texture.Format != BioShockTextureFormat.Rgba8)
            DdsWriter.Write(Path.Combine(directory, stem + ".dds"), texture);
    }

    private void ExtractAnimatedAsset(BioShockPackage package, AssetRow row)
    {
        var export = package.Exports
            .Where(e => e.ObjectName == row.ObjectName
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize) ?? throw new InvalidOperationException("animation package not found");

        var animations = AnimationPackage.Load(package, export);

        // Companion mesh, sockets and geometry, if the group has them.
        var meshExport = package.Exports
            .Where(e => package.GetClassName(e) == AssetClasses.SkeletalMesh
                        && string.Equals(AssetContextResolver.TopLevelGroup(package, e), row.Group,
                            StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        IReadOnlyList<MeshSocket> sockets = [];
        SkeletalMeshGeometry? geometry = null;
        if (meshExport is not null)
        {
            byte[] payload = package.ReadExportData(meshExport);
            sockets = SkeletalMeshReader.ReadSockets(payload, package.Names);
            geometry = SkeletalMeshReader.ReadGeometry(payload);
        }

        var events = new Dictionary<string, IReadOnlyList<AnimationEvent>>(StringComparer.Ordinal);
        foreach (var animation in animations.Animations)
        {
            var metadata = package.Exports.FirstOrDefault(e =>
                string.Equals(e.ObjectName, AnimationMetadataReader.ObjectPrefix + animation.Name,
                    StringComparison.OrdinalIgnoreCase));
            if (metadata is null) continue;
            var track = AnimationMetadataReader.ReadEvents(package, metadata, animation.Duration);
            if (track.Count > 0) events[animation.Name] = track;
        }

        var scene = Core.Export.AnimationSceneExporter.Build(animations, null, sockets, geometry, events);

        string directory = Path.Combine(OutputDirectory,
            row.Category == "First-Person" ? "FirstPerson" : "Characters", row.Package);
        Directory.CreateDirectory(directory);
        Core.Export.AnimationSceneExporter.WriteJson(scene, Path.Combine(directory, Sanitise(row.Group) + ".json"));
    }

    private static string Sanitise(string name) => string.Concat(name.Split(Path.GetInvalidFileNameChars()));

    private void Append(string line) => Log += line + Environment.NewLine;

    [RelayCommand]
    private void OpenOutput()
    {
        Directory.CreateDirectory(OutputDirectory);
        Process.Start(new ProcessStartInfo(OutputDirectory) { UseShellExecute = true });
    }
}
