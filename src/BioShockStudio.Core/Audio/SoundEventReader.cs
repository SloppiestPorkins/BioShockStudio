using System.Buffers.Binary;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Audio;

/// <summary>
/// The game's own binding from an animation's effect event to a named sound.
/// </summary>
/// <param name="ObjectName">The response object — <c>HandsReloadPistolOne</c>.</param>
/// <param name="Event">
/// The event name it answers. This is the same string an animation's <c>AnimNotify_EffectEvent</c>
/// carries, which is what makes the link structural rather than a name resemblance.
/// </param>
/// <param name="SourceClassName">
/// The actor class the response applies to — <c>Hands</c> for the first-person rig. Event names are
/// not unique on their own, so this is what stops one actor's event resolving to another's sound.
/// </param>
/// <param name="SoundName">
/// The sound the response names, or null when the specification did not match the shape this reader
/// understands. Null means <b>unknown</b>, never "no sound".
/// </param>
public sealed record SoundEventResponse(
    string ObjectName,
    string Event,
    string SourceClassName,
    bool SpecificationPresent,
    IReadOnlyList<SoundEventSpecification> Specifications,
    byte? FilteredState,
    IReadOnlyList<int> Chances,
    IReadOnlyList<string> LevelContexts,
    bool? LevelContextsMoved,
    bool ConditionsComplete)
{
    public string? SoundName => Specifications.FirstOrDefault()?.SoundName;
    public IReadOnlyList<string> SoundNames => Specifications.Select(specification => specification.SoundName).ToList();
    public bool IsResolved => Specifications.Count > 0;
    public bool SpecificationComplete => !SpecificationPresent || Specifications.Count > 0;
}

/// <summary>One exact variable-length entry from a response's <c>Specification</c> array.</summary>
public sealed record SoundEventSpecification(
    string SoundName, string SpecificationClass, byte EncodedNameSize, byte[] RawPayload);

/// <summary>
/// Reads <c>EventResponse_SoundEffectsSubsystem</c> objects — the bridge from an animation event to a
/// sound name.
/// </summary>
/// <remarks>
/// <para>
/// <b>CONFIRMED_BYTES.</b> The chain, end to end, entirely from shipped data:
/// </para>
/// <code>
/// FastReloadPistol   event "ReloadPistolOne" @ 0.30s   (AnimNotify_EffectEvent)
///        ↓  Event name matches exactly; SourceClassName says which actor
/// EventResponse_SoundEffectsSubsystem "HandsReloadPistolOne"
///        ↓  Specification names a sound
/// weapons_pistol_reload_one
/// </code>
/// <para>
/// <b>How the sound names are read, and why it is not a guess.</b> <c>Specification</c> is an array
/// of nested property-list entries. Each has one <c>SpecificationType</c> name and one
/// <c>SpecificationClass</c> object reference; the numbered sound FName takes
/// six or seven bytes, making the complete entries 25 or 26 bytes. Each
/// name points into the package's own name table. Across all 21 maps, 106,000 response objects contain 110,120 entries and every
/// array boundary consumes exactly; 1,760 responses carry several alternatives.
/// </para>
/// <para>
/// <b>The other bytes remain <c>UNKNOWN</c> and are preserved rather than interpreted.</b> The reader
/// validates the count, nested property, entry length and full consumption.
/// A response with no <c>Specification</c> remains explicitly distinct from malformed bytes.
/// </para>
/// <para>
/// Nothing here decodes audio. It resolves names and selection declarations; native and FSB sample
/// location are separate routes — see <c>docs/research/audio.md</c>.
/// </para>
/// </remarks>
public static class SoundEventReader
{
    public const string ClassName = "EventResponse_SoundEffectsSubsystem";

    /// <summary>Every sound-event response in a package.</summary>
    public static IReadOnlyList<SoundEventResponse> Read(BioShockPackage package)
    {
        var found = new List<SoundEventResponse>();

        foreach (var export in package.Exports)
        {
            if (export.SerialSize <= 0) continue;
            if (package.GetClassName(export) != ClassName) continue;

            var response = Read(package, export);
            if (response is not null) found.Add(response);
        }

        return found;
    }

    /// <summary>One response, or null when the object will not read at all.</summary>
    public static SoundEventResponse? Read(BioShockPackage package, ObjectExport export)
    {
        List<UnrealProperty> properties;
        try
        {
            properties = UnrealPropertyReader.Read(package.ReadExportData(export), package.Names, out _);
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException or IOException)
        {
            return null;
        }

        string? Name(string property) => properties
            .FirstOrDefault(p => p.Name == property && p.Type == UnrealPropertyType.Name)
            ?.Value is { } value
            ? ResolveName(package, value)
            : null;

        string eventName = Name("Event") ?? string.Empty;
        if (eventName.Length == 0) return null;

        var specification = properties.FirstOrDefault(p => p.Name == "Specification");
        var chance = properties.FirstOrDefault(p => p.Name == "Chance");
        var levelContext = properties.FirstOrDefault(p => p.Name == "LevelContext");
        bool conditionsComplete = true;
        IReadOnlyList<int> chances = [];
        if (chance is not null && !TryIntArray(chance.Value, out chances)) conditionsComplete = false;
        IReadOnlyList<string> contexts = [];
        if (levelContext is not null
            && !PropertyValues.TryAsNameArrayExact(levelContext, package, out contexts)) conditionsComplete = false;
        byte? filteredState = properties.FirstOrDefault(p => p.Name == "FilteredState") is
            { Type: UnrealPropertyType.Byte, Value.Length: > 0 } filtered ? filtered.Value[0] : null;
        bool? contextsMoved = properties.FirstOrDefault(p => p.Name == "bLevelContextsMoved") is
            { Type: UnrealPropertyType.Bool } moved ? moved.BoolValue : null;

        return new SoundEventResponse(
            export.ObjectName,
            eventName,
            Name("SourceClassName") ?? string.Empty,
            specification is not null,
            specification is null ? [] : SpecificationsFrom(package, specification.Value),
            filteredState, chances, contexts, contextsMoved, conditionsComplete);
    }

    /// <summary>
    /// Reads the exact variable-length specification array. Each entry begins with a nested
    /// <c>SpecificationType</c> name whose value occupies six or seven bytes and a
    /// <c>SpecificationClass</c> reference. The nested
    /// terminator proves each entry boundary; the count and final consumption must also agree.
    /// </summary>
    /// <remarks>
    /// The earlier single-19-byte interpretation was refuted by the whole-game census. Shipped
    /// responses contain 110,120 entries, including 1,760 responses with more than one alternative.
    /// Fields other than the sound name remain preserved in <see cref="SoundEventSpecification.RawPayload"/>.
    /// </remarks>
    private static IReadOnlyList<SoundEventSpecification> SpecificationsFrom(
        BioShockPackage package, byte[] value)
    {
        var result = new List<SoundEventSpecification>();
        int offset = 0;
        try
        {
            int count = ReadCompactIndex(value, ref offset);
            if (count < 0 || count > value.Length) return [];
            for (int i = 0; i < count; i++)
            {
                int elementStart = offset;
                var fields = UnrealPropertyReader.Read(value, package.Names, out int propertiesEnd,
                    out bool truncated, elementStart);
                var soundNames = fields.Where(field => field is
                    { Name: "SpecificationType", Type: UnrealPropertyType.Name }).ToList();
                var classes = fields.Where(field => field is
                    { Name: "SpecificationClass", Type: UnrealPropertyType.Object }).ToList();
                if (truncated || fields.Count != 2 || soundNames.Count != 1 || classes.Count != 1
                    || !classes[0].TryAsObjectReference(out var classReference))
                    return [];
                var soundName = soundNames[0];
                if (soundName.Value.Length is not (6 or 7)) return [];
                if (!TryNumberedName(soundName.Value, package, out string name)) return [];
                int elementEnd = propertiesEnd;
                if (elementEnd - elementStart is not (25 or 26)) return [];
                result.Add(new SoundEventSpecification(name, package.ResolveName(classReference),
                    (byte)soundName.Value.Length,
                    value.AsSpan(elementStart, elementEnd - elementStart).ToArray()));
                offset = elementEnd;
            }
            return offset == value.Length ? result : [];
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return [];
        }
    }

    private static bool TryNumberedName(byte[] value, BioShockPackage package, out string name)
    {
        name = string.Empty;
        int offset = 0;
        try
        {
            int index = ReadCompactIndex(value, ref offset);
            if (index < 0 || index >= package.Names.Count || offset + 4 != value.Length) return false;
            int number = BinaryPrimitives.ReadInt32LittleEndian(value.AsSpan(offset));
            name = package.Names[index].Name;
            // The suffix carries no separator - the same rendering the package's own FName reader
            // uses, confirmed against UEViewer's BioShock branch. Writing "name_N" here instead made
            // every numbered specification name miss the export it refers to: the response naming
            // ambience_common_bubbles number 2 points at the export ambience_common_bubbles2.
            if (number > 0) name += (number - 1).ToString();
            return true;
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return false;
        }
    }

    private static bool TryIntArray(byte[] value, out IReadOnlyList<int> values)
    {
        values = [];
        int offset = 0;
        try
        {
            int count = ReadCompactIndex(value, ref offset);
            if (count < 0 || offset + count * 4 != value.Length) return false;
            var result = new List<int>(count);
            for (int i = 0; i < count; i++, offset += 4)
                result.Add(BinaryPrimitives.ReadInt32LittleEndian(value.AsSpan(offset)));
            values = result;
            return true;
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return false;
        }
    }

    private static string? ResolveName(BioShockPackage package, byte[] value)
    {
        int offset = 0;
        int index;
        try { index = ReadCompactIndex(value, ref offset); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return null;
        }

        return index >= 0 && index < package.Names.Count ? package.Names[index].Name : null;
    }

    /// <summary>
    /// The era's variable-length index. Six value bits in the first byte, seven in each continuation.
    /// </summary>
    /// <remarks>
    /// Reading this as a fixed-width integer is a mistake this project has already made once, on
    /// <c>AttachCoords</c>, where it put every subsequent float three bytes out. See the landmine in
    /// <c>docs/HANDOFF.md</c>.
    /// </remarks>
    private static int ReadCompactIndex(ReadOnlySpan<byte> data, ref int offset)
    {
        byte first = data[offset++];
        bool negative = (first & 0x80) != 0;
        int value = first & 0x3F;

        if ((first & 0x40) != 0)
        {
            int shift = 6;
            while (true)
            {
                byte next = data[offset++];
                value |= (next & 0x7F) << shift;
                if ((next & 0x80) == 0) break;
                shift += 7;
                if (shift > 28) throw new InvalidDataException("compact index is too long");
            }
        }

        return negative ? -value : value;
    }
}
