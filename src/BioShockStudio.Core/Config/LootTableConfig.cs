namespace BioShockStudio.Core.Config;

/// <summary>
/// One entry in a loot table: at <see cref="Chance"/> percent, either drop <see cref="ItemClass"/>
/// (a stack between <see cref="MinStackSize"/> and <see cref="MaxStackSize"/>) or roll the nested
/// <see cref="SubTable"/>.
/// </summary>
public readonly record struct LootSpec(
    float Chance, string? ItemClass, int MinStackSize, int MaxStackSize, string? SubTable);

/// <summary>A named loot table — the ordered chance entries a container or corpse rolls.</summary>
public sealed record LootTable(string Name, IReadOnlyList<LootSpec> Specs);

/// <summary>
/// The loot tables from <c>LootTables.ini</c> (inside <c>ConfigINI.IBF</c>). What every container,
/// corpse and lootable object can drop. Tables reference sub-tables, so a drop is a tree roll. See
/// <c>docs/research/config.md</c>.
/// </summary>
public static class LootTableConfig
{
    public static IReadOnlyDictionary<string, LootTable> ReadAll(IniDocument lootIni)
    {
        var result = new Dictionary<string, LootTable>(StringComparer.OrdinalIgnoreCase);

        foreach (var section in lootIni.Sections)
        {
            var specs = new List<LootSpec>();
            foreach (string literal in section.Values("LootSpec"))
            {
                var f = IniSection.ParseStruct(literal);
                string? Field(string k) =>
                    f.FirstOrDefault(p => p.Key.Equals(k, StringComparison.OrdinalIgnoreCase)) is { Value.Length: > 0 } p
                        ? p.Value : null;
                int IntField(string k, int fallback) => int.TryParse(Field(k), out int v) ? v : fallback;
                float chance = float.TryParse(Field("Chance"), System.Globalization.CultureInfo.InvariantCulture, out float c) ? c : 0f;

                specs.Add(new LootSpec(
                    chance,
                    Unqualify(Field("ItemClass")),
                    IntField("MinStackSize", 1),
                    IntField("MaxStackSize", 1),
                    Field("TableName")));
            }

            if (specs.Count > 0) result[section.Name] = new LootTable(section.Name, specs);
        }

        return result;
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
