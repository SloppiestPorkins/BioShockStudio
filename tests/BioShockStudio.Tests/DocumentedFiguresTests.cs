using BioShockStudio.Core.Diagnostics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Services;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The figures written down in <c>docs/QUALITY.md</c> still hold.
/// </summary>
/// <remarks>
/// <para>
/// Measured numbers get copied into prose by hand and rot immediately. "73.9% of meshes have a
/// diffuse texture" was stated in three documents and was wrong in all three within one session,
/// and nothing anywhere could tell you that. The tool already produces these numbers — this makes
/// the documentation a thing that can go <i>red</i> rather than a thing that quietly goes stale.
/// </para>
/// <para>
/// <b>A failure here is not necessarily a regression.</b> It means the game as measured no longer
/// matches what <c>docs/QUALITY.md</c> claims, and there are two honest responses: the code got
/// better and the document should be updated to the new figure, or the code got worse and the
/// figure is telling you so. Classify it before changing either — see
/// <c>docs/ENGINEERING_RULES.md</c> §24. Do <b>not</b> relax an assertion to make it pass; that
/// converts the one mechanism that notices drift into a rubber stamp.
/// </para>
/// <para>
/// Every number below is quoted in <c>docs/QUALITY.md</c> §"Whole-game diagnostic sweep" and its
/// headline table. Keep the two in step in the same commit.
/// </para>
/// </remarks>
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class DocumentedFiguresTests
{
    /// <summary>
    /// The whole-game sweep, run once for the class.
    /// </summary>
    /// <remarks>
    /// It reads every mesh, material and texture in the install and costs minutes, so the tests
    /// below share one run rather than each paying for their own. It is the same call the
    /// <c>diagnose</c> command makes, with the same two sources — without the external material
    /// source and the bulk texture catalogue it would report faults the exporter does not have.
    /// </remarks>
    private static readonly Lazy<DiagnosticReport?> Sweep = new(() =>
    {
        if (GameLocator.Find() is not { } root) return null;

        return AssetDiagnostics.Run(root, new PackageMaterialSource(root), BulkTextureCatalog.Load(root));
    });

    /// <summary>
    /// The sweep, or a failure — never a silent skip.
    /// </summary>
    /// <remarks>
    /// <b>These tests must not be able to pass without measuring anything.</b> The first version
    /// returned early when the sweep produced nothing, which would have turned "the install was not
    /// readable" into a green tick asserting the documented figures were correct.
    /// <see cref="RequiresGameFactAttribute"/> already skips the whole test when the game is not
    /// installed, so by the time a body runs the install exists and a null or empty report is a real
    /// failure rather than an absence.
    /// <para>
    /// <b>Do not read the runner's reported duration as evidence that this ran.</b> It shows about
    /// eight milliseconds for the four tests while the run really takes two to three minutes: the
    /// sweep happens in this class's static initialiser, which the CLR is free to run outside the
    /// window xUnit times. The wall clock is the honest figure, and the assertions below are what
    /// prove the work happened.
    /// </para>
    /// </remarks>
    private static DiagnosticReport Measured()
    {
        var report = Sweep.Value;

        Assert.True(report is not null,
            "the whole-game sweep produced nothing, though the install was found. These assertions "
            + "cannot be allowed to pass without it: a green result would claim the documented "
            + "figures had been checked when nothing was read.");

        Assert.True(report!.Coverage.Meshes > 0 && report.Coverage.Textures > 0,
            $"the sweep examined {report.Coverage.Meshes} meshes and {report.Coverage.Textures} "
            + "textures, so it did not actually run over the install.");

        return report;
    }

    private static int CountOf(DiagnosticReport report, string code) =>
        report.Diagnostics.Count(d => d.Code == code);

    /// <summary>
    /// Coverage: how much of the game the sweep looked at.
    /// </summary>
    /// <remarks>
    /// This is the figure that matters most, and it is the one a reader skips. Every other number
    /// here is a count of faults, and a fault count is meaningless without knowing what was
    /// examined — "no problems" and "nothing ran" are opposite conclusions that otherwise render
    /// identically.
    /// </remarks>
    [RequiresGameFact]
    public void TheSweepExaminesWhatTheQualityNoteSaysItExamines()
    {
        var report = Measured();

        var coverage = report.Coverage;
        int total = coverage.Meshes + coverage.Materials + coverage.Textures;

        Assert.Equal(33, coverage.Packages);
        Assert.Equal(9_684, coverage.Meshes);
        Assert.Equal(14_328, coverage.Materials);
        Assert.Equal(31_106, coverage.Textures);

        // The headline "55,118 assets examined" is the sum of the three, and is quoted as such.
        Assert.Equal(55_118, total);
    }

    /// <summary>The totals by severity, as the quality note's sweep section states them.</summary>
    /// <remarks>
    /// Was 582/64/365/153, then 490/19/314/157 — each move a real fix, not a regression: (1)
    /// <c>AssetDiagnostics.ScanExport</c> checked <c>MaterialReader.IsMaterialClass</c> before the
    /// texture-class check, so every <c>Texture</c> export (also a valid material-slot value) was
    /// swallowed into the Materials bucket and the sweep silently examined 0 textures; (2)
    /// <c>TextureReader</c> now decodes UE2's constant-colour <c>MipZero</c> texture variant, which
    /// several "no Format property" textures turn out to actually be; (3) <c>ScanMesh</c> called
    /// <c>MeshGeometryReader.Read</c>'s 2-arg overload, so a <c>SkeletalMesh</c>'s
    /// <c>geometry.Sections</c> was always empty and the sweep couldn't tell a mesh whose section
    /// table genuinely didn't resolve from one that resolved fine and just names >1 material — fixed
    /// by calling the package-aware overload. See <c>docs/QUALITY.md</c>.
    /// <para>
    /// Then 427/19/314/94 to <b>333/19/314/0</b>, 22 Aug 2026: the whole 94-finding drop is
    /// <c>mesh-materials-without-sections</c> going to zero, and 427 − 94 = 333 exactly, with no
    /// other code moving. <c>SkeletalMeshSectionReader</c> gained a second route to the section
    /// table that counts backward from the bone map instead of walking forward from the socket
    /// table, so a mesh with no sockets no longer loses its sections for an unrelated reason:
    /// coverage went from <b>331 of 944 exports (35%) to 966 of 967 (99.9%)</b>, and the two routes
    /// produce byte-identical tables wherever both succeed. <c>SkeletalMeshSectionCoverageTests</c>.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheDiagnosticTotalsStillHold()
    {
        var report = Measured();

        Assert.Equal(333, report.Diagnostics.Count);
        Assert.Equal(19, report.Count(DiagnosticSeverity.Broken));
        Assert.Equal(314, report.Count(DiagnosticSeverity.Degraded));
        Assert.Equal(0, report.Count(DiagnosticSeverity.Note));
    }

    /// <summary>
    /// The per-code counts in the quality note's table.
    /// </summary>
    /// <remarks>
    /// Two of these are cross-checked by other tests, which is what says the sweep is measuring the
    /// same game rather than merely being self-consistent: the 18 <c>mesh-no-geometry</c> are the 18
    /// door exports <c>SkeletalMeshGeometryTests</c> names, and the 2 <c>mesh-uv-out-of-range</c>
    /// are <c>BatPath</c> and <c>Shadow_Scissors</c>.
    /// </remarks>
    [RequiresGameFact]
    public void ThePerCodeCountsStillHold()
    {
        var report = Measured();

        Assert.Equal(1, CountOf(report, DiagnosticCodes.TextureUndecodable));
        Assert.Equal(18, CountOf(report, DiagnosticCodes.MeshNoGeometry));
        Assert.Equal(202, CountOf(report, DiagnosticCodes.MeshNoDiffuse));
        Assert.Equal(110, CountOf(report, DiagnosticCodes.MeshSlotUnresolved));
        Assert.Equal(2, CountOf(report, DiagnosticCodes.MeshUvOutOfRange));
        // Zero since the section table gained a second locator, 22 Aug 2026. Kept as an assertion
        // rather than deleted: this code firing again would mean skeletal meshes are back to drawing
        // several materials in one, which is invisible to every other count.
        Assert.Equal(0, CountOf(report, DiagnosticCodes.MeshNoSections));
    }

    /// <summary>
    /// How many meshes carry a base-colour fault, and the share that therefore do not.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>This asserts 312, not the 363 the previous measurement found, and the difference is a real
    /// improvement rather than a regression.</b> Two independent fixes shrank both contributing
    /// codes: <c>AssetDiagnostics.ScanExport</c> was checking <c>MaterialReader.IsMaterialClass</c>
    /// before the texture-class check, which swallowed every <c>Texture</c> export into the
    /// Materials bucket and meant the sweep silently examined 0 textures — reordering the two checks
    /// let <c>mesh-material-slot-unresolved</c> actually resolve slots that name a Texture directly;
    /// and <c>TextureReader</c> now decodes UE2's constant-colour <c>MipZero</c> variant, which
    /// several previously-"undecodable" base-colour textures turn out to be. 240 → 202
    /// <c>mesh-no-diffuse</c>, 123 → 110 <c>mesh-material-slot-unresolved</c>, still disjoint
    /// (202 + 110 = 312).
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheShareOfMeshesCarryingABaseColourStillHolds()
    {
        var report = Measured();

        var affected = report.Diagnostics
            .Where(d => d.Code is DiagnosticCodes.MeshNoDiffuse or DiagnosticCodes.MeshSlotUnresolved)
            .Select(d => $"{d.Package}/{d.Asset}")
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        // Disjoint on the shipped game. Asserted rather than assumed, because if the two codes ever
        // start overlapping the sum below stops being the distinct count and this figure moves for a
        // reason that has nothing to do with the game getting better or worse.
        Assert.Equal(
            CountOf(report, DiagnosticCodes.MeshNoDiffuse) + CountOf(report, DiagnosticCodes.MeshSlotUnresolved),
            affected.Count);

        Assert.Equal(312, affected.Count);

        // 9,372 of 9,684. Compared to one decimal place rather than as an exact double, because a
        // rounded percentage is what the documentation quotes and exact equality on a double is a
        // trap this assertion should not be setting for the next person.
        double percent = 100.0 * (report.Coverage.Meshes - affected.Count) / report.Coverage.Meshes;
        Assert.Equal(96.8, percent, 1);
    }
}
