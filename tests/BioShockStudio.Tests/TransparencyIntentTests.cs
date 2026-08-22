using BioShockStudio.Core.Game;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// When a diffuse texture's alpha channel means opacity, and when it means something else.
/// </summary>
/// <remarks>
/// <para>
/// <b>Why this exists.</b> The level viewport drew parts of solid props invisible. The GL shader
/// never blends — it writes alpha 1.0 — so its only transparency mechanism is a
/// <c>discard</c> below 0.35, applied to every textured fragment. A great many of this game's
/// diffuse textures carry a gloss or specular mask in alpha rather than opacity, and a few
/// "diffuse" slots resolve to a normal map or heightmap outright; those sit around 0.3 across the
/// whole surface, so the discard removed all of it and the prop vanished.
/// </para>
/// <para>
/// <b>The fix reads intent instead of pixels alone</b>, from two independent signals, either of
/// which is sufficient: the material declaring transparency
/// (<see cref="BioShockMaterial.DeclaresTransparency"/>, whose flag names are
/// <c>CONFIRMED_EXTERNAL</c> from UModel's <c>UTexture</c> table and Nyko's SDK), or the texture
/// genuinely containing cutout holes (<see cref="PreviewImage.HasCutoutHoles"/>).
/// </para>
/// <para>
/// <b>Both halves are asserted here deliberately.</b> Forcing surfaces opaque is the dangerous
/// direction: this game's gratings, foliage and decals are cutouts, and turning them into solid
/// rectangles would be a worse bug than the one being fixed. So the cutout cases are pinned
/// alongside the mask cases.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class TransparencyIntentTests(GameFixture game)
{
    private sealed record Resolved(BioShockMaterial Material, PreviewImage Diffuse);

    /// <summary>A material in 0-Lighthouse together with its decoded diffuse, at full size.</summary>
    private static Resolved Load(BioShockPackage package, string materialName)
    {
        var export = package.Exports.FirstOrDefault(e =>
            e.ObjectName == materialName && MaterialReader.IsMaterialClass(package.GetClassName(e)));
        Assert.True(export is not null, $"{materialName} is not a material in 0-Lighthouse");

        var material = MaterialReader.Read(package, export!);
        Assert.NotNull(material);

        string? diffuseName = material!.DiffuseTexture;
        Assert.True(diffuseName is { Length: > 0 }, $"{materialName} binds no diffuse");

        var textureExport = package.Exports
            .Where(e => e.ObjectName.Equals(diffuseName, StringComparison.OrdinalIgnoreCase)
                        && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize);
        Assert.True(textureExport is not null, $"{diffuseName} is not a texture in 0-Lighthouse");

        var texture = TextureReader.Read(package, textureExport!);
        Assert.True(texture is { Mips.Count: > 0 }, $"{diffuseName} decoded no mips");

        var mip = texture!.Mips[0];
        var rgba = BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height);
        return new Resolved(material, new PreviewImage(mip.Width, mip.Height, rgba));
    }

    /// <summary>
    /// The surfaces that were disappearing: nothing declares transparency and there are no holes.
    /// </summary>
    /// <remarks>
    /// Measured, full-size mip: <c>Liquor_Store_Sign_Diffuse</c> and <c>martini_neon</c> are 0.0%
    /// holes with 100% of texels mid-range, <c>GraniteColor_NOR</c> is 0.0%/80.0%. A uniform
    /// mid-range alpha over an entire texture is not an opacity map; it is a mask channel.
    /// </remarks>
    [RequiresGameFact]
    public void AMaskChannelIsNotOpacity()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        foreach (string name in new[] { "Liquor_Store_Sign_Diffuse", "martini_neon", "GraniteColor_NOR" })
        {
            var (material, diffuse) = Load(package, name);

            Assert.False(material.DeclaresTransparency,
                $"{name} declares transparency after all, so it is not an example of this case");
            Assert.False(diffuse.HasCutoutHoles, $"{name} has cutout holes, so it is a real cutout");

            // The texture does carry non-opaque alpha — that is exactly why it used to vanish.
            Assert.True(diffuse.HasTransparency, $"{name} has no non-opaque alpha to misread");
        }
    }

    /// <summary>
    /// A material that states its intent is honoured, even where the texture has few holes.
    /// </summary>
    [RequiresGameFact]
    public void ADeclaredTransparencyIsHonoured()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        // Steam and hitspray both declare bAlphaTexture; the shader-side cases declare Opacity.
        foreach (string name in new[] { "Steam_O", "hitspray", "ExpSmoke_Shader", "BloodSpray_Shader" })
        {
            var (material, _) = Load(package, name);
            Assert.True(material.DeclaresTransparency, $"{name} no longer declares transparency");
        }
    }

    /// <summary>
    /// A cutout with no declaration is still a cutout — the case that must not be forced opaque.
    /// </summary>
    /// <remarks>
    /// This is the guard on the dangerous direction. Across 0-Lighthouse, 136 materials with
    /// non-opaque alpha declare nothing at all, and only 26 of those also lack holes; the other
    /// ~110 are hole-bearing cutouts that draw correctly today and must keep doing so.
    /// </remarks>
    [RequiresGameFact]
    public void AnUndeclaredCutoutIsStillACutout()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        foreach (string name in new[] { "CloudWAlpha", "splash", "FishBubbles_Diffuse_BSG" })
        {
            var (material, diffuse) = Load(package, name);

            Assert.False(material.DeclaresTransparency,
                $"{name} declares transparency, so it is not an example of the undeclared case");
            Assert.True(diffuse.HasCutoutHoles,
                $"{name} would be forced opaque, turning a real cutout into a solid rectangle");
        }
    }

    /// <summary>
    /// The whole-map shape of the two signals, so the counts in the docs cannot rot silently.
    /// </summary>
    [RequiresGameFact]
    public void MostAlphaBearingDiffusesAreExplainedByOneOfTheTwoSignals()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var texturesByName = new Dictionary<string, ObjectExport>(StringComparer.OrdinalIgnoreCase);
        foreach (var export in package.Exports)
        {
            if (package.GetClassName(export) != TextureReader.ClassName) continue;
            if (!texturesByName.TryGetValue(export.ObjectName, out var existing)
                || export.SerialSize > existing.SerialSize)
                texturesByName[export.ObjectName] = export;
        }

        int nonOpaque = 0, forcedOpaque = 0;

        foreach (var export in package.Exports)
        {
            if (!MaterialReader.IsMaterialClass(package.GetClassName(export))) continue;

            BioShockMaterial? material;
            try { material = MaterialReader.Read(package, export); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (material?.DiffuseTexture is not { Length: > 0 } diffuseName) continue;
            if (!texturesByName.TryGetValue(diffuseName, out var textureExport)) continue;

            BioShockTexture? texture;
            try { texture = TextureReader.Read(package, textureExport); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }
            if (texture is null || texture.Mips.Count == 0) continue;

            var mip = texture.Mips[0];
            byte[] rgba;
            try { rgba = BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height); }
            catch (Exception ex) when (ex is InvalidDataException or ArgumentException) { continue; }

            var image = new PreviewImage(mip.Width, mip.Height, rgba);
            if (!image.HasTransparency) continue;

            nonOpaque++;
            if (!material.DeclaresTransparency && !image.HasCutoutHoles) forcedOpaque++;
        }

        // Measured 23 Aug 2026: 211 alpha-bearing diffuses, 26 explained by neither signal.
        Assert.InRange(nonOpaque, 190, 230);

        // The change must stay a scalpel. If this fraction climbs, the rule has started forcing
        // real cutouts opaque and the viewport is losing gratings rather than gaining props.
        Assert.InRange(forcedOpaque, 15, 40);
        Assert.True(forcedOpaque * 100.0 / nonOpaque < 20,
            $"{forcedOpaque} of {nonOpaque} alpha-bearing diffuses would be forced opaque, which is "
            + "too many to be only the mask-channel cases");
    }
}
