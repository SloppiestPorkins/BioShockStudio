using BioShockStudio.Core.Io;

namespace BioShockStudio.Core.Packages;

/// <summary>
/// Reader for BioShock 1 Remastered <c>.bsm</c> packages.
/// <para>
/// Only the header and the three tables are read on open; export payloads are fetched on demand,
/// so opening a 230 MB map costs a few hundred kilobytes of I/O.
/// </para>
/// </summary>
public sealed class BioShockPackage : IDisposable
{
    public const ushort RemasteredFileVersion = 142;
    public const ushort RemasteredLicenseeVersion = 56;

    private readonly FileStream _stream;
    private readonly StreamReaderLE _reader;

    /// <summary>Guards the reader's position, so a cached package can serve several threads.</summary>
    private readonly object _readGate = new();

    public string FilePath { get; }
    public PackageSummary Summary { get; }
    public IReadOnlyList<NameEntry> Names { get; }
    public IReadOnlyList<ObjectImport> Imports { get; }
    public IReadOnlyList<ObjectExport> Exports { get; }

    /// <summary>Byte offset one past the last export table entry. Equals the file length in every shipped package.</summary>
    public long ExportTableEnd { get; }

    private BioShockPackage(string path, FileStream stream)
    {
        FilePath = path;
        _stream = stream;
        _reader = new StreamReaderLE(stream);

        Summary = ReadSummary(_reader);
        Names = ReadNames(_reader, Summary);
        Imports = ReadImports(_reader, Summary, Names);
        (Exports, ExportTableEnd) = ReadExports(_reader, Summary, Names);
    }

    public static BioShockPackage Open(string path)
    {
        var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read, 64 * 1024);
        try
        {
            return new BioShockPackage(path, stream);
        }
        catch
        {
            stream.Dispose();
            throw;
        }
    }

    private static PackageSummary ReadSummary(StreamReaderLE r)
    {
        r.Position = 0;
        uint magic = r.ReadUInt32();
        if (magic != PackageSummary.UnrealPackageMagic)
            throw new InvalidDataException($"Not an Unreal package (magic 0x{magic:X8}).");

        ushort fileVersion = r.ReadUInt16();
        ushort licenseeVersion = r.ReadUInt16();
        if (fileVersion != RemasteredFileVersion || licenseeVersion != RemasteredLicenseeVersion)
        {
            throw new NotSupportedException(
                $"Unsupported package version {fileVersion}/{licenseeVersion}. " +
                $"This tool targets BioShock 1 Remastered only ({RemasteredFileVersion}/{RemasteredLicenseeVersion}).");
        }

        uint flags = r.ReadUInt32();
        int nameCount = r.ReadInt32();
        int nameOffset = r.ReadInt32();
        int exportCount = r.ReadInt32();
        int exportOffset = r.ReadInt32();
        int importCount = r.ReadInt32();
        int importOffset = r.ReadInt32();
        Guid guid = r.ReadGuid();

        int generationCount = r.ReadInt32();
        var generations = new PackageGeneration[generationCount];
        for (int i = 0; i < generationCount; i++)
            generations[i] = new PackageGeneration(r.ReadInt32(), r.ReadInt32());

        return new PackageSummary
        {
            FileVersion = fileVersion,
            LicenseeVersion = licenseeVersion,
            PackageFlags = flags,
            NameCount = nameCount,
            NameOffset = nameOffset,
            ExportCount = exportCount,
            ExportOffset = exportOffset,
            ImportCount = importCount,
            ImportOffset = importOffset,
            Guid = guid,
            Generations = generations,
        };
    }

    private static NameEntry[] ReadNames(StreamReaderLE r, PackageSummary summary)
    {
        r.Position = summary.NameOffset;
        var names = new NameEntry[summary.NameCount];
        for (int i = 0; i < names.Length; i++)
        {
            string text = r.ReadUnicodeString();
            ulong flags = r.ReadUInt64();
            names[i] = new NameEntry(text, flags);
        }
        return names;
    }

    /// <summary>
    /// FName: FCompactIndex into the name table plus an int32 "extra index". An extra index of 0 means
    /// the bare name; otherwise the suffix <c>extra - 1</c> is appended with no separator, matching
    /// UEViewer's BioShock branch (CONFIRMED_EXTERNAL: gildor2/UEViewer <c>GAME_Bioshock</c> FName path).
    /// </summary>
    private static string ReadFName(StreamReaderLE r, IReadOnlyList<NameEntry> names)
    {
        int index = r.ReadCompactIndex();
        int extra = r.ReadInt32();
        if (index < 0 || index >= names.Count)
            throw new InvalidDataException($"Name index {index} out of range (0..{names.Count - 1}).");
        string baseName = names[index].Name;
        return extra == 0 ? baseName : baseName + (extra - 1);
    }

    private static ObjectImport[] ReadImports(StreamReaderLE r, PackageSummary summary, IReadOnlyList<NameEntry> names)
    {
        r.Position = summary.ImportOffset;
        var imports = new ObjectImport[summary.ImportCount];
        for (int i = 0; i < imports.Length; i++)
        {
            imports[i] = new ObjectImport
            {
                ClassPackage = ReadFName(r, names),
                ClassName = ReadFName(r, names),
                Outer = new PackageIndex(r.ReadInt32()),
                ObjectName = ReadFName(r, names),
            };
        }
        return imports;
    }

    private static (ObjectExport[] Exports, long End) ReadExports(
        StreamReaderLE r, PackageSummary summary, IReadOnlyList<NameEntry> names)
    {
        r.Position = summary.ExportOffset;
        var exports = new ObjectExport[summary.ExportCount];
        for (int i = 0; i < exports.Length; i++)
        {
            exports[i] = new ObjectExport
            {
                Index = i,
                ClassIndex = new PackageIndex(r.ReadCompactIndex()),
                SuperIndex = new PackageIndex(r.ReadCompactIndex()),
                OuterIndex = new PackageIndex(r.ReadInt32()),
                Unknown32 = r.ReadInt32(),
                ObjectName = ReadFName(r, names),
                ObjectFlags = r.ReadUInt64(),
                SerialSize = r.ReadCompactIndex(),
                SerialOffset = r.ReadCompactIndex(),
                TrailingUnknown32 = r.ReadInt32(),
            };
        }
        return (exports, r.Position);
    }

    /// <summary>Resolves a <see cref="PackageIndex"/> to a display name.</summary>
    public string ResolveName(PackageIndex index)
    {
        if (index.IsNull) return "None";
        if (index.IsImport)
        {
            int i = index.ImportIndex;
            return i >= 0 && i < Imports.Count ? Imports[i].ObjectName : $"<bad import {i}>";
        }
        int e = index.ExportIndex;
        return e >= 0 && e < Exports.Count ? Exports[e].ObjectName : $"<bad export {e}>";
    }

    /// <summary>
    /// The class name of an export. A null class index means the export *is* a UClass
    /// (Unreal's convention), so "Class" is returned.
    /// </summary>
    public string GetClassName(ObjectExport export) =>
        export.ClassIndex.IsNull ? "Class" : ResolveName(export.ClassIndex);

    /// <summary>Full <c>Outer.Outer.Name</c> path of an export.</summary>
    public string GetFullPath(ObjectExport export)
    {
        var parts = new List<string> { export.ObjectName };
        var outer = export.OuterIndex;
        // Guard against malformed self-referential outer chains.
        for (int guard = 0; !outer.IsNull && guard < 32; guard++)
        {
            parts.Add(ResolveName(outer));
            if (!outer.IsExport) break;
            outer = Exports[outer.ExportIndex].OuterIndex;
        }
        parts.Reverse();
        return string.Join('.', parts);
    }

    /// <summary>Reads the serialised payload of an export.</summary>
    /// <remarks>
    /// <para>
    /// <b>Locked, so several threads may read one package at once.</b> Seeking a shared reader and
    /// then reading from it is a race the moment two callers hold the same instance — and holding
    /// one instance is the whole point of <see cref="PackageCache"/>, because opening
    /// <c>1-Medical.bsm</c> parses its tables in 46 ms while reading a payload out of it costs a
    /// thousandth of that.
    /// </para>
    /// <para>
    /// <b>A lock rather than a positionless read, and that was measured.</b> Reading at an absolute
    /// offset through <c>RandomAccess</c> needs no lock at all, but it also bypasses the stream's
    /// 64 KB buffer — and this is called once per export, thousands of times in a row, by anything
    /// that walks a package. <c>LevelAnalyzer.Analyze</c> went from <b>107.6 ms to 217.7 ms</b> that
    /// way, so the lock is the cheaper of the two: a read is microseconds and the packages a
    /// contended one would be serialising are the ones already in cache.
    /// </para>
    /// </remarks>
    public byte[] ReadExportData(ObjectExport export)
    {
        if (export.SerialSize == 0) return [];
        if (export.SerialOffset < 0 || export.SerialOffset + (long)export.SerialSize > _stream.Length)
            throw new InvalidDataException($"Export '{export.ObjectName}' payload lies outside the file.");

        lock (_readGate)
        {
            _reader.Position = export.SerialOffset;
            return _reader.ReadBytes(export.SerialSize);
        }
    }

    /// <summary>Opens a read-only view over an export's payload without copying it.</summary>
    public Stream OpenExportStream(ObjectExport export)
    {
        var view = new FileStream(FilePath, FileMode.Open, FileAccess.Read, FileShare.Read, 64 * 1024);
        return new WindowStream(view, export.SerialOffset, export.SerialSize);
    }

    public void Dispose() => _stream.Dispose();
}
