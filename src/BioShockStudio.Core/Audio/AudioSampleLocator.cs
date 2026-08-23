using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Audio;

/// <summary>Which shipped store holds a sample, and where in it.</summary>
/// <param name="Store">
/// <c>CoreMap</c>, <c>LocalisedMap</c>, <c>ScriptPackage</c> or <c>StreamedBank</c>.
/// </param>
/// <param name="Container">The package file name, or the bank file name.</param>
/// <param name="Index">Subsound index, for a streamed bank only.</param>
public sealed record AudioSampleLocation(string Store, string Container, int? Index);

/// <summary>
/// An exact-name index of every place BioShock ships a sound sample.
/// </summary>
/// <remarks>
/// <para>
/// <b>CONFIRMED_BYTES, 23 Aug 2026.</b> There are four stores, and an index that misses one produces
/// a confident, wrong "missing audio" figure. That has already happened here: counting only the 21
/// non-localised map packages reported <b>1,970 of 5,726 samples (34.4%) missing</b>, when the game
/// simply ships its voice-over in the 140 <i>localised</i> packages — which is where localised
/// content belongs. Across all four stores, <b>5,722 of 5,726 (99.93%)</b> are located.
/// </para>
/// <list type="bullet">
/// <item>2,080 in the 21 core map packages.</item>
/// <item>1,995 in the 140 localised map packages — almost entirely <c>vo_*</c>.</item>
/// <item>1,676 in the streamed FSB5 banks.</item>
/// <item>10 in the script package <c>FMODAudio.U</c> — the shell/menu sounds.</item>
/// </list>
/// <para>
/// <b><c>BulkContent/</c> holds none.</b> It was the leading candidate in
/// <c>docs/research/audio.md</c> §4 and is ruled out: 0 of 5,726, and no audio-shaped name anywhere
/// in its 5,622 entries.
/// </para>
/// <para>
/// Building the native half reads every shipped package and is slow; build it once and reuse it.
/// The streamed half additionally needs the x86 FMOD bridge, so it is opt-in.
/// </para>
/// </remarks>
public sealed class AudioSampleLocator
{
    private readonly IReadOnlyDictionary<string, AudioSampleLocation> _byName;

    private AudioSampleLocator(IReadOnlyDictionary<string, AudioSampleLocation> byName) => _byName = byName;

    /// <summary>Distinct sample names the index holds.</summary>
    public int Count => _byName.Count;

    /// <summary>Where the sample ships, or null when no indexed store holds it.</summary>
    public AudioSampleLocation? Locate(string name) =>
        _byName.TryGetValue(name, out var found) ? found : null;

    /// <summary>
    /// Indexes the three package-backed stores. Does not need the FMOD bridge.
    /// </summary>
    /// <remarks>
    /// Earlier stores win, so a name present in both a core and a localised package is reported
    /// against the core one. That ordering is deliberate: the core packages are the ones this
    /// project's other readers already open.
    /// </remarks>
    public static AudioSampleLocator BuildNative(string gameRoot)
    {
        var byName = new Dictionary<string, AudioSampleLocation>(StringComparer.OrdinalIgnoreCase);

        var core = GameLocator.EnumeratePackages(gameRoot).ToList();
        Index(core, "CoreMap", byName);

        var coreSet = new HashSet<string>(core, StringComparer.OrdinalIgnoreCase);
        string maps = GameLocator.MapsDirectory(gameRoot);
        var localised = Directory.Exists(maps)
            ? Directory.GetFiles(maps, "*.bsm").Where(file => !coreSet.Contains(file)).ToList()
            : [];
        Index(localised, "LocalisedMap", byName);

        Index(GameLocator.EnumerateScriptPackages(gameRoot).ToList(), "ScriptPackage", byName);

        return new AudioSampleLocator(byName);
    }

    /// <summary>Adds the streamed FSB5 banks, which needs the game's x86 FMOD runtime.</summary>
    public static async Task<AudioSampleLocator> BuildAsync(
        string gameRoot, CancellationToken cancellation = default)
    {
        var native = BuildNative(gameRoot);
        var byName = new Dictionary<string, AudioSampleLocation>(native._byName, StringComparer.OrdinalIgnoreCase);

        var catalog = await StreamSampleCatalog.BuildAsync(gameRoot, cancellation);
        foreach (var location in catalog.Locations)
            if (!byName.ContainsKey(location.Name))
                byName[location.Name] = new AudioSampleLocation("StreamedBank", location.Bank.Name, location.Index);

        return new AudioSampleLocator(byName);
    }

    private static void Index(
        IReadOnlyList<string> files, string store, Dictionary<string, AudioSampleLocation> byName)
    {
        foreach (string file in files)
        {
            BioShockPackage package;
            try { package = BioShockPackage.Open(file); }
            catch (Exception ex) when (ex is InvalidDataException or IOException) { continue; }

            using (package)
            {
                string container = Path.GetFileName(file);
                foreach (var export in package.Exports)
                {
                    if (package.GetClassName(export) != SoundReader.ClassName) continue;
                    if (!byName.ContainsKey(export.ObjectName))
                        byName[export.ObjectName] = new AudioSampleLocation(store, container, null);
                }
            }
        }
    }
}
