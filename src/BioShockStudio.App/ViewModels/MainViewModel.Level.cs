using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace BioShockStudio.App.ViewModels;

/// <summary>One line of the level's composition, shown beside the counts.</summary>
public sealed record LevelClassRow(string ClassName, int Count)
{
    public string Display => $"{ClassName}  ({Count:N0})";
}

/// <summary>
/// The Level tab: pick a map, see what is in it, write it out.
/// </summary>
/// <remarks>
/// <para>
/// Phase 2's actor layer resolved 1,877 actors on <c>0-Lighthouse</c> and then went nowhere — there
/// was no consumer for a level in any form, in the window or out of it. This is that consumer.
/// </para>
/// <para>
/// It holds no format knowledge: <see cref="LevelService"/> in Core reads and writes, so the tab and
/// a command line cannot disagree about what a level contains, and the service can be tested
/// without a window.
/// </para>
/// </remarks>
public partial class MainViewModel
{
    private readonly LevelService _levels = new();
    private CancellationTokenSource? _levelWork;

    public ObservableCollection<LevelEntry> Levels { get; } = [];
    public ObservableCollection<LevelClassRow> LevelComposition { get; } = [];

    /// <summary>Files the last extraction wrote, so the result is visible rather than merely claimed.</summary>
    public ObservableCollection<string> LevelOutputs { get; } = [];

    /// <summary>Which workspace is showing. 0 = Assets, 1 = Level.</summary>
    /// <remarks>
    /// Held here because the asset extraction bar at the foot of the window has to disappear on the
    /// Level tab. Rendering the tab the first time showed that bar under the level panel, offering
    /// "Extract selected" and "Extract all shown" — which reads as though those buttons extract the
    /// level. They do not, and the level has its own button.
    /// </remarks>
    [ObservableProperty] private int _selectedTabIndex;

    /// <summary>True while the asset browser is the visible workspace.</summary>
    public bool IsAssetsTab => SelectedTabIndex == 0;

    partial void OnSelectedTabIndexChanged(int value) => OnPropertyChanged(nameof(IsAssetsTab));

    [ObservableProperty] private LevelEntry? _selectedLevel;
    [ObservableProperty] private LevelSummary? _levelSummary;
    [ObservableProperty] private string _levelStatus = "Choose a map to see what it holds.";
    [ObservableProperty] private bool _isLevelBusy;

    /// <summary>Whether the extraction writes the OBJ as well as the scene JSON.</summary>
    /// <remarks>
    /// Both on by default. They do different jobs — the JSON keeps instancing and the lights, the
    /// OBJ opens in anything — and the OBJ is much the larger of the two, so it is separately
    /// switchable rather than bundled.
    /// </remarks>
    [ObservableProperty] private bool _levelExportSceneJson = true;
    [ObservableProperty] private bool _levelExportObj = true;
    [ObservableProperty] private bool _levelReadableJson;

    /// <summary>
    /// The warning that stops a surprise. A level OBJ is over 100 MB and the user should know before
    /// pressing the button, not after — bulk extraction size has already been reported as a fault
    /// once in this project when it was really an unstated cost.
    /// </summary>
    [ObservableProperty] private string _levelSizeWarning = "";

    public bool CanExtractLevel => SelectedLevel is not null && !IsLevelBusy
                                   && (LevelExportSceneJson || LevelExportObj);

    private void LoadLevels()
    {
        Levels.Clear();
        if (!HasInstall) return;
        foreach (var level in _levels.Levels(GamePath)) Levels.Add(level);
    }

    partial void OnSelectedLevelChanged(LevelEntry? value)
    {
        LevelSummary = null;
        LevelComposition.Clear();
        LevelOutputs.Clear();
        LevelSizeWarning = "";
        if (value is not null) _ = InspectAsync(value);
    }

    partial void OnIsLevelBusyChanged(bool value) => OnPropertyChanged(nameof(CanExtractLevel));
    partial void OnLevelExportSceneJsonChanged(bool value) => OnPropertyChanged(nameof(CanExtractLevel));
    partial void OnLevelExportObjChanged(bool value) => OnPropertyChanged(nameof(CanExtractLevel));

    private async Task InspectAsync(LevelEntry level)
    {
        _levelWork?.Cancel();
        _levelWork = new CancellationTokenSource();
        var token = _levelWork.Token;

        // Deliberately not IsBusy: that flag belongs to the extraction pipeline and borrowing it
        // would let a finishing level scan re-enable the asset Extract buttons mid-extraction. The
        // Problems panel keeps its own flag for the same reason.
        IsLevelBusy = true;
        LevelStatus = $"Reading {level.Name}…";

        try
        {
            var progress = new Progress<string>(text => LevelStatus = $"{level.Name}: {text}");
            var summary = await Task.Run(() => _levels.Describe(level.File, progress), token);
            if (token.IsCancellationRequested) return;

            LevelSummary = summary;
            LevelComposition.Clear();
            foreach (var (className, count) in summary.WithoutGeometry)
                LevelComposition.Add(new LevelClassRow(className, count));

            LevelStatus = $"{summary.Name}: {summary.Instances:N0} placed objects, {summary.Triangles:N0} triangles, "
                          + $"{summary.Lights:N0} lights.";
            LevelSizeWarning = EstimateSize(summary);
        }
        catch (OperationCanceledException)
        {
            LevelStatus = "Cancelled.";
        }
        catch (Exception ex)
        {
            LevelStatus = $"{level.Name} could not be read: {ex.Message}";
        }
        finally
        {
            IsLevelBusy = false;
        }
    }

    /// <summary>
    /// Roughly how large the export will be, stated before it runs.
    /// </summary>
    /// <remarks>
    /// From a measured rate rather than a guess: <c>0-Lighthouse</c>'s 2,181,021 triangles wrote a
    /// 112 MB OBJ, which is about 54 bytes per triangle. It is labelled "about" because it is an
    /// estimate and the window should not imply otherwise.
    /// </remarks>
    private static string EstimateSize(LevelSummary summary)
    {
        double megabytes = summary.Triangles * 54.0 / 1024 / 1024;
        return megabytes < 25
            ? ""
            : $"The OBJ for this map will be about {megabytes:0} MB.";
    }

    [RelayCommand]
    private async Task ExtractLevelAsync()
    {
        if (SelectedLevel is not { } level) return;
        if (PickFolder is null) { LevelStatus = "No folder picker is available."; return; }

        string? directory = await PickFolder("Where should the level go?");
        if (string.IsNullOrWhiteSpace(directory)) return;

        var formats = LevelExportFormats.None;
        if (LevelExportSceneJson) formats |= LevelExportFormats.SceneJson;
        if (LevelExportObj) formats |= LevelExportFormats.Obj;

        IsLevelBusy = true;
        LevelOutputs.Clear();
        LevelStatus = $"Extracting {level.Name}…";

        try
        {
            var progress = new Progress<string>(text => LevelStatus = $"{level.Name}: {text}");
            var written = await Task.Run(
                () => _levels.Extract(level.File, directory!, formats, LevelReadableJson, progress));

            foreach (string path in written)
                LevelOutputs.Add($"{Path.GetFileName(path)}  ({new FileInfo(path).Length / 1024.0 / 1024.0:0.#} MB)");

            LevelStatus = $"{level.Name}: wrote {written.Count} file{(written.Count == 1 ? "" : "s")} to {directory}.";
        }
        catch (Exception ex)
        {
            LevelStatus = $"{level.Name} could not be extracted: {ex.Message}";
        }
        finally
        {
            IsLevelBusy = false;
        }
    }
}
