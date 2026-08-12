using System.Text.Json;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
public sealed class ExportTests(GameFixture game)
{
    private AnimationPackage Hands()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && package.GetClassName(e) == "AnimationPackageWrapper");
        return AnimationPackage.Load(package, export);
    }

    [RequiresGameFact]
    public void PistolScene_ContainsTheFullWeaponSet()
    {
        var scene = AnimationSceneExporter.Build(Hands(), "Pistol");

        Assert.Equal(47, scene.Bones.Count);
        Assert.Equal(10, scene.Animations.Count);
        Assert.Empty(scene.Failures);

        var names = scene.Animations.Select(a => a.Name).ToHashSet(StringComparer.Ordinal);
        Assert.Contains("EquipPistol", names);
        Assert.Contains("FireSinglePistol", names);
        Assert.Contains("FastReloadPistol", names);
        Assert.Contains("UnequipPistol", names);
    }

    [RequiresGameFact]
    public void Scene_MarksWeaponSockets()
    {
        var scene = AnimationSceneExporter.Build(Hands(), "Pistol");

        var sockets = scene.Bones.Where(b => b.IsSocket).Select(b => b.Name).ToList();
        Assert.Equal(2, sockets.Count);
        Assert.Contains("R_grip", sockets);
        Assert.Contains("IKbindLhandDummy", sockets);
    }

    [RequiresGameFact]
    public void Scene_KeepsBoneIndicesAndParentOrdering()
    {
        var scene = AnimationSceneExporter.Build(Hands(), "Pistol");

        for (int i = 0; i < scene.Bones.Count; i++)
        {
            Assert.Equal(i, scene.Bones[i].Index);
            Assert.InRange(scene.Bones[i].Parent, -1, i - 1);
        }
    }

    [RequiresGameFact]
    public void Scene_TrackArraysAreFrameAligned()
    {
        var scene = AnimationSceneExporter.Build(Hands(), "Pistol");

        foreach (var animation in scene.Animations)
        {
            foreach (var track in animation.Tracks)
            {
                Assert.Equal(animation.FrameCount * 3, track.Translations.Length);
                Assert.Equal(animation.FrameCount * 4, track.Rotations.Length);
                Assert.Equal(animation.FrameCount * 3, track.Scales.Length);
                Assert.InRange(track.BoneIndex, 0, scene.Bones.Count - 1);
            }
        }
    }

    [RequiresGameFact]
    public void Scene_RoundTripsThroughJsonWithCamelCaseNames()
    {
        var scene = AnimationSceneExporter.Build(Hands(), "Pistol");

        string path = Path.Combine(Path.GetTempPath(), $"bioshock-scene-{Guid.NewGuid():N}.json");
        try
        {
            AnimationSceneExporter.WriteJson(scene, path);

            using var document = JsonDocument.Parse(File.ReadAllText(path));
            var root = document.RootElement;

            // The Blender importer reads these exact property names.
            Assert.True(root.TryGetProperty("bones", out _));
            Assert.True(root.TryGetProperty("animations", out _));
            Assert.True(root.TryGetProperty("skeletonName", out _));

            var firstBone = root.GetProperty("bones")[0];
            Assert.True(firstBone.TryGetProperty("isSocket", out _));
            Assert.True(firstBone.TryGetProperty("parent", out _));

            var firstTrack = root.GetProperty("animations")[0].GetProperty("tracks")[0];
            Assert.True(firstTrack.TryGetProperty("boneIndex", out _));
        }
        finally
        {
            if (File.Exists(path)) File.Delete(path);
        }
    }

    [RequiresGameFact]
    public void Scene_PreservesAuthoredTimingRatherThanANominalRate()
    {
        var scene = AnimationSceneExporter.Build(Hands(), "Pistol");

        foreach (var animation in scene.Animations)
        {
            Assert.True(animation.FrameDuration > 0f);
            Assert.Equal((animation.FrameCount - 1) * animation.FrameDuration, animation.Duration, 3);
        }

        // The set genuinely contains more than one authored rate, so a single scene-wide fps would
        // be lossy.
        var rates = scene.Animations.Select(a => MathF.Round(1f / a.FrameDuration, 2)).Distinct().ToList();
        Assert.True(rates.Count > 1);
    }
}
