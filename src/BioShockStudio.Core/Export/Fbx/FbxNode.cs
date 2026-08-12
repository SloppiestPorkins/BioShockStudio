using System.Buffers.Binary;
using System.IO.Compression;
using System.Numerics;
using System.Text;

namespace BioShockStudio.Core.Export.Fbx;

/// <summary>
/// One property of an FBX node record: a single-character type code and its already-encoded
/// little-endian payload.
/// <para>
/// Payloads are encoded when the property is added rather than when the file is written, because
/// the binary format stores each record's absolute end offset, so every length — including the
/// compressed length of an array — has to be known before anything is written.
/// </para>
/// </summary>
public readonly record struct FbxProperty(char TypeCode, byte[] Payload);

/// <summary>
/// A node record in an FBX binary document: a name, a property list and nested children.
/// </summary>
public sealed class FbxNode(string name)
{
    /// <summary>Arrays shorter than this are stored raw; the deflate header costs more than it saves.</summary>
    private const int CompressionThreshold = 128;

    public string Name { get; } = name.Length < 256
        ? name
        : throw new ArgumentException("An FBX node name must fit in a byte length prefix.", nameof(name));

    public List<FbxProperty> Properties { get; } = [];
    public List<FbxNode> Children { get; } = [];

    // Filled by the size pass in FbxWriter, which mirrors the offsets the write pass then asserts.
    internal long EndOffset;
    internal int PropertiesLength;

    /// <summary>Appends a child node and returns it, so trees can be built by chaining.</summary>
    public FbxNode Add(string childName)
    {
        var child = new FbxNode(childName);
        Children.Add(child);
        return child;
    }

    /// <summary>Appends a child node carrying a single string property — the common leaf shape.</summary>
    public FbxNode Add(string childName, string value) => Add(childName).String(value);

    public FbxNode Add(string childName, int value) => Add(childName).Int32(value);

    public FbxNode Add(string childName, long value) => Add(childName).Int64(value);

    public FbxNode Add(string childName, double value) => Add(childName).Double(value);

    public FbxNode Bool(bool value) => Raw('C', [value ? (byte)1 : (byte)0]);

    public FbxNode Int16(short value)
    {
        var buffer = new byte[2];
        BinaryPrimitives.WriteInt16LittleEndian(buffer, value);
        return Raw('Y', buffer);
    }

    public FbxNode Int32(int value)
    {
        var buffer = new byte[4];
        BinaryPrimitives.WriteInt32LittleEndian(buffer, value);
        return Raw('I', buffer);
    }

    public FbxNode Int64(long value)
    {
        var buffer = new byte[8];
        BinaryPrimitives.WriteInt64LittleEndian(buffer, value);
        return Raw('L', buffer);
    }

    public FbxNode Float(float value)
    {
        var buffer = new byte[4];
        BinaryPrimitives.WriteSingleLittleEndian(buffer, value);
        return Raw('F', buffer);
    }

    public FbxNode Double(double value)
    {
        var buffer = new byte[8];
        BinaryPrimitives.WriteDoubleLittleEndian(buffer, value);
        return Raw('D', buffer);
    }

    /// <summary>
    /// Adds a string property. FBX object names embed their class after a <c>\0\1</c> separator, so
    /// the payload is written verbatim rather than being validated as text.
    /// </summary>
    public FbxNode String(string value)
    {
        byte[] text = Encoding.UTF8.GetBytes(value);
        var payload = new byte[4 + text.Length];
        BinaryPrimitives.WriteInt32LittleEndian(payload, text.Length);
        text.CopyTo(payload.AsSpan(4));
        return Raw('S', payload);
    }

    public FbxNode Bytes(byte[] value)
    {
        var payload = new byte[4 + value.Length];
        BinaryPrimitives.WriteInt32LittleEndian(payload, value.Length);
        value.CopyTo(payload.AsSpan(4));
        return Raw('R', payload);
    }

    public FbxNode Int32Array(ReadOnlySpan<int> values)
    {
        var raw = new byte[values.Length * 4];
        for (int i = 0; i < values.Length; i++) BinaryPrimitives.WriteInt32LittleEndian(raw.AsSpan(i * 4), values[i]);
        return Array('i', values.Length, raw);
    }

    public FbxNode Int64Array(ReadOnlySpan<long> values)
    {
        var raw = new byte[values.Length * 8];
        for (int i = 0; i < values.Length; i++) BinaryPrimitives.WriteInt64LittleEndian(raw.AsSpan(i * 8), values[i]);
        return Array('l', values.Length, raw);
    }

    public FbxNode FloatArray(ReadOnlySpan<float> values)
    {
        var raw = new byte[values.Length * 4];
        for (int i = 0; i < values.Length; i++) BinaryPrimitives.WriteSingleLittleEndian(raw.AsSpan(i * 4), values[i]);
        return Array('f', values.Length, raw);
    }

    public FbxNode DoubleArray(ReadOnlySpan<double> values)
    {
        var raw = new byte[values.Length * 8];
        for (int i = 0; i < values.Length; i++) BinaryPrimitives.WriteDoubleLittleEndian(raw.AsSpan(i * 8), values[i]);
        return Array('d', values.Length, raw);
    }

    /// <summary>
    /// Writes a 4x4 matrix as the 16 doubles FBX expects: row-major with the translation in the
    /// fourth row, which is exactly <see cref="Matrix4x4"/>'s own layout.
    /// </summary>
    public FbxNode MatrixArray(Matrix4x4 m) => DoubleArray(
    [
        m.M11, m.M12, m.M13, m.M14,
        m.M21, m.M22, m.M23, m.M24,
        m.M31, m.M32, m.M33, m.M34,
        m.M41, m.M42, m.M43, m.M44,
    ]);

    private FbxNode Raw(char typeCode, byte[] payload)
    {
        Properties.Add(new FbxProperty(typeCode, payload));
        return this;
    }

    private FbxNode Array(char typeCode, int count, byte[] raw)
    {
        byte[] data = raw;
        uint encoding = 0;

        if (raw.Length >= CompressionThreshold)
        {
            byte[] compressed = Deflate(raw);
            // Random-looking float data occasionally grows under deflate; keep whichever is smaller.
            if (compressed.Length < raw.Length)
            {
                data = compressed;
                encoding = 1;
            }
        }

        var payload = new byte[12 + data.Length];
        BinaryPrimitives.WriteUInt32LittleEndian(payload, (uint)count);
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(4), encoding);
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(8), (uint)data.Length);
        data.CopyTo(payload.AsSpan(12));
        return Raw(typeCode, payload);
    }

    /// <summary>FBX array encoding 1 is zlib, not bare deflate.</summary>
    private static byte[] Deflate(byte[] raw)
    {
        using var output = new MemoryStream();
        using (var zlib = new ZLibStream(output, CompressionLevel.Optimal, leaveOpen: true)) zlib.Write(raw);
        return output.ToArray();
    }
}
