namespace BioShockStudio.Core.Config;

/// <summary>One damage stimulus a hit applies — the base number, before the target's resistance set.</summary>
public readonly record struct DamageStimulus(string Type, float Amount, float Chance);

/// <summary>
/// One ammo type: its damage (via a <c>[*StimuliSet]</c> section), stack size and value.
/// </summary>
public sealed record AmmoInfo
{
    public required string Name { get; init; }
    public string? FriendlyName { get; init; }
    public string? DamageStimuliSetName { get; init; }
    public int? MaximumStackSize { get; init; }
    public float? CreditValue { get; init; }
    public int? RoundsPerShot { get; init; }
    public int? BurstShots { get; init; }

    /// <summary>The stimuli the <see cref="DamageStimuliSetName"/> set applies, resolved.</summary>
    public required IReadOnlyList<DamageStimulus> Damage { get; init; }
}

/// <summary>One player weapon: firing stats plus its ammo types with damage resolved.</summary>
public sealed record WeaponInfo
{
    public required string Name { get; init; }
    public string? FriendlyName { get; init; }
    public string? Model { get; init; }
    public int? BaseMagazineSize { get; init; }
    public float? BaseAccuracy { get; init; }
    public float? BaseFireRate { get; init; }
    public float? BaseReloadRate { get; init; }
    public bool? CanBeZoomed { get; init; }
    public required IReadOnlyList<AmmoInfo> Ammo { get; init; }
}

/// <summary>Reads the player weapons and their ammo/damage from <c>Weapons.ini</c> (in <c>ConfigINI.IBF</c>).</summary>
/// <remarks>
/// The damage chain: <c>[ShockGame.&lt;Weapon&gt;]</c> lists <c>AvailableAmmoTypes</c> →
/// <c>[ShockGame.&lt;Ammo&gt;]</c> names a <c>DamageStimuliSetName</c> →
/// <c>[&lt;name&gt;StimuliSet]</c> carries one <c>Stimulus=(Type=,Amount=,Chance=)</c> line per
/// stimulus. Final damage to an AI is <c>stimulus.Amount ×</c> that archetype's
/// <see cref="ResistanceSet"/> modifier for the same <c>Type</c>. See <c>docs/research/config.md</c>.
/// </remarks>
public static class WeaponConfig
{
    private static readonly string[] WeaponSectionPrefixes = ["ShockGame."];

    public static IReadOnlyList<WeaponInfo> ReadAll(IniDocument weaponsIni)
    {
        var ammoByName = new Dictionary<string, IniSection>(StringComparer.OrdinalIgnoreCase);
        var stimuliByName = new Dictionary<string, IniSection>(StringComparer.OrdinalIgnoreCase);
        var weaponSections = new List<IniSection>();

        foreach (var s in weaponsIni.Sections)
        {
            if (s.Name.EndsWith("StimuliSet", StringComparison.OrdinalIgnoreCase))
                stimuliByName[s.Name] = s;
            else if (s.Value("DamageStimuliSetName") is not null || s.Value("MaximumStackSize") is not null)
                ammoByName[Bare(s.Name)] = s;
            else if (s.Value("AvailableAmmoTypes") is not null && s.Value("BaseFireRate") is not null)
                weaponSections.Add(s);
        }

        var result = new List<WeaponInfo>();
        foreach (var w in weaponSections)
        {
            var ammo = new List<AmmoInfo>();
            foreach (string ammoRef in w.Values("AvailableAmmoTypes"))
            {
                if (Unqualify(ammoRef) is not { } ammoName
                    || !ammoByName.TryGetValue(Bare(ammoName), out var a)) continue;

                var damage = new List<DamageStimulus>();
                if (a.Value("DamageStimuliSetName") is { } setName
                    && stimuliByName.TryGetValue(setName, out var set))
                {
                    foreach (string literal in set.Values("Stimulus"))
                    {
                        var f = IniSection.ParseStruct(literal);
                        string? type = f.FirstOrDefault(p => p.Key.Equals("Type", StringComparison.OrdinalIgnoreCase)).Value;
                        if (type is null) continue;
                        damage.Add(new DamageStimulus(
                            type,
                            Num(f, "Amount"),
                            f.Any(p => p.Key.Equals("Chance", StringComparison.OrdinalIgnoreCase)) ? Num(f, "Chance") : 1f));
                    }
                }

                ammo.Add(new AmmoInfo
                {
                    Name = ammoName,
                    FriendlyName = a.Value("FriendlyName"),
                    DamageStimuliSetName = a.Value("DamageStimuliSetName"),
                    MaximumStackSize = Int(a, "MaximumStackSize"),
                    CreditValue = a.Float("CreditValue"),
                    RoundsPerShot = Int(a, "NumRoundsUsedPerShot"),
                    BurstShots = Int(a, "NumBurstShots"),
                    Damage = damage,
                });
            }

            result.Add(new WeaponInfo
            {
                Name = Bare(w.Name),
                FriendlyName = w.Value("FriendlyName"),
                Model = Unqualify(w.Value("WeaponModel")),
                BaseMagazineSize = Int(w, "BaseMagazineSize"),
                BaseAccuracy = w.Float("BaseAccuracy"),
                BaseFireRate = w.Float("BaseFireRate"),
                BaseReloadRate = w.Float("BaseReloadRate"),
                CanBeZoomed = w.Bool("CanBeZoomed"),
                Ammo = ammo,
            });
        }

        return result;
    }

    private static string Bare(string section)
    {
        foreach (string p in WeaponSectionPrefixes)
            if (section.StartsWith(p, StringComparison.OrdinalIgnoreCase)) return section[p.Length..];
        return section;
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

    private static int? Int(IniSection s, string key) =>
        int.TryParse(s.Value(key), out int v) ? v : null;

    private static float Num(IReadOnlyList<(string Key, string Value)> fields, string key) =>
        fields.FirstOrDefault(p => p.Key.Equals(key, StringComparison.OrdinalIgnoreCase)) is { } p
        && float.TryParse(p.Value.TrimEnd('f'), System.Globalization.CultureInfo.InvariantCulture, out float v)
            ? v : 0f;
}
