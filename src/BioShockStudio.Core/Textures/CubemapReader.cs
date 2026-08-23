using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Textures;

/// <summary>An environment cubemap: six ordinary textures named as one object.</summary>
public sealed record BioShockCubemap
{
    public required string Name { get; init; }

    /// <summary>
    /// The faces, in the order the <c>Faces</c> array declares them.
    /// </summary>
    /// <remarks>
    /// <b>Declaration order, not a cube-face mapping.</b> Which index is +X, -X, +Y and so on is
    /// <c>UNKNOWN</c>: the game names them only <c>_Face_0</c> to <c>_Face_5</c> and nothing read so
    /// far states the convention. The order is preserved exactly as serialised so that a consumer
    /// which does know the convention can apply it, rather than this reader guessing at one and
    /// baking a wrong rotation into every reflection.
    /// </remarks>
    public required IReadOnlyList<BioShockTexture> Faces { get; init; }

    /// <summary>Names of faces that were declared but could not be read.</summary>
    public required IReadOnlyList<string> UnreadableFaces { get; init; }

    /// <summary>True when all six faces decoded. A cubemap short of a face cannot be sampled.</summary>
    public bool IsComplete => Faces.Count == 6 && UnreadableFaces.Count == 0;
}

/// <summary>
/// Reads <c>Cubemap</c> exports.
/// </summary>
/// <remarks>
/// <para>
/// <c>CONFIRMED_BYTES</c>, 23 Aug 2026: a <c>Cubemap</c> introduces no new payload format at all.
/// Its export is an ordinary property list whose <c>Faces</c> entries are six <c>Object</c>
/// references, each resolving to a plain <c>Texture</c> export named <c>&lt;cubemap&gt;_Face_N</c>,
/// which <see cref="TextureReader"/> already decodes. 287 cubemaps ship across the 33 packages.
/// </para>
/// <para>
/// This is why the class was worth opening before anything harder: the gap was that nothing
/// <i>looked</i> for them, not that their contents were unknown.
/// </para>
/// </remarks>
public static class CubemapReader
{
    public const string ClassName = "Cubemap";

    /// <summary>The property naming each face.</summary>
    private const string FacesProperty = "Faces";

    /// <summary>
    /// Reads a cubemap and its faces. Null when the export is not a readable cubemap.
    /// </summary>
    /// <remarks>
    /// A face that fails to decode is reported in <see cref="BioShockCubemap.UnreadableFaces"/>
    /// rather than dropped, so an incomplete cubemap is visibly incomplete instead of quietly
    /// looking like a smaller one.
    /// </remarks>
    public static BioShockCubemap? Read(BioShockPackage package, ObjectExport export,
        BulkTextureCatalog? bulk = null)
    {
        if (package.GetClassName(export) != ClassName) return null;

        byte[] payload;
        try { payload = package.ReadExportData(export); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException)
        {
            return null;
        }

        List<UnrealProperty> properties;
        try { properties = UnrealPropertyReader.Read(payload, package.Names, out _); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return null;
        }

        var faces = new List<BioShockTexture>();
        var unreadable = new List<string>();

        foreach (var property in properties)
        {
            if (property.Name != FacesProperty || property.Type != UnrealPropertyType.Object) continue;
            if (!property.TryAsObjectReference(out var reference)) continue;

            // A face in another package carries no bytes here. Reported, not silently skipped.
            if (!reference.IsExport || reference.ExportIndex >= package.Exports.Count)
            {
                unreadable.Add(reference.IsImport ? "<import>" : "<unresolved>");
                continue;
            }

            var faceExport = package.Exports[reference.ExportIndex];

            BioShockTexture? face;
            try { face = TextureReader.Read(package, faceExport, bulk); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                           or ArgumentOutOfRangeException)
            {
                face = null;
            }

            if (face is null) unreadable.Add(faceExport.ObjectName);
            else faces.Add(face);
        }

        if (faces.Count == 0 && unreadable.Count == 0) return null;

        return new BioShockCubemap
        {
            Name = export.ObjectName,
            Faces = faces,
            UnreadableFaces = unreadable,
        };
    }
}
