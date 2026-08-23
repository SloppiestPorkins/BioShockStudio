using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
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
        return material is null ? null : Convert(package, material, outputDirectory, bulk);
    }

    /// <summary>
    /// Resolves every material a mesh uses and which triangles use each.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A mesh naming more than one material draws a run of its index buffer with each — 1,179 of the
    /// game's 8,668 static meshes do. Exporting only the first is what put hull metal on the
    /// Bathysphere's windows.
    /// </para>
    /// <para>
    /// The pairing itself is <see cref="MeshSurfaceResolver"/>'s, not this method's: this only turns
    /// its result into scene records and writes the images.
    /// </para>
    /// </remarks>
    /// <returns>
    /// The distinct materials, and one index per triangle into that list. A triangle whose slot
    /// resolves nothing gets <c>-1</c> and exports with no material rather than a neighbour's.
    /// </returns>
    public static (IReadOnlyList<SceneMaterial> Materials, int[] TriangleMaterials) ResolveSurfaces(
        BioShockPackage package,
        ObjectExport meshExport,
        MeshGeometry geometry,
        string outputDirectory,
        BulkTextureCatalog? bulk = null,
        IExternalMaterialSource? external = null)
    {
        var surfaces = MeshSurfaceResolver.Resolve(package, meshExport, geometry, external);
        var triangles = new int[geometry.Indices.Count / 3];
        Array.Fill(triangles, -1);

        if (surfaces.Count == 0) return ([], triangles);

        var materials = new List<SceneMaterial>();
        var indexOf = new Dictionary<string, int>(StringComparer.Ordinal);

        foreach (var surface in surfaces)
        {
            int index = -1;

            if (surface.Material is not null)
            {
                // The same shader on two sections is one slot, not two.
                // Names repeat across packages.  An imported weapon shader and a map-local shader
                // with the same object name are distinct authored materials and may bind different
                // textures, so deduplicating by name alone silently assigns one section the other
                // package's images.  SourceFile is populated by both local and external reads.
                string materialKey = $"{surface.Material.SourceFile}|{surface.Material.Name}";
                if (!indexOf.TryGetValue(materialKey, out index))
                {
                    materials.Add(Convert(package, surface.Material, outputDirectory, bulk));
                    index = materials.Count - 1;
                    indexOf[materialKey] = index;
                }
            }

            int first = surface.FirstIndex / 3;
            int last = Math.Min(triangles.Length, (surface.FirstIndex + surface.IndexCount) / 3);
            for (int t = Math.Max(0, first); t < last; t++) triangles[t] = index;
        }

        return (materials, triangles);
    }

    private static SceneMaterial Convert(
        BioShockPackage package, BioShockMaterial material, string outputDirectory, BulkTextureCatalog? bulk)
    {
        var written = new Dictionary<string, string>(StringComparer.Ordinal);
        var files = new Dictionary<string, string>(StringComparer.Ordinal);

        // A material resolved out of another package keeps its textures there — the weapon shaders
        // and their images are both in the script packages — so the images are read from wherever
        // the material came from, not from beside the mesh.
        BioShockPackage? borrowed = null;
        if (material.SourceFile is { } file
            && !string.Equals(file, package.FilePath, StringComparison.OrdinalIgnoreCase))
        {
            try { borrowed = BioShockPackage.Open(file); }
            catch (Exception ex) when (ex is IOException or InvalidDataException) { borrowed = null; }
        }

        var source = borrowed ?? package;

        try
        {
            return Build(source, material, outputDirectory, bulk, written, files);
        }
        finally
        {
            borrowed?.Dispose();
        }
    }

    private static SceneMaterial Build(
        BioShockPackage package,
        BioShockMaterial material,
        string outputDirectory,
        BulkTextureCatalog? bulk,
        Dictionary<string, string> written,
        Dictionary<string, string> files)
    {
        var intents = new Dictionary<string, TextureIntent>(StringComparer.Ordinal);

        foreach (var texture in material.Textures)
        {
            // Intent is per binding, so it is recorded even when the image itself was already
            // written for another slot: the same file can be a base colour here and a mask there.
            var decoded = Decode(package, texture, bulk);
            if (decoded is not null) intents[texture.Slot] = TextureIntent.For(decoded, texture.Slot);

            // The same image is usually bound to several slots — the hands use Hand_DIFF as both the
            // facing and edge diffuse — so it is written once and shared.
            if (written.TryGetValue(texture.TextureName, out string? existing))
            {
                files[texture.Slot] = existing;
                continue;
            }

            string? file = decoded is null ? null : WritePng(decoded, outputDirectory);
            if (file is null) continue;

            written[texture.TextureName] = file;
            files[texture.Slot] = file;
        }

        return new SceneMaterial
        {
            Name = material.Name,
            SourceFile = material.SourceFile,
            SourceExportIndex = material.SourceExportIndex,
            ClassName = material.ClassName,
            Textures = files,
            TextureIntents = intents,
            Animators = material.Animators,
            Diffuse = Lookup(files, material.DiffuseTexture, material, "Diffuse", "FacingDiffuse", "EdgeDiffuse"),
            NormalMap = Lookup(files, material.NormalTexture, material, "NormalMap"),
            Specular = Lookup(files, material.SpecularTexture, material,
                "SpecularColorMap", "FacingSpecularColorMap", "EdgeSpecularColorMap"),
            Glossiness = material.Glossiness,
            SpecularBrightness = material.SpecularBrightness,
            EmissiveBrightness = material.EmissiveBrightness,
            DiffuseColor = ToFloats(material.DiffuseColor),
            SpecularColor = ToFloats(material.SpecularColor),
            EmissiveColor = ToFloats(material.EmissiveColor),
            TwoSided = material.TwoSided,
            Masked = material.Masked,
            UsesSpecularCubemap = material.UsesSpecularCubemap,
            SpecularCubemapBrightness = material.SpecularCubemapBrightness,
            OutputBlending = material.OutputBlending,
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

    /// <summary>
    /// Decodes the texture a binding names, without writing anything.
    /// </summary>
    /// <remarks>
    /// Split out from the write because a binding's <i>intent</i> has to be recorded even when the
    /// image was already written for an earlier slot — the same file is a base colour in one slot
    /// and a mask in another, and only the binding says which.
    /// </remarks>
    private static BioShockTexture? Decode(
        BioShockPackage package, MaterialTexture texture, BulkTextureCatalog? bulk)
    {
        var export = Resolve(package, texture);
        if (export is null) return null;

        BioShockTexture? decoded;
        try { decoded = TextureReader.Read(package, export, bulk); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }

        return decoded is null || decoded.Mips.Count == 0 ? null : decoded;
    }

    /// <summary>Writes a decoded texture beside the scene and returns its relative path.</summary>
    private static string? WritePng(BioShockTexture decoded, string outputDirectory)
    {
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
