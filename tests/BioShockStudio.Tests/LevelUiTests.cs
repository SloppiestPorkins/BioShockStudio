using System.Linq;
using System.Threading;
using Avalonia.Headless;
using Avalonia.Headless.XUnit;
using Avalonia.Controls;
using Avalonia.Media.Imaging;
using Avalonia.VisualTree;
using Avalonia.Threading;
using BioShockStudio.App.ViewModels;
using BioShockStudio.App.Views;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The Level tab, driven through the real view model.
/// </summary>
/// <remarks>
/// <para>
/// <b>These drive the view model's own commands and properties, not the services beneath it.</b>
/// Service tests can only prove the pipeline works; they cannot prove a button reaches it. That
/// distinction has cost this project before — extraction was reported as broken when the pipeline
/// was fine and the buttons were disabled — so the tab gets the same treatment
/// <c>ExtractionUiTests</c> gave the Extract buttons.
/// </para>
/// <para>
/// <c>BIOSHOCK_LEVELUI_SNAPSHOT</c> writes the tab out as a PNG. Three features in an earlier
/// session were implemented, tested and invisible; none were findable from the code.
/// </para>
/// </remarks>
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LevelUiTests
{
    private static void Pump(Func<bool> until, int attempts = 400, int delayMs = 50)
    {
        for (int i = 0; i < attempts && !until(); i++)
        {
            Dispatcher.UIThread.RunJobs();
            Thread.Sleep(delayMs);
        }
        Dispatcher.UIThread.RunJobs();
    }

    [AvaloniaFact]
    public void TheLevelTabListsTheMapsAndReadsOne()
    {
        var model = new MainViewModel();
        var window = new MainWindow { DataContext = model, Width = 1280, Height = 820 };
        window.Show();

        Pump(() => model.HasInstall);
        if (!model.HasInstall) return;   // no game installed; RequiresGameFact's rule, by hand.

        // The map list is a directory listing, so it is ready as soon as the install is, without
        // waiting for the asset catalogue.
        Assert.NotEmpty(model.Levels);
        Assert.Contains(model.Levels, l => l.Name == "0-Lighthouse");

        // Selecting a map reads it. This is the path the tab exists for.
        model.SelectedLevel = model.Levels.First(l => l.Name == "0-Lighthouse");
        Pump(() => model.LevelSummary is not null && !model.IsLevelBusy);

        Assert.NotNull(model.LevelSummary);
        var summary = model.LevelSummary!;

        Assert.Equal("0-Lighthouse", summary.Name);
        Assert.True(summary.Actors > 1000, $"only {summary.Actors} actors reached the window");
        Assert.True(summary.Brushes > 0, "no BSP brushes reached the window");
        Assert.True(summary.Meshes > 0, "no static meshes reached the window");
        Assert.True(summary.Lights > 0, "no lights reached the window");
        Assert.True(summary.Triangles > 10_000);

        // The composition list is what says a level is mostly not geometry.
        Assert.NotEmpty(model.LevelComposition);

        // The button is reachable, which is the half a service test cannot check.
        Assert.True(model.CanExtractLevel);

        // …and it is correctly disabled when neither format is chosen, rather than writing nothing.
        model.LevelExportSceneJson = false;
        model.LevelExportObj = false;
        Assert.False(model.CanExtractLevel);
        model.LevelExportSceneJson = true;
        Assert.True(model.CanExtractLevel);

        // The tab has to be the visible one or the snapshot shows the asset browser — which is how
        // the first capture of this test "passed" while showing nothing it was testing. Selected by
        // header rather than index, so adding a workspace does not silently point this at the
        // wrong tab: it already did once, when the browser split into Animated and Static.
        var tabs = window.GetVisualDescendants().OfType<TabControl>().First();
        int Index(string header) => tabs.Items
            .OfType<TabItem>()
            .Select((t, i) => (t, i))
            .First(x => (string?)x.t.Header == header).i;

        tabs.SelectedIndex = Index("Level");
        Pump(() => false, attempts: 10, delayMs: 20);

        Assert.Equal("Level", ((TabItem)tabs.SelectedItem!).Header);

        // The asset extraction bar must not be showing on the Level tab. It offers "Extract
        // selected" and "Extract all shown", which on this tab reads as though they extract the
        // level. Found by rendering the tab and looking at it; the numbers were all green.
        Assert.False(model.IsAssetsTab);
        tabs.SelectedIndex = Index("Animated");
        Assert.True(model.IsAssetsTab);
        tabs.SelectedIndex = Index("Level");

        // The empty-state prompt must be hidden once a map is chosen. It was bound with "!" on a
        // non-boolean, which does not negate, so it rendered on top of a fully-loaded level.
        var prompts = window.GetVisualDescendants().OfType<TextBlock>()
            .Where(t => t.Text is not null && t.Text.StartsWith("A level is its placed actors", StringComparison.Ordinal))
            .ToList();
        Assert.NotEmpty(prompts);
        Assert.All(prompts, t => Assert.False(t.IsVisible, "the empty-state prompt is showing while a map is selected"));

        if (Environment.GetEnvironmentVariable("BIOSHOCK_LEVELUI_SNAPSHOT") is { Length: > 0 } path)
        {
            Dispatcher.UIThread.RunJobs();
            window.CaptureRenderedFrame()?.Save(path);
        }
    }

    /// <summary>
    /// The size warning appears before a large export, not after it.
    /// </summary>
    /// <remarks>
    /// A level OBJ is over 100 MB. Bulk extraction size has already been reported as a fault in this
    /// project when it was really an unstated cost, so the estimate is shown up front — and it is
    /// asserted here because an estimate that never renders is the same as no estimate.
    /// </remarks>
    [AvaloniaFact]
    public void ALargeLevelWarnsAboutItsSizeBeforeExtracting()
    {
        var model = new MainViewModel();
        var window = new MainWindow { DataContext = model, Width = 1280, Height = 820 };
        window.Show();

        Pump(() => model.HasInstall);
        if (!model.HasInstall) return;

        model.SelectedLevel = model.Levels.First(l => l.Name == "0-Lighthouse");
        Pump(() => model.LevelSummary is not null && !model.IsLevelBusy);

        Assert.False(string.IsNullOrWhiteSpace(model.LevelSizeWarning));
        Assert.Contains("MB", model.LevelSizeWarning);
    }
}
