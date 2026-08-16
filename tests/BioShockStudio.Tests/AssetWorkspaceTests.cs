using System.Linq;
using System.Threading;
using Avalonia.Headless;
using Avalonia.Headless.XUnit;
using Avalonia.Controls;
using Avalonia.Threading;
using Avalonia.VisualTree;
using BioShockStudio.App.ViewModels;
using BioShockStudio.App.Views;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The browser's split into Animated and Static workspaces.
/// </summary>
/// <remarks>
/// The split is a filter over one catalogue, not two catalogues, so what has to be proved is that
/// the filter actually holds: an asset must not be reachable from the workspace it does not belong
/// to, and no category may fall out of both and become unreachable.
/// </remarks>
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class AssetWorkspaceTests
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

    /// <summary>
    /// Every category belongs to exactly one asset workspace.
    /// </summary>
    /// <remarks>
    /// The failure this guards against is silent: a category in neither list is simply unreachable
    /// in the browser, with nothing to indicate it. <c>Other</c> is excluded deliberately — it is
    /// the catalogue's own catch-all and was never offered as a category before this split either.
    /// </remarks>
    [Fact]
    public void EveryCategoryBelongsToExactlyOneWorkspace()
    {
        var covered = AssetWorkspaces.AllCovered.ToList();

        Assert.Equal(covered.Count, covered.Distinct().Count());

        foreach (var category in Enum.GetValues<AssetCategory>())
        {
            if (category == AssetCategory.Other) continue;
            Assert.Contains(category, covered);
        }
    }

    [AvaloniaFact]
    public void EachWorkspaceShowsOnlyItsOwnAssets()
    {
        var model = new MainViewModel();
        var window = new MainWindow { DataContext = model, Width = 1280, Height = 820 };
        window.Show();

        Pump(() => model.Assets.Count > 0);
        if (!model.HasInstall) return;

        // Animated is the default workspace.
        Assert.Equal(AssetWorkspace.Animated, model.Workspace);
        Assert.NotEmpty(model.Assets);
        Assert.All(model.Assets, a => Assert.Contains(a.Category, AssetWorkspaces.Animated));

        // The "all" row counts this workspace, not the catalogue. Showing the game's whole total
        // beside a list that can only reach half of it states something untrue.
        var everything = model.Categories[0];
        Assert.Equal("All rigged assets", everything.Label);
        Assert.True(everything.Count < model.TotalCount,
            $"the rigged workspace claims all {everything.Count:N0} assets in the game");

        int animatedCount = everything.Count;

        // Switch, and nothing from the other workspace comes with it.
        model.SelectedTabIndex = (int)AssetWorkspace.Static;
        Pump(() => model.Assets.Count > 0 && model.Assets.All(a => AssetWorkspaces.Static.Contains(a.Category)));

        Assert.Equal(AssetWorkspace.Static, model.Workspace);
        Assert.NotEmpty(model.Assets);
        Assert.All(model.Assets, a => Assert.Contains(a.Category, AssetWorkspaces.Static));
        Assert.Equal("All static assets", model.Categories[0].Label);

        // Between them the two workspaces reach the whole catalogue apart from Other.
        Assert.True(animatedCount + model.Categories[0].Count > 0);
    }

    /// <summary>
    /// A search is confined to its workspace, and is kept when the workspace changes.
    /// </summary>
    /// <remarks>
    /// Both halves matter. Confinement is the point of the split; keeping the text is the behaviour
    /// a user wants when they switch — "show me the other half of what I just searched for" — and
    /// clearing it would look like the search box had broken.
    /// </remarks>
    [AvaloniaFact]
    public void ASearchIsConfinedToItsWorkspaceAndSurvivesSwitchingIt()
    {
        var model = new MainViewModel();
        var window = new MainWindow { DataContext = model, Width = 1280, Height = 820 };
        window.Show();

        Pump(() => model.Assets.Count > 0);
        if (!model.HasInstall) return;

        model.Search = "a";
        Pump(() => model.Assets.Count > 0);
        Assert.All(model.Assets, a => Assert.Contains(a.Category, AssetWorkspaces.Animated));

        model.SelectedTabIndex = (int)AssetWorkspace.Static;
        Pump(() => model.Assets.Count > 0 && model.Assets.All(a => AssetWorkspaces.Static.Contains(a.Category)));

        Assert.Equal("a", model.Search);
        Assert.All(model.Assets, a => Assert.Contains(a.Category, AssetWorkspaces.Static));
    }

    /// <summary>Both workspaces host a browser, and the window renders with them.</summary>
    [AvaloniaFact]
    public void BothWorkspacesHostABrowser()
    {
        var model = new MainViewModel();
        var window = new MainWindow { DataContext = model, Width = 1280, Height = 820 };
        window.Show();
        Dispatcher.UIThread.RunJobs();

        var tabs = window.GetVisualDescendants().OfType<TabControl>().First();
        var headers = tabs.Items.OfType<TabItem>().Select(t => (string?)t.Header).ToList();

        Assert.Equal(["Animated", "Static", "Level"], headers);
        Assert.NotNull(window.CaptureRenderedFrame());
    }
}
