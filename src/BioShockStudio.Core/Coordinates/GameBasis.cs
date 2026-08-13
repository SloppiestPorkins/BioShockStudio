using System.Numerics;
using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Skeleton;

namespace BioShockStudio.Core.Coordinates;

/// <summary>
/// The project's single coordinate-system policy: the one conversion from the game's basis into
/// BioShockStudio's internal basis.
/// <para>
/// BioShock's Vengeance engine inherits Unreal's basis — <b>+X forward, +Y right, +Z up, and
/// left-handed</b>. Every consumer this project has is right-handed: the preview rasteriser
/// (<c>Matrix4x4.CreateLookAt</c> and <c>CreatePerspectiveFieldOfView</c> are right-handed), FBX as
/// Blender reads it, Blender itself, and glTF. A left-handed basis cannot be carried into a
/// right-handed one by any rotation, so passing the game's numbers through unchanged — which is
/// what this project did until now — mirrors every asset.
/// </para>
/// <para>
/// The conversion is therefore a reflection, and this is the only one in the codebase. See
/// <c>docs/research/ANIMATION_COORDINATE_SYSTEM.md</c> for the evidence it rests on and for why the
/// reflection is in Y rather than X or Z.
/// </para>
/// </summary>
public static class GameBasis
{
    /// <summary>
    /// The basis conversion <c>C = diag(1, -1, 1)</c>. Its determinant is <c>-1</c>: it is a
    /// reflection, which is what changes handedness. It keeps the game's forward (+X) and up (+Z)
    /// and turns right (+Y) into left, giving a right-handed <b>+X forward, +Y left, +Z up</b>
    /// basis — Blender's own, which is why the FBX header's existing axis declaration (up +Z,
    /// front -Y, coord +X) becomes correct once the data reaching it is converted.
    /// </summary>
    public static readonly Matrix4x4 Conversion = new(
        1f, 0f, 0f, 0f,
        0f, -1f, 0f, 0f,
        0f, 0f, 1f, 0f,
        0f, 0f, 0f, 1f);

    /// <summary>
    /// A point or a direction. Because <see cref="Conversion"/> is diagonal, orthogonal and
    /// symmetric, it is its own inverse-transpose, so a normal converts by exactly the same map as
    /// a position — there is no separate normal transform to get wrong.
    /// </summary>
    public static Vector3 Convert(Vector3 v) => new(v.X, -v.Y, v.Z);

    /// <summary>
    /// A rotation, conjugated into the new basis: <c>R' = C · R · C⁻¹</c>.
    /// <para>
    /// Conjugating a rotation by a reflection reflects its axis and negates its angle. For
    /// <c>C = diag(1,-1,1)</c> that is axis <c>(x,y,z) → (x,-y,z)</c> with angle <c>θ → -θ</c>,
    /// which multiplies out to <c>q = (x,y,z,w) → (-x, y, -z, w)</c>. This is derived, not fitted:
    /// <c>CoordinateSystemTests</c> checks it against <c>C · R · C⁻¹</c> built as matrices.
    /// </para>
    /// </summary>
    public static Quaternion Convert(Quaternion q) => new(-q.X, q.Y, -q.Z, q.W);

    /// <summary>
    /// Scale. A diagonal conversion commutes with a diagonal scale, so scale is carried unchanged —
    /// the conversion never introduces a negative scale factor of its own.
    /// </summary>
    public static Vector3 ConvertScale(Vector3 scale) => scale;

    /// <summary>A transform, conjugated: <c>C · M · C⁻¹</c>.</summary>
    public static Matrix4x4 Convert(Matrix4x4 m) => Conversion * m * Conversion;

    /// <summary>
    /// A decoded mesh, converted into the internal basis.
    /// <para>
    /// Positions and all three basis vectors convert by <see cref="Convert(Vector3)"/>. The
    /// <b>triangle winding is deliberately left alone</b>, and that is a derived result rather than
    /// an omission.
    /// </para>
    /// <para>
    /// The game's geometry is front-face-clockwise: its geometric normal <c>(B-A)×(C-A)</c> points
    /// <i>against</i> the shipped shading normal, measured at 100% of triangles on the hands, Rosie
    /// and BabyJane, and corroborated by Nyko's SDK having to force <c>GL_CW</c>. A cross product
    /// transforms by <c>det(C)·(C⁻¹)ᵀ = -C</c> while a normal transforms by <c>+C</c>, so the
    /// reflection negates their agreement: <c>dot(g', n') = -dot(g, n)</c>. The game's disagreement
    /// therefore becomes agreement, and the converted mesh is counter-clockwise front-facing — the
    /// convention FBX, Blender and Unreal all expect — with no index swap at all. Reversing the
    /// winding on top of the reflection would undo exactly this and put it back the wrong way,
    /// which is what <c>CoordinateSystemTests</c> caught when this reader first tried it.
    /// </para>
    /// <para>UVs are untouched: the conversion acts on space, not on texture parameterisation.</para>
    /// </summary>
    public static MeshGeometry Convert(MeshGeometry geometry)
    {
        var vertices = new MeshVertex[geometry.Vertices.Count];
        for (int i = 0; i < vertices.Length; i++)
        {
            var v = geometry.Vertices[i];
            vertices[i] = v with
            {
                Position = Convert(v.Position),
                Normal = Convert(v.Normal),
                Tangent = Convert(v.Tangent),
                Binormal = Convert(v.Binormal),
            };
        }

        return geometry with { Vertices = vertices };
    }

    /// <summary>A decoded skeleton, converted bone by bone in its parent-local frame.</summary>
    /// <remarks>
    /// Converting local transforms converts the composed global ones too: if a bone's global
    /// transform is the product of its chain, then conjugating every link by <c>C</c> gives
    /// <c>C·M₁·C⁻¹ · C·M₂·C⁻¹ · … = C·(M₁·M₂·…)·C⁻¹</c>, the conjugate of the original global. The
    /// same identity is what keeps a converted mesh and a converted skeleton in step, since the
    /// mesh is stored in skeleton space.
    /// </remarks>
    public static BioShockSkeleton Convert(BioShockSkeleton skeleton)
    {
        var bones = new BioShockBone[skeleton.Bones.Count];
        for (int i = 0; i < bones.Length; i++)
        {
            var bone = skeleton.Bones[i];
            bones[i] = bone with
            {
                LocalTranslation = Convert(bone.LocalTranslation),
                LocalRotation = Convert(bone.LocalRotation),
                LocalScale = ConvertScale(bone.LocalScale),
            };
        }

        return new BioShockSkeleton
        {
            Name = skeleton.Name,
            Bones = bones,
            SourceSection = skeleton.SourceSection,
            SourceOffset = skeleton.SourceOffset,
        };
    }

    /// <summary>
    /// A decoded animation, converted track by track.
    /// <para>
    /// Animation tracks are parent-local transforms in the same space as the skeleton's reference
    /// pose, so they take the same conversion. There is deliberately no animation-specific
    /// adjustment: an animation that needed one would mean the skeleton and the animation disagreed
    /// about their basis, which they do not.
    /// </para>
    /// </summary>
    public static DecodedAnimation Convert(DecodedAnimation animation)
    {
        var tracks = new DecodedTrack[animation.Tracks.Count];
        for (int t = 0; t < tracks.Length; t++)
        {
            var track = animation.Tracks[t];

            var translations = new Vector3[track.Translations.Length];
            for (int f = 0; f < translations.Length; f++)
                translations[f] = Convert(track.Translations[f]);

            var rotations = new Quaternion[track.Rotations.Length];
            for (int f = 0; f < rotations.Length; f++)
                rotations[f] = Convert(track.Rotations[f]);

            var scales = new Vector3[track.Scales.Length];
            for (int f = 0; f < scales.Length; f++)
                scales[f] = ConvertScale(track.Scales[f]);

            tracks[t] = new DecodedTrack
            {
                OriginalTrackIndex = track.OriginalTrackIndex,
                Translations = translations,
                Rotations = rotations,
                Scales = scales,
                TargetBoneIndex = track.TargetBoneIndex,
            };
        }

        return animation with { Tracks = tracks };
    }

    /// <summary>A reference transform, converted. Used where a channel falls back to the bind pose.</summary>
    public static ReferenceTransform Convert(ReferenceTransform transform) => new(
        Convert(transform.Translation),
        Convert(transform.Rotation),
        ConvertScale(transform.Scale));

    /// <summary>
    /// A reference transform taken back to the game's basis.
    /// <para>
    /// <c>C</c> is a reflection, so <c>C·C = I</c> and this is the same map as
    /// <see cref="Convert(ReferenceTransform)"/>. It exists under its own name because there is
    /// exactly one call site that means "back to the game's basis" — the spline decompressor's
    /// reference-pose fallback, which has to receive game-basis values so that the decoded result
    /// can be converted once, as a whole. Leaning on the involution silently there is how a double
    /// conversion gets introduced.
    /// </para>
    /// </summary>
    public static ReferenceTransform ToGameBasis(ReferenceTransform transform) => Convert(transform);
}
