using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Assets;

/// <summary>
/// One AI archetype: the data record a spawner or an <c>ActionSpawnAI</c> names to say <i>which</i>
/// enemy to place — its behaviour class, mesh, health and loadout.
/// </summary>
/// <remarks>
/// <para>
/// <b>What resolves the archetype-name gap.</b> <c>Spawner.OverriddenAiArchetypeNames</c>,
/// <c>ActionSpawnAI.OverriddenAIArchetypeNames</c> and the character-name-shaped
/// <c>TriggerOnlyByLabels</c> entries (<c>Steinman</c>, <c>Cohen</c>, …) resolved against no
/// placed-actor field and were `UNKNOWN`. They are <c>AIArchetype</c> object names.
/// <c>SpawningManager.uc</c>'s <c>defaultproperties</c> lists all 313 by name; each map ships the
/// subset it uses as real <c>AIArchetype</c> exports (267 across the 21 maps), outer'd to the map's
/// <c>SpawningManager</c>. <c>AIArchetype</c> is <c>extends Object native config(Spawning)
/// perobjectconfig</c> — a plain tagged-property list.
/// </para>
/// <para>
/// See <c>docs/research/spawning.md</c>. This reader carries its <b>own</b> property walk rather
/// than <c>UnrealPropertyReader</c>'s, because the loadout slots (<c>MaterialSlot</c>,
/// <c>AttachmentSlot1..4</c>, <c>WeaponSlot1..4</c>) are <c>array&lt;struct&gt;</c> whose element
/// property lists the array tag under-sizes — the same shortfall
/// <c>UnrealPropertyReader.CorrectedStructSize</c> handles one level down, but correcting it in the
/// shared reader shifts pinned diagnostic/emitter figures and needs its own classification pass
/// (ENGINEERING_RULES §24). Scoped here for now; the slot arrays are only ever seen on archetypes.
/// </para>
/// </remarks>
public sealed record AiArchetype
{
    /// <summary>The archetype's own name — the key a spawner or script uses to select it.</summary>
    public required string Name { get; init; }

    public required string PackageName { get; init; }

    /// <summary><c>AIType</c> — the <c>Class&lt;ShockAI&gt;</c> that runs the behaviour. Resolved name.</summary>
    public string? AiType { get; init; }

    /// <summary><c>Mesh</c> — the <c>SkeletalMesh</c> the archetype wears. Resolved name.</summary>
    public string? Mesh { get; init; }

    public float? Health { get; init; }
    public float? FrozenHealth { get; init; }
    public float? CollisionHeight { get; init; }

    public string? DamageResistanceSetName { get; init; }

    public bool? ShouldGoRagdollOnDeath { get; init; }
    public bool? ShouldBeHarvested { get; init; }
    public bool? CanRunAway { get; init; }
    public bool? CannotBeShattered { get; init; }

    /// <summary>Elemental efficacy caps — how far burning / frozen / shocked can progress (0–100).</summary>
    public float? MaxBurningEfficacy { get; init; }
    public float? MaxFrozenEfficacy { get; init; }
    public float? MaxShockedEfficacy { get; init; }

    public float? BurningTimeout { get; init; }
    public float? FrozenHealthDecayPerSecond { get; init; }
    public float? ShatteredDamageAmount { get; init; }

    /// <summary>Set on the enemies scripted not to catch fire (e.g. grenadiers holding live grenades).</summary>
    public bool? DoNotDoBurningBehavior { get; init; }

    public required IReadOnlyList<string> RequiredAnimationGroups { get; init; }
    public required IReadOnlyList<string> VoiceTypes { get; init; }

    /// <summary>
    /// <c>MaterialSlot</c> — skin variants, each with the chance it is picked. The material name
    /// resolves against the package; <c>null</c> is an authored-empty slot.
    /// </summary>
    public required IReadOnlyList<ArchetypeChance> MaterialSlots { get; init; }

    /// <summary><c>AttachmentSlot1..4</c> flattened — masks, held props, and their chances.</summary>
    public required IReadOnlyList<ArchetypeChance> AttachmentSlots { get; init; }

    /// <summary>
    /// <c>WeaponSlot1..4</c> flattened — a weapon swap replaces <see cref="ArchetypeChance.Name"/>
    /// with <see cref="ArchetypeChance.Replacement"/> at the given chance.
    /// </summary>
    public required IReadOnlyList<ArchetypeChance> WeaponSlots { get; init; }

    /// <summary>Entries in the <c>MaterialSlot</c> chance array.</summary>
    public int MaterialSlotEntries => MaterialSlots.Count;

    /// <summary>Entries across <c>AttachmentSlot1..4</c>.</summary>
    public int AttachmentSlotEntries => AttachmentSlots.Count;

    /// <summary>Entries across <c>WeaponSlot1..4</c>.</summary>
    public int WeaponSlotEntries => WeaponSlots.Count;

    /// <summary>The property list ended on a clean terminator — nothing after it is invented.</summary>
    public required bool Complete { get; init; }

    public override string ToString() =>
        $"{Name}"
        + (AiType is { } t ? $" [{t}]" : "")
        + (Mesh is { } m ? $" {m}" : "")
        + (Health is { } h ? $" hp{h:0}" : "");
}

/// <summary>One chance-weighted slot entry: a material, attachment or weapon and how likely it is.</summary>
/// <param name="Name">Resolved object name, or null for an authored-empty slot.</param>
/// <param name="Chance">The authored chance (0–100).</param>
/// <param name="Replacement">For a weapon slot, what <paramref name="Name"/> is swapped to; null otherwise.</param>
public readonly record struct ArchetypeChance(string? Name, float Chance, string? Replacement = null);

/// <summary>Reads every <c>AIArchetype</c> export in a package.</summary>
public static class AiArchetypeCatalog
{
    private const string ArchetypeClass = "AIArchetype";
    private const int PropertyOffset = 8;

    private static readonly string[] AttachmentSlots =
        ["AttachmentSlot1", "AttachmentSlot2", "AttachmentSlot3", "AttachmentSlot4"];

    private static readonly string[] WeaponSlots =
        ["WeaponSlot1", "WeaponSlot2", "WeaponSlot3", "WeaponSlot4"];

    public static IReadOnlyList<AiArchetype> Read(BioShockPackage package)
    {
        string packageName = Path.GetFileNameWithoutExtension(package.FilePath);
        var result = new List<AiArchetype>();

        foreach (var export in package.Exports)
        {
            if (package.GetClassName(export) != ArchetypeClass || export.SerialSize <= 0) continue;

            List<UnrealProperty> properties;
            bool complete;
            try
            {
                (properties, complete) = Walk(package.ReadExportData(export), package.Names);
            }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
            {
                result.Add(Unreadable(export.ObjectName, packageName));
                continue;
            }

            UnrealProperty? Find(string name) => properties.FirstOrDefault(p => p.Name == name);
            float? Float(string name) => Find(name) is { Type: UnrealPropertyType.Float } p ? p.AsFloat() : null;
            bool? Bool(string name) => Find(name) is { Type: UnrealPropertyType.Bool } p ? p.BoolValue : null;
            string? Name(string name) => Find(name) is { Type: UnrealPropertyType.Name } p ? PropertyValues.AsName(p, package) : null;
            string? Ref(string name) =>
                Find(name) is { Type: UnrealPropertyType.Object or UnrealPropertyType.Class } p
                && PropertyValues.AsReference(p) is { } index && !index.IsNull
                    ? package.ResolveName(index)
                    : null;
            IReadOnlyList<string> Names(string name) =>
                Find(name) is { Type: UnrealPropertyType.Array } p
                && PropertyValues.TryAsNameArrayExact(p, package, out var values) ? values : [];

            // Each slot element is a nested { <ref>, float Chance, None? } list. The re-measured
            // walk above captures the slot's full value, so TryAsStructArrayExact walks it exactly.
            List<ArchetypeChance> Slots(string refField, params string[] slotNames)
            {
                var rows = new List<ArchetypeChance>();
                foreach (var name in slotNames)
                {
                    if (Find(name) is not { Type: UnrealPropertyType.Array } p) continue;
                    if (!PropertyValues.TryAsStructArrayExact(p, package, out var elements)) continue;
                    foreach (var fields in elements)
                    {
                        string? Resolve(string f) =>
                            fields.FirstOrDefault(x => x.Name == f) is { } fp
                            && PropertyValues.AsReference(fp) is { } idx && !idx.IsNull
                                ? package.ResolveName(idx)
                                : null;
                        float chance = fields.FirstOrDefault(x => x.Name == "Chance") is { Type: UnrealPropertyType.Float } cp
                            ? cp.AsFloat() : 0f;
                        rows.Add(new ArchetypeChance(Resolve(refField), chance,
                            refField == "CurrentAIWeaponClass" ? Resolve("ReplacementAIWeaponClass") : null));
                    }
                }
                return rows;
            }

            result.Add(new AiArchetype
            {
                Name = export.ObjectName,
                PackageName = packageName,
                AiType = Ref("AIType"),
                Mesh = Ref("Mesh"),
                Health = Float("Health"),
                FrozenHealth = Float("FrozenHealth"),
                CollisionHeight = Float("CollisionHeight"),
                DamageResistanceSetName = Name("DamageResistanceSetName"),
                ShouldGoRagdollOnDeath = Bool("bShouldGoRagdollOnDeath"),
                ShouldBeHarvested = Bool("bShouldBeHarvested"),
                CanRunAway = Bool("bCanRunAway"),
                CannotBeShattered = Bool("bCannotBeShattered"),
                MaxBurningEfficacy = Float("MaxBurningEfficacy"),
                MaxFrozenEfficacy = Float("MaxFrozenEfficacy"),
                MaxShockedEfficacy = Float("MaxShockedEfficacy"),
                BurningTimeout = Float("BurningTimeout"),
                FrozenHealthDecayPerSecond = Float("FrozenHealthDecayPerSecond"),
                ShatteredDamageAmount = Float("ShatteredDamageAmount"),
                DoNotDoBurningBehavior = Bool("bDoNotDoBurningBehavior"),
                RequiredAnimationGroups = Names("RequiredAnimationGroups"),
                VoiceTypes = Names("VoiceTypes"),
                MaterialSlots = Slots("AIMaterial", "MaterialSlot"),
                AttachmentSlots = Slots("AIAttachmentClass", AttachmentSlots),
                WeaponSlots = Slots("CurrentAIWeaponClass", WeaponSlots),
                Complete = complete,
            });
        }

        return result;
    }

    /// <summary>
    /// A tagged-property walk that re-measures an <c>array&lt;struct&gt;</c> by walking its nested
    /// element property lists, rather than trusting the array tag's declared size. Only overrides
    /// the declared size when it is demonstrably wrong (the bytes at its end are not a property
    /// tag) and every element walks cleanly to a bare <c>None</c>. Flat arrays — names, ints, refs —
    /// fail the "first element is a property list" test and keep their declared size.
    /// </summary>
    private static (List<UnrealProperty> Properties, bool Complete) Walk(byte[] p, IReadOnlyList<NameEntry> names)
    {
        var result = new List<UnrealProperty>();
        int offset = PropertyOffset;

        for (int guard = 0; guard < 4096; guard++)
        {
            if (offset + 5 > p.Length) return (result, false);

            int nameIndex = ReadCompact(p, ref offset);
            int nameNumber = ReadI32(p, ref offset);
            if (nameIndex < 0 || nameIndex >= names.Count) return (result, false);
            if (names[nameIndex].Name == "None") return (result, nameNumber == 0);

            // FName numbering: a disambiguating number turns "AttachmentSlot"+2 into "AttachmentSlot1".
            string propertyName = nameNumber == 0
                ? names[nameIndex].Name
                : names[nameIndex].Name + (nameNumber - 1);

            byte info = p[offset++];
            var type = (UnrealPropertyType)(info & 0x0F);
            int sizeEncoding = (info >> 4) & 0x07;
            bool isArray = (info & 0x80) != 0;

            string? structName = null;
            if (type == UnrealPropertyType.Struct)
            {
                int sIdx = ReadCompact(p, ref offset);
                ReadI32(p, ref offset);
                structName = sIdx >= 0 && sIdx < names.Count ? names[sIdx].Name : null;
            }

            int size = sizeEncoding switch
            {
                0 => 1, 1 => 2, 2 => 4, 3 => 12, 4 => 16,
                5 => p[offset++],
                6 => ReadU16(p, ref offset),
                _ => ReadI32(p, ref offset),
            };

            if (isArray && type != UnrealPropertyType.Bool) ReadCompact(p, ref offset);

            if (type == UnrealPropertyType.Array
                && TryMeasureStructArray(p, offset, size, names, out int measured))
                size = measured;

            if (size < 0 || offset + size > p.Length) return (result, false);

            result.Add(new UnrealProperty
            {
                Name = propertyName,
                Type = type,
                StructName = structName,
                ArrayIndex = 0,
                Value = p[offset..(offset + size)],
                BoolValue = type == UnrealPropertyType.Bool && isArray,
            });
            offset += size;
        }

        return (result, false);
    }

    private static bool TryMeasureStructArray(
        byte[] p, int start, int declared, IReadOnlyList<NameEntry> names, out int span)
    {
        span = 0;
        if (declared < 0 || start + declared > p.Length) return false;

        int offset = start;
        int count;
        try { count = ReadCompact(p, ref offset); }
        catch { return false; }
        if (count <= 0 || count > 4096) return false;

        int sizeBytes = 0;
        for (int i = 0; i < count; i++)
        {
            if (!TrySkipNestedList(p, ref offset, names, ref sizeBytes)) return false;
        }

        int measured = offset - start;
        if (start + measured > p.Length) return false;

        // Exactly the shortfall the rule predicts — the declared size omits its elements' own
        // size-encoding bytes — or leave it. This is the same non-heuristic test
        // UnrealPropertyReader.CorrectedStructSize applies one level down.
        if (measured == declared) { span = declared; return false; }
        if (measured != declared + sizeBytes || sizeBytes == 0) return false;

        span = measured;
        return true;
    }

    private static bool TrySkipNestedList(
        byte[] p, ref int offset, IReadOnlyList<NameEntry> names, ref int sizeBytes)
    {
        for (int guard = 0; guard < 64; guard++)
        {
            if (offset + 5 > p.Length) return false;

            int nameIndex, nameNumber;
            try { nameIndex = ReadCompact(p, ref offset); nameNumber = ReadI32(p, ref offset); }
            catch { return false; }
            if (nameIndex < 0 || nameIndex >= names.Count) return false;
            if (names[nameIndex].Name == "None") return nameNumber == 0;

            if (offset >= p.Length) return false;
            byte info = p[offset++];
            var type = (UnrealPropertyType)(info & 0x0F);
            int sizeEncoding = (info >> 4) & 0x07;

            if (type == UnrealPropertyType.Struct)
            {
                try { ReadCompact(p, ref offset); ReadI32(p, ref offset); } catch { return false; }
            }

            int size;
            try
            {
                size = sizeEncoding switch
                {
                    0 => 1, 1 => 2, 2 => 4, 3 => 12, 4 => 16,
                    5 => Tally(p[offset++], ref sizeBytes, 1),
                    6 => Tally(ReadU16(p, ref offset), ref sizeBytes, 2),
                    _ => Tally(ReadI32(p, ref offset), ref sizeBytes, 4),
                };
            }
            catch { return false; }

            if ((info & 0x80) != 0 && type != UnrealPropertyType.Bool)
            {
                try { ReadCompact(p, ref offset); } catch { return false; }
            }

            if (size < 0 || offset + size > p.Length) return false;
            offset += size;
        }
        return false;

        static int Tally(int value, ref int bytes, int width)
        {
            bytes += width;
            return value;
        }
    }

    private static int ReadCompact(byte[] d, ref int offset)
    {
        byte b = d[offset++];
        bool negative = (b & 0x80) != 0;
        int value = b & 0x3F;
        if ((b & 0x40) != 0)
        {
            int shift = 6;
            while (true)
            {
                byte c = d[offset++];
                value |= (c & 0x7F) << shift;
                shift += 7;
                if ((c & 0x80) == 0) break;
                if (shift > 31) throw new InvalidDataException("FCompactIndex overflow.");
            }
        }
        return negative ? -value : value;
    }

    private static int ReadI32(byte[] d, ref int offset)
    {
        int v = d[offset] | (d[offset + 1] << 8) | (d[offset + 2] << 16) | (d[offset + 3] << 24);
        offset += 4;
        return v;
    }

    private static ushort ReadU16(byte[] d, ref int offset)
    {
        ushort v = (ushort)(d[offset] | (d[offset + 1] << 8));
        offset += 2;
        return v;
    }

    private static AiArchetype Unreadable(string name, string packageName) => new()
    {
        Name = name,
        PackageName = packageName,
        RequiredAnimationGroups = [],
        VoiceTypes = [],
        MaterialSlots = [],
        AttachmentSlots = [],
        WeaponSlots = [],
        Complete = false,
    };
}
