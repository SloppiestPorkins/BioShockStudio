using System.Numerics;

namespace BioShockStudio.Core.Mesh;

/// <summary>One skin influence: a skeleton bone index and its weight in 0..1.</summary>
public readonly record struct SkinInfluence(int BoneIndex, float Weight);

/// <summary>A decoded mesh vertex, already resolved onto skeleton bone indices.</summary>
public sealed record MeshVertex
{
    public required Vector3 Position { get; init; }
    public required Vector3 Normal { get; init; }
    public required Vector2 Uv { get; init; }

    /// <summary>Influences with a non-zero weight. Never truncated to satisfy an exporter limit.</summary>
    public required IReadOnlyList<SkinInfluence> Influences { get; init; }
}

/// <summary>Geometry of a <c>SkeletalMesh</c>: one vertex pool plus a triangle list.</summary>
public sealed record SkeletalMeshGeometry
{
    public required IReadOnlyList<MeshVertex> Vertices { get; init; }

    /// <summary>Triangle corner indices into <see cref="Vertices"/>, three per face.</summary>
    public required IReadOnlyList<int> Indices { get; init; }

    /// <summary>Mesh-local bone slot to skeleton bone index.</summary>
    public required IReadOnlyList<int> BoneMap { get; init; }

    /// <summary>Vertices carrying full skin influences.</summary>
    public required int SkinnedVertexCount { get; init; }

    /// <summary>Vertices bound rigidly to a single bone.</summary>
    public required int RigidVertexCount { get; init; }

    public int TriangleCount => Indices.Count / 3;
}
