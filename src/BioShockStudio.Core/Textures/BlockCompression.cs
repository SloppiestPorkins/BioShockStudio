using System.Buffers.Binary;

namespace BioShockStudio.Core.Textures;

/// <summary>
/// Decodes S3TC/DXT blocks to straight RGBA8.
/// <para>
/// BC1 (DXT1), BC2 (DXT3) and BC3 (DXT5) are the formats BioShock ships, alongside uncompressed
/// RGBA8. All three share the same 4x4 colour block; they differ only in how alpha is carried.
/// </para>
/// </summary>
public static class BlockCompression
{
    /// <summary>Decodes a mip into RGBA8, row-major, four bytes per pixel.</summary>
    public static byte[] Decode(BioShockTextureFormat format, ReadOnlySpan<byte> data, int width, int height)
    {
        var pixels = new byte[width * height * 4];

        switch (format)
        {
            case BioShockTextureFormat.Rgba8:
                // BioShock stores this channel order as BGRA on disk.
                for (int i = 0; i + 3 < data.Length && i + 3 < pixels.Length; i += 4)
                {
                    pixels[i] = data[i + 2];
                    pixels[i + 1] = data[i + 1];
                    pixels[i + 2] = data[i];
                    pixels[i + 3] = data[i + 3];
                }
                return pixels;

            case BioShockTextureFormat.Dxt1:
                DecodeBlocks(data, width, height, pixels, blockSize: 8, DecodeDxt1Block);
                return pixels;

            case BioShockTextureFormat.Dxt3:
                DecodeBlocks(data, width, height, pixels, blockSize: 16, DecodeDxt3Block);
                return pixels;

            case BioShockTextureFormat.Dxt5:
                DecodeBlocks(data, width, height, pixels, blockSize: 16, DecodeDxt5Block);
                return pixels;

            default:
                throw new NotSupportedException($"Unsupported texture format {format}.");
        }
    }

    private delegate void BlockDecoder(ReadOnlySpan<byte> block, Span<byte> rgba);

    private static void DecodeBlocks(
        ReadOnlySpan<byte> data, int width, int height, byte[] pixels, int blockSize, BlockDecoder decoder)
    {
        int blocksX = Math.Max(1, (width + 3) / 4);
        int blocksY = Math.Max(1, (height + 3) / 4);
        Span<byte> block = stackalloc byte[64];

        for (int by = 0; by < blocksY; by++)
        {
            for (int bx = 0; bx < blocksX; bx++)
            {
                int offset = (by * blocksX + bx) * blockSize;
                if (offset + blockSize > data.Length) return;

                decoder(data.Slice(offset, blockSize), block);

                for (int y = 0; y < 4; y++)
                {
                    int py = by * 4 + y;
                    if (py >= height) break;
                    for (int x = 0; x < 4; x++)
                    {
                        int px = bx * 4 + x;
                        if (px >= width) break;
                        int source = (y * 4 + x) * 4;
                        int destination = (py * width + px) * 4;
                        pixels[destination] = block[source];
                        pixels[destination + 1] = block[source + 1];
                        pixels[destination + 2] = block[source + 2];
                        pixels[destination + 3] = block[source + 3];
                    }
                }
            }
        }
    }

    /// <summary>Expands the shared 4x4 colour block. Alpha is left at 255.</summary>
    private static void DecodeColourBlock(ReadOnlySpan<byte> block, Span<byte> rgba, bool punchThroughAlpha)
    {
        ushort c0 = BinaryPrimitives.ReadUInt16LittleEndian(block);
        ushort c1 = BinaryPrimitives.ReadUInt16LittleEndian(block[2..]);
        uint indices = BinaryPrimitives.ReadUInt32LittleEndian(block[4..]);

        Span<byte> palette = stackalloc byte[16];
        Expand565(c0, palette[..4]);
        Expand565(c1, palette.Slice(4, 4));

        bool fourColour = c0 > c1 || !punchThroughAlpha;
        for (int channel = 0; channel < 3; channel++)
        {
            byte a = palette[channel];
            byte b = palette[4 + channel];
            if (fourColour)
            {
                palette[8 + channel] = (byte)((2 * a + b) / 3);
                palette[12 + channel] = (byte)((a + 2 * b) / 3);
            }
            else
            {
                palette[8 + channel] = (byte)((a + b) / 2);
                palette[12 + channel] = 0;
            }
        }
        palette[11] = 255;
        palette[15] = (byte)(fourColour ? 255 : 0);

        for (int i = 0; i < 16; i++)
        {
            int index = (int)((indices >> (i * 2)) & 0x3) * 4;
            rgba[i * 4] = palette[index];
            rgba[i * 4 + 1] = palette[index + 1];
            rgba[i * 4 + 2] = palette[index + 2];
            rgba[i * 4 + 3] = palette[index + 3];
        }
    }

    private static void Expand565(ushort value, Span<byte> rgba)
    {
        int r = (value >> 11) & 0x1F;
        int g = (value >> 5) & 0x3F;
        int b = value & 0x1F;
        rgba[0] = (byte)((r << 3) | (r >> 2));
        rgba[1] = (byte)((g << 2) | (g >> 4));
        rgba[2] = (byte)((b << 3) | (b >> 2));
        rgba[3] = 255;
    }

    private static void DecodeDxt1Block(ReadOnlySpan<byte> block, Span<byte> rgba) =>
        DecodeColourBlock(block, rgba, punchThroughAlpha: true);

    private static void DecodeDxt3Block(ReadOnlySpan<byte> block, Span<byte> rgba)
    {
        DecodeColourBlock(block[8..], rgba, punchThroughAlpha: false);

        // Four bits of explicit alpha per pixel.
        for (int i = 0; i < 16; i++)
        {
            int nibble = (block[i / 2] >> ((i % 2) * 4)) & 0xF;
            rgba[i * 4 + 3] = (byte)(nibble * 17);
        }
    }

    private static void DecodeDxt5Block(ReadOnlySpan<byte> block, Span<byte> rgba)
    {
        DecodeColourBlock(block[8..], rgba, punchThroughAlpha: false);

        Span<byte> alpha = stackalloc byte[8];
        alpha[0] = block[0];
        alpha[1] = block[1];
        if (alpha[0] > alpha[1])
        {
            for (int i = 1; i < 7; i++)
                alpha[i + 1] = (byte)(((7 - i) * alpha[0] + i * alpha[1]) / 7);
        }
        else
        {
            for (int i = 1; i < 5; i++)
                alpha[i + 1] = (byte)(((5 - i) * alpha[0] + i * alpha[1]) / 5);
            alpha[6] = 0;
            alpha[7] = 255;
        }

        ulong bits = 0;
        for (int i = 0; i < 6; i++) bits |= (ulong)block[2 + i] << (8 * i);

        for (int i = 0; i < 16; i++)
            rgba[i * 4 + 3] = alpha[(int)((bits >> (3 * i)) & 0x7)];
    }
}
