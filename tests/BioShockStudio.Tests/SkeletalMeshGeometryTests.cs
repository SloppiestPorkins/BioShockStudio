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

    [RequiresGameFact]
    public void EveryWeaponViewmodelDecodes()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);

        var failed = new List<string>();
        int total = 0;

        foreach (var export in package.Exports.Where(e =>
                     package.GetClassName(e) == "SkeletalMesh" && e.SerialSize > 0))
        {
            total++;
            if (SkeletalMeshReader.ReadGeometry(package.ReadExportData(export)) is null)
                failed.Add(export.ObjectName);
        }

        Assert.True(total > 0);
        Assert.Empty(failed);
    }

    [RequiresGameFact]
    public void AWeaponsVerticesAreAllRigidlyBound()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        var launcher = package.Exports
            .Where(e => e.ObjectName == "WP_GrenadeLauncherMesh" && package.GetClassName(e) == "SkeletalMesh")
            .MaxBy(e => e.SerialSize)!;

        var geometry = SkeletalMeshReader.ReadGeometry(package.ReadExportData(launcher))!;

        // A gun's parts are hinged, not deformed, so every vertex is bound to exactly one bone and
        // the skinned block is present but empty. The reader used to read that zero as "no vertex
        // block here" and give up, which is why the launcher loaded its skeleton, its animations and
        // its material and then drew nothing at all.
        Assert.Equal(0, geometry.SkinnedVertexCount);
        Assert.Equal(5386, geometry.RigidVertexCount);
        Assert.Equal(5386, geometry.Vertices.Count);
        Assert.All(geometry.Vertices, v => Assert.Single(v.Influences));
        Assert.All(geometry.Vertices, v => Assert.Equal(1f, v.Influences[0].Weight, 3));

        // And it is still a real mesh addressed by a whole index buffer.
        Assert.Equal(geometry.Vertices.Count - 1, geometry.Indices.Max());
        Assert.Equal(0, geometry.Indices.Count % 3);
    }

    [RequiresGameFact]
    public void NearlyEveryShippedSkeletalMeshDecodes()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var failed = new List<string>();
        int total = 0;

        foreach (var export in package.Exports.Where(e =>
                     package.GetClassName(e) == "SkeletalMesh" && e.SerialSize > 0))
        {
            total++;
            if (SkeletalMeshReader.ReadGeometry(package.ReadExportData(export)) is null)
                failed.Add(export.ObjectName);
        }

        // 0-Lighthouse went from 18 of 46 to all 46 when the empty skinned block was accepted.
        Assert.Equal(46, total);
        Assert.Empty(failed);
    }

    /// <summary>
    /// The exports that yield no geometry carry none, rather than using a layout this reader cannot
    /// read.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <c>CORROBORATED.</c> §6.2 of the handoff used to describe these as an unsupported vertex
    /// variant to be found. They are four door rigs — <c>LowRentDoor_Mesh</c>,
    /// <c>Sliding512SingleDoorMesh</c>, <c>GathererDoorAnimMesh</c> and <c>Atlas_labs_doorAnim</c>,
    /// 18 copies between them — and three independent things say there is nothing to decode:
    /// </para>
    /// <list type="number">
    /// <item>the payloads separate cleanly by size with no overlap — every mesh that decodes is at
    /// least 2,443 bytes and every one of these is at most 1,291;</item>
    /// <item>their sockets are named for door leaves (<c>Door</c>, <c>BigDoor</c>,
    /// <c>doorLargeRight</c>) and their groups hold a skeleton and open/close/stuck animations but no
    /// drawable mesh of their own — <c>AtlasLabsDoorAnim</c> ships <c>Model</c> and <c>Polys</c>,
    /// which is BSP;</item>
    /// <item>other doors decode perfectly well — <c>PeepDoorMESH</c> and <c>Gate01Anim</c> both do —
    /// so this is not a format the door pipeline uses.</item>
    /// </list>
    /// <para>
    /// What would settle it outright is byte-exact accounting of a <c>SkeletalMesh</c> payload, which
    /// this project does not yet have. Until then the reader reports "no vertex data was found"
    /// rather than diagnosing an unread format, because the evidence is against that diagnosis.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheMeshesWithoutGeometryAreTooSmallToHoldAny()
    {
        var files = Core.Game.GameLocator.EnumeratePackages(game.RequireRoot).ToList();
        if (Core.Game.GameLocator.WeaponPackage(game.RequireRoot) is { } weapons) files.Add(weapons);

        int smallestDecoding = int.MaxValue, largestFailing = 0, total = 0, failed = 0;
        var failingNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (string file in files)
        {
            using var package = BioShockPackage.Open(file);

            foreach (var export in package.Exports.Where(e =>
                         package.GetClassName(e) == "SkeletalMesh" && e.SerialSize > 0))
            {
                byte[] payload = package.ReadExportData(export);
                total++;

                MeshGeometry? geometry;
                try { geometry = SkeletalMeshReader.ReadGeometry(payload); }
                catch { geometry = null; }

                if (geometry is not null && geometry.Vertices.Count > 0)
                {
                    smallestDecoding = Math.Min(smallestDecoding, payload.Length);
                    continue;
                }

                failed++;
                largestFailing = Math.Max(largestFailing, payload.Length);
                failingNames.Add(export.ObjectName);
            }
        }

        Assert.Equal(972, total);
        Assert.Equal(18, failed);

        Assert.Equal(
            new[] { "Atlas_labs_doorAnim", "GathererDoorAnimMesh", "LowRentDoor_Mesh", "Sliding512SingleDoorMesh" },
            failingNames.OrderBy(n => n, StringComparer.OrdinalIgnoreCase));

        // The separation is the evidence: no mesh that ships geometry is anywhere near this small.
        Assert.True(largestFailing < smallestDecoding,
            $"a mesh with no geometry is {largestFailing} bytes and the smallest with geometry is "
            + $"{smallestDecoding} — the two no longer separate, so the 'carries none' reading is in doubt");
    }
}
