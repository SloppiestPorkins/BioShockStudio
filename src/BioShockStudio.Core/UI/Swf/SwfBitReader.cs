namespace BioShockStudio.Core.UI.Swf;

/// <summary>
/// MSB-first bit reader over a byte span, for SWF's packed bit fields (RECT, shape records).
/// SWF bit fields are read most-significant-bit first within each byte; <see cref="AlignToByte"/>
/// must be called before resuming byte-aligned tag reads (SWF spec, "the bit stream is read from
/// the most significant bit of the first byte").
/// </summary>
public ref struct SwfBitReader(ReadOnlySpan<byte> data)
{
    private readonly ReadOnlySpan<byte> _data = data;
    private int _bytePos;
    private int _bitPos; // 0-7, next bit to read within _data[_bytePos], MSB first.

    public readonly int BytePosition => _bytePos + (_bitPos > 0 ? 1 : 0);

    public uint ReadUnsigned(int bits)
    {
        if (bits == 0) return 0;
        uint value = 0;
        for (int i = 0; i < bits; i++)
        {
            value = (value << 1) | ReadBit();
        }
        return value;
    }

    public int ReadSigned(int bits)
    {
        if (bits == 0) return 0;
        uint raw = ReadUnsigned(bits);
        // Sign-extend from `bits`-wide two's complement.
        uint signBit = 1u << (bits - 1);
        if ((raw & signBit) != 0)
        {
            uint extendMask = ~0u << bits;
            raw |= extendMask;
        }
        return unchecked((int)raw);
    }

    private uint ReadBit()
    {
        if (_bytePos >= _data.Length) return 0; // Tolerate a short trailing record rather than throw.
        byte b = _data[_bytePos];
        uint bit = (uint)((b >> (7 - _bitPos)) & 1);
        _bitPos++;
        if (_bitPos == 8)
        {
            _bitPos = 0;
            _bytePos++;
        }
        return bit;
    }

    public void AlignToByte()
    {
        if (_bitPos != 0)
        {
            _bitPos = 0;
            _bytePos++;
        }
    }

    /// <summary>Byte-align, then return everything from here to the end as a fresh array (small,
    /// occasional-use copy — needed because the array-based tag readers take byte[]/int position
    /// rather than a ref struct span). Advances past `consumed` bytes of what's returned.</summary>
    public byte[] AlignAndCopyRemaining()
    {
        AlignToByte();
        return _data[_bytePos..].ToArray();
    }

    public void SkipBytes(int count) => _bytePos += count;

    /// <summary>Read an SWF RECT (Nbits(5) then 4 signed fields of Nbits each), in twips.</summary>
    public SwfRect ReadRect()
    {
        int nbits = (int)ReadUnsigned(5);
        int xMin = ReadSigned(nbits);
        int xMax = ReadSigned(nbits);
        int yMin = ReadSigned(nbits);
        int yMax = ReadSigned(nbits);
        return new SwfRect(xMin, xMax, yMin, yMax);
    }
}

/// <summary>SWF RECT: bounds in twips (1/20 px). Matches the spec field order exactly.</summary>
public readonly record struct SwfRect(int XMin, int XMax, int YMin, int YMax)
{
    public double WidthPx => (XMax - XMin) / 20.0;
    public double HeightPx => (YMax - YMin) / 20.0;
}
