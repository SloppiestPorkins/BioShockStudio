using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Avalonia.Media.Imaging;
using Avalonia.Threading;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace BioShockStudio.App.ViewModels;

/// <summary>
/// The 3D preview: an orbit viewport with animation playback.
/// </summary>
/// <remarks>
/// Drawing is done by <see cref="SoftwareRenderer"/> on a background thread and the finished image
/// is handed back to the UI. Frames are dropped rather than queued when a render overruns, so
/// dragging the camera stays responsive on a heavy mesh instead of building a backlog.
/// </remarks>
public partial class MainViewModel
{
    private PreviewModel? _previewModel;
    private PreviewAnimation? _animation;
    private PreviewCamera _camera = new();
    private DispatcherTimer? _playback;
    private CancellationTokenSource? _previewWork;
    private bool _rendering;
    private bool _renderQueued;

    [ObservableProperty] private Bitmap? _viewport;
    [ObservableProperty] private bool _hasViewport;
    [ObservableProperty] private string? _viewportProblem;
    [ObservableProperty] private int _viewportWidth = 420;
    [ObservableProperty] private int _viewportHeight = 300;

    [ObservableProperty] private bool _showTextures = true;
    [ObservableProperty] private bool _showWireframe;
    [ObservableProperty] private bool _showSkeleton;
    [ObservableProperty] private bool _showSockets;

    [ObservableProperty] private string? _selectedAnimation;
    [ObservableProperty] private bool _isPlaying;
    [ObservableProperty] private int _frame;
    [ObservableProperty] private int _lastFrame;
    [ObservableProperty] private double _playbackSpeed = 1.0;
    [ObservableProperty] private string _animationSummary = "";

    public ObservableCollection<string> PreviewAnimations { get; } = [];
    public ObservableCollection<double> PlaybackSpeeds { get; } = [0.25, 0.5, 1.0, 2.0];

    partial void OnShowTexturesChanged(bool value) => RequestRender();
    partial void OnShowWireframeChanged(bool value) => RequestRender();
    partial void OnShowSkeletonChanged(bool value) => RequestRender();
    partial void OnShowSocketsChanged(bool value) => RequestRender();
    partial void OnFrameChanged(int value) => RequestRender();
    partial void OnViewportWidthChanged(int value) => RequestRender();
    partial void OnViewportHeightChanged(int value) => RequestRender();
    partial void OnPlaybackSpeedChanged(double value) => RestartPlaybackTimer();

    partial void OnSelectedAnimationChanged(string? value) => _ = LoadAnimationAsync(value);

    /// <summary>Loads the model for a newly selected asset, or clears the viewport for one with none.</summary>
    private async Task LoadPreviewAsync(CatalogEntry? entry)
    {
        StopPlayback();
        _previewWork?.Cancel();

        _previewModel = null;
        _animation = null;
        Viewport = null;
        HasViewport = false;
        ViewportProblem = null;
        PreviewAnimations.Clear();
        SelectedAnimation = null;
        LastFrame = 0;
        Frame = 0;
        AnimationSummary = "";

        // Textures have their own preview; there is nothing to draw in 3D for a material either.
        if (entry is null || entry.Category is AssetCategory.Textures or AssetCategory.Materials) return;

        _previewWork = new CancellationTokenSource();
        var token = _previewWork.Token;

        try
        {
            var subject = await Task.Run(() => _preview.Load(entry, token), token);
            if (token.IsCancellationRequested) return;

            _previewModel = subject.Model;
            ViewportProblem = subject.Problem;
            HasViewport = subject.Model.HasGeometry || subject.Model.Bones.Count > 0;

            if (!HasViewport) return;

            _camera = PreviewCamera.Frame(subject.Model);
            ShowSkeleton = !subject.Model.HasGeometry;

            foreach (string name in subject.Animations) PreviewAnimations.Add(name);
            RequestRender();
        }
        catch (OperationCanceledException)
        {
            // Superseded by a newer selection.
        }
        catch (Exception ex)
        {
            ViewportProblem = ex.Message;
        }
    }

    private async Task LoadAnimationAsync(string? name)
    {
        StopPlayback();
        _animation = null;
        LastFrame = 0;
        Frame = 0;
        AnimationSummary = "";

        if (name is null || SelectedAsset is null || _previewModel is null)
        {
            RequestRender();
            return;
        }

        var entry = SelectedAsset;
        var model = _previewModel;

        try
        {
            var animation = await Task.Run(() => _preview.LoadAnimation(entry, name));
            if (animation is null || !ReferenceEquals(model, _previewModel)) return;

            _animation = animation;
            LastFrame = Math.Max(0, animation.FrameCount - 1);
            Frame = 0;
            AnimationSummary =
                $"{animation.FrameCount} frames · {animation.Duration:0.00}s · {animation.FrameRate:0.##} fps";

            // Framed over the whole animation so the subject never leaves the view mid-playback.
            var (centre, radius) = model.BoundsOver(model.SamplePoses(animation.Decoded));
            _camera = _camera with { Target = centre, Distance = Math.Max(radius, 0.001f) * 2.15f };

            RequestRender();
        }
        catch (Exception ex)
        {
            ViewportProblem = ex.Message;
        }
    }

    // ------------------------------------------------------------------ camera

    /// <summary>Called by the view on a drag. Deltas are in pixels.</summary>
    public void OrbitCamera(double deltaX, double deltaY)
    {
        _camera = _camera.Orbit((float)(-deltaX * 0.01), (float)(deltaY * 0.01));
        RequestRender();
    }

    /// <summary>Called by the view on a wheel notch.</summary>
    public void ZoomCamera(double delta)
    {
        _camera = _camera.Zoom((float)Math.Pow(0.88, delta));
        RequestRender();
    }

    /// <summary>Called by the view on a middle-button or shift drag.</summary>
    public void PanCamera(double deltaX, double deltaY)
    {
        if (_previewModel is null) return;

        // Pan in the camera's own plane, scaled by distance so it feels the same at any zoom.
        var eye = _camera.Eye;
        var forward = System.Numerics.Vector3.Normalize(_camera.Target - eye);
        var right = System.Numerics.Vector3.Normalize(
            System.Numerics.Vector3.Cross(forward, System.Numerics.Vector3.UnitZ));
        var up = System.Numerics.Vector3.Cross(right, forward);

        float scale = _camera.Distance * 0.002f;
        _camera = _camera with
        {
            Target = _camera.Target + right * (float)(-deltaX * scale) + up * (float)(deltaY * scale),
        };
        RequestRender();
    }

    [RelayCommand]
    private void ResetCamera()
    {
        if (_previewModel is null) return;

        if (_animation is not null)
        {
            var (centre, radius) = _previewModel.BoundsOver(_previewModel.SamplePoses(_animation.Decoded));
            _camera = PreviewCamera.Frame(centre, radius);
        }
        else
        {
            _camera = PreviewCamera.Frame(_previewModel);
        }

        RequestRender();
    }

    // ------------------------------------------------------------------ playback

    [RelayCommand]
    private void TogglePlay()
    {
        if (_animation is null || LastFrame <= 0) return;
        if (IsPlaying) StopPlayback();
        else StartPlayback();
    }

    [RelayCommand]
    private void NextFrame()
    {
        StopPlayback();
        if (LastFrame > 0) Frame = Frame >= LastFrame ? 0 : Frame + 1;
    }

    [RelayCommand]
    private void PreviousFrame()
    {
        StopPlayback();
        if (LastFrame > 0) Frame = Frame <= 0 ? LastFrame : Frame - 1;
    }

    private void StartPlayback()
    {
        if (_animation is null) return;

        IsPlaying = true;
        RestartPlaybackTimer();
    }

    private void RestartPlaybackTimer()
    {
        _playback?.Stop();
        if (!IsPlaying || _animation is null) return;

        // The authored rate, not a nominal one: these animations run at 30.00, 29.94 and 27.02.
        double seconds = _animation.FrameDuration > 0f ? _animation.FrameDuration : 1.0 / 30.0;
        double interval = Math.Clamp(seconds / Math.Max(PlaybackSpeed, 0.01), 0.008, 1.0);

        _playback = new DispatcherTimer { Interval = TimeSpan.FromSeconds(interval) };
        _playback.Tick += (_, _) => Frame = Frame >= LastFrame ? 0 : Frame + 1;
        _playback.Start();
    }

    private void StopPlayback()
    {
        IsPlaying = false;
        _playback?.Stop();
        _playback = null;
    }

    // ------------------------------------------------------------------ rendering

    private void RequestRender()
    {
        if (_previewModel is null || !HasViewport) return;

        // A render already running means this frame is superseded; remember to draw once more when
        // it finishes rather than piling up work behind a drag.
        if (_rendering) { _renderQueued = true; return; }

        _ = RenderAsync();
    }

    private async Task RenderAsync()
    {
        var model = _previewModel;
        if (model is null) return;

        _rendering = true;
        try
        {
            do
            {
                _renderQueued = false;

                var camera = _camera;
                var options = new RenderOptions
                {
                    Textured = ShowTextures,
                    Wireframe = ShowWireframe,
                    ShowSkeleton = ShowSkeleton,
                    ShowSockets = ShowSockets,
                };

                var animation = _animation;
                int frame = Frame;
                int width = Math.Max(64, ViewportWidth);
                int height = Math.Max(64, ViewportHeight);

                var image = await Task.Run(() =>
                {
                    var pose = animation is null ? null : model.Pose(animation.Decoded, frame);
                    return SoftwareRenderer.Render(model, camera, options, width, height, pose);
                });

                if (!ReferenceEquals(model, _previewModel)) return;
                Viewport = ToBitmap(image);
            }
            while (_renderQueued);
        }
        catch (Exception ex)
        {
            ViewportProblem = ex.Message;
        }
        finally
        {
            _rendering = false;
        }
    }
}
