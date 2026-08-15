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
    string? SoundName)
{
    public bool IsResolved => SoundName is not null;
}

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
/// <b>How the sound name is read, and why it is not a guess.</b> <c>Specification</c> is an array
/// property whose single element is 19 bytes. Across the three reload responses only one field
/// varies, and read as an <c>FCompactIndex</c> it gives 5057, 5065 and 5063 — which are, in the
/// package's own name table, <c>weapons_pistol_reload_one</c>, <c>_two</c> and <c>_three</c>. Three
/// independent values each landing on the semantically correct sound is the check; a wrong framing
/// does not do that three times.
/// </para>
/// <para>
/// <b>The rest of the 19 bytes is <c>UNKNOWN</c> and is preserved rather than interpreted.</b> The
/// reader only accepts a specification whose constant bytes match the observed template, and returns
/// a null sound name otherwise. That makes the read self-validating in the same way the material
/// struct-size correction is: a blob of a different shape cannot satisfy it and is reported as
/// unresolved instead of being decoded into a plausible wrong name.
/// </para>
/// <para>
/// Nothing here decodes audio. It resolves a <i>name</i>. Whether a sample of that name ships, and
/// where, is a separate and still-open question — see <c>docs/research/audio.md</c>.
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

        return new SoundEventResponse(
            export.ObjectName,
            eventName,
            Name("SourceClassName") ?? string.Empty,
            specification is null ? null : SoundNameFrom(package, specification.Value));
    }

    /// <summary>
    /// The 19-byte specification element as observed on every response checked so far. The bytes
    /// marked <c>..</c> are the name reference; everything else is required to match.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The element looks like this, and only the marked bytes are constant:
    /// </para>
    /// <code>
    /// 1-Medical      01 13000000 00 56 06  41 4F  00000000 14000000 00 05 84000000
    /// 0-Lighthouse   01 09000000 00 56 06  44 2C  00000000 08000000 00 05 83000000
    ///                ▲▲          ▲▲ ▲▲ ▲▲  name
    /// </code>
    /// <para>
    /// <b>Most of the surrounding bytes are package-local and vary.</b> An earlier version of this
    /// reader required the whole 1-Medical byte pattern, which made every other package's copy
    /// unresolved — caught by a test that read the events from one package and the responses from
    /// another. Only <c>[0]</c>, <c>[5]</c>, <c>[6]</c> and <c>[7]</c> hold across packages, so only
    /// those are checked. What they mean is <c>UNKNOWN</c>; they are a shape check, not an
    /// interpretation.
    /// </para>
    /// <para>
    /// <b>The <c>06</c> at [7] is part of the shape, not part of the index.</b> Reading the index
    /// one byte early yields 6 — the name <c>Tag</c> — on every response, which looks like a
    /// plausible resolved name rather than an error. A regression test caught that too.
    /// </para>
    /// <para>
    /// It is not <c>06</c> everywhere: level-actor responses such as
    /// <c>ActorScriptTrigger_RedLightAudio</c> carry <c>56 07</c>. Those are deliberately
    /// <b>not</b> decoded — only the shape proven against the pistol reload is read, in two
    /// packages, and anything else is reported unresolved.
    /// </para>
    /// </remarks>
    private static readonly (int Offset, byte Value)[] SpecificationShape =
        [(0, 0x01), (5, 0x00), (6, 0x56), (7, 0x06)];

    /// <summary>Where the name reference begins, once the shape above has matched.</summary>
    private const int SoundNameOffset = 8;

    private static string? SoundNameFrom(BioShockPackage package, byte[] value)
    {
        if (value.Length < SoundNameOffset + 2) return null;

        foreach (var (at, expected) in SpecificationShape)
            if (value[at] != expected) return null;

        int offset = SoundNameOffset;
        int index;
        try { index = ReadCompactIndex(value, ref offset); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return null;
        }

        return index >= 0 && index < package.Names.Count ? package.Names[index].Name : null;
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
