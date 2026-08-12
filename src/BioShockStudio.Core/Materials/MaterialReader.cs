using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Materials;

/// <summary>One texture a material binds, and the slot it binds it to.</summary>
public sealed record MaterialTexture
{
    /// <summary>The shader property, e.g. <c>Diffuse</c>, <c>NormalMap</c>, <c>SpecularColorMap</c>.</summary>
    public required string Slot { get; init; }

    public required string TextureName { get; init; }

    /// <summary>The reference as stored, so a caller can follow it back to the export.</summary>
    public required PackageIndex Reference { get; init; }

    /// <summary>True when the texture lives in another package and only its name is available here.</summary>
    public bool IsExternal => Reference.IsImport;

    public override string ToString() => $"{Slot} = {TextureName}";
}

/// <summary>A colour as a shader stores it: four bytes, blue first.</summary>
public readonly record struct MaterialColor(byte R, byte G, byte B, byte A)
{
    public override string ToString() => $"#{R:X2}{G:X2}{B:X2}{A:X2}";
}

/// <summary>A decoded <c>Shader</c> object.</summary>
public sealed record BioShockMaterial
{
    public required string Name { get; init; }

    /// <summary>Shader class — <c>Shader</c>, <c>FacingShader</c> and so on.</summary>
    public required string ClassName { get; init; }

    public required IReadOnlyList<MaterialTexture> Textures { get; init; }

    public float? Glossiness { get; init; }
    public float? SpecularBrightness { get; init; }
    public float? EmissiveBrightness { get; init; }
    public MaterialColor? DiffuseColor { get; init; }
    public MaterialColor? SpecularColor { get; init; }
    public MaterialColor? EmissiveColor { get; init; }
    public bool TwoSided { get; init; }
    public bool Masked { get; init; }

    /// <summary>Blend mode. UNKNOWN: what its values mean; carried through rather than interpreted.</summary>
    public byte? OutputBlending { get; init; }

    /// <summary>
    /// Properties present on the object but not interpreted, by name. Kept so a reader can see what
    /// was dropped rather than assuming the decode was complete.
    /// </summary>
    public required IReadOnlyList<string> UnhandledProperties { get; init; }

    /// <summary>
    /// True when the property walk lost alignment before the list ended, so the material is partial.
    /// Reported rather than hidden: a partial material is not a complete one.
    /// </summary>
    public required bool Truncated { get; init; }

    /// <summary>
    /// The base colour texture, whichever slot the shader class puts it in. <c>FacingShader</c> has
    /// no <c>Diffuse</c>; its base colour is the facing one, with the edge texture as the fallback.
    /// </summary>
    public string? DiffuseTexture =>
        TextureFor("Diffuse") ?? TextureFor("FacingDiffuse") ?? TextureFor("EdgeDiffuse");

    public string? NormalTexture => TextureFor("NormalMap");

    public string? SpecularTexture =>
        TextureFor("SpecularColorMap") ?? TextureFor("FacingSpecularColorMap") ?? TextureFor("EdgeSpecularColorMap");

    public string? TextureFor(string slot) =>
        Textures.FirstOrDefault(t => string.Equals(t.Slot, slot, StringComparison.OrdinalIgnoreCase))?.TextureName;

    public override string ToString() => $"{ClassName} {Name} ({Textures.Count} textures)";
}

/// <summary>
/// Reads BioShock's material objects, and resolves the material a <c>SkeletalMesh</c> uses.
/// </summary>
/// <remarks>
/// <para>
/// A <c>Shader</c> is an ordinary Unreal property list, so it needs no new container work: the
/// texture bindings are <c>Object</c> properties naming <c>Texture</c> exports or imports directly.
/// </para>
/// <para>
/// The mesh side is the part that had to be found. A <c>SkeletalMesh</c>'s own property list is
/// empty — it carries only the <c>CheckpointTypePadding</c> tag every export has — so the reference
/// lives in the binary payload, in the <c>FCompactIndex</c> immediately after the fixed tag block
/// that <c>docs/research/skeletalmesh.md</c> had recorded as unexplained.
/// </para>
/// </remarks>
public static class MaterialReader
{
    /// <summary>Export classes that are materials.</summary>
    public static readonly string[] ClassNames = ["Shader", "FacingShader", "TerrainShader", "WaterShader"];

    /// <summary>
    /// Shader properties that bind a texture.
    /// <para>
    /// The <c>Facing*</c> and <c>Edge*</c> slots belong to <c>FacingShader</c>, which is what the
    /// first-person hands actually use: it has no plain <c>Diffuse</c>, so a reader that only knew
    /// the <c>Shader</c> slots would report the hands as having a material and no diffuse texture.
    /// </para>
    /// </summary>
    private static readonly string[] TextureSlots =
    [
        "Diffuse", "NormalMap", "SpecularColorMap", "Emissive", "Subsurface", "Opacity", "Detail",
        "FacingDiffuse", "EdgeDiffuse", "FacingSpecularColorMap", "EdgeSpecularColorMap",
        "FacingEmissive", "EdgeEmissive",
    ];

    /// <summary>
    /// The block that separates a <c>SkeletalMesh</c>'s bounds from its material reference:
    /// <c>int32 4, int32 5, byte 1</c>. Its position varies between meshes — 64 in
    /// <c>NEWPlayerHands</c>, 54 in <c>WP_PistolMesh</c> — so it is searched for rather than assumed.
    /// </summary>
    private static readonly byte[] TagBlock = [4, 0, 0, 0, 5, 0, 0, 0, 1];

    /// <summary>How far into a payload the tag block is looked for.</summary>
    private const int TagBlockSearchLimit = 256;

    public static bool IsMaterialClass(string className) => ClassNames.Contains(className, StringComparer.Ordinal);

    /// <summary>
    /// Reads the material reference out of a mesh payload, or null when the tag block is not found or
    /// the reference does not resolve to a material.
    /// </summary>
    public static PackageIndex? ReadMeshMaterialReference(ReadOnlySpan<byte> payload, BioShockPackage package)
    {
        int limit = Math.Min(TagBlockSearchLimit, payload.Length - TagBlock.Length);
        for (int at = 0; at < limit; at++)
        {
            if (!payload.Slice(at, TagBlock.Length).SequenceEqual(TagBlock)) continue;

            int offset = at + TagBlock.Length;
            int value;
            try { value = ReadCompactIndex(payload, ref offset); }
            catch (InvalidDataException) { return null; }

            var reference = new PackageIndex(value);
            return NamesAMaterial(package, reference) ? reference : null;
        }

        return null;
    }

    /// <summary>The material a mesh export uses, or null when it does not resolve to one in this package.</summary>
    public static BioShockMaterial? ReadForMesh(BioShockPackage package, ObjectExport mesh)
    {
        if (mesh.SerialSize <= 0) return null;

        var reference = ReadMeshMaterialReference(package.ReadExportData(mesh), package);
        if (reference is not { IsExport: true } index) return null;

        return Read(package, package.Exports[index.ExportIndex]);
    }

    public static BioShockMaterial? Read(BioShockPackage package, ObjectExport export)
    {
        if (export.SerialSize <= 0) return null;

        byte[] payload = package.ReadExportData(export);
        List<UnrealProperty> properties;
        bool truncated;
        try { properties = UnrealPropertyReader.Read(payload, package.Names, out _, out truncated); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }

        var textures = new List<MaterialTexture>();
        var unhandled = new List<string>();

        float? glossiness = null, specularBrightness = null, emissiveBrightness = null;
        MaterialColor? diffuseColor = null, specularColor = null, emissiveColor = null;
        bool twoSided = false, masked = false;
        byte? outputBlending = null;

        foreach (var property in properties)
        {
            switch (property.Name)
            {
                case "Glossiness" or "FacingGlossiness": glossiness = property.AsFloat(); continue;
                case "SpecularBrightness" or "FacingSpecularBrightness":
                    specularBrightness = property.AsFloat(); continue;
                case "EmissiveBrightness" or "EdgeEmissiveBrightness":
                    emissiveBrightness = property.AsFloat(); continue;
                case "DiffuseColor": diffuseColor = ReadColor(property); continue;
                case "SpecularColor": specularColor = ReadColor(property); continue;
                case "EmissiveColor" or "EdgeEmissiveColor": emissiveColor = ReadColor(property); continue;
                case "TwoSided": twoSided = true; continue;
                case "Masked": masked = true; continue;
                case "OutputBlending": outputBlending = property.AsByte(); continue;

                // Every export carries this tag; it is not part of the material.
                case "CheckpointTypePadding": continue;
            }

            if (property.Type == UnrealPropertyType.Object && TextureSlots.Contains(property.Name, StringComparer.Ordinal))
            {
                var texture = ReadTexture(package, property);
                if (texture is not null) { textures.Add(texture); continue; }
            }

            unhandled.Add(property.Name);
        }

        return new BioShockMaterial
        {
            Name = export.ObjectName,
            ClassName = package.GetClassName(export),
            Textures = textures,
            Glossiness = glossiness,
            SpecularBrightness = specularBrightness,
            EmissiveBrightness = emissiveBrightness,
            DiffuseColor = diffuseColor,
            SpecularColor = specularColor,
            EmissiveColor = emissiveColor,
            TwoSided = twoSided,
            Masked = masked,
            OutputBlending = outputBlending,
            UnhandledProperties = unhandled,
            Truncated = truncated,
        };
    }

    private static MaterialTexture? ReadTexture(BioShockPackage package, UnrealProperty property)
    {
        int offset = 0;
        int value;
        try { value = ReadCompactIndex(property.Value, ref offset); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }

        var reference = new PackageIndex(value);
        string? name = ResolveName(package, reference, "Texture");
        if (name is null) return null;

        return new MaterialTexture { Slot = property.Name, TextureName = name, Reference = reference };
    }

    private static bool NamesAMaterial(BioShockPackage package, PackageIndex reference)
    {
        if (reference.IsExport)
        {
            if (reference.ExportIndex >= package.Exports.Count) return false;
            return IsMaterialClass(package.GetClassName(package.Exports[reference.ExportIndex]));
        }

        if (reference.IsImport)
        {
            if (reference.ImportIndex >= package.Imports.Count) return false;
            return IsMaterialClass(package.Imports[reference.ImportIndex].ClassName);
        }

        return false;
    }

    /// <summary>Resolves a reference to an object name, checking the class rather than trusting the slot.</summary>
    private static string? ResolveName(BioShockPackage package, PackageIndex reference, string expectedClass)
    {
        if (reference.IsExport && reference.ExportIndex < package.Exports.Count)
        {
            var export = package.Exports[reference.ExportIndex];
            return package.GetClassName(export) == expectedClass ? export.ObjectName : null;
        }

        if (reference.IsImport && reference.ImportIndex < package.Imports.Count)
        {
            var import = package.Imports[reference.ImportIndex];
            return import.ClassName == expectedClass ? import.ObjectName : null;
        }

        return null;
    }

    /// <summary>A <c>Color</c> struct is four bytes stored blue first.</summary>
    private static MaterialColor? ReadColor(UnrealProperty property) =>
        property.Value.Length < 4
            ? null
            : new MaterialColor(property.Value[2], property.Value[1], property.Value[0], property.Value[3]);

    private static int ReadCompactIndex(ReadOnlySpan<byte> data, ref int offset)
    {
        byte b = data[offset++];
        bool negative = (b & 0x80) != 0;
        int value = b & 0x3F;

        if ((b & 0x40) != 0)
        {
            int shift = 6;
            while (true)
            {
                byte c = data[offset++];
                value |= (c & 0x7F) << shift;
                shift += 7;
                if ((c & 0x80) == 0) break;
                if (shift > 31) throw new InvalidDataException("FCompactIndex overflow.");
            }
        }

        return negative ? -value : value;
    }
}
