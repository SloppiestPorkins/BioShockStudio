using System.Text.Json;
using System.Text.Json.Serialization;
using BioShockStudio.Core.Export.Fbx;
using BioShockStudio.Core.Animation;

namespace BioShockStudio.Core.Export;

/// <summary>
/// Writes an <see cref="AnimationScene"/> as the set of FBX files an engine import expects, plus a
/// manifest describing what the FBX container cannot carry.
/// </summary>
/// <remarks>
/// <para>
/// One file holds the skinned mesh and its skeleton; each animation gets its own file. That split is
/// not a convenience — the shipped animations are authored at different rates within a single set
/// (30.00, 29.94 and 27.02 all occur among the pistol animations), and an FBX declares one frame
/// rate per file. Baking them together would force a resample and quietly change the timing.
/// </para>
/// <para>
/// The manifest carries what FBX has no place for: animation notifies, the socket a weapon rig
/// attaches to, and which weapon animation goes with which hand animation.
/// </para>
/// </remarks>
public static class FbxExporter
{
    private static readonly JsonSerializerOptions ManifestOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    public const string ManifestFileName = "ue5_manifest.json";

    /// <param name="previewAnimation">
    /// When set, also writes one extra file per rig holding the mesh and that animation together.
    /// The split above is what an engine import wants and is awkward to simply look at, so this is
    /// the file to open in a viewer to check that a rig deforms. It is not part of the import set.
    /// </param>
    public static FbxManifest Write(
        AnimationScene scene,
        string outputDirectory,
        FbxExportOptions? options = null,
        string? previewAnimation = null)
    {
        options ??= new FbxExportOptions();
        options = options with { BaseDirectory = outputDirectory };
        Directory.CreateDirectory(outputDirectory);

        var rigs = new List<FbxRig>
        {
            WriteRig(scene, outputDirectory, options, attachedTo: null, host: null, previewAnimation),
        };

        foreach (var attachment in scene.Attachments)
        {
            rigs.Add(WriteRig(
                attachment.Scene,
                outputDirectory,
                options,
                new FbxAttachmentPoint
                {
                    Host = scene.SourceObject,
                    Socket = attachment.SocketName,
                    Bone = attachment.SocketBone,
                },
                scene,
                // The weapon's animations are named without the weapon suffix the hands use, so the
                // same pairing heuristic that fills the manifest picks the preview's counterpart.
                previewAnimation is null
                    ? null
                    : Counterpart(
                        previewAnimation,
                        scene.Animations.FirstOrDefault(a => a.Name == previewAnimation)?.Duration ?? 0f,
                        attachment.Scene)));
        }

        var manifest = new FbxManifest
        {
            SourcePackage = scene.SourcePackage,
            SourceObject = scene.SourceObject,
            Rigs = rigs,
        };

        using var stream = File.Create(Path.Combine(outputDirectory, ManifestFileName));
        JsonSerializer.Serialize(stream, manifest, ManifestOptions);
        return manifest;
    }

    private static FbxRig WriteRig(
        AnimationScene scene,
        string outputDirectory,
        FbxExportOptions options,
        FbxAttachmentPoint? attachedTo,
        AnimationScene? host,
        string? previewAnimation)
    {
        string stem = Sanitise(AssetName(scene.SourceObject));
        string meshFile = stem + ".fbx";
        FbxWriter.Write(
            Path.Combine(outputDirectory, meshFile),
            FbxSceneBuilder.Build(scene, options with { Animation = null }));

        string animationDirectory = stem + "_Animations";
        var animations = new List<FbxAnimationEntry>();

        if (scene.Animations.Count > 0) Directory.CreateDirectory(Path.Combine(outputDirectory, animationDirectory));

        foreach (var animation in scene.Animations)
        {
            // The mesh travels once, in the file above; an animation file only needs the skeleton the
            // curves address.
            string file = Path.Combine(animationDirectory, Sanitise(animation.Name) + ".fbx").Replace('\\', '/');
            FbxWriter.Write(
                Path.Combine(outputDirectory, file),
                FbxSceneBuilder.Build(scene, options with { Animation = animation.Name, IncludeMesh = false }));

            animations.Add(new FbxAnimationEntry
            {
                Name = animation.Name,
                File = file,
                FrameCount = animation.FrameCount,
                FrameRate = animation.FrameDuration > 0f ? 1f / animation.FrameDuration : 0f,
                Duration = animation.Duration,
                PairedWith = host is null ? null : Counterpart(animation.Name, animation.Duration, host),
                Notifies = animation.Events
                    .Select(e => new FbxNotify { Time = e.Time, Name = e.Name, NotifyClass = e.NotifyClass })
                    .ToList(),
            });
        }

        string? preview = null;
        if (previewAnimation is not null
            && scene.Animations.Any(a => string.Equals(a.Name, previewAnimation, StringComparison.Ordinal)))
        {
            preview = $"{stem}_{Sanitise(previewAnimation)}_Preview.fbx";
            FbxWriter.Write(
                Path.Combine(outputDirectory, preview),
                FbxSceneBuilder.Build(scene, options with { Animation = previewAnimation, IncludeMesh = true }));
        }

        return new FbxRig
        {
            Name = AssetName(scene.SourceObject),
            SourceObject = scene.SourceObject,
            Preview = preview,
            Skeleton = scene.SkeletonName,
            Mesh = meshFile,
            BoneCount = scene.Bones.Count,
            VertexCount = scene.Mesh is null ? 0 : scene.Mesh.Positions.Length / 3,
            Sockets = scene.Sockets.Select(s => new FbxSocketEntry { Name = s.Name, Bone = s.BoneName }).ToList(),
            AttachedTo = attachedTo,
            Animations = animations,
            Undecoded = scene.Failures.Count,
        };
    }

    /// <summary>
    /// Names the host animation an attachment animation plays with — the pistol's <c>FastReload</c>
    /// against the hands' <c>FastReloadPistol</c>.
    /// </summary>
    /// <remarks>
    /// The rule itself lives in <see cref="AnimationPairing"/>, so the manifest and the preview
    /// cannot disagree about what pairs with what.
    /// </remarks>
    private static string? Counterpart(string name, float duration, AnimationScene host) =>
        AnimationPairing.Counterpart(
            name, duration, host.Animations.Select(a => (a.Name, a.Duration)));

    /// <summary>Prefix the game puts on an animation package wrapper object.</summary>
    private const string WrapperPrefix = "UAPW_";

    /// <summary>
    /// The asset's name, without the internal prefix its animation package carries.
    /// </summary>
    /// <remarks>
    /// A scene is built from the wrapper export, so its object name is <c>UAPW_NEWPlayerHands</c>
    /// and every file and folder was being named after it. The prefix is the game's bookkeeping, not
    /// part of what the asset is called, and it has no business in an export someone else opens. The
    /// wrapper's real name is still recorded in the manifest as <c>sourceObject</c>.
    /// </remarks>
    private static string AssetName(string sourceObject) =>
        sourceObject.StartsWith(WrapperPrefix, StringComparison.OrdinalIgnoreCase)
            ? sourceObject[WrapperPrefix.Length..]
            : sourceObject;

    private static string Sanitise(string name) => string.Concat(name.Split(Path.GetInvalidFileNameChars()));
}

/// <summary>Everything an engine import needs that the FBX files themselves cannot express.</summary>
public sealed record FbxManifest
{
    public required string SourcePackage { get; init; }
    public required string SourceObject { get; init; }

    /// <summary>The game's unit, carried through unscaled. Unreal's unit is the same.</summary>
    public string Unit { get; init; } = "centimetre";

    public string UpAxis { get; init; } = "Z";

    public required IReadOnlyList<FbxRig> Rigs { get; init; }
}

public sealed record FbxRig
{
    /// <summary>What the asset is called, without the animation package's internal prefix.</summary>
    public required string Name { get; init; }

    /// <summary>The export this was built from, prefix and all, so it can be traced back.</summary>
    public string? SourceObject { get; init; }

    public required string Skeleton { get; init; }

    /// <summary>Path, relative to the manifest, of the skinned mesh and skeleton.</summary>
    public required string Mesh { get; init; }

    /// <summary>
    /// A mesh-and-animation file for looking at, when one was asked for. Not part of the import set:
    /// importing it as well as the files above would duplicate the mesh.
    /// </summary>
    public string? Preview { get; init; }

    public required int BoneCount { get; init; }
    public required int VertexCount { get; init; }
    public required IReadOnlyList<FbxSocketEntry> Sockets { get; init; }

    /// <summary>Set when this rig hangs off another rig's socket rather than standing alone.</summary>
    public FbxAttachmentPoint? AttachedTo { get; init; }

    public required IReadOnlyList<FbxAnimationEntry> Animations { get; init; }

    /// <summary>Animations that did not decode, so a short list is visibly short rather than silently so.</summary>
    public required int Undecoded { get; init; }
}

public sealed record FbxSocketEntry
{
    public required string Name { get; init; }
    public required string Bone { get; init; }
}

public sealed record FbxAttachmentPoint
{
    public required string Host { get; init; }
    public required string Socket { get; init; }
    public required string Bone { get; init; }
}

public sealed record FbxAnimationEntry
{
    public required string Name { get; init; }
    public required string File { get; init; }
    public required int FrameCount { get; init; }
    public required float FrameRate { get; init; }
    public required float Duration { get; init; }

    /// <summary>The host animation this one plays with, when this rig is an attachment. Heuristic.</summary>
    public string? PairedWith { get; init; }

    public required IReadOnlyList<FbxNotify> Notifies { get; init; }
}

public sealed record FbxNotify
{
    public required float Time { get; init; }
    public required string Name { get; init; }
    public required string NotifyClass { get; init; }
}
