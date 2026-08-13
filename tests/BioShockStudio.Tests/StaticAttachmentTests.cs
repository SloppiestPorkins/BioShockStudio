using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Covers the second kind of thing a socket points at: a static prop in the host's own group.
/// </summary>
/// <remarks>
/// The first kind — a weapon group with its own skeleton and animations — is covered by
/// <see cref="ContextTests"/>. This one needs no second skeleton and no second package, and until
/// the static-mesh reader existed it could not have been drawn even once resolved.
/// </remarks>
[Collection(GameCollection.Name)]
public sealed class StaticAttachmentTests(GameFixture game)
{
    private AssetCatalogService Catalog()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        return catalog;
    }

    private string MedicalFile => Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");

    private CatalogEntry? Bouncer()
    {
        using var package = BioShockPackage.Open(MedicalFile);
        return AssetCatalogService.Catalogue(package, "1-Medical")
            .Where(e => e.Group == "NewProtectorBouncer" && e.ClassName == "SkeletalMesh")
            .MaxBy(e => e.SerialSize);
    }

    [RequiresGameFact]
    public void Bouncer_ResolvesItsDrillCageAndBackpack()
    {
        if (Bouncer() is not { } host) return;

        var attachments = new AssetContextService(Catalog()).Attachments(host);

        var byMesh = attachments
            .Where(a => a.IsStatic)
            .ToDictionary(a => a.MeshObject, a => a, StringComparer.OrdinalIgnoreCase);

        Assert.Contains("ConeDrill", byMesh.Keys);
        Assert.Contains("ConeDrillCage", byMesh.Keys);
        Assert.Contains("ConeDrillBackpack", byMesh.Keys);

        // Each prop is claimed by exactly one socket: 'Drill' must take ConeDrill rather than
        // ConeDrillCage, which it also matches as a substring.
        Assert.Equal(byMesh.Count, attachments.Count(a => a.IsStatic));
        Assert.Equal("ConeDrill", byMesh["ConeDrill"].MeshObject);
    }

    [RequiresGameFact]
    public void StaticAttachments_CarryTheirEvidenceAndClaimNoSkeleton()
    {
        if (Bouncer() is not { } host) return;

        foreach (var attachment in new AssetContextService(Catalog()).Attachments(host).Where(a => a.IsStatic))
        {
            // No skeleton of its own means it can never be Confirmed by the root-bone test, and the
            // tool must not imply otherwise.
            Assert.Equal("Likely", attachment.Confidence);
            Assert.Empty(attachment.AnimationPackageObject);
            Assert.Contains("static mesh in the host's own group", attachment.Evidence);
            Assert.Contains(attachment.MeshObject, attachment.Evidence);
        }
    }

    [RequiresGameFact]
    public void StaticAttachment_LoadsAsItsOwnPropWithNoBones()
    {
        if (Bouncer() is not { } host) return;

        var catalog = Catalog();
        var drill = new AssetContextService(catalog).Attachments(host)
            .Single(a => string.Equals(a.MeshObject, "ConeDrill", StringComparison.OrdinalIgnoreCase));

        var subject = new MeshPreviewService(catalog).LoadAttachment(drill);

        // It must be the drill, not the largest mesh in the group, which is the Bouncer's own body.
        Assert.True(subject.Model.HasGeometry);
        Assert.Equal(561, subject.Model.Vertices.Count);

        // And it must not borrow the host's skeleton just because they share a group.
        Assert.Empty(subject.Model.Bones);
        Assert.Empty(subject.Animations);
    }

    [RequiresGameFact]
    public void Bouncer_DrawsWithItsPropsOnTheirSocketBones()
    {
        if (Bouncer() is not { } entry) return;

        var catalog = Catalog();
        var preview = new MeshPreviewService(catalog);
        var host = preview.Load(entry).Model;
        var attachments = new AssetContextService(catalog).Attachments(entry).Where(a => a.IsStatic).ToList();

        Assert.NotEmpty(attachments);

        var instances = new List<PreviewInstance> { new(host) };
        int placed = 0;

        foreach (var attachment in attachments)
        {
            int bone = -1;
            for (int i = 0; i < host.Bones.Count; i++)
                if (string.Equals(host.Bones[i].Name, attachment.SocketBone, StringComparison.OrdinalIgnoreCase))
                    bone = i;
            if (bone < 0) continue;

            var prop = preview.LoadAttachment(attachment).Model;
            if (!prop.HasGeometry) continue;

            instances.Add(new PreviewInstance(prop, null, host.Bones[bone].RestGlobal));
            placed++;
        }

        Assert.True(placed > 0, "no static prop resolved onto a bone the host skeleton actually has");

        var camera = PreviewCamera.Frame(host);
        var alone = SoftwareRenderer.Render([new PreviewInstance(host)], camera, new RenderOptions(), 320, 240);
        var together = SoftwareRenderer.Render(instances, camera, new RenderOptions(), 320, 240);

        int changed = 0;
        for (int i = 0; i < alone.Rgba.Length; i += 4)
            if (alone.Rgba[i] != together.Rgba[i] || alone.Rgba[i + 1] != together.Rgba[i + 1]) changed++;

        double difference = (double)changed / (alone.Width * alone.Height);
        Assert.True(difference > 0.002, $"adding the props changed only {difference:P2} of the view");
    }

    /// <summary>Draws the Bouncer with its props so a human can look at it. Off unless a path is given.</summary>
    [RequiresGameFact]
    public void Bouncer_Snapshot()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_BOUNCER_SNAPSHOT");
        if (string.IsNullOrWhiteSpace(target) || Bouncer() is not { } entry) return;

        var catalog = Catalog();
        var preview = new MeshPreviewService(catalog);
        var host = preview.Load(entry).Model;

        var instances = new List<PreviewInstance> { new(host) };
        foreach (var attachment in new AssetContextService(catalog).Attachments(entry).Where(a => a.IsStatic))
        {
            int bone = -1;
            for (int i = 0; i < host.Bones.Count; i++)
                if (string.Equals(host.Bones[i].Name, attachment.SocketBone, StringComparison.OrdinalIgnoreCase))
                    bone = i;
            if (bone < 0) continue;

            var prop = preview.LoadAttachment(attachment).Model;
            if (prop.HasGeometry) instances.Add(new PreviewInstance(prop, null, host.Bones[bone].RestGlobal));
        }

        var image = SoftwareRenderer.Render(
            instances, PreviewCamera.Frame(host).Orbit(0.7f, 0.2f),
            new RenderOptions { ShowSkeleton = false, ShowSockets = false }, 560, 720);

        Core.Textures.PngWriter.Write(target, image.Rgba, image.Width, image.Height);
        Assert.True(File.Exists(target));
    }

    [RequiresGameFact]
    public void RivetGunSocket_MatchesDespiteTheSocketSuffix()
    {
        var catalog = Catalog();

        // ProtectorRosie declares 'RivetGunSocket' and her weapon group is WP_AI_RivetGun. Requiring
        // the names to match with the suffix left on made the whole shape look unsupported.
        foreach (string packageName in new[] { "1-Medical", "1-Welcome", "4-Recreation", "7-BossFight" })
        {
            using var package = BioShockPackage.Open(
                Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), packageName + ".bsm"));

            var rosie = AssetCatalogService.Catalogue(package, packageName)
                .Where(e => e.Group == "ProtectorRosie" && e.ClassName == "SkeletalMesh")
                .MaxBy(e => e.SerialSize);
            if (rosie is null) continue;

            var attachments = new AssetContextService(catalog).Attachments(rosie);
            var rivet = attachments.FirstOrDefault(a =>
                a.Socket.Contains("RivetGun", StringComparison.OrdinalIgnoreCase));

            Assert.NotNull(rivet);
            Assert.Contains("RivetGun", rivet.MeshObject + rivet.Group, StringComparison.OrdinalIgnoreCase);
            return;
        }
    }

    [RequiresGameFact]
    public void HandsAttachments_AreUnaffectedByTheSuffixStrip()
    {
        var catalog = Catalog();

        using var package = BioShockPackage.Open(game.LighthousePackage);
        var hands = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);

        var attachments = new AssetContextService(catalog).Attachments(hands);

        // The pistol is the project's target case and stays Confirmed: its own skeleton is rooted at
        // R_grip, the bone the socket names, which outranks anything found by name alone.
        var pistol = attachments.Single(a => a.Socket == "Pistol");
        Assert.Equal("Confirmed", pistol.Confidence);
        Assert.False(pistol.IsStatic);
    }
}
