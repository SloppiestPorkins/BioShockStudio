using System;
using System.Collections.Generic;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Threading;
using BioShockStudio.App.ViewModels;

namespace BioShockStudio.App.Views;

/// <summary>
/// The ghost camera's controls: keys to move, the pointer to look.
/// </summary>
/// <remarks>
/// <para>
/// <b>Movement is driven by a timer over a held-key set, not by key-repeat.</b> Key-repeat is a
/// text-entry feature: it delivers one event, pauses for the platform's repeat delay, then fires at
/// the platform's repeat rate — so holding W stutters and two keys at once move in steps rather
/// than diagonally. Tracking which keys are down and stepping the camera on a timer is what makes
/// it feel like flying.
/// </para>
/// <para>
/// The step is scaled by real elapsed time rather than assuming the timer fired on schedule,
/// because the frame it triggers takes tens to hundreds of milliseconds on the CPU rasteriser and
/// the timer will not keep up. Without that, movement speed would depend on how much of the level
/// is on screen.
/// </para>
/// </remarks>
public partial class MainWindow
{
    private readonly HashSet<Key> _levelKeys = [];
    private DispatcherTimer? _levelTimer;
    private DateTime _lastStep = DateTime.UtcNow;
    private Point? _lookFrom;

    private MainViewModel? Model => DataContext as MainViewModel;

    private void HookLevelCamera()
    {
        var surface = this.FindControl<Border>("LevelSurface");
        if (surface is null) return;

        HookGpu();

        // Clicking the surface takes focus so the movement keys arrive, and starts the look drag.
        surface.PointerPressed += (_, e) =>
        {
            surface.Focus();
            _lookFrom = e.GetPosition(surface);
            e.Pointer.Capture(surface);
        };

        surface.PointerMoved += (_, e) =>
        {
            if (_lookFrom is not { } from || Model is not { HasLevelView: true } model) return;

            var to = e.GetPosition(surface);
            _lookFrom = to;

            // Dragging right looks right. The camera's yaw increases anticlockwise in the studio's
            // right-handed basis, so the horizontal delta is negated; getting this wrong inverts the
            // mouse and reads as a bug rather than a convention.
            const float sensitivity = 0.005f;
            model.LookLevelCamera((float)(from.X - to.X) * sensitivity, (float)(to.Y - from.Y) * sensitivity);
        };

        surface.PointerReleased += (_, e) =>
        {
            _lookFrom = null;
            e.Pointer.Capture(null);
            Model?.SettleLevelCamera();
        };

        // The wheel is speed, not zoom: a free camera has no distance to zoom.
        surface.PointerWheelChanged += (_, e) =>
        {
            if (Model is not { HasLevelView: true } model) return;
            model.LevelCameraSpeed = Math.Clamp(model.LevelCameraSpeed * (e.Delta.Y > 0 ? 1.25 : 0.8), 0.05, 20);
        };

        surface.KeyDown += (_, e) =>
        {
            if (Model is not { HasLevelView: true }) return;
            if (!IsMovementKey(e.Key)) return;
            _levelKeys.Add(e.Key);
            e.Handled = true;
            Start();
        };

        surface.KeyUp += (_, e) =>
        {
            if (!_levelKeys.Remove(e.Key)) return;
            e.Handled = true;
            if (_levelKeys.Count == 0)
            {
                Stop();
                Model?.SettleLevelCamera();
            }
        };

        // Losing focus must release every key, or a key held while alt-tabbing leaves the camera
        // flying away with nothing to stop it.
        surface.LostFocus += (_, _) =>
        {
            _levelKeys.Clear();
            Stop();
        };

        surface.SizeChanged += (_, e) =>
        {
            if (Model is not { } model) return;
            model.LevelViewWidth = Math.Max(64, (int)e.NewSize.Width);
            model.LevelViewHeight = Math.Max(64, (int)e.NewSize.Height);
            if (model.HasLevelView) model.SettleLevelCamera();
        };
    }

    /// <summary>
    /// Connects the GPU viewport, and decides whether it can be used at all.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Whether a GPU is available is a fact about the platform, so the view decides it and tells
    /// the view model</b> — the view model has no business asking. The GL control reports a reason
    /// in <c>Failed</c> if the context, the shaders or the upload go wrong, and the window falls
    /// back to the software rasteriser and <i>says</i> that it did. A viewport that silently becomes
    /// twenty times slower reads as a broken feature.
    /// </para>
    /// <para>
    /// The check is deferred rather than made up front: <c>OnOpenGlInit</c> does not run until the
    /// control has been rendered once, so asking before that would always report failure.
    /// </para>
    /// </remarks>
    private void HookGpu()
    {
        var gl = this.FindControl<LevelGlViewport>("LevelGl");
        if (gl is null) return;

        DataContextChanged += (_, _) =>
        {
            if (DataContext is not MainViewModel model) return;

            model.LevelOpened += (level, camera) =>
            {
                gl.TriangleBudget = Math.Max(model.LevelTriangleBudget * 8, 1_500_000);
                gl.Filter = model.ViewFilter;
                gl.Show(level, camera);
                Dispatcher.UIThread.Post(() => Confirm(model, gl), DispatcherPriority.Background);
            };

            // The GL control owns its draw selection after the initial Show call. Updating only
            // the bound view-model value left Detail's thumb moving while the displayed geometry
            // remained at the old budget, which made omitted exterior assemblies look broken.
            model.LevelTriangleBudgetChanged += budget =>
                gl.TriangleBudget = Math.Max(budget * 8, 1_500_000);

            model.CameraMoved += camera => { gl.Filter = model.ViewFilter; gl.Move(camera); };
            model.LevelClosed += () => { gl.Clear(); model.UsingGpu = false; };
        };
    }

    /// <summary>
    /// Settles whether the GPU actually drew, once it has had a chance to.
    /// </summary>
    /// <remarks>
    /// Runs a beat after the level opens, by which time the control has been asked for a frame. If
    /// the GL path reported a fault the software renderer stays in charge and the status line
    /// carries the reason, so the slowdown is explained rather than mysterious.
    /// </remarks>
    private static void Confirm(MainViewModel model, LevelGlViewport gl)
    {
        if (gl.Failed is { } reason)
        {
            model.UsingGpu = false;
            model.LevelViewStatus = $"Drawing on the CPU — the GPU path could not start: {reason}";
            return;
        }

        model.UsingGpu = true;
    }

    private static bool IsMovementKey(Key key) => key
        is Key.W or Key.A or Key.S or Key.D or Key.Q or Key.E
        or Key.Up or Key.Down or Key.Left or Key.Right;

    private void Start()
    {
        if (_levelTimer is not null) return;

        _lastStep = DateTime.UtcNow;
        _levelTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(30) };
        _levelTimer.Tick += (_, _) => Step();
        _levelTimer.Start();
    }

    private void Stop()
    {
        _levelTimer?.Stop();
        _levelTimer = null;
    }

    private void Step()
    {
        if (Model is not { HasLevelView: true } model) { Stop(); return; }

        var now = DateTime.UtcNow;
        // Clamped: a frame that took a second should not teleport the camera a second's worth.
        float seconds = (float)Math.Clamp((now - _lastStep).TotalSeconds, 0, 0.1);
        _lastStep = now;

        float forward = Held(Key.W, Key.Up) - Held(Key.S, Key.Down);
        float right = Held(Key.D, Key.Right) - Held(Key.A, Key.Left);
        float up = Held(Key.E) - Held(Key.Q);

        if (forward == 0 && right == 0 && up == 0) return;

        model.MoveLevelCamera(forward, right, up, seconds);
    }

    private float Held(params Key[] keys)
    {
        foreach (var key in keys) if (_levelKeys.Contains(key)) return 1f;
        return 0f;
    }
}
