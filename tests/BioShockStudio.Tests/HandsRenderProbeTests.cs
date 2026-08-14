using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Scratch: render the hands with a weapon. Writes to <c>BIOSHOCK_HANDS_RENDER</c>.</summary>
[Collection(GameCollection.Name)]
public sealed class HandsRenderProbeTests(GameFixture game)
{
    [RequiresGameFact]
    public void Probe()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_HANDS_RENDER");
        if (string.IsNullOrWhiteSpace(target)) return;

        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        var preview = new MeshPreviewService(catalog);

        using var package = Core.Packages.BioShockPackage.Open(game.LighthousePackage);
        var entry = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);
        var host = preview.Load(entry).Model;
        var context = new AssetContextService(catalog);

        foreach (var (socket, hostAnimation, weaponAnimation) in new[]
                 {
                     ("Crossbow", "FidgetCrossbow", "Fidget"),
                     ("Pistol", "FidgetPistol", "Fidget"),
                 })
        {
            var attachment = context.Attachments(entry).FirstOrDefault(a => a.Socket == socket);
            if (attachment is null) continue;
            var weapon = preview.LoadAttachment(attachment).Model;

            int bone = 0;
            for (int i = 0; i < host.Bones.Count; i++)
                if (string.Equals(host.Bones[i].Name, attachment.SocketBone, StringComparison.OrdinalIgnoreCase)) bone = i;

            var loaded = preview.LoadAnimation(entry, hostAnimation);
            if (loaded is null) continue;
            var hostPose = host.Pose(loaded.Decoded, 0);

            var weaponLoaded = preview.LoadAttachmentAnimation(attachment, weaponAnimation);
            var weaponPose = weaponLoaded is null ? null : weapon.Pose(weaponLoaded.Decoded, 0);

            var instances = new List<PreviewInstance>
            {
                new(host, hostPose),
                new(weapon, weaponPose, hostPose[bone]),
            };

            var (centre, radius) = host.BoundsOver(host.SamplePoses(loaded.Decoded));
            foreach (var (label, yaw) in new[] { ("a", 0.5f), ("c", 0.5f + MathF.PI) })
            {
                var camera = PreviewCamera.Frame(centre, radius).Orbit(yaw, 0.1f);
                var image = SoftwareRenderer.Render(instances, camera, new RenderOptions(), 460, 460);
                Core.Textures.PngWriter.Write(target.Replace(".png", $"_{socket}_{label}.png"), image.Rgba, 460, 460);
            }
        }
    }
}
