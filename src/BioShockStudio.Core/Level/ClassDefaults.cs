using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>
/// The default property list at the end of a <c>Class</c> export.
/// <para>
/// This matters because most of a level's props do not name their own mesh. <c>dyn_gurney9</c> is a
/// placed actor of class <c>dyn_gurney</c>, and it stores a location and nothing about geometry; the
/// mesh — <c>Gurney</c> — is a default on the class. Without reading class defaults a third of the
/// world has no mesh at all.
/// </para>
/// <para>
/// CONFIRMED_BYTES that the list is there and decodes; the offset it starts at is found by search,
/// because a <c>Class</c> payload begins with script bytecode of unknown length. The search is
/// constrained: the walk must terminate on a clean <c>None</c> exactly at the end of the payload and
/// must not contain a property of type <c>None</c>, which is what a misaligned walk produces.
/// </para>
/// <para>
/// When several offsets satisfy that constraint, the <b>longest</b> list wins. An earlier mid-stream
/// start can invent a shorter garbage prefix (often a numbered <c>Text…</c> name) that still lands
/// on the same terminator — returning the first hit silently drops real leading defaults
/// (<c>BerserkRageAbility.ProjectileClass</c>, <c>ShockPlayer.SanctuaryModelClass</c>). Across all
/// 654 <c>Class</c> exports in <c>ShockGame.U</c>, 17 differ between earliest and longest; longest
/// is strictly longer on every one of them.
/// </para>
/// </summary>
public sealed class ClassDefaults
{
    private readonly Dictionary<int, IReadOnlyList<UnrealProperty>> _cache = [];
    private readonly BioShockPackage _package;

    public ClassDefaults(BioShockPackage package) => _package = package;

    /// <summary>
    /// The defaults declared on one class export. Empty when the payload holds no readable list.
    /// </summary>
    public IReadOnlyList<UnrealProperty> For(ObjectExport classExport)
    {
        if (_cache.TryGetValue(classExport.Index, out var cached)) return cached;

        var result = Read(classExport);
        _cache[classExport.Index] = result;
        return result;
    }

    /// <summary>
    /// Looks a property up on a class and then on its supers, returning the first that declares it.
    /// <para>
    /// The chain stops at an import: a class defined in another package has no payload here, so the
    /// answer is "not resolvable from this package" rather than a guess.
    /// </para>
    /// </summary>
    public UnrealProperty? Lookup(PackageIndex classIndex, string propertyName)
    {
        var index = classIndex;
        // Bounded: a malformed super chain must not loop.
        for (int depth = 0; depth < 32 && index.IsExport; depth++)
        {
            var classExport = _package.Exports[index.ExportIndex];
            var property = For(classExport).FirstOrDefault(p => p.Name == propertyName);
            if (property is not null) return property;
            index = classExport.SuperIndex;
        }
        return null;
    }

    private IReadOnlyList<UnrealProperty> Read(ObjectExport classExport)
    {
        byte[] data;
        try { data = _package.ReadExportData(classExport); }
        catch { return []; }
        if (data.Length <= UnrealPropertyReader.PayloadPropertyOffset) return [];

        IReadOnlyList<UnrealProperty>? best = null;
        for (int start = UnrealPropertyReader.PayloadPropertyOffset; start < data.Length; start++)
        {
            List<UnrealProperty> properties;
            int end;
            bool truncated;
            try { properties = UnrealPropertyReader.Read(data, _package.Names, out end, out truncated, start); }
            catch { continue; }

            if (truncated || end != data.Length || properties.Count == 0) continue;
            // A walk that lands mid-bytecode produces properties with no type. A real list has none.
            if (properties.Any(p => p.Type == UnrealPropertyType.None)) continue;
            if (best is null || properties.Count > best.Count) best = properties;
        }

        return best ?? [];
    }
}
