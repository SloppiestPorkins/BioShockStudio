using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Materials;

/// <summary>One material a <c>MaterialSwitch</c> can select between.</summary>
public sealed record MaterialSwitchCandidate
{
    /// <summary>Position in the switch's own <c>Materials</c> array.</summary>
    public required int Index { get; init; }

    /// <summary>The candidate's object name, or null when the reference does not resolve here.</summary>
    public string? Name { get; init; }

    /// <summary>The candidate's class, when it resolves.</summary>
    public string? ClassName { get; init; }

    /// <summary>True when this candidate is the switch's authored default (its <c>Material</c>).</summary>
    public bool IsDefault { get; init; }
}

/// <summary>
/// Reads a <c>MaterialSwitch</c>'s candidate array.
/// </summary>
/// <remarks>
/// <para>
/// <c>CONFIRMED_BYTES</c>, 23 Aug 2026. The <c>Materials</c> array property is an
/// <c>FCompactIndex</c> count followed by that many <c>FCompactIndex</c> object references, and it
/// consumes its declared size exactly on every switch sampled — 10 bytes for a count of 3, 7 bytes
/// for a count of 2.
/// </para>
/// <para>
/// <b>What this does and does not settle.</b> The <i>candidates</i> are now recoverable; <b>which
/// one a running game picks is still <c>UNKNOWN</c></b> and is not in this data — it is driven by
/// game logic elsewhere. That distinction is why the switch still resolves to its authored default
/// child for rendering and export, exactly as before; the candidate list is added alongside rather
/// than replacing that choice.
/// </para>
/// <para>
/// The candidates are plainly meaningful even without the selection rule:
/// <c>Resurrection_Shader</c> beside <c>Resurrection_Shader_NoLights</c>, and a quarantine sign's
/// <c>_scroll</c> beside its <c>_off</c> variant — a consumer can carry all states across and drive
/// them itself.
/// </para>
/// </remarks>
public static class MaterialSwitchReader
{
    public const string ClassName = "MaterialSwitch";

    /// <summary>The array property holding the candidates.</summary>
    private const string CandidatesProperty = "Materials";

    /// <summary>
    /// Reads the candidates a switch declares. Empty when the export is not a switch, or declares
    /// none, or its array does not walk cleanly — never a partial list.
    /// </summary>
    /// <param name="defaultName">
    /// The authored default's object name, so the matching candidate can be flagged. The default is
    /// a separate <c>Material</c> property, not a position in the array — it happens to be the
    /// first entry on the switches sampled, and that is not relied on.
    /// </param>
    public static IReadOnlyList<MaterialSwitchCandidate> ReadCandidates(
        BioShockPackage package, IReadOnlyList<UnrealProperty> properties, string? defaultName)
    {
        var array = properties.FirstOrDefault(p =>
            p.Name == CandidatesProperty && p.Type == UnrealPropertyType.Array);
        if (array is null || array.Value.Length == 0) return [];

        var candidates = new List<MaterialSwitchCandidate>();
        int offset = 0;

        try
        {
            int count = UnrealPropertyReader.ReadCompactIndexAt(array.Value, ref offset);

            // A count that cannot fit in the bytes available is a misread, not a long list.
            if (count <= 0 || count > array.Value.Length) return [];

            for (int i = 0; i < count; i++)
            {
                if (offset >= array.Value.Length) return [];

                var reference = new PackageIndex(
                    UnrealPropertyReader.ReadCompactIndexAt(array.Value, ref offset));

                string? name = null, className = null;
                if (reference.IsExport && reference.ExportIndex < package.Exports.Count)
                {
                    var export = package.Exports[reference.ExportIndex];
                    name = export.ObjectName;
                    className = package.GetClassName(export);
                }
                else if (reference.IsImport && -reference.Value - 1 < package.Imports.Count)
                {
                    name = package.Imports[-reference.Value - 1].ObjectName;
                }

                candidates.Add(new MaterialSwitchCandidate
                {
                    Index = i,
                    Name = name,
                    ClassName = className,
                    IsDefault = name is not null && name == defaultName,
                });
            }
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return [];
        }

        // The array must account for itself exactly. Anything left over means the shape is not what
        // this reader believes, and a plausible-looking partial list is worse than none.
        return offset == array.Value.Length ? candidates : [];
    }
}
