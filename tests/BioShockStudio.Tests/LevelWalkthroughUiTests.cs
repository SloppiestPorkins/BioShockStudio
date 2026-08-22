using System;
using System.IO;
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
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
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

    /// <summary>
    /// The camera's position readout: present, updating, and in the <b>game's</b> coordinates.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Added so a user reporting a misplaced asset can say exactly where they are standing rather
    /// than describing the room. That is only useful if the numbers are the ones an actor's
    /// <c>Location</c> is written in — the viewport works in the studio basis, whose Y is the
    /// negation of the game's (<c>C = diag(1,-1,1)</c>), so a readout that forgot the conversion
    /// would look entirely plausible while naming the mirror image of the right place.
    /// </para>
    /// <para>
    /// <b>Asserted against a real actor, not against the conversion function.</b> Comparing
    /// <c>Convert(Convert(x))</c> to <c>x</c> would pass with the conversion missing from the view
    /// model entirely. This drives the camera to a shipped actor's stated <c>Location</c> and
    /// requires the readout to report that actor's own numbers back.
    /// </para>
    /// </remarks>
    /// <summary>
    /// The viewport says what the level holds, including the categories it cannot draw.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Gate 0 item 4's second clause: "non-drawable actor classes should be listed explicitly, not
    /// silently absent". The toggles cover every drawable category, but a level is mostly things the
    /// viewport never places — lights, zones, navigation nodes, sound actors, script graphs — and a
    /// picture cannot distinguish "this map has none" from "these are never drawn".
    /// </para>
    /// <para>
    /// <b>Asserts the not-drawn half specifically.</b> A ledger that listed only the geometry would
    /// satisfy a count-based check while omitting the entire point of the feature.
    /// </para>
    /// </remarks>
    [AvaloniaFact]
    public void TheViewportListsWhatItCannotDraw()
    {
        if (Open() is not var (model, window)) return;

        model.OpenLevelViewCommand.Execute(null);
        Pump(() => model.HasLevelView && model.LevelImage is not null && !model.IsLevelViewLoading);
        if (!model.HasLevelView) return;

        Assert.NotEmpty(model.LevelContents);

        string all = string.Join(Environment.NewLine, model.LevelContents);
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } probe)
            File.AppendAllText(probe, all + Environment.NewLine);

        // Coverage before findings: the total has to be stated, or a short list reads as a small level.
        Assert.Contains("actors", all);
        Assert.Contains("classes", all);

        // The half that matters. 0-Lighthouse carries lights and a navigation graph, neither drawn.
        Assert.Contains("not drawn", all);

        var notDrawn = model.LevelContents.Where(line => line.Contains("not drawn")).ToList();
        Assert.True(notDrawn.Count >= 2,
            "only " + notDrawn.Count + " undrawn categories listed: " + Environment.NewLine + all);

        // Each line names actual classes, so "not drawn - lights" can be acted on rather than
        // merely noted.
        Assert.All(notDrawn, line => Assert.Contains("(", line));

        window.Close();
    }

    [AvaloniaFact]
    public void TheCameraPositionIsReportedInTheGamesOwnCoordinates()
    {
        if (Open() is not var (model, window)) return;

        model.OpenLevelViewCommand.Execute(null);
        Pump(() => model.HasLevelView && model.LevelImage is not null && !model.IsLevelViewLoading);
        if (!model.HasLevelView) return;

        Assert.False(string.IsNullOrWhiteSpace(model.LevelLocation),
            "the level view opened but reports no camera position");

        // A real actor from the map being viewed, and its stated Location in the game's basis —
        // read from the package rather than from anything the view model derived.
        string root = GameLocator.Find()!;
        using var package = BioShockPackage.Open(
            System.IO.Path.Combine(GameLocator.MapsDirectory(root), "0-Lighthouse.bsm"));
        var stated = LevelAnalyzer.Analyze(package).Actors
            .First(a => a.Transform.Location != Vector3.Zero
                        && MathF.Abs(a.Transform.Location.Y) > 100f).Transform.Location;

        // Put the camera exactly there, in the basis the viewport works in.
        model.PlaceLevelCameraAt(GameBasis.Convert(stated));
        Pump(() => model.LevelLocation.Contains(((int)MathF.Round(stated.X)).ToString()), attempts: 20);

        // The readout must name the actor's own coordinates back.
        foreach (float component in new float[] { stated.X, stated.Y, stated.Z })
        {
            string expected = ((int)MathF.Round(component)).ToString();
            Assert.Contains(expected, model.LevelLocation);
        }

        window.Close();
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
