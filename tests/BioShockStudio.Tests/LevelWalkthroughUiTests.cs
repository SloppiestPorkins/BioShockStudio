using System.Linq;
using System.Numerics;
using System.Threading;
using Avalonia.Controls;
using Avalonia.Headless;
using Avalonia.Headless.XUnit;
using Avalonia.Media.Imaging;
using Avalonia.Threading;
using Avalonia.VisualTree;
using BioShockStudio.App.ViewModels;
using BioShockStudio.App.Views;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Walking through a level in the window.
/// </summary>
/// <remarks>
/// Driven through the real view model, because a service test can prove the renderer works and
/// still leave a button that never reaches it — which this project has shipped before.
/// </remarks>
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LevelWalkthroughUiTests
{
    private static void Pump(Func<bool> until, int attempts = 900, int delayMs = 50)
    {
        for (int i = 0; i < attempts && !until(); i++)
        {
            Dispatcher.UIThread.RunJobs();
            Thread.Sleep(delayMs);
        }
        Dispatcher.UIThread.RunJobs();
    }

    private static (MainViewModel Model, MainWindow Window)? Open()
    {
        var model = new MainViewModel();
        var window = new MainWindow { DataContext = model, Width = 1400, Height = 900 };
        window.Show();

        Pump(() => model.HasInstall);
        if (!model.HasInstall) return null;

        var tabs = window.GetVisualDescendants().OfType<TabControl>().First();
        tabs.SelectedIndex = tabs.Items.OfType<TabItem>()
            .Select((t, i) => (t, i)).First(x => (string?)x.t.Header == "Level").i;

        model.SelectedLevel = model.Levels.First(l => l.Name == "0-Lighthouse");
        Pump(() => model.LevelSummary is not null && !model.IsLevelBusy);

        return (model, window);
    }

    [AvaloniaFact]
    public void TheLevelCanBeOpenedAndFlownThrough()
    {
        if (Open() is not var (model, window)) return;

        // Opening the walkthrough is a separate action from selecting the map: it decodes every
        // mesh, material and texture and takes seconds.
        Assert.False(model.HasLevelView);
        model.OpenLevelViewCommand.Execute(null);
        Pump(() => model.HasLevelView && model.LevelImage is not null && !model.IsLevelViewLoading);

        Assert.True(model.HasLevelView, $"the level view did not open: {model.LevelViewStatus}");
        Assert.NotNull(model.LevelImage);

        var start = model.Camera.Position;

        // Moving forward moves the camera along its own heading, not along a world axis.
        model.MoveLevelCamera(1, 0, 0, 0.5f);
        Pump(() => model.Camera.Position != start, attempts: 20);

        var moved = model.Camera.Position;
        Assert.NotEqual(start, moved);

        var travelled = moved - start;
        var heading = model.Camera.Forward;
        Assert.True(Vector3.Dot(Vector3.Normalize(travelled), heading) > 0.99f,
            "moving forward did not move the camera along the direction it is facing");

        // Looking changes the heading, and pitch is clamped short of the poles so the view cannot
        // invert — a free camera that can look past straight up tumbles.
        float yaw = model.Camera.Yaw;
        model.LookLevelCamera(0.4f, 0.2f);
        Assert.NotEqual(yaw, model.Camera.Yaw);

        for (int i = 0; i < 50; i++) model.LookLevelCamera(0, 1f);
        Assert.True(model.Camera.Pitch < 1.6f, "pitch is not clamped; the camera can tumble past vertical");

        // Strafing right and left are opposites, and neither is the forward axis.
        var before = model.Camera.Position;
        model.MoveLevelCamera(0, 1, 0, 0.5f);
        var right = model.Camera.Position - before;
        model.MoveLevelCamera(0, -1, 0, 0.5f);
        Assert.True(Vector3.Distance(model.Camera.Position, before) < 1f,
            "strafing right then left did not return the camera to where it started");
        Assert.True(MathF.Abs(Vector3.Dot(Vector3.Normalize(right), model.Camera.Forward)) < 0.01f,
            "strafing moves the camera along its own forward axis");

        Pump(() => !model.IsLevelViewLoading, attempts: 60);

        if (Environment.GetEnvironmentVariable("BIOSHOCK_WALK_SNAPSHOT") is { Length: > 0 } path)
        {
            Dispatcher.UIThread.RunJobs();
            window.CaptureRenderedFrame()?.Save(path);
        }

        // Closing releases the level. A map's decoded geometry and textures are hundreds of
        // megabytes and holding several would read as a leak.
        model.CloseLevelViewCommand.Execute(null);
        Assert.False(model.HasLevelView);
        Assert.Null(model.LevelImage);
    }

    /// <summary>
    /// The viewport reports what it did not draw.
    /// </summary>
    /// <remarks>
    /// The budget means a busy view is deliberately incomplete. A viewport that drops geometry
    /// silently is showing a partial level while implying a whole one, which is the exact shape of
    /// mistake this project keeps having to correct.
    /// </remarks>
    [AvaloniaFact]
    public void TheViewportSaysWhatItLeftOut()
    {
        if (Open() is not var (model, _)) return;

        model.LevelTriangleBudget = 25_000;
        model.OpenLevelViewCommand.Execute(null);
        Pump(() => model.HasLevelView && model.LevelImage is not null && !model.IsLevelViewLoading);
        if (!model.HasLevelView) return;

        model.SettleLevelCamera();
        Pump(() => model.LevelViewStatus.Contains("triangles", StringComparison.Ordinal), attempts: 120);

        Assert.Contains("drawn", model.LevelViewStatus, StringComparison.Ordinal);
        Assert.Contains("triangles", model.LevelViewStatus, StringComparison.Ordinal);
        Assert.Contains("not drawn", model.LevelViewStatus, StringComparison.Ordinal);
    }
}
