using BioShockStudio.Core.Config;
using BioShockStudio.Core.Game;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The baked config bundle (<c>ContentBaked/pc/ConfigINI.IBF</c>) — the data layer for everything
/// the packages carry only by name: AI archetypes, resistance sets, loot tables, weapon and plasmid
/// stats. See <c>docs/research/config.md</c>.
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class IniBundleTests(GameFixture game)
{
    private IniBundle Bundle() => IniBundle.Load(GameLocator.ConfigBundle(game.RequireRoot));

    [RequiresGameFact]
    public void TheBundleParsesIntoTheGamesConfigFiles()
    {
        var bundle = Bundle();

        // The shipped bundle holds every PerObjIniFile the engine declares, plus Default/DefUser.
        Assert.Contains("Spawning.ini", bundle.FileNames);
        Assert.Contains("Weapons.ini", bundle.FileNames);
        Assert.Contains("LootTables.ini", bundle.FileNames);
        Assert.Contains("Ai.ini", bundle.FileNames);
        Assert.True(bundle.FileNames.Count >= 20, $"only {bundle.FileNames.Count} files parsed");

        // Each is a real ini with many sections — a parse that lost alignment would collapse these.
        Assert.True(bundle["Spawning.ini"]!.Sections.Count > 300);
        Assert.True(bundle["Weapons.ini"]!.Sections.Count > 400);
    }

    [RequiresGameFact]
    public void AnArchetypeSectionCarriesWhatTheExportCarries()
    {
        var spawning = Bundle()["Spawning.ini"]!;
        var grenadier = spawning["MedicalDoctorGrenadier"];

        Assert.NotNull(grenadier);
        Assert.Equal(400f, grenadier.Float("Health"));
        Assert.Equal("MedicalGrenadierResistanceSet", grenadier.Value("DamageResistanceSetName"));
        Assert.Equal(36f, grenadier.Float("MaxBurningEfficacy"));
        // The loadout — one AttachmentSlot1 line, the grenade box.
        Assert.Contains("GrenadeBox", string.Join(" ", grenadier.Values("AttachmentSlot1")));
    }

    [RequiresGameFact]
    public void ResistanceSetsResolveToPerStimulusModifiers()
    {
        var weapons = Bundle()["Weapons.ini"]!;

        // The default set is a no-op — every modifier 1.0.
        var def = weapons["DefaultResistanceSet"];
        Assert.NotNull(def);
        Assert.All(def.Values("Resistance"), line =>
        {
            var fields = IniSection.ParseStruct(line);
            Assert.Contains(fields, f => f.Key == "Type" && f.Value.StartsWith("STIMULUS_"));
            Assert.Contains(fields, f => f.Key == "AmountModification");
        });

        // Steinman shrugs off direct fire — every weapon-damage stimulus zeroed.
        var steinman = weapons["SteinmanResistanceSet"];
        Assert.NotNull(steinman);
        var heat = steinman.Values("Resistance")
            .Select(IniSection.ParseStruct)
            .First(f => f.Any(p => p.Key == "Type" && p.Value == "STIMULUS_Heat"));
        Assert.Equal("0.0", heat.First(p => p.Key == "AmountModification").Value);
    }
}
