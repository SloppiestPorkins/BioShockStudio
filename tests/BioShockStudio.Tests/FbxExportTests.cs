using System.Numerics;
using System.Text.Json;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Export.Fbx;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers the FBX writer against the hands scene the rest of the suite uses.
/// <para>
/// These assert the container and the object graph. What they cannot assert is that another program
/// reads the file the way this one meant it — <c>tools/blender/validate_fbx.py</c> does that, by
/// importing the output into Blender and comparing rest matrices, skin weights and posed bone
/// positions against transforms composed independently from the game's own track data.
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
public sealed class FbxExportTests(GameFixture game)
{
    private AnimationScene HandsScene(string owner = "Pistol")
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var wrapper = package.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper);
        var meshExport = package.Exports
            .Where(e => e.ObjectName == "NEWPlayerHands" && package.GetClassName(e) == AssetClasses.SkeletalMesh)
            .MaxBy(e => e.SerialSize)!;

        byte[] payload = package.ReadExportData(meshExport);
        var animations = AnimationPackage.Load(package, wrapper);

        return AnimationSceneExporter.Build(
            animations,
            owner,
            SkeletalMeshReader.ReadSockets(payload, package.Names),
            SkeletalMeshReader.ReadGeometry(payload),
            Events(package, animations));
    }

    /// <summary>Each animation's event track, from its SharedSkeletonAnimationMetadata sibling.</summary>
    private static IReadOnlyDictionary<string, IReadOnlyList<AnimationEvent>> Events(
        BioShockPackage package, AnimationPackage animations)
    {
        var metadata = package.Exports
            .Where(e => package.GetClassName(e) == AnimationMetadataReader.ClassName)
            .GroupBy(e => e.ObjectName, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

        var result = new Dictionary<string, IReadOnlyList<AnimationEvent>>(StringComparer.Ordinal);
        foreach (var animation in animations.Animations)
        {
            if (!metadata.TryGetValue(AnimationMetadataReader.ObjectPrefix + animation.Name, out var export)) continue;
            var events = AnimationMetadataReader.ReadEvents(package, export, animation.Duration);
            if (events.Count > 0) result[animation.Name] = events;
        }
        return result;
    }

    private static IReadOnlyList<FbxRecord> WriteAndRead(AnimationScene scene, FbxExportOptions options)
    {
        using var stream = new MemoryStream();
        FbxWriter.Write(stream, FbxSceneBuilder.Build(scene, options));
        return FbxTestReader.Read(stream.ToArray());
    }

    private static FbxRecord Objects(IReadOnlyList<FbxRecord> roots) => roots.First(r => r.Name == "Objects");

    private static FbxRecord Connections(IReadOnlyList<FbxRecord> roots) => roots.First(r => r.Name == "Connections");

    [RequiresGameFact]
    public void Container_ParsesBackRecordForRecord()
    {
        var roots = WriteAndRead(HandsScene(), new FbxExportOptions());

        // An independent reader walking to the footer proves every record's end offset was right,
        // which is the one framing error that produces a file no importer can open.
        Assert.Contains(roots, r => r.Name == "FBXHeaderExtension");
        Assert.Contains(roots, r => r.Name == "GlobalSettings");
        Assert.Contains(roots, r => r.Name == "Definitions");
        Assert.Contains(roots, r => r.Name == "Objects");
        Assert.Contains(roots, r => r.Name == "Connections");
    }

    [RequiresGameFact]
    public void Definitions_CountEveryObjectThatWasWritten()
    {
        var roots = WriteAndRead(HandsScene(), new FbxExportOptions());

        var definitions = roots.First(r => r.Name == "Definitions");
        var objects = Objects(roots);

        foreach (var type in definitions.FindAll("ObjectType"))
        {
            string name = (string)type.Properties[0];
            if (name == "GlobalSettings") continue;
            int declared = (int)type.Find("Count")!.Properties[0];
            Assert.Equal(objects.Children.Count(c => c.Name == name), declared);
        }
    }

    [RequiresGameFact]
    public void Skeleton_IsWrittenAsOneLimbNodePerBoneInTheGamesOwnOrder()
    {
        var scene = HandsScene();
        var roots = WriteAndRead(scene, new FbxExportOptions());

        var limbs = Objects(roots).FindAll("Model").Where(m => m.SubClass == "LimbNode").ToList();

        Assert.Equal(scene.Bones.Count, limbs.Count);
        Assert.Equal(scene.Bones.Select(b => b.Name), limbs.Select(m => m.ObjectName));
    }

    [RequiresGameFact]
    public void Skeleton_ParentsEveryBoneOntoTheBoneTheGameNames()
    {
        var scene = HandsScene();
        var roots = WriteAndRead(scene, new FbxExportOptions());

        var limbs = Objects(roots).FindAll("Model").Where(m => m.SubClass == "LimbNode").ToList();
        var idOf = limbs.Select((m, i) => (Id: (long)m.Properties[0], Index: i)).ToDictionary(p => p.Id, p => p.Index);

        // A bone model appears as the child of its parent bone and, later, of every skin cluster that
        // deforms with it. The first connection is the hierarchy one.
        var parentOf = new Dictionary<int, long>();
        foreach (var connection in Connections(roots).FindAll("C"))
        {
            if ((string)connection.Properties[0] != "OO") continue;
            long child = (long)connection.Properties[1];
            if (idOf.TryGetValue(child, out int index)) parentOf.TryAdd(index, (long)connection.Properties[2]);
        }

        for (int i = 0; i < scene.Bones.Count; i++)
        {
            long parent = parentOf[i];
            // The document root node is id 0; every other bone hangs off its own parent's model.
            int expected = scene.Bones[i].Parent;
            Assert.Equal(expected < 0 ? 0 : (long)limbs[expected].Properties[0], parent);
        }
    }

    [RequiresGameFact]
    public void Mesh_KeepsEveryVertexAndTriangle()
    {
        var scene = HandsScene();
        var roots = WriteAndRead(scene, new FbxExportOptions());

        var geometry = Objects(roots).FindAll("Geometry").Single();
        var vertices = (double[])geometry.Find("Vertices")!.Properties[0];
        var polygons = (int[])geometry.Find("PolygonVertexIndex")!.Properties[0];

        Assert.Equal(scene.Mesh!.Positions.Length, vertices.Length);
        Assert.Equal(scene.Mesh.Triangles.Length, polygons.Length);

        // Every third index is the last corner of a triangle, which FBX marks by complementing it.
        for (int i = 0; i < polygons.Length; i++)
            Assert.Equal(scene.Mesh.Triangles[i], i % 3 == 2 ? ~polygons[i] : polygons[i]);
    }

    [RequiresGameFact]
    public void Skin_WeightsEveryVertexExactlyAsTheGameDoes()
    {
        var scene = HandsScene();
        var roots = WriteAndRead(scene, new FbxExportOptions());

        var clusters = Objects(roots).FindAll("Deformer").Where(d => d.SubClass == "Cluster").ToList();
        Assert.NotEmpty(clusters);

        var totals = new float[scene.Mesh!.Positions.Length / 3];
        foreach (var cluster in clusters)
        {
            var indexes = (int[])cluster.Find("Indexes")!.Properties[0];
            var weights = (double[])cluster.Find("Weights")!.Properties[0];
            Assert.Equal(indexes.Length, weights.Length);

            for (int i = 0; i < indexes.Length; i++) totals[indexes[i]] += (float)weights[i];
        }

        for (int vertex = 0; vertex < totals.Length; vertex++) Assert.Equal(1f, totals[vertex], 3);
    }

    [RequiresGameFact]
    public void Skin_BindMatricesAreTheReferencePoseAndItsInverse()
    {
        var scene = HandsScene();
        var roots = WriteAndRead(scene, new FbxExportOptions());

        foreach (var cluster in Objects(roots).FindAll("Deformer").Where(d => d.SubClass == "Cluster"))
        {
            var transform = ToMatrix((double[])cluster.Find("Transform")!.Properties[0]);
            var link = ToMatrix((double[])cluster.Find("TransformLink")!.Properties[0]);

            // The mesh sits at the origin of skeleton space, so the pair must cancel exactly.
            var product = transform * link;
            for (int row = 1; row <= 4; row++)
                for (int column = 1; column <= 4; column++)
                    Assert.Equal(row == column ? 1f : 0f, Element(product, row, column), 3);
        }
    }

    [RequiresGameFact]
    public void Sockets_BecomeNullNodesUnderTheBoneTheMeshNames()
    {
        var scene = HandsScene();
        var roots = WriteAndRead(scene, new FbxExportOptions());

        var nulls = Objects(roots).FindAll("Model").Where(m => m.SubClass == "Null").ToList();
        Assert.Equal(scene.Sockets.Count, nulls.Count);

        var pistol = nulls.Single(n => n.ObjectName == FbxSceneBuilder.SocketPrefix + "Pistol");
        var limbs = Objects(roots).FindAll("Model").Where(m => m.SubClass == "LimbNode").ToList();

        long parent = Connections(roots).FindAll("C")
            .Where(c => (string)c.Properties[0] == "OO" && (long)c.Properties[1] == (long)pistol.Properties[0])
            .Select(c => (long)c.Properties[2])
            .Single();

        // The mesh writes R_Grip and the skeleton writes R_grip; the socket must still land on it.
        var bone = limbs.Single(m => (long)m.Properties[0] == parent);
        Assert.Equal("R_grip", bone.ObjectName, ignoreCase: true);
    }

    [RequiresGameFact]
    public void MeshFile_CarriesNoAnimation()
    {
        var roots = WriteAndRead(HandsScene(), new FbxExportOptions());
        Assert.Empty(Objects(roots).FindAll("AnimationStack"));
    }

    [RequiresGameFact]
    public void Take_KeysEveryBoundTrackAtTheGamesOwnSampleTimes()
    {
        var scene = HandsScene();
        var animation = scene.Animations.Single(a => a.Name == "FastReloadPistol");
        var roots = WriteAndRead(scene, new FbxExportOptions { Animation = animation.Name, IncludeMesh = false });

        Assert.Single(Objects(roots).FindAll("AnimationStack"));
        Assert.Single(Objects(roots).FindAll("AnimationLayer"));

        // One curve node per animated property, one curve per component.
        Assert.Equal(animation.Tracks.Count * 3, Objects(roots).FindAll("AnimationCurveNode").Count());

        var curves = Objects(roots).FindAll("AnimationCurve").ToList();
        Assert.Equal(animation.Tracks.Count * 9, curves.Count);

        foreach (var curve in curves)
        {
            var times = (long[])curve.Find("KeyTime")!.Properties[0];
            var values = (float[])curve.Find("KeyValueFloat")!.Properties[0];

            Assert.Equal(animation.FrameCount, times.Length);
            Assert.Equal(animation.FrameCount, values.Length);
            Assert.Equal(0L, times[0]);

            // Times are absolute, so the authored rate survives even though it is not an integer.
            for (int frame = 0; frame < times.Length; frame++)
                Assert.Equal(FbxMath.ToTicks((double)frame * animation.FrameDuration), times[frame]);
        }
    }

    [RequiresGameFact]
    public void Take_DeclaresTheAnimationsOwnFrameRateRatherThanANominalOne()
    {
        var scene = HandsScene();
        var animation = scene.Animations.Single(a => a.Name == "ZoomingOutPistol");
        var roots = WriteAndRead(scene, new FbxExportOptions { Animation = animation.Name, IncludeMesh = false });

        var settings = roots.First(r => r.Name == "GlobalSettings").Find("Properties70")!;
        double rate = settings.FindAll("P")
            .Where(p => (string)p.Properties[0] == "CustomFrameRate")
            .Select(p => (double)p.Properties[4])
            .Single();

        // This one is authored at 27.02 fps. Rounding it to 30 would silently change the timing.
        Assert.Equal(1f / animation.FrameDuration, rate, 2);
        Assert.NotEqual(30.0, rate, 2);
    }

    /// <summary>
    /// FBX has no quaternion channel for a node's local rotation, so the exporter converts to Euler
    /// angles. This pins the convention down against the real bone rotations rather than a synthetic
    /// one: a wrong composition order still produces a rig that animates and looks plausible.
    /// </summary>
    [RequiresGameFact]
    public void EulerConversion_RecomposesEveryBoneRotationExactly()
    {
        var scene = HandsScene();
        float worst = 0f;

        foreach (var bone in scene.Bones)
        {
            var rotation = Quaternion.Normalize(
                new Quaternion(bone.Rotation[0], bone.Rotation[1], bone.Rotation[2], bone.Rotation[3]));
            var euler = FbxMath.ToEulerDegrees(rotation);

            // FBX's default rotation order composes as Rz · Ry · Rx on column vectors, which is
            // Rx · Ry · Rz in System.Numerics' row-vector convention.
            const float ToRadians = MathF.PI / 180f;
            var recomposed =
                Matrix4x4.CreateRotationX(euler.X * ToRadians)
                * Matrix4x4.CreateRotationY(euler.Y * ToRadians)
                * Matrix4x4.CreateRotationZ(euler.Z * ToRadians);

            var expected = Matrix4x4.CreateFromQuaternion(rotation);
            for (int row = 1; row <= 3; row++)
                for (int column = 1; column <= 3; column++)
                    worst = MathF.Max(worst, MathF.Abs(Element(recomposed, row, column) - Element(expected, row, column)));
        }

        Assert.True(worst < 1e-4f, $"worst rotation element error {worst}");
    }

    [RequiresGameFact]
    public void EulerConversion_KeepsConsecutiveFramesOnTheSameBranch()
    {
        var scene = HandsScene();
        var animation = scene.Animations.Single(a => a.Name == "FastReloadPistol");

        foreach (var track in animation.Tracks)
        {
            var previous = Vector3.Zero;
            for (int frame = 0; frame < animation.FrameCount; frame++)
            {
                var euler = FbxMath.ToEulerDegrees(new Quaternion(
                    track.Rotations[frame * 4], track.Rotations[frame * 4 + 1],
                    track.Rotations[frame * 4 + 2], track.Rotations[frame * 4 + 3]));
                if (frame == 0) { previous = euler; continue; }

                euler = FbxMath.MakeCompatible(previous, euler);

                // A bone that moves a little between two frames of a 30 fps animation must not jump
                // most of a turn in Euler space; that would interpolate as a spin.
                float step = MathF.Abs(euler.X - previous.X) + MathF.Abs(euler.Y - previous.Y)
                             + MathF.Abs(euler.Z - previous.Z);
                Assert.True(step < 180f, $"{track.BoneIndex} frame {frame} jumped {step} degrees");
                previous = euler;
            }
        }
    }

    [RequiresGameFact]
    public void Export_WritesOneFilePerAnimationPlusAManifest()
    {
        var scene = HandsScene();
        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-fbx-{Guid.NewGuid():N}");

        try
        {
            var manifest = FbxExporter.Write(scene, directory);
            var rig = Assert.Single(manifest.Rigs);

            Assert.True(File.Exists(Path.Combine(directory, rig.Mesh)));
            Assert.Equal(scene.Animations.Count, rig.Animations.Count);

            foreach (var animation in rig.Animations)
            {
                Assert.True(File.Exists(Path.Combine(directory, animation.File)), animation.File);
                Assert.Equal(
                    scene.Animations.Single(a => a.Name == animation.Name).FrameCount, animation.FrameCount);
            }

            // Notifies have no home in FBX, so the manifest is the only place they survive.
            var reload = rig.Animations.Single(a => a.Name == "FastReloadPistol");
            Assert.Contains(reload.Notifies, n => n.Name == "ReloadPistolOne");
            Assert.All(reload.Notifies, n => Assert.InRange(n.Time, 0f, reload.Duration));

            using var document = JsonDocument.Parse(
                File.ReadAllText(Path.Combine(directory, FbxExporter.ManifestFileName)));
            Assert.Equal("centimetre", document.RootElement.GetProperty("unit").GetString());
            Assert.Equal("Z", document.RootElement.GetProperty("upAxis").GetString());
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    private static Matrix4x4 ToMatrix(double[] values) => new(
        (float)values[0], (float)values[1], (float)values[2], (float)values[3],
        (float)values[4], (float)values[5], (float)values[6], (float)values[7],
        (float)values[8], (float)values[9], (float)values[10], (float)values[11],
        (float)values[12], (float)values[13], (float)values[14], (float)values[15]);

    private static float Element(Matrix4x4 m, int row, int column) => (row, column) switch
    {
        (1, 1) => m.M11, (1, 2) => m.M12, (1, 3) => m.M13, (1, 4) => m.M14,
        (2, 1) => m.M21, (2, 2) => m.M22, (2, 3) => m.M23, (2, 4) => m.M24,
        (3, 1) => m.M31, (3, 2) => m.M32, (3, 3) => m.M33, (3, 4) => m.M34,
        (4, 1) => m.M41, (4, 2) => m.M42, (4, 3) => m.M43, _ => m.M44,
    };
}
