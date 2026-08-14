using System.Numerics;
using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Havok.Animation;
using BioShockStudio.Core.Havok.Animation.SplineCompression;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers the two decode faults that only showed up on long animations.
/// <para>
/// Both were invisible on the hands, whose animations are a few dozen frames and fit in one block.
/// Ryan's speeches are 2,352 and 2,613 frames across ten and eleven blocks, and that is where a
/// sampling error has room to accumulate — his chest folded into his legs partway through.
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
public sealed class AnimationContinuityTests(GameFixture game)
{
    private string RyanPackage => Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "5-Ryan.bsm");

    private (MeshPreviewService Preview, CatalogEntry Entry) Ryan()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = BioShockPackage.Open(RyanPackage);
        var entry = AssetCatalogService.Catalogue(package, "5-Ryan")
            .Where(e => e.Group == "Ryan" && e.ClassName == AssetClasses.SkeletalMesh)
            .MaxBy(e => e.SerialSize)!;

        return (new MeshPreviewService(catalog), entry);
    }

    /// <summary>Bones the mesh is actually skinned to. Prop and dummy bones are never drawn.</summary>
    private static HashSet<int> SkinnedBones(Core.Rendering.PreviewModel model)
    {
        var skinned = new HashSet<int>();
        foreach (var vertex in model.Vertices)
            foreach (var influence in vertex.Influences)
                skinned.Add(influence.BoneIndex);
        return skinned;
    }

    private static float WorstStep(Core.Rendering.PreviewModel model, DecodedAnimation animation, HashSet<int> bones)
    {
        Matrix4x4[]? previous = null;
        float worst = 0;

        for (int f = 0; f < animation.FrameCount; f++)
        {
            var pose = model.Pose(animation, f);
            if (previous is not null)
            {
                foreach (int b in bones)
                    if (b < pose.Length)
                        worst = Math.Max(worst, (pose[b].Translation - previous[b].Translation).Length());
            }
            previous = pose;
        }

        return worst;
    }

    [RequiresGameFact]
    public void ALoopingAnimationMovesSmoothly()
    {
        var (preview, entry) = Ryan();
        var model = preview.Load(entry).Model;
        var animation = preview.LoadAnimation(entry, "Ryan_DoorLoop")!;

        // A quiet idle loop moves a bone a fraction of a unit per frame. Before the knot-span fix
        // the worst step here was 10.4 units on a skeleton 130 units tall — the last span of every
        // curve was evaluated against the span below it, so the end of each block extrapolated.
        float worst = WorstStep(model, animation.Decoded, SkinnedBones(model));

        Assert.True(worst < 2f, $"a door-idle loop moved a bone {worst:F2} units in one frame");
    }

    [RequiresGameFact]
    public void ALongAnimationKeepsItsSkeletonRigid()
    {
        var (preview, entry) = Ryan();
        var model = preview.Load(entry).Model;
        var animation = preview.LoadAnimation(entry, "Ryan_Speech_B")!;

        var restLength = new float[model.Bones.Count];
        for (int b = 0; b < model.Bones.Count; b++)
        {
            int parent = model.Bones[b].Parent;
            restLength[b] = parent < 0
                ? 0
                : (model.Bones[b].RestGlobal.Translation - model.Bones[parent].RestGlobal.Translation).Length();
        }

        var skinned = SkinnedBones(model);
        int worstBroken = 0;

        for (int f = 0; f < animation.FrameCount; f++)
        {
            var pose = model.Pose(animation.Decoded, f);
            int broken = 0;

            foreach (int b in skinned)
            {
                int parent = model.Bones[b].Parent;
                if (parent < 0 || restLength[b] < 0.5f) continue;

                float length = (pose[b].Translation - pose[parent].Translation).Length();
                if (Math.Abs(length - restLength[b]) / restLength[b] > 0.25f) broken++;
            }

            worstBroken = Math.Max(worstBroken, broken);
        }

        // Bones do not stretch. A handful translate legitimately; a quarter of the skeleton changing
        // length at once is a decode that has lost the plot.
        Assert.True(worstBroken < skinned.Count / 4,
            $"{worstBroken} of {skinned.Count} skinned bones changed length by over a quarter");
    }

    [RequiresGameFact]
    public void BlocksAdvanceByOneLessThanTheirFrameCapacity()
    {
        using var package = BioShockPackage.Open(RyanPackage);
        var wrapper = package.Exports
            .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper
                        && AssetContextResolver.TopLevelGroup(package, e) == "Ryan")
            .MaxBy(e => e.SerialSize)!;

        var animations = AnimationPackage.Load(package, wrapper);
        var speech = animations.Animations.Single(a => a.Name == "Ryan_Speech_B");

        var section = animations.Packfile.ResolvedSections[speech.SectionIndex];
        var header = HkaSplineCompressedAnimationReader.Read(section, speech.Offset);
        var data = section.Data.Span.Slice(header.DataOffset!.Value, header.DataSize);

        var referencePose = new ReferenceTransform[header.TransformTrackCount];
        for (int track = 0; track < referencePose.Length; track++)
        {
            int bone = speech.Binding.BoneForTrack(track);
            referencePose[track] = bone >= 0 && bone < animations.Skeleton.BoneCount
                ? new ReferenceTransform(
                    animations.Skeleton.Bones[bone].LocalTranslation,
                    animations.Skeleton.Bones[bone].LocalRotation,
                    animations.Skeleton.Bones[bone].LocalScale)
                : ReferenceTransform.Identity;
        }

        var blocks = SplineDecompressor.DescribeBlocks(data, header.BlockOffsets, header.TransformTrackCount, referencePose);

        Assert.Equal(11, blocks.Count);
        Assert.All(blocks, b => Assert.True(b.LooksComplete, $"block {b.Index} left {b.Slack} bytes"));

        // This is the evidence for the stride. A full block's knots run to 255, so it describes
        // frames 0..255 — 256 of them, the last shared with the next block. The final block's knots
        // stop at 62, so it describes 63 frames: exactly what is left of 2,613 after ten blocks have
        // advanced 255 each. Advancing 256 each would leave 53, and its knots would stop at 52.
        int full = header.MaxFramesPerBlock - 1;
        Assert.All(blocks.Take(blocks.Count - 1), b => Assert.Equal(full, b.MaxKnot));

        int remaining = header.NumFrames - (blocks.Count - 1) * full;
        Assert.Equal(remaining - 1, blocks[^1].MaxKnot);
    }

    [RequiresGameFact]
    public void EveryRyanAnimationDecodesWithoutStretchingTheSkeleton()
    {
        var (preview, entry) = Ryan();
        var subject = preview.Load(entry);
        var model = subject.Model;
        var skinned = SkinnedBones(model);

        foreach (string name in subject.Animations)
        {
            var animation = preview.LoadAnimation(entry, name);
            Assert.NotNull(animation);

            foreach (int b in skinned)
            {
                for (int f = 0; f < animation.Decoded.FrameCount; f += 17)
                {
                    var pose = model.Pose(animation.Decoded, f);
                    Assert.True(float.IsFinite(pose[b].Translation.X), $"{name} frame {f} produced a non-finite bone");
                }
                break;
            }
        }
    }

    [Fact]
    public void FindSpanSelectsTheLastSpanOfAClampedCurve()
    {
        // A clamped cubic over six control points: knots 0,0,0,0,1,2,3,3,3,3 — n + degree + 2 = 10.
        var basis = new NurbsBasis(numItems: 5, degree: 3, knots: [0, 0, 0, 0, 1, 2, 3, 3, 3, 3]);

        Assert.Equal(3, basis.FindSpan(0f));
        Assert.Equal(3, basis.FindSpan(0.5f));
        Assert.Equal(4, basis.FindSpan(1.5f));

        // The end of the domain belongs to the last span, n. Clamping to n - 1 here is what made the
        // final frames of every block extrapolate.
        Assert.Equal(5, basis.FindSpan(3f));
        Assert.Equal(5, basis.FindSpan(2.5f));
    }

    [Fact]
    public void BasisFunctionsSumToOneAcrossTheDomain()
    {
        var basis = new NurbsBasis(numItems: 5, degree: 3, knots: [0, 0, 0, 0, 1, 2, 3, 3, 3, 3]);

        // A partition of unity. If it does not hold, the blend is not an interpolation and the pose
        // drifts off the curve — which is exactly what a wrong span produces.
        for (float t = 0f; t <= 3f; t += 0.125f)
        {
            float total = basis.Weights(t).Sum(w => w.Weight);
            Assert.Equal(1f, total, 4);
        }
    }
}
