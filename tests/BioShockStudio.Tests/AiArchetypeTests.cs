using System.Text.Json;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Export;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// <c>AIArchetype</c> exports — the enemy roster a spawner names. This is what resolves the
/// archetype-name gap: <c>Spawner.OverriddenAiArchetypeNames</c> and the character-shaped
/// <c>TriggerOnlyByLabels</c> entries point here, not at a placed actor. See
/// <c>docs/research/spawning.md</c>.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class AiArchetypeTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void EveryArchetypeExportResolvesItsBehaviourClassAndMesh()
    {
        long total = 0, clean = 0, withType = 0, withMesh = 0, withHealth = 0, withSlots = 0;
        var meshes = new HashSet<string>(StringComparer.Ordinal);

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .Where(f => !Path.GetFileNameWithoutExtension(f).Contains('_'))
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            using var package = BioShockPackage.Open(map);
            foreach (var archetype in AiArchetypeCatalog.Read(package))
            {
                total++;
                if (archetype.Complete) clean++;
                if (archetype.AiType is not null) withType++;
                if (archetype.Mesh is { } m) { withMesh++; meshes.Add(m); }
                if (archetype.Health is not null) withHealth++;
                if (archetype.MaterialSlotEntries + archetype.AttachmentSlotEntries + archetype.WeaponSlotEntries > 0)
                    withSlots++;
            }
        }

        Log($"archetypes {total}  clean {clean}  type {withType}  mesh {withMesh}  health {withHealth}  slots {withSlots}");
        Log($"  distinct meshes: {string.Join(", ", meshes.OrderBy(x => x))}");

        // The 21 maps ship a subset each of SpawningManager's 313-name master list.
        Assert.InRange(total, 250, 320);

        // The two fields that make an archetype usable — behaviour class and mesh — resolve for the
        // overwhelming majority. A handful of special-map archetypes (boss proteges, challenge-room
        // stand-ins) and three that hit a pre-existing Range-struct reader gap are the exceptions.
        Assert.True(withType > total * 0.9, $"only {withType}/{total} archetypes resolved an AIType");
        Assert.True(withMesh > total * 0.9, $"only {withMesh}/{total} archetypes resolved a Mesh");

        // The meshes are real skeletal-mesh names, not garbage from a derailed walk.
        Assert.Contains("Agg_BabyJane", meshes);
        Assert.Contains("GathererGirl", meshes);
        Assert.All(meshes, m => Assert.Matches("^[A-Za-z0-9_]+$", m));

        // The CorrectedStructArraySize fix: the loadout slots (nested ChancePair lists) parse rather
        // than truncating the walk. Before it, ~40% of archetypes lost every property after the
        // first slot, Health included.
        Assert.True(clean > total * 0.9, $"only {clean}/{total} archetypes parsed to a clean terminator");
        Assert.True(withSlots > total / 2, $"only {withSlots}/{total} archetypes decoded any loadout slot");
    }

    [RequiresGameFact]
    public void MedicalArchetypesCarryTheStatsTheGameShipsForThem()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var byName = AiArchetypeCatalog.Read(package).ToDictionary(a => a.Name, StringComparer.Ordinal);

        var grenadier = byName["MedicalDoctorGrenadier"];
        Assert.Equal("SpawnedGrenadier", grenadier.AiType);
        Assert.Equal("Agg_Doctor_Mesh", grenadier.Mesh);
        Assert.Equal(400f, grenadier.Health);
        Assert.Equal(200f, grenadier.FrozenHealth);

        var babyJane = byName["MedicalBabyJaneMelee"];
        Assert.Equal("SpawnedMeleeThug", babyJane.AiType);
        Assert.Equal("Agg_BabyJane", babyJane.Mesh);
        Assert.Equal(80f, babyJane.Health);
        Assert.True(babyJane.MaterialSlotEntries > 0, "the material slot did not decode");

        // A base (unprefixed) archetype: class + mesh + loadout, but no authored Health — it takes
        // the AIType class's own default. Not a decode miss; the property is genuinely absent.
        var doctorMelee = byName["DoctorMelee"];
        Assert.Equal("SpawnedMeleeThug", doctorMelee.AiType);
        Assert.Null(doctorMelee.Health);
        Assert.True(doctorMelee.Complete);
    }

    [RequiresGameFact]
    public void TheArchetypesReachTheLevelManifestAndSurviveTheJsonRoundTrip()
    {
        using var package = BioShockPackage.Open(game.MedicalPackage);
        var scene = LevelSceneBuilder.Build(package, LevelAnalyzer.Analyze(package));

        var document = LevelSceneExporter.ToDocument(scene, package: package);
        Assert.NotEmpty(document.Archetypes);
        Assert.Equal(
            AiArchetypeCatalog.Read(package).Count,
            document.Archetypes.Count);

        string json = JsonSerializer.Serialize(document,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        var back = JsonSerializer.Deserialize<LevelDocument>(json,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase })!;

        var grenadier = back.Archetypes.Single(a => a.Name == "MedicalDoctorGrenadier");
        Assert.Equal("SpawnedGrenadier", grenadier.AiType);
        Assert.Equal("Agg_Doctor_Mesh", grenadier.Mesh);
        Assert.Equal(400f, grenadier.Health);

        // A no-package export carries no archetypes — a scope choice, stated by the empty list.
        Assert.Empty(LevelSceneExporter.ToDocument(scene).Archetypes);
    }
}
