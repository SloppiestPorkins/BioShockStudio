using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Avalonia.Media.Imaging;
using Avalonia.Threading;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Animation;
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
    private PreviewModel? _attachmentModel;
    private PreviewAnimation? _attachmentAnimation;
    private AttachmentCandidate? _attachment;
    private IReadOnlyList<AttachmentCandidate> _candidates = [];
    private int _socketBone = -1;
    private PreviewCamera _camera = new();
    private DispatcherTimer? _playback;
    private CancellationTokenSource? _previewWork;
    private bool _rendering;
    private bool _renderQueued;

    /// <summary>When the last camera move or playback frame happened.</summary>
    private DateTime _lastInteraction = DateTime.MinValue;

    /// <summary>
    /// How long after the last interaction the viewport keeps drawing at reduced size.
    /// </summary>
    private static readonly TimeSpan InteractionSettle = TimeSpan.FromMilliseconds(220);

    /// <summary>
    /// Fraction of the full render size used while the camera is moving or an animation is playing.
    /// </summary>
    /// <remarks>
    /// The rasteriser is on the CPU and its cost is per pixel, so full size — physical pixels with
    /// supersampling on top — is roughly 940,000 of them for a panel this size. That is fine to
    /// look at and too slow to drag. Dropping to six tenths is a little over a third of the pixels
    /// and the difference is invisible while something is moving; the full-size frame follows a
    /// fifth of a second after you stop.
    /// </remarks>
    private const double InteractiveScale = 0.6;

    private bool Interacting => DateTime.UtcNow - _lastInteraction < InteractionSettle;

    /// <summary>Marks the viewport as being interacted with, so the next frames draw smaller.</summary>
    private void NoteInteraction() => _lastInteraction = DateTime.UtcNow;

    [ObservableProperty] private Bitmap? _viewport;
    [ObservableProperty] private bool _hasViewport;
    [ObservableProperty] private bool _isPreviewLoading;
    [ObservableProperty] private string? _viewportProblem;
    [ObservableProperty] private int _viewportWidth = 420;
    [ObservableProperty] private int _viewportHeight = 300;

    [ObservableProperty] private bool _showTextures = true;

    /// <summary>Honour the diffuse texture's alpha rather than drawing every surface solid.</summary>
    [ObservableProperty] private bool _showTransparency = true;
    [ObservableProperty] private bool _showWireframe;
    [ObservableProperty] private bool _showShading = true;
    [ObservableProperty] private bool _showSkeleton;
    [ObservableProperty] private bool _showSockets;

    [ObservableProperty] private string? _selectedAnimation;
    [ObservableProperty] private bool _isPlaying;
    [ObservableProperty] private int _frame;
    [ObservableProperty] private int _lastFrame;
    [ObservableProperty] private double _playbackSpeed = 1.0;
    [ObservableProperty] private string _animationSummary = "";

    [ObservableProperty] private string? _selectedPreviewMesh;
    [ObservableProperty] private bool _hasMeshVariants;
    private bool _switchingMesh;

    [ObservableProperty] private string? _selectedAttachment;
    [ObservableProperty] private string _attachmentEvidence = "";
    [ObservableProperty] private bool _hasAttachments;

    public ObservableCollection<string> PreviewMeshes { get; } = [];
    public ObservableCollection<string> Attachments { get; } = [];
    public ObservableCollection<string> PreviewAnimations { get; } = [];

    /// <summary>Animation set names, with an "All sets" entry first.</summary>
    public ObservableCollection<string> AnimationSets { get; } = [];

    [ObservableProperty] private string? _selectedAnimationSet;
    [ObservableProperty] private bool _hasAnimationSets;

    /// <summary>Every animation of the current asset, with the set it belongs to.</summary>
    private IReadOnlyList<AnimationSetEntry> _animationSets = [];

    /// <summary>Shown when one set is chosen, so it is clear how much is being hidden.</summary>
    [ObservableProperty] private string _animationSetSummary = "";

    public const string AllAnimationSets = "All sets";

    partial void OnSelectedAnimationSetChanged(string? value) => ApplyAnimationSetFilter();

    /// <summary>
    /// Rebuilds the animation list for the chosen set.
    /// </summary>
    /// <remarks>
    /// A character can carry hundreds of animations across a dozen behaviour sets, and the sets are
    /// the game's own grouping rather than one this tool invents — they come from the Havok root
    /// table's owner column.
    /// </remarks>
    private void ApplyAnimationSetFilter()
    {
        string? keep = SelectedAnimation;

        PreviewAnimations.Clear();
        bool all = SelectedAnimationSet is null or AllAnimationSets;

        foreach (var entry in _animationSets)
        {
            if (all || string.Equals(entry.Owner, SelectedAnimationSet, StringComparison.Ordinal))
                PreviewAnimations.Add(entry.Name);
        }

        AnimationSetSummary = all
            ? $"{_animationSets.Count} animations in {_animationSets.Select(a => a.Owner).Distinct().Count()} sets"
            : $"{PreviewAnimations.Count} of {_animationSets.Count} animations";

        // Keep the current selection when it survives the filter, so switching sets to look around
        // does not stop playback of something already chosen.
        if (keep is not null && PreviewAnimations.Contains(keep)) SelectedAnimation = keep;
    }
    public ObservableCollection<double> PlaybackSpeeds { get; } = [0.25, 0.5, 1.0, 2.0];

    partial void OnShowTexturesChanged(bool value) => RequestRender();
    partial void OnShowTransparencyChanged(bool value) => RequestRender();
    partial void OnShowWireframeChanged(bool value) => RequestRender();
    partial void OnShowShadingChanged(bool value) => RequestRender();
    partial void OnShowSkeletonChanged(bool value) => RequestRender();
    partial void OnShowSocketsChanged(bool value) => RequestRender();
    partial void OnFrameChanged(int value) { NoteInteraction(); RequestRender(); }
    partial void OnViewportWidthChanged(int value) => RequestRender();
    partial void OnViewportHeightChanged(int value) => RequestRender();
    partial void OnPlaybackSpeedChanged(double value) => RestartPlaybackTimer();

    partial void OnSelectedAnimationChanged(string? value) => _ = LoadAnimationAsync(value);
    partial void OnSelectedAttachmentChanged(string? value) => _ = LoadAttachmentAsync(value);

    /// <summary>
    /// Switches which mesh of the group is drawn.
    /// </summary>
    /// <remarks>
    /// A group is often several meshes on one skeleton — the Baby Jane splicer carries the doctor,
    /// the corpse and the Lady Smith variants — so the animations and attachments stay as they are
    /// and only the geometry is rebuilt.
    /// </remarks>
    partial void OnSelectedPreviewMeshChanged(string? value)
    {
        if (_switchingMesh || value is null || SelectedAsset is null) return;
        _ = SwitchMeshAsync(SelectedAsset, value);
    }

    private async Task SwitchMeshAsync(CatalogEntry entry, string meshName)
    {
        try
        {
            var subject = await Task.Run(() => _preview.Load(entry, meshName));
            if (!ReferenceEquals(entry, SelectedAsset)) return;

            _previewModel = subject.Model;
            ViewportProblem = subject.Problem;
            HasViewport = subject.Model.HasGeometry || subject.Model.Bones.Count > 0;
            RequestRender();
        }
        catch (Exception ex)
        {
            ViewportProblem = ex.Message;
        }
    }

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
        _animationSets = [];
        AnimationSets.Clear();
        SelectedAnimationSet = null;
        HasAnimationSets = false;
        AnimationSetSummary = "";
        Attachments.Clear();
        _switchingMesh = true;
        PreviewMeshes.Clear();
        SelectedPreviewMesh = null;
        _switchingMesh = false;
        HasMeshVariants = false;
        SelectedAnimation = null;
        SelectedAttachment = null;
        AttachmentEvidence = "";
        HasAttachments = false;
        _attachment = null;
        _attachmentModel = null;
        _attachmentAnimation = null;
        _socketBone = -1;
        _candidates = [];
        LastFrame = 0;
        Frame = 0;
        AnimationSummary = "";

        // Textures have their own preview; there is nothing to draw in 3D for a material either.
        if (entry is null || entry.Category is AssetCategory.Textures or AssetCategory.Materials) return;

        _previewWork = new CancellationTokenSource();
        var token = _previewWork.Token;
        IsPreviewLoading = true;

        try
        {
            var subject = await Task.Run(() => _preview.Load(entry, null, token), token);
            if (token.IsCancellationRequested) return;

            _previewModel = subject.Model;
            ViewportProblem = subject.Problem;
            HasViewport = subject.Model.HasGeometry || subject.Model.Bones.Count > 0;

            if (!HasViewport) return;

            _camera = PreviewCamera.Frame(subject.Model);
            ShowSkeleton = !subject.Model.HasGeometry;

            _switchingMesh = true;
            foreach (string mesh in subject.Meshes) PreviewMeshes.Add(mesh);
            SelectedPreviewMesh = subject.SelectedMesh;
            _switchingMesh = false;
            HasMeshVariants = subject.Meshes.Count > 1;

            _animationSets = subject.AnimationSets;

            var owners = _animationSets.Select(a => a.Owner).Distinct(StringComparer.Ordinal).ToList();
            HasAnimationSets = owners.Count > 1;
            if (HasAnimationSets)
            {
                AnimationSets.Add(AllAnimationSets);
                foreach (string owner in owners) AnimationSets.Add(owner);
            }

            SelectedAnimationSet = AllAnimationSets;
            ApplyAnimationSetFilter();
            RequestRender();

            // What attaches to this asset is a cross-package search, so it runs after the model is
            // already on screen rather than holding it up.
            _ = LoadAttachmentCandidatesAsync(entry, token);
        }
        catch (OperationCanceledException)
        {
            // Superseded by a newer selection.
        }
        catch (Exception ex)
        {
            ViewportProblem = ex.Message;
        }
        finally
        {
            IsPreviewLoading = false;
        }
    }

    private async Task LoadAttachmentCandidatesAsync(CatalogEntry entry, CancellationToken token)
    {
        try
        {
            var candidates = await Task.Run(() => _context.Attachments(entry, token), token);
            if (token.IsCancellationRequested || !ReferenceEquals(entry, SelectedAsset)) return;

            _candidates = candidates;
            Attachments.Clear();
            foreach (var candidate in candidates) Attachments.Add(candidate.Socket);
            HasAttachments = candidates.Count > 0;
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

    /// <summary>
    /// Loads the asset that hangs off a socket and places it there.
    /// </summary>
    /// <remarks>
    /// The two rigs stay separate. The attachment is drawn with the host's socket-bone transform, so
    /// a first-person set is what the game actually is — two skeletons played together — rather than
    /// one merged rig.
    /// </remarks>
    private async Task LoadAttachmentAsync(string? socket)
    {
        _attachment = null;
        _attachmentModel = null;
        _attachmentAnimation = null;
        _socketBone = -1;
        AttachmentEvidence = "";

        if (socket is null || _previewModel is null)
        {
            RequestRender();
            return;
        }

        var candidate = _candidates.FirstOrDefault(c => c.Socket == socket);
        if (candidate is null) { RequestRender(); return; }

        var host = _previewModel;

        try
        {
            var subject = await Task.Run(() => _preview.LoadAttachment(candidate));
            if (!ReferenceEquals(host, _previewModel)) return;

            _attachment = candidate;
            _attachmentModel = subject.Model;
            AttachmentEvidence = candidate.Confidence + ": " + candidate.Evidence;

            // An attachment that resolves but cannot be drawn — TommyGunMESH is one — otherwise
            // appears simply not to attach. The tool knows why; it has to say so.
            if (subject.Problem is not null)
            {
                ViewportProblem = $"{candidate.Socket}: {subject.Problem}";
            }
            else if (!subject.Model.HasGeometry)
            {
                ViewportProblem = $"{candidate.Socket} attached, but '{candidate.MeshObject}' has no "
                                  + "geometry this tool can read, so only its animation is applied.";
            }

            for (int i = 0; i < host.Bones.Count; i++)
            {
                if (string.Equals(host.Bones[i].Name, candidate.SocketBone, StringComparison.OrdinalIgnoreCase))
                {
                    _socketBone = i;
                    break;
                }
            }

            SelectAnimationSetForAttachment(candidate);

            await PairAttachmentAnimationAsync(subject.Animations);
            RequestRender();
        }
        catch (Exception ex)
        {
            ViewportProblem = ex.Message;
        }
    }

    /// <summary>
    /// Switches the host's animation list to the set that belongs to the chosen attachment.
    /// </summary>
    /// <remarks>
    /// Playing the Pistol set while the grenade launcher is attached poses the hands for a gun that
    /// is not there — the launcher passes through the forearm and neither hand is on the grip. It
    /// reads as a broken attachment, and it is really a mismatched animation, so the two are now
    /// tied together.
    /// <para>
    /// A current selection inside the new set is kept; one from another weapon's set is dropped,
    /// because it is the thing that was drawing wrongly.
    /// </para>
    /// </remarks>
    private void SelectAnimationSetForAttachment(AttachmentCandidate candidate)
    {
        if (!HasAnimationSets) return;

        var owners = _animationSets.Select(a => a.Owner).Distinct(StringComparer.Ordinal).ToList();
        string? set = AssetContextService.AnimationSetFor(candidate, owners);
        if (set is null || !AnimationSets.Contains(set)) return;

        bool selectionBelongs = SelectedAnimation is not null
            && _animationSets.Any(a => a.Name == SelectedAnimation && a.Owner == set);

        if (!selectionBelongs) SelectedAnimation = null;
        SelectedAnimationSet = set;
    }

    /// <summary>Finds and loads the attachment animation that goes with the host's current one.</summary>
    private async Task PairAttachmentAnimationAsync(IReadOnlyList<string> available)
    {
        _attachmentAnimation = null;
        if (_attachment is null || SelectedAnimation is null || available.Count == 0) return;

        string? paired = AssetContextService.Counterpart(SelectedAnimation, available);
        if (paired is null) return;

        var candidate = _attachment;
        var loaded = await Task.Run(() => _preview.LoadAttachmentAnimation(candidate, paired));
        if (loaded is null) return;

        // The name match is a heuristic; the timing is the evidence. Two rigs playing one
        // performance share a DURATION — not a frame count. A weapon rig is often authored sparsely:
        // the launcher's FireLast is 0.70s in 2 frames at 1.43 fps against the hands' 0.70s in 22
        // frames at 30, and its Equip is 0.23s in 2 frames against 8. Requiring equal frame counts
        // silently dropped the weapon's motion from the crossbow reload (93 against 91), the
        // launcher's FireLast and Equip, and every zoomed fire.
        //
        // The pairing this guard exists to reject — the hands' 1.43s FireLauncher against the
        // weapon's 0.70s FireLast — is 51% apart, while every correct pairing is within 10%.
        if (_animation is not null && !AnimationPairing.PlaysTogether(_animation.Duration, loaded.Duration)) return;

        _attachmentAnimation = loaded;
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

            // The weapon plays its own matching animation, in sync with the hands'.
            if (_attachment is not null)
            {
                var candidate = _attachment;
                var available = await Task.Run(() => _preview.LoadAttachment(candidate).Animations);
                await PairAttachmentAnimationAsync(available);
            }

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
        NoteInteraction();
        RequestRender();
    }

    /// <summary>Called by the view on a wheel notch.</summary>
    public void ZoomCamera(double delta)
    {
        _camera = _camera.Zoom((float)Math.Pow(0.88, delta));
        NoteInteraction();
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
        NoteInteraction();
        RequestRender();
    }

    /// <summary>One notch closer. Bound to the + button, matching one wheel notch.</summary>
    [RelayCommand]
    private void ZoomIn() => ZoomCamera(1);

    /// <summary>One notch further away.</summary>
    [RelayCommand]
    private void ZoomOut() => ZoomCamera(-1);

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
        bool reduced = false;
        try
        {
            do
            {
                _renderQueued = false;

                var camera = _camera;
                var options = new RenderOptions
                {
                    Textured = ShowTextures,
                    Transparency = ShowTransparency,
                    Shaded = ShowShading,
                    Wireframe = ShowWireframe,
                    ShowSkeleton = ShowSkeleton,
                    ShowSockets = ShowSockets,
                };

                var animation = _animation;
                int frame = Frame;
                // While something is moving, draw fewer pixels. The frame after it settles is
                // full size, and RequestRender's queue-one-more means that frame always happens.
                bool interacting = Interacting;
                double scale = interacting ? InteractiveScale : 1.0;
                int width = Math.Max(64, (int)(ViewportWidth * scale));
                int height = Math.Max(64, (int)(ViewportHeight * scale));

                var attachmentModel = _attachmentModel;
                var attachmentAnimation = _attachmentAnimation;
                int socketBone = _socketBone;

                var image = await Task.Run(() =>
                {
                    var pose = animation is null ? null : model.Pose(animation.Decoded, frame);
                    var instances = new List<PreviewInstance> { new(model, pose) };

                    if (attachmentModel is not null && socketBone >= 0)
                    {
                        var transform = pose is null ? model.Bones[socketBone].RestGlobal : pose[socketBone];

                        // The two rigs agree on duration, not on frame count, so the attachment is
                        // sampled by normalised time. Posing it at the host's own frame index reads
                        // a 2-frame weapon animation off the end of its own track.
                        var attachmentPose = attachmentAnimation is null
                            ? null
                            : attachmentModel.Pose(
                                attachmentAnimation.Decoded,
                                AnimationPairing.AttachmentFrame(
                                    animation?.FrameCount ?? 1, attachmentAnimation.FrameCount, frame));
                        instances.Add(new PreviewInstance(attachmentModel, attachmentPose, transform));
                    }

                    return SoftwareRenderer.Render(instances, camera, options, width, height);
                });

                if (!ReferenceEquals(model, _previewModel)) return;
                Viewport = ToBitmap(image);
                reduced = interacting;
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

        // The last frame of a drag is a reduced one, and nothing else is coming to replace it —
        // so draw once more after the interaction has settled. Without this the viewport stays
        // soft until the next time it is touched.
        if (reduced) _ = RedrawWhenSettledAsync();
    }

    private async Task RedrawWhenSettledAsync()
    {
        await Task.Delay(InteractionSettle).ConfigureAwait(true);
        if (!Interacting) RequestRender();
    }
}
