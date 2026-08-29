namespace BioShockStudio.Core.Config;

/// <summary>
/// One plasmid or tonic's shop/progression metadata from <c>Plasmids.ini</c> (in
/// <c>ConfigINI.IBF</c>). The <b>effect</b> numbers — bolt damage, burn duration, EVE cost — live
/// in the decompiled <c>ShockGame.&lt;name&gt;</c> class defaults, not here.
/// </summary>
public sealed record PlasmidInfo
{
    public required string Name { get; init; }
    public string? FriendlyName { get; init; }
    public string? Description { get; init; }

    /// <summary><c>TRACK_Active</c> (a plasmid you cast) or <c>TRACK_Passive</c> (a gene tonic).</summary>
    public string? Track { get; init; }

    public string? Color { get; init; }
    public float? CreditValue { get; init; }
    public bool? MandatoryEquip { get; init; }

    /// <summary>The plasmid this one upgrades (<c>PlasmidPrerequisite</c>), for the 3-tier chains.</summary>
    public string? UpgradeOf { get; init; }

    /// <summary>The four DNA-track prerequisite counts, <c>Prereqs[1..4]</c>.</summary>
    public required int[] Prereqs { get; init; }
}

/// <summary>Reads the plasmid / tonic roster from <c>Plasmids.ini</c>.</summary>
public static class PlasmidConfig
{
    public static IReadOnlyList<PlasmidInfo> ReadAll(IniDocument plasmidsIni)
    {
        var result = new List<PlasmidInfo>();

        foreach (var section in plasmidsIni.Sections)
        {
            if (section.Value("Track") is null) continue;

            result.Add(new PlasmidInfo
            {
                Name = Bare(section.Name),
                FriendlyName = section.Value("FriendlyName"),
                Description = section.Value("Description"),
                Track = section.Value("Track"),
                Color = section.Value("Color"),
                CreditValue = section.Float("CreditValue"),
                MandatoryEquip = section.Bool("MandatoryEquip"),
                UpgradeOf = Unqualify(section.Value("PlasmidPrerequisite")),
                Prereqs =
                [
                    IntKey(section, "Prereqs[1]"), IntKey(section, "Prereqs[2]"),
                    IntKey(section, "Prereqs[3]"), IntKey(section, "Prereqs[4]"),
                ],
            });
        }

        return result;
    }

    private static int IntKey(IniSection s, string key) => int.TryParse(s.Value(key), out int v) ? v : 0;

    private static string Bare(string section)
    {
        int dot = section.IndexOf('.');
        return dot >= 0 ? section[(dot + 1)..] : section;
    }

    private static string? Unqualify(string? reference)
    {
        if (string.IsNullOrWhiteSpace(reference)) return null;
        string s = reference.Trim();
        int quote = s.IndexOf('\'');
        if (quote >= 0 && s.EndsWith('\'')) s = s[(quote + 1)..^1];
        int dot = s.LastIndexOf('.');
        return dot >= 0 ? s[(dot + 1)..] : s;
    }
}
