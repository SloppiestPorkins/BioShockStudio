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
    /// One compiled-world draw batch that can bind a base material and one proven baked-light atlas.
    /// </summary>
    /// <remarks>
    /// A descriptor can name several lights. The first is the composite layer shipped for the
    /// surface on the maps whose <c>LightMaps_BSP</c> pool is decoded; the remaining layers are
    /// deliberately retained in <see cref="BspWorld.LightMaps"/> until their blend rule is proven.
    /// </remarks>
    public sealed record LightMapBatch(PackageIndex Material, PackageIndex Atlas, MeshGeometry Geometry);

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

    /// <summary>
    /// Triangulates the compiled world, one section per distinct material.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Surfaces the game never draws are left out</b> — zoning, portal and backdrop panes carry
    /// real geometry that would otherwise fill the level with invisible walls. That is what Nyko's
    /// level editor does too; see <see cref="BspSurfaceFlags.NotDrawn"/>.
    /// </para>
    /// <para>
    /// <b>The winding is reversed, for the same reason the source brushes' is.</b> Unreal derives a
    /// BSP polygon's orientation from its own plane, so in the game's left-handed basis the stored
    /// order and the plane normal agree; the basis reflection negates that agreement, so a fan taken
    /// in stored order faces backwards. <c>BspWorldTests</c> measures both directions rather than
    /// trusting this paragraph.
    /// </para>
    /// <para>
    /// Normals come from the node's plane rather than from the winding. A BSP polygon is planar by
    /// construction — that is what the planarity check verifies — so the plane is the more
    /// authoritative source, and it stays correct on the slivers a cross product cannot resolve.
    /// </para>
    /// </remarks>
    public static MeshGeometry ToGeometry(BspWorld world)
    {
        var vertices = new List<MeshVertex>();
        var indices = new List<int>();
        var sections = new List<MeshSection>();

        var byMaterial = world.Nodes
            .Where(n => n.IsPolygon)
            .Where(n => n.Surface >= 0 && n.Surface < world.Surfaces.Count)
            .Where(n => world.Surfaces[n.Surface].IsDrawn)
            .GroupBy(n => world.Surfaces[n.Surface].Material.Value)
            .OrderBy(g => g.Key);

        foreach (var group in byMaterial)
        {
            int firstIndex = indices.Count;
            int firstVertex = vertices.Count;
            int triangles = 0;

            foreach (var node in group)
            {
                var polygon = world.PolygonOf(node);
                if (polygon.Count < 3) continue;

                var surface = world.Surfaces[node.Surface];
                int start = vertices.Count;

                foreach (var position in polygon)
                {
                    vertices.Add(new MeshVertex
                    {
                        Position = position,
                        Normal = node.Plane.Normal,
                        Uv = world.TexelsAt(surface, position),
                        Influences = [],
                    });
                }

                // Reversed, as ToGeometry(polygons) does — see the remarks.
                for (int i = polygon.Count - 1; i - 1 > 0; i--)
                {
                    indices.Add(start);
                    indices.Add(start + i);
                    indices.Add(start + i - 1);
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

    /// <summary>
    /// Triangulates every drawn BSP surface with a verified baked-light atlas, grouped for a
    /// two-texture draw. Vertices retain the normal material UV in <see cref="MeshVertex.Uv"/> and
    /// their atlas UV in <see cref="MeshVertex.LightMapUv"/>.
    /// </summary>
    /// <remarks>
    /// Only the descriptor's first layer is emitted for now. It is a usable, byte-faithful base
    /// lightmap; rendering all layers requires the game's still-unproven modulation blend rule.
    /// </remarks>
    public static IReadOnlyList<LightMapBatch> ToLightMapBatches(BspWorld world)
    {
        var groups = world.Nodes
            .Where(n => n.IsPolygon)
            .Where(n => n.Surface >= 0 && n.Surface < world.Surfaces.Count)
            .Where(n => world.Surfaces[n.Surface].IsDrawn)
            .Where(n => n.LightMap >= 0 && n.LightMap < world.LightMaps.Count)
            .Select(n => (Node: n, Descriptor: world.LightMaps[n.LightMap]))
            .Where(x => x.Descriptor.Lights.Count > 0)
            .Select(x => (x.Node, x.Descriptor, Layer: x.Descriptor.Lights[0]))
            .Where(x => x.Layer.Atlas >= 0 && x.Layer.Atlas < world.LightMapTextures.Count)
            .GroupBy(x => (Material: world.Surfaces[x.Node.Surface].Material, Atlas: world.LightMapTextures[x.Layer.Atlas].Texture))
            .OrderBy(g => g.Key.Material.Value)
            .ThenBy(g => g.Key.Atlas.Value);

        var batches = new List<LightMapBatch>();
        foreach (var group in groups)
        {
            var vertices = new List<MeshVertex>();
            var indices = new List<int>();
            int triangles = 0;

            foreach (var (node, _, layer) in group)
            {
                var polygon = world.PolygonOf(node);
                if (polygon.Count < 3) continue;

                var surface = world.Surfaces[node.Surface];
                int start = vertices.Count;
                foreach (var position in polygon)
                {
                    vertices.Add(new MeshVertex
                    {
                        Position = position,
                        Normal = node.Plane.Normal,
                        Uv = world.TexelsAt(surface, position),
                        LightMapUv = world.LightMapUv(node, position, layer),
                        Influences = [],
                    });
                }

                for (int i = polygon.Count - 1; i - 1 > 0; i--)
                {
                    indices.Add(start);
                    indices.Add(start + i);
                    indices.Add(start + i - 1);
                    triangles++;
                }
            }

            if (triangles == 0) continue;
            batches.Add(new LightMapBatch(group.Key.Material, group.Key.Atlas, new MeshGeometry
            {
                Vertices = vertices,
                Indices = indices,
                BoneMap = [],
                SkinnedVertexCount = 0,
                RigidVertexCount = vertices.Count,
                Sections = [new MeshSection(0, 0, vertices.Count - 1, triangles)],
            }));
        }

        return batches;
    }

    /// <summary>The distinct materials the compiled world's sections draw with, in section order.</summary>
    public static IReadOnlyList<PackageIndex> Materials(BspWorld world) => world.Nodes
        .Where(n => n.IsPolygon)
        .Where(n => n.Surface >= 0 && n.Surface < world.Surfaces.Count)
        .Where(n => world.Surfaces[n.Surface].IsDrawn)
        .GroupBy(n => world.Surfaces[n.Surface].Material.Value)
        .OrderBy(g => g.Key)
        .Select(g => new PackageIndex(g.Key))
        .ToList();

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

    /// <summary>
    /// Rescales a brush geometry's texel UVs into 0–1 space, one texture size per section.
    /// </summary>
    /// <param name="sizes">
    /// The bound texture's dimensions for each section, in section order. A null entry leaves that
    /// section's UVs alone, because a surface that resolved no texture has no size to divide by.
    /// </param>
    /// <remarks>
    /// <para>
    /// <b>This existed as <see cref="NormaliseUvs"/> and was never called, and the result was
    /// visible immediately:</b> a 512-pixel texture on a wall got UVs running 0→512 rather than
    /// 0→1, so it tiled 512 times and every brush surface in the game rendered as a dense moiré.
    /// The static meshes beside them looked correct throughout, because their UVs come from their
    /// own vertex data and never went through this path — which is exactly the kind of half-right
    /// output that reads as "the textures are a bit odd" rather than "a function is not being
    /// called".
    /// </para>
    /// <para>
    /// <b>Found by a user looking at the render.</b> Every count agreed, every surface bound a
    /// texture, and the textured-vs-untextured check passed at 51% — none of them can see a UV
    /// scale. <c>BspUvTests</c> now pins the magnitude directly.
    /// </para>
    /// </remarks>
    public static MeshGeometry NormaliseUvs(MeshGeometry geometry, IReadOnlyList<(int Width, int Height)?> sizes)
    {
        var vertices = geometry.Vertices.ToArray();

        for (int section = 0; section < geometry.Sections.Count && section < sizes.Count; section++)
        {
            if (sizes[section] is not { } size || size.Width <= 0 || size.Height <= 0) continue;

            var range = geometry.Sections[section];
            for (int i = range.FirstVertex; i <= range.LastVertex && i < vertices.Length; i++)
                vertices[i] = vertices[i] with { Uv = NormaliseUvs(vertices[i].Uv, size.Width, size.Height) };
        }

        return geometry with { Vertices = vertices };
    }

    private static Vector2 Project(BspPolygon polygon, Vector3 position)
    {
        var offset = position - polygon.Base;
        return new Vector2(Vector3.Dot(offset, polygon.TextureU), Vector3.Dot(offset, polygon.TextureV));
    }
}
