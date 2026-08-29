using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Config;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
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

    [RequiresGameFact]
    public void EveryArchetypeInSpawningIniParsesAndMatchesItsPackageExport()
    {
        var config = AiArchetypeConfig.Read(Bundle()["Spawning.ini"]!)
            .ToDictionary(a => a.Name, StringComparer.OrdinalIgnoreCase);

        // All 312 archetype sections (the ~25 non-archetype sections carry no AIType).
        Assert.InRange(config.Count, 300, 320);
        Assert.All(config.Values, a => Assert.NotNull(a.AiType));

        // The one referenced archetype that ships as no package export is here.
        Assert.True(config.ContainsKey("PlayerEscortedGathererDLCCombat"));

        // Where a map does ship the export, the two decodes agree on the fields that matter.
        using var medical = BioShockPackage.Open(game.MedicalPackage);
        int checvar = 0;
        foreach (var fromPackage in AiArchetypeCatalog.Read(medical))
        {
            if (!config.TryGetValue(fromPackage.Name, out var fromIni)) continue;
            checvar++;
            // The ini and the name table disagree on case (SpawnedRangedAggressorPISTOL vs
            // ...Pistol) — same class, so compare case-insensitively.
            Assert.Equal(fromPackage.AiType, fromIni.AiType, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(fromPackage.Mesh, fromIni.Mesh, StringComparer.OrdinalIgnoreCase);
            Assert.Equal(fromPackage.Health, fromIni.Health);
            Assert.Equal(fromPackage.MaterialSlots.Count, fromIni.MaterialSlots.Count);
        }
        Assert.True(checvar > 15, $"only {checvar} archetypes cross-checked");
    }

    [RequiresGameFact]
    public void WeaponConfigResolvesTheWeaponAmmoDamageChain()
    {
        var weapons = WeaponConfig.ReadAll(Bundle()["Weapons.ini"]!);

        var pistol = weapons.Single(w => w.Name == "Pistol");
        Assert.Equal(6, pistol.BaseMagazineSize);
        Assert.Equal(3, pistol.Ammo.Count);

        var standard = pistol.Ammo.Single(a => a.Name == "Pistol_Bullet");
        Assert.Equal("StandardBulletStimuliSet", standard.DamageStimuliSetName);
        Assert.Equal(48, standard.MaximumStackSize);
        // The base number a pistol round deals to an AI, before the target's resistance set.
        var piercing = standard.Damage.Single(d => d.Type == "STIMULUS_AIGenericPiercing");
        Assert.Equal(40f, piercing.Amount);

        // The crossbow's steel-tip bolt is the game's hardest-hitting basic round.
        var bolt = weapons.Single(w => w.Name == "Crossbow").Ammo
            .Single(a => a.Name == "Crossbow_Bolt").Damage
            .Single(d => d.Type == "STIMULUS_AIGenericPiercing");
        Assert.Equal(450f, bolt.Amount);
    }

    [RequiresGameFact]
    public void ResistanceSetReadsTheWeaponsIniIntoTypedModifiers()
    {
        var sets = ResistanceSet.ReadAll(Bundle()["Weapons.ini"]!);

        Assert.True(sets.Count > 80, $"only {sets.Count} resistance sets");
        Assert.False(sets["SteinmanResistanceSet"].IsNeutral);

        // Default is neutral bar one entry — ElectricInWater is zeroed for everyone.
        var def = sets["DefaultResistanceSet"];
        Assert.Equal(1f, def.For("STIMULUS_Heat").Amount);
        Assert.Equal(0f, def.For("STIMULUS_ElectricInWater").Amount);

        // Steinman: 0× weapon heat damage, so a fireball does nothing until he's scripted killable.
        Assert.Equal(0f, sets["SteinmanResistanceSet"].For("STIMULUS_Heat").Amount);
        // An archetype's name resolves straight in.
        var grenadier = Bundle()["Spawning.ini"]!["MedicalDoctorGrenadier"]!;
        Assert.True(sets.ContainsKey(grenadier.Value("DamageResistanceSetName")!));
    }
}
