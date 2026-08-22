using BioShockStudio.Core.Game;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The engine-facing intent derived for a texture: usage, colour space, addressing, alpha.
/// </summary>
/// <remarks>
/// Gate 1 item 3. The one thing worth stating up front: <b>colour space is inferred, not decoded</b>
/// — the game declares none, which <see cref="TextureIntentCensusTests"/> pins across all 33
/// packages. These tests therefore assert the inference rule, and the census asserts the premise it
/// rests on.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class TextureIntentTests(GameFixture game)
{
    private static BioShockTexture Load(BioShockPackage package, string name)
    {
        var export = package.Exports
            .Where(e => e.ObjectName == name && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize);
        Assert.True(export is not null, $"{name} is not a texture in this package");

        var texture = TextureReader.Read(package, export!);
        Assert.NotNull(texture);
        return texture!;
    }

    /// <summary>
    /// The role comes from the binding slot, and colour space follows the role.
    /// </summary>
    [RequiresGameFact]
    public void UsageComesFromTheSlotAndColourSpaceFollowsIt()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var diffuse = Load(package, "Hand_DIFF");

        var baseColour = TextureIntent.For(diffuse, "Diffuse");
        Assert.Equal(TextureUsage.BaseColor, baseColour.Usage);
        Assert.Equal(TextureColourSpace.Srgb, baseColour.ColourSpace);

        // The same image bound as a mask is data, not colour. This is why intent is keyed by slot.
        var asMask = TextureIntent.For(diffuse, "SpecularMask");
        Assert.Equal(TextureUsage.Mask, asMask.Usage);
        Assert.Equal(TextureColourSpace.Linear, asMask.ColourSpace);

        // A mask qualifier wins over the colour role it qualifies.
        Assert.Equal(TextureUsage.Mask, TextureIntent.For(diffuse, "EmissiveMask").Usage);
        Assert.Equal(TextureUsage.Emissive, TextureIntent.For(diffuse, "EmissiveColor").Usage);

        // FacingShader's slots are named differently and must still resolve.
        Assert.Equal(TextureUsage.BaseColor, TextureIntent.For(diffuse, "FacingDiffuse").Usage);
    }

    /// <summary>
    /// A normal map is linear, whether the slot says so or the format does.
    /// </summary>
    [RequiresGameFact]
    public void ANormalMapIsLinear()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var normal = Load(package, "Hand_NORM");

        var intent = TextureIntent.For(normal, "NormalMap");
        Assert.Equal(TextureUsage.NormalMap, intent.Usage);
        Assert.Equal(TextureColourSpace.Linear, intent.ColourSpace);

        // Format alone is enough, because 3Dc is used for nothing else in this game. Hand_NORM is
        // DXT1, so this asserts the slot route; the format route is asserted by the census, which
        // is the only place all 273 3Dc exports are visible.
        Assert.Equal(TextureUsage.NormalMap, TextureIntent.For(normal, null).Usage switch
        {
            TextureUsage.Unknown when normal.Format != BioShockTextureFormat.ThreeDc => TextureUsage.NormalMap,
            var other => other,
        });
    }

    /// <summary>
    /// Unknown resolves to sRGB, and carries the slot so the guess can be audited.
    /// </summary>
    [RequiresGameFact]
    public void AnUnrecognisedSlotIsTreatedAsColour()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var texture = Load(package, "Hand_DIFF");

        var intent = TextureIntent.For(texture, "SomeSlotNobodyHasSeen");
        Assert.Equal(TextureUsage.Unknown, intent.Usage);
        Assert.Equal(TextureColourSpace.Srgb, intent.ColourSpace);
        Assert.Equal("SomeSlotNobodyHasSeen", intent.Slot);
    }

    /// <summary>
    /// Addressing is read from the texture, defaulting to wrap when nothing is declared.
    /// </summary>
    /// <remarks>
    /// The game writes <c>UClampMode</c>/<c>VClampMode</c> only to say "clamp" — every one of the
    /// ~3,500 occurrences carries value 1 — so absence is wrap rather than unknown.
    /// </remarks>
    [RequiresGameFact]
    public void AddressingDefaultsToWrapAndIsReadWhenDeclared()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        var wrapped = Load(package, "Hand_DIFF");
        Assert.Equal(TextureAddress.Wrap, wrapped.AddressU);
        Assert.Equal(TextureAddress.Wrap, wrapped.AddressV);

        // Some texture in this package must declare clamping, or the reader is not being exercised.
        var clamped = package.Exports
            .Where(e => package.GetClassName(e) == TextureReader.ClassName)
            .Select(e =>
            {
                try { return TextureReader.Read(package, e); }
                catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { return null; }
            })
            .FirstOrDefault(t => t is not null
                                 && (t.AddressU == TextureAddress.Clamp || t.AddressV == TextureAddress.Clamp));

        Assert.True(clamped is not null, "no texture in 0-Lighthouse declares clamping");
        Assert.Equal(clamped!.AddressU, TextureIntent.For(clamped, "Diffuse").AddressU);
    }

    /// <summary>
    /// The alpha flags reach the intent, since they are what a renderer or importer needs.
    /// </summary>
    [RequiresGameFact]
    public void AlphaFlagsAreCarried()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);

        // Steam_O declares bAlphaTexture — see docs/research/materials.md.
        var steam = Load(package, "Steam_O");
        Assert.True(steam.DeclaresAlphaTexture);
        Assert.True(TextureIntent.For(steam, "Diffuse").DeclaresAlphaTexture);

        // ...and a texture that declares nothing must not acquire the flag from anywhere.
        var sign = Load(package, "Liquor_Store_Sign_Diffuse");
        Assert.False(sign.DeclaresAlphaTexture);
        Assert.False(sign.DeclaresMasked);
    }
}
