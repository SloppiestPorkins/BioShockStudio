using System.Numerics;

namespace BioShockStudio.Core.Level;

/// <summary>
/// An Unreal rotator: three angles in the engine's own unit of 65,536 per turn.
/// CONFIRMED_BYTES that the property is three int32s; the meaning of the units is
/// CONFIRMED_EXTERNAL from Unreal Engine, where the type is universal.
/// </summary>
public readonly record struct UnrealRotator(int Pitch, int Yaw, int Roll)
{
    public const double UnitsPerTurn = 65536.0;

    public static readonly UnrealRotator Identity = new(0, 0, 0);

    public bool IsIdentity => Pitch == 0 && Yaw == 0 && Roll == 0;

    /// <summary>Degrees about (X = roll, Y = pitch, Z = yaw), wrapped to -180..180.</summary>
    public Vector3 ToDegrees() => new(Wrap(Roll), Wrap(Pitch), Wrap(Yaw));

    private static float Wrap(int units)
    {
        double turns = units / UnitsPerTurn;
        double degrees = (turns - Math.Floor(turns)) * 360.0;
        return (float)(degrees > 180.0 ? degrees - 360.0 : degrees);
    }

    /// <summary>
    /// The rotation as a quaternion.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>CONFIRMED_EXTERNAL, and it took a real bug report to find the sign.</b> The composition
    /// order — yaw about Z, then pitch about Y, then roll about X — is Unreal's own
    /// (<c>FRotationMatrix</c>), inherited from UE2.5 rather than derived from BioShock's bytes.
    /// What this project had wrong was the sign on pitch.
    /// </para>
    /// <para>
    /// <b>The bug, and how it was found.</b> A user reported a ceiling window arch at the Medical
    /// Pavilion entrance rendering as a twisted, self-intersecting shape instead of the smooth
    /// barrel vault it should be — four <c>window_512_corner_4up</c> instances, all
    /// <c>pitch = −90°, yaw = 0°</c>, roll alternating <c>0°</c> and <c>±180°</c>. That is exactly
    /// the case a wrong pitch sign breaks visibly: at pitch ±90° a sign error does not merely tilt
    /// the result, it flips which way the roll's mirror lands.
    /// </para>
    /// <para>
    /// <b>Settled by matching the reference's own matrix construction, numerically.</b> Nyko's level
    /// editor (<c>viewport.cpp</c>, <c>BuildActorTransform</c>) composes
    /// <c>Ry(yaw) · Rp(pitch) · Rr(roll)</c> — no sign flip visible in the C++ — but it applies to a
    /// <b>column</b> vector (<c>v' = M·v</c>), while this project uses <b>row</b>-vector convention
    /// throughout (<c>v' = v·M</c>, stated on <see cref="ActorTransform.ToMatrix"/>). Six quaternion
    /// candidates were each converted to a matrix and applied to four probe vectors under both
    /// conventions, compared against Nyko's raw float matrix built and multiplied by hand in the
    /// same test. <c>Rz(yaw) · Ry(−pitch) · Rx(roll)</c> reproduced Nyko's construction to
    /// floating-point precision (worst mismatch 1e-6) against six sampled rotations including the
    /// exact pitch=−90°/roll=180° case; every other candidate — including the unmodified
    /// <c>+pitch</c> this project shipped — mismatched by more than 6 units on the same probes.
    /// </para>
    /// <para>
    /// <b>Rendering the reported case confirms it independently of the derivation.</b> The four
    /// window instances, placed with the corrected sign, assemble into one continuous, seamless
    /// barrel vault — no twist, no gap. Under the old sign they formed two panels meeting at a
    /// diagonal seam, which is the exact shape in the bug report.
    /// </para>
    /// </remarks>
    public Quaternion ToQuaternion()
    {
        var degrees = ToDegrees();
        const float toRadians = MathF.PI / 180f;
        return Quaternion.CreateFromAxisAngle(Vector3.UnitZ, degrees.Z * toRadians)
             * Quaternion.CreateFromAxisAngle(Vector3.UnitY, -degrees.Y * toRadians)
             * Quaternion.CreateFromAxisAngle(Vector3.UnitX, degrees.X * toRadians);
    }

    public override string ToString() =>
        IsIdentity ? "none" : $"pitch {Pitch} yaw {Yaw} roll {Roll}";
}

/// <summary>
/// Where a placed actor sits, as the level stores it.
/// <para>
/// Each field is exactly one actor property, and each is optional: an actor that does not write
/// <c>Rotation</c> is unrotated, one that does not write <c>DrawScale</c> is at scale 1. Which
/// properties were actually present is kept in <see cref="Present"/> so a caller can tell a
/// defaulted value from a stored one.
/// </para>
/// </summary>
public sealed record ActorTransform
{
    public static readonly ActorTransform Default = new();

    /// <summary><c>Location</c>, in centimetres, in the level's own space.</summary>
    public Vector3 Location { get; init; } = Vector3.Zero;

    public UnrealRotator Rotation { get; init; } = UnrealRotator.Identity;

    /// <summary><c>DrawScale</c>: a uniform multiplier applied on top of <see cref="DrawScale3D"/>.</summary>
    public float DrawScale { get; init; } = 1f;

    public Vector3 DrawScale3D { get; init; } = Vector3.One;

    /// <summary>
    /// <c>PrePivot</c>: an offset subtracted from the mesh before it is rotated and scaled, so the
    /// actor turns about a point other than the mesh origin. Brushes use it heavily.
    /// </summary>
    public Vector3 PrePivot { get; init; } = Vector3.Zero;

    /// <summary>Names of the transform properties the actor actually stored.</summary>
    public IReadOnlyList<string> Present { get; init; } = [];

    public Vector3 Scale => DrawScale3D * DrawScale;

    public bool IsIdentity =>
        Location == Vector3.Zero && Rotation.IsIdentity && DrawScale == 1f
        && DrawScale3D == Vector3.One && PrePivot == Vector3.Zero;

    /// <summary>
    /// The actor's local-to-world matrix, row-vector convention (a point is multiplied on the left).
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>CONFIRMED_EXTERNAL.</b> The order — subtract the pre-pivot, scale, rotate, translate — is
    /// Unreal's, inherited rather than derived from BioShock's bytes. See
    /// <see cref="UnrealRotator.ToQuaternion"/> for how the rotation itself is now known to compose:
    /// a user-reported warped ceiling arch led to matching this project's quaternion against the
    /// reference level editor's own matrix construction, numerically, which is stronger evidence
    /// than the rendered-skyline check below ever was.
    /// </para>
    /// <para>
    /// <b>What the skyline check established, and what it could not.</b> <c>LevelRenderingTests</c>
    /// renders <c>0-Lighthouse</c>'s 911 placed static meshes into recognisable Rapture towers,
    /// which ruled out a wrong axis or a wrong order outright. It could not distinguish the pitch
    /// sign, because a mostly-yaw skyline looks the same either way — exactly the gap the arch bug
    /// fell into, and exactly why "renders plausibly" is not the same evidentiary weight as "matches
    /// the reference construction to 1e-6".
    /// </para>
    /// </remarks>
    public Matrix4x4 ToMatrix() =>
        Matrix4x4.CreateTranslation(-PrePivot)
        * Matrix4x4.CreateScale(Scale)
        * Matrix4x4.CreateFromQuaternion(Rotation.ToQuaternion())
        * Matrix4x4.CreateTranslation(Location);

    public override string ToString() =>
        $"{Location:0.##} {Rotation}" + (Scale == Vector3.One ? "" : $" scale {Scale:0.###}");
}
