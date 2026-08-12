using System.Buffers.Binary;
using System.IO.Compression;
using System.Text;

namespace BioShockStudio.Tests;

/// <summary>One parsed FBX node record.</summary>
public sealed record FbxRecord(string Name, IReadOnlyList<object> Properties, IReadOnlyList<FbxRecord> Children)
{
    public FbxRecord? Find(string name) => Children.FirstOrDefault(c => c.Name == name);

    public IEnumerable<FbxRecord> FindAll(string name) => Children.Where(c => c.Name == name);

    /// <summary>An object record's name, with the <c>\0\1class</c> suffix stripped.</summary>
    public string ObjectName =>
        Properties.Count > 1 && Properties[1] is string s ? s.Split((char)0)[0] : string.Empty;

    /// <summary>An object record's subclass, e.g. <c>LimbNode</c>.</summary>
    public string SubClass => Properties.Count > 2 && Properties[2] is string s ? s : string.Empty;
}

/// <summary>
/// Reads back the binary FBX container the exporter writes.
/// <para>
/// Deliberately a second, independent implementation rather than a shared one: a test that used the
/// writer's own framing to check the writer would pass on a file no other reader could open.
/// </para>
/// </summary>
public static class FbxTestReader
{
    public static IReadOnlyList<FbxRecord> Read(byte[] data)
    {
        string magic = Encoding.ASCII.GetString(data, 0, 20);
        if (magic != "Kaydara FBX Binary  ")
            throw new InvalidDataException($"Not an FBX binary file: '{magic}'.");

        uint version = BinaryPrimitives.ReadUInt32LittleEndian(data.AsSpan(23));
        if (version != 7400) throw new InvalidDataException($"Unexpected FBX version {version}.");

        using var stream = new MemoryStream(data);
        using var reader = new BinaryReader(stream);
        stream.Position = 27;

        var roots = ReadList(reader);

        // Everything after the top-level terminator is the footer; the first 16 bytes identify it.
        byte[] footerId = reader.ReadBytes(16);
        if (footerId[0] != 0xFA || footerId[15] != 0x7E)
            throw new InvalidDataException("The top-level record list did not end on the footer.");

        return roots;
    }

    private static List<FbxRecord> ReadList(BinaryReader reader)
    {
        var records = new List<FbxRecord>();

        while (true)
        {
            uint endOffset = reader.ReadUInt32();
            uint propertyCount = reader.ReadUInt32();
            reader.ReadUInt32();
            byte nameLength = reader.ReadByte();

            // A zeroed record header is the end-of-list sentinel.
            if (endOffset == 0) return records;

            string name = Encoding.ASCII.GetString(reader.ReadBytes(nameLength));

            var properties = new List<object>();
            for (int i = 0; i < propertyCount; i++) properties.Add(ReadProperty(reader));

            var children = reader.BaseStream.Position < endOffset ? ReadList(reader) : [];
            if (reader.BaseStream.Position != endOffset)
                throw new InvalidDataException(
                    $"Record '{name}' ended at {reader.BaseStream.Position}, its header said {endOffset}.");

            records.Add(new FbxRecord(name, properties, children));
        }
    }

    private static object ReadProperty(BinaryReader reader)
    {
        char type = (char)reader.ReadByte();
        switch (type)
        {
            case 'Y': return reader.ReadInt16();
            case 'C': return reader.ReadByte() != 0;
            case 'I': return reader.ReadInt32();
            case 'F': return reader.ReadSingle();
            case 'D': return reader.ReadDouble();
            case 'L': return reader.ReadInt64();
            case 'S': return Encoding.UTF8.GetString(reader.ReadBytes(reader.ReadInt32()));
            case 'R': return reader.ReadBytes(reader.ReadInt32());

            case 'i': return ReadArray(reader, 4, b => ToInt32(b));
            case 'l': return ReadArray(reader, 8, ToInt64);
            case 'f': return ReadArray(reader, 4, ToSingle);
            case 'd': return ReadArray(reader, 8, ToDouble);
            case 'b': return ReadArray(reader, 1, b => b.Select(x => x != 0).ToArray());

            default: throw new InvalidDataException($"Unknown FBX property type '{type}'.");
        }
    }

    private static object ReadArray(BinaryReader reader, int elementSize, Func<byte[], object> convert)
    {
        int length = reader.ReadInt32();
        uint encoding = reader.ReadUInt32();
        int compressedLength = reader.ReadInt32();
        byte[] payload = reader.ReadBytes(compressedLength);

        if (encoding == 1)
        {
            using var input = new MemoryStream(payload);
            using var zlib = new ZLibStream(input, CompressionMode.Decompress);
            using var output = new MemoryStream();
            zlib.CopyTo(output);
            payload = output.ToArray();
        }

        if (payload.Length != length * elementSize)
            throw new InvalidDataException($"Array declared {length} elements but decoded to {payload.Length} bytes.");

        return convert(payload);
    }

    private static int[] ToInt32(byte[] b)
    {
        var result = new int[b.Length / 4];
        for (int i = 0; i < result.Length; i++) result[i] = BinaryPrimitives.ReadInt32LittleEndian(b.AsSpan(i * 4));
        return result;
    }

    private static object ToInt64(byte[] b)
    {
        var result = new long[b.Length / 8];
        for (int i = 0; i < result.Length; i++) result[i] = BinaryPrimitives.ReadInt64LittleEndian(b.AsSpan(i * 8));
        return result;
    }

    private static object ToSingle(byte[] b)
    {
        var result = new float[b.Length / 4];
        for (int i = 0; i < result.Length; i++) result[i] = BinaryPrimitives.ReadSingleLittleEndian(b.AsSpan(i * 4));
        return result;
    }

    private static object ToDouble(byte[] b)
    {
        var result = new double[b.Length / 8];
        for (int i = 0; i < result.Length; i++) result[i] = BinaryPrimitives.ReadDoubleLittleEndian(b.AsSpan(i * 8));
        return result;
    }
}
