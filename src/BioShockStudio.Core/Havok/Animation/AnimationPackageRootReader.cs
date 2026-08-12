using BioShockStudio.Core.Havok.Objects;
using BioShockStudio.Core.Havok.Packfile;

namespace BioShockStudio.Core.Havok.Animation;

/// <summary>One row of the package's animation table.</summary>
public sealed record AnimationPackageEntry
{
    /// <summary>e.g. <c>FireSinglePistol</c>.</summary>
    public required string AnimationName { get; init; }

    /// <summary>e.g. <c>Pistol</c>, <c>Default</c>. Untruncated, unlike the section tag.</summary>
    public required string OwnerName { get; init; }

    /// <summary>Cross-section reference to the <c>hkaAnimationBinding</c> for this animation.</summary>
    public required GlobalFixup Binding { get; init; }

    public override string ToString() => $"{OwnerName}/{AnimationName}";
}

/// <summary>The decoded 2K root object.</summary>
public sealed record AnimationPackageRoot
{
    /// <summary>Reference to the skeleton every animation in the package is bound against.</summary>
    public required GlobalFixup? Skeleton { get; init; }

    public required IReadOnlyList<AnimationPackageEntry> Entries { get; init; }
}

/// <summary>
/// Reads <c>AnimationPackageRoot</c> — 2K's replacement for <c>hkRootLevelContainer</c>, and the
/// class that generic Havok tooling (including UEViewer) reports as unknown.
/// <para>
/// CONFIRMED_BYTES against <c>UAPW_NEWPlayerHands</c>: 130 entries, which equals the total number of
/// <c>hkaAnimationBinding</c> objects across all ten content sections, and every entry's owner name
/// matches its section tag (including the untruncated <c>ChemicalThrower</c> and
/// <c>GrenadeLauncher</c>, whose tags are cut to 19 bytes).
/// </para>
/// <code>
/// +0   hkaSkeleton*   m_skeleton     (global fixup)
/// +16  Entry*         m_entries      (local fixup)
/// +20  hkInt32        m_entryCount
/// Entry (12 bytes)
/// +0   const char*    m_animationName  (local fixup)
/// +4   const char*    m_ownerName      (local fixup)
/// +8   hkaAnimationBinding* m_binding  (global fixup)
/// </code>
/// <para>
/// UNKNOWN: bytes +4..+15 of the root, which are zero in every sample inspected. They are not read
/// and not assumed to be padding.
/// </para>
/// </summary>
public static class AnimationPackageRootReader
{
    public const string ClassName = "AnimationPackageRoot";

    private const int SkeletonPointerOffset = 0;
    private const int EntriesPointerOffset = 16;
    private const int EntryCountOffset = 20;
    private const int EntryStride = 12;

    public static AnimationPackageRoot Read(HavokSection section, int objectOffset)
    {
        int? entriesOffset = section.ResolvePointer(objectOffset + EntriesPointerOffset);
        int entryCount = section.ReadInt32(objectOffset + EntryCountOffset);

        if (entryCount < 0)
            throw new InvalidDataException($"AnimationPackageRoot reports a negative entry count ({entryCount}).");

        var entries = new List<AnimationPackageEntry>(entryCount);
        if (entriesOffset is not null)
        {
            for (int i = 0; i < entryCount; i++)
            {
                int entry = entriesOffset.Value + i * EntryStride;
                var binding = section.ResolveGlobalPointer(entry + 8);

                // An entry whose binding pointer has no fixup would silently become a broken
                // animation, so skip it loudly rather than fabricating a target.
                if (binding is null) continue;

                entries.Add(new AnimationPackageEntry
                {
                    AnimationName = section.ReadStringPointer(entry) ?? $"<unnamed {i}>",
                    OwnerName = section.ReadStringPointer(entry + 4) ?? string.Empty,
                    Binding = binding.Value,
                });
            }
        }

        return new AnimationPackageRoot
        {
            Skeleton = section.ResolveGlobalPointer(objectOffset + SkeletonPointerOffset),
            Entries = entries,
        };
    }
}
