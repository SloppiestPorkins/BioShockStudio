using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Every placed sound actor in the game, and what it resolves to.
/// </summary>
/// <remarks>
/// <para>
/// The figure this replaces: exact matching against the shipped FSB sample names resolved
/// <b>177 of 3,247</b> actors, all <c>SoundMarker</c>s, and no <c>AmbientSound</c> whatsoever.
/// Through the specification route it is <b>3,068 of 3,247</b>.
/// </para>
/// <para>
/// The remainder is not a decode failure and is not rounded away: 142 <c>AmbientSound</c>s, 35
/// <c>SoundMarker</c>s and both <c>MusicBox</c>es declare no name that any shipped object answers
/// to — many of them carrying only an editor default such as <c>SoundMarker3</c>. Unknown is a
/// valid answer.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class SoundActorSpecificationCoverageTests(GameFixture game)
{
    [RequiresGameFact]
    public void EverySoundActorIsAccountedForAgainstTheShippedSpecifications()
    {
        int actors = 0, direct = 0, spawned = 0, resolved = 0;
        int ambient = 0, ambientResolved = 0, markers = 0, markersResolved = 0, musicBoxes = 0, musicResolved = 0;
        int sampleReferences = 0;

        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            using var package = BioShockPackage.Open(file);
            var index = SoundActorSpecificationIndex.Build(package);
            var context = LevelAnalyzer.Analyze(package);

            foreach (var actor in context.Actors)
            {
                string className = actor.Source.ClassName;
                if (className is not ("AmbientSound" or "SoundMarker" or "MusicBox")) continue;

                actors++;
                var resolution = index.Resolve(actor, package);
                if (resolution.Route == SoundActorRoute.Direct) direct++;
                if (resolution.Route == SoundActorRoute.SpawnedEvent) spawned++;
                if (resolution.IsResolved) { resolved++; sampleReferences += resolution.SampleNames.Count; }

                switch (className)
                {
                    case "AmbientSound": ambient++; if (resolution.IsResolved) ambientResolved++; break;
                    case "SoundMarker": markers++; if (resolution.IsResolved) markersResolved++; break;
                    default: musicBoxes++; if (resolution.IsResolved) musicResolved++; break;
                }

                // An unresolved actor must claim nothing at all.
                if (!resolution.IsResolved)
                {
                    Assert.Equal(SoundActorRoute.None, resolution.Route);
                    Assert.Null(resolution.MatchedName);
                    Assert.Empty(resolution.Specifications);
                }
            }
        }

        Assert.Equal(3_247, actors);
        Assert.Equal(2_893, ambient);
        Assert.Equal(352, markers);
        Assert.Equal(2, musicBoxes);

        Assert.Equal(3_068, resolved);
        Assert.Equal(317, direct);
        Assert.Equal(2_751, spawned);
        Assert.Equal(direct + spawned, resolved);

        // Each class takes exactly one of the two routes, which is what makes them two routes and
        // not one heuristic: no AmbientSound names a specification outright, and no SoundMarker
        // goes through a spawned event.
        Assert.Equal(2_751, ambientResolved);
        Assert.Equal(spawned, ambientResolved);
        Assert.Equal(317, markersResolved);
        Assert.Equal(direct, markersResolved);
        Assert.Equal(0, musicResolved);

        Assert.Equal(5_804, sampleReferences);
    }

    /// <summary>
    /// The <c>AmbientSoundSpawned_</c> prefix is structural across the whole game.
    /// </summary>
    /// <remarks>
    /// 10,360 responses carry it, and every one declares the same event and the same source class.
    /// A prefix that meant nothing would not do that.
    /// </remarks>
    [RequiresGameFact]
    public void EverySpawnedResponseDeclaresTheSpawnedAmbientSoundEvent()
    {
        int spawnedResponses = 0;
        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            using var package = BioShockPackage.Open(file);
            var spawned = SoundEventReader.Read(package)
                .Where(response => response.ObjectName.StartsWith(
                    SoundActorSpecificationIndex.SpawnedPrefix, StringComparison.Ordinal))
                .ToList();

            spawnedResponses += spawned.Count;
            Assert.All(spawned, response => Assert.Equal("Spawned", response.Event));
            Assert.All(spawned, response => Assert.Equal("AmbientSound", response.SourceClassName));
        }

        Assert.Equal(10_360, spawnedResponses);
    }

    /// <summary>
    /// Where the samples the specifications name actually ship - all four stores.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A resolved name is not a located sample, and this project has a rule against calling the
    /// first one the second. Of the 5,726 distinct names the specifications reference,
    /// <b>5,722 (99.93%) are located</b>.
    /// </para>
    /// <para>
    /// <b>An earlier version of this test asserted 3,756 located and 1,970 "in neither store".</b>
    /// Those numbers were real but they counted only the 21 non-localised map packages, and the
    /// game ships its voice-over in the 140 <i>localised</i> ones - which is exactly where localised
    /// content belongs. That is why this test now enumerates every store the game actually has, and
    /// why it asserts the per-store split rather than only a total: a total alone would have looked
    /// equally plausible while missing 1,995 samples.
    /// </para>
    /// <para>
    /// The four that remain unlocated are named below. Three carry the <c>99</c> level prefix and
    /// <c>vo_waders_frozen</c> has no shipped variant at all, so they read as references to cut
    /// content - <c>LIKELY</c>, and asserted here as an exact set so that a fifth would fail rather
    /// than pass unnoticed.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public async Task EverySpecificationSampleNameIsLocatedInAShippedStore()
    {
        string root = game.RequireRoot;
        var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var coreSounds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var localisedSounds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var scriptSounds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        var core = GameLocator.EnumeratePackages(root).ToList();
        foreach (string file in core)
        {
            using var package = BioShockPackage.Open(file);
            foreach (var metadata in SoundEffectSpecificationReader.Read(package))
                foreach (var entry in metadata.SoundSpecs)
                    if (!string.IsNullOrEmpty(entry.SoundName)) names.Add(entry.SoundName!);

            foreach (var export in package.Exports)
                if (package.GetClassName(export) == "Sound") coreSounds.Add(export.ObjectName);
        }

        // The localised duplicates are where the voice-over ships. Skipping them is what made an
        // earlier reading of this figure report a 34% gap that was not there.
        var coreSet = new HashSet<string>(core, StringComparer.OrdinalIgnoreCase);
        foreach (string file in Directory.GetFiles(GameLocator.MapsDirectory(root), "*.bsm")
                     .Where(file => !coreSet.Contains(file)))
        {
            using var package = BioShockPackage.Open(file);
            foreach (var export in package.Exports)
                if (package.GetClassName(export) == "Sound") localisedSounds.Add(export.ObjectName);
        }

        // The shell/menu sounds live in a script package, not a map.
        foreach (string file in GameLocator.EnumerateScriptPackages(root))
        {
            using var package = BioShockPackage.Open(file);
            foreach (var export in package.Exports)
                if (package.GetClassName(export) == "Sound") scriptSounds.Add(export.ObjectName);
        }

        var catalog = await StreamSampleCatalog.BuildAsync(root);
        bool Streamed(string name) => catalog.Find(name).Count > 0;
        bool Located(string name) => coreSounds.Contains(name) || localisedSounds.Contains(name)
                                     || scriptSounds.Contains(name) || Streamed(name);

        Assert.Equal(5_726, names.Count);
        Assert.Equal(2_080, names.Count(coreSounds.Contains));
        Assert.Equal(1_995, names.Count(localisedSounds.Contains));
        Assert.Equal(1_676, names.Count(Streamed));
        Assert.Equal(10, names.Count(scriptSounds.Contains));

        Assert.Equal(5_722, names.Count(Located));

        Assert.Equal(
            ["vo_PA_99_Fa_ResponsibilityPA", "vo_PA_99_Fa_ResponsibilityPA4a",
             "vo_S_99_Ad_SportsBoostAd", "vo_waders_frozen_04"],
            names.Where(name => !Located(name)).OrderBy(name => name, StringComparer.Ordinal).ToArray());
    }

    /// <summary>
    /// <c>BulkContent/</c> holds no audio at all - the candidate <c>audio.md</c> §4 proposed.
    /// </summary>
    /// <remarks>
    /// Controlled in both directions, because a negative result from a broken query is worth
    /// nothing: a name taken from the catalogue itself must resolve, and an invented one must not.
    /// The earlier reasoning that kept this candidate alive used <c>Hand_DIFF</c> as its control,
    /// which <c>docs/research/bulkcontent.md</c> records as a texture that was never stripped - so
    /// it has no bulk entry to find and proved nothing.
    /// </remarks>
    [RequiresGameFact]
    public void TheBulkContentStoreHoldsNoSoundSamples()
    {
        string root = game.RequireRoot;
        var catalog = BulkTextureCatalog.Load(root);
        Assert.NotNull(catalog);

        Assert.NotNull(catalog!.Find(catalog.Entries[0].Texture));            // positive control
        Assert.Null(catalog.Find("definitely_not_a_real_asset_xyz"));         // negative control

        var bulk = new HashSet<string>(catalog.Entries.Select(entry => entry.Texture),
            StringComparer.OrdinalIgnoreCase);

        var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (string file in GameLocator.EnumeratePackages(root))
        {
            using var package = BioShockPackage.Open(file);
            foreach (var metadata in SoundEffectSpecificationReader.Read(package))
                foreach (var entry in metadata.SoundSpecs)
                    if (!string.IsNullOrEmpty(entry.SoundName)) names.Add(entry.SoundName!);
        }

        Assert.Equal(5_726, names.Count);
        Assert.Empty(names.Where(bulk.Contains));

        // Nor anything audio-shaped under any name: "Gen_Ambience" is environment art.
        Assert.Empty(bulk.Where(name =>
            name.StartsWith("ambience_", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("weapons_", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("scripted_", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("vo_", StringComparison.OrdinalIgnoreCase)));
    }
}
