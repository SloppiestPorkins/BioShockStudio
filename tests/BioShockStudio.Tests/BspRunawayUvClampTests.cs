using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Mesh;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The per-face runaway-UV clamp in <see cref="BspGeometry.NormaliseUvs(MeshGeometry, System.Collections.Generic.IReadOnlyList{System.ValueTuple{int, int}?})"/>.
/// </summary>
/// <remarks>
/// <para>
/// <b>A user found this by looking at the viewport.</b> The compiled-world <c>pBase</c> fix
/// (<c>c650959</c>) put ~93% of 1-Medical's drawn surfaces at a sane texture scale, but a tail of
/// faces — water shaders with no diffuse, an untextured zoning batch, a few walls whose texture
/// vectors this decoder still misreads — came out tiling their texture hundreds to thousands of
/// times. At that magnitude the renderer collapses to the smallest mip and the surface reads as
/// shimmering green scanlines rather than a wall.
/// </para>
/// <para>
/// The clamp rescales any single face tiling past the cap about its own centre. This pins the two
/// things that were wrong when it did not fire: a section that resolved a texture size, and a
/// section that resolved none (its UVs still in raw texels).
/// </para>
/// </remarks>
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class BspRunawayUvClampTests
{
    /// <summary>
    /// One quad, built the way <see cref="BspGeometry.ToGeometry(BspWorld)"/> emits a polygon: a
    /// triangle fan around vertex 0, vertices never shared, with the given texel-space UVs.
    /// </summary>
    private static MeshGeometry Quad(params Vector2[] uvs)
    {
        var vertices = new List<MeshVertex>();
        var indices = new List<int>();
        for (int i = 0; i < uvs.Length; i++)
            vertices.Add(new MeshVertex
            {
                Position = new Vector3(i, 0, 0),
                Normal = Vector3.UnitZ,
                Uv = uvs[i],
                Influences = [],
            });

        for (int i = uvs.Length - 1; i - 1 > 0; i--)
        {
            indices.Add(0);
            indices.Add(i);
            indices.Add(i - 1);
        }

        return new MeshGeometry
        {
            Vertices = vertices,
            Indices = indices,
            BoneMap = [],
            SkinnedVertexCount = 0,
            RigidVertexCount = vertices.Count,
            Sections = [new MeshSection(0, 0, vertices.Count - 1, uvs.Length - 2)],
        };
    }

    private static float MaxUv(MeshGeometry g)
    {
        float worst = 0f;
        foreach (var v in g.Vertices)
            worst = MathF.Max(worst, MathF.Max(MathF.Abs(v.Uv.X), MathF.Abs(v.Uv.Y)));
        return worst;
    }

    [Fact]
    public void AFaceTilingThousandsOfTimesIsRescaledUnderTheCap()
    {
        // Raw texels: a face spanning 6,000,000 texels of a 512 texture -> ~11,700 tiles.
        var geometry = Quad(
            new Vector2(0, 0),
            new Vector2(6_000_000, 0),
            new Vector2(6_000_000, 6_000_000),
            new Vector2(0, 6_000_000));

        var clamped = BspGeometry.NormaliseUvs(geometry, [(512, 512)]);

        Assert.True(MaxUv(clamped) <= 13f,
            $"the runaway face still tiles {MaxUv(clamped):0} times after the clamp");
    }

    [Fact]
    public void ASectionThatResolvedNoTextureSizeIsStillClamped()
    {
        // Water/ocean shaders carry no diffuse, so NormaliseUvs gets a null size. It must still
        // divide by the nominal size and clamp the runaway face like any other.
        var geometry = Quad(
            new Vector2(0, 0),
            new Vector2(2_000_000, 0),
            new Vector2(2_000_000, 40_000),
            new Vector2(0, 40_000));

        var noSize = new List<(int Width, int Height)?> { null };
        var clamped = BspGeometry.NormaliseUvs(geometry, noSize);

        Assert.True(MaxUv(clamped) <= 13f,
            $"an untextured runaway face still tiles {MaxUv(clamped):0} times after the clamp");
    }

    [Fact]
    public void AWallTilingAHandfulOfTimesIsUntouched()
    {
        // A correctly-decoded surface: 512 texture, ~4 tiles across. Rebase may shift absolute
        // values by whole periods (here centre~(2,1) → max abs 2) but must not clamp the span.
        var geometry = Quad(
            new Vector2(0, 0),
            new Vector2(2048, 0),
            new Vector2(2048, 1024),
            new Vector2(0, 1024));

        var normalised = BspGeometry.NormaliseUvs(geometry, [(512, 512)]);

        float minU = float.MaxValue, maxU = float.MinValue, minV = float.MaxValue, maxV = float.MinValue;
        foreach (var v in normalised.Vertices)
        {
            minU = MathF.Min(minU, v.Uv.X); maxU = MathF.Max(maxU, v.Uv.X);
            minV = MathF.Min(minV, v.Uv.Y); maxV = MathF.Max(maxV, v.Uv.Y);
        }
        float span = MathF.Max(maxU - minU, maxV - minV);
        Assert.Equal(4f, span, 3);
        Assert.True(MaxUv(normalised) <= 4f,
            $"a sane wall was over-clamped to max |UV| {MaxUv(normalised):0.##}");
    }

    /// <summary>
    /// Whole-period rebase subtracts an integer from every UV of a face, so <c>frac(UV)</c> —
    /// what a wrapping sampler uses — is unchanged within float noise.
    /// </summary>
    [Fact]
    public void WholePeriodRebasePreservesFractionalPart()
    {
        // Pan-baked magnitude (~1000 tiles) with a modest face span so the clamp does not fire.
        var geometry = Quad(
            new Vector2(512_000, 256_000),
            new Vector2(513_024, 256_000),
            new Vector2(513_024, 256_512),
            new Vector2(512_000, 256_512));

        static Vector2 Frac(Vector2 uv) =>
            new(uv.X - MathF.Floor(uv.X), uv.Y - MathF.Floor(uv.Y));

        var beforeFrac = geometry.Vertices
            .Select(v => Frac(new Vector2(v.Uv.X / 512f, v.Uv.Y / 512f)))
            .ToList();

        var after = BspGeometry.NormaliseUvs(geometry, [(512, 512)]);

        for (int i = 0; i < beforeFrac.Count; i++)
        {
            var af = Frac(after.Vertices[i].Uv);
            Assert.True(MathF.Abs(beforeFrac[i].X - af.X) < 1e-3f
                        && MathF.Abs(beforeFrac[i].Y - af.Y) < 1e-3f,
                $"vertex {i}: frac before {beforeFrac[i]} after {af}");
        }
    }
}
