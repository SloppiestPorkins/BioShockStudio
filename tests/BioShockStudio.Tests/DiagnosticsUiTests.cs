using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Avalonia.Headless;
using Avalonia.Headless.XUnit;
using Avalonia.Threading;
using BioShockStudio.App.ViewModels;
using BioShockStudio.App.Views;
using BioShockStudio.Core.Game;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The Problems panel, driven the way the window drives it.
/// </summary>
/// <remarks>
/// <c>DiagnosticsTests</c> proves the checks find things. It cannot prove the button reaches them,
/// and a panel that is always empty is worse than no panel: it reads as a clean bill of health.
/// This project has shipped three features that were implemented, tested and invisible.
/// </remarks>
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class DiagnosticsUiTests
{
    private static async Task<bool> WaitFor(Func<bool> condition, int seconds = 900)
    {
        for (int i = 0; i < seconds * 20; i++)
        {
            Dispatcher.UIThread.RunJobs();
            if (condition()) return true;
            await Task.Delay(50);
        }

        return false;
    }

    private static MainViewModel? _shared;

    /// <summary>
    /// One view model for the whole class, with its catalogue built.
    /// </summary>
    /// <remarks>
    /// Building the catalogue reads every shipped package and takes over a minute, so constructing
    /// one per test would cost more than the rest of the suite. The tests below are therefore written
    /// not to depend on each other's leftovers — none asserts on a state a previous one could have
    /// set.
    /// </remarks>
    private static async Task<MainViewModel?> LoadedModel()
    {
        if (GameLocator.Find() is null) return null;
        if (_shared is not null) return _shared;

        var model = new MainViewModel();
        Assert.True(await WaitFor(() => model.HasInstall && model.TotalCount > 0),
            $"the catalogue never loaded (status: {model.Status})");
        Assert.True(await WaitFor(() => !model.IsBusy), "the view model never stopped being busy");
        return _shared = model;
    }

    /// <summary>
    /// The shared model with one package checked. Checking a package decodes every texture in it, so
    /// this is done once for the class rather than once per test.
    /// </summary>
    private static async Task<MainViewModel?> ScannedModel()
    {
        if (await LoadedModel() is not { } model) return null;
        if (model.HasScanned) return model;

        model.SelectedPackage = "0-Lighthouse";
        await model.ScanPackageCommand.ExecuteAsync(null);
        await WaitFor(() => !model.IsScanning);

        Assert.True(model.HasScanned, $"the check never completed (status: {model.Status})");
        Assert.NotEmpty(model.Problems);
        return model;
    }

    /// <summary>
    /// Nothing is claimed before anything is checked.
    /// </summary>
    /// <remarks>
    /// An empty Problems panel that has not run reads as a clean bill of health, and this project has
    /// been wrong in exactly that direction before. The panel says so in as many words, and
    /// <c>HasScanned</c> is what it says it with.
    /// </remarks>
    [AvaloniaFact]
    public void NothingIsClaimedBeforeACheckHasRun()
    {
        var model = new MainViewModel();

        Assert.False(model.HasScanned);
        Assert.Empty(model.Problems);
        Assert.Equal(string.Empty, model.ProblemsSummary);
    }

    /// <summary>
    /// "Check this package" fills the panel, and selecting a row selects the asset it is about.
    /// </summary>
    [AvaloniaFact]
    public async Task CheckingAPackageFillsThePanelAndTheRowsNavigate()
    {
        if (await ScannedModel() is not { } model) return;

        // The summary states coverage even when it also states faults, so a short scan cannot read
        // as a whole-game verdict.
        Assert.Contains("meshes", model.ProblemsSummary, StringComparison.Ordinal);

        // Worst first. A panel sorted any other way buries what a user came for.
        Assert.Equal(
            model.Problems.Select(p => p.Severity).OrderByDescending(s => s),
            model.Problems.Select(p => p.Severity));

        // Click-to-navigate: a problem on an asset the browser lists selects that asset.
        var navigable = model.Problems.FirstOrDefault(p => model.Assets.Any(a =>
            string.Equals(a.Package, p.Package, StringComparison.OrdinalIgnoreCase)
            && string.Equals(a.Name, p.Asset, StringComparison.OrdinalIgnoreCase)));

        if (navigable is not null)
        {
            model.SelectedProblem = navigable;
            Assert.True(await WaitFor(() => model.SelectedAsset is not null));
            Assert.Equal(navigable.Asset, model.SelectedAsset!.Name, ignoreCase: true);
        }
    }

    /// <summary>
    /// A problem on an asset that several maps embed still navigates.
    /// </summary>
    /// <remarks>
    /// Found by rendering the panel, not by a number: every map embeds its own copy of what it uses,
    /// so the catalogue collapses duplicates into one row whose reported package is often a different
    /// map from the one the diagnostic came from. Requiring both name and package to match made the
    /// click do nothing and print "not in the browser's list" — on an asset that was in it.
    /// </remarks>
    [AvaloniaFact]
    public async Task AProblemOnAnAssetSeveralMapsEmbedStillNavigates()
    {
        if (await ScannedModel() is not { } model) return;

        // A row whose catalogue entry exists but reports a different package — the case that failed.
        var shared = model.Problems.FirstOrDefault(p => model.CatalogueEntriesNamed(p.Asset)
            .Any(e => !string.Equals(e.Package, p.Package, StringComparison.OrdinalIgnoreCase)));

        if (shared is null) return;   // nothing in this package is embedded elsewhere; nothing to prove

        model.SelectedProblem = shared;
        Assert.True(await WaitFor(() => model.SelectedAsset is not null, seconds: 60),
            $"selecting a problem on {shared.Asset} ({shared.Package}) selected nothing "
            + $"(status: {model.Status})");
        Assert.Equal(shared.Asset, model.SelectedAsset!.Name, ignoreCase: true);
    }

    /// <summary>
    /// Copy Diagnostic produces the whole entry, not just its summary.
    /// </summary>
    /// <remarks>
    /// The point of the button is a report a future session can act on without this one, so what it
    /// puts on the clipboard has to carry the package and the evidence.
    /// </remarks>
    [AvaloniaFact]
    public async Task CopyDiagnosticProducesTheAssetPackageAndEvidence()
    {
        if (await ScannedModel() is not { } model) return;

        string copied = string.Empty;
        model.CopyText = text => { copied = text; return Task.CompletedTask; };

        model.SelectedProblem = model.Problems.First();
        await model.CopyProblemCommand.ExecuteAsync(null);

        Assert.Contains(model.SelectedProblem!.Asset, copied, StringComparison.Ordinal);
        Assert.Contains(model.SelectedProblem.Package, copied, StringComparison.Ordinal);
        Assert.Contains(model.SelectedProblem.Evidence, copied, StringComparison.Ordinal);
    }

    /// <summary>
    /// Selecting an asset that has a known fault shows it beside the asset.
    /// </summary>
    /// <remarks>
    /// <c>LowRentDoor_Mesh</c> is a door rig carrying no vertex data — the case the details panel
    /// used to describe as an unsupported layout. It is used here because it is the one asset whose
    /// fault is pinned by its own regression test, so a change in behaviour is unambiguous.
    /// </remarks>
    [AvaloniaFact]
    public async Task SelectingAFaultyAssetShowsItsProblemInTheDetailsPanel()
    {
        if (await LoadedModel() is not { } model) return;

        // The model is shared with the other tests in this class, so the browser's filters have to
        // be put back before searching: this mesh is in 1-Medical, and a test that checked
        // 0-Lighthouse leaves the package filter pointing there.
        model.SelectedPackage = MainViewModel.AllPackages;
        model.SelectedCategory = model.Categories.First();
        model.Search = "LowRentDoor_Mesh";

        Assert.True(await WaitFor(() => model.Assets.Any(a => a.Name == "LowRentDoor_Mesh"), seconds: 30),
            $"LowRentDoor_Mesh is not in the browser ({model.Assets.Count} rows shown, "
            + $"package filter '{model.SelectedPackage}')");

        model.SelectedAsset = model.Assets.First(a => a.Name == "LowRentDoor_Mesh");

        Assert.True(await WaitFor(() => model.AssetProblems.Count > 0, seconds: 120),
            $"no problem was shown for a mesh with no geometry (details problem: {model.DetailsProblem})");

        var problem = model.AssetProblems.First();
        Assert.Equal("mesh-no-geometry", problem.Code);
        Assert.Contains("byte payload", problem.Evidence, StringComparison.Ordinal);
    }

    /// <summary>The window renders with the panel in it.</summary>
    /// <remarks>
    /// Numeric validation has passed on invisible features in this project before — a column squeezed
    /// to zero width, an error message never displayed. Set <c>BIOSHOCK_PROBLEMS_SNAPSHOT</c> to a
    /// path to write the frame out and look at it.
    /// </remarks>
    [AvaloniaFact]
    public async Task TheWindowRendersWithTheProblemsPanel()
    {
        if (await ScannedModel() is not { } model) return;

        model.SelectedProblem = model.Problems.First();
        await WaitFor(() => model.SelectedAsset is not null);

        var window = new MainWindow { DataContext = model };
        window.Show();
        Dispatcher.UIThread.RunJobs();

        var frame = window.CaptureRenderedFrame();
        Assert.NotNull(frame);

        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBLEMS_SNAPSHOT") is { Length: > 0 } path)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            frame!.Save(path);
        }
    }
}
