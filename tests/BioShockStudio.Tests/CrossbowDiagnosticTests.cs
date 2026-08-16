using System.Numerics;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Scratch diagnostic for the crossbow reload. Delete once the pairing question is settled.</summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class CrossbowDiagnosticTests(GameFixture game)
{
    [RequiresGameFact]
    public void Render_CrossbowReloadFilmstrip()
    {
        string? target = Environment.GetEnvironmentVariable("BIOSHOCK_CROSSBOW_SNAPSHOT");
        if (string.IsNullOrWhiteSpace(target)) return;

        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);

        using var package = Core.Packages.BioShockPackage.Open(game.LighthousePackage);
        var entry = AssetCatalogService.Catalogue(package, "0-Lighthouse")
            .Single(e => e.Name == "NEWPlayerHands" && e.Category == AssetCategory.FirstPerson);
        var preview = new MeshPreviewService(catalog);
        var crossbow = new AssetContextService(catalog).Attachments(entry).Single(a => a.Socket == "Crossbow");

        var host = preview.Load(entry).Model;
        var weapon = preview.LoadAttachment(crossbow).Model;

        var hostAnimation = preview.LoadAnimation(entry, Environment.GetEnvironmentVariable("BIOSHOCK_XBOW_ANIM") ?? "ReloadCrossbow")!;
        var weaponAnimation = preview.LoadAttachmentAnimation(crossbow, "Reload")!;

        int bone = 0;
        for (int i = 0; i < host.Bones.Count; i++)
            if (string.Equals(host.Bones[i].Name, crossbow.SocketBone, StringComparison.OrdinalIgnoreCase)) bone = i;

        int hostFrames = hostAnimation.Decoded.FrameCount;
        int weaponFrames = weaponAnimation.Decoded.FrameCount;
        var (centre, radius) = host.BoundsOver(host.SamplePoses(hostAnimation.Decoded));

        const int columns = 4, rows = 4, cell = 300;
        int[] frames = new int[columns * rows];
        for (int i = 0; i < frames.Length; i++) frames[i] = i * (hostFrames - 1) / (frames.Length - 1);

        // Orbit a single frame instead of stepping time, when asked: the rig's own space is not
        // Z-up, so a fixed camera angle says very little about where the hands actually are.
        int orbitFrame = int.TryParse(Environment.GetEnvironmentVariable("BIOSHOCK_XBOW_ORBIT"), out int of) ? of : -1;
        if (orbitFrame >= 0) for (int i = 0; i < frames.Length; i++) frames[i] = orbitFrame;

        // Two strips: the weapon animated in step with the hands by time, and the weapon left in its
        // rest pose — which is what the application currently draws, because it drops a weapon
        // animation whose frame count differs from the host's.
        foreach (bool animateWeapon in new[] { true, false })
        {
            var sheet = new byte[columns * cell * rows * cell * 4];

            for (int i = 0; i < frames.Length; i++)
            {
                var hostPose = host.Pose(hostAnimation.Decoded, frames[i]);

                // Sample the weapon by normalised time, not by frame index — the two rigs do not
                // agree on frame count.
                int weaponFrame = hostFrames <= 1
                    ? 0
                    : (int)MathF.Round(frames[i] * (weaponFrames - 1) / (float)(hostFrames - 1));

                var instances = new List<PreviewInstance> { new(host, hostPose) };
                instances.Add(animateWeapon
                    ? new PreviewInstance(weapon, weapon.Pose(weaponAnimation.Decoded, weaponFrame), hostPose[bone])
                    : new PreviewInstance(weapon, null, hostPose[bone]));

                // "Player view": the viewmodel camera sits at the rig root, not the head — root to
                // weapon is 41 cm, head to weapon is 100 cm. Looking from the root along the line to
                // the weapon reproduces roughly what the game draws, which is the only view that can
                // be compared against a screenshot.
                PreviewCamera camera;
                if (Environment.GetEnvironmentVariable("BIOSHOCK_XBOW_PLAYERVIEW") == "1")
                {
                    var eye = hostPose[RootBone(host)].Translation;
                    var look = WeaponCentre(weapon, hostPose[bone]);
                    var back = eye - look;
                    // Stand well behind the eye point, or the camera sits inside the forearm.
                    float distance = back.Length() * 3.5f;
                    var dir = Vector3.Normalize(back);
                    camera = new PreviewCamera
                    {
                        Target = look,
                        Distance = distance,
                        Pitch = MathF.Asin(Math.Clamp(dir.Z, -1f, 1f)),
                        Yaw = MathF.Atan2(dir.Y, dir.X),
                        FieldOfView = 70f * MathF.PI / 180f,
                    };
                }
                else
                {
                    camera = PreviewCamera.Frame(centre, radius).Orbit(
                        0.5f + (orbitFrame >= 0 ? i * MathF.PI * 2f / frames.Length : 0f),
                        orbitFrame >= 0 ? 0.2f : 0.1f);
                }

                var image = SoftwareRenderer.Render(instances, camera, new RenderOptions(), cell, cell);

                int cx = (i % columns) * cell, cy = (i / columns) * cell;
                for (int y = 0; y < cell; y++)
                {
                    Array.Copy(image.Rgba, y * cell * 4,
                        sheet, ((cy + y) * columns * cell + cx) * 4, cell * 4);
                }
            }

            string path = target.Replace(".png", animateWeapon ? "_animated.png" : "_rest.png");
            Core.Textures.PngWriter.Write(path, sheet, columns * cell, rows * cell);
        }

        Assert.True(true);
    }

    private static int RootBone(PreviewModel model)
    {
        for (int i = 0; i < model.Bones.Count; i++)
            if (model.Bones[i].Parent < 0) return i;
        return 0;
    }

    private static Vector3 WeaponCentre(PreviewModel weapon, Matrix4x4 socket)
    {
        var sum = Vector3.Zero;
        foreach (var v in weapon.Vertices) sum += v.Position;
        return Vector3.Transform(sum / Math.Max(1, weapon.Vertices.Count), socket);
    }
}
