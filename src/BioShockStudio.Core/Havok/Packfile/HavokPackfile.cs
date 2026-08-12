using System.Text;

namespace BioShockStudio.Core.Havok.Packfile;

/// <summary>
/// A parsed Havok packfile: header plus section headers, with the class-name table decoded.
/// <para>
/// This is deliberately the *structural* layer only. Object graph reconstruction, skeletons,
/// animations and compression sit above it and are not implemented yet — see
/// <c>docs/research/havok.md</c> for what is confirmed versus still unknown.
/// </para>
/// </summary>
public sealed class HavokPackfile
{
    private readonly ReadOnlyMemory<byte> _buffer;

    public PackfileHeader Header { get; }
    public IReadOnlyList<PackfileSectionHeader> Sections { get; }

    /// <summary>Class names declared in the <c>__classnames__</c> section, keyed by their local offset.</summary>
    public IReadOnlyDictionary<int, string> ClassNames { get; }

    private HavokPackfile(ReadOnlyMemory<byte> buffer, PackfileHeader header, PackfileSectionHeader[] sections)
    {
        _buffer = buffer;
        Header = header;
        Sections = sections;
        ClassNames = ReadClassNames(buffer.Span, sections, header);
    }

    /// <summary>Parses a packfile starting at <paramref name="offset"/> within <paramref name="buffer"/>.</summary>
    public static HavokPackfile Parse(ReadOnlyMemory<byte> buffer, int offset = 0)
    {
        var span = buffer.Span[offset..];
        if (!PackfileHeader.TryRead(span, out var header) || header is null)
            throw new InvalidDataException($"No Havok packfile header at offset {offset}.");

        var sections = new PackfileSectionHeader[header.NumSections];
        for (int i = 0; i < sections.Length; i++)
        {
            int at = PackfileHeader.Size + i * PackfileSectionHeader.Size;
            sections[i] = PackfileSectionHeader.Read(span[at..]);
        }

        return new HavokPackfile(buffer[offset..], header, sections);
    }

    /// <summary>Total byte length of the packfile, derived from the last section's end offset.</summary>
    public int TotalSize
    {
        get
        {
            int max = Header.AbsoluteDataStart;
            foreach (var s in Sections)
                max = Math.Max(max, s.AbsoluteDataStart + s.EndOffset);
            return max;
        }
    }

    /// <summary>The raw object-data region of a section (everything before its fixup tables).</summary>
    public ReadOnlyMemory<byte> GetSectionData(PackfileSectionHeader section) =>
        _buffer.Slice(section.AbsoluteDataStart, section.DataSize);

    public PackfileSectionHeader? FindSection(string tag)
    {
        foreach (var s in Sections)
            if (s.SectionTag == tag) return s;
        return null;
    }

    /// <summary>
    /// The class name of the packfile's root object, resolved through
    /// <see cref="PackfileHeader.ContentsClassNameSectionIndex"/>/<c>Offset</c>.
    /// For stock Havok content this is <c>hkRootLevelContainer</c>; BioShock is expected to differ.
    /// </summary>
    public string? ContentsClassName =>
        ClassNames.TryGetValue(Header.ContentsClassNameSectionOffset, out var name) ? name : null;

    /// <summary>
    /// The <c>__classnames__</c> section is a sequence of {uint32 signature, byte 0x09, ASCIIZ name}
    /// records. The offset recorded for each name is the offset of its *text*, which is what the
    /// header and virtual fixups reference.
    /// </summary>
    private static Dictionary<int, string> ReadClassNames(
        ReadOnlySpan<byte> buffer, PackfileSectionHeader[] sections, PackfileHeader header)
    {
        var result = new Dictionary<int, string>();
        if (header.ContentsClassNameSectionIndex < 0 || header.ContentsClassNameSectionIndex >= sections.Length)
            return result;

        var section = sections[header.ContentsClassNameSectionIndex];
        int start = section.AbsoluteDataStart;
        int end = start + section.DataSize;
        if (end > buffer.Length) return result;

        int pos = start;
        while (pos + 5 < end)
        {
            // 4-byte type signature, then a 0x09 separator, then the null-terminated name.
            int textStart = pos + 5;
            int nul = buffer[textStart..end].IndexOf((byte)0);
            if (nul <= 0) break;
            result[textStart - start] = Encoding.ASCII.GetString(buffer.Slice(textStart, nul));
            pos = textStart + nul + 1;
        }

        return result;
    }
}
