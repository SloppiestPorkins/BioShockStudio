using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Audio;

/// <summary>The raw payload of one native Unreal <c>Sound</c> export.</summary>
/// <param name="Name">The package export's object name.</param>
/// <param name="RawData">The exact bytes from the export's lazy array.</param>
/// <param name="Format">The identified container, or <see cref="SoundFormat.Unknown"/>.</param>
/// <param name="LazyArraySkipPosition">The lazy array's on-disk skip position, preserved uninterpreted.</param>
/// <param name="Unknown10">The first BioShock-specific lazy-array field, preserved uninterpreted.</param>
/// <param name="Unknown8">The second BioShock-specific lazy-array field, preserved uninterpreted.</param>
public sealed record BioShockSound(
    string Name,
    byte[] RawData,
    SoundFormat Format,
    int LazyArraySkipPosition,
    int Unknown10,
    int Unknown8);

/// <summary>Container identified from a recovered sound payload's own signature.</summary>
public enum SoundFormat
{
    Unknown,
    Mp3,
}

/// <summary>Reads the native Unreal <c>Sound</c> container used by BioShock's embedded FMOD audio.</summary>
/// <remarks>
/// <para><b>CONFIRMED_BYTES.</b> The payload has an ordinary tagged-property list, then the layout
/// UModel reads for BioShock's <c>USound</c>: an <c>FName</c> (compact index plus number), followed
/// by a lazy byte array. BioShock version 142 writes three int32 fields before the compact byte
/// count. The count must consume the export exactly; otherwise this reader returns null rather than
/// treating a plausible tail as audio.</para>
/// <para>The three pre-array integers are preserved because their meaning is not yet established.
/// Only the raw payload boundary is decoded here. See <c>docs/research/audio.md</c>.</para>
/// </remarks>
public static class SoundReader
{
    public const string ClassName = "Sound";

    /// <summary>Reads every native Sound export that satisfies the byte-exact payload boundary.</summary>
    public static IReadOnlyList<BioShockSound> Read(BioShockPackage package)
    {
        var found = new List<BioShockSound>();
        foreach (var export in package.Exports)
        {
            if (export.SerialSize <= 0 || package.GetClassName(export) != ClassName) continue;
            var sound = Read(package, export);
            if (sound is not null) found.Add(sound);
        }
        return found;
    }

    /// <summary>Reads one Sound export, or null when its layout is not the proven BioShock shape.</summary>
    public static BioShockSound? Read(BioShockPackage package, ObjectExport export)
    {
        if (package.GetClassName(export) != ClassName) return null;

        byte[] payload = package.ReadExportData(export);
        int offset;
        try
        {
            UnrealPropertyReader.Read(payload, package.Names, out offset);

            _ = ReadCompactIndex(payload, ref offset); // FName index; its semantic role remains unknown.
            _ = ReadInt32(payload, ref offset);        // FName number.

            int skipPosition = ReadInt32(payload, ref offset);
            int unknown10 = ReadInt32(payload, ref offset);
            int unknown8 = ReadInt32(payload, ref offset);
            int count = ReadCompactIndex(payload, ref offset);

            if (count < 0 || count != payload.Length - offset) return null;

            byte[] raw = payload.AsSpan(offset, count).ToArray();
            return new BioShockSound(export.ObjectName, raw, Identify(raw), skipPosition, unknown10, unknown8);
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return null;
        }
    }

    private static SoundFormat Identify(ReadOnlySpan<byte> data) =>
        IsMpegLayer3Frame(data) ? SoundFormat.Mp3 : SoundFormat.Unknown;

    // MPEG audio frame sync (11 one bits), a defined MPEG version/layer, and a non-free bitrate.
    // This is an identification gate, not an MP3 decoder.
    private static bool IsMpegLayer3Frame(ReadOnlySpan<byte> data)
    {
        if (data.Length < 4 || data[0] != 0xFF || (data[1] & 0xE0) != 0xE0) return false;
        int version = (data[1] >> 3) & 0x03;
        int layer = (data[1] >> 1) & 0x03;
        int bitrate = (data[2] >> 4) & 0x0F;
        int sampleRate = (data[2] >> 2) & 0x03;
        return version != 0x01 && layer == 0x01 && bitrate is > 0 and < 0x0F && sampleRate != 0x03;
    }

    private static int ReadInt32(ReadOnlySpan<byte> data, ref int offset)
    {
        if (offset < 0 || offset > data.Length - sizeof(int)) throw new InvalidDataException("truncated Sound payload");
        int value = BitConverter.ToInt32(data.Slice(offset, sizeof(int)));
        offset += sizeof(int);
        return value;
    }

    private static int ReadCompactIndex(ReadOnlySpan<byte> data, ref int offset)
    {
        if ((uint)offset >= (uint)data.Length) throw new InvalidDataException("truncated compact index");
        byte first = data[offset++];
        bool negative = (first & 0x80) != 0;
        int value = first & 0x3F;

        if ((first & 0x40) != 0)
        {
            int shift = 6;
            while (true)
            {
                if ((uint)offset >= (uint)data.Length) throw new InvalidDataException("truncated compact index");
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
