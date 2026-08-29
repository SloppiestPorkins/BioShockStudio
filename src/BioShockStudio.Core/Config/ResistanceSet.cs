namespace BioShockStudio.Core.Config;

/// <summary>
/// One damage-resistance set — a per-stimulus multiplier table. An <c>AIArchetype</c> (or
/// <c>ShockPawn</c>) names one through <c>DamageResistanceSetName</c>; the sets themselves are
/// <c>[&lt;name&gt;ResistanceSet]</c> sections in <c>Weapons.ini</c> (inside <c>ConfigINI.IBF</c>).
/// </summary>
/// <param name="Amount">Damage/state multiplier for this stimulus — 1.0 neutral, 0.0 immune, &gt;1 vulnerable.</param>
/// <param name="Chance">Multiplier on the chance the stimulus applies at all.</param>
public readonly record struct StimulusResistance(float Amount, float Chance);

/// <summary>The 88 resistance sets in <c>Weapons.ini</c>, each 27 stimulus modifiers.</summary>
public sealed class ResistanceSet
{
    private readonly Dictionary<string, StimulusResistance> _byStimulus;

    private ResistanceSet(string name, Dictionary<string, StimulusResistance> byStimulus)
    {
        Name = name;
        _byStimulus = byStimulus;
    }

    public string Name { get; }

    /// <summary>Every stimulus this set names, with its modifiers. Keys are <c>STIMULUS_*</c>.</summary>
    public IReadOnlyDictionary<string, StimulusResistance> Modifiers => _byStimulus;

    /// <summary>The modifier for one stimulus, or the neutral <c>(1, 1)</c> if the set does not name it.</summary>
    public StimulusResistance For(string stimulus) =>
        _byStimulus.TryGetValue(stimulus, out var r) ? r : new StimulusResistance(1f, 1f);

    /// <summary>True when every modifier is neutral — the set changes nothing.</summary>
    public bool IsNeutral => _byStimulus.Values.All(r => r is { Amount: 1f, Chance: 1f });

    /// <summary>
    /// All <c>[*ResistanceSet]</c> sections in a <c>Weapons.ini</c> document, keyed by set name
    /// (case-insensitive) with the <c>ResistanceSet</c> suffix kept — that is how archetypes name it.
    /// </summary>
    public static IReadOnlyDictionary<string, ResistanceSet> ReadAll(IniDocument weaponsIni)
    {
        var result = new Dictionary<string, ResistanceSet>(StringComparer.OrdinalIgnoreCase);

        foreach (var section in weaponsIni.Sections)
        {
            if (!section.Name.EndsWith("ResistanceSet", StringComparison.OrdinalIgnoreCase)) continue;

            var byStimulus = new Dictionary<string, StimulusResistance>(StringComparer.OrdinalIgnoreCase);
            foreach (string literal in section.Values("Resistance"))
            {
                var fields = IniSection.ParseStruct(literal);
                string? type = null;
                float amount = 1f, chance = 1f;
                foreach (var (key, value) in fields)
                {
                    if (key.Equals("Type", StringComparison.OrdinalIgnoreCase)) type = value;
                    else if (key.Equals("AmountModification", StringComparison.OrdinalIgnoreCase))
                        float.TryParse(value, System.Globalization.CultureInfo.InvariantCulture, out amount);
                    else if (key.Equals("ChanceModification", StringComparison.OrdinalIgnoreCase))
                        float.TryParse(value, System.Globalization.CultureInfo.InvariantCulture, out chance);
                }
                if (type is not null) byStimulus[type] = new StimulusResistance(amount, chance);
            }

            result[section.Name] = new ResistanceSet(section.Name, byStimulus);
        }

        return result;
    }
}
