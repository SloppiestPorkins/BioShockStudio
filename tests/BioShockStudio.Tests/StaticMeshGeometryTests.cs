using System.Numerics;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Regression tests for <see cref="StaticMeshReader"/>, all against shipped bytes.
/// <para>
/// The Big Daddy's drill is the case that motivated the reader: <c>NewProtectorBouncer</c> declares
/// three sockets that name three static meshes in its own group, and until this reader existed the
/// relationship resolved but nothing could be drawn.
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
public sealed class StaticMeshGeometryTests(GameFixture game)
{
    private string MedicalPackage =>
        Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");

    private byte[] Payload(string packageFile, string objectName)
    {
        using var package = BioShockPackage.Open(packageFile);
        var export = package.Exports
            .Where(e => e.ObjectName == objectName && package.GetClassName(e) == AssetClasses.StaticMesh)
            .MaxBy(e => e.SerialSize)
            ?? throw new InvalidOperationException($"{objectName} is not a StaticMesh in {packageFile}.");
        return package.ReadExportData(export);
    }

    private MeshGeometry Drill() => StaticMeshReader.ReadGeometry(Payload(MedicalPackage, "ConeDrill"))!;

    [RequiresGameFact]
    public void Drill_DecodesToKnownCounts()
    {
        var geometry = Drill();

        Assert.Equal(561, geometry.Vertices.Count);
        Assert.Equal(562, geometry.TriangleCount);
        Assert.Equal(1686, geometry.Indices.Count);
        Assert.Equal(0, geometry.ExtraUvStreamCount);
    }

    [RequiresGameFact]
    public void Drill_CarriesNoSkinning()
    {
        var geometry = Drill();

        // A static mesh binds to no skeleton. Saying so explicitly is what stops the exporter from
        // writing an armature for something that has none.
        Assert.False(geometry.IsSkinned);
        Assert.Empty(geometry.BoneMap);
        Assert.Equal(0, geometry.SkinnedVertexCount);
        Assert.Equal(0, geometry.RigidVertexCount);
        Assert.All(geometry.Vertices, v => Assert.Empty(v.Influences));
    }

    [RequiresGameFact]
    public void Drill_IndicesAddressTheVertexPoolExactly()
    {
        var geometry = Drill();

        Assert.Equal(0, geometry.Indices.Count % 3);
        Assert.All(geometry.Indices, i => Assert.InRange(i, 0, geometry.Vertices.Count - 1));
        Assert.Equal(geometry.Vertices.Count - 1, geometry.Indices.Max());

        // Every vertex is used by at least one triangle: the buffer covers the pool and nothing else.
        Assert.Equal(geometry.Vertices.Count, geometry.Indices.Distinct().Count());
    }

    [RequiresGameFact]
    public void Drill_TrianglesAreSmallAgainstTheModel()
    {
        var geometry = Drill();

        // The index-order landmine from the skeletal reader: a wrong pool ordering still produces a
        // valid-looking index buffer, and only triangle size gives it away. The drill is ~71 units
        // long, so a median edge in single figures means the triangles are local to the surface.
        var edges = new List<float>();
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

        Assert.InRange(edges[edges.Count / 2], 0.1f, 12f);
        Assert.Equal(0, geometry.Indices.Chunk(3).Count(t => t[0] == t[1] || t[1] == t[2] || t[0] == t[2]));
    }

    [RequiresGameFact]
    public void Drill_UvsOccupyASensibleRange()
    {
        var geometry = Drill();

        Assert.All(geometry.Vertices, v =>
        {
            Assert.InRange(v.Uv.X, -1f, 2f);
            Assert.InRange(v.Uv.Y, -1f, 2f);
        });

        // A decode error tends to collapse the UVs onto a point or scatter them over huge values.
        Assert.True(geometry.Vertices.Max(v => v.Uv.X) - geometry.Vertices.Min(v => v.Uv.X) > 0.5f);
        Assert.True(geometry.Vertices.Max(v => v.Uv.Y) - geometry.Vertices.Min(v => v.Uv.Y) > 0.5f);
    }

    [RequiresGameFact]
    public void BigDaddyAttachments_AllDecode()
    {
        // The three meshes the Bouncer's sockets name. This is the case §6.1 of the handoff was for.
        foreach (string name in new[] { "ConeDrill", "ConeDrillCage", "ConeDrillBackpack" })
        {
            var geometry = StaticMeshReader.ReadGeometry(Payload(MedicalPackage, name));
            Assert.NotNull(geometry);
            Assert.True(geometry.TriangleCount > 0, $"{name} decoded to no triangles.");
            Assert.All(geometry.Vertices, v => Assert.True(float.IsFinite(v.Position.X)));
        }
    }

    [RequiresGameFact]
    public void Wrench_DecodesFromTheWeaponPackage()
    {
        // The wrench ships as a static prop rather than a rig, which is why the skeletal reader
        // never found geometry for it.
        var geometry = StaticMeshReader.ReadGeometry(Payload(game.WeaponPackage, "WP_WrenchMesh"))!;

        Assert.Equal(3153, geometry.Vertices.Count);
        Assert.Equal(3696, geometry.TriangleCount);
        Assert.False(geometry.IsSkinned);
    }

    [RequiresGameFact]
    public void EveryStaticMeshInAPackageDecodes()
    {
        using var package = BioShockPackage.Open(MedicalPackage);
        var exports = package.Exports.Where(e => package.GetClassName(e) == AssetClasses.StaticMesh).ToList();

        Assert.Equal(610, exports.Count);

        var failed = new List<string>();
        foreach (var export in exports)
        {
            if (StaticMeshReader.ReadGeometry(package.ReadExportData(export)) is null)
                failed.Add(export.ObjectName);
        }

        // "A parse that looks right once is not a result." The claim is the whole package, not a
        // hand-picked mesh.
        Assert.Empty(failed);
    }

    [RequiresGameFact]
    public void DecodedVerticesSitInsideEachMeshsOwnBounds()
    {
        using var package = BioShockPackage.Open(MedicalPackage);

        foreach (var export in package.Exports.Where(e => package.GetClassName(e) == AssetClasses.StaticMesh))
        {
            byte[] payload = package.ReadExportData(export);
            var geometry = StaticMeshReader.ReadGeometry(payload)!;

            // Not a tautology of the reader's own guard: this recomputes the extent from the decoded
            // vertices and asserts it is a real, non-degenerate volume at model scale.
            var min = new Vector3(
                geometry.Vertices.Min(v => v.Position.X),
                geometry.Vertices.Min(v => v.Position.Y),
                geometry.Vertices.Min(v => v.Position.Z));
            var max = new Vector3(
                geometry.Vertices.Max(v => v.Position.X),
                geometry.Vertices.Max(v => v.Position.Y),
                geometry.Vertices.Max(v => v.Position.Z));

            Assert.True((max - min).Length() > 0.001f, $"{export.ObjectName} decoded to a degenerate extent.");
            Assert.True((max - min).Length() < 100_000f, $"{export.ObjectName} decoded to an exploded extent.");
        }
    }

    [RequiresGameFact]
    public void MultipleUvStreamsAreReportedRatherThanDropped()
    {
        using var package = BioShockPackage.Open(MedicalPackage);

        int extra = 0;
        foreach (var export in package.Exports.Where(e => package.GetClassName(e) == AssetClasses.StaticMesh))
        {
            var geometry = StaticMeshReader.ReadGeometry(package.ReadExportData(export))!;
            if (geometry.ExtraUvStreamCount > 0) extra++;
        }

        // 52 of the 610 ship a second stream. The export carries the first; the count is how the
        // tool admits the rest are being left behind.
        Assert.Equal(52, extra);
    }

    [RequiresGameFact]
    public void ReaderRefusesASkeletalPayload()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var hands = package.Exports
            .Where(e => e.ObjectName == "NEWPlayerHands" && package.GetClassName(e) == AssetClasses.SkeletalMesh)
            .MaxBy(e => e.SerialSize)!;

        // The skinned container is a different shape. The static reader must not find a plausible
        // chain in it — a false positive here would silently replace a skinned mesh with rubbish.
        Assert.Null(StaticMeshReader.ReadGeometry(package.ReadExportData(hands)));
    }

    [RequiresGameFact]
    public void FacadeRoutesOnClassName()
    {
        using var package = BioShockPackage.Open(MedicalPackage);
        var drill = package.Exports
            .Where(e => e.ObjectName == "ConeDrill" && package.GetClassName(e) == AssetClasses.StaticMesh)
            .MaxBy(e => e.SerialSize)!;

        byte[] payload = package.ReadExportData(drill);

        Assert.NotNull(MeshGeometryReader.Read(AssetClasses.StaticMesh, payload));
        Assert.Null(MeshGeometryReader.Read("Texture2D", payload));
        Assert.True(MeshGeometryReader.IsMeshClass(AssetClasses.StaticMesh));
        Assert.False(MeshGeometryReader.IsMeshClass("Texture2D"));
    }
}
