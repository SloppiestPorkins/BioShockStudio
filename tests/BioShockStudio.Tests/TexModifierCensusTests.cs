using BioShockStudio.Core.Game;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// What a material's object properties point at when they are not textures.
/// </summary>
/// <remarks>
/// Gate 1 item 4's "panners/rotators". Censused by following what materials actually reference
/// rather than by looking for class names taken from UModel — the game may ship modifiers that no
/// reference project names, and may ship none of the ones they do.
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class TexModifierCensusTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void CensusWhatMaterialsPointAt()
    {
        var targetClasses = new Dictionary<string, int>(StringComparer.Ordinal);
        var slotsByClass = new Dictionary<string, HashSet<string>>(StringComparer.Ordinal);
        var propertiesByClass = new Dictionary<string, Dictionary<string, int>>(StringComparer.Ordinal);

        foreach (string mapFile in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(mapFile);

            foreach (var export in package.Exports)
            {
                if (!MaterialReader.IsMaterialClass(package.GetClassName(export))) continue;

                List<UnrealProperty> properties;
                try { properties = UnrealPropertyReader.Read(package.ReadExportData(export), package.Names, out _); }
                catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                               or ArgumentOutOfRangeException)
                {
                    continue;
                }

                foreach (var property in properties)
                {
                    if (property.Type != UnrealPropertyType.Object) continue;
                    if (!property.TryAsObjectReference(out var reference)) continue;
                    if (!reference.IsExport || reference.ExportIndex >= package.Exports.Count) continue;

                    var target = package.Exports[reference.ExportIndex];
                    string className = package.GetClassName(target);

                    // Textures and cubemaps are already understood; this is about everything else.
                    if (className is "Texture" or "Cubemap") continue;

                    targetClasses[className] = targetClasses.GetValueOrDefault(className) + 1;

                    if (!slotsByClass.TryGetValue(className, out var slots))
                        slotsByClass[className] = slots = new HashSet<string>(StringComparer.Ordinal);
                    slots.Add(property.Name);

                    // What does the modifier itself declare?
                    if (!propertiesByClass.TryGetValue(className, out var own))
                        propertiesByClass[className] = own = new Dictionary<string, int>(StringComparer.Ordinal);

                    try
                    {
                        var ownProperties = UnrealPropertyReader.Read(
                            package.ReadExportData(target), package.Names, out _);
                        foreach (var p in ownProperties)
                            own[$"{p.Name} ({p.Type})"] = own.GetValueOrDefault($"{p.Name} ({p.Type})") + 1;
                    }
                    catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                                   or ArgumentOutOfRangeException)
                    {
                        own["<unreadable>"] = own.GetValueOrDefault("<unreadable>") + 1;
                    }
                }
            }
        }

        Log("classes a material's object properties point at, excluding Texture and Cubemap:");
        foreach (var (className, count) in targetClasses.OrderByDescending(p => p.Value))
        {
            Log($"  {className,-28} {count,6:N0}   slots: "
                + string.Join(", ", slotsByClass[className].OrderBy(s => s, StringComparer.Ordinal).Take(8)));

            foreach (var (property, n) in propertiesByClass[className].OrderByDescending(p => p.Value).Take(12))
                Log($"        {property,-40} {n,6:N0}");
        }

        Assert.NotEmpty(targetClasses);

        // The four animator classes the game actually ships, with the counts the decoder was
        // written against. These are what a material's object properties mostly point at once
        // textures and cubemaps are excluded.
        Assert.InRange(targetClasses.GetValueOrDefault("TexturePanner"), 2_500, 3_200);
        Assert.InRange(targetClasses.GetValueOrDefault("TextureScalar"), 600, 800);
        Assert.InRange(targetClasses.GetValueOrDefault("ColorCycle"), 550, 750);
        Assert.InRange(targetClasses.GetValueOrDefault("TextureRotator"), 350, 500);

        // UE2's names, from UModel. The game ships neither, which is why decoding by the reference
        // layout would have been wrong rather than merely incomplete.
        Assert.False(targetClasses.ContainsKey("TexPanner"));
        Assert.False(targetClasses.ContainsKey("TexRotator"));
        Assert.False(targetClasses.ContainsKey("TexOscillator"));

        // Every one of them is now decoded rather than reported as an unknown property.
        foreach (string className in new[] { "TexturePanner", "TextureScalar", "ColorCycle", "TextureRotator" })
            Assert.True(MaterialAnimatorReader.IsAnimatorClass(className),
                $"{className} is shipped {targetClasses[className]} times and is not decoded");
    }
}
