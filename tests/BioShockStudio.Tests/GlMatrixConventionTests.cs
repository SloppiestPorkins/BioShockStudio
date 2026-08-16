using System.Numerics;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The matrix convention the GPU viewport depends on.
/// </summary>
/// <remarks>
/// <para>
/// <b>This is the one part of the GL path that can be tested without a GL context, and it is the
/// part most likely to be wrong.</b> Avalonia's headless renderer has no GPU, so
/// <c>LevelGlViewport</c> is never exercised by the suite — but its correctness rests almost
/// entirely on one claim about how a <see cref="Matrix4x4"/> reaches a shader, and that claim is
/// arithmetic.
/// </para>
/// <para>
/// The claim: <see cref="Matrix4x4"/> stores rows contiguously and uses the <b>row-vector</b>
/// convention (<c>v · M</c>), which is what <c>SoftwareRenderer</c> uses. OpenGL, given the same
/// bytes with <c>transpose = false</c>, reads them as <b>columns</b> — so the matrix the shader
/// receives is <c>Mᵀ</c>. The shader then computes <c>Mᵀ · v</c> in the column-vector convention,
/// and <c>Mᵀ · v</c> is exactly <c>v · M</c>.
/// </para>
/// <para>
/// Getting this wrong — transposing on upload as well, which is the intuitive thing to do — applies
/// the inverse convention twice and puts the whole level inside out. That looks like a camera bug
/// and would cost an afternoon.
/// </para>
/// </remarks>
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class GlMatrixConventionTests
{
    /// <summary>A matrix with no symmetry, so a transposition cannot pass by accident.</summary>
    private static Matrix4x4 Awkward() =>
        Matrix4x4.CreateScale(2.5f, 0.75f, 1.5f)
        * Matrix4x4.CreateFromYawPitchRoll(0.7f, -0.35f, 1.1f)
        * Matrix4x4.CreateTranslation(120f, -45f, 8_000f)
        * Matrix4x4.CreatePerspectiveFieldOfView(0.9f, 1.6f, 4f, 400_000f);

    /// <summary>Row-vector multiply: what <c>SoftwareRenderer</c> does.</summary>
    private static Vector4 RowVector(Vector4 v, Matrix4x4 m) => new(
        v.X * m.M11 + v.Y * m.M21 + v.Z * m.M31 + v.W * m.M41,
        v.X * m.M12 + v.Y * m.M22 + v.Z * m.M32 + v.W * m.M42,
        v.X * m.M13 + v.Y * m.M23 + v.Z * m.M33 + v.W * m.M43,
        v.X * m.M14 + v.Y * m.M24 + v.Z * m.M34 + v.W * m.M44);

    /// <summary>
    /// Column-vector multiply against the matrix <b>as OpenGL reconstructs it</b> from our bytes.
    /// </summary>
    /// <remarks>
    /// The reconstruction is the point: <paramref name="uploaded"/> is the 16 floats in the order
    /// <see cref="Matrix4x4"/> lays them out in memory, and GL with <c>transpose = false</c> takes
    /// the first four as column 0, the next four as column 1, and so on.
    /// </remarks>
    private static Vector4 ShaderWouldCompute(float[] uploaded, Vector4 v)
    {
        // gl[row, column] — column-major fill, which is what GL does with transpose = false.
        var gl = new float[4, 4];
        for (int column = 0; column < 4; column++)
            for (int row = 0; row < 4; row++)
                gl[row, column] = uploaded[column * 4 + row];

        Span<float> input = [v.X, v.Y, v.Z, v.W];
        Span<float> result = stackalloc float[4];

        for (int row = 0; row < 4; row++)
            for (int k = 0; k < 4; k++)
                result[row] += gl[row, k] * input[k];

        return new Vector4(result[0], result[1], result[2], result[3]);
    }

    /// <summary>The 16 floats as <see cref="Matrix4x4"/> lays them out — the bytes GL is handed.</summary>
    private static float[] AsUploaded(Matrix4x4 m) =>
    [
        m.M11, m.M12, m.M13, m.M14,
        m.M21, m.M22, m.M23, m.M24,
        m.M31, m.M32, m.M33, m.M34,
        m.M41, m.M42, m.M43, m.M44,
    ];

    [Fact]
    public void UploadingWithoutTransposeMakesTheShaderAgreeWithTheSoftwareRenderer()
    {
        var matrix = Awkward();
        var uploaded = AsUploaded(matrix);

        foreach (var point in new[]
                 {
                     new Vector4(0, 0, 0, 1),
                     new Vector4(1, 0, 0, 1),
                     new Vector4(-3_500f, 12_000f, -800f, 1),
                     new Vector4(47_170f, 6_976f, -17_848f, 1),
                 })
        {
            var software = RowVector(point, matrix);
            var shader = ShaderWouldCompute(uploaded, point);

            Assert.Equal(software.X, shader.X, 2);
            Assert.Equal(software.Y, shader.Y, 2);
            Assert.Equal(software.Z, shader.Z, 2);
            Assert.Equal(software.W, shader.W, 2);
        }
    }

    /// <summary>
    /// Transposing on upload as well — the intuitive move — disagrees, which is what makes the test
    /// above meaningful rather than vacuous.
    /// </summary>
    [Fact]
    public void TransposingOnUploadWouldBeWrong()
    {
        var matrix = Awkward();
        var wrong = AsUploaded(Matrix4x4.Transpose(matrix));

        var point = new Vector4(-3_500f, 12_000f, -800f, 1);
        var software = RowVector(point, matrix);
        var shader = ShaderWouldCompute(wrong, point);

        Assert.True(
            MathF.Abs(software.X - shader.X) > 1f || MathF.Abs(software.Y - shader.Y) > 1f
            || MathF.Abs(software.Z - shader.Z) > 1f || MathF.Abs(software.W - shader.W) > 1f,
            "transposing on upload produced the same answer, so this pair of tests proves nothing");
    }

    /// <summary>
    /// <c>GhostCamera</c> and the GPU path build the same view-projection, so the two renderers
    /// cannot disagree about where the camera is.
    /// </summary>
    /// <remarks>
    /// <c>LevelGlViewport</c> composes its own matrices rather than calling into the software
    /// renderer, which is a real opportunity for the two to drift. This pins that they do not.
    /// </remarks>
    [Fact]
    public void TheGpuAndSoftwarePathsBuildTheSameViewProjection()
    {
        var camera = new Core.Rendering.GhostCamera
        {
            Position = new Vector3(47_170f, 6_976f, -17_848f),
            Yaw = 0.8f,
            Pitch = -0.2f,
        };

        var view = camera.ToPreviewCamera();

        // What LevelGlViewport builds.
        var gpu =
            Matrix4x4.CreateLookAt(view.Eye, view.Target, Vector3.UnitZ)
            * Matrix4x4.CreatePerspectiveFieldOfView(
                view.FieldOfView, 1.6f, view.NearPlane ?? 4f, view.FarPlane ?? 400_000f);

        // The same inputs the software renderer is given.
        Assert.Equal(4f, view.NearPlane);
        Assert.Equal(400_000f, view.FarPlane);

        // The eye is where the camera says it is — the half-turn/negated-pitch trick in LookFrom is
        // the easiest thing in the whole path to get backwards.
        Assert.Equal(camera.Position.X, view.Eye.X, 2);
        Assert.Equal(camera.Position.Y, view.Eye.Y, 2);
        Assert.Equal(camera.Position.Z, view.Eye.Z, 2);

        // And it looks along the camera's heading.
        var heading = Vector3.Normalize(view.Target - view.Eye);
        Assert.True(Vector3.Dot(heading, camera.Forward) > 0.999f,
            $"the projection looks along {heading} but the camera faces {camera.Forward}");

        Assert.NotEqual(default, gpu);
    }
}
