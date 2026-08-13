using System.Numerics;

namespace BioShockStudio.Core.Mesh;

/// <summary>One skin influence: a skeleton bone index and its weight in 0..1.</summary>
public readonly record struct SkinInfluence(int BoneIndex, float Weight);

/// <summary>A decoded mesh vertex, already resolved onto skeleton bone indices.</summary>
public sealed record MeshVertex
{
    public required Vector3 Position { get; init; }
    public required Vector3 Normal { get; init; }

    /// <summary>
    /// Tangent basis, as shipped. The game stores a tangent and a binormal per vertex alongside the
    /// normal; both are needed to apply a tangent-space normal map without inventing a basis.
    /// </summary>
    public Vector3 Tangent { get; init; }

    public Vector3 Binormal { get; init; }

    public required Vector2 Uv { get; init; }

    /// <summary>Influences with a non-zero weight. Never truncated to satisfy an exporter limit.</summary>
    public required IReadOnlyList<SkinInfluence> Influences { get; init; }
}

/// <summary>
/// Geometry of a mesh: one vertex pool plus a triangle list.
/// <para>
/// Both mesh classes decode into this. A <c>SkeletalMesh</c> fills the bone map and the influences;
/// a <c>StaticMesh</c> has neither, so <see cref="IsSkinned"/> is false and every vertex carries an
/// empty influence list. Nothing downstream needs to know which reader produced it.
/// </para>
/// </summary>
public sealed record MeshGeometry
{
    public required IReadOnlyList<MeshVertex> Vertices { get; init; }

    /// <summary>Triangle corner indices into <see cref="Vertices"/>, three per face.</summary>
    public required IReadOnlyList<int> Indices { get; init; }

    /// <summary>Mesh-local bone slot to skeleton bone index. Empty for a static mesh.</summary>
    public required IReadOnlyList<int> BoneMap { get; init; }

    /// <summary>Vertices carrying full skin influences. Zero for a static mesh.</summary>
    public required int SkinnedVertexCount { get; init; }

    /// <summary>Vertices bound rigidly to a single bone. Zero for a static mesh.</summary>
    public required int RigidVertexCount { get; init; }

    /// <summary>
    /// Extra UV streams the mesh ships beyond the first, which are read but not carried: a
    /// <see cref="MeshVertex"/> holds one UV. Non-zero means the export drops a lightmap or detail
    /// channel, and says so rather than pretending the mesh had one set.
    /// </summary>
    public int ExtraUvStreamCount { get; init; }

    /// <summary>Whether the vertices are bound to a skeleton at all.</summary>
    public bool IsSkinned => BoneMap.Count > 0;

    public int TriangleCount => Indices.Count / 3;
}
