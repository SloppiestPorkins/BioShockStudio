using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Export;

/// <summary>
/// Resolves the material a mesh uses and writes its textures beside the scene, so an exported mesh
/// arrives textured rather than as bare geometry.
/// </summary>
public static class MaterialExporter
{
    /// <summary>Subdirectory the images are written to, relative to the scene.</summary>
    public const string TextureDirectory = "Textures";

    /// <summary>
    /// Resolves a mesh's material and writes every texture it binds as PNG.
    /// </summary>
    /// <remarks>
    /// A texture the shader names but which this package does not hold is skipped rather than
    /// substituted: the slot is simply absent from the result, so a missing map is visible as a
    /// missing map instead of a black image.
    /// </remarks>
    public static SceneMaterial? Resolve(
        BioShockPackage package, ObjectExport meshExport, string outputDirectory, BulkTextureCatalog? bulk = null)
    {
        var material = MaterialReader.ReadForMesh(package, meshExport);
        if (material is null) return null;

        var written = new Dictionary<string, string>(StringComparer.Ordinal);
        var files = new Dictionary<string, string>(StringComparer.Ordinal);

        foreach (var texture in material.Textures)
        {
            // The same image is usually bound to several slots — the hands use Hand_DIFF as both the
            // facing and edge diffuse — so it is written once and shared.
            if (written.TryGetValue(texture.TextureName, out string? existing))
            {
                files[texture.Slot] = existing;
                continue;
            }

            string? file = WriteTexture(package, texture, outputDirectory, bulk);
            if (file is null) continue;

            written[texture.TextureName] = file;
            files[texture.Slot] = file;
        }

        return new SceneMaterial
        {
            Name = material.Name,
            ClassName = material.ClassName,
            Textures = files,
            Diffuse = Lookup(files, material.DiffuseTexture, material, "Diffuse", "FacingDiffuse", "EdgeDiffuse"),
            NormalMap = Lookup(files, material.NormalTexture, material, "NormalMap"),
            Specular = Lookup(files, material.SpecularTexture, material,
                "SpecularColorMap", "FacingSpecularColorMap", "EdgeSpecularColorMap"),
            Glossiness = material.Glossiness,
            SpecularBrightness = material.SpecularBrightness,
            DiffuseColor = ToFloats(material.DiffuseColor),
            SpecularColor = ToFloats(material.SpecularColor),
            TwoSided = material.TwoSided,
            Masked = material.Masked,
            Partial = material.Truncated,
            Uninterpreted = material.UnhandledProperties.Distinct(StringComparer.Ordinal).ToList(),
        };
    }

    private static string? Lookup(
        IReadOnlyDictionary<string, string> files, string? textureName, BioShockMaterial material, params string[] slots)
    {
        if (textureName is null) return null;
        foreach (string slot in slots)
        {
            if (material.TextureFor(slot) == textureName && files.TryGetValue(slot, out string? file)) return file;
        }
        return null;
    }

    private static string? WriteTexture(
        BioShockPackage package, MaterialTexture texture, string outputDirectory, BulkTextureCatalog? bulk)
    {
        var export = Resolve(package, texture);
        if (export is null) return null;

        BioShockTexture? decoded;
        try { decoded = TextureReader.Read(package, export, bulk); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }
        if (decoded is null || decoded.Mips.Count == 0) return null;

        string directory = Path.Combine(outputDirectory, TextureDirectory);
        Directory.CreateDirectory(directory);

        string stem = string.Concat(decoded.Name.Split(Path.GetInvalidFileNameChars()));
        string relative = $"{TextureDirectory}/{stem}.png";

        var top = decoded.Mips[0];
        byte[] rgba = BlockCompression.Decode(decoded.Format, top.Data, top.Width, top.Height);
        PngWriter.Write(Path.Combine(outputDirectory, TextureDirectory, stem + ".png"), rgba, top.Width, top.Height);

        return relative;
    }

    /// <summary>
    /// Finds the texture export a binding names. A binding into another package carries only a name,
    /// so that case falls back to a name match within this one and gives up if there is none.
    /// </summary>
    private static ObjectExport? Resolve(BioShockPackage package, MaterialTexture texture)
    {
        if (texture.Reference.IsExport && texture.Reference.ExportIndex < package.Exports.Count)
            return package.Exports[texture.Reference.ExportIndex];

        return package.Exports
            .Where(e => package.GetClassName(e) == TextureReader.ClassName
                        && string.Equals(e.ObjectName, texture.TextureName, StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);
    }

    private static float[]? ToFloats(MaterialColor? color) => color is null
        ? null
        : [color.Value.R / 255f, color.Value.G / 255f, color.Value.B / 255f, color.Value.A / 255f];
}
