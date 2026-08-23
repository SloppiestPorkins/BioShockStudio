using System.Buffers.Binary;
using System.Numerics;
using BioShockStudio.Core.Havok.Objects;
using BioShockStudio.Core.Havok.Packfile;

namespace BioShockStudio.Core.Havok.Physics;

/// <summary>
/// Reads <c>hkpRigidBody</c> — currently just the one field confirmed against real bytes.
/// <para>
/// <b>CONFIRMED_BYTES</b>: <c>m_collidable.m_shape</c> resolves to a real <c>hkpCapsuleShape</c> on
/// all 17 of <c>AggressorBabyJane</c>'s rigid bodies, 0 disagreements. This is the field the
/// inheritance chain predicts should be reachable soonest (<c>hkpEntity</c> → <c>hkpWorldObject</c>
/// → <c>m_collidable</c>, an embedded <c>hkpLinkedCollidable</c> whose own only field is
/// <c>+nosave</c> → its base <c>hkpCollidable</c> → its base <c>hkpCdBody</c>, which owns the shape
/// pointer) and it lands exactly where a straightforward reading of those headers places it.
/// </para>
/// <para>
/// <b>Deliberately not attempted here</b>: mass, inverse inertia, linear/angular velocity, friction,
/// restitution, and the body's own world-space transform (position/rotation). `hkpEntity`'s full
/// class hierarchy is materially deeper than every other class this project has decoded so far —
/// <c>hkpWorldObject</c> → <c>hkpCollidable</c> → <c>hkpCdBody</c>, plus an embedded
/// <c>hkpMaxSizeMotion</c> (effectively <c>hkpMotion</c>: a 64-byte <c>hkTransform</c>, an
/// <c>hkVector4</c> packing inverse inertia and inverse mass together, velocities, damping) — each
/// with its own mix of real and <c>+nosave</c>/<c>+serialized(false)</c> fields to work out. A first
/// empirical byte dump found several plausible-looking candidates (a `0.5`/`0.1` pair that could be
/// friction/restitution, a `(x,y,z,w)` quadruple close to unit length that could be a rotation
/// component), and a cross-reference attempt against this rig's own bind-pose bone translation (using
/// the bone this rigid body maps to via <see cref="HkaRagdollInstanceReader"/> +
/// <see cref="HkaSkeletonMapperReader"/>) came up inconclusive — the tested bone's local translation
/// happened to be exactly zero, and a rigid body's own transform is in world space, not
/// parent-relative, so the two aren't directly comparable without composing the full bone chain.
/// Nothing here is promoted past "plausible, not cross-validated" — see
/// <c>docs/research/havok-physics.md</c> for the full record and a better cross-reference plan
/// (repeat the comparison against a bone whose translation is <i>not</i> zero, and compose the parent
/// chain rather than reading one bone in isolation).
/// </para>
/// </summary>
/// <summary>
/// A rigid body's world placement and mass properties, as the embedded motion stores them.
/// </summary>
public sealed record HkpRigidBodyMotion
{
    /// <summary>The three columns of <c>hkTransform</c>'s rotation, in order.</summary>
    public required Vector3 ColumnX { get; init; }

    public required Vector3 ColumnY { get; init; }
    public required Vector3 ColumnZ { get; init; }

    /// <summary>World-space position. <b>Metres</b>, like the capsules and unlike the mesh data.</summary>
    public required Vector3 Translation { get; init; }

    /// <summary>Inverse inertia about each principal axis.</summary>
    public required Vector3 InverseInertia { get; init; }

    /// <summary>Inverse mass. Zero would mean a fixed body; no shipped ragdoll body is fixed.</summary>
    public required float InverseMass { get; init; }

    /// <summary>
    /// Mass in kilograms, or zero when the body is <see cref="IsFixed"/>.
    /// </summary>
    /// <remarks>
    /// Every shipped simulated body carries a clean authored value — whole kilograms overwhelmingly
    /// (5, 10, 1, 30, 20, 60, 50 are the commonest in the game), with a handful of halves and a
    /// flower vase at 0.2 kg.
    /// </remarks>
    public float Mass => InverseMass > 0 ? 1f / InverseMass : 0f;

    /// <summary>
    /// True when the body has infinite mass — Havok's fixed/keyframed body.
    /// </summary>
    /// <remarks>
    /// <c>CONFIRMED_BYTES</c> and self-corroborating: the 40 bodies in the game with zero inverse
    /// mass belong to <c>LoadRoomDoorAnim</c>, <c>SecurityCameraSmall</c>,
    /// <c>SecurityCameraSmallWall</c> and <c>Wel_PlaneCrash</c> — doors, wall-mounted cameras and a
    /// scripted set-piece, which is exactly the set of things that should be anchored to the world
    /// rather than simulated. A misread offset would not sort itself into that category.
    /// <b>A UE5 bridge needs this distinction</b>: a fixed body becomes a kinematic constraint, not
    /// a simulated one.
    /// </remarks>
    public bool IsFixed => InverseMass == 0f;

    /// <summary>
    /// <c>hkMotionState::m_objectRadius</c> — the body's bounding radius.
    /// </summary>
    /// <remarks>
    /// Cross-validated against already-decoded data rather than eyeballed: it tracks the owning
    /// capsule's extent across all 17 bodies of the first character (the largest capsules carry the
    /// largest radii) and mirrors in the same left/right pairs the translations do.
    /// </remarks>
    public required float ObjectRadius { get; init; }

    /// <summary>Linear damping. Zero on every shipped body.</summary>
    public required float LinearDamping { get; init; }

    /// <summary>Angular damping. <c>0.0498</c> on every shipped body — the hkHalf encoding of 0.05.</summary>
    public required float AngularDamping { get; init; }

    /// <summary>
    /// Time scale for this body's integration. Exactly <c>1.0</c> on every shipped body.
    /// </summary>
    /// <remarks>
    /// This is the field that confirms the hkHalf decode: 1.0 is the Havok default, and reading
    /// exactly 1.0 out of a 16-bit half at a predicted offset is not something a wrong offset does.
    /// </remarks>
    public required float TimeFactor { get; init; }

    /// <summary>Linear velocity. Zero throughout — this is authored data, not a simulation snapshot.</summary>
    public required Vector3 LinearVelocity { get; init; }

    /// <summary>Angular velocity. Zero throughout, for the same reason.</summary>
    public required Vector3 AngularVelocity { get; init; }

    /// <summary>
    /// <c>hkpMaterial::m_friction</c>. Clean authored values — 0.5 and 0.2 in the game.
    /// </summary>
    public required float Friction { get; init; }

    /// <summary>
    /// <c>hkpMaterial::m_restitution</c>. Clean authored values — 0.1 and 1.0 in the game.
    /// </summary>
    public required float Restitution { get; init; }

    /// <summary>Determinant of the rotation basis: +1 for a proper rotation.</summary>
    public float Determinant => Vector3.Dot(ColumnX, Vector3.Cross(ColumnY, ColumnZ));

    /// <summary>True when the basis is orthonormal and right-handed.</summary>
    public bool IsProperRotation =>
        Math.Abs(ColumnX.Length() - 1f) < 0.01f
        && Math.Abs(ColumnY.Length() - 1f) < 0.01f
        && Math.Abs(ColumnZ.Length() - 1f) < 0.01f
        && Math.Abs(Vector3.Dot(ColumnX, ColumnY)) < 0.01f
        && Math.Abs(Vector3.Dot(ColumnX, ColumnZ)) < 0.01f
        && Math.Abs(Vector3.Dot(ColumnY, ColumnZ)) < 0.01f
        && Math.Abs(Determinant - 1f) < 0.01f;
}

public static class HkpRigidBodyReader
{
    public const string ClassName = "hkpRigidBody";

    /// <summary><c>hkpCollidable::m_shape</c>, reached via the embedded <c>hkpLinkedCollidable</c>.</summary>
    private const int ShapeOffset = 16;

    /// <summary>
    /// <c>hkMotionState::m_transform</c> — the first field of the motion state, which is itself a
    /// member of the embedded motion.
    /// </summary>
    /// <remarks>
    /// <b>Located by search, then confirmed by structure rather than by arithmetic.</b> Deriving
    /// this by hand through <c>hkpEntity</c> → <c>hkpWorldObject</c> → <c>hkpCollidable</c> →
    /// <c>hkpCdBody</c> plus the embedded <c>hkpMaxSizeMotion</c>, each with its own mix of real
    /// and <c>+nosave</c> fields, is exactly the kind of offset arithmetic that produces a
    /// confident wrong answer. Instead every 16-byte-aligned position was tested for an orthonormal
    /// 3x3 basis — a signature random float data does not produce — and <b>exactly one offset hits,
    /// on all 17 of <c>AggressorBabyJane</c>'s bodies</b>.
    /// </remarks>
    private const int TransformOffset = 240;

    /// <summary>Translation is the fourth column of <c>hkTransform</c>.</summary>
    private const int TranslationOffset = TransformOffset + 48;

    /// <summary>
    /// <c>hkpMotion::m_inertiaAndMassInv</c> — inverse inertia in xyz, inverse mass in w.
    /// </summary>
    /// <remarks>
    /// Found the same way: the first offset after the motion state where all four components are
    /// positive and finite on every body. What confirms it is not plausibility but arithmetic —
    /// <c>1/w</c> comes out as <b>exactly round kilogram values</b> (60, 30, 10, 5, 1) on every
    /// shipped body.
    /// </remarks>
    private const int InertiaAndMassInvOffset = 416;

    /// <summary>
    /// The rest of the motion block, <b>derived</b> from the headers once the two anchors above were
    /// confirmed, rather than searched for.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The derivation is exact and self-checking: <c>hkMotionState</c> is <c>hkTransform</c> (64) +
    /// <c>hkSweptTransform</c> (5 × <c>hkVector4</c> = 80) + <c>m_deltaAngle</c> (16) +
    /// <c>m_objectRadius</c> (4) + three <c>hkHalf</c> (6) + trailing bytes, padding to 176 — and
    /// <c>240 + 176 = 416</c>, exactly where <c>m_inertiaAndMassInv</c> was independently found.
    /// The two anchors bracket the block and the header accounts for every byte between them.
    /// </para>
    /// <para>
    /// Confirmed on the data: <c>m_timeFactor</c> reads exactly 1.0 (its default) on every body,
    /// <c>m_angularDamping</c> reads 0.0498 (the hkHalf encoding of 0.05), and
    /// <c>m_objectRadius</c> tracks the owning capsule's extent.
    /// </para>
    /// </remarks>
    private const int ObjectRadiusOffset = 400;

    private const int LinearDampingOffset = 404;
    private const int AngularDampingOffset = 406;
    private const int TimeFactorOffset = 408;
    private const int LinearVelocityOffset = 432;
    private const int AngularVelocityOffset = 448;

    /// <summary>
    /// <c>hkpMaterial</c>, embedded in <c>hkpEntity</c>: an <c>hkInt8</c> response type, an
    /// <c>hkHalf</c> rolling-friction multiplier, then friction and restitution as floats.
    /// </summary>
    /// <remarks>
    /// Located by scanning for a float pair that is constant per body and physically sensible, then
    /// matched against the header's field order. The values are authored constants — friction 0.5
    /// or 0.2, restitution 0.1 or 1.0 — which is what rules out a coincidental alignment.
    /// </remarks>
    private const int FrictionOffset = 140;

    private const int RestitutionOffset = 144;

    public static (HavokSection Section, int Offset)? ReadShape(HavokPackfile packfile, HavokSection section, int objectOffset) =>
        packfile.ResolvePointerField(section, objectOffset + ShapeOffset);

    /// <summary>
    /// Reads the body's world transform and mass properties. Null when the object is truncated.
    /// </summary>
    public static HkpRigidBodyMotion? ReadMotion(HavokSection section, int objectOffset)
    {
        var data = section.Data.Span;
        if (objectOffset < 0 || objectOffset + AngularVelocityOffset + 16 > data.Length) return null;

        return new HkpRigidBodyMotion
        {
            ColumnX = ReadVector(data, objectOffset + TransformOffset),
            ColumnY = ReadVector(data, objectOffset + TransformOffset + 16),
            ColumnZ = ReadVector(data, objectOffset + TransformOffset + 32),
            Translation = ReadVector(data, objectOffset + TranslationOffset),
            InverseInertia = ReadVector(data, objectOffset + InertiaAndMassInvOffset),
            InverseMass = ReadFloat(data, objectOffset + InertiaAndMassInvOffset + 12),
            ObjectRadius = ReadFloat(data, objectOffset + ObjectRadiusOffset),
            LinearDamping = ReadHalf(data, objectOffset + LinearDampingOffset),
            AngularDamping = ReadHalf(data, objectOffset + AngularDampingOffset),
            TimeFactor = ReadHalf(data, objectOffset + TimeFactorOffset),
            LinearVelocity = ReadVector(data, objectOffset + LinearVelocityOffset),
            AngularVelocity = ReadVector(data, objectOffset + AngularVelocityOffset),
            Friction = ReadFloat(data, objectOffset + FrictionOffset),
            Restitution = ReadFloat(data, objectOffset + RestitutionOffset),
        };
    }

    private static Vector3 ReadVector(ReadOnlySpan<byte> data, int offset) =>
        new(ReadFloat(data, offset), ReadFloat(data, offset + 4), ReadFloat(data, offset + 8));

    private static float ReadFloat(ReadOnlySpan<byte> data, int offset) =>
        BinaryPrimitives.ReadSingleLittleEndian(data[offset..]);

    /// <summary>
    /// An <c>hkHalf</c>, which stores the <b>high 16 bits of a float</b> rather than an IEEE half.
    /// </summary>
    /// <remarks>
    /// Confirmed by the result, not assumed: read this way, <c>m_timeFactor</c> comes out as exactly
    /// 1.0 on every body in the game and <c>m_angularDamping</c> as 0.0498, the nearest
    /// representable value to an authored 0.05.
    /// </remarks>
    private static float ReadHalf(ReadOnlySpan<byte> data, int offset) =>
        BitConverter.UInt32BitsToSingle((uint)BinaryPrimitives.ReadUInt16LittleEndian(data[offset..]) << 16);
}
