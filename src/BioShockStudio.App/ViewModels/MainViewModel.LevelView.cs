using System;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using Avalonia;
using Avalonia.Media.Imaging;
using Avalonia.Platform;
using System.Collections.Generic;
using System.Linq;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Level;
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
    // The GL path multiplies this by eight and Medical contains 4.2M triangles. Starting at the
    // slider maximum therefore shows the complete scene rather than silently omitting 1,000+
    // exterior parts; users can still lower it for a slower GPU.
    [ObservableProperty] private int _levelTriangleBudget = 600_000;

    /// <summary>Movement multiplier, so a map can be crossed without waiting.</summary>
    [ObservableProperty] private double _levelCameraSpeed = 1.0;

    /// <summary>
    /// Draw zones, triggers and the other volumes the game never renders. <b>Off by default.</b>
    /// </summary>
    /// <remarks>
    /// A blocking volume, trigger or water volume is a region the engine tests against; its brush is
    /// a box the size of a room and it is never drawn. Shown, they are the enormous grey slabs that
    /// swallow a level view. Kept as an option because seeing where they are is useful in itself.
    /// </remarks>
    [ObservableProperty] private bool _showLevelVolumes;

    /// <summary>
    /// Draw the designer's source brushes as well as the compiled world. <b>Off by default.</b>
    /// </summary>
    /// <remarks>
    /// A source brush is the <i>input</i> to CSG and the compiled world is its <i>output</i> — the
    /// solid block a designer drew, against the room carved out of it. Drawing both stacks the
    /// uncarved blocks on top of the rooms, which is most of what "weird boxes covering everything"
    /// turns out to be.
    /// </remarks>
    [ObservableProperty] private bool _showSourceBrushes;

    /// <summary>Draw the compiled CSG world: the actual rooms, floors and walls.</summary>
    [ObservableProperty] private bool _showCompiledWorld = true;

    /// <summary>Draw ordinary placed UE2 StaticMesh actors.</summary>
    [ObservableProperty] private bool _showStaticMeshes = true;

    /// <summary>Draw placed UE2 SkeletalMesh actors.</summary>
    [ObservableProperty] private bool _showSkeletalMeshes = true;

    /// <summary>Light the level with its own point lights rather than the fixed studio lighting.</summary>
    /// <remarks>
    /// Off by default, and that is a claim about honesty rather than taste: this is <b>not</b> the
    /// game's lighting model. Static lighting now has a separately-toggleable, vertex-sampled
    /// baked-light atlas path; these actor lights remain a simple point-light approximation.
    /// </remarks>
    [ObservableProperty] private bool _useLevelLights;

    /// <summary>Apply the compiled world's verified baked-light atlas samples in the GPU viewport.</summary>
    [ObservableProperty] private bool _showBakedLightmaps = true;

    /// <summary>Draw light shafts and glow cards. Off by default — they have no base colour.</summary>
    [ObservableProperty] private bool _showLevelUnpainted;

    /// <summary>Draw godrays, water and glow cards that intentionally omit a base-colour map.</summary>
    [ObservableProperty] private bool _showLevelEffects;

    partial void OnShowLevelUnpaintedChanged(bool value) => SettleLevelCamera();
    partial void OnShowLevelEffectsChanged(bool value) => SettleLevelCamera();

    partial void OnUseLevelLightsChanged(bool value) => SettleLevelCamera();
    partial void OnShowBakedLightmapsChanged(bool value) => SettleLevelCamera();

    partial void OnShowLevelVolumesChanged(bool value) => SettleLevelCamera();
    partial void OnShowSourceBrushesChanged(bool value) => SettleLevelCamera();
    partial void OnShowCompiledWorldChanged(bool value) => SettleLevelCamera();
    partial void OnShowStaticMeshesChanged(bool value) => SettleLevelCamera();
    partial void OnShowSkeletalMeshesChanged(bool value) => SettleLevelCamera();

    /// <summary>What the viewport draws. Read by both renderers.</summary>
    public LevelViewFilter ViewFilter => new()
    {
        ShowVolumes = ShowLevelVolumes,
        ShowSourceBrushes = ShowSourceBrushes,
        ShowWorld = ShowCompiledWorld,
        ShowStaticMeshes = ShowStaticMeshes,
        ShowSkeletalMeshes = ShowSkeletalMeshes,
        ShowUnpainted = ShowLevelUnpainted,
        ShowEffects = ShowLevelEffects,
        ShowBakedLightmaps = ShowBakedLightmaps,
    };

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

    /// <summary>Raised when the live viewport's requested triangle budget changes.</summary>
    public event Action<int>? LevelTriangleBudgetChanged;

    /// <summary>Raised when a level is ready, so the view can hand it to the GPU.</summary>
    public event Action<PreparedLevel, GhostCamera>? LevelOpened;

    partial void OnLevelTriangleBudgetChanged(int value) => LevelTriangleBudgetChanged?.Invoke(value);

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
            UpdateLevelLocation();
            UpdateLevelContents(prepared.Scene);
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
        LevelLocation = "";
        LevelContents = [];
        LevelClosed?.Invoke();
    }

    /// <summary>Turns the camera, in radians.</summary>
    public void LookLevelCamera(float deltaYaw, float deltaPitch)
    {
        if (!HasLevelView) return;
        _levelCamera = _levelCamera.Look(deltaYaw, deltaPitch);
        UpdateLevelLocation();
        Invalidate(moving: true);
    }

    /// <summary>Moves the camera. Each axis is -1, 0 or 1.</summary>
    public void MoveLevelCamera(float forward, float right, float up, float seconds)
    {
        if (!HasLevelView) return;
        _levelCamera = _levelCamera.Move(forward, right, up, seconds, (float)LevelCameraSpeed);
        UpdateLevelLocation();
        Invalidate(moving: true);
    }

    /// <summary>
    /// Where the camera is, <b>in the game's own coordinates</b> — the numbers an actor's
    /// <c>Location</c> property is written in.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Reported in the game's basis, not the studio's, and that is the whole point.</b> Geometry
    /// and placements are converted on decode by <c>C = diag(1,-1,1)</c>
    /// (<c>docs/research/ANIMATION_COORDINATE_SYSTEM.md</c>), so the viewport's own Y is the
    /// negation of the one every shipped package, every actor <c>Location</c>, and Nyko's editor
    /// use. A readout in studio coordinates would be a number nobody could look anything up with,
    /// and worse, one that looks plausible while pointing at the mirror image of the right place.
    /// The conversion is its own inverse, so this is the same call in both directions.
    /// </para>
    /// <para>
    /// Added because a user reporting a misplaced asset had no way to say <i>where</i> — the
    /// alternative was describing the room and guessing which actors were in it.
    /// </para>
    /// </remarks>
    [ObservableProperty] private string _levelLocation = "";

    private void UpdateLevelLocation()
    {
        var game = GameBasis.Convert(_levelCamera.Position);
        float heading = _levelCamera.Yaw * 180f / MathF.PI;
        float elevation = _levelCamera.Pitch * 180f / MathF.PI;

        LevelLocation =
            $"X {game.X:0} · Y {game.Y:0} · Z {game.Z:0} · facing {heading:0}° · pitch {elevation:0}°";
    }

    /// <summary>
    /// What this level contains, and which of it the viewport draws — including the categories it
    /// does <b>not</b>.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Silent omission is the failure mode this exists to stop.</b> A viewport that shows a
    /// level's geometry and quietly leaves out its lights, zones, navigation graph, sounds and
    /// script actors looks complete, and the difference between "this map has no triggers" and
    /// "triggers are never drawn" is invisible from the picture. The ledger behind this
    /// (<see cref="LevelCoverageReport"/>) has existed for a while and reached only the CLI's
    /// <c>level-audit</c>; the person who needs it most is the one looking at the level.
    /// </para>
    /// <para>
    /// The same principle as the Problems panel stating its coverage before its findings: "nothing
    /// found" and "nothing looked" must not render identically.
    /// </para>
    /// </remarks>
    [ObservableProperty] private IReadOnlyList<string> _levelContents = [];

    /// <summary>Whether a coverage status is geometry the viewport actually places.</summary>
    private static bool IsDrawn(LevelActorCoverage status) =>
        status is LevelActorCoverage.GeometryInScene or LevelActorCoverage.SkeletalMeshBindPose;

    private static string Describe(LevelActorCoverage status) => status switch
    {
        LevelActorCoverage.GeometryInScene => "drawn — meshes and brushes",
        LevelActorCoverage.SkeletalMeshBindPose => "drawn — skeletal, in bind pose",
        LevelActorCoverage.ExternalGeometryPending => "not drawn — geometry in another package",
        LevelActorCoverage.LightPending => "not drawn — lights (see the Level lights toggle)",
        LevelActorCoverage.RegionPending => "not drawn — zones, triggers and volumes",
        LevelActorCoverage.EffectPending => "not drawn — particle emitters",
        LevelActorCoverage.AudioPending => "not drawn — sound actors",
        LevelActorCoverage.NavigationPending => "not drawn — navigation graph",
        LevelActorCoverage.ScriptPending => "not drawn — script action graphs",
        _ => "not drawn — unclassified",
    };

    private void UpdateLevelContents(LevelScene scene)
    {
        if (scene.Coverage is not { } coverage) { LevelContents = []; return; }

        var byStatus = coverage.Classes
            .SelectMany(row => row.StatusCounts.Select(entry => (row.ClassName, entry.Key, entry.Value)))
            .GroupBy(entry => entry.Key)
            .Select(group => (
                Status: group.Key,
                Actors: group.Sum(entry => entry.Value),
                Classes: group.OrderByDescending(entry => entry.Value)
                    .Select(entry => entry.ClassName).ToList()))
            // Drawn first, then the rest by how much of the level they account for: the biggest
            // omission is the one worth seeing.
            .OrderByDescending(group => IsDrawn(group.Status))
            .ThenByDescending(group => group.Actors)
            .ToList();

        var lines = new List<string>(byStatus.Count + 1)
        {
            $"{coverage.ActorCount:N0} actors, {coverage.Classes.Count:N0} classes",
        };

        foreach (var (status, actors, classes) in byStatus)
        {
            string examples = string.Join(", ", classes.Take(3));
            if (classes.Count > 3) examples += $", +{classes.Count - 3} more";
            lines.Add($"{actors,6:N0}  {Describe(status)}  ({examples})");
        }

        LevelContents = lines;
    }

    /// <summary>Puts the camera at a point, in the studio basis the viewport works in.</summary>
    /// <remarks>
    /// Exists so the position readout can be tested against a shipped actor's own stated
    /// <c>Location</c> rather than against the conversion function — see
    /// <c>LevelWalkthroughUiTests.TheCameraPositionIsReportedInTheGamesOwnCoordinates</c>.
    /// </remarks>
    public void PlaceLevelCameraAt(System.Numerics.Vector3 position)
    {
        if (!HasLevelView) return;
        _levelCamera = _levelCamera with { Position = position };
        UpdateLevelLocation();
        Invalidate(moving: false);
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
            var filter = ViewFilter;
            var lights = UseLevelLights ? prepared.Lights : [];
            var timer = Stopwatch.StartNew();

            var (image, selection) = await Task.Run(() =>
            {
                var chosen = prepared.Viewport.Select(camera, (float)width / height, budget, filter);
                var rendered = SoftwareRenderer.Render(
                    chosen.Instances,
                    camera.ToPreviewCamera(),
                    new RenderOptions
                    {
                        ShowSkeleton = false, ShowSockets = false, Textured = true,
                        Lights = lights,
                        ShowUnpainted = filter.ShowUnpainted,
                        ShowEffects = filter.ShowEffects,
                    },
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
