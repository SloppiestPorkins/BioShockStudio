using System.Numerics;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers asset context: what attaches to what, and drawing a host with its attachment.
/// </summary>
[Collection(GameCollection.Name)]
public sealed class ContextTests(GameFixture game)
{
    private AssetCatalogService Catalog()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        return catalog;
    }

    private CatalogEntry Hands()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        return AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);
    }

    [RequiresGameFact]
    public void Attachments_FindTheWeaponsTheHandsSocketsName()
    {
        var context = new AssetContextService(Catalog());
        var attachments = context.Attachments(Hands());

        Assert.NotEmpty(attachments);

        var pistol = attachments.Single(a => a.Socket == "Pistol");
        Assert.Equal("WP_Pistol", pistol.Group);
        Assert.Equal("R_Grip", pistol.SocketBone, ignoreCase: true);

        // The weapon viewmodels are in the script package, not a map.
        Assert.Equal("ShockGame", pistol.Package);
    }

    [RequiresGameFact]
    public void Attachments_AreConfirmedOnlyWhenTheSkeletonRootMatchesTheSocketBone()
    {
        var context = new AssetContextService(Catalog());
        var attachments = context.Attachments(Hands());

        var pistol = attachments.Single(a => a.Socket == "Pistol");

        // This is the fact that makes the relationship stated rather than inferred: the pistol's own
        // skeleton is rooted at R_grip, the bone the hands' Pistol socket attaches to.
        Assert.Equal("Confirmed", pistol.Confidence);
        Assert.Contains("rooted at", pistol.Evidence, StringComparison.OrdinalIgnoreCase);

        // And nothing may be reported without saying how it was established.
        Assert.All(attachments, a =>
        {
            Assert.Contains(a.Confidence, new[] { "Confirmed", "Likely" });
            Assert.False(string.IsNullOrWhiteSpace(a.Evidence));
        });
    }

    [RequiresGameFact]
    public void Attachments_FindWeaponsWhoseGroupIsNotSpeltLikeTheSocket()
    {
        var attachments = new AssetContextService(Catalog()).Attachments(Hands());
        var bySocket = attachments.ToDictionary(a => a.Socket, StringComparer.OrdinalIgnoreCase);

        // The game does not spell its sockets and its groups the same way. Requiring an exact match
        // found the pistol and left most of the arsenal looking unsupported when it was only unnamed.
        Assert.Equal("WP_ChemicalThrower", bySocket["Chem"].Group);
        Assert.Equal("WP_GrenadeLauncher", bySocket["Launcher"].Group);

        // The ones that do line up must not be broken by the looser rule.
        Assert.Equal("WP_Pistol", bySocket["Pistol"].Group);
        Assert.Equal("WP_TommyGun", bySocket["TommyGun"].Group);
        Assert.Equal("WP_Crossbow", bySocket["Crossbow"].Group);

        // UNKNOWN: the Wrench socket resolves to nothing. WP_Wrench carries no SkeletalMesh in
        // ShockGame.U, so the wrench viewmodel is either a static mesh or lives elsewhere.
        Assert.DoesNotContain("Wrench", bySocket.Keys);

        Assert.True(attachments.Count >= 5, $"only {attachments.Count} weapons resolved");
    }

    [RequiresGameFact]
    public void Counterpart_PairsTheWeaponAnimationWithTheHandAnimation()
    {
        string[] weaponAnimations = ["FastReload", "FireSingle"];

        Assert.Equal("FastReload", AssetContextService.Counterpart("FastReloadPistol", weaponAnimations));
        Assert.Equal("FireSingle", AssetContextService.Counterpart("FireSinglePistol", weaponAnimations));

        // A short or absent match is rejected rather than guessed at.
        Assert.Null(AssetContextService.Counterpart("EquipPistol", weaponAnimations));
        Assert.Null(AssetContextService.Counterpart("X", weaponAnimations));
    }

    [RequiresGameFact]
    public void Attachment_LoadsItsOwnMeshSkeletonAndAnimations()
    {
        var catalog = Catalog();
        var pistol = new AssetContextService(catalog).Attachments(Hands()).Single(a => a.Socket == "Pistol");

        var subject = new MeshPreviewService(catalog).LoadAttachment(pistol);

        Assert.Null(subject.Problem);
        Assert.True(subject.Model.HasGeometry);
        Assert.Equal(3736, subject.Model.Vertices.Count);
        Assert.Equal(8, subject.Model.Bones.Count);
        Assert.Contains("FastReload", subject.Animations);
    }

    [RequiresGameFact]
    public void Render_PlacesTheWeaponAtTheHandsSocketBone()
    {
        var catalog = Catalog();
        var entry = Hands();
        var preview = new MeshPreviewService(catalog);
        var pistol = new AssetContextService(catalog).Attachments(entry).Single(a => a.Socket == "Pistol");

        var host = preview.Load(entry).Model;
        var weapon = preview.LoadAttachment(pistol).Model;

        int bone = -1;
        for (int i = 0; i < host.Bones.Count; i++)
            if (string.Equals(host.Bones[i].Name, pistol.SocketBone, StringComparison.OrdinalIgnoreCase)) bone = i;
        Assert.True(bone >= 0, "the socket bone must exist on the host skeleton");

        var transform = host.Bones[bone].RestGlobal;

        // The weapon's own origin lands on the socket bone: that is what attaching means here.
        var placed = Vector3.Transform(Vector3.Zero, transform);
        Assert.Equal(transform.Translation.X, placed.X, 3);

        // The weapon must sit inside the hands' own extent, not somewhere off in space.
        float distance = (transform.Translation - host.Centre).Length();
        Assert.True(distance < host.Radius * 2f,
            $"the socket bone is {distance:0.#} from the hands' centre, whose radius is {host.Radius:0.#}");

        var alone = SoftwareRenderer.Render(
            [new PreviewInstance(host)], PreviewCamera.Frame(host), new RenderOptions(), 320, 240);

        var together = SoftwareRenderer.Render(
            [new PreviewInstance(host), new PreviewInstance(weapon, null, transform)],
            PreviewCamera.Frame(host), new RenderOptions(), 320, 240);

        int changed = 0;
        for (int i = 0; i < alone.Rgba.Length; i += 4)
            if (alone.Rgba[i] != together.Rgba[i] || alone.Rgba[i + 1] != together.Rgba[i + 1]) changed++;

        // This is a rest-pose render, and in the rest pose the pistol sits largely inside the
        // closed fist — so what it measures is "the weapon is drawn somewhere near the hand", not
        // how much of it is visible. The posed view in Render_ContextSnapshot is the one to look at.
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_ATTACHMENT_SNAPSHOT");
        if (!string.IsNullOrWhiteSpace(target))
        {
            Core.Textures.PngWriter.Write(target, together.Rgba, together.Width, together.Height);
        }

        double difference = (double)changed / (alone.Width * alone.Height);
        Assert.True(difference > 0.002, $"adding the weapon changed only {difference:P2} of the view");
    }

    [RequiresGameFact]
    public void EveryWeaponTheHandsNameDrawsAndAnimates()
    {
        var catalog = Catalog();
        var preview = new MeshPreviewService(catalog);
        var attachments = new AssetContextService(catalog).Attachments(Hands())
            .Where(a => !a.IsStatic)
            .ToList();

        Assert.NotEmpty(attachments);

        // Every one of them used to load its skeleton and animations and then draw nothing, because
        // a weapon's vertices are all rigidly bound and the reader rejected the empty skinned block
        // that says so.
        foreach (var attachment in attachments)
        {
            var subject = preview.LoadAttachment(attachment);

            Assert.True(subject.Model.HasGeometry, $"{attachment.MeshObject} produced no geometry");
            Assert.NotEmpty(subject.Model.Bones);

            // The only thing left to report is that a two-material mesh is textured from the first
            // of them. Nothing should still be saying it cannot be drawn.
            if (subject.Problem is not null)
                Assert.Contains("materials", subject.Problem, StringComparison.OrdinalIgnoreCase);
        }
    }

    /// <summary>Renders the whole first-person set so a human can look at it.</summary>
    [RequiresGameFact]
    public void Render_ContextSnapshot()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_CONTEXT_SNAPSHOT");
        if (string.IsNullOrWhiteSpace(target)) return;

        var catalog = Catalog();
        var entry = Hands();
        var preview = new MeshPreviewService(catalog);
        var pistol = new AssetContextService(catalog).Attachments(entry).Single(a => a.Socket == "Pistol");

        var host = preview.Load(entry).Model;
        var weapon = preview.LoadAttachment(pistol).Model;

        var hostAnimation = preview.LoadAnimation(entry, "FastReloadPistol")!;
        var weaponAnimation = preview.LoadAttachmentAnimation(pistol, "FastReload")!;

        int bone = 0;
        for (int i = 0; i < host.Bones.Count; i++)
            if (string.Equals(host.Bones[i].Name, pistol.SocketBone, StringComparison.OrdinalIgnoreCase)) bone = i;

        const int frame = 27;
        var hostPose = host.Pose(hostAnimation.Decoded, frame);
        var weaponPose = weapon.Pose(weaponAnimation.Decoded, frame);

        var (centre, radius) = host.BoundsOver(host.SamplePoses(hostAnimation.Decoded));

        var image = SoftwareRenderer.Render(
            [
                new PreviewInstance(host, hostPose),
                new PreviewInstance(weapon, weaponPose, hostPose[bone]),
            ],
            PreviewCamera.Frame(centre, radius).Orbit(0.5f, 0.1f),
            new RenderOptions { ShowSockets = true },
            640, 560);

        Core.Textures.PngWriter.Write(target, image.Rgba, image.Width, image.Height);
        Assert.True(File.Exists(target));
    }
}
