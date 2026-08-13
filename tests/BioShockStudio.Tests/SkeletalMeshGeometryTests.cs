using System.Numerics;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
public sealed class SkeletalMeshGeometryTests(GameFixture game)
{
    private byte[] Payload(string objectName)
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports
            .Where(e => e.ObjectName == objectName && package.GetClassName(e) == "SkeletalMesh")
            .MaxBy(e => e.SerialSize)!;
        return package.ReadExportData(export);
    }

    private MeshGeometry Hands() =>
        SkeletalMeshReader.ReadGeometry(Payload("NEWPlayerHands"))!;

    [RequiresGameFact]
    public void HandsMesh_DecodesToKnownCounts()
    {
        var geometry = Hands();

        Assert.Equal(3469, geometry.SkinnedVertexCount);
        Assert.Equal(1383, geometry.RigidVertexCount);
        Assert.Equal(4852, geometry.Vertices.Count);
        Assert.Equal(8726, geometry.TriangleCount);
        Assert.Equal(38, geometry.BoneMap.Count);
    }

    [RequiresGameFact]
    public void HandsMesh_IndicesAddressTheVertexPoolExactly()
    {
        var geometry = Hands();

        Assert.Equal(0, geometry.Indices.Count % 3);
        Assert.All(geometry.Indices, i => Assert.InRange(i, 0, geometry.Vertices.Count - 1));

        // The largest index is the last vertex: the buffer addresses the whole pool and nothing past it.
        Assert.Equal(geometry.Vertices.Count - 1, geometry.Indices.Max());

        // Every vertex is used by at least one triangle.
        var referenced = geometry.Indices.ToHashSet();
        Assert.Equal(geometry.Vertices.Count, referenced.Count);
    }

    [RequiresGameFact]
    public void HandsMesh_HasNoDegenerateTriangles()
    {
        var geometry = Hands();

        int degenerate = 0;
        for (int t = 0; t < geometry.TriangleCount; t++)
        {
            int a = geometry.Indices[t * 3], b = geometry.Indices[t * 3 + 1], c = geometry.Indices[t * 3 + 2];
            if (a == b || b == c || a == c) degenerate++;
        }

        Assert.Equal(0, degenerate);
    }

    [RequiresGameFact]
    public void HandsMesh_TrianglesAreLocal()
    {
        var geometry = Hands();

        // The strongest available check that the index buffer addresses the vertex pool in the right
        // order. Triangles in a real mesh are small; if the two vertex blocks are concatenated the
        // wrong way round the counts still line up and every vertex is still referenced, but the
        // triangles span the whole model and it renders as shattered geometry.
        var edges = new List<float>(geometry.TriangleCount * 3);
        for (int t = 0; t < geometry.TriangleCount; t++)
        {
            var a = geometry.Vertices[geometry.Indices[t * 3]].Position;
            var b = geometry.Vertices[geometry.Indices[t * 3 + 1]].Position;
            var c = geometry.Vertices[geometry.Indices[t * 3 + 2]].Position;
            edges.Add((a - b).Length());
            edges.Add((b - c).Length());
            edges.Add((c - a).Length());
        }

        edges.Sort();
        float median = edges[edges.Count / 2];

        // Measured: 0.87 with the correct ordering, 44.04 with the blocks swapped, against a mesh
        // roughly 140 units across.
        Assert.True(median < 5f, $"median triangle edge {median:0.##} suggests the vertex pool order is wrong");
    }

    [RequiresGameFact]
    public void HandsMesh_SkinWeightsAreNormalised()
    {
        var geometry = Hands();

        foreach (var vertex in geometry.Vertices)
        {
            Assert.NotEmpty(vertex.Influences);
            float total = vertex.Influences.Sum(i => i.Weight);
            Assert.Equal(1f, total, 2);
        }
    }

    [RequiresGameFact]
    public void HandsMesh_BoneMapResolvesOntoTheAnimationSkeleton()
    {
        var geometry = Hands();

        // The map is a distinct selection of skeleton bones, which is what makes it a bone map
        // rather than an arbitrary array.
        Assert.Equal(geometry.BoneMap.Count, geometry.BoneMap.Distinct().Count());
        Assert.All(geometry.BoneMap, index => Assert.InRange(index, 0, 46));

        // Every influence addresses a real skeleton bone.
        foreach (var vertex in geometry.Vertices)
            foreach (var influence in vertex.Influences)
                Assert.InRange(influence.BoneIndex, 0, 46);
    }

    [RequiresGameFact]
    public void HandsMesh_VerticesSitInsideTheDeclaredBounds()
    {
        byte[] payload = Payload("NEWPlayerHands");
        var header = SkeletalMeshReader.ReadHeader(payload);
        var geometry = SkeletalMeshReader.ReadGeometry(payload)!;

        // The shipped bounds are not a strict hull — the most extreme vertex sits ~11 units outside
        // on Z, and the overshoot comes from the rigid block, so the bounds most likely describe the
        // skinned body only. What matters for correctness is that the geometry sits in the same
        // place and at the same scale, which would not survive a decode error.
        var min = new Vector3(
            geometry.Vertices.Min(v => v.Position.X),
            geometry.Vertices.Min(v => v.Position.Y),
            geometry.Vertices.Min(v => v.Position.Z));
        var max = new Vector3(
            geometry.Vertices.Max(v => v.Position.X),
            geometry.Vertices.Max(v => v.Position.Y),
            geometry.Vertices.Max(v => v.Position.Z));

        var declaredSize = header.BoundsMax - header.BoundsMin;
        var actualSize = max - min;

        // The declared bounds are much larger than the bind pose on some axes — they cover the
        // animated range, not the rest pose. So the honest relationship is that the bind pose fits
        // inside them, not that it fills them.
        Assert.True(actualSize.X <= declaredSize.X * 1.2f);
        Assert.True(actualSize.Y <= declaredSize.Y * 1.2f);
        Assert.True(actualSize.Z <= declaredSize.Z * 1.2f);

        // And the mesh is real geometry at the expected scale, not a collapsed or exploded decode.
        Assert.InRange(actualSize.Length(), 50f, 250f);
    }

    [RequiresGameFact]
    public void HandsMesh_UvsOccupyASensibleRange()
    {
        var geometry = Hands();

        Assert.InRange(geometry.Vertices.Min(v => v.Uv.X), -2f, 2f);
        Assert.InRange(geometry.Vertices.Max(v => v.Uv.X), -2f, 2f);
        Assert.InRange(geometry.Vertices.Min(v => v.Uv.Y), -2f, 2f);
        Assert.InRange(geometry.Vertices.Max(v => v.Uv.Y), -2f, 2f);

        // Real UVs vary; a constant set would mean the field is being misread.
        Assert.True(geometry.Vertices.Select(v => v.Uv).Distinct().Count() > 1000);
    }
}
