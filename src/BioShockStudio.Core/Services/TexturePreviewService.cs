using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Services;

/// <summary>A decoded image, ready for a UI to display. Straight RGBA, eight bits per channel.</summary>
public sealed record PreviewImage(int Width, int Height, byte[] Rgba)
{
    private bool? _hasTransparency;

    /// <summary>
    /// True when any pixel is not fully opaque, so the UI knows to show transparency and the
    /// renderer knows to run a blended pass.
    /// </summary>
    /// <remarks>
    /// Cached: this is asked once per mesh per frame and scanning a 512-square texture on every
    /// call showed up as a visible cost in the viewport.
    /// </remarks>
    public bool HasTransparency
    {
        get
        {
            if (_hasTransparency is { } known) return known;

            bool found = false;
            for (int i = 3; i < Rgba.Length; i += 4)
            {
                if (Rgba[i] == 255) continue;
                found = true;
                break;
            }

            _hasTransparency = found;
            return found;
        }
    }

    /// <summary>
    /// True when enough of this image is fully punched through to be a cutout — a grating, foliage,
    /// a decal on a quad — rather than a channel that merely happens to hold values below 255.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The distinguishing measurement, taken across <c>0-Lighthouse</c>: a genuine cutout has a
    /// population of fully-transparent texels (smoke 26%, gratings and decals far more), whereas an
    /// alpha channel storing a gloss or specular mask sits in the middle of the range and has
    /// essentially none — <c>Liquor_Store_Sign_Diffuse</c>, <c>martini_neon</c> and
    /// <c>glassShard</c> all measure 0.0% holes with ~100% of texels mid-range.
    /// </para>
    /// <para>
    /// One percent rather than zero because block compression reconstructs a few stray texels near
    /// a hard alpha edge, so an exact-zero test would call a real cutout a mask on some textures.
    /// </para>
    /// </remarks>
    public bool HasCutoutHoles
    {
        get
        {
            if (_hasCutoutHoles is { } known) return known;

            int pixels = Rgba.Length / 4, holes = 0;
            for (int i = 3; i < Rgba.Length; i += 4)
                if (Rgba[i] < CutoutAlpha) holes++;

            _hasCutoutHoles = pixels > 0 && holes * 100.0 / pixels >= CutoutHolePercent;
            return _hasCutoutHoles.Value;
        }
    }

    private bool? _hasCutoutHoles;

    /// <summary>At or below this, a texel is a hole. Matches the software renderer's threshold.</summary>
    private const byte CutoutAlpha = 8;

    /// <summary>How much of an image must be punched through before its alpha reads as a cutout.</summary>
    private const double CutoutHolePercent = 1.0;
}

/// <summary>A texture's header facts plus the mip sizes available to preview.</summary>
public sealed record TexturePreview
{
    public required string Name { get; init; }
    public required BioShockTextureFormat Format { get; init; }
    public required int Width { get; init; }
    public required int Height { get; init; }
    public required IReadOnlyList<(int Width, int Height)> Mips { get; init; }
}

/// <summary>
/// Decodes textures for on-screen preview, using the same reader the extractor uses.
/// </summary>
/// <remarks>
/// There is no placeholder path here. A texture whose format is not understood returns null and the
/// UI says so, because a grey rectangle presented as the asset is worse than an honest gap.
/// </remarks>
public sealed class TexturePreviewService(AssetCatalogService catalog)
{
    /// <summary>Largest mip this will decode for display, in pixels per side.</summary>
    /// <remarks>
    /// The hands' diffuse is 5.6 MB and decodes to a 2048² image; the preview picks a smaller mip
    /// when one is available so that scrolling the browser does not allocate tens of megabytes per
    /// selection. Full resolution is still what gets extracted.
    /// </remarks>
    public const int PreferredMaximumSize = 1024;

    public TexturePreview? Describe(CatalogEntry entry)
    {
        using var lease = catalog.OpenShared(entry.Package);
        BioShockPackage package = lease;
        var texture = Read(package, entry);
        if (texture is null) return null;

        return new TexturePreview
        {
            Name = texture.Name,
            Format = texture.Format,
            Width = texture.Width,
            Height = texture.Height,
            Mips = texture.Mips.Select(m => (m.Width, m.Height)).ToList(),
        };
    }

    /// <summary>
    /// Decodes one mip to RGBA. Pass -1 to let the service pick the largest mip that is not
    /// wastefully big for a preview.
    /// </summary>
    public PreviewImage? Decode(CatalogEntry entry, int mip = -1)
    {
        using var lease = catalog.OpenShared(entry.Package);
        BioShockPackage package = lease;
        var texture = Read(package, entry);
        if (texture is null || texture.Mips.Count == 0) return null;

        int index = mip >= 0 && mip < texture.Mips.Count ? mip : ChooseMip(texture);
        var chosen = texture.Mips[index];

        byte[] rgba = BlockCompression.Decode(texture.Format, chosen.Data, chosen.Width, chosen.Height);
        return new PreviewImage(chosen.Width, chosen.Height, rgba);
    }

    private static int ChooseMip(BioShockTexture texture)
    {
        for (int i = 0; i < texture.Mips.Count; i++)
        {
            var mip = texture.Mips[i];
            if (Math.Max(mip.Width, mip.Height) <= PreferredMaximumSize) return i;
        }
        // Every mip is large, so the smallest is the best available choice.
        return texture.Mips.Count - 1;
    }

    private BioShockTexture? Read(BioShockPackage package, CatalogEntry entry)
    {
        var export = entry.ExportIndex >= 0 && entry.ExportIndex < package.Exports.Count
            ? package.Exports[entry.ExportIndex]
            : package.Exports
                .Where(e => e.ObjectName == entry.ObjectName && package.GetClassName(e) == TextureReader.ClassName)
                .MaxBy(e => e.SerialSize);

        if (export is null) return null;

        try { return TextureReader.Read(package, export, catalog.Bulk); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }
    }
}
