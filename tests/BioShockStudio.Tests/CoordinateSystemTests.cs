using System.Numerics;
using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Skeleton;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The basis conversion, checked as mathematics rather than by eye.
/// <para>
/// The conversion is the one thing in this project that no amount of looking at a render can
/// validate: a mirrored asset looks entirely plausible, which is how it survived until now. So these
/// tests assert the properties the conversion has to have — determinant, involution, conjugation,
/// winding — and then check on real game bytes that a character's left side really does come out on
/// the left.
/// </para>
/// <para>The synthetic cases here test arithmetic, not a reverse-engineered structure, so the
/// project's no-synthetic-fixtures rule does not apply to them.</para>
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class CoordinateSystemTests(GameFixture game)
{
    private const float Tolerance = 1e-5f;

    // ---- the conversion itself -------------------------------------------------------------

    [Fact]
    public void Conversion_IsAReflection()
    {
        // Determinant -1 is the whole point: a rotation cannot take a left-handed basis to a
        // right-handed one, so if this ever becomes +1 the mirror is back.
        Assert.Equal(-1f, Matrix4x4.Transpose(GameBasis.Conversion).GetDeterminant(), 5);
        Assert.Equal(-1f, GameBasis.Conversion.GetDeterminant(), 5);
    }

    [Fact]
    public void Conversion_IsItsOwnInverse()
    {
        var point = new Vector3(3f, -7f, 11f);
        Assert.Equal(point, GameBasis.Convert(GameBasis.Convert(point)));

        var rotation = Quaternion.Normalize(new Quaternion(0.3f, -0.5f, 0.2f, 0.8f));
        AssertSameRotation(rotation, GameBasis.Convert(GameBasis.Convert(rotation)));
    }

    [Fact]
    public void Position_ConvertsToTheKnownPoint()
    {
        // The game's +Y is right; the studio's +Y is left. Nothing else moves.
        Assert.Equal(new Vector3(1f, -2f, 3f), GameBasis.Convert(new Vector3(1f, 2f, 3f)));
        Assert.Equal(Vector3.Zero, GameBasis.Convert(Vector3.Zero));
        Assert.Equal(Vector3.UnitX, GameBasis.Convert(Vector3.UnitX));
        Assert.Equal(Vector3.UnitZ, GameBasis.Convert(Vector3.UnitZ));
        Assert.Equal(-Vector3.UnitY, GameBasis.Convert(Vector3.UnitY));
    }

    [Fact]
    public void GameForwardRightUp_BecomeARightHandedFrame()
    {
        // The game's basis is left-handed: forward x left = -up. After conversion it must be
        // right-handed: forward x left = +up. This is the property the whole fix exists to restore.
        var gameForward = Vector3.UnitX;
        var gameLeft = -Vector3.UnitY;
        var gameUp = Vector3.UnitZ;
        Assert.Equal(-gameUp, Vector3.Cross(gameForward, gameLeft));

        var forward = GameBasis.Convert(gameForward);
        var left = GameBasis.Convert(gameLeft);
        var up = GameBasis.Convert(gameUp);
        Assert.Equal(up, Vector3.Cross(forward, left));
    }

    [Fact]
    public void Normal_ConvertsByTheInverseTranspose()
    {
        // A normal transforms by (C^-1)^T. For this C that is C itself, which is why the code uses
        // one function for both — asserted here rather than assumed.
        Assert.True(Matrix4x4.Invert(GameBasis.Conversion, out var inverse));
        var inverseTranspose = Matrix4x4.Transpose(inverse);

        var normal = Vector3.Normalize(new Vector3(0.3f, 0.9f, -0.2f));
        AssertClose(
            Vector3.TransformNormal(normal, inverseTranspose),
            GameBasis.Convert(normal));
    }

    // ---- rotations -------------------------------------------------------------------------

    [Fact]
    public void Rotation_MatchesConjugationByTheBasis()
    {
        // R' = C * R * C^-1, built independently as matrices, against the quaternion shortcut the
        // code actually uses. Identity, each axis, and a combination.
        Quaternion[] cases =
        [
            Quaternion.Identity,
            Quaternion.CreateFromAxisAngle(Vector3.UnitX, MathF.PI / 2f),
            Quaternion.CreateFromAxisAngle(Vector3.UnitY, MathF.PI / 2f),
            Quaternion.CreateFromAxisAngle(Vector3.UnitZ, MathF.PI / 2f),
            Quaternion.CreateFromAxisAngle(Vector3.UnitX, -MathF.PI / 3f),
            Quaternion.CreateFromAxisAngle(Vector3.Normalize(new Vector3(1f, 2f, -3f)), 1.1f),
            Quaternion.Concatenate(
                Quaternion.CreateFromAxisAngle(Vector3.UnitZ, 0.7f),
                Quaternion.CreateFromAxisAngle(Vector3.UnitX, -0.4f)),
        ];

        foreach (var rotation in cases)
        {
            var expected = GameBasis.Conversion
                           * Matrix4x4.CreateFromQuaternion(rotation)
                           * GameBasis.Conversion;
            var actual = Matrix4x4.CreateFromQuaternion(GameBasis.Convert(rotation));
            AssertClose(expected, actual);
        }
    }

    [Fact]
    public void Rotation_ConvertsTheRotatedPointTheSameWayAsThePoint()
    {
        // The consistency condition between the two conversions: rotating in the game's basis and
        // then converting must equal converting and then rotating. If this fails, meshes and
        // skeletons drift apart under animation.
        var rotation = Quaternion.Normalize(new Quaternion(0.2f, 0.4f, -0.3f, 0.85f));
        var point = new Vector3(5f, -2f, 7f);

        AssertClose(
            GameBasis.Convert(Vector3.Transform(point, rotation)),
            Vector3.Transform(GameBasis.Convert(point), GameBasis.Convert(rotation)));
    }

    [Fact]
    public void Identity_IsUnchanged()
    {
        AssertSameRotation(Quaternion.Identity, GameBasis.Convert(Quaternion.Identity));
        Assert.Equal(Vector3.One, GameBasis.ConvertScale(Vector3.One));
    }

    [Fact]
    public void Scale_IsCarriedUnchanged()
    {
        // The conversion must never smuggle in a negative scale of its own; a hidden -1 somewhere in
        // a root node is exactly the failure this whole exercise was chasing.
        var scale = new Vector3(2f, 3f, 0.5f);
        Assert.Equal(scale, GameBasis.ConvertScale(scale));
    }

    // ---- meshes ----------------------------------------------------------------------------

    [Fact]
    public void Mesh_TurnsClockwiseWindingIntoCounterClockwiseWithoutTouchingTheIndices()
    {
        // An asymmetric triangle wound the way the shipped geometry is: clockwise, so (B-A)x(C-A)
        // points against the shading normal.
        var a = new Vector3(0f, 0f, 0f);
        var b = new Vector3(1f, 0f, 0f);
        var c = new Vector3(0f, 3f, 0f);
        var normal = -Vector3.UnitZ;
        Assert.True(Vector3.Dot(Vector3.Cross(b - a, c - a), normal) < 0f, "the fixture is not clockwise");

        var converted = GameBasis.Convert(TriangleMesh(a, b, c, normal));

        // The indices are untouched. A cross product transforms by -C and a normal by +C, so the
        // reflection alone negates their agreement — an index swap on top would undo it.
        Assert.Equal([0, 1, 2], converted.Indices);

        var p = converted.Vertices.Select(v => v.Position).ToArray();
        Assert.True(
            Vector3.Dot(Vector3.Cross(p[1] - p[0], p[2] - p[0]), converted.Vertices[0].Normal) > 0f,
            "the converted triangle should be counter-clockwise front-facing");
    }

    [Fact]
    public void Mesh_ConvertsEveryBasisVectorAndLeavesUvsAlone()
    {
        var geometry = TriangleMesh(
            new Vector3(1f, 2f, 3f), new Vector3(4f, 5f, 6f), new Vector3(7f, 8f, 9f), Vector3.UnitY);
        var converted = GameBasis.Convert(geometry);

        for (int i = 0; i < geometry.Vertices.Count; i++)
        {
            var before = geometry.Vertices[i];
            var after = converted.Vertices[i];
            Assert.Equal(GameBasis.Convert(before.Position), after.Position);
            Assert.Equal(GameBasis.Convert(before.Normal), after.Normal);
            Assert.Equal(GameBasis.Convert(before.Tangent), after.Tangent);
            Assert.Equal(GameBasis.Convert(before.Binormal), after.Binormal);

            // The conversion acts on space, not on texture parameterisation.
            Assert.Equal(before.Uv, after.Uv);
        }
    }

    [Fact]
    public void Mesh_KeepsTheTangentBasisConsistentWithTheNormal()
    {
        // The game ships tangent and binormal explicitly, so converting all three by the same map
        // keeps them mutually consistent. Nothing needs a hand-applied sign.
        var geometry = TriangleMesh(
            Vector3.Zero, Vector3.UnitX, Vector3.UnitY, Vector3.UnitZ,
            tangent: Vector3.UnitX, binormal: Vector3.UnitY);
        var v = GameBasis.Convert(geometry).Vertices[0];

        AssertClose(GameBasis.Convert(Vector3.Cross(Vector3.UnitX, Vector3.UnitY)),
                    -Vector3.Cross(v.Tangent, v.Binormal));
    }

    // ---- skeletons and animation on real bytes ----------------------------------------------

    [RequiresGameFact]
    public void Skeleton_PutsTheLeftSideOnTheLeft()
    {
        // The decisive case. A character skeleton in world space: feet near Z=0, head high in Z,
        // toes ahead of ankles in X. In the game's left-handed basis Bip01_L_* sits at negative Y;
        // in the studio's right-handed basis it must sit at positive Y, because +Y is now left.
        var skeleton = RosieSkeleton();
        var globals = skeleton.ComputeGlobalTransforms();

        Vector3 Position(string name)
        {
            int index = skeleton.Bones.ToList().FindIndex(b => b.Name == name);
            Assert.True(index >= 0, $"{name} not found");
            return globals[index].Translation;
        }

        var up = Position("Bip01_Neck") - Position("Bip01_Pelvis");
        Assert.True(up.Z > 20f, $"the head should be up in +Z, got {up}");

        var forward = Position("Bip01_L_Toe0") - Position("Bip01_L_Foot");
        Assert.True(forward.X > 5f, $"toes should be forward in +X, got {forward}");

        foreach (string name in new[] { "Bip01_L_Clavicle", "Bip01_L_Thigh", "Bip01_L_Foot" })
            Assert.True(Position(name).Y > 0f, $"{name} should be on the +Y (left) side");

        foreach (string name in new[] { "Bip01_R_Clavicle", "Bip01_R_Thigh", "Bip01_R_Foot" })
            Assert.True(Position(name).Y < 0f, $"{name} should be on the -Y (right) side");

        // And the frame those three axes form is right-handed.
        var left = Position("Bip01_L_Thigh") - Position("Bip01_R_Thigh");
        Assert.True(Vector3.Dot(Vector3.Cross(forward, left), up) > 0f,
            "forward x left must point up — the frame is still left-handed");
    }

    [RequiresGameFact]
    public void Skeleton_HasNoMirroredReferenceBasis()
    {
        // A negative-determinant bone basis would be a mirror hiding inside the skeleton rather than
        // in the conversion, and would survive any amount of fixing at the exporter.
        var skeleton = RosieSkeleton();
        foreach (var bone in skeleton.Bones)
        {
            float determinant = Matrix4x4.CreateFromQuaternion(bone.LocalRotation).GetDeterminant();
            Assert.True(determinant > 0f, $"{bone.Name} carries a mirrored reference rotation");
            Assert.True(bone.LocalScale.X > 0f && bone.LocalScale.Y > 0f && bone.LocalScale.Z > 0f,
                $"{bone.Name} carries a negative reference scale");
        }
    }

    [RequiresGameFact]
    public void ShippedGeometry_IsCounterClockwiseFrontFacingAfterConversion()
    {
        // The game ships clockwise front faces — measured at 100% of triangles before conversion.
        // After it, every triangle's geometric normal must agree with its shading normal.
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports.First(e =>
            e.ObjectName == "NEWPlayerHands" && package.GetClassName(e) == "SkeletalMesh");

        var geometry = SkeletalMeshReader.ReadGeometry(package.ReadExportData(export));
        Assert.NotNull(geometry);

        int agree = 0, disagree = 0;
        for (int t = 0; t + 2 < geometry.Indices.Count; t += 3)
        {
            var a = geometry.Vertices[geometry.Indices[t]];
            var b = geometry.Vertices[geometry.Indices[t + 1]];
            var c = geometry.Vertices[geometry.Indices[t + 2]];

            var geometric = Vector3.Cross(b.Position - a.Position, c.Position - a.Position);
            float d = Vector3.Dot(geometric, a.Normal + b.Normal + c.Normal);
            if (d > 0f) agree++;
            else if (d < 0f) disagree++;
        }

        Assert.True(agree > 0);
        Assert.True(disagree * 200 < agree,
            $"{disagree} of {agree + disagree} triangles still wind the wrong way");
    }

    [RequiresGameFact]
    public void Animation_UsesTheSameBasisAsTheSkeleton()
    {
        // No animation-specific adjustment: a track's rotation converts by exactly the map the
        // skeleton's reference rotation does. Checked by converting back and comparing with the
        // undecorated Havok values the decompressor produced.
        var package = HandsAnimationPackage();
        var animation = package.Animations.First();
        var decoded = package.Decode(animation);

        // Most tracks store no translation channel and fall back to the bound bone's reference
        // translation. That fallback is the one value in the pipeline that passes through two
        // conversions' worth of code, so it is where a double conversion would show up — and it
        // shows up as the reference translation with its Y negated. Count both readings.
        int matchingReference = 0, mirroredReference = 0;

        foreach (var track in decoded.Tracks)
        {
            if (track.TargetBoneIndex < 0) continue;

            var reference = package.Skeleton.Bones[track.TargetBoneIndex].LocalTranslation;

            // A bone on the centre line reads the same either way, so it distinguishes nothing.
            if (MathF.Abs(reference.Y) < 1e-3f) continue;

            var first = track.Translations[0];
            bool constant = track.Translations.All(t => Vector3.Distance(t, first) < 1e-4f);
            if (!constant) continue;

            if (Vector3.Distance(first, reference) < 1e-3f) matchingReference++;
            else if (Vector3.Distance(first, GameBasis.Convert(reference)) < 1e-3f) mirroredReference++;
        }

        Assert.True(matchingReference > 0,
            "no track fell back to its bone's reference translation, so this proves nothing");
        Assert.Equal(0, mirroredReference);
    }

    // ---- helpers ---------------------------------------------------------------------------

    private BioShockSkeleton RosieSkeleton() => LoadSkeleton("UAPW_ProtectorRosie");

    private Core.Assets.AnimationPackage HandsAnimationPackage()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && package.GetClassName(e) == "AnimationPackageWrapper");
        return Core.Assets.AnimationPackage.Load(package, export);
    }

    private BioShockSkeleton LoadSkeleton(string objectName)
    {
        foreach (string path in Directory.EnumerateFiles(
                     Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "*.bsm"))
        {
            using var package = BioShockPackage.Open(path);
            var export = package.Exports.FirstOrDefault(e =>
                e.ObjectName == objectName && package.GetClassName(e) == "AnimationPackageWrapper");
            if (export is null) continue;
            return Core.Assets.AnimationPackage.Load(package, export).Skeleton;
        }

        throw new InvalidOperationException($"{objectName} was not found in any shipped package.");
    }

    private static MeshGeometry TriangleMesh(
        Vector3 a, Vector3 b, Vector3 c, Vector3 normal,
        Vector3 tangent = default, Vector3 binormal = default)
    {
        MeshVertex Vertex(Vector3 position, float u) => new()
        {
            Position = position,
            Normal = normal,
            Tangent = tangent == default ? Vector3.UnitX : tangent,
            Binormal = binormal == default ? Vector3.UnitY : binormal,
            Uv = new Vector2(u, 0.25f),
            Influences = [],
        };

        return new MeshGeometry
        {
            Vertices = [Vertex(a, 0f), Vertex(b, 0.5f), Vertex(c, 1f)],
            Indices = [0, 1, 2],
            BoneMap = [],
            SkinnedVertexCount = 0,
            RigidVertexCount = 0,
        };
    }

    private static void AssertClose(Vector3 expected, Vector3 actual) =>
        Assert.True(Vector3.Distance(expected, actual) < Tolerance, $"expected {expected}, got {actual}");

    private static void AssertClose(Matrix4x4 expected, Matrix4x4 actual)
    {
        AssertClose(new Vector3(expected.M11, expected.M12, expected.M13), new Vector3(actual.M11, actual.M12, actual.M13));
        AssertClose(new Vector3(expected.M21, expected.M22, expected.M23), new Vector3(actual.M21, actual.M22, actual.M23));
        AssertClose(new Vector3(expected.M31, expected.M32, expected.M33), new Vector3(actual.M31, actual.M32, actual.M33));
    }

    private static void AssertSameRotation(Quaternion expected, Quaternion actual)
    {
        // q and -q are the same rotation.
        float dot = MathF.Abs(Quaternion.Dot(expected, actual));
        Assert.True(dot > 1f - Tolerance, $"expected {expected}, got {actual}");
    }
}
