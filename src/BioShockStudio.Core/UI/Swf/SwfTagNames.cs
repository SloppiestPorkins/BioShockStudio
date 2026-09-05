namespace BioShockStudio.Core.UI.Swf;

/// <summary>
/// Human-readable names for SWF / Scaleform tag codes used by <c>swf-inspect</c> and tests.
/// Unknown codes stay as <c>Unknown(N)</c>.
/// </summary>
public static class SwfTagNames
{
    public static string Get(int code) => code switch
    {
        2 => "DefineShape",
        6 => "DefineBits",
        8 => "JPEGTables",
        9 => "SetBackgroundColor",
        10 => "DefineFont",
        11 => "DefineText",
        12 => "DoAction",
        20 => "DefineBitsLossless",
        21 => "DefineBitsJPEG2",
        22 => "DefineShape2",
        26 => "PlaceObject2",
        32 => "DefineShape3",
        33 => "DefineText2",
        34 => "DefineButton2",
        35 => "DefineBitsJPEG3",
        36 => "DefineBitsLossless2",
        37 => "DefineEditText",
        39 => "DefineSprite",
        48 => "DefineFont2",
        56 => "ExportAssets",
        57 => "ImportAssets",
        70 => "PlaceObject3",
        75 => "DefineFont3",
        78 => "DefineScalingGrid",
        82 => "DoABC",
        83 => "DefineShape4",
        88 => "DefineFontName",
        SwfBitmapReader.TagCode => "DefineBitsDxt",
        _ => $"Unknown({code})",
    };
}
