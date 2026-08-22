using BioShockStudio.Core.Havok.Objects;
using BioShockStudio.Core.Havok.Packfile;

namespace BioShockStudio.Core.Havok.Physics;

/// <summary>
/// Reads <c>hkpConstraintInstance</c> — which two rigid bodies a joint connects, and where its real
/// joint data (e.g. <c>hkpRagdollConstraintData</c>) lives.
/// <para>
/// <b>CONFIRMED_BYTES</b> against all 16 of <c>AggressorBabyJane</c>'s constraints, 0 disagreements:
/// <c>Data</c> resolves to a real <c>hkpRagdollConstraintData</c> on every one, and both
/// <c>EntityA</c>/<c>EntityB</c> resolve to real <c>hkpRigidBody</c> objects on every one
/// (<c>HavokPhysicsTests.EveryConstraintConnectsTwoRealRigidBodiesToRealConstraintData</c>). The
/// resulting graph is coherent, not just individually plausible: every constraint's second entity is
/// rigid body 0 (this character's pelvis, per <c>docs/research/havok-physics.md</c>) or another body
/// already connected to it, which is the shape a real skeletal hierarchy radiating from a root
/// produces, not a set of unrelated pairs.
/// </para>
/// <para>
/// The class's own field list (<c>hkpConstraintInstance.h</c>) explained an assumption from earlier
/// in this investigation had been too strong: <c>m_owner</c> is marked <c>+nosave</c> but still
/// occupies its 4-byte slot at <c>+8</c> (as a permanently-null pointer, no fixup entry) rather than
/// being omitted from the layout — <c>+nosave</c> means "always written as a default," not always
/// "removed from the struct." The two are indistinguishable when the omitted field is immediately
/// followed by an alignment-padded field of its own (as in <c>hkaAnimatedReferenceFrame</c>'s
/// <c>m_frameType</c>, elsewhere in this project), which is why it went unnoticed until a field with
/// no such padding neighbour (this one) made the difference in this class's initial byte dump.
/// </para>
/// <para>
/// <b>Not attempted here</b>: <c>Priority</c>/<c>WantRuntime</c>/<c>DestructionRemapInfo</c> (small
/// fields, +24..+26, not needed for topology) and the real joint payload
/// (<c>hkpRagdollConstraintData::Atoms</c> — seven nested "atom" structs holding limits, motor
/// parameters and per-body local transforms), which is the largest remaining piece of the whole
/// physics investigation. See <c>docs/research/havok-physics.md</c>.
/// </para>
/// </summary>
public static class HkpConstraintInstanceReader
{
    public const string ClassName = "hkpConstraintInstance";

    private const int DataOffset = 12;
    private const int EntityAOffset = 20;
    private const int EntityBOffset = 24;

    public static ConstraintInstance Read(HavokPackfile packfile, HavokSection section, int objectOffset) => new()
    {
        Data = packfile.ResolvePointerField(section, objectOffset + DataOffset),
        EntityA = packfile.ResolvePointerField(section, objectOffset + EntityAOffset),
        EntityB = packfile.ResolvePointerField(section, objectOffset + EntityBOffset),
    };
}

/// <summary>Decoded <c>hkpConstraintInstance</c>: which two bodies a joint connects, and its real joint data.</summary>
public sealed record ConstraintInstance
{
    public required (HavokSection Section, int Offset)? Data { get; init; }
    public required (HavokSection Section, int Offset)? EntityA { get; init; }
    public required (HavokSection Section, int Offset)? EntityB { get; init; }
}
