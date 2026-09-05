using BioShockStudio.Core.Game;
using BioShockStudio.Core.UI.Swf;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Scaleform tag-512 (DefineBitsDxt) decode against real HUDPC.swf bytes — 14 bitmaps including
/// five 2048×1024 DXT5 chrome atlases and the 4096×256 vignette. See docs/UI_ROADMAP.md Phase U1.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class SwfBitmapReaderTests(GameFixture game)
{
    private string HudPcPath =>
        Path.Combine(GameLocator.FlashMoviesDirectory(game.RequireRoot), "HUDPC.swf");

    [RequiresGameFact]
    public void HudPcYieldsExactlyFourteenBitmaps()
    {
        var swf = SwfFile.Read(HudPcPath);
        var dict = SwfCharacterDictionary.Build(swf);
        Assert.Equal(14, dict.Bitmaps.Count());
        Assert.Equal(14, swf.Tags.Count(t => t.Code == SwfBitmapReader.TagCode));
    }

    [RequiresGameFact]
    public void HudPcAtlasesAndVignetteHaveKnownIdsSizesAndFormats()
    {
        var dict = SwfCharacterDictionary.Build(SwfFile.Read(HudPcPath));
        var byId = dict.Bitmaps.ToDictionary(b => b.CharacterId);

        // Five 2048×1024 DXT5 chrome atlases.
        foreach (int id in new[] { 86, 100, 105, 111, 118 })
        {
            Assert.True(byId.ContainsKey(id), $"missing atlas id {id}");
            SwfBitmap b = byId[id];
            Assert.Equal(2048, b.Width);
            Assert.Equal(1024, b.Height);
            Assert.Equal(SwfBitmapFormat.Dxt5, b.Format);
            Assert.Equal(0, b.Flags);
            Assert.Equal(2048 * 1024 * 4, b.Rgba.Length);
        }

        // Bottom vignette gradient.
        SwfBitmap vignette = byId[177];
        Assert.Equal(4096, vignette.Width);
        Assert.Equal(256, vignette.Height);
        Assert.Equal(SwfBitmapFormat.Dxt5, vignette.Format);

        // DXT1 samples also present in HUDPC.
        Assert.Equal(SwfBitmapFormat.Dxt1, byId[552].Format);
        Assert.Equal(256, byId[552].Width);
        Assert.Equal(256, byId[552].Height);
    }

    [RequiresGameFact]
    public void DecodedAtlasesAreNonEmptyAndNonUniform()
    {
        var dict = SwfCharacterDictionary.Build(SwfFile.Read(HudPcPath));

        // Chrome atlas — RGB variation (same discipline as capture_shot.ps1).
        Assert.True(dict.TryGetBitmap(86, out SwfBitmap? atlas));
        Assert.NotNull(atlas);
        double rgbStd = RgbaChannelStdDev(atlas!.Rgba, channels: 3);
        Assert.True(rgbStd >= 1.0,
            $"atlas 86 looks blank/uniform (RGB stddev {rgbStd:F3}); decode likely wrong.");

        // Bottom vignette is black RGB with an alpha gradient — variation lives in A.
        Assert.True(dict.TryGetBitmap(177, out SwfBitmap? vignette));
        Assert.NotNull(vignette);
        double alphaStd = RgbaChannelStdDev(vignette!.Rgba, channels: 4, channelOffset: 3, channelCount: 1);
        Assert.True(alphaStd >= 1.0,
            $"vignette 177 alpha looks uniform (A stddev {alphaStd:F3}); decode likely wrong.");
    }

    /// <summary>
    /// Mean of per-channel stddevs over the selected channels. Default is RGB (matches
    /// <c>capture_shot.ps1</c>); pass <paramref name="channelOffset"/>/<paramref name="channelCount"/>
    /// for alpha-only gradients like the HUD vignette.
    /// </summary>
    private static double RgbaChannelStdDev(
        byte[] rgba, int channels = 3, int channelOffset = 0, int channelCount = -1)
    {
        if (channelCount < 0) channelCount = channels;
        long n = rgba.Length / 4;
        if (n == 0) return 0;

        double sumStd = 0;
        for (int c = 0; c < channelCount; c++)
        {
            int ch = channelOffset + c;
            double mean = 0;
            for (int i = 0; i < rgba.Length; i += 4)
                mean += rgba[i + ch];
            mean /= n;

            double var = 0;
            for (int i = 0; i < rgba.Length; i += 4)
            {
                double d = rgba[i + ch] - mean;
                var += d * d;
            }
            sumStd += Math.Sqrt(var / n);
        }
        return sumStd / channelCount;
    }

    [RequiresGameFact]
    public void SwfInspectNamesTag512DefineBitsDxt()
    {
        Assert.Equal("DefineBitsDxt", SwfTagNames.Get(SwfBitmapReader.TagCode));
        Assert.DoesNotContain("Unknown", SwfTagNames.Get(SwfBitmapReader.TagCode), StringComparison.Ordinal);

        var swf = SwfFile.Read(HudPcPath);
        Assert.Contains(swf.Tags, t => t.Code == 512);
        Assert.Equal("DoAction", SwfTagNames.Get(12));
        Assert.Equal("DefineButton2", SwfTagNames.Get(34));
    }
}
