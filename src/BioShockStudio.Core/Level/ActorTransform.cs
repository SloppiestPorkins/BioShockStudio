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
    /// LIKELY. The composition order — yaw about Z, then pitch about Y, then roll about X — is
    /// Unreal's own (<c>FRotationMatrix</c>), and BioShock is Unreal Engine 2.5, so the convention
    /// is inherited rather than inferred from BioShock's bytes. It has not yet been checked against
    /// a rendered level, which is the evidence that would raise it to CONFIRMED.
    /// </remarks>
    public Quaternion ToQuaternion()
    {
        var degrees = ToDegrees();
        const float toRadians = MathF.PI / 180f;
        return Quaternion.CreateFromAxisAngle(Vector3.UnitZ, degrees.Z * toRadians)
             * Quaternion.CreateFromAxisAngle(Vector3.UnitY, degrees.Y * toRadians)
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
    /// <b>CORROBORATED, upgraded from LIKELY by a rendered level.</b> The order — subtract the
    /// pre-pivot, scale, rotate, translate — is Unreal's, inherited rather than derived from
    /// BioShock's bytes, and this note previously said it was "not yet checked against a rendered
    /// level, which is the evidence that would raise it". <c>LevelRenderingTests</c> is now that
    /// evidence: <c>0-Lighthouse</c>'s 911 placed static meshes assemble into Rapture's skyline —
    /// recognisable art-deco towers, standing upright, correctly spaced — which a wrong rotation
    /// order or composition sequence would not produce.
    /// </para>
    /// <para>
    /// <b>What that does and does not establish.</b> It exercises real data: 1,223 of Lighthouse's
    /// actors carry a rotation and 1,171 a scale. It does <i>not</i> pin the rotation order to the
    /// exclusion of every alternative — a level whose actors are mostly yaw-only would look right
    /// under several conventions — so this is CORROBORATED rather than CONFIRMED_BYTES, and the raw
    /// fields are kept alongside so a caller can compose them differently without re-reading the
    /// package.
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
