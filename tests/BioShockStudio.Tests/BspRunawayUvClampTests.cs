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

        Assert.True(MaxUv(clamped) <= 17f,
            $"the runaway face still tiles {MaxUv(clamped):0} times after the clamp");
    }

    [Fact]
    public void ASectionThatResolvedNoTextureSizeIsStillClamped()
    {
        // Water/ocean shaders carry no diffuse, so NormaliseUvs gets a null size and never
        // divides. The clamp must still catch a raw-texel face here.
        var geometry = Quad(
            new Vector2(0, 0),
            new Vector2(2_000_000, 0),
            new Vector2(2_000_000, 40_000),
            new Vector2(0, 40_000));

        var noSize = new List<(int Width, int Height)?> { null };
        var clamped = BspGeometry.NormaliseUvs(geometry, noSize);

        // Nominal 256 texture, cap 16 -> ~4,096 texels.
        Assert.True(MaxUv(clamped) <= 4_500f,
            $"an untextured runaway face still spans {MaxUv(clamped):0} texels after the clamp");
    }

    [Fact]
    public void AWallTilingAHandfulOfTimesIsUntouched()
    {
        // The 93% that resolved correctly: a 512 texture, a 4m wall, ~4 tiles. Must pass through
        // the clamp unchanged.
        var geometry = Quad(
            new Vector2(0, 0),
            new Vector2(2048, 0),
            new Vector2(2048, 1024),
            new Vector2(0, 1024));

        var normalised = BspGeometry.NormaliseUvs(geometry, [(512, 512)]);

        Assert.Equal(4f, MaxUv(normalised), 3);
    }
}
