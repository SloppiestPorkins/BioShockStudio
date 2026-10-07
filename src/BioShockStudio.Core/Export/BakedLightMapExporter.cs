using System.Globalization;
using System.Numerics;
using System.Text;
using System.Text.Json;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Export;

/// <summary>
/// Composites BioShock's per-channel baked BSP lightmaps into RGB atlases and writes a two-UV
/// glTF of the compiled world that matches the BuiltWorld OBJ export.
/// </summary>
/// <remarks>
/// Shading matches <c>LevelViewportService.ComposeBakedLight</c>: sample each layer at
/// <c>primaryUv + UvOffset</c>, unswizzle atlas channels as <c>.yzx</c>, and accumulate
/// <c>lightColour * luminance[slot] * max(0, N·L)</c>. <see cref="BspGeometry.LightMapLayer.UvOffset"/>
/// is in normalised atlas units (tile delta / 1024), not texels — see
/// <see cref="BspGeometry.ToLightMapBatches"/>.
/// </remarks>
public static class BakedLightMapExporter
{
    /// <summary>
    /// Fallback multiplier when a map has no lit texels to measure. Medical's measured p75 of
    /// lit max(R,G,B) lands near 0.37 before scaling; 1.75 maps that to ~0.65 with a few percent
    /// of bright texels clipping — mid-range for typical lit samples.
    /// </summary>
    public const float GlobalScale = 1.75f;

    private const float AtlasSize = 1024f;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public sealed record AtlasSummary(
        int AtlasIndex,
        int Width,
        int Height,
        int Surfaces,
        float LitTexelPercent,
        float ClipPercent,
        float Scale);

    public sealed record ExportSummary(
        string Package,
        string Model,
        float Scale,
        float ClipPercent,
        IReadOnlyList<AtlasSummary> Atlases,
        int VertexCount,
        int TriangleCount,
        IReadOnlyList<string> Files);

    public sealed record ExportResult(ExportSummary Summary, string Directory);

    /// <summary>Exports baked RGB lightmaps and a two-UV glTF for the package's compiled world.</summary>
    public static ExportResult Export(
        BioShockPackage package,
        string outputDirectory,
        BulkTextureCatalog? bulk = null)
    {
        Directory.CreateDirectory(outputDirectory);

        var context = LevelAnalyzer.Analyze(package);
        var scene = LevelSceneBuilder.Build(package, context);
        var built = scene.Instances.FirstOrDefault(i => i.Kind == LevelGeometryKind.BuiltWorld)
            ?? throw new InvalidDataException($"{context.PackageName}: no compiled world.");

        var model = ModelReader.BuiltWorld(package)
            ?? throw new InvalidDataException($"{context.PackageName}: BuiltWorld model missing.");
        var world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex])
            ?? throw new InvalidDataException($"{context.PackageName}: compiled world would not decode.");

        var lightsByExport = scene.Lights.ToDictionary(light => light.Source.ExportIndex);
        var atlasImages = DecodeAtlases(package, world, bulk);
        var origins = BspTextureOrigin.Resolve(package, world, context);

        var floatAtlases = new Dictionary<int, float[]>();
        var atlasSizes = new Dictionary<int, (int Width, int Height)>();
        var surfaceCounts = new Dictionary<int, int>();
        var litCounts = new Dictionary<int, int>();
        var tileTexelCounts = new Dictionary<int, int>();

        foreach (var node in world.Nodes.Where(n => n.IsPolygon && BspGeometry.HasLightMapAtlas(world, n)))
        {
            var descriptor = world.LightMaps[node.LightMap];
            if (descriptor.Lights.Count == 0) continue;
            var primary = descriptor.Lights[0];
            int atlasIndex = primary.Atlas;
            if (!atlasImages.TryGetValue(atlasIndex, out var primaryImage)) continue;

            if (!floatAtlases.TryGetValue(atlasIndex, out var buffer))
            {
                buffer = new float[primaryImage.Width * primaryImage.Height * 3];
                floatAtlases[atlasIndex] = buffer;
                atlasSizes[atlasIndex] = (primaryImage.Width, primaryImage.Height);
                surfaceCounts[atlasIndex] = 0;
                litCounts[atlasIndex] = 0;
                tileTexelCounts[atlasIndex] = 0;
            }

            surfaceCounts[atlasIndex]++;
            var normal = Vector3.Normalize(node.Plane.Normal);
            if (normal.LengthSquared() < 1e-8f) continue;

            for (int iy = 0; iy < descriptor.Height; iy++)
            for (int ix = 0; ix < descriptor.Width; ix++)
            {
                int atlasX = primary.TileX + ix;
                int atlasY = primary.TileY + iy;
                if (atlasX < 0 || atlasY < 0 || atlasX >= primaryImage.Width || atlasY >= primaryImage.Height)
                    continue;

                tileTexelCounts[atlasIndex]++;
                if (!TryUnprojectTexel(descriptor, primary, ix, iy, node, out var studioPoint))
                    continue;

                var primaryUv = new Vector2(
                    (atlasX + 0.5f) / AtlasSize,
                    (atlasY + 0.5f) / AtlasSize);

                var colour = ComposeBakedLight(
                    world, descriptor, primary, primaryUv, studioPoint, normal,
                    atlasImages, lightsByExport);

                int pixel = (atlasY * primaryImage.Width + atlasX) * 3;
                // Overlapping tiles (rare) keep the brighter sample rather than summing twice.
                buffer[pixel] = MathF.Max(buffer[pixel], colour.X);
                buffer[pixel + 1] = MathF.Max(buffer[pixel + 1], colour.Y);
                buffer[pixel + 2] = MathF.Max(buffer[pixel + 2], colour.Z);
                if (colour.X > 0f || colour.Y > 0f || colour.Z > 0f)
                    litCounts[atlasIndex]++;
            }
        }

        float scale = ChooseScale(floatAtlases.Values);
        var files = new List<string>();
        long clipped = 0, writtenTexels = 0;
        var atlasSummaries = new List<AtlasSummary>();

        foreach (var (atlasIndex, buffer) in floatAtlases.OrderBy(kv => kv.Key))
        {
            var (width, height) = atlasSizes[atlasIndex];
            var rgba = new byte[width * height * 4];
            for (int i = 0, p = 0; i < buffer.Length; i += 3, p += 4)
            {
                writtenTexels++;
                float r = buffer[i] * scale;
                float g = buffer[i + 1] * scale;
                float b = buffer[i + 2] * scale;
                if (r > 1f || g > 1f || b > 1f) clipped++;
                rgba[p] = ToByte(r);
                rgba[p + 1] = ToByte(g);
                rgba[p + 2] = ToByte(b);
                rgba[p + 3] = 255;
            }

            string stem = $"baked_{atlasIndex}";
            string pngPath = Path.Combine(outputDirectory, stem + ".png");
            PngWriter.Write(pngPath, rgba, width, height);
            files.Add(pngPath);

            int tileTexels = Math.Max(1, tileTexelCounts[atlasIndex]);
            float litPercent = 100f * litCounts[atlasIndex] / tileTexels;
            float atlasClip = 100f * CountClipped(buffer, scale) / Math.Max(1, width * height);
            var atlasJson = new
            {
                atlasIndex,
                width,
                height,
                scale,
                surfaces = surfaceCounts[atlasIndex],
                litTexelPercent = litPercent,
                clipPercent = atlasClip,
            };
            string jsonPath = Path.Combine(outputDirectory, stem + ".json");
            File.WriteAllText(jsonPath, JsonSerializer.Serialize(atlasJson, JsonOptions));
            files.Add(jsonPath);

            atlasSummaries.Add(new AtlasSummary(
                atlasIndex, width, height, surfaceCounts[atlasIndex], litPercent, atlasClip, scale));
        }

        var objGeometry = LevelSceneExporter.AssetObjGeometry(package, built);
        var (gltfPath, binPath, vertexCount, triangleCount) = WriteGltf(
            package, world, built, origins, objGeometry, outputDirectory, floatAtlases.Keys.ToHashSet());
        files.Add(gltfPath);
        files.Add(binPath);

        float totalClip = writtenTexels == 0 ? 0f : 100f * clipped / writtenTexels;
        var summary = new ExportSummary(
            context.PackageName,
            model.Source.ObjectName,
            scale,
            totalClip,
            atlasSummaries,
            vertexCount,
            triangleCount,
            files);

        string summaryPath = Path.Combine(outputDirectory, "baked_lightmaps.json");
        File.WriteAllText(summaryPath, JsonSerializer.Serialize(new
        {
            package = summary.Package,
            model = summary.Model,
            scale = summary.Scale,
            clipPercent = summary.ClipPercent,
            vertexCount = summary.VertexCount,
            triangleCount = summary.TriangleCount,
            atlases = atlasSummaries.Select(a => new
            {
                a.AtlasIndex,
                a.Width,
                a.Height,
                a.Surfaces,
                a.LitTexelPercent,
                a.ClipPercent,
                a.Scale,
            }),
        }, JsonOptions));
        files.Add(summaryPath);

        Console.Error.WriteLine(
            $"baked lightmaps: scale={scale.ToString("0.###", CultureInfo.InvariantCulture)} "
            + $"clip={totalClip.ToString("0.##", CultureInfo.InvariantCulture)}% "
            + $"atlases={atlasSummaries.Count}");

        return new ExportResult(summary with { Files = files }, outputDirectory);
    }

    /// <summary>
    /// Picks a global scale so the 75th percentile of lit texel peak channels lands near 0.65.
    /// Falls back to <see cref="GlobalScale"/> when there is nothing to measure.
    /// </summary>
    private static float ChooseScale(IEnumerable<float[]> atlases)
    {
        var peaks = new List<float>();
        foreach (var buffer in atlases)
        {
            for (int i = 0; i < buffer.Length; i += 3)
            {
                float peak = MathF.Max(buffer[i], MathF.Max(buffer[i + 1], buffer[i + 2]));
                if (peak > 1e-6f) peaks.Add(peak);
            }
        }

        if (peaks.Count == 0) return GlobalScale;
        peaks.Sort();
        float p75 = peaks[(int)((peaks.Count - 1) * 0.75)];
        if (p75 < 1e-6f) return GlobalScale;
        float scale = 0.65f / p75;
        return Math.Clamp(scale, 0.25f, 8f);
    }

    /// <summary>
    /// Confirms <see cref="BspLightMap.WorldToLightMap"/> is applied as a row-vector transform on
    /// game-space positions (after reversing the studio Y reflection), and that plane-constrained
    /// unprojection round-trips within half a texel.
    /// </summary>
    public static (int Checked, int ForwardOk, int InverseOk) ProbeMatrixConvention(BspWorld world, int sampleLimit = 2_000)
    {
        int checkedCount = 0, forwardOk = 0, inverseOk = 0;
        foreach (var node in world.Nodes.Where(n => n.IsPolygon && BspGeometry.HasLightMapAtlas(world, n)))
        {
            var descriptor = world.LightMaps[node.LightMap];
            var primary = descriptor.Lights[0];
            foreach (var position in world.PolygonOf(node))
            {
                if (checkedCount >= sampleLimit) return (checkedCount, forwardOk, inverseOk);
                checkedCount++;

                var expected = world.LightMapUv(node, position, primary);
                var game = GameBasis.Convert(position);
                var projected = Vector4.Transform(new Vector4(game, 1f), descriptor.WorldToLightMap);
                var forward = new Vector2(
                    (projected.X * descriptor.Width + primary.TileX + 0.5f) / AtlasSize,
                    (projected.Y * descriptor.Height + primary.TileY + 0.5f) / AtlasSize);
                if (Vector2.Distance(forward, expected) * AtlasSize <= 0.5f) forwardOk++;

                float ix = projected.X * descriptor.Width;
                float iy = projected.Y * descriptor.Height;
                if (!TryUnprojectProjected(descriptor, ix, iy, node, out var recovered)) continue;
                var roundTrip = world.LightMapUv(node, recovered, primary);
                if (Vector2.Distance(roundTrip, expected) * AtlasSize <= 0.5f) inverseOk++;
            }
        }

        return (checkedCount, forwardOk, inverseOk);
    }

    private static Dictionary<int, AtlasImage> DecodeAtlases(
        BioShockPackage package, BspWorld world, BulkTextureCatalog? bulk)
    {
        var result = new Dictionary<int, AtlasImage>();
        for (int i = 0; i < world.LightMapTextures.Count; i++)
        {
            var reference = world.LightMapTextures[i].Texture;
            if (!reference.IsExport || reference.ExportIndex >= package.Exports.Count) continue;
            var export = package.Exports[reference.ExportIndex];
            if (package.GetClassName(export) != TextureReader.ClassName) continue;

            BioShockTexture? texture;
            try { texture = TextureReader.Read(package, export, bulk); }
            catch (Exception ex) when (ex is IOException or InvalidDataException or NotSupportedException)
            {
                continue;
            }

            if (texture is null || texture.Mips.Count == 0) continue;
            var mip = texture.Mips[0];
            byte[] rgba;
            try { rgba = BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height); }
            catch (Exception ex) when (ex is NotSupportedException or InvalidDataException
                                           or IndexOutOfRangeException or ArgumentOutOfRangeException)
            {
                continue;
            }

            result[i] = new AtlasImage(mip.Width, mip.Height, rgba);
        }

        return result;
    }

    private static Vector3 ComposeBakedLight(
        BspWorld world,
        BspLightMap descriptor,
        BspLightMapLight primary,
        Vector2 primaryUv,
        Vector3 point,
        Vector3 normal,
        IReadOnlyDictionary<int, AtlasImage> atlases,
        IReadOnlyDictionary<int, LevelLight> lightsByExport)
    {
        var total = Vector3.Zero;
        foreach (var layer in descriptor.Lights)
        {
            if (layer.Atlas < 0 || layer.Atlas >= world.LightMapTextures.Count) continue;
            if (!atlases.TryGetValue(layer.Atlas, out var image)) continue;

            var uvOffset = new Vector2(layer.TileX - primary.TileX, layer.TileY - primary.TileY) / AtlasSize;
            var raw = SampleLightMap(image, primaryUv + uvOffset);
            float[] luminance = [raw.Y, raw.Z, raw.X];

            for (int slot = 0; slot < Math.Min(3, layer.LightActors.Count); slot++)
            {
                var reference = layer.LightActors[slot];
                if (!reference.IsExport
                    || !lightsByExport.TryGetValue(reference.ExportIndex, out var light)) continue;

                var colour = (light.Color?.ToVector() ?? Vector3.One) * (light.Brightness ?? 1f);
                var toLight = light.Location - point;
                float distance = toLight.Length();
                if (distance < 1e-3f) continue;
                float facing = MathF.Max(0f, Vector3.Dot(normal, toLight / distance));
                total += colour * (luminance[slot] * facing);
            }
        }

        return total;
    }

    private static Vector3 SampleLightMap(AtlasImage image, Vector2 uv)
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

    /// <summary>
    /// Recovers the studio-space point on the node's plane whose lightmap projection is the centre
    /// of tile texel (<paramref name="ix"/>, <paramref name="iy"/>).
    /// </summary>
    /// <remarks>
    /// <see cref="BspWorld.LightMapUv"/> builds atlas UVs as
    /// <c>(projected.X * Width + TileX + 0.5) / 1024</c> with
    /// <c>projected = Transform(gamePos, WorldToLightMap)</c> (row-vector). Texel centres therefore
    /// correspond to <c>projected.XY = ((ix+0.5)/Width, (iy+0.5)/Height)</c>. The matrix alone is
    /// under-determined in depth, so the node's plane closes the system.
    /// </remarks>
    private static bool TryUnprojectTexel(
        BspLightMap descriptor, BspLightMapLight primary, int ix, int iy, BspNode node, out Vector3 studioPoint) =>
        TryUnprojectProjected(descriptor, ix + 0.5f, iy + 0.5f, node, out studioPoint);

    private static bool TryUnprojectProjected(
        BspLightMap descriptor, float tileX, float tileY, BspNode node, out Vector3 studioPoint)
    {
        studioPoint = default;
        float u = tileX / descriptor.Width;
        float v = tileY / descriptor.Height;
        var m = descriptor.WorldToLightMap;

        // Studio plane: Normal·X + D = 0 with D = -distance. Converted normal keeps the same D
        // because GameBasis is an involution: gameNormal·gamePos = studioNormal·studioPos = -D.
        var gameNormal = GameBasis.Convert(node.Plane.Normal);
        if (gameNormal.LengthSquared() < 1e-10f) return false;
        gameNormal = Vector3.Normalize(gameNormal);
        float planeD = -node.Plane.D;

        // Row-vector: projected.XY = Transform(gamePos, M).XY. Close depth with the plane.
        var a = new Matrix4x4(
            m.M11, m.M12, gameNormal.X, 0f,
            m.M21, m.M22, gameNormal.Y, 0f,
            m.M31, m.M32, gameNormal.Z, 0f,
            0f, 0f, 0f, 1f);
        if (!Matrix4x4.Invert(a, out var inv)) return false;

        var game = Vector3.Transform(new Vector3(u - m.M41, v - m.M42, planeD), inv);
        studioPoint = GameBasis.Convert(game);
        return float.IsFinite(studioPoint.X) && float.IsFinite(studioPoint.Y) && float.IsFinite(studioPoint.Z);
    }

    private static (string GltfPath, string BinPath, int VertexCount, int TriangleCount) WriteGltf(
        BioShockPackage package,
        BspWorld world,
        LevelInstance built,
        IReadOnlyList<Vector3?> origins,
        MeshGeometry objGeometry,
        string outputDirectory,
        HashSet<int> writtenAtlases)
    {
        var batches = BspGeometry.ToLightMapBatches(world, origins);
        var primitives = new List<GltfPrimitiveBuild>();

        foreach (var batch in batches)
        {
            int atlasIndex = IndexOfAtlas(world, batch.Atlas);
            var size = AuthoredSizeFor(package, batch.Material);
            var geometry = BspGeometry.NormaliseUvs(batch.Geometry, [size]);
            string? materialName = DescribeMaterial(package, batch.Material);
            primitives.Add(new GltfPrimitiveBuild(
                geometry,
                materialName,
                batch.Material.IsExport ? batch.Material.ExportIndex : null,
                atlasIndex >= 0 && writtenAtlases.Contains(atlasIndex) ? $"baked_{atlasIndex}.png" : null,
                Lightmapped: true));
        }

        if (built.LightMapRemainder is { } remainder && remainder.Indices.Count >= 3)
        {
            var remainderMaterials = built.LightMapRemainderMaterials
                .Select(m => DescribeSource(package, m))
                .ToList();
            var remainderInstance = built with
            {
                Geometry = remainder,
                Materials = remainderMaterials,
                MaterialReferences = built.LightMapRemainderMaterials,
            };
            var geometry = LevelSceneExporter.AssetObjGeometry(package, remainderInstance);
            // One primitive per section so material extras stay honest.
            for (int s = 0; s < geometry.Sections.Count; s++)
            {
                var section = geometry.Sections[s];
                var sliced = SliceSection(geometry, section);
                var materialRef = s < built.LightMapRemainderMaterials.Count
                    ? built.LightMapRemainderMaterials[s]
                    : default;
                primitives.Add(new GltfPrimitiveBuild(
                    sliced,
                    DescribeMaterial(package, materialRef),
                    materialRef.IsExport ? materialRef.ExportIndex : null,
                    null,
                    Lightmapped: false));
            }
        }

        int vertexCount = primitives.Sum(p => p.Geometry.Vertices.Count);
        int triangleCount = primitives.Sum(p => p.Geometry.Indices.Count / 3);

        // Prefer the OBJ geometry totals when the remainder path did not fire (no lightmaps): the
        // single BuiltWorld OBJ is the contract. When batches exist, batches+remainder cover the
        // same drawn triangles as the OBJ; assert equality in tests.
        if (primitives.Count == 0)
        {
            primitives.Add(new GltfPrimitiveBuild(objGeometry, null, null, null, false));
            vertexCount = objGeometry.Vertices.Count;
            triangleCount = objGeometry.Indices.Count / 3;
        }

        string modelName = built.Asset.ObjectName;
        string binName = modelName + ".bin";
        string gltfName = modelName + ".gltf";
        var (bin, gltfJson) = BuildGltfDocuments(modelName, binName, primitives);

        string binPath = Path.Combine(outputDirectory, binName);
        string gltfPath = Path.Combine(outputDirectory, gltfName);
        File.WriteAllBytes(binPath, bin);
        File.WriteAllText(gltfPath, gltfJson);
        return (gltfPath, binPath, vertexCount, triangleCount);
    }

    private static (byte[] Bin, string Json) BuildGltfDocuments(
        string modelName, string binName, IReadOnlyList<GltfPrimitiveBuild> primitives)
    {
        using var bin = new MemoryStream();
        var accessors = new List<object>();
        var bufferViews = new List<object>();
        var gltfPrimitives = new List<object>();
        int accessorIndex = 0;

        foreach (var primitive in primitives)
        {
            var geometry = primitive.Geometry;
            int vertexCount = geometry.Vertices.Count;
            var positions = new float[vertexCount * 3];
            var normals = new float[vertexCount * 3];
            var uv0 = new float[vertexCount * 2];
            var uv1 = new float[vertexCount * 2];
            float minX = float.MaxValue, minY = float.MaxValue, minZ = float.MaxValue;
            float maxX = float.MinValue, maxY = float.MinValue, maxZ = float.MinValue;

            for (int i = 0; i < vertexCount; i++)
            {
                var v = geometry.Vertices[i];
                positions[i * 3] = v.Position.X;
                positions[i * 3 + 1] = v.Position.Y;
                positions[i * 3 + 2] = v.Position.Z;
                normals[i * 3] = v.Normal.X;
                normals[i * 3 + 1] = v.Normal.Y;
                normals[i * 3 + 2] = v.Normal.Z;
                // No V flip: glTF, D3D and UE all put V=0 at the top of the texture. (The OBJ writer
                // flips because OBJ does not; copying that flip here put the Medical wall's trim band
                // at the wrong height - live comparison, 7 Oct 2026.)
                uv0[i * 2] = v.Uv.X;
                uv0[i * 2 + 1] = v.Uv.Y;
                uv1[i * 2] = v.LightMapUv.X;
                uv1[i * 2 + 1] = v.LightMapUv.Y;
                minX = MathF.Min(minX, v.Position.X); maxX = MathF.Max(maxX, v.Position.X);
                minY = MathF.Min(minY, v.Position.Y); maxY = MathF.Max(maxY, v.Position.Y);
                minZ = MathF.Min(minZ, v.Position.Z); maxZ = MathF.Max(maxZ, v.Position.Z);
            }

            var indices = geometry.Indices.Select(i => (uint)i).ToArray();

            int AddView(ReadOnlySpan<byte> data, int target)
            {
                Align(bin, 4);
                int offset = (int)bin.Position;
                bin.Write(data);
                bufferViews.Add(new { buffer = 0, byteOffset = offset, byteLength = data.Length, target });
                return bufferViews.Count - 1;
            }

            int posView = AddView(MemoryMarshalAsBytes(positions), 34962);
            int nrmView = AddView(MemoryMarshalAsBytes(normals), 34962);
            int uv0View = AddView(MemoryMarshalAsBytes(uv0), 34962);
            int uv1View = AddView(MemoryMarshalAsBytes(uv1), 34962);
            int idxView = AddView(MemoryMarshalAsBytes(indices), 34963);

            int posAcc = accessorIndex++;
            accessors.Add(new
            {
                bufferView = posView,
                componentType = 5126,
                count = vertexCount,
                type = "VEC3",
                max = new[] { maxX, maxY, maxZ },
                min = new[] { minX, minY, minZ },
            });
            int nrmAcc = accessorIndex++;
            accessors.Add(new { bufferView = nrmView, componentType = 5126, count = vertexCount, type = "VEC3" });
            int uv0Acc = accessorIndex++;
            accessors.Add(new { bufferView = uv0View, componentType = 5126, count = vertexCount, type = "VEC2" });
            int uv1Acc = accessorIndex++;
            accessors.Add(new { bufferView = uv1View, componentType = 5126, count = vertexCount, type = "VEC2" });
            int idxAcc = accessorIndex++;
            accessors.Add(new { bufferView = idxView, componentType = 5125, count = indices.Length, type = "SCALAR" });

            gltfPrimitives.Add(new
            {
                attributes = new Dictionary<string, int>
                {
                    ["POSITION"] = posAcc,
                    ["NORMAL"] = nrmAcc,
                    ["TEXCOORD_0"] = uv0Acc,
                    ["TEXCOORD_1"] = uv1Acc,
                },
                indices = idxAcc,
                extras = new
                {
                    materialKey = primitive.MaterialExportIndex is { } idx ? idx.ToString(CultureInfo.InvariantCulture) : null,
                    material = primitive.MaterialName,
                    bakedAtlas = primitive.BakedAtlas,
                },
            });
        }

        var root = new
        {
            asset = new { version = "2.0", generator = "BioShockStudio baked-lightmaps" },
            buffers = new[] { new { uri = binName, byteLength = bin.Length } },
            bufferViews,
            accessors,
            meshes = new[] { new { name = modelName, primitives = gltfPrimitives } },
            nodes = new[] { new { mesh = 0, name = modelName } },
            scenes = new[] { new { nodes = new[] { 0 } } },
            scene = 0,
        };

        return (bin.ToArray(), JsonSerializer.Serialize(root, new JsonSerializerOptions
        {
            WriteIndented = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull,
        }));
    }

    private static MeshGeometry SliceSection(MeshGeometry geometry, MeshSection section)
    {
        var remap = new Dictionary<int, int>();
        var vertices = new List<MeshVertex>();
        var indices = new List<int>();
        int end = section.FirstIndex + section.TriangleCount * 3;
        for (int i = section.FirstIndex; i < end && i < geometry.Indices.Count; i++)
        {
            int old = geometry.Indices[i];
            if (!remap.TryGetValue(old, out int mapped))
            {
                mapped = vertices.Count;
                remap[old] = mapped;
                vertices.Add(geometry.Vertices[old]);
            }
            indices.Add(mapped);
        }

        return new MeshGeometry
        {
            Vertices = vertices,
            Indices = indices,
            BoneMap = [],
            SkinnedVertexCount = 0,
            RigidVertexCount = vertices.Count,
            Sections = [new MeshSection(0, 0, vertices.Count - 1, indices.Count / 3)],
        };
    }

    private static int IndexOfAtlas(BspWorld world, PackageIndex texture)
    {
        for (int i = 0; i < world.LightMapTextures.Count; i++)
            if (world.LightMapTextures[i].Texture == texture) return i;
        return -1;
    }

    private static string? DescribeMaterial(BioShockPackage package, PackageIndex material)
    {
        if (!material.IsExport || material.ExportIndex >= package.Exports.Count) return null;
        return package.Exports[material.ExportIndex].ObjectName;
    }

    private static SourceId? DescribeSource(BioShockPackage package, PackageIndex material)
    {
        if (!material.IsExport || material.ExportIndex >= package.Exports.Count) return null;
        var export = package.Exports[material.ExportIndex];
        return new SourceId(
            Path.GetFileNameWithoutExtension(package.FilePath),
            material.ExportIndex,
            package.GetClassName(export),
            export.ObjectName);
    }

    private static (int Width, int Height)? AuthoredSizeFor(BioShockPackage package, PackageIndex material)
    {
        if (!material.IsExport || material.ExportIndex >= package.Exports.Count) return null;
        var export = package.Exports[material.ExportIndex];
        var id = new SourceId(
            Path.GetFileNameWithoutExtension(package.FilePath),
            material.ExportIndex,
            package.GetClassName(export),
            export.ObjectName);
        return LevelSceneExporter.AuthoredTextureSize(package, id);
    }

    private static void Align(Stream stream, int alignment)
    {
        int pad = (int)((alignment - (stream.Position % alignment)) % alignment);
        for (int i = 0; i < pad; i++) stream.WriteByte(0);
    }

    private static byte[] MemoryMarshalAsBytes<T>(T[] data) where T : unmanaged
    {
        var bytes = new byte[data.Length * System.Runtime.CompilerServices.Unsafe.SizeOf<T>()];
        System.Buffer.BlockCopy(data, 0, bytes, 0, bytes.Length);
        return bytes;
    }

    private static byte ToByte(float value) =>
        (byte)Math.Clamp((int)MathF.Round(Math.Clamp(value, 0f, 1f) * 255f), 0, 255);

    private static int CountClipped(float[] buffer, float scale)
    {
        int clipped = 0;
        for (int i = 0; i < buffer.Length; i += 3)
        {
            if (buffer[i] * scale > 1f || buffer[i + 1] * scale > 1f || buffer[i + 2] * scale > 1f)
                clipped++;
        }
        return clipped;
    }

    private sealed record AtlasImage(int Width, int Height, byte[] Rgba);

    private sealed record GltfPrimitiveBuild(
        MeshGeometry Geometry,
        string? MaterialName,
        int? MaterialExportIndex,
        string? BakedAtlas,
        bool Lightmapped);
}
