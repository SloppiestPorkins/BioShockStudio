using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Every property a shipped texture declares, and every texture-like class the game ships,
/// censused across all packages.
/// </summary>
/// <remarks>
/// Gate 1 item 3 asks for colour-space/normal/mask/cubemap intent as UE5-facing metadata. This
/// establishes what is actually there to export before anything is written, the same way
/// <see cref="StaticMeshPropertyTests"/> did for item 1 — where the answer turned out to be that
/// half the item's subject did not exist.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class TextureIntentCensusTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>Front of an export, which is where the property list sits.</summary>
    private const int ProbeSize = 4096;

    [RequiresGameFact]
    public void CensusTextureIntent()
    {
        var classCounts = new Dictionary<string, int>(StringComparer.Ordinal);
        var propertyCounts = new Dictionary<string, int>(StringComparer.Ordinal);
        var propertyValues = new Dictionary<string, Dictionary<string, int>>(StringComparer.Ordinal);
        int textures = 0;

        // Values worth knowing the distribution of, not just the presence.
        string[] enumerated = ["LODSet", "Format", "UClampMode", "VClampMode", "CompressionSettings", "MipGenSettings"];

        foreach (string file in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(file);

            foreach (var export in package.Exports)
            {
                string className = package.GetClassName(export);

                // Everything in the BitmapMaterial branch of the tree, so a Cubemap cannot hide.
                if (className is not ("Texture" or "Cubemap" or "BitmapMaterial" or "RenderedMaterial"
                    or "ScriptedTexture" or "ShadowBitmapMaterial"))
                    continue;

                classCounts[className] = classCounts.GetValueOrDefault(className) + 1;
                if (className != "Texture") continue;
                if (export.SerialSize < 64) continue;

                var buffer = new byte[Math.Min(ProbeSize, export.SerialSize)];
                using (var stream = package.OpenExportStream(export))
                {
                    int read = stream.ReadAtLeast(buffer, buffer.Length, throwOnEndOfStream: false);
                    if (read < 64) continue;
                }

                List<UnrealProperty> properties;
                try { properties = UnrealPropertyReader.Read(buffer, package.Names, out _); }
                catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                               or ArgumentOutOfRangeException)
                {
                    continue;
                }

                textures++;
                foreach (var property in properties)
                {
                    propertyCounts[property.Name] = propertyCounts.GetValueOrDefault(property.Name) + 1;

                    // Is a serialised bool ever false? If it is, "the property is present" is not
                    // the same claim as "the flag is set", and every reader that tests presence is
                    // wrong on those textures.
                    if (property.Type == UnrealPropertyType.Bool)
                    {
                        string key = $"BOOL {property.Name} = {property.BoolValue}";
                        propertyCounts[key] = propertyCounts.GetValueOrDefault(key) + 1;
                    }

                    if (!enumerated.Contains(property.Name)) continue;

                    // Byte, not int: these are UE2 enums serialised in one byte, and AsInt()
                    // returns 0 for anything shorter than four bytes rather than failing. The first
                    // cut of this census used AsInt() and reported every Format in the game as 0,
                    // which the reader's own DXT1/DXT5/3Dc handling immediately contradicts.
                    string value = property.AsByte().ToString();

                    if (!propertyValues.TryGetValue(property.Name, out var histogram))
                        propertyValues[property.Name] = histogram = new Dictionary<string, int>(StringComparer.Ordinal);
                    histogram[value] = histogram.GetValueOrDefault(value) + 1;
                }
            }
        }

        Log($"texture-like classes shipped:");
        foreach (var (name, count) in classCounts.OrderByDescending(p => p.Value))
            Log($"    {name,-28} {count,7:N0}");

        Log($"{textures:N0} Texture exports walked; distinct property names:");
        foreach (var (name, count) in propertyCounts.OrderByDescending(p => p.Value))
            Log($"    {name,-28} {count,7:N0}");

        foreach (var (name, histogram) in propertyValues.OrderBy(p => p.Key, StringComparer.Ordinal))
        {
            Log($"  {name} values:");
            foreach (var (value, count) in histogram.OrderByDescending(p => p.Value))
                Log($"      {value,-6} {count,7:N0}");
        }

        Assert.True(textures > 1_000, $"only {textures} Texture exports were walked");

        // The item asks for "colour-space intent". The answer is that the game states none: not one
        // of the ~30,800 shipped textures declares a colour space or a compression setting, so any
        // sRGB flag an exporter emits is inferred from usage and must be labelled as such.
        foreach (string absent in new[] { "sRGB", "SRGB", "CompressionSettings", "MipGenSettings", "bSRGB" })
            Assert.False(propertyCounts.ContainsKey(absent),
                $"{absent} is declared after all, so colour space need not be inferred");

        // Cubemaps are a distinct class and they do ship. Undecoded as of 23 Aug 2026.
        Assert.True(classCounts.GetValueOrDefault("Cubemap") > 100,
            "no Cubemap exports found, so the class is not the cubemap carrier after all");

        // Addressing is declared, and only ever as "clamp" — which is why an absent property is
        // read as wrap rather than as unknown.
        Assert.True(propertyCounts.GetValueOrDefault("UClampMode") > 1_000);
        Assert.Single(propertyValues["UClampMode"]);
        Assert.True(propertyValues["UClampMode"].ContainsKey("1"));
        Assert.Single(propertyValues["VClampMode"]);
        Assert.True(propertyValues["VClampMode"].ContainsKey("1"));

        // A serialised bool is NOT necessarily true: bStreamable is written thousands of times and
        // is false on every one. Any reader testing presence instead of value is wrong.
        Assert.True(propertyCounts.GetValueOrDefault("BOOL bStreamable = False") > 1_000,
            "bStreamable is no longer serialised false, which was the proof that presence != value");
        Assert.False(propertyCounts.ContainsKey("BOOL bStreamable = True"));

        // ...whereas the three flags the exporter actually reads are true wherever they appear.
        foreach (string flag in new[] { "bMasked", "bAlphaTexture", "bTwoSided" })
            Assert.False(propertyCounts.ContainsKey($"BOOL {flag} = False"),
                $"{flag} is now serialised false somewhere, so anything reading it must use the value");

        // Format cross-checks against the reader's own enum: DXT1 dominates, 3Dc is the normal-map
        // format and is rare. If these move, either the decode or the game install has changed.
        Assert.True(propertyValues["Format"]["3"] > 20_000);
        Assert.True(propertyValues["Format"]["12"] is > 200 and < 400);
    }
}
