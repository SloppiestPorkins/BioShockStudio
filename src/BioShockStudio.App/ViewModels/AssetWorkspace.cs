using System.Collections.Generic;
using BioShockStudio.Core.Services;

namespace BioShockStudio.App.ViewModels;

/// <summary>
/// The browser's top-level split: assets that move, assets that do not, and the level.
/// </summary>
/// <remarks>
/// <para>
/// The one distinction that changes how an asset is worked with is <b>whether it carries a rig</b>.
/// A skinned mesh has a skeleton, animation sets, sockets and attachments, and its preview has a
/// transport; a static mesh has none of that and its whole story is geometry and materials. Those
/// were previously nine categories in one list where the two kinds sat interleaved.
/// </para>
/// <para>
/// Textures and materials sit with the static assets rather than getting a workspace of their own.
/// They are shared by both kinds, so any placement is a choice rather than a fact — and this one is
/// at least consistent: nothing in the Animated workspace is anything but a rig, its parts, or its
/// motion.
/// </para>
/// </remarks>
public enum AssetWorkspace
{
    /// <summary>Rigs, their meshes, and their motion.</summary>
    Animated,

    /// <summary>Geometry that does not move, and the surfaces everything is painted with.</summary>
    Static,

    /// <summary>Whole maps.</summary>
    Level,

    /// <summary>Dialogue, ambience and music stored in FMOD stream banks.</summary>
    Audio,
}

/// <summary>Which categories each workspace shows, in the order they are listed.</summary>
public static class AssetWorkspaces
{
    /// <summary>
    /// Rigged assets: the first-person set, characters, the weapons that carry their own skeletons,
    /// every skeletal mesh, and the animations themselves.
    /// </summary>
    public static readonly IReadOnlyList<AssetCategory> Animated =
    [
        AssetCategory.FirstPerson,
        AssetCategory.Characters,
        AssetCategory.Weapons,
        AssetCategory.SkeletalMeshes,
        AssetCategory.Animations,
    ];

    /// <summary>Static geometry, surface data, and native package audio.</summary>
    public static readonly IReadOnlyList<AssetCategory> Static =
    [
        AssetCategory.StaticMeshes,
        AssetCategory.Props,
        AssetCategory.Materials,
        AssetCategory.Textures,
        AssetCategory.Sounds,
    ];

    public static IReadOnlyList<AssetCategory> For(AssetWorkspace workspace) => workspace switch
    {
        AssetWorkspace.Animated => Animated,
        AssetWorkspace.Static => Static,
        _ => [],
    };

    /// <summary>The label for the "no particular category" row, which differs per workspace.</summary>
    /// <remarks>
    /// "Everything" would be a lie inside a workspace that shows half the game. The row means
    /// "everything in this workspace", and it says so.
    /// </remarks>
    public static string EverythingLabel(AssetWorkspace workspace) => workspace switch
    {
        AssetWorkspace.Animated => "All rigged assets",
        AssetWorkspace.Static => "All static assets",
        _ => "Everything",
    };

    /// <summary>
    /// Every category the two asset workspaces cover, so a category cannot be silently dropped by
    /// belonging to neither.
    /// </summary>
    public static IEnumerable<AssetCategory> AllCovered => [.. Animated, .. Static];
}
