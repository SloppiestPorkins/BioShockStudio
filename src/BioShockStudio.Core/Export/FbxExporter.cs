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

    /// <summary>
    /// Schema version of <see cref="ManifestFileName"/>. Bump only for incompatible changes.
    /// </summary>
    /// <remarks>
    /// <b>1</b> first carried texture intent. <b>2</b> carries the authored material records those
    /// textures belong to, so an engine can create instances without inferring shader defaults.
    /// </remarks>
    public const int ManifestVersion = 2;

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

    /// <summary>
    /// Every texture the scene's materials bind, with its intent, deduplicated by file and slot.
    /// </summary>
    /// <remarks>
    /// Keyed by material and slot rather than by file: the same image is legitimately a base colour
    /// in one binding and a mask in another, and an importer that collapsed them would have to
    /// pick one colour space for both.
    /// </remarks>
    private static List<FbxTextureEntry> TextureEntries(AnimationScene scene)
    {
        var entries = new List<FbxTextureEntry>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        var materials = scene.Materials.Count > 0
            ? scene.Materials
            : scene.Material is null ? [] : new List<SceneMaterial> { scene.Material };

        foreach (var material in materials)
        {
            foreach (var (slot, file) in material.Textures)
            {
                if (!material.TextureIntents.TryGetValue(slot, out var intent)) continue;
                if (!seen.Add($"{material.Name}|{slot}")) continue;

                entries.Add(new FbxTextureEntry
                {
                    File = file,
                    Slot = slot,
                    Material = material.Name,
                    Usage = intent.Usage.ToString(),
                    ColourSpace = intent.ColourSpace.ToString(),
                    AddressU = intent.AddressU.ToString(),
                    AddressV = intent.AddressV.ToString(),
                    DeclaresMasked = intent.DeclaresMasked,
                    DeclaresAlphaTexture = intent.DeclaresAlphaTexture,
                });
            }
        }

        return entries;
    }

    private static IReadOnlyList<SceneMaterial> MaterialEntries(AnimationScene scene) =>
        scene.Materials.Count > 0
            ? scene.Materials
            : scene.Material is null ? [] : [scene.Material];

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
            Textures = TextureEntries(scene),
            Materials = MaterialEntries(scene),
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
    /// <summary>
    /// Schema version for the rig-to-UE5 handoff. Bump only for incompatible changes.
    /// </summary>
    /// <remarks>
    /// <b>Added 23 Aug 2026, Gate 5 item 1.</b> The level manifest has carried a version since it
    /// existed and `tools/ue5/validate_level_manifest.py` refuses an unsupported one; this document
    /// had none at all, so an importer had no way to tell a manifest predating
    /// <see cref="FbxRig.Textures"/> from one carrying it, and would silently import a rig with no
    /// textures rather than reporting a stale export.
    /// </remarks>
    public int Version { get; init; } = FbxExporter.ManifestVersion;

    public required string SourcePackage { get; init; }
    public required string SourceObject { get; init; }

    /// <summary>The game's unit, carried through unscaled. Unreal's unit is the same.</summary>
    public string Unit { get; init; } = "centimetre";

    public string UpAxis { get; init; } = "Z";

    public required IReadOnlyList<FbxRig> Rigs { get; init; }
}

/// <summary>One texture an import should create, and how it must be sampled.</summary>
public sealed record FbxTextureEntry
{
    /// <summary>Path of the PNG, relative to the manifest.</summary>
    public required string File { get; init; }

    /// <summary>The material slot that binds it, which is where the usage comes from.</summary>
    public required string Slot { get; init; }

    /// <summary>The material binding it, so several materials' textures stay distinguishable.</summary>
    public required string Material { get; init; }

    /// <summary>Base colour, normal map, mask and so on.</summary>
    public required string Usage { get; init; }

    /// <summary>
    /// <c>Srgb</c> or <c>Linear</c>. <b>Inferred from usage, not declared by the game</b> - see
    /// <see cref="Textures.TextureColourSpace"/>.
    /// </summary>
    public required string ColourSpace { get; init; }

    /// <summary>Sampler addressing, <c>Wrap</c> or <c>Clamp</c>.</summary>
    public required string AddressU { get; init; }

    public required string AddressV { get; init; }

    /// <summary>The texture declares its alpha to be a cutout.</summary>
    public bool DeclaresMasked { get; init; }

    /// <summary>The texture declares its alpha to be for blending.</summary>
    public bool DeclaresAlphaTexture { get; init; }
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

    /// <summary>
    /// The textures this rig's materials bind, with the engine-facing intent for each.
    /// </summary>
    /// <remarks>
    /// <b>Added because a UE5 import run proved the gap.</b> The intent was already exported in the
    /// scene JSON the Blender path consumes, but this manifest is a separate document and is what
    /// <c>tools/ue5/import_bioshock.py</c> reads, so an importer had no way to know that a normal
    /// map is not colour. Unit tests could not have caught that: both documents were individually
    /// correct.
    /// </remarks>
    public IReadOnlyList<FbxTextureEntry> Textures { get; init; } = [];

    /// <summary>
    /// Authored material parameters and slot bindings. Texture files remain relative to the
    /// manifest; unknown blend ordinals and animator timing remain carried, not interpreted.
    /// </summary>
    public IReadOnlyList<SceneMaterial> Materials { get; init; } = [];

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
