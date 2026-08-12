using System.Buffers.Binary;
using System.Text;

namespace BioShockStudio.Core.Export.Fbx;

/// <summary>
/// Writes an FBX node tree in the binary 7.4 container.
/// <para>
/// Binary rather than ASCII deliberately: Blender's importer refuses ASCII FBX outright, and
/// Blender is what validates this exporter's output against the game's own transforms. The
/// framing rules below — in particular which records need a 13-byte null terminator — are the ones
/// Blender's reader enforces.
/// </para>
/// </summary>
public static class FbxWriter
{
    public const int Version = 7400;

    /// <summary>23 bytes: the literal, two trailing spaces, then <c>00 1A 00</c>.</summary>
    private static readonly byte[] HeadMagic =
        [.. Encoding.ASCII.GetBytes("Kaydara FBX Binary  "), 0x00, 0x1A, 0x00];

    private static readonly byte[] FooterId =
        [0xFA, 0xBC, 0xAB, 0x09, 0xD0, 0xC8, 0xD4, 0x66, 0xB1, 0x76, 0xFB, 0x83, 0x1C, 0xF7, 0x26, 0x7E];

    private static readonly byte[] FooterMagic =
        [0xF8, 0x5A, 0x8C, 0x6A, 0xDE, 0xF5, 0xD9, 0x7E, 0xEC, 0xE9, 0x0C, 0xE3, 0x75, 0x8F, 0x29, 0x0B];

    /// <summary>End-of-nested-list marker: three zeroed uint32s plus a zero name length.</summary>
    private const int SentinelLength = 13;

    /// <summary>
    /// Records that carry the null terminator even with no children. Empirical, from Autodesk's own
    /// files; readers that expect it reject the file otherwise.
    /// </summary>
    private static readonly string[] AlwaysTerminated = ["AnimationStack", "AnimationLayer"];

    public static void Write(string path, IReadOnlyList<FbxNode> roots)
    {
        using var stream = File.Create(path);
        Write(stream, roots);
    }

    public static void Write(Stream stream, IReadOnlyList<FbxNode> roots)
    {
        stream.Write(HeadMagic);
        WriteUInt32(stream, Version);

        // The top-level list behaves like the child list of an unnamed root record.
        MeasureChildren(roots, HeadMagic.Length + 4, isLast: false);
        WriteChildren(stream, roots, isLast: false);

        stream.Write(FooterId);
        stream.Write(new byte[4]);

        // Alignment padding; a file that is already aligned still takes a full 16 bytes.
        int pad = (int)((stream.Position + 15) / 16 * 16 - stream.Position);
        stream.Write(new byte[pad == 0 ? 16 : pad]);

        WriteUInt32(stream, Version);
        stream.Write(new byte[120]);
        stream.Write(FooterMagic);
    }

    private static long Measure(FbxNode node, long offset, bool isLast)
    {
        // uint32 endOffset, uint32 propertyCount, uint32 propertyListLength, then byte nameLength.
        offset += 12 + 1 + Encoding.ASCII.GetByteCount(node.Name);

        int propertiesLength = 0;
        foreach (var property in node.Properties) propertiesLength += 1 + property.Payload.Length;
        node.PropertiesLength = propertiesLength;
        offset += propertiesLength;

        offset = MeasureChildren(node.Children, offset, isLast, node);
        node.EndOffset = offset;
        return offset;
    }

    private static long MeasureChildren(IReadOnlyList<FbxNode> children, long offset, bool isLast, FbxNode? parent = null)
    {
        if (children.Count > 0)
        {
            for (int i = 0; i < children.Count; i++) offset = Measure(children[i], offset, i == children.Count - 1);
            return offset + SentinelLength;
        }

        return NeedsBareTerminator(parent, isLast) ? offset + SentinelLength : offset;
    }

    private static void WriteChildren(Stream stream, IReadOnlyList<FbxNode> children, bool isLast, FbxNode? parent = null)
    {
        if (children.Count > 0)
        {
            for (int i = 0; i < children.Count; i++) WriteNode(stream, children[i], i == children.Count - 1);
            stream.Write(new byte[SentinelLength]);
            return;
        }

        if (NeedsBareTerminator(parent, isLast)) stream.Write(new byte[SentinelLength]);
    }

    private static bool NeedsBareTerminator(FbxNode? parent, bool isLast) =>
        parent is not null && ((parent.Properties.Count == 0 && !isLast) || AlwaysTerminated.Contains(parent.Name));

    private static void WriteNode(Stream stream, FbxNode node, bool isLast)
    {
        WriteUInt32(stream, (uint)node.EndOffset);
        WriteUInt32(stream, (uint)node.Properties.Count);
        WriteUInt32(stream, (uint)node.PropertiesLength);

        byte[] name = Encoding.ASCII.GetBytes(node.Name);
        stream.WriteByte((byte)name.Length);
        stream.Write(name);

        foreach (var property in node.Properties)
        {
            stream.WriteByte((byte)property.TypeCode);
            stream.Write(property.Payload);
        }

        WriteChildren(stream, node.Children, isLast, node);

        // The size pass and the write pass must agree exactly; every reader navigates by end offset.
        if (stream.Position != node.EndOffset)
            throw new InvalidOperationException(
                $"FBX record '{node.Name}' ended at {stream.Position}, expected {node.EndOffset}.");
    }

    private static void WriteUInt32(Stream stream, uint value)
    {
        Span<byte> buffer = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32LittleEndian(buffer, value);
        stream.Write(buffer);
    }
}
