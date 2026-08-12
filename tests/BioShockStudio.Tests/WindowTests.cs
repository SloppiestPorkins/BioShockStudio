using Avalonia;
using Avalonia.Controls;
using Avalonia.Headless;
using Avalonia.Headless.XUnit;
using Avalonia.Media.Imaging;
using System.Linq;
using Avalonia.Threading;
using BioShockStudio.App.ViewModels;
using BioShockStudio.App.Views;
using BioShockStudio.Core.Services;
using Xunit;

[assembly: AvaloniaTestApplication(typeof(BioShockStudio.Tests.HeadlessApp))]

namespace BioShockStudio.Tests;

/// <summary>
/// Hosts the real application in a headless renderer.
/// </summary>
/// <remarks>
/// Skia is enabled rather than the headless stub so the window is genuinely laid out and drawn — a
/// binding that throws, a resource that does not resolve or a template that fails shows up here.
/// That is the whole point: the previous release crashed on a binding that only a real render would
/// have caught.
/// </remarks>
public sealed class HeadlessApp
{
    public static AppBuilder BuildAvaloniaApp() =>
        AppBuilder.Configure<App.App>()
            .UseSkia()
            .UseHeadless(new AvaloniaHeadlessPlatformOptions { UseHeadlessDrawing = false });
}

public sealed class WindowTests
{
    /// <summary>
    /// The window must build and render. Every binding is resolved during this, so a typo in the
    /// XAML fails here rather than on the user's machine.
    /// </summary>
    [AvaloniaFact]
    public void MainWindow_BuildsAndRenders()
    {
        var window = new MainWindow { DataContext = new MainViewModel() };
        window.Show();

        var frame = window.CaptureRenderedFrame();

        Assert.NotNull(frame);
        Assert.True(frame!.PixelSize.Width > 100);
        Assert.True(frame.PixelSize.Height > 100);
    }

    /// <summary>
    /// With no install chosen, the window must offer the discovery panel rather than an empty
    /// browser, and must not claim to have any assets.
    /// </summary>
    [AvaloniaFact]
    public void MainWindow_WithoutAnInstall_ShowsTheDiscoveryPanel()
    {
        var model = new MainViewModel();
        model.GamePath = System.IO.Path.GetTempPath();
        model.UseTypedPathCommand.Execute(null);

        var window = new MainWindow { DataContext = model };
        window.Show();

        Assert.False(model.HasInstall);
        Assert.NotEmpty(model.Checks);
        Assert.Contains(model.Checks, c => !c.Passed);
        Assert.Empty(model.Assets);

        Assert.NotNull(window.CaptureRenderedFrame());
    }

    /// <summary>Renders the window to a PNG so a human can look at the layout.</summary>
    /// <remarks>
    /// Off by default: it depends on the installed game and writes a file. Set
    /// <c>BIOSHOCK_UI_SNAPSHOT</c> to a path to produce one.
    /// </remarks>
    [AvaloniaFact]
    public void MainWindow_Snapshot()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_UI_SNAPSHOT");
        if (string.IsNullOrWhiteSpace(target)) return;

        var model = new MainViewModel();
        var window = new MainWindow { DataContext = model, Width = 1280, Height = 820 };
        window.Show();

        // The catalogue is built on a background thread; pump the UI until it lands so the snapshot
        // shows real data rather than an empty browser.
        for (int i = 0; i < 400 && model.Assets.Count == 0; i++)
        {
            Dispatcher.UIThread.RunJobs();
            Thread.Sleep(50);
        }

        // Select something so the snapshot exercises the details panel rather than the empty state.
        model.SelectedAsset = model.Assets.FirstOrDefault(a => a.Category == AssetCategory.FirstPerson)
                              ?? model.Assets.FirstOrDefault();

        for (int i = 0; i < 200 && (model.DetailFields.Count == 0 || model.Viewport is null); i++)
        {
            Dispatcher.UIThread.RunJobs();
            Thread.Sleep(50);
        }

        // Choose an animation so the transport and the posed model are both in the picture.
        model.ShowSockets = true;
        model.SelectedAnimation = model.PreviewAnimations.FirstOrDefault(a => a == "FastReloadPistol")
                                  ?? model.PreviewAnimations.FirstOrDefault();

        for (int i = 0; i < 200 && model.LastFrame == 0; i++)
        {
            Dispatcher.UIThread.RunJobs();
            Thread.Sleep(50);
        }

        // Attach the pistol so the snapshot shows the two-rig first-person set.
        for (int i = 0; i < 300 && model.Attachments.Count == 0; i++)
        {
            Dispatcher.UIThread.RunJobs();
            Thread.Sleep(50);
        }
        model.SelectedAttachment = model.Attachments.FirstOrDefault(a => a == "Pistol")
                                   ?? model.Attachments.FirstOrDefault();

        for (int i = 0; i < 200; i++)
        {
            Dispatcher.UIThread.RunJobs();
            Thread.Sleep(30);
        }

        model.Frame = model.LastFrame / 2;
        for (int i = 0; i < 60; i++)
        {
            Dispatcher.UIThread.RunJobs();
            Thread.Sleep(30);
        }
        window.CaptureRenderedFrame()?.Save(target);
        Assert.True(File.Exists(target));
    }
}
