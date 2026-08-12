using System.Buffers.Binary;
using BioShockStudio.Core.Havok.Packfile;

namespace BioShockStudio.Core.Havok.Detection;

/// <summary>A Havok packfile located inside a larger buffer.</summary>
public readonly record struct HavokPackfileLocation(int Offset, PackfileHeader Header);

/// <summary>
/// Finds Havok packfiles embedded in arbitrary buffers.
/// <para>
/// BioShock stores Havok payloads inline in package export data rather than as standalone files —
/// a single map contains thousands of them — so scanning for the magic is the entry point for
/// everything downstream.
/// </para>
/// </summary>
public static class HavokDetector
{
    /// <summary>Enumerates every Havok packfile whose header parses at a magic match.</summary>
    public static IEnumerable<HavokPackfileLocation> FindAll(ReadOnlyMemory<byte> buffer)
    {
        var results = new List<HavokPackfileLocation>();
        var span = buffer.Span;

        // BioShock writes packfiles into export payloads at arbitrary byte offsets, not on a 4-byte
        // boundary, so the scan has to be byte-granular.
        Span<byte> magic = stackalloc byte[8];
        BinaryPrimitives.WriteUInt32LittleEndian(magic, PackfileHeader.Magic0);
        BinaryPrimitives.WriteUInt32LittleEndian(magic[4..], PackfileHeader.Magic1);

        int searchFrom = 0;
        while (searchFrom + PackfileHeader.Size <= span.Length)
        {
            int found = span[searchFrom..].IndexOf(magic);
            if (found < 0) break;

            int offset = searchFrom + found;
            if (offset + PackfileHeader.Size <= span.Length &&
                PackfileHeader.TryRead(span[offset..], out var header) && header is not null)
            {
                results.Add(new HavokPackfileLocation(offset, header));
            }
            searchFrom = offset + 1;
        }

        return results;
    }

    /// <summary>Returns the first Havok packfile in the buffer, or null if there is none.</summary>
    public static HavokPackfileLocation? FindFirst(ReadOnlyMemory<byte> buffer)
    {
        foreach (var hit in FindAll(buffer)) return hit;
        return null;
    }
}
