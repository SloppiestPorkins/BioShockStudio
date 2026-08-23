using System.Numerics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Compares single-light atlas tiles with the referenced lights' shipped colours.</summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LightmapColourCorrelationTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void SingleLightTilesDoNotTrackTheReferencedLightColour()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var model = ModelReader.BuiltWorld(package);
        Assert.NotNull(model);
        var world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex]);
        Assert.NotNull(world);

        var actors = LevelAnalyzer.Analyze(package).Actors.ToDictionary(a => a.Source.ExportIndex);
        var colourCache = new Dictionary<int, ColourResult>();
        var atlases = new Dictionary<int, (int Width, int Height, byte[] Rgba)>();

        ColourResult ActorColour(LevelActor actor)
        {
            if (colourCache.TryGetValue(actor.Source.ExportIndex, out var cached)) return cached;
            var actorExport = package.Exports[actor.Source.ExportIndex];
            var explicitProperty = actor.Properties.FirstOrDefault(p => p.Name == "LightColor");
            var property = explicitProperty
                ?? DefaultProperty(package, actorExport.ClassIndex, "LightColor", catalog, 0);
            var result = property is { Value.Length: >= 4 }
                ? new ColourResult(new Vector3(property.Value[2], property.Value[1], property.Value[0]),
                    explicitProperty is null ? "inherited" : "explicit")
                : new ColourResult(null, "unresolved");
            colourCache[actor.Source.ExportIndex] = result;
            return result;
        }

        (int Width, int Height, byte[] Rgba)? Atlas(int index)
        {
            if (atlases.TryGetValue(index, out var cached)) return cached;
            if (index < 0 || index >= world.LightMapTextures.Count) return null;
            var reference = world.LightMapTextures[index].Texture;
            if (!reference.IsExport || reference.ExportIndex >= package.Exports.Count) return null;
            var texture = TextureReader.Read(
                package, package.Exports[reference.ExportIndex], catalog.Bulk, "LightMaps_BSP");
            if (texture is null || texture.Mips.Count == 0) return null;
            var mip = texture.Mips[0];
            var decoded = (mip.Width, mip.Height,
                BlockCompression.Decode(texture.Format, mip.Data, mip.Width, mip.Height));
            atlases[index] = decoded;
            return decoded;
        }

        int single = 0, resolvedColour = 0;
        int[] singleBySlot = [0, 0, 0];
        var provenance = new Dictionary<string, int>(StringComparer.Ordinal);
        var samples = Enumerable.Range(0, 4)
            .Select(_ => new List<(Vector3 Actor, Vector3 Tile)>()).ToArray();

        foreach (var descriptor in world.LightMaps)
        foreach (var layer in descriptor.Lights)
        {
            var occupied = layer.LightActors.Where(a => !a.IsNull).ToList();
            if (occupied.Count != 1 || !occupied[0].IsExport) continue;
            single++;
            singleBySlot[layer.LightActors.ToList().FindIndex(a => !a.IsNull)]++;
            if (!actors.TryGetValue(occupied[0].ExportIndex, out var actor)) continue;
            var colour = ActorColour(actor);
            provenance[colour.Provenance] = provenance.GetValueOrDefault(colour.Provenance) + 1;
            if (colour.Value is not { } actorColour || actorColour.LengthSquared() < 1f) continue;
            resolvedColour++;
            var atlas = Atlas(layer.Atlas);
            if (atlas is null || atlas.Value.Width != 1024 || atlas.Value.Height != 1024) continue;

            Vector3 TileMean(int tileX, int tileY)
            {
                Vector3 sum = Vector3.Zero;
                int pixels = 0;
                int x1 = Math.Min(tileX + descriptor.Width, atlas.Value.Width);
                int y1 = Math.Min(tileY + descriptor.Height, atlas.Value.Height);
                for (int y = Math.Max(0, tileY); y < y1; y++)
                for (int x = Math.Max(0, tileX); x < x1; x++)
                {
                    int at = (y * atlas.Value.Width + x) * 4;
                    sum += new Vector3(atlas.Value.Rgba[at], atlas.Value.Rgba[at + 1], atlas.Value.Rgba[at + 2]);
                    pixels++;
                }
                return pixels == 0 ? Vector3.Zero : sum / pixels;
            }

            Vector3[] tiles =
            [
                TileMean(layer.TileX, layer.TileY),
                TileMean(layer.TileX, atlas.Value.Height - layer.TileY - descriptor.Height),
                TileMean(atlas.Value.Width - layer.TileX - descriptor.Width, layer.TileY),
                TileMean(atlas.Value.Width - layer.TileX - descriptor.Width,
                    atlas.Value.Height - layer.TileY - descriptor.Height),
            ];
            for (int orientation = 0; orientation < tiles.Length; orientation++)
                if (tiles[orientation].LengthSquared() >= 1f)
                    samples[orientation].Add((actorColour, tiles[orientation]));
        }

        Log($"single-light layers: {single:N0}; colours resolved: {resolvedColour:N0}");
        Log($"single export by slot: 0={singleBySlot[0]:N0}, 1={singleBySlot[1]:N0}, 2={singleBySlot[2]:N0}");
        Log($"colour provenance: {string.Join(", ", provenance.OrderBy(p => p.Key).Select(p => $"{p.Key}={p.Value:N0}"))}");
        string[] labels = ["raw X/raw Y", "raw X/flipped Y", "flipped X/raw Y", "flipped X/flipped Y"];
        int[][] permutations =
        [
            [0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0],
        ];
        for (int orientation = 0; orientation < labels.Length; orientation++)
        {
            var set = samples[orientation];
            var scored = permutations.Select(permutation =>
            {
                double matched = 0, shuffled = 0;
                int same = 0;
                for (int i = 0; i < set.Count; i++)
                {
                    var tile = Permute(set[i].Tile, permutation);
                    matched += Cosine(set[i].Actor, tile);
                    foreach (int offset in new[] { 31, 97, 211, 389 })
                        shuffled += Cosine(set[(i + offset) % set.Count].Actor, tile) / 4;
                    if (Dominant(set[i].Actor) == Dominant(tile)) same++;
                }
                return (Permutation: string.Concat(permutation.Select(p => "RGB"[p])), Same: same,
                    Matched: matched / Math.Max(1, set.Count), Shuffled: shuffled / Math.Max(1, set.Count));
            }).OrderByDescending(score => score.Matched - score.Shuffled).ToList();
            var best = scored[0];
            Log($"{labels[orientation]}: compared {set.Count:N0}; best swizzle {best.Permutation}; "
                + $"same dominant {best.Same:N0}/{set.Count:N0} ({best.Same * 100.0 / Math.Max(1, set.Count):0.0}%); "
                + $"matched cosine {best.Matched:0.000}; shuffled {best.Shuffled:0.000}; "
                + $"lift {best.Matched - best.Shuffled:+0.000;-0.000;0.000}");
        }

        Assert.True(single > 700);
        Assert.True(samples.All(sample => sample.Count > 100),
            $"too few readable samples by orientation: {string.Join(", ", samples.Select(s => s.Count))}");
        double bestLift = samples.Select(set => permutations.Max(permutation =>
        {
            double matched = 0, shuffled = 0;
            for (int i = 0; i < set.Count; i++)
            {
                var tile = Permute(set[i].Tile, permutation);
                matched += Cosine(set[i].Actor, tile);
                foreach (int offset in new[] { 31, 97, 211, 389 })
                    shuffled += Cosine(set[(i + offset) % set.Count].Actor, tile) / 4;
            }
            return (matched - shuffled) / set.Count;
        })).Max();
        Assert.True(bestLift < 0.03,
            $"an atlas orientation/channel swizzle tracked actor colour with {bestLift:0.000} cosine lift");
    }

    private static UnrealProperty? DefaultProperty(
        BioShockPackage package, PackageIndex classIndex, string name, AssetCatalogService catalog, int depth)
    {
        if (depth >= 32 || classIndex.IsNull) return null;
        if (classIndex.IsExport)
        {
            var export = package.Exports[classIndex.ExportIndex];
            var local = new ClassDefaults(package).For(export).FirstOrDefault(p => p.Name == name);
            return local ?? DefaultProperty(package, export.SuperIndex, name, catalog, depth + 1);
        }
        if (!classIndex.IsImport || classIndex.ImportIndex >= package.Imports.Count) return null;

        var import = package.Imports[classIndex.ImportIndex];
        string packageName = RootImportName(package, import.Outer);
        if (packageName.Length == 0 || !catalog.Packages.Contains(packageName, StringComparer.OrdinalIgnoreCase))
            return null;

        using var external = BioShockPackage.Open(catalog.PackageFile(packageName));
        var target = external.Exports.FirstOrDefault(e =>
            e.ObjectName == import.ObjectName && external.GetClassName(e) == "Class");
        return target is null
            ? null
            : DefaultProperty(external, new PackageIndex(target.Index + 1), name, catalog, depth + 1);
    }

    private static string RootImportName(BioShockPackage package, PackageIndex outer)
    {
        string result = string.Empty;
        for (int depth = 0; depth < 16 && outer.IsImport && outer.ImportIndex < package.Imports.Count; depth++)
        {
            var import = package.Imports[outer.ImportIndex];
            result = import.ObjectName;
            outer = import.Outer;
        }
        return result;
    }

    private static int Dominant(Vector3 value) =>
        value.X >= value.Y && value.X >= value.Z ? 0 : value.Y >= value.Z ? 1 : 2;

    private static Vector3 Permute(Vector3 value, int[] permutation)
    {
        float[] channels = [value.X, value.Y, value.Z];
        return new Vector3(channels[permutation[0]], channels[permutation[1]], channels[permutation[2]]);
    }

    private static double Cosine(Vector3 left, Vector3 right) =>
        Vector3.Dot(Vector3.Normalize(left), Vector3.Normalize(right));

    private readonly record struct ColourResult(Vector3? Value, string Provenance);
}
