using System.Buffers.Binary;
using System.IO.Compression;
using System.Text;

namespace BioShockStudio.Core.Textures;

/// <summary>Minimal PNG writer. Avoids a third-party imaging dependency for a well-specified format.</summary>
public static class PngWriter
{
    public static void Write(string path, byte[] rgba, int width, int height)
    {
        using var stream = File.Create(path);
        Write(stream, rgba, width, height);
    }

    public static void Write(Stream stream, byte[] rgba, int width, int height)
    {
        stream.Write([0x89, (byte)'P', (byte)'N', (byte)'G', 0x0D, 0x0A, 0x1A, 0x0A]);

        var header = new byte[13];
        BinaryPrimitives.WriteInt32BigEndian(header, width);
        BinaryPrimitives.WriteInt32BigEndian(header.AsSpan(4), height);
        header[8] = 8;   // bit depth
        header[9] = 6;   // colour type: RGBA
        WriteChunk(stream, "IHDR", header);

        // Each scanline is prefixed with a filter byte; filter 0 (none) keeps this simple and the
        // deflate stream still compresses well.
        var raw = new byte[(width * 4 + 1) * height];
        for (int y = 0; y < height; y++)
        {
            int source = y * width * 4;
            int destination = y * (width * 4 + 1);
            raw[destination] = 0;
            Array.Copy(rgba, source, raw, destination + 1, width * 4);
        }

        WriteChunk(stream, "IDAT", Deflate(raw));
        WriteChunk(stream, "IEND", []);
    }

    private static byte[] Deflate(byte[] data)
    {
        using var output = new MemoryStream();
        // zlib wrapper: 0x78 0x01, deflate payload, Adler-32.
        output.WriteByte(0x78);
        output.WriteByte(0x01);
        using (var deflate = new DeflateStream(output, CompressionLevel.Optimal, leaveOpen: true))
            deflate.Write(data);

        Span<byte> adler = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(adler, Adler32(data));
        output.Write(adler);
        return output.ToArray();
    }

    private static uint Adler32(ReadOnlySpan<byte> data)
    {
        uint a = 1, b = 0;
        foreach (byte value in data)
        {
            a = (a + value) % 65521;
            b = (b + a) % 65521;
        }
        return (b << 16) | a;
    }

    private static void WriteChunk(Stream stream, string type, byte[] data)
    {
        Span<byte> length = stackalloc byte[4];
        BinaryPrimitives.WriteInt32BigEndian(length, data.Length);
        stream.Write(length);

        var typeBytes = Encoding.ASCII.GetBytes(type);
        stream.Write(typeBytes);
        stream.Write(data);

        uint crc = Crc32(typeBytes, data);
        Span<byte> crcBytes = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(crcBytes, crc);
        stream.Write(crcBytes);
    }

    private static readonly uint[] CrcTable = BuildCrcTable();

    private static uint[] BuildCrcTable()
    {
        var table = new uint[256];
        for (uint i = 0; i < 256; i++)
        {
            uint c = i;
            for (int k = 0; k < 8; k++) c = (c & 1) != 0 ? 0xEDB88320u ^ (c >> 1) : c >> 1;
            table[i] = c;
        }
        return table;
    }

    private static uint Crc32(ReadOnlySpan<byte> a, ReadOnlySpan<byte> b)
    {
        uint c = 0xFFFFFFFFu;
        foreach (byte value in a) c = CrcTable[(c ^ value) & 0xFF] ^ (c >> 8);
        foreach (byte value in b) c = CrcTable[(c ^ value) & 0xFF] ^ (c >> 8);
        return c ^ 0xFFFFFFFFu;
    }
}

/// <summary>
/// DDS writer, used when the point is to keep the GPU-compressed data and the full mip chain
/// exactly as the game shipped it.
/// </summary>
public static class DdsWriter
{
    public static void Write(string path, BioShockTexture texture)
    {
        using var stream = File.Create(path);

        var header = new byte[128];
        Encoding.ASCII.GetBytes("DDS ").CopyTo(header, 0);
        BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(4), 124);              // header size

        // caps | height | width | pitch | mipmapcount | pixelformat
        int flags = 0x1 | 0x2 | 0x4 | 0x1000 | 0x20000;
        bool compressed = texture.Format != BioShockTextureFormat.Rgba8;
        flags |= compressed ? 0x80000 : 0x8;
        BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(8), flags);
        BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(12), texture.Height);
        BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(16), texture.Width);
        BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(20),
            compressed ? texture.Mips[0].Data.Length : texture.Width * 4);
        BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(28), texture.Mips.Count);

        // DDS_PIXELFORMAT at offset 76
        BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(76), 32);
        if (compressed)
        {
            BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(80), 0x4);          // DDPF_FOURCC
            Encoding.ASCII.GetBytes(texture.Format switch
            {
                BioShockTextureFormat.Dxt1 => "DXT1",
                BioShockTextureFormat.Dxt3 => "DXT3",
                _ => "DXT5",
            }).CopyTo(header, 84);
        }
        else
        {
            BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(80), 0x41);         // RGB | ALPHAPIXELS
            BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(88), 32);           // bit count
            BinaryPrimitives.WriteUInt32LittleEndian(header.AsSpan(92), 0x00FF0000);  // R
            BinaryPrimitives.WriteUInt32LittleEndian(header.AsSpan(96), 0x0000FF00);  // G
            BinaryPrimitives.WriteUInt32LittleEndian(header.AsSpan(100), 0x000000FF); // B
            BinaryPrimitives.WriteUInt32LittleEndian(header.AsSpan(104), 0xFF000000); // A
        }

        int caps = 0x1000 | (texture.Mips.Count > 1 ? 0x400008 : 0);
        BinaryPrimitives.WriteInt32LittleEndian(header.AsSpan(108), caps);

        stream.Write(header);
        foreach (var mip in texture.Mips) stream.Write(mip.Data);
    }
}
