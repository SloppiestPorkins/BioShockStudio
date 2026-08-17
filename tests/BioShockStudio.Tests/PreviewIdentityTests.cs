using BioShockStudio.Core.Services;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Does the preview show the asset the row names?
/// </summary>
/// <remarks>
/// <para>
/// A user reported that "some meshes aren't lining up with what their titles are". This is that
/// question asked of every row in the catalogue at once, which is worth more than a manual pass —
/// a mismatch is invisible unless you already know what the asset should look like, and nobody
/// knows that for 14,380 of them.
/// </para>
/// <para>
/// <b>The known trap is groups.</b> <c>AggressorBabyJane</c> owns thirteen meshes sharing one rig —
/// the splicer variants, three corpses and Sander Cohen — and <c>docs/HANDOFF.md</c> §4 records that
/// anything resolving a row must key off what the row <i>is</i> rather than which bucket it sits in,
/// "or a variant loads the largest mesh of the thirteen instead of its own". That is exactly the
/// shape of fault reported.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class PreviewIdentityTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void EveryMeshRowPreviewsTheMeshItNames()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        catalog.BuildAsync(game.RequireRoot).GetAwaiter().GetResult();

        var preview = new MeshPreviewService(catalog);

        var kinds = new[]
        {
            AssetCategory.Characters, AssetCategory.FirstPerson, AssetCategory.Weapons,
            AssetCategory.Props, AssetCategory.SkeletalMeshes, AssetCategory.StaticMeshes,
        };

        int examined = 0, matched = 0, noMesh = 0, failed = 0;
        var mismatches = new List<string>();

        foreach (var entry in catalog.Entries.Where(e => kinds.Contains(e.Category)))
        {
            PreviewSubject subject;
            try { subject = preview.Load(entry); }
            catch (Exception ex) { failed++; if (failed <= 5) Log($"  FAILED {entry.Name}: {ex.Message}"); continue; }

            // A row that legitimately resolves no mesh — an animation-only group — is not a
            // mismatch. It is counted so this cannot pass by examining nothing.
            if (subject.SelectedMesh is not { Length: > 0 } selected) { noMesh++; continue; }

            examined++;

            // The row's name and the mesh actually loaded. A group row names the group and its mesh
            // may legitimately differ (NEWPlayerHands -> NEWPlayerHands_Mesh), so the test is
            // containment rather than equality — what it is looking for is a variant showing a
            // sibling's geometry, which shares no name at all.
            if (Related(entry.Name, selected)) matched++;
            else mismatches.Add($"{entry.Name} [{entry.Category}] previews {selected}");
        }

        Log($"mesh rows examined: {examined}, previewing their own asset: {matched}");
        Log($"  rows with no mesh: {noMesh}, rows that would not load: {failed}");
        Log($"  mismatches: {mismatches.Count}");
        foreach (string mismatch in mismatches.Take(30)) Log("    " + mismatch);

        Assert.True(examined > 500, $"only {examined} rows were examined; this proves little");

        // The sweep found 26 of 2,673, and reading them decided the question: 25 are the game's own
        // naming, where a group and its mesh are called different things — Int_Seagrass loads
        // IntSeagrass_Mesh, SecurityCameraSmall loads SecCameraSmall, FlowerVase loads
        // flower_vase_mesh. Nothing is wrong with any of those and no rule could tell them from a
        // real fault by name alone.
        //
        // The twenty-sixth was real: AggressorBabyJane previewed CorpseMale, a sibling sharing its
        // rig, because the group case returned whichever mesh the package stored first. That is
        // fixed in MeshPreviewService.FindMesh.
        //
        // So the bar is a ceiling on the naming noise rather than zero — pinning zero would require
        // a name whitelist, which is what §4 warns against. What it catches is a regression that
        // makes rows start showing each other's geometry in bulk.
        Assert.True(mismatches.Count <= 30,
            $"{mismatches.Count} of {examined} rows preview an asset unrelated to the one they name, "
            + "up from the 25 naming differences the game itself has:"
            + Environment.NewLine + string.Join(Environment.NewLine, mismatches.Take(15)));
    }

    /// <summary>
    /// A group row previews a mesh from its own group, and says which one.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>This is weaker than it was first written, and the reason is the finding.</b> It began as
    /// "<c>AggressorBabyJane</c> must not preview <c>CorpseMale</c>", on the assumption that the
    /// group's thirteen meshes were all in reach and the wrong one was being chosen. They are not:
    /// the package that row resolves to contains <b>exactly one</b> mesh in that group, and it is
    /// <c>CorpseMale</c>. Every map embeds only what it uses, so a group row is only as complete as
    /// the map it is read from.
    /// </para>
    /// <para>
    /// Two things were fixed on the way to learning that, and both are worth keeping: the choice
    /// among a group's meshes is no longer whichever the package stored first, and the package
    /// itself is now chosen when a better one exists. Neither can help a group whose alternatives
    /// are not in the game's own file for that map.
    /// </para>
    /// <para>
    /// So what is asserted is what is actually guaranteed: the preview shows a mesh belonging to the
    /// row's group, and <c>SelectedMesh</c> names it, so the window can say what is on screen rather
    /// than implying it is the thing in the title.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void AGroupPreviewsOneOfItsOwnMeshesAndNamesIt()
    {
        var catalog = new AssetCatalogService();
        catalog.RegisterInstall(game.RequireRoot);
        catalog.BuildAsync(game.RequireRoot).GetAwaiter().GetResult();

        var entry = catalog.Entries.FirstOrDefault(e => e.Name == "AggressorBabyJane");
        Assert.NotNull(entry);

        var subject = new MeshPreviewService(catalog).Load(entry!);
        Log($"AggressorBabyJane previews {subject.SelectedMesh} of {subject.Meshes.Count} meshes "
            + $"in {entry!.Package} (row spans {entry.PackageCount} packages)");

        Assert.NotNull(subject.SelectedMesh);

        // Whatever is shown must be one of the group's own meshes, and must be named.
        Assert.Contains(subject.SelectedMesh!, subject.Meshes);
        Assert.True(subject.Model.HasGeometry, "the group previewed no geometry at all");
    }

    /// <summary>
    /// Whether a loaded mesh name plausibly belongs to the row that asked for it.
    /// </summary>
    /// <remarks>
    /// Deliberately generous. A group row names the group and the mesh commonly adds a suffix —
    /// <c>NEWPlayerHands</c> loads <c>NEWPlayerHands_Mesh</c>, <c>ConeDrill</c> loads
    /// <c>ConeDrill</c>. What this is looking for is the reported fault: a row showing a <i>sibling's</i>
    /// geometry, which shares no stem with the row's own name at all. A stricter rule would flag the
    /// suffixes and bury the real thing.
    /// </remarks>
    private static bool Related(string row, string mesh)
    {
        if (string.Equals(row, mesh, StringComparison.OrdinalIgnoreCase)) return true;

        string a = Stem(row), b = Stem(mesh);
        return a.Contains(b, StringComparison.OrdinalIgnoreCase)
               || b.Contains(a, StringComparison.OrdinalIgnoreCase);

        static string Stem(string value)
        {
            foreach (string suffix in new[] { "_Mesh", "MESH", "_mesh", "Mesh", "Anim", "_Anim" })
            {
                if (value.EndsWith(suffix, StringComparison.OrdinalIgnoreCase))
                    return value[..^suffix.Length];
            }
            return value;
        }
    }
}
