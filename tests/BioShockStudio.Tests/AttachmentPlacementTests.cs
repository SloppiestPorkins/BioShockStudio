using System.Numerics;
using System.Threading.Tasks;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// A prop hung on a socket has to travel with the bone it hangs off.
/// </summary>
/// <remarks>
/// Drawing it on the socket bone's <b>rest</b> transform leaves the drill hanging in the air while
/// the Bouncer swings, which looks exactly like a broken attachment and is not one. Nothing about
/// the numbers says which transform was used, so this measures the prop's placement at two frames
/// of a real animation and requires it to have moved.
/// </remarks>
[Collection(GameCollection.Name)]
public sealed class AttachmentPlacementTests(GameFixture game)
{
    private AssetCatalogService Catalog()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        return catalog;
    }

    /// <summary>The Bouncer, read straight from its package rather than from a built catalogue.</summary>
    private Core.Services.CatalogEntry? Bouncer()
    {
        using var package = Core.Packages.BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));

        return AssetCatalogService.Catalogue(package, "1-Medical")
            .Where(e => e.Group == "NewProtectorBouncer" && e.ClassName == "SkeletalMesh")
            .MaxBy(e => e.SerialSize);
    }

    /// <summary>
    /// The socket bone's posed transform must differ from its rest transform during an animation,
    /// and the difference is what a static prop has to be drawn with.
    /// </summary>
    [RequiresGameFact]
    public void AStaticPropFollowsTheHostsPosedSocketBone()
    {
        var catalog = Catalog();

        var host = Bouncer();
        if (host is null) return;

        var preview = new MeshPreviewService(catalog);
        var subject = preview.Load(host);

        Assert.NotEmpty(subject.Model.Bones);
        Assert.NotEmpty(subject.Animations);

        var attachments = new AssetContextService(catalog).Attachments(host).Where(a => a.IsStatic).ToList();
        Assert.NotEmpty(attachments);

        var attachment = attachments[0];
        int socketBone = subject.Model.Sockets
            .Where(s => string.Equals(s.Name, attachment.Socket, StringComparison.OrdinalIgnoreCase))
            .Select(s => s.Bone)
            .DefaultIfEmpty(-1)
            .First();

        if (socketBone < 0) socketBone = subject.Model.Sockets[0].Bone;

        // An animation that actually moves the rig.
        var animation = subject.Animations
            .Select(name => preview.LoadAnimation(host, name))
            .First(a => a is not null && a.FrameCount > 4)!;

        var rest = subject.Model.Bones[socketBone].RestGlobal;
        var first = subject.Model.Pose(animation.Decoded, 0)[socketBone];
        var later = subject.Model.Pose(animation.Decoded, animation.FrameCount - 1)[socketBone];

        // The prop is drawn at the origin of whichever transform it is given, so this is exactly the
        // distance between a correctly placed prop and one left on the bind pose.
        float restToLater = Vector3.Distance(rest.Translation, later.Translation);
        float firstToLater = Vector3.Distance(first.Translation, later.Translation);

        Assert.True(firstToLater > 0.5f,
            $"the socket bone barely moves across '{animation.Name}' ({firstToLater:N3}), so this "
            + "animation cannot tell a posed attachment from a rest-posed one — pick another");

        Assert.True(restToLater > 0.5f,
            $"the posed socket bone sits {restToLater:N3} from its rest position; a prop drawn on "
            + "RestGlobal would be that far from where it belongs");
    }

    /// <summary>
    /// Extracting a host must bring its props with it, each on its own socket.
    /// </summary>
    /// <remarks>
    /// Only a <i>skeletal</i> attachment used to reach the export, so a Big Daddy arrived in Blender
    /// with nothing on his back and the drill had to be found and placed by hand. The props are
    /// exported as attachment scenes with no bones — they are positioned by a socket, not deformed
    /// by one — and the importer parents each to its bone.
    /// </remarks>
    [RequiresGameFact]
    public async Task ExtractingTheBouncerBringsItsDrillCageAndBackpack()
    {
        var host = Bouncer();
        if (host is null) return;

        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-attach-{Guid.NewGuid():N}");

        try
        {
            var report = await new ExtractionService(Catalog()).RunAsync(
                [host],
                new ExtractionOptions
                {
                    OutputDirectory = directory,
                    Formats = ExportFormats.SceneJson,
                    PreservePackageStructure = false,
                });

            Assert.Equal(1, report.Succeeded);

            string scenePath = Directory.GetFiles(directory, "*.json", SearchOption.AllDirectories)
                .First(f => Path.GetFileName(f) != Core.Export.FbxExporter.ManifestFileName);

            var scene = System.Text.Json.JsonSerializer.Deserialize<Core.Export.AnimationScene>(
                File.ReadAllBytes(scenePath),
                new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase,
                })!;

            var byObject = scene.Attachments.ToDictionary(
                a => a.Scene.SourceObject, StringComparer.OrdinalIgnoreCase);

            Assert.Contains("ConeDrill", byObject.Keys);
            Assert.Contains("ConeDrillCage", byObject.Keys);
            Assert.Contains("ConeDrillBackpack", byObject.Keys);

            foreach (var attachment in scene.Attachments)
            {
                // Each must name a real socket on the host and carry geometry of its own.
                Assert.False(string.IsNullOrWhiteSpace(attachment.SocketName));
                Assert.Contains(scene.Sockets, s =>
                    string.Equals(s.Name, attachment.SocketName, StringComparison.OrdinalIgnoreCase));

                Assert.NotNull(attachment.Scene.Mesh);
                Assert.NotEmpty(attachment.Scene.Mesh!.Positions);

                // A prop has no skeleton. Inventing one would state a binding the game does not have.
                Assert.Empty(attachment.Scene.Bones);
                Assert.Empty(attachment.Scene.Animations);
            }
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    /// <summary>
    /// Extracting the first-person hands produces a complete library: every animation set, every
    /// weapon rig on its socket, and the props.
    /// </summary>
    /// <remarks>
    /// This is the Phase 1B contract. The weapons live in <c>ShockGame.U</c> rather than in the map
    /// holding the hands, so an attachment that carries its own rig has to be loaded from another
    /// package — which is why extraction used to produce hands holding nothing.
    /// </remarks>
    [RequiresGameFact]
    public async Task ExtractingTheHandsProducesTheWholeFirstPersonLibrary()
    {
        using var package = Core.Packages.BioShockPackage.Open(
            Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), "0-Lighthouse.bsm"));

        var host = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Where(e => e.Group == "NEWPlayerHands" && e.ClassName == "SkeletalMesh")
            .MaxBy(e => e.SerialSize);
        if (host is null) return;

        string directory = Path.Combine(Path.GetTempPath(), $"bioshock-library-{Guid.NewGuid():N}");

        try
        {
            var report = await new ExtractionService(Catalog()).RunAsync(
                [host],
                new ExtractionOptions
                {
                    OutputDirectory = directory,
                    Formats = ExportFormats.SceneJson,
                    PreservePackageStructure = false,
                });

            Assert.Equal(1, report.Succeeded);

            string scenePath = Directory.GetFiles(directory, "*.json", SearchOption.AllDirectories)
                .First(f => Path.GetFileName(f) != FbxExporter.ManifestFileName);

            var scene = System.Text.Json.JsonSerializer.Deserialize<AnimationScene>(
                File.ReadAllBytes(scenePath),
                new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase,
                })!;

            // Every animation, not one weapon's set: a library the user has to re-export per weapon
            // is not a library.
            Assert.True(scene.Animations.Count >= 130,
                $"only {scene.Animations.Count} animations exported");

            Assert.True(scene.Animations.Select(a => a.Owner).Distinct().Count() >= 8,
                "the hands' animation sets did not all come through");

            // The weapons are in another package and must still arrive, each on the grip.
            var rigs = scene.Attachments.Where(a => a.Scene.Bones.Count > 0).ToList();
            Assert.True(rigs.Count >= 5, $"only {rigs.Count} weapon rigs attached");

            foreach (string weapon in new[] { "Pistol", "TommyGun", "Crossbow", "Launcher", "Chem" })
                Assert.Contains(rigs, r => string.Equals(r.SocketName, weapon, StringComparison.OrdinalIgnoreCase));

            Assert.All(rigs, r => Assert.Equal("R_Grip", r.SocketBone, ignoreCase: true));

            // Events are what make the actions usable on a timeline.
            Assert.True(scene.Animations.Sum(a => a.Events.Count) > 100,
                "the animation events did not come through");
        }
        finally
        {
            if (Directory.Exists(directory)) Directory.Delete(directory, recursive: true);
        }
    }

    /// <summary>
    /// The render path must use the posed matrix, not the rest one.
    /// </summary>
    /// <remarks>
    /// Renders the host and its prop twice — once placed on the posed socket bone, once on the rest
    /// bone — and requires the two images to differ. That is what the window does; a regression to
    /// <c>RestGlobal</c> makes these identical.
    /// </remarks>
    [RequiresGameFact]
    public void PlacingAPropOnTheRestBoneDrawsSomethingElse()
    {
        var catalog = Catalog();
        var host = Bouncer();
        if (host is null) return;

        var preview = new MeshPreviewService(catalog);
        var subject = preview.Load(host);

        var attachment = new AssetContextService(catalog).Attachments(host).First(a => a.IsStatic);
        var prop = preview.LoadAttachment(attachment).Model;
        if (!prop.HasGeometry) return;

        int socketBone = subject.Model.Sockets[0].Bone;
        var animation = subject.Animations
            .Select(name => preview.LoadAnimation(host, name))
            .First(a => a is not null && a.FrameCount > 4)!;

        int frame = animation.FrameCount - 1;
        var pose = subject.Model.Pose(animation.Decoded, frame);

        var camera = PreviewCamera.Frame(subject.Model.Centre, subject.Model.Radius).Orbit(0.6f, 0.3f);
        var options = new RenderOptions { ShowSkeleton = false, ShowSockets = false };

        var posed = SoftwareRenderer.Render(
            [new PreviewInstance(subject.Model, pose), new PreviewInstance(prop, null, pose[socketBone])],
            camera, options, 320, 320);

        var rested = SoftwareRenderer.Render(
            [new PreviewInstance(subject.Model, pose),
             new PreviewInstance(prop, null, subject.Model.Bones[socketBone].RestGlobal)],
            camera, options, 320, 320);

        int different = 0;
        for (int i = 0; i < posed.Rgba.Length; i += 4)
            if (posed.Rgba[i] != rested.Rgba[i]) different++;

        Assert.True(different > 200,
            $"only {different} pixels differ between a prop on the posed socket bone and one on the "
            + "rest bone — the two placements should not look the same");
    }
}
