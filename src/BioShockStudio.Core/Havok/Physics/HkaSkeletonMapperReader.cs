using BioShockStudio.Core.Havok.Objects;
using BioShockStudio.Core.Havok.Packfile;

namespace BioShockStudio.Core.Havok.Physics;

/// <summary>
/// Reads <c>hkaSkeletonMapper</c> — the bone-index correspondence between two skeletons, closing the
/// gap <see cref="HkaRagdollInstanceReader"/> left open: a ragdoll's own skeleton is not the 73-bone
/// animation skeleton, so nothing before this reader could say <i>which named animation bone</i> a
/// given rigid body/capsule belongs to.
/// <para>
/// <b>CONFIRMED_BYTES</b> against <c>AggressorBabyJane</c>'s two mappers. Both resolved
/// <c>SkeletonA</c>/<c>SkeletonB</c> to real, class-named, bone-counted <c>hkaSkeleton</c> objects —
/// one mapper is `73-bone "Bip01"` → `17-bone "Ragdoll_Bip01 Pelvis01"`, the other is close to (not
/// exactly) the inverse. Their <c>SimpleMappings</c> confirm the correspondence structurally: 20 of
/// the 73→17 direction's 21 entries have an exact reverse counterpart in the 17→73 direction's 29
/// (mapper one's entry <c>[0]</c> is <c>(boneA: 65, boneB: 2)</c>, mapper two's entry <c>[1]</c> is
/// <c>(boneA: 2, boneB: 65)</c> — the same correspondence read both ways). <b>The one exception is a
/// real, understood asymmetry, not reader error</b>: bone 4 also maps to ragdoll bone 1 in the 73→17
/// direction with no reverse entry — ragdoll bone 1 is plausibly one of the 17→73 mapper's 42
/// separately-counted "unmapped bones" (<see cref="SkeletonMapper.UnmappedBoneCount"/>) rather than a
/// simple mapping, i.e. the sparser direction still names a nearest bone where the richer direction
/// considers it genuinely unmapped. Every <c>BoneA</c>/<c>BoneB</c> value across all entries falls
/// inside its own skeleton's real bone count (0–72 for the 73-bone side, 0–16 for the 17-bone side).
/// </para>
/// </summary>
public static class HkaSkeletonMapperReader
{
    public const string ClassName = "hkaSkeletonMapper";

    /// <summary>
    /// <c>hkaSkeletonMapperData</c> is embedded (not a pointer) at <c>hkaSkeletonMapper</c>'s own
    /// <c>m_mapping</c> field, and is itself padded to a 16-byte boundary after the 8-byte
    /// <c>hkReferencedObject</c> header — confirmed because <c>+8</c>/<c>+12</c> carry no fixup of
    /// either kind on either mapper checked, while <c>+16</c> always does.
    /// </summary>
    private const int MappingDataOffset = 16;

    private const int SkeletonAOffset = MappingDataOffset + 0;
    private const int SkeletonBOffset = MappingDataOffset + 4;
    private const int PartitionMapOffset = MappingDataOffset + 8;
    private const int SimpleMappingPartitionRangesOffset = MappingDataOffset + 20;
    private const int ChainMappingPartitionRangesOffset = MappingDataOffset + 32;
    private const int SimpleMappingsOffset = MappingDataOffset + 44;
    private const int ChainMappingsOffset = MappingDataOffset + 56;
    private const int UnmappedBonesOffset = MappingDataOffset + 68;

    /// <summary><c>hkaSkeletonMapperData::SimpleMapping</c>: two bone indices plus a 48-byte transform.</summary>
    private const int SimpleMappingStride = 64;

    public static SkeletonMapper Read(HavokPackfile packfile, HavokSection section, int objectOffset) => new()
    {
        SkeletonA = packfile.ResolvePointerField(section, objectOffset + SkeletonAOffset),
        SkeletonB = packfile.ResolvePointerField(section, objectOffset + SkeletonBOffset),
        SimpleMappings = ReadSimpleMappings(section, objectOffset + SimpleMappingsOffset),
        ChainMappingCount = section.ReadArray(objectOffset + ChainMappingsOffset).Count,
        UnmappedBoneCount = section.ReadArray(objectOffset + UnmappedBonesOffset).Count,
    };

    private static IReadOnlyList<(short BoneA, short BoneB)> ReadSimpleMappings(HavokSection section, int arrayFieldOffset)
    {
        var array = section.ReadArray(arrayFieldOffset);
        if (array.IsEmpty) return [];

        var result = new (short, short)[array.Count];
        for (int i = 0; i < result.Length; i++)
        {
            int entryOffset = array.DataOffset!.Value + i * SimpleMappingStride;
            result[i] = (section.ReadInt16(entryOffset), section.ReadInt16(entryOffset + 2));
        }
        return result;
    }
}

/// <summary>
/// Decoded <c>hkaSkeletonMapper</c>: a bone-index correspondence from <see cref="SkeletonA"/> to
/// <see cref="SkeletonB"/>. <see cref="SimpleMappings"/> is a one-bone-to-one-bone correspondence;
/// chain mappings (a range of bones on one side to a range on the other) are counted but not
/// individually decoded here.
/// </summary>
public sealed record SkeletonMapper
{
    public required (HavokSection Section, int Offset)? SkeletonA { get; init; }
    public required (HavokSection Section, int Offset)? SkeletonB { get; init; }
    public required IReadOnlyList<(short BoneA, short BoneB)> SimpleMappings { get; init; }
    public required int ChainMappingCount { get; init; }
    public required int UnmappedBoneCount { get; init; }
}
