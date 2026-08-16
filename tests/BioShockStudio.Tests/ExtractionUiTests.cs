using System.Linq;
using System.Threading.Tasks;
using Avalonia.Headless.XUnit;
using Avalonia.Threading;
using BioShockStudio.App.ViewModels;
using BioShockStudio.Core.Game;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Extraction driven the way the window drives it, rather than the way a service test does.
/// </summary>
/// <remarks>
/// The service tests prove the pipeline writes files. They cannot prove the button reaches it: this
/// project has shipped three features that were implemented, tested and invisible, and a command
/// that never runs looks exactly like a broken extractor.
/// </remarks>
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ExtractionUiTests
{
    /// <summary>Pumps the dispatcher until a condition holds, so a fire-and-forget task can finish.</summary>
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

    /// <summary>
    /// "Extract all shown" must actually write something. Drives the real command on the real view
    /// model with the real catalogue.
    /// </summary>
    [AvaloniaFact]
    public async Task ExtractShown_WritesFiles()
    {
        if (GameLocator.Find() is null) return;

        var model = new MainViewModel();

        // The constructor kicks off discovery and the catalogue build without awaiting it.
        Assert.True(await WaitFor(() => model.HasInstall && model.TotalCount > 0),
            $"the catalogue never loaded (status: {model.Status})");
        Assert.True(await WaitFor(() => !model.IsBusy), "the view model never stopped being busy");

        // A small, fast slice: one package's textures. Textures live in the Static workspace, and
        // the browser opens on Animated — so the workspace has to be switched before the category
        // exists to select. This test used to pick it straight out of a single flat category list.
        model.SelectedTabIndex = (int)AssetWorkspace.Static;
        Assert.True(await WaitFor(() => model.Categories.Any(c => c.Category == Core.Services.AssetCategory.Textures)),
            "the Static workspace never listed a Textures category");

        model.SelectedCategory = model.Categories.First(c => c.Category == Core.Services.AssetCategory.Textures);
        model.SelectedPackage = "0-Lighthouse";
        Assert.True(await WaitFor(() => model.Assets.Count > 0), "no assets shown to extract");

        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-ui-extract-{Guid.NewGuid():N}");
        model.OutputDirectory = directory;
        model.ExportPng = true;
        model.ExportSceneJson = false;
        model.ExportFbx = false;
        model.ExportDds = false;

        try
        {
            Assert.True(model.ExtractShownCommand.CanExecute(null),
                $"the Extract all shown button is disabled (IsBusy={model.IsBusy})");

            await model.ExtractShownCommand.ExecuteAsync(null);
            await WaitFor(() => !model.IsBusy);

            string diagnostic =
                $"status='{model.Status}' shown={model.Assets.Count} total={model.TotalCount} "
                + $"busy={model.IsBusy} png={model.ExportPng} json={model.ExportSceneJson} "
                + $"fbx={model.ExportFbx} dds={model.ExportDds} out='{model.OutputDirectory}' "
                + $"failures=[{string.Join(" | ", model.Failures.Select(f => f.Name + ": " + f.Reason))}] "
                + $"exists={Directory.Exists(directory)} "
                + $"files={(Directory.Exists(directory) ? Directory.GetFiles(directory, "*", SearchOption.AllDirectories).Length : -1)} "
                + $"firstAssets=[{string.Join(", ", model.Assets.Take(4).Select(a => a.Category + "/" + a.Name + "/" + a.Package))}]";

            Assert.True(Directory.Exists(directory), diagnostic);
            Assert.True(Directory.GetFiles(directory, "*.png", SearchOption.AllDirectories).Length > 0, diagnostic);
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }
}
