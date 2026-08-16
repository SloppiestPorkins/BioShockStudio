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
        Assert.Equal(13_545, coverage.Materials);
        Assert.Equal(31_106, coverage.Textures);

        // The headline "54,335 assets examined" is the sum of the three, and is quoted as such.
        Assert.Equal(54_335, total);
    }

    /// <summary>The totals by severity, as the quality note's sweep section states them.</summary>
    [RequiresGameFact]
    public void TheDiagnosticTotalsStillHold()
    {
        var report = Measured();

        Assert.Equal(582, report.Diagnostics.Count);
        Assert.Equal(64, report.Count(DiagnosticSeverity.Broken));
        Assert.Equal(365, report.Count(DiagnosticSeverity.Degraded));
        Assert.Equal(153, report.Count(DiagnosticSeverity.Note));
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

        Assert.Equal(46, CountOf(report, DiagnosticCodes.TextureUndecodable));
        Assert.Equal(18, CountOf(report, DiagnosticCodes.MeshNoGeometry));
        Assert.Equal(240, CountOf(report, DiagnosticCodes.MeshNoDiffuse));
        Assert.Equal(123, CountOf(report, DiagnosticCodes.MeshSlotUnresolved));
        Assert.Equal(2, CountOf(report, DiagnosticCodes.MeshUvOutOfRange));
        Assert.Equal(153, CountOf(report, DiagnosticCodes.MeshNoSections));
    }

    /// <summary>
    /// How many meshes carry a base-colour fault, and the share that therefore do not.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>This asserts 363, not the 347 that <c>docs/QUALITY.md</c> quoted, and the difference is a
    /// real finding rather than a regression.</b> The two count different things:
    /// </para>
    /// <list type="bullet">
    /// <item><b>363</b> — distinct meshes raising <i>either</i> base-colour diagnostic. The two codes
    /// turn out to be disjoint on the shipped game (240 + 123, no mesh raises both), and this is
    /// reproducible from the <c>diagnose</c> output, which is why it is what gets asserted.</item>
    /// <item><b>347</b> — the previously published figure, from a stricter rule: meshes with no base
    /// colour <i>at all</i>, being the 240 plus only those slot-unresolved meshes whose <i>every</i>
    /// surface resolves nothing. A mesh with one unresolved slot out of three still has a base
    /// colour, so 347 is the smaller and more meaningful number.</item>
    /// </list>
    /// <para>
    /// <b>The report does not distinguish the two, so 347 cannot be reproduced from it</b>, and the
    /// derivation was not written down anywhere — which is exactly the rot this class exists to
    /// catch. 363 is therefore an upper bound on meshes lacking a base colour, and 96.2% a lower
    /// bound on those carrying one. Pinning 347 properly needs a per-mesh surface measurement the
    /// sweep does not currently expose; that is recorded as open rather than faked here.
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

        Assert.Equal(363, affected.Count);

        // 9,321 of 9,684. Compared to one decimal place rather than as an exact double, because a
        // rounded percentage is what the documentation quotes and exact equality on a double is a
        // trap this assertion should not be setting for the next person.
        double percent = 100.0 * (report.Coverage.Meshes - affected.Count) / report.Coverage.Meshes;
        Assert.Equal(96.3, percent, 1);
    }
}
