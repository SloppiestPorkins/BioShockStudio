using System.Buffers.Binary;
using System.Text;

namespace BioShockStudio.Core.Io;

/// <summary>
/// Little-endian primitive reader over a seekable stream.
/// Deliberately stream-based: BioShock Remastered packages are up to ~230 MB and the
/// bulk archives total ~8 GB, so nothing is ever fully materialised in memory.
/// </summary>
public sealed class StreamReaderLE
{
    private readonly Stream _stream;
    private readonly byte[] _scratch = new byte[16];

    public StreamReaderLE(Stream stream)
    {
        _stream = stream ?? throw new ArgumentNullException(nameof(stream));
        if (!stream.CanSeek) throw new ArgumentException("Stream must be seekable.", nameof(stream));
    }

    public long Position
    {
        get => _stream.Position;
        set => _stream.Position = value;
    }

    public long Length => _stream.Length;

    private ReadOnlySpan<byte> Fill(int count)
    {
        var span = _scratch.AsSpan(0, count);
        _stream.ReadExactly(span);
        return span;
    }

    public byte ReadByte()
    {
        int b = _stream.ReadByte();
        if (b < 0) throw new EndOfStreamException();
        return (byte)b;
    }

    public short ReadInt16() => BinaryPrimitives.ReadInt16LittleEndian(Fill(2));
    public ushort ReadUInt16() => BinaryPrimitives.ReadUInt16LittleEndian(Fill(2));
    public int ReadInt32() => BinaryPrimitives.ReadInt32LittleEndian(Fill(4));
    public uint ReadUInt32() => BinaryPrimitives.ReadUInt32LittleEndian(Fill(4));
    public long ReadInt64() => BinaryPrimitives.ReadInt64LittleEndian(Fill(8));
    public ulong ReadUInt64() => BinaryPrimitives.ReadUInt64LittleEndian(Fill(8));
    public float ReadSingle() => BinaryPrimitives.ReadSingleLittleEndian(Fill(4));

    public byte[] ReadBytes(int count)
    {
        var buffer = new byte[count];
        _stream.ReadExactly(buffer);
        return buffer;
    }

    public Guid ReadGuid() => new(ReadBytes(16));

    public void Skip(long count) => _stream.Position += count;

    /// <summary>
    /// Unreal FCompactIndex: variable-length signed integer.
    /// Byte 0: bit7 = sign, bit6 = continue, bits 0-5 = value. Following bytes: bit7 = continue, bits 0-6 = value.
    /// </summary>
    public int ReadCompactIndex()
    {
        byte b = ReadByte();
        bool negative = (b & 0x80) != 0;
        int value = b & 0x3F;

        if ((b & 0x40) != 0)
        {
            int shift = 6;
            while (true)
            {
                byte c = ReadByte();
                value |= (c & 0x7F) << shift;
                shift += 7;
                if ((c & 0x80) == 0) break;
                if (shift > 31) throw new InvalidDataException("FCompactIndex overflow.");
            }
        }

        return negative ? -value : value;
    }

    /// <summary>Length-prefixed UTF-16LE string: FCompactIndex character count (including terminator).</summary>
    public string ReadUnicodeString()
    {
        int charCount = ReadCompactIndex();
        if (charCount <= 0) return string.Empty;
        byte[] raw = ReadBytes(charCount * 2);
        // Trim the trailing null terminator.
        return Encoding.Unicode.GetString(raw, 0, (charCount - 1) * 2);
    }
}
