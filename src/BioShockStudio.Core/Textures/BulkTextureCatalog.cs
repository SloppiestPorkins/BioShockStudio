using System.Buffers.Binary;
using System.Text;
using BioShockStudio.Core.Game;

namespace BioShockStudio.Core.Textures;

/// <summary>Where one texture's stripped mips live in the bulk store.</summary>
/// <param name="Chunk">File name of the <c>.blk</c> chunk, e.g. <c>BulkChunk0_29.blk</c>.</param>
/// <param name="Offset">Byte offset within that chunk. Always a multiple of 32,768.</param>
/// <param name="Size">Total bytes, which is the sum of the stripped mip levels exactly.</param>
public sealed record BulkTextureEntry(string Texture, string Group, string Chunk, long Offset, int Size, int Index);

/// <summary>
/// The index into <c>ContentBaked/pc/BulkContent</c>.
/// </summary>
/// <remarks>
/// <para>
/// Most of the game's textures are shipped with their top mips removed. A stripped <c>Texture</c>
/// export says so itself — <c>HasBeenStripped</c>, <c>StrippedNumMips</c> — and still declares its
/// real <c>USize</c> and <c>VSize</c>, while the mips it carries start well below that. In
/// <c>1-Medical</c>, 1,639 of ~1,937 textures top out at 64 square.
/// </para>
/// <para>
/// The removed mips are in 201 <c>BulkChunk*.blk</c> files, about 8 GB, indexed by
/// <c>Catalog.bdc</c>. <b>CONFIRMED_BYTES</b> — see <c>docs/research/bulkcontent.md</c>:
/// </para>
/// <code>
/// 23 bytes                        header, not understood
/// per chunk:
///   FString  chunk file name      "BulkChunk0_0.blk"
///   byte                          not understood, 0x17 on the first
///   per texture:
///     FString  texture name
///     FString  group name
///     int32    zero
///     int32    offset into the chunk, always a multiple of 32768
///     int32    size
///     int32    the same size again
///     int32    index
/// </code>
/// <para>
/// An <c>FString</c> here is a byte unit count then that many UTF-16 units, the last a terminator.
/// </para>
/// <para>
/// The evidence that this is read correctly is arithmetic rather than plausibility: for all 5,777
/// entries the offset is 32,768-aligned, and <b>every single size is exactly the sum of a run of
/// mip levels</b> for a square power of two — 2,793,472 bytes is precisely DXT1 at
/// 2048 + 1024 + 512 + 256 + 128. A misparse does not produce 5,777 exact mip-chain sums.
/// </para>
/// </remarks>
public sealed class BulkTextureCatalog
{
    /// <summary>Bulk offsets are aligned to this, in every entry.</summary>
    public const int OffsetAlignment = 32768;

    private const string CatalogFileName = "Catalog.bdc";

    /// <summary>Bytes before the first chunk name.</summary>
    private const int HeaderSize = 23;

    /// <summary>Byte between a chunk's name and its first entry.</summary>
    private const int ChunkGap = 1;

    private const int RecordSize = 20;

    private readonly Dictionary<string, List<BulkTextureEntry>> _byTexture;

    public string Directory { get; }

    public IReadOnlyList<BulkTextureEntry> Entries { get; }

    private BulkTextureCatalog(string directory, IReadOnlyList<BulkTextureEntry> entries)
    {
        Directory = directory;
        Entries = entries;

        _byTexture = new Dictionary<string, List<BulkTextureEntry>>(StringComparer.OrdinalIgnoreCase);
        foreach (var entry in entries)
        {
            if (!_byTexture.TryGetValue(entry.Texture, out var list))
                _byTexture[entry.Texture] = list = [];
            list.Add(entry);
        }
    }

    /// <summary>Loads the catalogue, or null when the game has no bulk content beside it.</summary>
    public static BulkTextureCatalog? Load(string gameRoot)
    {
        string directory = GameLocator.BulkContentDirectory(gameRoot);
        string path = Path.Combine(directory, CatalogFileName);
        if (!File.Exists(path)) return null;

        return new BulkTextureCatalog(directory, Parse(File.ReadAllBytes(path)));
    }

    /// <summary>
    /// The entry for a texture, narrowed by group.
    /// </summary>
    /// <remarks>
    /// <b>Pass the group.</b> This used to say that when a name appears in more than one group the
    /// duplicates are "copies of the same art", so taking the first was harmless. <b>That was wrong.</b>
    /// 112 names in the catalogue appear in more than one group, and all 112 point at different
    /// bytes — different offsets, sometimes different sizes. Taking the first put another group's
    /// texture on 340 of the game's 30,831 texture exports, including the final boss, whose skin was
    /// drawn with the <c>Gen_Graffiti</c> "ATLAS IS WATCHING" wall decal that shares the name
    /// <c>Atlas_Diffuse</c>.
    /// <para>
    /// The fallback to the first candidate is kept, because a texture whose outer names no
    /// catalogue group still has to resolve to something, and for the 5,510 unambiguous names it is
    /// the only candidate anyway. <see cref="TextureReader"/> supplies the group from the export's
    /// own outer, so callers do not have to know about this.
    /// </para>
    /// </remarks>
    public BulkTextureEntry? Find(string textureName, string? group = null)
    {
        if (!_byTexture.TryGetValue(textureName, out var candidates)) return null;

        if (group is not null)
        {
            var matched = candidates.FirstOrDefault(e => string.Equals(e.Group, group, StringComparison.OrdinalIgnoreCase));
            if (matched is not null) return matched;
        }

        return candidates[0];
    }

    /// <summary>Reads an entry's bytes out of its chunk, or null when the chunk is missing.</summary>
    public byte[]? Read(BulkTextureEntry entry)
    {
        string path = Path.Combine(Directory, entry.Chunk);
        if (!File.Exists(path)) return null;

        using var stream = File.OpenRead(path);
        if (entry.Offset < 0 || entry.Offset + entry.Size > stream.Length) return null;

        stream.Seek(entry.Offset, SeekOrigin.Begin);
        var buffer = new byte[entry.Size];
        return stream.ReadAtLeast(buffer, entry.Size, throwOnEndOfStream: false) == entry.Size ? buffer : null;
    }

    private static List<BulkTextureEntry> Parse(byte[] data)
    {
        var entries = new List<BulkTextureEntry>();
        string chunk = "";
        int offset = HeaderSize;

        while (offset < data.Length)
        {
            if (!TryReadString(data, ref offset, out string name)) { offset++; continue; }

            if (name.EndsWith(".blk", StringComparison.OrdinalIgnoreCase))
            {
                chunk = name;
                offset += ChunkGap;
                continue;
            }

            if (!TryReadString(data, ref offset, out string group)) continue;
            if (offset + RecordSize > data.Length) break;

            int leading = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset));
            long at = BinaryPrimitives.ReadUInt32LittleEndian(data.AsSpan(offset + 4));
            int size = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset + 8));
            int repeated = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset + 12));
            int index = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset + 16));
            offset += RecordSize;

            // The record is only accepted when its own redundancy holds. A record that does not is a
            // record this reader has misunderstood, and is dropped rather than guessed at.
            if (leading != 0 || size != repeated || size <= 0) continue;
            if (at % OffsetAlignment != 0) continue;

            entries.Add(new BulkTextureEntry(name, group, chunk, at, size, index));
        }

        return entries;
    }

    /// <summary>A byte unit count, then that many UTF-16 units, the last of which is the terminator.</summary>
    private static bool TryReadString(byte[] data, ref int offset, out string text)
    {
        text = "";
        if (offset < 0 || offset >= data.Length) return false;

        int units = data[offset];
        if (units is < 2 or > 128) return false;

        int bytes = units * 2;
        if (offset + 1 + bytes > data.Length) return false;
        if (BinaryPrimitives.ReadUInt16LittleEndian(data.AsSpan(offset + 1 + bytes - 2)) != 0) return false;

        var builder = new StringBuilder(units - 1);
        for (int i = 0; i < units - 1; i++)
        {
            ushort c = BinaryPrimitives.ReadUInt16LittleEndian(data.AsSpan(offset + 1 + i * 2));
            if (c is < 32 or > 126) return false;
            builder.Append((char)c);
        }

        text = builder.ToString();
        offset += 1 + bytes;
        return true;
    }
}
