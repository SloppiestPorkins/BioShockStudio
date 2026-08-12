using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Avalonia.Media.Imaging;
using BioShockStudio.Core.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace BioShockStudio.App.ViewModels;

/// <summary>One entry in the category list, with how many assets it holds.</summary>
public sealed record CategoryRow(AssetCategory? Category, string Label, int Count)
{
    public string Display => Count > 0 ? $"{Label}  ({Count:N0})" : Label;
}

/// <summary>A check shown in the installation panel.</summary>
public sealed record CheckRow(string Glyph, string Name, string Detail, bool Passed);

/// <summary>A failed extraction, kept so the user can see what did not come out and why.</summary>
public sealed record FailureRow(string Name, string Package, string Reason);

/// <summary>
/// The application's single window.
/// </summary>
/// <remarks>
/// This holds no parsing, no format knowledge and no file layout decisions. Everything it shows
/// comes from the services in <c>BioShockStudio.Core.Services</c>, which is why those can be tested
/// without a window and why the browser and the command line cannot drift apart.
/// </remarks>
public partial class MainViewModel : ViewModelBase
{
    private readonly InstallationService _installation = new();
    private readonly AssetCatalogService _catalog = new();
    private readonly AssetDetailsService _details;
    private readonly TexturePreviewService _textures;
    private readonly ExtractionService _extraction;

    private CancellationTokenSource? _work;
    private CancellationTokenSource? _detailsWork;

    /// <summary>Set by the view: the platform folder picker. Null in the designer.</summary>
    public Func<string, Task<string?>>? PickFolder { get; set; }

    [ObservableProperty] private string _gamePath = "";
    [ObservableProperty] private bool _hasInstall;
    [ObservableProperty] private string _installSummary = "Choose your BioShock Remastered folder to begin.";
    [ObservableProperty] private string _status = "";
    [ObservableProperty] private bool _isBusy;
    [ObservableProperty] private double _progress;
    [ObservableProperty] private string _progressText = "";
    [ObservableProperty] private bool _researchMode;

    [ObservableProperty] private string _search = "";
    [ObservableProperty] private CategoryRow? _selectedCategory;
    [ObservableProperty] private string _selectedPackage = AllPackages;
    [ObservableProperty] private CatalogEntry? _selectedAsset;
    [ObservableProperty] private int _shownCount;
    [ObservableProperty] private int _totalCount;

    /// <summary>
    /// How many results are shown against how many exist, and whether the list was capped.
    /// </summary>
    /// <remarks>
    /// The cap matters: showing "2,000 of 71,106" without saying it is a limit reads as a filter
    /// that found 2,000 matches.
    /// </remarks>
    [ObservableProperty] private string _resultSummary = "";

    [ObservableProperty] private string _detailsTitle = "";
    [ObservableProperty] private string _detailsSubtitle = "";
    [ObservableProperty] private string? _detailsProblem;
    [ObservableProperty] private Bitmap? _texturePreview;
    [ObservableProperty] private string _texturePreviewCaption = "";

    [ObservableProperty] private string _outputDirectory =
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "BioShockExtract");

    [ObservableProperty] private bool _exportSceneJson = true;
    [ObservableProperty] private bool _exportFbx = true;
    [ObservableProperty] private bool _exportPng = true;
    [ObservableProperty] private bool _exportDds;
    [ObservableProperty] private bool _preservePackageStructure = true;
    [ObservableProperty] private bool _skipExisting;

    public const string AllPackages = "All packages";

    /// <summary>Rows the grid will hold at once. Beyond this the user is told to narrow the search.</summary>
    private const int SearchLimit = 2000;

    public ObservableCollection<CheckRow> Checks { get; } = [];
    public ObservableCollection<CategoryRow> Categories { get; } = [];
    public ObservableCollection<string> Packages { get; } = [AllPackages];
    public ObservableCollection<CatalogEntry> Assets { get; } = [];
    public ObservableCollection<DetailField> DetailFields { get; } = [];
    public ObservableCollection<DetailSection> DetailSections { get; } = [];
    public ObservableCollection<DetailField> ResearchFields { get; } = [];
    public ObservableCollection<FailureRow> Failures { get; } = [];

    public MainViewModel()
    {
        _details = new AssetDetailsService(_catalog);
        _textures = new TexturePreviewService(_catalog);
        _extraction = new ExtractionService(_catalog);

        string? found = _installation.Detect();
        if (found is not null) _ = UseInstallAsync(found);
    }

    // ------------------------------------------------------------------ installation

    [RelayCommand]
    private async Task DetectAsync()
    {
        string? found = _installation.Detect();
        if (found is null)
        {
            InstallSummary = "Could not find BioShock Remastered automatically. Use Browse to point at the folder.";
            return;
        }
        await UseInstallAsync(found);
    }

    [RelayCommand]
    private async Task BrowseAsync()
    {
        if (PickFolder is null) return;
        string? chosen = await PickFolder("Select your BioShock Remastered folder");
        if (chosen is not null) await UseInstallAsync(chosen);
    }

    [RelayCommand]
    private async Task UseTypedPathAsync() => await UseInstallAsync(GamePath);

    private async Task UseInstallAsync(string path)
    {
        GamePath = path;

        var report = _installation.Validate(path);
        Checks.Clear();
        foreach (var check in report.Checks)
            Checks.Add(new CheckRow(check.Passed ? "✓" : check.Required ? "✕" : "⚠", check.Name, check.Detail, check.Passed));

        if (!report.IsUsable)
        {
            HasInstall = false;
            InstallSummary = report.Problem ?? "That folder cannot be used.";
            return;
        }

        HasInstall = true;
        InstallSummary = $"{path}  ·  {report.Packages.Count} map packages";
        _catalog.RegisterInstall(path);

        await BuildCatalogAsync(path);
    }

    private async Task BuildCatalogAsync(string path)
    {
        _work?.Cancel();
        _work = new CancellationTokenSource();
        var token = _work.Token;

        IsBusy = true;
        Status = "Reading the game's packages…";

        try
        {
            var progress = new Progress<CatalogProgress>(p =>
            {
                Progress = p.PackagesTotal == 0 ? 0 : p.PackagesDone * 100.0 / p.PackagesTotal;
                ProgressText = p.CurrentPackage.Length > 0
                    ? $"{p.CurrentPackage}  ·  {p.EntriesSoFar:N0} assets"
                    : $"{p.EntriesSoFar:N0} assets";
            });

            await _catalog.BuildAsync(path, progress, token);

            Packages.Clear();
            Packages.Add(AllPackages);
            foreach (string name in _catalog.Packages.Order(StringComparer.OrdinalIgnoreCase)) Packages.Add(name);
            SelectedPackage = AllPackages;

            RefreshCategories();
            TotalCount = _catalog.Entries.Count;
            ApplyFilter();

            Status = _catalog.Failures.Count == 0
                ? $"{TotalCount:N0} assets across {_catalog.Packages.Count} packages."
                : $"{TotalCount:N0} assets. {_catalog.Failures.Count} packages could not be read.";

            foreach (var failure in _catalog.Failures)
                Failures.Add(new FailureRow(failure.Package, failure.Package, failure.Reason));
        }
        catch (OperationCanceledException)
        {
            Status = "Cancelled.";
        }
        catch (Exception ex)
        {
            Status = $"Could not read the game: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
            ProgressText = "";
        }
    }

    private void RefreshCategories()
    {
        var counts = _catalog.CategoryCounts();
        Categories.Clear();
        Categories.Add(new CategoryRow(null, "Everything", _catalog.Entries.Count));

        // Fixed order: the things a user comes here for first.
        foreach (var category in new[]
                 {
                     AssetCategory.FirstPerson, AssetCategory.Characters, AssetCategory.Weapons,
                     AssetCategory.Props, AssetCategory.SkeletalMeshes, AssetCategory.StaticMeshes,
                     AssetCategory.Animations, AssetCategory.Textures, AssetCategory.Materials,
                 })
        {
            Categories.Add(new CategoryRow(category, Label(category), counts.GetValueOrDefault(category)));
        }

        SelectedCategory = Categories[0];
    }

    private static string Label(AssetCategory category) => category switch
    {
        AssetCategory.FirstPerson => "First person",
        AssetCategory.SkeletalMeshes => "Skeletal meshes",
        AssetCategory.StaticMeshes => "Static meshes",
        _ => category.ToString(),
    };

    // ------------------------------------------------------------------ browsing

    partial void OnSearchChanged(string value) => ApplyFilter();
    partial void OnSelectedCategoryChanged(CategoryRow? value) => ApplyFilter();
    partial void OnSelectedPackageChanged(string value) => ApplyFilter();

    private void ApplyFilter()
    {
        if (!_catalog.IsLoaded) return;

        var results = _catalog.Search(
            Search,
            SelectedCategory?.Category,
            SelectedPackage == AllPackages ? null : SelectedPackage,
            SearchLimit);

        Assets.Clear();
        foreach (var entry in results.OrderBy(e => e.Category).ThenBy(e => e.Name, StringComparer.OrdinalIgnoreCase))
            Assets.Add(entry);

        ShownCount = Assets.Count;
        ResultSummary = ShownCount >= SearchLimit
            ? $"first {ShownCount:N0} of {TotalCount:N0} — narrow the search to see the rest"
            : $"{ShownCount:N0} of {TotalCount:N0}";
    }

    partial void OnSelectedAssetChanged(CatalogEntry? value) => _ = ShowDetailsAsync(value);

    private async Task ShowDetailsAsync(CatalogEntry? entry)
    {
        _detailsWork?.Cancel();
        DetailFields.Clear();
        DetailSections.Clear();
        ResearchFields.Clear();
        TexturePreview = null;
        TexturePreviewCaption = "";
        DetailsProblem = null;

        if (entry is null)
        {
            DetailsTitle = "";
            DetailsSubtitle = "";
            return;
        }

        DetailsTitle = entry.Name;
        DetailsSubtitle = $"{Label(entry.Category)} · {entry.Package}";

        _detailsWork = new CancellationTokenSource();
        var token = _detailsWork.Token;

        try
        {
            // Reading a skeleton or decoding a texture is far too slow for the UI thread; a fast
            // click through the list cancels the previous one rather than queueing behind it.
            var (details, image, caption) = await Task.Run(() =>
            {
                var described = _details.Describe(entry, token);

                if (entry.Category != AssetCategory.Textures) return (described, null, string.Empty);

                var preview = _textures.Decode(entry);
                var described2 = _textures.Describe(entry);
                string text = preview is null || described2 is null
                    ? "This texture's format is not understood, so it cannot be shown."
                    : $"{described2.Width} × {described2.Height} · {described2.Format} · "
                      + $"{described2.Mips.Count} mips · showing {preview.Width} × {preview.Height}";

                return (described, preview, text);
            }, token);

            if (token.IsCancellationRequested) return;

            foreach (var field in details.Fields) DetailFields.Add(field);
            foreach (var section in details.Sections) DetailSections.Add(section);
            foreach (var field in details.Research) ResearchFields.Add(field);
            DetailsProblem = details.Problem;

            TexturePreviewCaption = caption;
            if (image is not null) TexturePreview = ToBitmap(image);
        }
        catch (OperationCanceledException)
        {
            // Superseded by a newer selection.
        }
        catch (Exception ex)
        {
            DetailsProblem = ex.Message;
        }
    }

    /// <summary>
    /// Converts a decoded image for display.
    /// </summary>
    /// <remarks>
    /// The decoder produces RGBA and Avalonia's surface format is BGRA, so the red and blue channels
    /// are swapped here. Skipping this is not subtle — everything comes out blue.
    /// </remarks>
    private static Bitmap ToBitmap(PreviewImage image)
    {
        var bitmap = new WriteableBitmap(
            new Avalonia.PixelSize(image.Width, image.Height),
            new Avalonia.Vector(96, 96),
            Avalonia.Platform.PixelFormat.Bgra8888,
            Avalonia.Platform.AlphaFormat.Unpremul);

        var row = new byte[image.Width * 4];
        using var buffer = bitmap.Lock();

        for (int y = 0; y < image.Height; y++)
        {
            int source = y * image.Width * 4;
            for (int x = 0; x < image.Width; x++)
            {
                int from = source + x * 4;
                int to = x * 4;
                row[to] = image.Rgba[from + 2];
                row[to + 1] = image.Rgba[from + 1];
                row[to + 2] = image.Rgba[from];
                row[to + 3] = image.Rgba[from + 3];
            }

            // Copied a row at a time because the surface may be padded to a wider stride.
            System.Runtime.InteropServices.Marshal.Copy(
                row, 0, buffer.Address + y * buffer.RowBytes, row.Length);
        }

        return bitmap;
    }

    // ------------------------------------------------------------------ extraction

    private ExportFormats Formats()
    {
        var formats = ExportFormats.None;
        if (ExportSceneJson) formats |= ExportFormats.SceneJson;
        if (ExportFbx) formats |= ExportFormats.Fbx;
        if (ExportPng) formats |= ExportFormats.Png;
        if (ExportDds) formats |= ExportFormats.Dds;
        return formats;
    }

    [RelayCommand]
    private async Task ExtractSelectedAsync()
    {
        if (SelectedAsset is null) { Status = "Select an asset first."; return; }
        await ExtractAsync([SelectedAsset]);
    }

    [RelayCommand]
    private async Task ExtractShownAsync() => await ExtractAsync(Assets.ToList());

    [RelayCommand]
    private async Task ChooseOutputAsync()
    {
        if (PickFolder is null) return;
        string? chosen = await PickFolder("Where should extracted files go?");
        if (chosen is not null) OutputDirectory = chosen;
    }

    private async Task ExtractAsync(IReadOnlyList<CatalogEntry> entries)
    {
        if (entries.Count == 0) { Status = "Nothing to extract."; return; }
        if (Formats() == ExportFormats.None) { Status = "Choose at least one output format."; return; }

        _work?.Cancel();
        _work = new CancellationTokenSource();
        var token = _work.Token;

        IsBusy = true;
        Progress = 0;
        Failures.Clear();

        try
        {
            var progress = new Progress<ExtractionProgress>(p =>
            {
                Progress = p.Total == 0 ? 0 : p.Completed * 100.0 / p.Total;
                ProgressText = $"{p.Completed:N0} / {p.Total:N0}  ·  {p.Current}";
                Status = $"{p.Succeeded} done · {p.Failed} failed · {p.Skipped} skipped";
            });

            var report = await _extraction.RunAsync(
                entries,
                new ExtractionOptions
                {
                    OutputDirectory = OutputDirectory,
                    Formats = Formats(),
                    PreservePackageStructure = PreservePackageStructure,
                    SkipExisting = SkipExisting,
                },
                progress,
                token);

            foreach (var failure in report.Failures)
                Failures.Add(new FailureRow(failure.Entry.Name, failure.Entry.Package, failure.Message ?? "Unknown"));

            Status = report.Cancelled
                ? $"Cancelled. {report.Succeeded} of {entries.Count} written to {OutputDirectory}."
                : $"{report.Succeeded} of {entries.Count} written to {OutputDirectory}. "
                  + $"{report.Failed} failed, {report.Skipped} skipped.";
        }
        catch (OperationCanceledException)
        {
            Status = "Cancelled.";
        }
        catch (Exception ex)
        {
            Status = $"Extraction stopped: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
            ProgressText = "";
        }
    }

    [RelayCommand]
    private void Cancel() => _work?.Cancel();

    [RelayCommand]
    private void OpenOutput()
    {
        try
        {
            Directory.CreateDirectory(OutputDirectory);
            Process.Start(new ProcessStartInfo(OutputDirectory) { UseShellExecute = true });
        }
        catch (Exception ex)
        {
            Status = $"Could not open {OutputDirectory}: {ex.Message}";
        }
    }
}
