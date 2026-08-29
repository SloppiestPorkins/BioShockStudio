using BioShockStudio.Core.Assets;

namespace BioShockStudio.Core.Config;

/// <summary>
/// Every AI archetype from <c>Spawning.ini</c> (inside <c>ConfigINI.IBF</c>) — all 313, including
/// the ~46 that no map ships as a package export.
/// </summary>
/// <remarks>
/// The 267 that <b>do</b> ship as exports are decoded byte-exact by <see cref="AiArchetypeCatalog"/>
/// and validate against these ini sections (<c>IniBundleTests</c>). This reader is the fallback for
/// the rest and the single source when no package is in hand. Field names in the ini match the
/// export property names exactly (`AIType`, `Mesh`, `Health`, `MaterialSlot`, `AttachmentSlot1..4`,
/// `MaxBurningEfficacy`, `bDoNotDoBurningBehavior`, …). See <c>docs/research/config.md</c>.
/// </remarks>
public static class AiArchetypeConfig
{
    private static readonly string[] AttachmentSlots =
        ["AttachmentSlot1", "AttachmentSlot2", "AttachmentSlot3", "AttachmentSlot4"];

    private static readonly string[] WeaponSlots =
        ["WeaponSlot1", "WeaponSlot2", "WeaponSlot3", "WeaponSlot4"];

    /// <summary>An <c>[X]</c> section is an archetype when it names an <c>AIType</c>.</summary>
    public static IReadOnlyList<AiArchetype> Read(IniDocument spawningIni)
    {
        var result = new List<AiArchetype>();

        foreach (var section in spawningIni.Sections)
        {
            if (section.Value("AIType") is null) continue;

            List<ArchetypeChance> Slots(string refKey, IEnumerable<string> keys)
            {
                var rows = new List<ArchetypeChance>();
                foreach (string key in keys)
                    foreach (string literal in section.Values(key))
                    {
                        var f = IniSection.ParseStruct(literal);
                        string? Field(string k) =>
                            f.FirstOrDefault(p => p.Key.Equals(k, StringComparison.OrdinalIgnoreCase)) is { Value.Length: > 0 } p
                                ? Unqualify(p.Value) : null;
                        float chance = f.FirstOrDefault(p => p.Key.Equals("Chance", StringComparison.OrdinalIgnoreCase)) is { } c
                            && float.TryParse(c.Value, System.Globalization.CultureInfo.InvariantCulture, out float v) ? v : 0f;
                        string? name = Field(refKey);
                        rows.Add(new ArchetypeChance(
                            string.Equals(name, "None", StringComparison.OrdinalIgnoreCase) ? null : name,
                            chance,
                            refKey == "CurrentAIWeaponClass" ? Field("ReplacementAIWeaponClass") : null));
                    }
                return rows;
            }

            result.Add(new AiArchetype
            {
                Name = section.Name,
                PackageName = "Spawning.ini",
                AiType = Unqualify(section.Value("AIType")),
                Mesh = Unqualify(section.Value("Mesh")),
                Health = section.Float("Health"),
                FrozenHealth = section.Float("FrozenHealth"),
                CollisionHeight = section.Float("CollisionHeight"),
                DamageResistanceSetName = section.Value("DamageResistanceSetName"),
                ShouldGoRagdollOnDeath = section.Bool("bShouldGoRagdollOnDeath"),
                ShouldBeHarvested = section.Bool("bShouldBeHarvested"),
                CanRunAway = section.Bool("bCanRunAway"),
                CannotBeShattered = section.Bool("bCannotBeShattered"),
                MaxBurningEfficacy = section.Float("MaxBurningEfficacy"),
                MaxFrozenEfficacy = section.Float("MaxFrozenEfficacy"),
                MaxShockedEfficacy = section.Float("MaxShockedEfficacy"),
                BurningTimeout = section.Float("BurningTimeout"),
                FrozenHealthDecayPerSecond = section.Float("FrozenHealthDecayPerSecond"),
                ShatteredDamageAmount = section.Float("ShatteredDamageAmount"),
                DoNotDoBurningBehavior = section.Bool("bDoNotDoBurningBehavior"),
                RequiredAnimationGroups = [.. section.Values("RequiredAnimationGroups")],
                VoiceTypes = [.. section.Values("VoiceTypes")],
                MaterialSlots = Slots("AIMaterial", ["MaterialSlot"]),
                AttachmentSlots = Slots("AIAttachmentClass", AttachmentSlots),
                WeaponSlots = Slots("CurrentAIWeaponClass", WeaponSlots),
                Complete = true,
            });
        }

        return result;
    }

    /// <summary>
    /// <c>class'ShockAIClasses.SpawnedMeleeThug'</c> or <c>SkeletalMesh'Group.Object'</c> → the bare
    /// object name (<c>SpawnedMeleeThug</c>, <c>Object</c>), matching the package-export decode.
    /// </summary>
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
