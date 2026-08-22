using BioShockStudio.Core.Havok.Objects;
using BioShockStudio.Core.Havok.Packfile;

namespace BioShockStudio.Core.Havok.Physics;

/// <summary>
/// Reads <c>hkaRagdollInstance</c> — the object that ties a character's rigid bodies, constraints and
/// bone indices together into one ragdoll.
/// <para>
/// <b>CONFIRMED_BYTES</b> against <c>AggressorBabyJane</c>'s one ragdoll: every field agrees with the
/// SDK header, not just the offsets. <c>m_rigidBodies</c> resolves to exactly 17 elements, matching
/// this character's independently-counted 17 <c>hkpRigidBody</c>/<c>hkpCapsuleShape</c> pairs
/// (<c>docs/research/havok-physics.md</c>); <c>m_constraints</c> resolves to exactly 16, matching the
/// independently-counted <c>hkpConstraintInstance</c> total; the array data for <c>m_rigidBodies</c>
/// sits immediately after the object (its resolved pointer is exactly <c>objectOffset + 48</c>, the
/// object's own size) and its first four entries are global fixups landing exactly on the offsets of
/// the first four <c>hkpRigidBody</c> objects found independently via
/// <see cref="HavokPackfile.EnumerateObjects"/>, in order. <c>m_skeleton</c> resolves to a real,
/// class-named <c>hkaSkeleton</c> object (this ragdoll's own 17-bone skeleton, not the 73-bone
/// animation skeleton the rest of this project already exposes as <c>AnimationPackage.Skeleton</c> —
/// they are different objects; correlating the two, e.g. via the wrapper's <c>hkaSkeletonMapper</c>
/// objects, is not attempted here).
/// </para>
/// </summary>
public static class HkaRagdollInstanceReader
{
    public const string ClassName = "hkaRagdollInstance";

    private const int RigidBodiesOffset = 8;
    private const int ConstraintsOffset = 20;
    private const int BoneToRigidBodyMapOffset = 32;
    private const int SkeletonOffset = 44;

    public static RagdollInstance Read(HavokPackfile packfile, HavokSection section, int objectOffset) => new()
    {
        RigidBodies = ReadPointerArray(packfile, section, objectOffset + RigidBodiesOffset),
        Constraints = ReadPointerArray(packfile, section, objectOffset + ConstraintsOffset),
        BoneToRigidBodyMap = ReadIntArray(section, objectOffset + BoneToRigidBodyMapOffset),
        Skeleton = packfile.ResolvePointerField(section, objectOffset + SkeletonOffset),
    };

    private static IReadOnlyList<(HavokSection Section, int Offset)> ReadPointerArray(
        HavokPackfile packfile, HavokSection section, int arrayFieldOffset)
    {
        var array = section.ReadArray(arrayFieldOffset);
        if (array.IsEmpty) return [];

        var result = new List<(HavokSection, int)>(array.Count);
        for (int i = 0; i < array.Count; i++)
        {
            var target = packfile.ResolvePointerField(section, array.DataOffset!.Value + i * 4);
            if (target is not null) result.Add(target.Value);
        }
        return result;
    }

    private static int[] ReadIntArray(HavokSection section, int arrayFieldOffset)
    {
        var array = section.ReadArray(arrayFieldOffset);
        if (array.IsEmpty) return [];

        var result = new int[array.Count];
        for (int i = 0; i < result.Length; i++)
            result[i] = section.ReadInt32(array.DataOffset!.Value + i * 4);
        return result;
    }
}

/// <summary>Decoded <c>hkaRagdollInstance</c>: a character's ragdoll object graph, resolved.</summary>
public sealed record RagdollInstance
{
    /// <summary>Each rigid body's location, in <c>m_rigidBodies</c> array order.</summary>
    public required IReadOnlyList<(HavokSection Section, int Offset)> RigidBodies { get; init; }

    /// <summary>Each constraint's location, in <c>m_constraints</c> array order.</summary>
    public required IReadOnlyList<(HavokSection Section, int Offset)> Constraints { get; init; }

    /// <summary>
    /// Index into <see cref="RigidBodies"/> for each bone of this ragdoll's own skeleton
    /// (<see cref="Skeleton"/>), <b>not</b> the animation skeleton — a bone with no rigid body of its
    /// own is not represented here at all (the array is one entry per rigid-body-bearing bone, not
    /// one per skeleton bone).
    /// </summary>
    public required IReadOnlyList<int> BoneToRigidBodyMap { get; init; }

    /// <summary>This ragdoll's own skeleton (<c>hkaSkeleton</c>), if the pointer resolved.</summary>
    public required (HavokSection Section, int Offset)? Skeleton { get; init; }
}
