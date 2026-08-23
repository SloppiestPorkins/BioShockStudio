using System.Numerics;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Rendering;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Services;

/// <summary>A level prepared for drawing, with how it was put together.</summary>
public sealed record PreparedLevel
{
    public required LevelScene Scene { get; init; }
    public required LevelViewport Viewport { get; init; }

    /// <summary>Where the camera starts: inside the level, at the densest part of it.</summary>
    public required GhostCamera Start { get; init; }

    /// <summary>
    /// The level's lights, as a renderer wants them: defaults resolved, and the ones that cannot
    /// light anything left out.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Resolving the defaults is this layer's job, not the rasteriser's.</b> A
    /// <see cref="LevelLight"/> reports what the package said, and 156 of Lighthouse's 465 lights
    /// state no brightness while 165 state no radius — the class default applies and this layer does
    /// not know it. Rather than inventing one silently, a light with no radius is <b>dropped</b>:
    /// its reach is genuinely unknown, and picking a number would put light in the level that the
    /// game may not have.
    /// </para>
    /// <para>
    /// A missing <i>brightness</i> is different and defaults to 1.0 — that is the median of the
    /// values that are stated (§C.6 gives the range as 0.0–3.1, median 1.0), so it is interpolation
    /// within measured data rather than a guess.
    /// </para>
    /// </remarks>
    public required IReadOnlyList<SceneLight> Lights { get; init; }

    public required int TexturesLoaded { get; init; }
    public required int SurfacesWithoutTexture { get; init; }
    public required int TotalSurfaces { get; init; }

    public string TextureSummary =>
        $"{TexturesLoaded:N0} textures over {TotalSurfaces - SurfacesWithoutTexture:N0} of {TotalSurfaces:N0} surfaces";
}

/// <summary>
/// Turns a level into something drawable: geometry, materials and textures, ready for a viewport.
/// </summary>
/// <remarks>
/// <para>
/// <b>Textures are resolved per asset, not per instance.</b> A map places the same mesh hundreds of
/// times and every placement shares the asset's surfaces, so the work — and the memory — is bounded
/// by the 401 distinct assets in a map rather than its 1,141 placements.
/// </para>
/// <para>
/// <b>A level's textures are capped much smaller than an asset preview's.</b> The preview caps at
/// 1024 because it is looking at one thing closely; a level holds hundreds at once and the sum is
/// what matters. At 256 the whole of <c>0-Lighthouse</c> fits in a fraction of the memory and the
/// difference is invisible at the distances a level is viewed from.
/// </para>
/// </remarks>
public sealed class LevelViewportService(AssetCatalogService catalog)
{
    /// <summary>
    /// The largest texture edge kept for a level.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Raised from 256 to 1024 after a user reported the level looking soft.</b> 256 was chosen
    /// when the level viewport drew on the CPU, where every sample is a cache miss and the whole
    /// working set has to stay small. The GPU changed that arithmetic: the textures are uploaded
    /// once and sampled by hardware, and 256 was throwing away most of the detail the game ships —
    /// its art is mostly 1024 and 2048.
    /// </para>
    /// <para>
    /// 1024 matches <c>MeshPreviewService</c>'s cap, which is the point where more stops being
    /// visible. <c>LevelTextureTests</c> reports the total decoded size so the cost of this is a
    /// measured number rather than an assumption.
    /// </para>
    /// </remarks>
    public const int MaximumTexture = 2048;

    public PreparedLevel Prepare(string packageFile, IProgress<string>? progress = null)
    {
        using var package = BioShockPackage.Open(packageFile);

        progress?.Report("Reading actors…");
        var context = LevelAnalyzer.Analyze(package);

        progress?.Report("Assembling geometry…");
        var scene = LevelSceneBuilder.Build(package, context);

        progress?.Report("Resolving materials…");
        var models = new Dictionary<string, PreviewModel>(StringComparer.Ordinal);
        var textures = new Dictionary<string, PreviewImage?>(StringComparer.OrdinalIgnoreCase);
        var borrowed = new Dictionary<string, BioShockPackage>(StringComparer.OrdinalIgnoreCase);

        int totalSurfaces = 0, withoutTexture = 0;
        var items = new List<ViewportItem>(scene.Instances.Count);

        try
        {
            foreach (var instance in scene.Instances)
            {
                // A compiled world with a package-proven atlas pool is drawn as material+atlas
                // batches. This keeps one lightmap texture per draw; forcing all of its triangles
                // through the old material-only model would bind the wrong atlas for most surfaces.
                if (instance.Kind == LevelGeometryKind.BuiltWorld && instance.LightMapBatches.Count > 0)
                {
                    var lightmapped = LightMappedWorld(package, instance, scene.Lights, textures, borrowed);
                    if (lightmapped.Count > 0)
                    {
                        foreach (var lightmappedModel in lightmapped)
                        {
                            var (lightmappedCentre, lightmappedRadius) = LevelViewport.BoundsOf(lightmappedModel.Vertices, instance.Transform);
                            items.Add(new ViewportItem(lightmappedModel, instance.Transform, lightmappedCentre, lightmappedRadius)
                            {
                                Kind = instance.Kind,
                                ActorClass = instance.Actor.ClassName,
                            });
                        }
                        continue;
                    }
                }

                if (!models.TryGetValue(instance.Asset.Key, out var model))
                {
                    var (surfaces, sizes) = Surfaces(package, instance, textures, borrowed);
                    totalSurfaces += surfaces.Count;
                    withoutTexture += surfaces.Count(s => s.Texture is null);

                    // BSP parameterises its surfaces in TEXELS — dot(v - Base, TextureU) — and the
                    // engine divides by the bound texture's size. That division can only happen once
                    // the material has resolved, which is here and not in the geometry layer.
                    // Skipping it tiles every wall hundreds of times; see BspGeometry.NormaliseUvs.
                    // It applies to the compiled world exactly as it does to a source brush.
                    //
                    // The size used is the texture's AUTHORED size, not the mip actually loaded —
                    // see Surfaces. Dividing by the loaded mip is wrong by the mip factor.
                    var geometry = instance.Kind is LevelGeometryKind.Brush or LevelGeometryKind.BuiltWorld
                        ? BspGeometry.NormaliseUvs(instance.Geometry, sizes)
                        : instance.Geometry;

                    models[instance.Asset.Key] = model = PreviewModel.Build(geometry, null, null, surfaces);

                    if (models.Count % 50 == 0) progress?.Report($"{models.Count} assets prepared…");
                }

                var (centre, radius) = LevelViewport.BoundsOf(instance.Geometry.Vertices, instance.Transform);
                items.Add(new ViewportItem(model, instance.Transform, centre, radius)
                {
                    Kind = instance.Kind,
                    ActorClass = instance.Actor.ClassName,
                });
            }
        }
        finally
        {
            foreach (var opened in borrowed.Values) opened?.Dispose();
        }

        return new PreparedLevel
        {
            Scene = scene,
            Viewport = new LevelViewport(items),
            Start = StartingCamera(items),
            Lights = ToSceneLights(scene.Lights),
            TexturesLoaded = textures.Values.Count(t => t is not null),
            SurfacesWithoutTexture = withoutTexture,
            TotalSurfaces = totalSurfaces,
        };
    }

    /// <summary>
    /// Makes the compiled world's atlas batches into preview models. A map only reaches this path
    /// after <see cref="BspWorldReader"/> has validated its <c>LightMaps_BSP</c> texture pool; an
    /// atlas that fails to decode simply leaves the old material-only world as the fallback.
    /// </summary>
    private IReadOnlyList<PreviewModel> LightMappedWorld(
        BioShockPackage package, LevelInstance world, IReadOnlyList<LevelLight> levelLights,
        Dictionary<string, PreviewImage?> textures,
        Dictionary<string, BioShockPackage> borrowed)
    {
        var result = new List<PreviewModel>(world.LightMapBatches.Count);
        var lightsByExport = levelLights.ToDictionary(light => light.Source.ExportIndex);

        foreach (var batch in world.LightMapBatches)
        {
            var material = Describe(package, batch.Material);
            var atlas = LightMapImage(package, batch.Atlas, textures);
            if (atlas is null) continue;

            var triangleLighting = batch.TriangleLightLayers.Select(layers =>
            {
                var resolved = layers.Select(layer =>
                {
                    var texture = LightMapImage(package, layer.Atlas, textures);
                    if (texture is null) return null;
                    var lights = layer.LightActors.Select(reference =>
                    {
                        if (!reference.IsExport
                            || !lightsByExport.TryGetValue(reference.ExportIndex, out var light)) return null;
                        var colour = (light.Color?.ToVector() ?? Vector3.One) * (light.Brightness ?? 1f);
                        return new PreviewBakedLight(light.Location, colour);
                    }).ToList();
                    return new PreviewBakedLightLayer(texture, layer.UvOffset, lights);
                }).Where(layer => layer is not null).Cast<PreviewBakedLightLayer>().ToList();
                return (PreviewBakedLighting?)new PreviewBakedLighting(resolved);
            }).ToList();

            var litVertices = batch.Geometry.Vertices.ToArray();
            var lit = new bool[litVertices.Length];
            for (int triangle = 0; triangle < batch.Geometry.Indices.Count / 3; triangle++)
            {
                if (triangle >= triangleLighting.Count || triangleLighting[triangle] is not { } lighting) continue;
                for (int corner = 0; corner < 3; corner++)
                {
                    int vertexIndex = batch.Geometry.Indices[triangle * 3 + corner];
                    if (lit[vertexIndex]) continue;
                    var vertex = litVertices[vertexIndex];
                    litVertices[vertexIndex] = vertex with
                    {
                        BakedLight = ComposeBakedLight(lighting, vertex.LightMapUv,
                            vertex.Position, Vector3.Normalize(vertex.Normal)),
                    };
                    lit[vertexIndex] = true;
                }
            }
            var litGeometry = batch.Geometry with { Vertices = litVertices };
            var batchInstance = world with
            {
                Geometry = litGeometry,
                Materials = [material],
                MaterialReferences = [batch.Material],
            };
            var (surfaces, sizes) = Surfaces(package, batchInstance, textures, borrowed);
            if (surfaces.Count == 0) continue;

            // A normal compiled-world model reaches NormaliseUvs in Prepare. Atlas batching was
            // bypassing that one step, leaving the BSP's texel-space UVs to be treated as
            // normalised coordinates: floors and ceilings then sampled their material at enormous
            // repeated offsets. Keep the per-atlas light data, but take the identical base-texture
            // path as the non-lightmapped world.
            var texturedGeometry = BspGeometry.NormaliseUvs(litGeometry, sizes);
            result.Add(PreviewModel.Build(texturedGeometry, null, null,
                [surfaces[0] with { LightMapTexture = atlas }], triangleLighting));
        }

        // The drawn surfaces no batch covers, unlit. Without this they are drawn by nothing at all:
        // this path replaces the material-only world entirely, so a surface missing from every batch
        // simply vanished from the level — 23,714 of 206,742 compiled-world triangles across the 20
        // maps with an atlas pool, and 49.5% of 7-BossFight. See BspGeometry.HasLightMapAtlas.
        if (result.Count > 0 && world.LightMapRemainder is { } remainder)
        {
            var remainderInstance = world with
            {
                Geometry = remainder,
                Materials = [],
                MaterialReferences = world.LightMapRemainderMaterials,
            };
            var (surfaces, sizes) = Surfaces(package, remainderInstance, textures, borrowed);
            if (surfaces.Count > 0)
                result.Add(PreviewModel.Build(
                    BspGeometry.NormaliseUvs(remainder, sizes), null, null, surfaces));
        }

        return result;
    }

    private static SourceId? Describe(BioShockPackage package, PackageIndex index)
    {
        if (!index.IsExport || index.ExportIndex >= package.Exports.Count) return null;
        var export = package.Exports[index.ExportIndex];
        return new SourceId(Path.GetFileNameWithoutExtension(package.FilePath), export.Index,
            package.GetClassName(export), export.ObjectName);
    }

    private PreviewImage? LightMapImage(
        BioShockPackage package, PackageIndex texture, Dictionary<string, PreviewImage?> textures)
    {
        if (!texture.IsExport || texture.ExportIndex >= package.Exports.Count) return null;
        string key = "lightmap:" + texture.Value;
        if (textures.TryGetValue(key, out var cached)) return cached;

        var export = package.Exports[texture.ExportIndex];
        return textures[key] = package.GetClassName(export) == TextureReader.ClassName
            ? Decode(package, export.ObjectName)
            : null;
    }

    /// <summary>
    /// Bilinear atlas lookup. Lightmap UVs point at texel centres and are already constrained to
    /// the declared tile by <see cref="BspWorld.LightMapUv"/>, so clamping here is intentional:
    /// it prevents a rounding edge from bleeding the neighbouring packed lightmap into a surface.
    /// </summary>
    private static Vector3 SampleLightMap(PreviewImage image, Vector2 uv)
    {
        float x = Math.Clamp(uv.X * image.Width - 0.5f, 0f, image.Width - 1);
        float y = Math.Clamp(uv.Y * image.Height - 0.5f, 0f, image.Height - 1);
        int x0 = (int)x, y0 = (int)y;
        int x1 = Math.Min(x0 + 1, image.Width - 1), y1 = Math.Min(y0 + 1, image.Height - 1);
        float tx = x - x0, ty = y - y0;

        Vector3 Pixel(int px, int py)
        {
            int at = (py * image.Width + px) * 4;
            return new Vector3(image.Rgba[at], image.Rgba[at + 1], image.Rgba[at + 2]) / 255f;
        }

        return Vector3.Lerp(Vector3.Lerp(Pixel(x0, y0), Pixel(x1, y0), tx),
            Vector3.Lerp(Pixel(x0, y1), Pixel(x1, y1), tx), ty);
    }

    private static Vector3 ComposeBakedLight(
        PreviewBakedLighting lighting, Vector2 primaryUv, Vector3 point, Vector3 normal)
    {
        var total = Vector3.Zero;
        foreach (var layer in lighting.Layers)
        {
            var raw = SampleLightMap(layer.Texture, primaryUv + layer.UvOffset);
            float[] luminance = [raw.Y, raw.Z, raw.X];
            for (int slot = 0; slot < Math.Min(3, layer.Lights.Count); slot++)
            {
                if (layer.Lights[slot] is not { } light) continue;
                var toLight = light.Position - point;
                float distance = toLight.Length();
                if (distance < 1e-3f) continue;
                float facing = MathF.Max(0f, Vector3.Dot(normal, toLight / distance));
                total += light.Colour * (luminance[slot] * facing);
            }
        }
        return total;
    }

    /// <summary>
    /// Turns decoded light actors into renderer lights, resolving what the package left unsaid.
    /// </summary>
    /// <remarks>
    /// See <see cref="PreparedLevel.Lights"/> for why a missing radius drops the light while a
    /// missing brightness defaults to 1.0. The white default for a missing colour is the same kind
    /// of judgement: an uncoloured light is a white light, which is what <c>LightColor</c>'s absence
    /// means in every engine of this family.
    /// </remarks>
    private static IReadOnlyList<SceneLight> ToSceneLights(IReadOnlyList<LevelLight> lights)
    {
        var result = new List<SceneLight>(lights.Count);

        foreach (var light in lights)
        {
            // No radius, no light: its reach is genuinely unknown and choosing one would put
            // illumination in the level that the game may not have.
            if (light.Radius is not { } radius || radius <= 0f) continue;

            result.Add(new SceneLight(
                light.Location,
                light.Color?.ToVector() ?? Vector3.One,
                radius,
                light.Brightness ?? 1f));
        }

        return result;
    }

    /// <summary>
    /// Where to put the camera when a level opens.
    /// </summary>
    /// <remarks>
    /// <b>The middle of the bounding box is the wrong answer</b> — a map's box is mostly empty and
    /// its centre is usually inside a wall or out over the ocean. This uses the median of the
    /// instance centres instead, which lands where the geometry actually is, and lifts the camera
    /// clear of the floor.
    /// </remarks>
    private static GhostCamera StartingCamera(IReadOnlyList<ViewportItem> items)
    {
        if (items.Count == 0) return new GhostCamera();

        var xs = items.Select(i => i.Centre.X).Order().ToList();
        var ys = items.Select(i => i.Centre.Y).Order().ToList();
        var zs = items.Select(i => i.Centre.Z).Order().ToList();

        return new GhostCamera
        {
            Position = new Vector3(xs[xs.Count / 2], ys[ys.Count / 2], zs[zs.Count / 2] + 200f),
            Yaw = 0f,
            Pitch = -0.15f,
        };
    }

    /// <summary>
    /// The surfaces one asset draws with: the section list paired with its materials, and each
    /// material's base colour decoded.
    /// </summary>
    /// <remarks>
    /// A brush's materials come from its own polygons — <see cref="BspGeometry.Materials"/> — and a
    /// static mesh's from <see cref="MeshSurfaceResolver"/>, which is the one place in the project
    /// that pairs a section with a material. Neither path invents one: a surface whose slot resolves
    /// to nothing gets a null texture and draws untextured, which is the honest signal.
    /// </remarks>
    /// <summary>
    /// The surfaces an asset draws with, and the <b>authored</b> size of each one's texture.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>The size is the texture's own <c>USize</c>/<c>VSize</c>, not the dimensions of the mip
    /// that was loaded, and the difference is the whole point of returning it separately.</b> A
    /// level caps its textures at <see cref="MaximumTexture"/> (rather than decoding every source
    /// mip at once), so a larger authored wall texture can still arrive at a smaller resident mip
    /// texture arrives as a 256-pixel image — but the game's UVs are normalised against 2048.
    /// Dividing by the loaded image's size instead tiles the surface <b>eight times too often</b>,
    /// and that is exactly the fault the first attempt at this shipped with: the tiling improved
    /// from "hundreds of times" to "several times" and still looked wrong.
    /// </para>
    /// <para>
    /// A mip is a scaled copy of the same texture and does not change its parameterisation. This is
    /// easy to get wrong precisely because the loaded image is right there and has a size on it.
    /// </para>
    /// </remarks>
    private (IReadOnlyList<PreviewSurface> Surfaces, IReadOnlyList<(int Width, int Height)?> Sizes) Surfaces(
        BioShockPackage package,
        LevelInstance instance,
        Dictionary<string, PreviewImage?> textures,
        Dictionary<string, BioShockPackage> borrowed)
    {
        var geometry = instance.Geometry;
        if (geometry.Indices.Count < 3) return ([], []);

        var sizes = new List<(int, int)?>();

        // A brush and the compiled world both carry their materials on the instance already, one per
        // section, resolved by the BSP readers. Only a static mesh needs the section table walked.
        if (instance.Kind is LevelGeometryKind.Brush or LevelGeometryKind.BuiltWorld)
        {
            var result = new List<PreviewSurface>();
            for (int i = 0; i < geometry.Sections.Count; i++)
            {
                var section = geometry.Sections[i];

                // Prefer the raw reference: it is the only form that can express an import, and a
                // compiled-world surface naming a material in another package is common. Fall back
                // to the described SourceId for anything that does not carry the raw list.
                BioShockMaterial? decoded;
                if (i < instance.MaterialReferences.Count)
                {
                    decoded = ReadMaterial(package, instance.MaterialReferences[i]);
                }
                else
                {
                    var material = i < instance.Materials.Count ? instance.Materials[i] : null;
                    decoded = material is null ? null : ReadMaterial(package, material.Value);
                }

                var diffuse = Image(package, decoded, decoded?.DiffuseTexture, textures, borrowed);

                result.Add(new PreviewSurface(
                    section.FirstIndex, section.IndexCount, decoded?.Name,
                    diffuse,
                    // BSP has a normal but no shipped tangent basis in this representation. A
                    // tangent-space map without that basis would be confidently wrong, so preserve
                    // it for export but do not feed it to the preview shader.
                    null, null)
                {
                    NoBaseColourByDesign = UnpaintedMaterials.HasNoBaseColourByDesign(decoded?.ClassName),
                    AlphaIsOpacity = AlphaIsOpacity(decoded, diffuse),
                });

                sizes.Add(AuthoredSize(package, decoded, decoded?.DiffuseTexture, borrowed));
            }
            return (result, sizes);
        }

        var export = package.Exports[instance.Asset.ExportIndex];
        var surfaces = MeshSurfaceResolver.Resolve(package, export, geometry, catalog.ExternalMaterials);

        bool hasTangentBasis = geometry.Vertices.Any(vertex =>
            vertex.Tangent.LengthSquared() > 1e-8f && vertex.Binormal.LengthSquared() > 1e-8f);

        return ([.. surfaces.Select(s =>
        {
            var diffuse = Image(package, s.Material, s.Material?.DiffuseTexture, textures, borrowed);

            return new PreviewSurface(
                s.FirstIndex, s.IndexCount, s.Material?.Name,
                diffuse,
                hasTangentBasis ? Image(package, s.Material, s.Material?.NormalTexture, textures, borrowed) : null,
                hasTangentBasis ? Image(package, s.Material, s.Material?.SpecularTexture, textures, borrowed) : null)
            {
                NoBaseColourByDesign = UnpaintedMaterials.HasNoBaseColourByDesign(s.Material?.ClassName),
                AlphaIsOpacity = AlphaIsOpacity(s.Material, diffuse),
            };
        })], sizes);
    }

    /// <summary>
    /// Whether a surface's alpha channel may be read as opacity.
    /// </summary>
    /// <remarks>
    /// Two independent signals, either of which is enough: the material declaring transparency, or
    /// the texture actually carrying cutout holes. A surface with neither has an alpha channel that
    /// means something else — a gloss or specular mask, or a "diffuse" slot that resolved to a
    /// normal map — and drawing it as opacity is what made solid props vanish in the level
    /// viewport. See <see cref="PreviewSurface.AlphaIsOpacity"/> for the measured counts.
    /// </remarks>
    private static bool AlphaIsOpacity(BioShockMaterial? material, PreviewImage? diffuse)
    {
        if (diffuse is null) return true;
        return material?.DeclaresTransparency == true || diffuse.HasCutoutHoles;
    }

    /// <summary>
    /// The size a texture declares — <c>USize</c>/<c>VSize</c> — which is what UVs are relative to.
    /// </summary>
    /// <remarks>
    /// Read from the header alone rather than by decoding the texture: the pixels are already
    /// cached elsewhere and this only needs two properties, so a full decode here would double the
    /// work for a level's several hundred textures.
    /// </remarks>
    private (int Width, int Height)? AuthoredSize(
        BioShockPackage package, BioShockMaterial? material, string? name,
        Dictionary<string, BioShockPackage> borrowed)
    {
        if (material is null || name is null) return null;

        var source = package;
        if (material.SourceFile is { } file
            && !string.Equals(file, package.FilePath, StringComparison.OrdinalIgnoreCase)
            && borrowed.TryGetValue(file, out var opened) && opened is not null)
        {
            source = opened;
        }

        var export = source.Exports
            .Where(e => e.ObjectName == name && source.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize);
        if (export is null) return null;

        try
        {
            var header = TextureReader.ReadHeader(source, export);
            return header is { Width: > 0, Height: > 0 } ? (header.Value.Width, header.Value.Height) : null;
        }
        catch (Exception ex) when (ex is IOException or InvalidDataException)
        {
            return null;
        }
    }

    private static BioShockMaterial? ReadMaterial(BioShockPackage package, SourceId material)
    {
        try { return MaterialReader.Read(package, package.Exports[material.ExportIndex]); }
        catch (Exception ex) when (ex is IOException or InvalidDataException or ArgumentOutOfRangeException)
        {
            return null;
        }
    }

    /// <summary>
    /// A BSP surface's material from the raw reference, so an <b>import</b> resolves instead of
    /// disappearing.
    /// </summary>
    /// <remarks>
    /// <b>This is the same two-branch rule <see cref="MeshSurfaceResolver"/> already applies to a
    /// mesh's slots</b>, which the BSP path never got. A compiled-world surface naming a material in
    /// another package went through <c>Describe</c>, which can only express an export, and came out
    /// null — indistinguishable from a surface that names nothing. Measured across the game:
    /// <b>1,530 of 74,091 drawn compiled-world polygons name an import and 0 name nothing</b>, so
    /// every one of those was an avoidable untextured surface rather than absent data.
    /// </remarks>
    private BioShockMaterial? ReadMaterial(BioShockPackage package, PackageIndex reference)
    {
        if (reference.IsNull) return null;

        try
        {
            if (reference.IsExport)
                return MaterialReader.Read(package, package.Exports[reference.ExportIndex]);

            if (catalog.ExternalMaterials is { } external && reference.IsImport)
            {
                var import = package.Imports[reference.ImportIndex];
                return external.Find(import.ObjectName, GroupOf(package, import.Outer));
            }
        }
        catch (Exception ex) when (ex is IOException or InvalidDataException
                                       or ArgumentOutOfRangeException or IndexOutOfRangeException)
        {
            // A shader that will not decode leaves its surface untextured and visible as such.
        }

        return null;
    }

    /// <summary>The group an import's outer names, or empty when the chain does not reach one.</summary>
    private static string GroupOf(BioShockPackage package, PackageIndex outer)
    {
        if (outer.IsImport && outer.ImportIndex < package.Imports.Count)
            return package.Imports[outer.ImportIndex].ObjectName;
        if (outer.IsExport && outer.ExportIndex < package.Exports.Count)
            return package.Exports[outer.ExportIndex].ObjectName;
        return string.Empty;
    }

    /// <summary>
    /// Decodes a material's base colour, once per texture however many surfaces bind it.
    /// </summary>
    /// <remarks>
    /// A material read from another package brings its textures with it — the shared shaders and
    /// their images both live in the script packages — so looking only beside the mesh finds
    /// nothing for 427 imported materials. The borrowed packages are opened once and closed by the
    /// caller.
    /// </remarks>
    private PreviewImage? Image(
        BioShockPackage package,
        BioShockMaterial? material,
        string? name,
        Dictionary<string, PreviewImage?> textures,
        Dictionary<string, BioShockPackage> borrowed)
    {
        if (material is null || name is null) return null;

        string key = $"{material.SourceFile}|{name}";
        if (textures.TryGetValue(key, out var cached)) return cached;

        var source = package;
        if (material.SourceFile is { } file
            && !string.Equals(file, package.FilePath, StringComparison.OrdinalIgnoreCase))
        {
            if (!borrowed.TryGetValue(file, out var opened))
            {
                try { opened = BioShockPackage.Open(file); }
                catch (Exception ex) when (ex is IOException or InvalidDataException) { opened = null!; }
                borrowed[file] = opened!;
            }
            if (opened is not null) source = opened;
        }

        return textures[key] = Decode(source, name);
    }

    private PreviewImage? Decode(BioShockPackage package, string name)
    {
        var export = package.Exports
            .Where(e => e.ObjectName == name && package.GetClassName(e) == TextureReader.ClassName)
            .MaxBy(e => e.SerialSize);
        if (export is null) return null;

        BioShockTexture? texture;
        try { texture = TextureReader.Read(package, export, catalog.Bulk); }
        catch (Exception ex) when (ex is IOException or InvalidDataException or NotSupportedException)
        {
            return null;
        }

        if (texture is null || texture.Mips.Count == 0) return null;

        // The largest mip within the cap, so a 2048 texture costs what a 256 does.
        int index = 0;
        for (int i = 0; i < texture.Mips.Count; i++)
        {
            if (Math.Max(texture.Mips[i].Width, texture.Mips[i].Height) <= MaximumTexture) { index = i; break; }
            index = i;
        }

        var mip = texture.Mips[index];
        try
        {
            var rgba = BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height);
            return rgba is null ? null : new PreviewImage(mip.Width, mip.Height, rgba);
        }
        catch (Exception ex) when (ex is NotSupportedException or InvalidDataException
                                       or IndexOutOfRangeException or ArgumentOutOfRangeException)
        {
            return null;
        }
    }
}
