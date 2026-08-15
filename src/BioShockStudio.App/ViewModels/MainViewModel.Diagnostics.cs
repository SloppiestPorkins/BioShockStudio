using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Avalonia.Threading;
using BioShockStudio.Core.Diagnostics;
using BioShockStudio.Core.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace BioShockStudio.App.ViewModels;

/// <summary>
/// The Problems panel.
/// </summary>
/// <remarks>
/// <para>
/// Every fault found in the sessions before this one was found by a human looking at the viewport —
/// grey security cameras, an armless splicer, a misaligned prop — while the tool already held the
/// evidence and never showed it. This panel is that evidence, surfaced.
/// </para>
/// <para>
/// It holds no checks of its own. <see cref="DiagnosticsService"/> in Core decides what is wrong and
/// why, so the panel and the command line cannot disagree about the state of an asset, and so the
/// checks can be tested without a window.
/// </para>
/// </remarks>
public partial class MainViewModel
{
    private DiagnosticsService? _diagnostics;
    private CancellationTokenSource? _diagnosticWork;

    /// <summary>Set by the view: puts text on the system clipboard. Null in the designer.</summary>
    public Func<string, Task>? CopyText { get; set; }

    /// <summary>What is wrong with the whole scanned scope.</summary>
    public ObservableCollection<Diagnostic> Problems { get; } = [];

    /// <summary>What is wrong with the selected asset, shown beside it in the details panel.</summary>
    public ObservableCollection<Diagnostic> AssetProblems { get; } = [];

    [ObservableProperty] private Diagnostic? _selectedProblem;
    [ObservableProperty] private string _problemsSummary = "";
    [ObservableProperty] private bool _isScanning;

    /// <summary>
    /// Whether the panel has been run at all. Without this an empty list is ambiguous — a clean
    /// package and an unrun scan look identical, and that is exactly the confusion this panel exists
    /// to remove.
    /// </summary>
    [ObservableProperty] private bool _hasScanned;

    private DiagnosticsService Diagnostics => _diagnostics ??= new DiagnosticsService(_catalog);

    /// <summary>
    /// Posts a scan's progress to the UI thread.
    /// </summary>
    /// <remarks>
    /// The scan runs on a worker, so its progress has to be posted rather than assigned: an
    /// observable property set off the UI thread is the kind of fault that only shows up on someone
    /// else's machine.
    /// </remarks>
    private void Report(string message) => Dispatcher.UIThread.Post(() => ProgressText = message);

    /// <summary>Scans the package the browser is filtered to, or the selected asset's own.</summary>
    [RelayCommand]
    private async Task ScanPackageAsync()
    {
        string? package = SelectedPackage != AllPackages
            ? SelectedPackage
            : SelectedAsset?.Package;

        if (package is null)
        {
            ProblemsSummary = "Choose a package in the browser, or select an asset, then scan.";
            return;
        }

        await ScanAsync($"Checking {package}…",
            token => Diagnostics.ScanPackage(package, token, Report));
    }

    /// <summary>Scans every mesh, material and texture in the install. Minutes, not seconds.</summary>
    [RelayCommand]
    private async Task ScanEverythingAsync()
    {
        if (!HasInstall) return;
        string root = GamePath;

        await ScanAsync("Checking every asset in the game…",
            token => Diagnostics.ScanEverything(root, Report, token));
    }

    private async Task ScanAsync(string status, Func<CancellationToken, DiagnosticReport> work)
    {
        _diagnosticWork?.Cancel();
        _diagnosticWork = new CancellationTokenSource();
        var token = _diagnosticWork.Token;

        // Deliberately not IsBusy: that flag is the extraction pipeline's, and borrowing it would
        // let a finishing scan re-enable the Extract buttons in the middle of an extraction.
        IsScanning = true;
        Status = status;
        Problems.Clear();

        try
        {
            var report = await Task.Run(() => work(token), token);
            if (token.IsCancellationRequested) return;

            // Worst first: a panel sorted by package buries the broken assets under the degraded
            // ones, and the broken ones are what a user is looking for.
            foreach (var diagnostic in report.Diagnostics
                         .OrderByDescending(d => d.Severity)
                         .ThenBy(d => d.Code, StringComparer.Ordinal)
                         .ThenBy(d => d.Asset, StringComparer.OrdinalIgnoreCase))
            {
                Problems.Add(diagnostic);
            }

            HasScanned = true;
            ProblemsSummary = Describe(report);
            Status = ProblemsSummary;
        }
        catch (OperationCanceledException)
        {
            Status = "Check cancelled.";
        }
        catch (Exception ex)
        {
            ProblemsSummary = $"The check could not run: {ex.Message}";
            Status = ProblemsSummary;
        }
        finally
        {
            IsScanning = false;
            ProgressText = "";
        }
    }

    /// <summary>
    /// One line saying what was examined and what came of it.
    /// </summary>
    /// <remarks>
    /// It always states the coverage, including when nothing is wrong. "No problems found" on its own
    /// is the kind of statement this project has been wrong about before.
    /// </remarks>
    private static string Describe(DiagnosticReport report)
    {
        string examined = $"{report.Coverage.Meshes:N0} meshes, {report.Coverage.Materials:N0} materials "
                          + $"and {report.Coverage.Textures:N0} textures";

        return report.Diagnostics.Count == 0
            ? $"Checked {examined}. Nothing wrong found."
            : $"{report.Diagnostics.Count:N0} problems on {report.AffectedAssets:N0} assets, out of "
              + $"{examined} checked — {report.Count(DiagnosticSeverity.Broken):N0} broken, "
              + $"{report.Count(DiagnosticSeverity.Degraded):N0} degraded.";
    }

    [RelayCommand]
    private void CancelScan() => _diagnosticWork?.Cancel();

    /// <summary>
    /// Copies the whole diagnostic — asset, package, subsystem, evidence and the research note it
    /// belongs to — so a report to a future session costs one click rather than a retyping.
    /// </summary>
    [RelayCommand]
    private async Task CopyProblemAsync()
    {
        if (SelectedProblem is null || CopyText is null) return;
        await CopyText(SelectedProblem.ToReport());
        Status = $"Copied the diagnostic for {SelectedProblem.Asset}.";
    }

    /// <summary>Copies every problem currently listed, for a whole-package report.</summary>
    [RelayCommand]
    private async Task CopyAllProblemsAsync()
    {
        if (Problems.Count == 0 || CopyText is null) return;

        await CopyText(string.Join(
            Environment.NewLine + Environment.NewLine,
            new[] { ProblemsSummary }.Concat(Problems.Select(p => p.ToReport()))));

        Status = $"Copied {Problems.Count:N0} diagnostics.";
    }

    /// <summary>
    /// Catalogue rows naming an asset, whichever map each is reported under. For the tests, which
    /// otherwise cannot see whether a diagnostic's asset is in the browser at all.
    /// </summary>
    public IReadOnlyList<CatalogEntry> CatalogueEntriesNamed(string asset) => _catalog.Entries
        .Where(e => string.Equals(e.ObjectName, asset, StringComparison.OrdinalIgnoreCase)
                    || string.Equals(e.Name, asset, StringComparison.OrdinalIgnoreCase))
        .ToList();

    /// <summary>Selecting a problem selects the asset it is about, so the viewport shows it.</summary>
    /// <remarks>
    /// <b>The row's package is not the only package it is in.</b> Every map embeds its own copy of
    /// what it uses, so the catalogue collapses duplicates into one row that carries all of them in
    /// <c>Packages</c> — and the one it reports as <c>Package</c> is often a different map from the
    /// one the diagnostic was raised in. Matching on both name and package therefore failed on real
    /// data (<c>Cheese_Mould_Normal</c>, raised in <c>0-Lighthouse</c>, listed under another map) and
    /// the click did nothing. This mirrors the catalogue's own <c>InPackage</c> rule instead.
    /// </remarks>
    partial void OnSelectedProblemChanged(Diagnostic? value)
    {
        if (value is null) return;

        if (!NavigateTo(value.Asset, value.Package))
        {
            // The catalogue does not list every export — a shader or a mip-stripped texture may have
            // no row of its own — so a diagnostic can name something the browser cannot show. Saying
            // so beats a dead click.
            Status = $"{value.Asset} has no row in the browser; it is export {value.ExportIndex} "
                     + $"of {value.Package}.";
        }
    }

    /// <summary>
    /// Loads the selected asset's own problems. Called from the details path, on the same background
    /// pass, because it opens the package.
    /// </summary>
    private async Task ShowAssetProblemsAsync(CatalogEntry? entry, CancellationToken token)
    {
        AssetProblems.Clear();
        if (entry is null || !_catalog.IsLoaded) return;

        try
        {
            var report = await Task.Run(() => Diagnostics.ScanAsset(entry, token), token);
            if (token.IsCancellationRequested) return;

            foreach (var diagnostic in report.Diagnostics.OrderByDescending(d => d.Severity))
                AssetProblems.Add(diagnostic);
        }
        catch (OperationCanceledException)
        {
            // Superseded by a newer selection.
        }
        catch (Exception)
        {
            // The details panel already reports why an asset could not be read; a second failure
            // message about the checks themselves would be noise.
        }
    }
}
