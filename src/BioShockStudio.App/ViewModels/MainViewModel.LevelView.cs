using System;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using Avalonia;
using Avalonia.Media.Imaging;
using Avalonia.Platform;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace BioShockStudio.App.ViewModels;

/// <summary>
/// The level viewport: walking through a map with a ghost camera.
/// </summary>
/// <remarks>
/// <para>
/// <b>The frame budget is the design, and it came from measurement.</b> Drawing all of
/// <c>0-Lighthouse</c> on the CPU rasteriser takes about 1.6 seconds; frustum culling alone reaches
/// 1.15 s, because Rapture's backdrop city is entirely in view and is most of the map's geometry.
/// What actually bounds a frame is <b>pixels</b>: 100,000 triangles cost 423 ms at 960×600 and
/// 147 ms at 480×300. So the viewport spends a triangle budget on whatever occupies the most
/// screen, <i>and</i> drops resolution while the camera is moving, restoring it when you stop.
/// <c>LevelViewportPerformanceTests</c> holds the measurements.
/// </para>
/// <para>
/// <b>It says what it left out.</b> A viewport that quietly drops geometry to keep up is showing a
/// partial level and claiming a whole one, which is the shape of mistake this project keeps
/// correcting. The status line reports the instances drawn and the number dropped.
/// </para>
/// </remarks>
public partial class MainViewModel
{
    private readonly LevelViewportService _levelViewport = new(new AssetCatalogService());

    private PreparedLevel? _prepared;
    private CancellationTokenSource? _viewWork;
    private readonly SemaphoreSlim _renderLock = new(1, 1);
    private bool _levelRenderQueued;

    [ObservableProperty] private WriteableBitmap? _levelImage;
    [ObservableProperty] private bool _isLevelViewLoading;
    [ObservableProperty] private string _levelViewStatus = "";
    [ObservableProperty] private bool _hasLevelView;

    /// <summary>
    /// How much geometry a frame may draw. Exposed because the right value depends on the machine,
    /// and a fixed one would be a guess about someone else's CPU.
    /// </summary>
    [ObservableProperty] private int _levelTriangleBudget = 150_000;

    /// <summary>Movement multiplier, so a map can be crossed without waiting.</summary>
    [ObservableProperty] private double _levelCameraSpeed = 1.0;

    private GhostCamera _levelCamera = new();

    /// <summary>
    /// Whether the GPU is drawing the level.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Set by the view once it knows whether a GL context came up, because whether a GPU is
    /// available is a fact about the platform and the view model has no business asking.
    /// </para>
    /// <para>
    /// When this is false the software rasteriser draws instead, at roughly half a frame a second
    /// on a whole map — so the fallback is <b>reported</b> rather than merely taken. A viewport that
    /// silently becomes twenty times slower reads as a broken feature.
    /// </para>
    /// </remarks>
    [ObservableProperty] private bool _usingGpu;

    /// <summary>Raised when the camera moves, so the view can ask the GPU for a frame.</summary>
    public event Action<GhostCamera>? CameraMoved;

    /// <summary>Raised when a level is ready, so the view can hand it to the GPU.</summary>
    public event Action<PreparedLevel, GhostCamera>? LevelOpened;

    /// <summary>Raised when the level is closed, so the view can release its GPU resources.</summary>
    public event Action? LevelClosed;

    /// <summary>Set by the view: the size of the viewport surface, in pixels.</summary>
    public int LevelViewWidth { get; set; } = 960;
    public int LevelViewHeight { get; set; } = 600;

    public GhostCamera Camera => _levelCamera;

    /// <summary>
    /// Loads the selected map for walking through.
    /// </summary>
    /// <remarks>
    /// Separate from selecting a map on purpose. Preparing a level decodes every mesh, material and
    /// texture it uses and takes about five seconds; doing that on selection would make simply
    /// browsing the map list feel broken.
    /// </remarks>
    [RelayCommand]
    private async Task OpenLevelViewAsync()
    {
        if (SelectedLevel is not { } level) return;

        _viewWork?.Cancel();
        _viewWork = new CancellationTokenSource();
        var token = _viewWork.Token;

        IsLevelViewLoading = true;
        HasLevelView = false;
        LevelViewStatus = $"Opening {level.Name}…";

        try
        {
            var progress = new Progress<string>(text => LevelViewStatus = $"{level.Name}: {text}");
            var prepared = await Task.Run(() => _levelViewport.Prepare(level.File, progress), token);
            if (token.IsCancellationRequested) return;

            _prepared = prepared;
            _levelCamera = prepared.Start;
            HasLevelView = true;
            LevelViewStatus = $"{level.Name}: {prepared.TextureSummary}.";

            LevelOpened?.Invoke(prepared, _levelCamera);

            // The software path still draws the first frame even on the GPU, so that a GL context
            // that comes up and then fails leaves a picture rather than a black rectangle.
            await RenderAsync(moving: false);
        }
        catch (OperationCanceledException)
        {
            LevelViewStatus = "Cancelled.";
        }
        catch (Exception ex)
        {
            LevelViewStatus = $"{level.Name} could not be opened: {ex.Message}";
        }
        finally
        {
            IsLevelViewLoading = false;
        }
    }

    /// <summary>Closes the walkthrough and returns to the level's summary.</summary>
    /// <remarks>
    /// The prepared level is dropped with it. A map's decoded geometry and textures are hundreds of
    /// megabytes, and holding several at once after browsing a few maps is how a tool starts being
    /// described as a memory leak.
    /// </remarks>
    [RelayCommand]
    private void CloseLevelView()
    {
        _viewWork?.Cancel();
        HasLevelView = false;
        _prepared = null;
        LevelImage = null;
        LevelViewStatus = "";
        LevelClosed?.Invoke();
    }

    /// <summary>Turns the camera, in radians.</summary>
    public void LookLevelCamera(float deltaYaw, float deltaPitch)
    {
        if (!HasLevelView) return;
        _levelCamera = _levelCamera.Look(deltaYaw, deltaPitch);
        Invalidate(moving: true);
    }

    /// <summary>Moves the camera. Each axis is -1, 0 or 1.</summary>
    public void MoveLevelCamera(float forward, float right, float up, float seconds)
    {
        if (!HasLevelView) return;
        _levelCamera = _levelCamera.Move(forward, right, up, seconds, (float)LevelCameraSpeed);
        Invalidate(moving: true);
    }

    /// <summary>Redraws at full quality — called when the camera stops.</summary>
    public void SettleLevelCamera() => Invalidate(moving: false);

    /// <summary>
    /// Requests a frame, coalescing requests that arrive while one is being drawn.
    /// </summary>
    /// <remarks>
    /// Input arrives far faster than a CPU frame takes, so without coalescing every keystroke would
    /// queue a render and the camera would keep drawing frames long after the user stopped moving.
    /// One frame in flight, one queued, the rest discarded.
    /// </remarks>
    private void Invalidate(bool moving)
    {
        // On the GPU the camera is all the view needs: the geometry is already uploaded, so a frame
        // is a draw call rather than a re-render, and none of the coalescing below applies.
        if (UsingGpu)
        {
            CameraMoved?.Invoke(_levelCamera);
            return;
        }

        if (_levelRenderQueued) return;
        _levelRenderQueued = true;
        _ = RenderAsync(moving);
    }

    private async Task RenderAsync(bool moving)
    {
        if (_prepared is not { } prepared) { _levelRenderQueued = false; return; }

        await _renderLock.WaitAsync();
        try
        {
            _levelRenderQueued = false;

            // While moving, draw at half resolution and a smaller budget. Measured, this is roughly
            // a third of the cost — the frame is bounded by pixels, not by triangles.
            int width = Math.Max(64, moving ? LevelViewWidth / 2 : LevelViewWidth);
            int height = Math.Max(64, moving ? LevelViewHeight / 2 : LevelViewHeight);
            int budget = moving ? LevelTriangleBudget / 2 : LevelTriangleBudget;

            var camera = _levelCamera;
            var timer = Stopwatch.StartNew();

            var (image, selection) = await Task.Run(() =>
            {
                var chosen = prepared.Viewport.Select(camera, (float)width / height, budget);
                var rendered = SoftwareRenderer.Render(
                    chosen.Instances,
                    camera.ToPreviewCamera(),
                    new RenderOptions { ShowSkeleton = false, ShowSockets = false, Textured = true },
                    width, height);
                return (rendered, chosen);
            });

            timer.Stop();

            LevelImage = LevelToBitmap(image);
            LevelViewStatus =
                $"{selection.Instances.Count:N0} drawn · {selection.Triangles:N0} triangles · "
                + $"{timer.ElapsedMilliseconds} ms"
                + (selection.Dropped > 0 ? $" · {selection.Dropped:N0} beyond the budget, not drawn" : "");
        }
        catch (Exception ex)
        {
            LevelViewStatus = $"The view could not be drawn: {ex.Message}";
        }
        finally
        {
            _renderLock.Release();
        }
    }

    private static WriteableBitmap LevelToBitmap(PreviewImage image)
    {
        var bitmap = new WriteableBitmap(
            new PixelSize(image.Width, image.Height), new Vector(96, 96),
            PixelFormat.Rgba8888, AlphaFormat.Premul);

        using var buffer = bitmap.Lock();
        System.Runtime.InteropServices.Marshal.Copy(image.Rgba, 0, buffer.Address, image.Rgba.Length);
        return bitmap;
    }
}
