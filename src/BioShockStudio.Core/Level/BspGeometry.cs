using System.Numerics;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>
/// Turns brush polygons into the same <see cref="MeshGeometry"/> the mesh readers produce, so the
/// preview, the exporters and the diagnostics can consume a brush without knowing what BSP is.
/// </summary>
public static class BspGeometry
{
    /// <summary>
    /// Triangulates polygons into one geometry, one <see cref="MeshSection"/> per distinct material.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Vertices are not shared between polygons. Two polygons meeting at an edge have different
    /// plane normals there, so welding them would either average the normals — rounding off every
    /// corner in the level — or need a split rule that the data does not state. Duplicating is the
    /// honest representation of what the container holds: a soup of independent planar faces.
    /// </para>
    /// <para>
    /// <b>UVs are in texels, not normalised.</b> An <c>FPoly</c> parameterises its surface with
    /// <c>Base</c>, <c>TextureU</c> and <c>TextureV</c>, and the projection of a vertex onto those
    /// axes is a distance in texture space — the engine divides it by the bound texture's own
    /// dimensions. This layer does not resolve materials, so it cannot know those dimensions and
    /// does not invent them; it emits the projection and says so. A consumer that has resolved the
    /// material divides by the texture's width and height. See <see cref="NormaliseUvs"/>.
    /// </para>
    /// </remarks>
    public static MeshGeometry ToGeometry(IEnumerable<BspPolygon> polygons)
    {
        var vertices = new List<MeshVertex>();
        var indices = new List<int>();
        var sections = new List<MeshSection>();

        // Grouped so that a brush drawing several surfaces comes out as several sections, which is
        // the shape MeshSurfaceResolver already pairs with a material list.
        var groups = polygons
            .GroupBy(p => p.Material.Value)
            .OrderBy(g => g.Key)
            .ToList();

        foreach (var group in groups)
        {
            int firstIndex = indices.Count;
            int firstVertex = vertices.Count;
            int triangles = 0;

            foreach (var polygon in group)
            {
                int start = vertices.Count;

                foreach (var position in polygon.Vertices)
                {
                    vertices.Add(new MeshVertex
                    {
                        Position = position,
                        Normal = polygon.Normal,
                        Uv = Project(polygon, position),
                        Influences = [],
                    });
                }

                // Triangles() is what carries the winding correction; index arithmetic here must
                // follow it rather than re-deriving a fan, or the correction is silently undone.
                foreach (var (a, b, c) in polygon.TriangleIndices())
                {
                    indices.Add(start + a);
                    indices.Add(start + b);
                    indices.Add(start + c);
                    triangles++;
                }
            }

            if (triangles == 0) continue;
            sections.Add(new MeshSection(firstIndex, firstVertex, vertices.Count - 1, triangles));
        }

        return new MeshGeometry
        {
            Vertices = vertices,
            Indices = indices,
            BoneMap = [],
            SkinnedVertexCount = 0,
            RigidVertexCount = vertices.Count,
            Sections = sections,
        };
    }

    /// <summary>The distinct materials the polygons name, in the order <see cref="ToGeometry"/> sections them.</summary>
    public static IReadOnlyList<PackageIndex> Materials(IEnumerable<BspPolygon> polygons) => polygons
        .GroupBy(p => p.Material.Value)
        .OrderBy(g => g.Key)
        .Select(g => new PackageIndex(g.Key))
        .ToList();

    /// <summary>
    /// Divides texel-space UVs by a texture's dimensions, giving the normalised UVs a renderer wants.
    /// </summary>
    /// <remarks>
    /// Separated from <see cref="ToGeometry"/> because the texture size comes from a resolved
    /// material, which is a layer this one deliberately does not reach into.
    /// </remarks>
    public static Vector2 NormaliseUvs(Vector2 texels, int textureWidth, int textureHeight) =>
        textureWidth > 0 && textureHeight > 0
            ? new Vector2(texels.X / textureWidth, texels.Y / textureHeight)
            : texels;

    private static Vector2 Project(BspPolygon polygon, Vector3 position)
    {
        var offset = position - polygon.Base;
        return new Vector2(Vector3.Dot(offset, polygon.TextureU), Vector3.Dot(offset, polygon.TextureV));
    }
}
