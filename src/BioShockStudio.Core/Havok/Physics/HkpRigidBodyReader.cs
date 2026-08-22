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
public static class HkpRigidBodyReader
{
    public const string ClassName = "hkpRigidBody";

    /// <summary><c>hkpCollidable::m_shape</c>, reached via the embedded <c>hkpLinkedCollidable</c>.</summary>
    private const int ShapeOffset = 16;

    public static (HavokSection Section, int Offset)? ReadShape(HavokPackfile packfile, HavokSection section, int objectOffset) =>
        packfile.ResolvePointerField(section, objectOffset + ShapeOffset);
}
