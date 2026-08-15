using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Assets;

/// <summary>One upgrade a weapon can be fitted with.</summary>
/// <param name="Tier">
/// The tier letter the game gives it — <c>A</c>, <c>B</c>, or <c>Balt</c> for the pistol's
/// alternative second tier.
/// </param>
/// <param name="Group">
/// The group the mesh lives in. Usually the weapon's own; the two upgrades that carry their own rig
/// are in a group of their own, which is why they were missing.
/// </param>
public sealed record WeaponUpgrade(string MeshObject, string Tier, string Group, string ClassName)
{
    /// <summary>True when the upgrade has its own skeleton rather than being a static part.</summary>
    public bool IsSkeletal => ClassName == AssetClasses.SkeletalMesh;

    public override string ToString() => $"{MeshObject} (tier {Tier})";
}

/// <summary>
/// The upgrade meshes belonging to a player weapon.
/// </summary>
/// <remarks>
/// <para>
/// Every player weapon has upgrade tiers, and the game names their meshes with a two-letter weapon
/// prefix: <c>PI_UpgradeA</c>, <c>SG_UpgradeB</c>, <c>TG_upgradeA</c>, <c>XB_UpgradeB_Mesh</c>.
/// Thirteen ship across the six weapons.
/// </para>
/// <para>
/// <b>Eleven of the thirteen sit in their weapon's own group</b>, so anything resolving by group
/// already found them — which is why some weapons showed upgrades and others did not. The two that
/// did not, <c>SG_UpgradeB</c> and <c>XB_UpgradeB_Mesh</c>, are each in a group of their own, and
/// they are exactly the two that carry their own skeleton.
/// </para>
/// <para>
/// <c>CORROBORATED</c>, not guessed: the prefix-to-weapon mapping below is confirmed by group
/// membership for 11 of the 13, so applying the same mapping to the remaining 2 follows the game's
/// own evidence rather than a resemblance. Anything not matching a known prefix is not claimed as an
/// upgrade at all.
/// </para>
/// </remarks>
public static class WeaponUpgrades
{
    /// <summary>Weapon-group name to the mesh-name prefix the game uses for its upgrades.</summary>
    private static readonly (string Group, string Prefix)[] Prefixes =
    [
        ("WP_Pistol", "PI_"),
        ("WP_Shotgun", "SG_"),
        ("WP_TommyGun", "TG_"),
        ("WP_Crossbow", "XB_"),
        ("WP_ChemicalThrower", "CT_"),
        ("WP_GrenadeLauncher", "GL_"),
    ];

    private const string Marker = "upgrade";

    /// <summary>The mesh-name prefix a weapon group's upgrades use, or null if it has none.</summary>
    public static string? PrefixFor(string group) =>
        Prefixes.FirstOrDefault(p => string.Equals(p.Group, group, StringComparison.OrdinalIgnoreCase)).Prefix;

    /// <summary>The weapon group an upgrade mesh belongs to, or null when the name is not one.</summary>
    public static string? WeaponFor(string meshObject)
    {
        if (meshObject.IndexOf(Marker, StringComparison.OrdinalIgnoreCase) < 0) return null;

        foreach (var (group, prefix) in Prefixes)
        {
            if (meshObject.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)) return group;
        }

        return null;
    }

    /// <summary>
    /// Every upgrade mesh for a weapon, wherever in the package it lives.
    /// </summary>
    /// <remarks>
    /// Ordered by tier so a caller lists them the way the game does. The weapon's base mesh is not
    /// included — this is what can be added to it, not the thing itself.
    /// </remarks>
    public static IReadOnlyList<WeaponUpgrade> For(BioShockPackage package, string weaponGroup)
    {
        if (PrefixFor(weaponGroup) is null) return [];

        var found = new List<WeaponUpgrade>();

        foreach (var export in package.Exports)
        {
            if (export.SerialSize <= 0) continue;

            string className = package.GetClassName(export);
            if (!MeshGeometryReader.IsMeshClass(className)) continue;

            if (!string.Equals(WeaponFor(export.ObjectName), weaponGroup, StringComparison.OrdinalIgnoreCase))
                continue;

            found.Add(new WeaponUpgrade(
                export.ObjectName,
                TierOf(export.ObjectName),
                AssetContextResolver.TopLevelGroup(package, export),
                className));
        }

        return [.. found
            .GroupBy(u => u.MeshObject, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.First())
            .OrderBy(u => u.Tier, StringComparer.OrdinalIgnoreCase)];
    }

    /// <summary>
    /// The tier letter from a name like <c>PI_UpgradeBalt</c> — everything after "upgrade", with a
    /// trailing <c>_Mesh</c> removed. Empty when the name carries none.
    /// </summary>
    private static string TierOf(string meshObject)
    {
        int at = meshObject.IndexOf(Marker, StringComparison.OrdinalIgnoreCase);
        if (at < 0) return string.Empty;

        string tail = meshObject[(at + Marker.Length)..];
        if (tail.EndsWith("_Mesh", StringComparison.OrdinalIgnoreCase))
            tail = tail[..^"_Mesh".Length];

        return tail.TrimStart('_');
    }
}
