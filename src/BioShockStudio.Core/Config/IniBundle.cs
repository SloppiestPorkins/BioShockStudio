using System.Text;

namespace BioShockStudio.Core.Config;

/// <summary>
/// The game's baked config bundle (<c>ContentBaked/pc/ConfigINI.IBF</c>) — every
/// <c>PerObjIniFile</c> the engine declares, concatenated.
/// </summary>
/// <remarks>
/// <para>
/// <b>Format, `CONFIRMED_BYTES`.</b> A flat sequence of entries, each:
/// </para>
/// <code>
/// FCompactIndex  nameLength        // characters, including the trailing NUL
/// UTF-16LE       fileName          // e.g. "Spawning.ini\0"
/// int32         contentLength      // bytes
/// byte[]        content            // the .ini text, ASCII/Latin-1, CRLF line endings
/// </code>
/// <para>
/// 21 files in the shipped bundle: <c>Spawning.ini</c> (every AI archetype), <c>Weapons.ini</c>
/// (weapon stats + the <c>[*ResistanceSet]</c> definitions), <c>LootTables.ini</c>, <c>Ai.ini</c>,
/// <c>Plasmids.ini</c>, <c>Difficulty.ini</c>, <c>Hacking.ini</c>, <c>Quests.ini</c>, and more.
/// This is the data layer for anything the packages carry only by name. See
/// <c>docs/research/config.md</c>.
/// </para>
/// </remarks>
public sealed class IniBundle
{
    private readonly Dictionary<string, IniDocument> _files;

    private IniBundle(Dictionary<string, IniDocument> files) => _files = files;

    /// <summary>The bundled file names, in bundle order.</summary>
    public IReadOnlyCollection<string> FileNames => _files.Keys;

    /// <summary>One parsed <c>.ini</c> by name (case-insensitive), or null if the bundle has no such file.</summary>
    public IniDocument? this[string fileName] =>
        _files.TryGetValue(fileName, out var doc) ? doc : null;

    public static IniBundle Load(string path) => Parse(File.ReadAllBytes(path));

    public static IniBundle Parse(ReadOnlySpan<byte> data)
    {
        var files = new Dictionary<string, IniDocument>(StringComparer.OrdinalIgnoreCase);
        int offset = 0;

        while (offset + 6 <= data.Length)
        {
            int nameLength = ReadCompactIndex(data, ref offset);
            if (nameLength <= 0 || nameLength > 256 || offset + nameLength * 2 + 4 > data.Length) break;

            string name = Encoding.Unicode.GetString(data.Slice(offset, nameLength * 2)).TrimEnd('\0');
            offset += nameLength * 2;

            int contentLength = ReadInt32(data, ref offset);
            if (contentLength < 0 || offset + contentLength > data.Length) break;

            // The .ini text is single-byte; Latin-1 keeps every byte a character without throwing.
            string content = Encoding.Latin1.GetString(data.Slice(offset, contentLength));
            offset += contentLength;

            if (name.Length > 0) files[name] = IniDocument.Parse(content);
        }

        return new IniBundle(files);
    }

    private static int ReadCompactIndex(ReadOnlySpan<byte> data, ref int offset)
    {
        byte b = data[offset++];
        bool negative = (b & 0x80) != 0;
        int value = b & 0x3F;
        if ((b & 0x40) != 0)
        {
            int shift = 6;
            while (true)
            {
                byte c = data[offset++];
                value |= (c & 0x7F) << shift;
                shift += 7;
                if ((c & 0x80) == 0) break;
                if (shift > 31) throw new InvalidDataException("FCompactIndex overflow.");
            }
        }
        return negative ? -value : value;
    }

    private static int ReadInt32(ReadOnlySpan<byte> data, ref int offset)
    {
        int value = data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) | (data[offset + 3] << 24);
        offset += 4;
        return value;
    }
}
