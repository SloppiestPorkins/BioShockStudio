using System.Numerics;

namespace BioShockStudio.Core.Export.Fbx;

/// <summary>
/// Transform conversions between the game's data and what an FBX node record can hold.
/// </summary>
/// <remarks>
/// Matrices use <see cref="Matrix4x4"/>'s row-vector convention throughout (a point is a row and is
/// multiplied on the left), which is the transpose of the column-vector convention the research
/// notes and the Blender importer are written in. Composition therefore reads child-then-parent
/// here where it reads parent-then-child there.
/// </remarks>
public static class FbxMath
{
    /// <summary>Ticks per second in FBX's time unit. Key times are absolute, not frame numbers.</summary>
    public const long TimeUnit = 46186158000L;

    public static Matrix4x4 Compose(Vector3 translation, Quaternion rotation, Vector3 scale) =>
        Matrix4x4.CreateScale(scale)
        * Matrix4x4.CreateFromQuaternion(rotation)
        * Matrix4x4.CreateTranslation(translation);

    /// <summary>
    /// Composes each bone's reference pose into skeleton space. Bones are stored parent-first, which
    /// the scene exporter asserts, so one forward pass suffices.
    /// </summary>
    public static Matrix4x4[] GlobalPose(IReadOnlyList<SceneBone> bones, float scale)
    {
        var result = new Matrix4x4[bones.Count];
        for (int i = 0; i < bones.Count; i++)
        {
            var bone = bones[i];
            var local = Compose(
                new Vector3(bone.Translation[0], bone.Translation[1], bone.Translation[2]) * scale,
                new Quaternion(bone.Rotation[0], bone.Rotation[1], bone.Rotation[2], bone.Rotation[3]),
                new Vector3(bone.Scale[0], bone.Scale[1], bone.Scale[2]));

            result[i] = bone.Parent < 0 ? local : local * result[bone.Parent];
        }
        return result;
    }

    /// <summary>
    /// Decomposes a rotation into the Euler angles an FBX node stores, in degrees.
    /// </summary>
    /// <remarks>
    /// FBX has no quaternion channel for a node's local rotation, so the game's quaternions have to
    /// be converted. With the default rotation order (<c>eEulerXYZ</c>, which this exporter always
    /// writes) the composed rotation is <c>Rz · Ry · Rx</c> in column-vector terms — X is applied
    /// first. Getting that order wrong produces a rig that is plausible and wrong, the same failure
    /// mode the Blender rest-matrix bug had.
    /// </remarks>
    public static Vector3 ToEulerDegrees(Quaternion rotation)
    {
        var m = Matrix4x4.CreateFromQuaternion(Quaternion.Normalize(rotation));

        // Row-vector storage, so the column-vector element R[row][col] is m.M(col+1)(row+1).
        float r00 = m.M11, r10 = m.M12;
        float r20 = m.M13, r21 = m.M23, r22 = m.M33;
        float r11 = m.M22, r12 = m.M32;

        float x, y, z;
        float sy = Math.Clamp(-r20, -1f, 1f);
        y = MathF.Asin(sy);

        // Gimbal lock: X and Z become a single degree of freedom, so Z is pinned and X absorbs it.
        if (MathF.Abs(r20) > 0.9999995f)
        {
            x = MathF.Atan2(-r12, r11);
            z = 0f;
        }
        else
        {
            x = MathF.Atan2(r21, r22);
            z = MathF.Atan2(r10, r00);
        }

        const float ToDegrees = 180f / MathF.PI;
        return new Vector3(x * ToDegrees, y * ToDegrees, z * ToDegrees);
    }

    /// <summary>
    /// Rewrites an Euler triple into the equivalent nearest the previous frame's.
    /// </summary>
    /// <remarks>
    /// Every rotation has two Euler solutions plus whole turns of each angle. Consecutive frames
    /// that pick different ones describe the same pose but interpolate through a different path, so
    /// a curve that is sampled correctly still plays back as a spin. Curves are keyed per frame
    /// here, so this only matters between keys — but FBX importers resample, and the game's own
    /// rates are not integers.
    /// </remarks>
    public static Vector3 MakeCompatible(Vector3 previous, Vector3 candidate)
    {
        var alternate = new Vector3(candidate.X + 180f, 180f - candidate.Y, candidate.Z + 180f);

        var a = Unwind(previous, candidate);
        var b = Unwind(previous, alternate);
        return Distance(previous, a) <= Distance(previous, b) ? a : b;

        static Vector3 Unwind(Vector3 previous, Vector3 value) => new(
            Nearest(previous.X, value.X), Nearest(previous.Y, value.Y), Nearest(previous.Z, value.Z));

        static float Nearest(float previous, float value) =>
            value + 360f * MathF.Round((previous - value) / 360f);

        static float Distance(Vector3 a, Vector3 b) =>
            MathF.Abs(a.X - b.X) + MathF.Abs(a.Y - b.Y) + MathF.Abs(a.Z - b.Z);
    }

    public static long ToTicks(double seconds) => (long)Math.Round(seconds * TimeUnit);
}
