namespace BioShockStudio.Core.Config;

/// <summary>
/// A parsed Unreal-style <c>.ini</c>: ordered sections, each an ordered list of <c>key=value</c>
/// entries. Keys repeat (UE arrays are written as one <c>Key=</c> line per element), so entries are
/// a list, not a map.
/// </summary>
public sealed class IniDocument
{
    private readonly List<IniSection> _sections;

    private IniDocument(List<IniSection> sections) => _sections = sections;

    public IReadOnlyList<IniSection> Sections => _sections;

    /// <summary>The first section with this name (case-insensitive), or null.</summary>
    public IniSection? this[string name] =>
        _sections.FirstOrDefault(s => string.Equals(s.Name, name, StringComparison.OrdinalIgnoreCase));

    public static IniDocument Parse(string text)
    {
        var sections = new List<IniSection>();
        List<(string Key, string Value)>? current = null;
        string currentName = "";

        foreach (string raw in text.Split('\n'))
        {
            string line = raw.Trim();
            if (line.Length == 0 || line[0] is ';' or '#') continue;

            if (line[0] == '[' && line[^1] == ']')
            {
                if (current is not null) sections.Add(new IniSection(currentName, current));
                currentName = line[1..^1].Trim();
                current = [];
                continue;
            }

            int eq = line.IndexOf('=');
            if (eq <= 0 || current is null) continue;
            current.Add((line[..eq].Trim(), line[(eq + 1)..].Trim()));
        }

        if (current is not null) sections.Add(new IniSection(currentName, current));
        return new IniDocument(sections);
    }
}

/// <summary>One <c>[Section]</c> and its ordered entries.</summary>
public sealed class IniSection(string name, IReadOnlyList<(string Key, string Value)> entries)
{
    public string Name { get; } = name;

    public IReadOnlyList<(string Key, string Value)> Entries { get; } = entries;

    /// <summary>The last value for a key (UE's "last write wins" for scalars), or null.</summary>
    public string? Value(string key)
    {
        string? found = null;
        foreach (var (k, v) in Entries)
            if (string.Equals(k, key, StringComparison.OrdinalIgnoreCase)) found = v;
        return found;
    }

    /// <summary>Every value for a key, in order — for UE array properties.</summary>
    public IEnumerable<string> Values(string key) =>
        Entries.Where(e => string.Equals(e.Key, key, StringComparison.OrdinalIgnoreCase)).Select(e => e.Value);

    public float? Float(string key) =>
        float.TryParse(Value(key), System.Globalization.CultureInfo.InvariantCulture, out float f) ? f : null;

    public bool? Bool(string key) => Value(key) is { } v
        ? v.Equals("true", StringComparison.OrdinalIgnoreCase) || v == "1"
        : null;

    /// <summary>
    /// Parses a UE struct literal — <c>(Type=STIMULUS_Heat,AmountModification=3.0)</c> — into its
    /// key/value pairs. Nested parens and quoted strings are kept whole.
    /// </summary>
    public static IReadOnlyList<(string Key, string Value)> ParseStruct(string literal)
    {
        var result = new List<(string, string)>();
        string s = literal.Trim();
        if (s.StartsWith('(') && s.EndsWith(')')) s = s[1..^1];

        int depth = 0, start = 0;
        bool quote = false;
        for (int i = 0; i < s.Length; i++)
        {
            char c = s[i];
            if (c == '"') quote = !quote;
            else if (!quote && c == '(') depth++;
            else if (!quote && c == ')') depth--;
            else if (!quote && depth == 0 && c == ',')
            {
                AddPair(s[start..i]);
                start = i + 1;
            }
        }
        AddPair(s[start..]);
        return result;

        void AddPair(string part)
        {
            int eq = part.IndexOf('=');
            if (eq > 0) result.Add((part[..eq].Trim(), part[(eq + 1)..].Trim()));
        }
    }
}
