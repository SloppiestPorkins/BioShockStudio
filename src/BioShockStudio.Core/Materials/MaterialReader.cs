using System.Buffers.Binary;
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
    /// The package file this material was read from.
    /// </summary>
    /// <remarks>
    /// A mesh often names a material that lives somewhere else — every NPC weapon points at the
    /// viewmodel's shader in <c>ShockGame.U</c>, every security camera at <c>ShockAI.U</c> — and
    /// <b>the textures live with the material, not with the mesh</b>. Across the game 427 imported
    /// materials name a diffuse texture and <b>none</b> of those textures is in the mesh's own
    /// package. A caller that looks for them beside the mesh finds nothing and draws grey, so the
    /// material has to say where it came from.
    /// </remarks>
    public string? SourceFile { get; init; }

    /// <summary>Zero-based export-table identity in <see cref="SourceFile"/>.</summary>
    /// <remarks>
    /// Names repeat both within and across packages. Keeping the original table identity lets an
    /// importer update the same authored UE5 material on a later run instead of using a name match.
    /// </remarks>
    public required int SourceExportIndex { get; init; }

    /// <summary>
    /// The base colour texture, whichever slot the shader class puts it in.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Each material class names it differently — <c>FacingShader</c> has no <c>Diffuse</c> at all,
    /// <c>PlantShader</c> calls it <c>AliveDiffuse</c>, <c>FluidShader</c> <c>WaterDiffuseMap</c> —
    /// so the known names are tried first and then any bound slot whose name contains "Diffuse".
    /// </para>
    /// <para>
    /// <b>There is deliberately no "first texture" fallback.</b> A material whose slots are all
    /// unrecognised returns null and the surface is reported as having no base colour, because
    /// picking arbitrarily would put a normal map on the mesh as its colour — a confidently wrong
    /// result that renders as a blue-purple surface and passes every count.
    /// </para>
    /// </remarks>
    public string? DiffuseTexture
    {
        get
        {
            foreach (string slot in MaterialReader.DiffuseSlots)
                if (TextureFor(slot) is { } named) return named;

            return Textures
                .FirstOrDefault(t => t.Slot.Contains("Diffuse", StringComparison.OrdinalIgnoreCase))
                ?.TextureName;
        }
    }

    /// <summary>Tangent-space normal map, including class-specific shader slot names.</summary>
    public string? NormalTexture => TextureFor("NormalMap") ?? TextureFor("AliveNormalMap");

    public string? SpecularTexture =>
        TextureFor("SpecularColorMap") ?? TextureFor("FacingSpecularColorMap") ?? TextureFor("EdgeSpecularColorMap")
        ?? TextureFor("AliveSpecularColorMap");

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
    /// <summary>
    /// Export classes that were originally observed in mesh slots. Kept as a discovery aid; slot
    /// validation itself must not be limited to this early sample (see <see cref="IsMaterialClass"/>).
    /// </summary>
    public static readonly string[] ClassNames = ["Shader", "FacingShader", "TerrainShader", "WaterShader"];

    /// <summary>
    /// Shader properties that bind a texture.
    /// <para>
    /// The <c>Facing*</c> and <c>Edge*</c> slots belong to <c>FacingShader</c>, which is what the
    /// first-person hands actually use: it has no plain <c>Diffuse</c>, so a reader that only knew
    /// the <c>Shader</c> slots would report the hands as having a material and no diffuse texture.
    /// </para>
    /// </summary>
    /// <summary>
    /// Slot names known to carry a base colour, in preference order.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Only used to decide which of a material's bound textures is <i>the</i> base colour. Which
    /// slots exist at all is not a list any more — see <see cref="Read"/>.
    /// </para>
    /// <para>
    /// <c>CONFIRMED_EXTERNAL</c> for <c>Diffuse</c> (Nyko's material note, §2.1) and
    /// <c>CONFIRMED_BYTES</c> for the rest, each read off a shipped material of that class:
    /// <c>FacingShader</c> has no <c>Diffuse</c> at all, <c>PlantShader</c> calls it
    /// <c>AliveDiffuse</c>, and <c>FluidShader</c> calls it <c>WaterDiffuseMap</c>.
    /// </para>
    /// </remarks>
    internal static readonly string[] DiffuseSlots =
    [
        "Diffuse", "FacingDiffuse", "EdgeDiffuse", "AliveDiffuse", "DeadDiffuse", "WaterDiffuseMap",
        SelfSlot,
    ];

    /// <summary>The class of a material that is itself a texture — the <c>BitmapMaterial</c> branch.</summary>
    private const string BitmapMaterialClass = "Texture";

    /// <summary>
    /// The slot a <see cref="BitmapMaterialClass"/> material binds itself under. Not a property name
    /// the data declares — such a material has no texture properties, it <i>is</i> the texture.
    /// </summary>
    public const string SelfSlot = "Self";

    /// <summary>
    /// The block that separates a <c>SkeletalMesh</c>'s bounds from its material list:
    /// <c>int32 4, int32 5</c>. Its position varies between meshes — 64 in <c>NEWPlayerHands</c>,
    /// 54 in <c>WP_PistolMesh</c> — so it is searched for rather than assumed.
    /// </summary>
    /// <remarks>
    /// What follows was recorded as a fixed <c>byte 1</c> and a single reference. It is not: it is an
    /// <c>FCompactIndex</c> count and that many references. Meshes with two materials read 2 there —
    /// <c>TommyGunMESH</c> and <c>PlasmidEquipMESH</c> both do — and reading the count as part of a
    /// fixed tag meant their second material was never seen.
    /// </remarks>
    private static readonly byte[] TagBlock = [4, 0, 0, 0, 5, 0, 0, 0];

    /// <summary>More materials than this on one mesh means the count was misread.</summary>
    private const int MaximumMaterials = 16;

    /// <summary>How far into a payload the tag block is looked for.</summary>
    private const int TagBlockSearchLimit = 256;

    /// <summary>
    /// Whether an object is a direct rendered material that a mesh slot may name.
    /// </summary>
    /// <remarks>
    /// BioShock's shipped mesh slots name class-specific shaders such as <c>PlantShader</c>,
    /// <c>FluidShader</c> and <c>LightBeamShader</c>, not only the four classes first sampled for
    /// <see cref="ClassNames"/>. All have the same ordinary tagged-property container, so rejecting
    /// a <c>*Shader</c> here leaves a verified base colour unbound before <see cref="Read"/> even
    /// gets a chance to decode it. Compound material nodes (<c>MaterialSwitch</c>,
    /// <c>MaterialSequence</c>) intentionally remain outside this predicate until their child
    /// selection semantics are byte-backed.  <c>MaterialSwitch</c> is an exception: each shipped
    /// switch has a direct <c>Material</c> property naming its declared default child, so that
    /// child is safe to follow while the candidate-array selection semantics remain preserved as
    /// unresolved data.
    /// </remarks>
    public static bool IsMaterialClass(string className) =>
        className == BitmapMaterialClass
        || className == "MaterialSwitch"
        || className.EndsWith("Shader", StringComparison.Ordinal);

    /// <summary>
    /// Reads the material reference out of a mesh payload, or null when the tag block is not found or
    /// the reference does not resolve to a material.
    /// </summary>
    public static PackageIndex? ReadMeshMaterialReference(ReadOnlySpan<byte> payload, BioShockPackage package) =>
        ReadMeshMaterialReferences(payload, package).FirstOrDefault(r => r.IsExport || r.IsImport) is { } first
        && first.Value != 0
            ? first
            : null;

    /// <summary>
    /// Reads a mesh's material list. Empty when the tag block is not found or nothing after it names
    /// a material.
    /// </summary>
    /// <remarks>
    /// Slots that name nothing are dropped, so this list cannot be indexed by a section ordinal.
    /// Use <see cref="ReadMeshMaterialSlots"/> for that.
    /// </remarks>
    public static IReadOnlyList<PackageIndex> ReadMeshMaterialReferences(
        ReadOnlySpan<byte> payload, BioShockPackage package) =>
        [.. ReadMeshMaterialSlots(payload, package).Where(r => r.IsExport || r.IsImport)];

    /// <summary>
    /// Reads a mesh's material list <b>at its own slot positions</b>, with a null
    /// <see cref="PackageIndex"/> where a slot names nothing.
    /// </summary>
    /// <remarks>
    /// This is the list a section table indexes: the Nth <c>MeshSection</c> uses the Nth entry here.
    /// Compacting the list — which is what <see cref="ReadMeshMaterialReferences"/> does — shifts
    /// every slot after an empty one, so a mesh whose first slot is null would draw its second
    /// section with its third material. See <c>docs/research/staticmesh.md</c>.
    /// </remarks>
    public static IReadOnlyList<PackageIndex> ReadMeshMaterialSlots(
        ReadOnlySpan<byte> payload, BioShockPackage package)
    {
        // A StaticMesh says it outright, in a property. Only a SkeletalMesh, whose property list is
        // empty, needs the tag-block search below.
        if (ReadMaterialsProperty(payload, package) is { Count: > 0 } declared) return declared;

        int limit = Math.Min(TagBlockSearchLimit, payload.Length - TagBlock.Length);

        for (int at = 0; at < limit; at++)
        {
            if (!payload.Slice(at, TagBlock.Length).SequenceEqual(TagBlock)) continue;

            int offset = at + TagBlock.Length;
            var references = new List<PackageIndex>();

            try
            {
                int count = ReadCompactIndex(payload, ref offset);
                if (count is <= 0 or > MaximumMaterials) return [];

                for (int i = 0; i < count; i++)
                {
                    var reference = new PackageIndex(ReadCompactIndex(payload, ref offset));
                    if (!NamesAMaterial(package, reference)) return references;
                    references.Add(reference);
                }
            }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
            {
                return references;
            }

            return references;
        }

        return [];
    }

    /// <summary>
    /// Reads a <c>StaticMesh</c>'s <c>Materials</c> property. Empty when there is no such property,
    /// which is every <c>SkeletalMesh</c>.
    /// </summary>
    /// <remarks>
    /// <b>CONFIRMED_BYTES.</b> <c>Materials</c> is an array of <c>FStaticMeshMaterial</c>, and each
    /// element is itself a property list — the game names its own fields:
    /// <code>
    /// FCompactIndex count
    /// per element:
    ///   EnableCollision   Bool     value carried in the info byte's array bit, no payload
    ///   Material          Object   FCompactIndex reference to a Shader or FacingShader
    ///   None                       terminator
    /// </code>
    /// <para>
    /// The array's declared size is **one byte short of its content**, so the last element's
    /// terminator is cut off. That is the same off-by-one <c>MaskMaterial</c> shows, and this is the
    /// second independent case of it: both contain a nested property carrying an explicit size byte.
    /// The walk therefore treats running out of bytes as the end of an element rather than an error.
    /// </para>
    /// <para>
    /// This is what took textured meshes from 7% of the game to most of it. The previous search
    /// looked for the skeletal tag block <c>4, 5, 1</c>, and a static mesh's is <c>4, 8, 1</c> with
    /// no reference after it, so it found nothing and 2,354 meshes drew flat grey.
    /// </para>
    /// </remarks>
    private static IReadOnlyList<PackageIndex> ReadMaterialsProperty(
        ReadOnlySpan<byte> payload, BioShockPackage package)
    {
        List<UnrealProperty> properties;
        try { properties = UnrealPropertyReader.Read(payload, package.Names, out _, out _); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return [];
        }

        var array = properties.FirstOrDefault(p =>
            p.Name == "Materials" && p.Type == UnrealPropertyType.Array);
        if (array is null) return [];

        var value = (ReadOnlySpan<byte>)array.Value;
        int offset = 0;

        int count;
        try { count = ReadCompactIndex(value, ref offset); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return [];
        }

        if (count is <= 0 or > MaximumMaterials) return [];

        // The array's own count is what the sections index, so the list is that long whether or not
        // every element can be read. A slot left null is a slot whose material is not known; it is
        // never closed up, because compacting would shift every later section onto the wrong
        // material. Nothing is invented — an unread slot stays null.
        var result = new PackageIndex[count];

        for (int i = 0; i < count && offset < value.Length; i++)
        {
            if (!TryReadMaterialElement(value, ref offset, package, out var reference)) break;
            result[i] = reference;
        }

        return result;
    }

    /// <summary>
    /// Walks one <c>FStaticMeshMaterial</c> element and returns the reference its <c>Material</c>
    /// field holds.
    /// </summary>
    /// <returns>
    /// True when the element was walked to its end, so <paramref name="offset"/> is positioned on the
    /// next one — including when the element named no material, which is a real empty slot. False
    /// means alignment was lost and nothing after this point can be trusted.
    /// </returns>
    private static bool TryReadMaterialElement(
        ReadOnlySpan<byte> value, ref int offset, BioShockPackage package, out PackageIndex reference)
    {
        reference = default;

        // Bounded: a misread element must not spin.
        for (int guard = 0; guard < 16; guard++)
        {
            // The array's declared size is one byte short of its content, so the last element's
            // terminator is cut off. Running out here is the end of a complete element, not a fault.
            if (offset >= value.Length) return true;

            int nameIndex;
            try { nameIndex = ReadCompactIndex(value, ref offset); }
            catch { return false; }

            if (offset + 4 > value.Length) return true;
            offset += 4; // FName number

            if (nameIndex < 0 || nameIndex >= package.Names.Count) return false;
            if (package.Names[nameIndex].Name == "None") return true;

            if (offset >= value.Length) return true;
            byte info = value[offset++];
            var type = (UnrealPropertyType)(info & 0x0F);
            int sizeEncoding = (info >> 4) & 0x07;
            bool isArray = (info & 0x80) != 0;

            if (type == UnrealPropertyType.Struct)
            {
                try { ReadCompactIndex(value, ref offset); } catch { return false; }
                if (offset + 4 > value.Length) return false;
                offset += 4;
            }

            int size;
            try
            {
                size = sizeEncoding switch
                {
                    0 => 1,
                    1 => 2,
                    2 => 4,
                    3 => 12,
                    4 => 16,
                    5 => value[offset++],
                    6 => BinaryPrimitives.ReadUInt16LittleEndian(Advance(value, ref offset, 2)),
                    _ => BinaryPrimitives.ReadInt32LittleEndian(Advance(value, ref offset, 4)),
                };
            }
            catch { return false; }

            // A Bool carries its value in the array bit and has no payload.
            if (isArray && type != UnrealPropertyType.Bool)
            {
                try { ReadCompactIndex(value, ref offset); } catch { return false; }
            }

            if (size < 0 || offset + size > value.Length) return false;

            if (reference.IsNull && type == UnrealPropertyType.Object
                && package.Names[nameIndex].Name == "Material")
            {
                int cursor = offset;
                try { reference = new PackageIndex(ReadCompactIndex(value, ref cursor)); }
                catch { /* leave it unread rather than guessing */ }
            }

            offset += size;
        }

        // Sixteen properties without a terminator is not an element this reader understands.
        return false;
    }

    private static ReadOnlySpan<byte> Advance(ReadOnlySpan<byte> value, ref int offset, int count)
    {
        var slice = value[offset..];
        offset += count;
        return slice;
    }

    /// <summary>The material a mesh export uses, or null when it does not resolve to one in this package.</summary>
    public static BioShockMaterial? ReadForMesh(BioShockPackage package, ObjectExport mesh)
    {
        if (mesh.SerialSize <= 0) return null;

        var reference = ReadMeshMaterialReference(package.ReadExportData(mesh), package);
        if (reference is not { IsExport: true } index) return null;

        return Read(package, package.Exports[index.ExportIndex]);
    }

    public static BioShockMaterial? Read(BioShockPackage package, ObjectExport export) =>
        Read(package, export, new HashSet<int>());

    /// <summary>Reads a rendered material, following a switch's explicit default child at most once per export.</summary>
    private static BioShockMaterial? Read(BioShockPackage package, ObjectExport export, HashSet<int> visited)
    {
        if (export.SerialSize <= 0 || !visited.Add(export.Index)) return null;

        byte[] payload = package.ReadExportData(export);
        List<UnrealProperty> properties;
        bool truncated;
        try { properties = UnrealPropertyReader.Read(payload, package.Names, out _, out truncated); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }

        string sourceFile = package.FilePath;
        string className = package.GetClassName(export);

        // A MaterialSwitch is a modifier, not the shader that ultimately renders.  Its Materials
        // array describes candidates whose runtime selection still needs a dedicated decode, but
        // the separate Material object property is the authored default child.  Following that
        // explicit reference improves static reconstruction without guessing how a live switch
        // chooses among candidates.  MaterialSequence deliberately does not enter this branch:
        // it only serialises SequenceItems structs, whose timing/selection semantics are unknown.
        if (className == "MaterialSwitch")
        {
            var selected = properties.FirstOrDefault(property =>
                property.Name == "Material" && property.Type == UnrealPropertyType.Object);
            if (selected is not null && TryReadObjectReference(selected, out var reference)
                && reference.IsExport && reference.ExportIndex < package.Exports.Count)
            {
                // The default child is not guaranteed to be a class this reader knows how to parse
                // as a shader — a switch can name something like ZoningOnlyBrushMaterial, whose
                // layout is unrelated. Reading it anyway with the generic tagged-property walk below
                // misinterprets its own Object properties (e.g. a self-reference) as texture slots.
                var childExport = package.Exports[reference.ExportIndex];
                if (IsMaterialClass(package.GetClassName(childExport)))
                {
                    var child = Read(package, childExport, visited);
                    if (child is not null) return child;
                }
            }
        }

        var textures = new List<MaterialTexture>();
        var unhandled = new List<string>();

        // A Texture IS a material — the BitmapMaterial branch of the class tree — and the surface it
        // draws is itself, through MaterialFactory_BitmapMaterial ("diffuse + alpha straight from one
        // texture"). 162 meshes in the game name a Texture in a material slot rather than a shader;
        // reading one as if it were a Shader finds no Object properties and reports a material that
        // binds nothing, and the mesh draws flat with its own texture sitting right there.
        // Bioshock1REMSDK-WIP--main/docs/reverse-engineering/BioShock_Materials_And_Shaders.md §1.
        if (className == BitmapMaterialClass)
        {
            textures.Add(new MaterialTexture
            {
                // Named for what it is rather than for a property that does not exist: the binding
                // is the object itself, not a slot it declares.
                Slot = SelfSlot,
                TextureName = export.ObjectName,
                Reference = new PackageIndex(export.Index + 1),
            });
        }

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

            // A texture binding is an Object property whose reference resolves to a Texture. It is
            // NOT a property whose name is on a list: the list held thirteen names and the game ships
            // at least nine material classes, each with its own — PlantShader binds AliveDiffuse,
            // FluidShader WaterDiffuseMap, LightBeamShader FalloffMap and DustMap — so 522 meshes
            // resolved a material that appeared to bind nothing and drew flat.
            //
            // The class check is what makes this safe rather than greedy: a FluidShader also carries
            // Object properties naming TextureRotator and TexturePanner objects, which are UV
            // modifiers and not textures, and those resolve to nothing here. See
            // Bioshock1REMSDK-WIP--main/docs/reverse-engineering/BioShock_Materials_And_Shaders.md §2.
            if (property.Type == UnrealPropertyType.Object)
            {
                var texture = ReadTexture(package, property);
                if (texture is not null) { textures.Add(texture); continue; }
            }

            unhandled.Add(property.Name);
        }

        return new BioShockMaterial
        {
            Name = export.ObjectName,
            ClassName = className,
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
            SourceFile = sourceFile,
            SourceExportIndex = export.Index,
        };
    }

    private static MaterialTexture? ReadTexture(BioShockPackage package, UnrealProperty property)
    {
        if (!TryReadObjectReference(property, out var reference)) return null;
        string? name = ResolveName(package, reference, "Texture");
        if (name is null) return null;

        return new MaterialTexture { Slot = property.Name, TextureName = name, Reference = reference };
    }

    private static bool TryReadObjectReference(UnrealProperty property, out PackageIndex reference)
    {
        reference = default;
        int offset = 0;
        try
        {
            reference = new PackageIndex(ReadCompactIndex(property.Value, ref offset));
            return true;
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return false;
        }
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
