using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Assets;

/// <summary>A character-like asset group: a skeletal mesh with its own animation package.</summary>
public sealed record CharacterEntry
{
    public required string Group { get; init; }
    public required string PackageName { get; init; }
    public required string AnimationPackageObject { get; init; }
    public required IReadOnlyList<string> Meshes { get; init; }
    public required int AnimationCount { get; init; }
    public required int TextureCount { get; init; }

    /// <summary>Largest mesh payload, a rough proxy for how substantial the asset is.</summary>
    public required int LargestMeshSize { get; init; }

    /// <summary>
    /// Whether the group's Havok packfile declares an <c>hkaRagdollInstance</c> — the game's own
    /// statement that this is something it expects to go limp under physics.
    /// </summary>
    /// <remarks>
    /// This is what separates an actor from scenery, and it is read from the data rather than
    /// guessed from a name or a size. 207 of the game's 870 animation wrappers declare one.
    /// <para>
    /// It is <b>not</b> a perfect "is a character" test and is not presented as one: breakable
    /// scenery carries a ragdoll too (a slot machine, a wall safe, a flower vase), and
    /// <c>Ryan</c> — 131 bones — does not carry one at all. It is the best structural signal the
    /// data offers, which is why the browser says what a row qualified on rather than asserting a
    /// category as fact.
    /// </para>
    /// </remarks>
    public required bool HasRagdoll { get; init; }

    public override string ToString() => $"{Group} ({AnimationCount} animations)";
}

/// <summary>
/// Finds animated character assets in a package.
/// <para>
/// A character is recognised structurally, not by name: an asset group that owns both a
/// <c>SkeletalMesh</c> and an <c>AnimationPackageWrapper</c>. That covers Big Daddies, Splicers,
/// the Little Sister and the player hands, and also picks up animated props, which are separated by
/// mesh size and animation count rather than by guessing from names.
/// </para>
/// </summary>
public static class CharacterCatalog
{
    public static IReadOnlyList<CharacterEntry> Find(BioShockPackage package)
    {
        var byGroup = new Dictionary<string, List<ObjectExport>>(StringComparer.Ordinal);

        foreach (var export in package.Exports)
        {
            string group = AssetContextResolver.TopLevelGroup(package, export);
            if (!byGroup.TryGetValue(group, out var members))
                byGroup[group] = members = [];
            members.Add(export);
        }

        var result = new List<CharacterEntry>();
        string packageName = Path.GetFileNameWithoutExtension(package.FilePath);

        foreach (var (group, members) in byGroup)
        {
            var wrapper = members
                .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
                .MaxBy(e => e.SerialSize);
            if (wrapper is null) continue;

            var meshes = members.Where(e => package.GetClassName(e) == AssetClasses.SkeletalMesh).ToList();
            if (meshes.Count == 0) continue;

            result.Add(new CharacterEntry
            {
                Group = group,
                PackageName = packageName,
                AnimationPackageObject = wrapper.ObjectName,
                Meshes = meshes.OrderByDescending(e => e.SerialSize).Select(e => e.ObjectName).ToList(),
                AnimationCount = members.Count(e => package.GetClassName(e) == AnimationMetadataReader.ClassName),
                TextureCount = members.Count(e => package.GetClassName(e) == "Texture"),
                LargestMeshSize = meshes.Max(e => e.SerialSize),
                HasRagdoll = DeclaresRagdoll(package, wrapper),
            });
        }

        return result.OrderByDescending(e => e.AnimationCount).ThenByDescending(e => e.LargestMeshSize).ToList();
    }

    /// <summary>Class name the Havok packfile declares for a ragdoll.</summary>
    private const string RagdollClassName = "hkaRagdollInstance";

    /// <summary>
    /// How much of a wrapper's payload has to be read to see its Havok class table.
    /// </summary>
    /// <remarks>
    /// <c>CONFIRMED_BYTES</c>: across all 870 animation wrappers the game ships, the deepest the
    /// name <c>hkaRagdollInstance</c> ever sits is <b>841 bytes</b> in, because the packfile's
    /// <c>__classnames__</c> section comes first. 4 KB is that with a 4.7× margin, and it matters:
    /// the payloads total 244 MB, and the catalogue's whole point is that listing an asset does not
    /// read it.
    /// </remarks>
    private const int ClassTableProbeSize = 4096;

    /// <summary>
    /// Whether a wrapper's packfile declares a ragdoll, from a bounded prefix of its payload.
    /// </summary>
    /// <remarks>
    /// A literal search for the class name rather than a packfile parse. <c>CONFIRMED_BYTES</c>
    /// that the two agree: on all 870 shipped wrappers the literal search and a full
    /// <c>HavokPackfile.Parse</c> class-table walk return the same answer, 207 of them positive,
    /// zero disagreements. The search is used because the parse needs the whole payload.
    /// </remarks>
    private static bool DeclaresRagdoll(BioShockPackage package, ObjectExport wrapper)
    {
        if (wrapper.SerialSize <= 0) return false;

        var buffer = new byte[Math.Min(ClassTableProbeSize, wrapper.SerialSize)];
        int read;
        try
        {
            using var stream = package.OpenExportStream(wrapper);
            read = stream.ReadAtLeast(buffer, buffer.Length, throwOnEndOfStream: false);
        }
        catch (IOException) { return false; }

        return Contains(buffer.AsSpan(0, read), RagdollClassName);
    }

    private static bool Contains(ReadOnlySpan<byte> haystack, string ascii)
    {
        for (int i = 0; i + ascii.Length <= haystack.Length; i++)
        {
            bool hit = true;
            for (int j = 0; j < ascii.Length; j++)
                if (haystack[i + j] != (byte)ascii[j]) { hit = false; break; }
            if (hit) return true;
        }
        return false;
    }
}
