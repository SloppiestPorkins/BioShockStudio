using System.Numerics;
using BioShockStudio.Core.Havok.Objects;

namespace BioShockStudio.Core.Havok.Physics;

/// <summary>
/// Reads <c>hkpCapsuleShape</c> — a capsule collision volume defined by two points and a radius.
/// <para>
/// <b>CONFIRMED_BYTES</b>, all 17 capsules on <c>AggressorBabyJane</c>'s ragdoll agreeing, 0
/// disagreements: <c>m_vertexA.w</c> and <c>m_vertexB.w</c> both equal <c>m_radius</c> exactly, on
/// every one — the SDK header's own description of the vertices as <c>hkSphere</c>s (position plus a
/// radius in the same four floats) rather than plain points. Every decoded radius (0.06–0.24) and
/// capsule length (0.09–0.92) is a plausible human-body proportion <b>in metres</b> — three orders of
/// magnitude smaller than the same rig's mesh/animation data, which is centimetre-scaled. That is
/// expected, not a bug: Havok physics content is conventionally authored in metres regardless of the
/// art scale, and nothing here should be mixed with mesh/animation coordinates without an explicit,
/// separately-confirmed scale factor.
/// </para>
/// </summary>
public static class HkpCapsuleShapeReader
{
    public const string ClassName = "hkpCapsuleShape";

    /// <summary>
    /// <c>hkReferencedObject</c> (8 bytes) + <c>hkcdShape</c>'s own fields, padded to a 16-byte
    /// boundary, land <c>hkpConvexShape::m_radius</c> here. The intervening classes
    /// (<c>hkpShapeBase</c>, <c>hkpShape</c>, <c>hkpSphereRepShape</c>) add no data fields of their
    /// own between the base header and this one, confirmed by this offset agreeing across all 17
    /// samples rather than assumed from the header alone.
    /// </summary>
    private const int RadiusOffset = 16;

    private const int VertexAOffset = 32;
    private const int VertexBOffset = 48;

    public static CapsuleShape Read(HavokSection section, int objectOffset) => new()
    {
        Radius = section.ReadSingle(objectOffset + RadiusOffset),
        VertexA = ReadVector3(section, objectOffset + VertexAOffset),
        VertexB = ReadVector3(section, objectOffset + VertexBOffset),
    };

    private static Vector3 ReadVector3(HavokSection section, int offset) => new(
        section.ReadSingle(offset), section.ReadSingle(offset + 4), section.ReadSingle(offset + 8));
}

/// <summary>
/// Decoded <c>hkpCapsuleShape</c>: a capsule collision volume in the owning rigid body's local space,
/// in Havok's native (metre) scale.
/// </summary>
public sealed record CapsuleShape
{
    public required float Radius { get; init; }
    public required Vector3 VertexA { get; init; }
    public required Vector3 VertexB { get; init; }

    /// <summary>Distance between the two end-sphere centres — the capsule's cylindrical length.</summary>
    public float Length => Vector3.Distance(VertexA, VertexB);
}
