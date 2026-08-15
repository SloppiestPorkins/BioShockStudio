using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Havok.Objects;
using BioShockStudio.Core.Skeleton;

namespace BioShockStudio.Core.Havok.Skeleton;

/// <summary>
/// Reads <c>hkaSkeleton</c> (Havok 2012.2.0-r1, 4-byte pointers).
/// <para>
/// CONFIRMED_BYTES against <c>UAPW_NEWPlayerHands</c>: 47 bones, and the reference-pose array ends
/// exactly on the section's data boundary, which validates the whole field layout at once.
/// </para>
/// <code>
/// +0   hkReferencedObject   vtable, memSizeAndFlags, referenceCount
/// +8   const char*          m_name
/// +12  hkArray&lt;hkInt16&gt;     m_parentIndices
/// +24  hkArray&lt;hkaBone&gt;     m_bones
/// +36  hkArray&lt;hkQsTransform&gt; m_referencePose
/// +48  hkArray&lt;hkReal&gt;      m_referenceFloats
/// +60  hkArray&lt;const char*&gt; m_floatSlots
/// +72  hkArray&lt;...&gt;         m_localFrames
/// +84  hkArray&lt;Partition&gt;   m_partitions
/// </code>
/// <c>hkaBone</c> is 8 bytes: <c>const char* m_name</c> then <c>hkBool m_lockTranslation</c>, padded.
/// </summary>
public static class HkaSkeletonReader
{
    public const string ClassName = "hkaSkeleton";

    private const int NameOffset = 8;
    private const int ParentIndicesOffset = 12;
    private const int BonesOffset = 24;
    private const int ReferencePoseOffset = 36;
    private const int PartitionsOffset = 84;
    private const int BoneStride = 8;

    /// <summary>A named, contiguous range of bones — Havok's unit for sampling part of a skeleton.</summary>
    /// <param name="Name">May be empty; the pointer is optional.</param>
    public readonly record struct SkeletonPartition(string Name, short StartBoneIndex, short BoneCount);

    /// <summary>
    /// The skeleton's partitions, if it declares any.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <c>hkaSkeleton::Partition</c> is <c>{ const char* m_name; hkInt16 m_startBoneIndex;
    /// hkInt16 m_numBones; }</c> — 8 bytes with padding.
    /// </para>
    /// <para>
    /// <b>Read and reported, not used.</b> This exists to measure a specific question: the four fire
    /// animations of <c>docs/HANDOFF.md</c> §6.0c drive a contiguous ascending subset of
    /// <c>AggressorBabyJane</c>'s bones, which is what a partition is, and nobody had checked whether
    /// the shipped skeletons declare any. Nothing decides anything on this yet.
    /// </para>
    /// </remarks>
    public static IReadOnlyList<SkeletonPartition> ReadPartitions(HavokSection section, int objectOffset)
    {
        var array = section.ReadArray(objectOffset + PartitionsOffset);
        if (array.IsEmpty || array.DataOffset is null) return [];

        var result = new SkeletonPartition[array.Count];
        for (int i = 0; i < result.Length; i++)
        {
            int at = array.DataOffset.Value + i * 8;
            result[i] = new SkeletonPartition(
                section.ReadStringPointer(at) ?? string.Empty,
                section.ReadInt16(at + 4),
                section.ReadInt16(at + 6));
        }

        return result;
    }

    public static BioShockSkeleton Read(HavokSection section, int objectOffset)
    {
        string name = section.ReadStringPointer(objectOffset + NameOffset) ?? string.Empty;

        var parentIndices = section.ReadArray(objectOffset + ParentIndicesOffset);
        var bones = section.ReadArray(objectOffset + BonesOffset);
        var referencePose = section.ReadArray(objectOffset + ReferencePoseOffset);

        int boneCount = bones.Count;
        if (boneCount == 0)
            throw new InvalidDataException("hkaSkeleton has no bones.");

        // Havok keeps these three arrays index-parallel. If they ever disagree the object is not
        // what we think it is, so fail loudly rather than reading past the end of one of them.
        if (parentIndices.Count != boneCount || referencePose.Count != boneCount)
        {
            throw new InvalidDataException(
                $"hkaSkeleton arrays disagree: {boneCount} bones, {parentIndices.Count} parents, " +
                $"{referencePose.Count} reference-pose transforms.");
        }

        if (bones.DataOffset is null || parentIndices.DataOffset is null || referencePose.DataOffset is null)
            throw new InvalidDataException("hkaSkeleton has an unresolved array pointer.");

        var result = new BioShockBone[boneCount];
        for (int i = 0; i < boneCount; i++)
        {
            int boneOffset = bones.DataOffset.Value + i * BoneStride;
            int poseOffset = referencePose.DataOffset.Value + i * HavokSection.QsTransformSize;
            var (translation, rotation, scale) = section.ReadQsTransform(poseOffset);

            result[i] = new BioShockBone
            {
                OriginalBoneIndex = i,
                Name = section.ReadStringPointer(boneOffset) ?? $"bone_{i}",
                ParentIndex = section.ReadInt16(parentIndices.DataOffset.Value + i * 2),
                LocalTranslation = translation,
                LocalRotation = rotation,
                LocalScale = scale,
                LockTranslation = section.ReadByte(boneOffset + 4) != 0,
            };
        }

        // The reference pose above is Havok's, in the game's basis. Converting here means every
        // consumer of a BioShockSkeleton — preview, FBX, Blender, binding — sees one basis. See
        // Coordinates/GameBasis.
        return GameBasis.Convert(new BioShockSkeleton
        {
            Name = name,
            Bones = result,
            SourceSection = section.Tag,
            SourceOffset = objectOffset,
        });
    }
}
