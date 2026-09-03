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
    /// Resolves a material directly from its own export — a <c>Shader</c>/<c>FacingShader</c>/etc.
    /// export, not a mesh that names one. For a level's placed geometry, which already knows each
    /// section's material export identity directly (<see cref="Level.LevelInstance.Materials"/>)
    /// rather than needing to look it up via a mesh.
    /// </summary>
    public static SceneMaterial? ResolveMaterial(
        BioShockPackage package, ObjectExport materialExport, string outputDirectory, BulkTextureCatalog? bulk = null)
    {
        var material = MaterialReader.Read(package, materialExport);
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
            Sequences = material.Sequences,
            SwitchName = material.SwitchName,
            SwitchCandidates = material.SwitchCandidates,
            // MaterialReader.DiffuseSlots itself, not a copy of it. This was a second hand-kept
            // list of the same slot names, and the two drifting is silent: DiffuseTexture picks a
            // slot, this resolves that slot to a written file, and a name in one list but not the
            // other yields no base colour with nothing logged. Sharing the array makes adding a
            // shader class a one-place change.
            Diffuse = Lookup(files, material.DiffuseTexture, material, MaterialReader.DiffuseSlots),
            NormalMap = Lookup(files, material.NormalTexture, material, "NormalMap"),
            Specular = Lookup(files, material.SpecularTexture, material,
                "SpecularColorMap", "FacingSpecularColorMap", "EdgeSpecularColorMap"),
            // Only export an Opacity binding the UE5 side can safely consume as a single-channel
            // BLEND_MASKED cutout -- see UsableAsOpacityMask. A BioShock `Opacity` MaskMaterial
            // often points at a PACKED texture (AlphaSpecGloss), the material's own glass diffuse,
            // or a specular map, and carries a channel selector this pipeline does not decode yet.
            // Feeding one of those in as an R-channel mask forced glass, damaged ceilings and wall
            // panels to BLEND_MASKED and cut them apart wherever the colour was dark.
            Opacity = UsableAsOpacityMask(
                Lookup(files, material.OpacityTexture, material, "Opacity"),
                Lookup(files, material.DiffuseTexture, material, MaterialReader.DiffuseSlots),
                material.Masked),
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


    /// <summary>
    /// True when a resolved <c>Opacity</c> mask file is safe to hand the UE5 importer as a
    /// single-channel <c>BLEND_MASKED</c> cutout.
    /// </summary>
    /// <remarks>
    /// A BioShock <c>Opacity</c> <c>MaskMaterial</c> is not always a cutout. Measured on 1-Medical:
    /// <c>marble_ceiling_damage2_diffuse_shader</c> points it at
    /// <c>marble_ceiling_damage2_AlphaSpecGloss</c> (a packed spec/gloss map), and
    /// <c>Exterior_Window_Glass_Shader</c> points it at the window's own diffuse. The struct
    /// carries a channel selector (R/G/B/A) that is not decoded yet, so the importer always samples
    /// R -- correct for a grey single-channel mask like <c>bloodsplat3opa</c>, garbage for a packed
    /// or colour texture. Until the channel is read, only pass the unambiguous cutouts through: the
    /// material's own <c>bMasked</c> flag (the game says it is a cutout), or a filename that says
    /// so, and never a packed / colour / data map.
    /// </remarks>
    internal static string? UsableAsOpacityMask(string? opacityFile, string? diffuseFile, bool masked)
    {
        if (opacityFile is null) return null;
        if (string.Equals(opacityFile, diffuseFile, StringComparison.OrdinalIgnoreCase)) return null;

        string stem = Path.GetFileNameWithoutExtension(opacityFile);
        bool Has(string token) => stem.Contains(token, StringComparison.OrdinalIgnoreCase);

        // A packed, colour or data map -- never a pure coverage mask, whatever its other name parts.
        if (Has("specgloss") || Has("_spec") || Has("specular") || Has("_diffuse") || Has("_diff")
            || Has("_normal") || Has("_nor") || Has("height"))
            return null;

        bool nameSaysMask =
            stem.EndsWith("opa", StringComparison.OrdinalIgnoreCase)
            || stem.EndsWith("_o", StringComparison.OrdinalIgnoreCase)
            || Has("opacity") || Has("_mask") || Has("_masks") || Has("_alpha") || Has("cutout");

        return (masked || nameSaysMask) ? opacityFile : null;
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
    public static string? WritePng(BioShockTexture decoded, string outputDirectory)
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
