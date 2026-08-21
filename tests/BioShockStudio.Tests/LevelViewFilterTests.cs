using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Filtering contracts for the level viewer's intentionally non-rendered geometry.</summary>
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class LevelViewFilterTests
{
    private static readonly PreviewModel Model = PreviewModel.Build(new MeshGeometry
    {
        Vertices =
        [
            new MeshVertex { Position = new Vector3(-1, -1, 0), Normal = Vector3.UnitZ, Uv = Vector2.Zero, Influences = [] },
            new MeshVertex { Position = new Vector3(1, -1, 0), Normal = Vector3.UnitZ, Uv = Vector2.Zero, Influences = [] },
            new MeshVertex { Position = new Vector3(0, 1, 0), Normal = Vector3.UnitZ, Uv = Vector2.Zero, Influences = [] },
        ],
        Indices = [0, 1, 2],
        BoneMap = [],
        SkinnedVertexCount = 0,
        RigidVertexCount = 3,
        Sections = [new MeshSection(0, 0, 2, 1)],
    }, null, null,
    [new PreviewSurface(0, 3, "LightBeamShader") { NoBaseColourByDesign = true }]);

    [Fact]
    public void EffectsAndUnresolvedSurfacesHaveIndependentControls()
    {
        var camera = PreviewCamera.Frame(Model);
        var hidden = SoftwareRenderer.Render(Model, camera,
            new RenderOptions { ShowUnpainted = true, ShowEffects = false }, 128, 128);
        var visible = SoftwareRenderer.Render(Model, camera,
            new RenderOptions { ShowUnpainted = false, ShowEffects = true }, 128, 128);

        Assert.Equal(0, Coverage(hidden));
        Assert.True(Coverage(visible) > 100, "an enabled effect surface was not drawn");
    }

    [Theory]
    [InlineData("BlockingVolume")]
    [InlineData("ProximityTrigger")]
    [InlineData("WaterZone")]
    [InlineData("ZoneInfo")]
    public void GameplayRegionsDoNotLeakThroughTheSourceBrushFilter(string actorClass)
    {
        var region = new ViewportItem(Model, Matrix4x4.Identity, Vector3.Zero, 1)
        {
            Kind = LevelGeometryKind.Brush,
            ActorClass = actorClass,
        };

        Assert.True(region.IsVolume);
        Assert.False(new LevelViewFilter { ShowSourceBrushes = true }.Accepts(region));
        Assert.True(new LevelViewFilter { ShowVolumes = true }.Accepts(region));
    }

    [Theory]
    [InlineData(LevelGeometryKind.BuiltWorld)]
    [InlineData(LevelGeometryKind.StaticMesh)]
    [InlineData(LevelGeometryKind.SkeletalMesh)]
    public void DrawableUe2GeometryCategoriesCanBeHiddenIndependently(LevelGeometryKind kind)
    {
        var item = new ViewportItem(Model, Matrix4x4.Identity, Vector3.Zero, 1) { Kind = kind };
        Assert.True(new LevelViewFilter().Accepts(item));

        var filter = kind switch
        {
            LevelGeometryKind.BuiltWorld => new LevelViewFilter { ShowWorld = false },
            LevelGeometryKind.StaticMesh => new LevelViewFilter { ShowStaticMeshes = false },
            LevelGeometryKind.SkeletalMesh => new LevelViewFilter { ShowSkeletalMeshes = false },
            _ => throw new ArgumentOutOfRangeException(nameof(kind)),
        };
        Assert.False(filter.Accepts(item));
    }

    private static int Coverage(PreviewImage image)
    {
        int covered = 0;
        for (int i = 0; i < image.Rgba.Length; i += 4)
            if (image.Rgba[i] != 32 || image.Rgba[i + 1] != 32 || image.Rgba[i + 2] != 32)
                covered++;
        return covered;
    }
}
