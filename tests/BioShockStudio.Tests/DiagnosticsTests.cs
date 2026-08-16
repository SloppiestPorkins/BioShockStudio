using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Diagnostics;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The diagnostics service — the aggregation of everything this tool already knows is wrong.
/// </summary>
/// <remarks>
/// <para>
/// Every fault found in the two sessions before this one was found by a human looking at the
/// viewport: grey security cameras, an armless splicer, a misaligned prop. In all three cases the
/// tool held the evidence and never surfaced it. This service exists to surface it, so the tests
/// that matter most are the ones proving each check <b>can fire</b> — a Problems panel that is
/// always empty is worse than no panel, because it reads as a clean bill of health.
/// </para>
/// <para>
/// Everything here runs against real shipped bytes, except the two that exercise the audit-to-
/// diagnostic translation, which build their input from a measurement taken from real bytes.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class DiagnosticsTests(GameFixture game)
{
    private string Map(string name) =>
        Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), name + ".bsm");

    private DiagnosticReport Scan(string map)
    {
        using var package = BioShockPackage.Open(Map(map));
        return AssetDiagnostics.ScanPackage(package, map);
    }

    /// <summary>
    /// A report always says what it examined.
    /// </summary>
    /// <remarks>
    /// Without coverage an empty report is ambiguous — nothing is wrong, or nothing was looked at —
    /// and those are opposite conclusions. This is the check that stops a scan which silently found
    /// no assets from reading as a clean game.
    /// </remarks>
    [RequiresGameFact]
    public void AReportSaysHowMuchItExamined()
    {
        var report = Scan("1-Medical");

        Assert.Equal(1, report.Coverage.Packages);
        Assert.True(report.Coverage.Meshes > 100, $"only {report.Coverage.Meshes} meshes examined");
        Assert.True(report.Coverage.Materials > 100, $"only {report.Coverage.Materials} materials examined");
        Assert.True(report.Coverage.Textures > 100, $"only {report.Coverage.Textures} textures examined");
        Assert.Contains("Examined", report.Summarise());
    }

    /// <summary>
    /// Every diagnostic is self-contained: asset, package, subsystem and the measurement behind it.
    /// </summary>
    /// <remarks>
    /// This is the "Copy Diagnostic" contract. A report is worth having only if it can be acted on
    /// without the session that produced it, so a row with an empty evidence field is a defect in
    /// the diagnostic rather than a cosmetic problem.
    /// </remarks>
    [RequiresGameFact]
    public void EveryDiagnosticCarriesItsAssetAndItsEvidence()
    {
        var report = Scan("1-Medical");
        Assert.NotEmpty(report.Diagnostics);

        foreach (var diagnostic in report.Diagnostics)
        {
            Assert.False(string.IsNullOrWhiteSpace(diagnostic.Code));
            Assert.False(string.IsNullOrWhiteSpace(diagnostic.Package));
            Assert.False(string.IsNullOrWhiteSpace(diagnostic.Asset));
            Assert.False(string.IsNullOrWhiteSpace(diagnostic.ClassName));
            Assert.False(string.IsNullOrWhiteSpace(diagnostic.Summary),
                $"{diagnostic.Code} on {diagnostic.Asset} has no summary");
            Assert.False(string.IsNullOrWhiteSpace(diagnostic.Evidence),
                $"{diagnostic.Code} on {diagnostic.Asset} has no evidence");

            string text = diagnostic.ToReport();
            Assert.Contains(diagnostic.Asset, text, StringComparison.Ordinal);
            Assert.Contains(diagnostic.Evidence, text, StringComparison.Ordinal);
            Assert.Contains(diagnostic.Package, text, StringComparison.Ordinal);
        }
    }

    /// <summary>
    /// The geometry check fires on the door rigs that carry no vertex data, and only on them.
    /// </summary>
    /// <remarks>
    /// These four are the known set — <c>SkeletalMeshGeometryTests</c> pins the names and the size
    /// separation. What is checked here is that the aggregation reaches them: a mesh that produces
    /// nothing must produce a diagnostic, not silence.
    /// </remarks>
    [RequiresGameFact]
    public void TheGeometryCheckFiresOnTheDoorRigsThatCarryNoVertices()
    {
        var report = Scan("1-Medical");

        var noGeometry = report.Diagnostics
            .Where(d => d.Code == DiagnosticCodes.MeshNoGeometry)
            .ToList();

        Assert.NotEmpty(noGeometry);
        Assert.All(noGeometry, d => Assert.Equal(DiagnosticSeverity.Broken, d.Severity));
        Assert.All(noGeometry, d => Assert.Equal(AssetClasses.SkeletalMesh, d.ClassName));

        // The payload size is the evidence the "carries none" reading rests on, so it has to be in
        // the row rather than only in the research note.
        Assert.All(noGeometry, d => Assert.Contains("byte payload", d.Evidence, StringComparison.Ordinal));
    }

    /// <summary>
    /// A scan of the same package twice yields the same diagnostics.
    /// </summary>
    /// <remarks>
    /// A report that is not stable cannot be compared between sessions, which is most of what it is
    /// for. This also catches a check whose result depends on dictionary or file-system ordering.
    /// </remarks>
    [RequiresGameFact]
    public void AScanIsRepeatable()
    {
        var first = Scan("0-Lighthouse");
        var second = Scan("0-Lighthouse");

        Assert.Equal(first.Coverage, second.Coverage);
        Assert.Equal(
            first.Diagnostics.Select(d => $"{d.Code}|{d.Asset}|{d.Evidence}"),
            second.Diagnostics.Select(d => $"{d.Code}|{d.Asset}|{d.Evidence}"));
    }

    /// <summary>
    /// The material checks fire, and a mesh whose surfaces all resolve produces none of them.
    /// </summary>
    /// <remarks>
    /// Both directions matter. <c>bat_vehicle</c> is the mesh whose two runs are pinned material by
    /// material in <c>MeshSurfaceTests</c>; if the diagnostic scan claims a fault on it, the fault is
    /// the scan's.
    /// </remarks>
    [RequiresGameFact]
    public void TheMaterialCheckIsSilentOnAMeshWhoseSurfacesAllResolve()
    {
        var report = Scan("0-Lighthouse");

        var onBathysphere = report.Diagnostics
            .Where(d => string.Equals(d.Asset, "bat_vehicle", StringComparison.OrdinalIgnoreCase)
                        && d.Subsystem == DiagnosticSubsystem.Materials)
            .ToList();

        Assert.True(onBathysphere.Count == 0,
            "bat_vehicle resolves both its materials, so a materials diagnostic on it is the scan's "
            + "own fault: " + string.Join("; ", onBathysphere.Select(d => d.ToString())));
    }

    /// <summary>
    /// A whole map produces material diagnostics, and each names the slot and what it points at.
    /// </summary>
    /// <remarks>
    /// The count is not pinned — it moves whenever material resolution improves, which is the point.
    /// What is pinned is that the check reaches something and says enough to act on.
    /// </remarks>
    [RequiresGameFact]
    public void TheUnresolvedSlotCheckFiresAndSaysWhatTheSlotPointsAt()
    {
        var report = Scan("1-Medical");

        var unresolved = report.Diagnostics
            .Where(d => d.Code == DiagnosticCodes.MeshSlotUnresolved)
            .ToList();

        Assert.NotEmpty(unresolved);
        Assert.All(unresolved, d => Assert.Contains("slot ", d.Evidence, StringComparison.Ordinal));
        Assert.All(unresolved, d => Assert.Contains("triangles", d.Evidence, StringComparison.Ordinal));
    }

    /// <summary>
    /// The scan reports the same unresolved slots the renderer would draw grey.
    /// </summary>
    /// <remarks>
    /// The whole value of the panel rests on this: a diagnostic must describe what the export
    /// pipeline actually produces, not what a second implementation of it thinks. So the check is
    /// made against <see cref="Core.Materials.MeshSurfaceResolver"/> itself — the one resolver the
    /// preview, the scene JSON, the FBX and Blender all share.
    /// </remarks>
    [RequiresGameFact]
    public void AnUnresolvedSlotDiagnosticMatchesWhatTheSharedResolverProduces()
    {
        using var package = BioShockPackage.Open(Map("1-Medical"));
        var report = AssetDiagnostics.ScanPackage(package, "1-Medical");

        var diagnostic = report.Diagnostics.First(d => d.Code == DiagnosticCodes.MeshSlotUnresolved);
        var export = package.Exports[diagnostic.ExportIndex];

        byte[] payload = package.ReadExportData(export);
        var geometry = Core.Mesh.MeshGeometryReader.Read(package.GetClassName(export), payload)!;
        var surfaces = Core.Materials.MeshSurfaceResolver.Resolve(package, export, geometry);

        int missing = surfaces.Count(s => s.Material is null);
        Assert.True(missing > 0,
            $"{diagnostic.Asset} was reported as having {missing} unresolved surfaces, but the "
            + "resolver the exporter uses resolves all of them");
        Assert.Contains($"{missing} of this mesh's", diagnostic.Summary, StringComparison.Ordinal);
    }

    // ------------------------------------------------------------------------- animation mapping

    /// <summary>
    /// A collapsed-bone measurement taken from real bytes becomes a diagnostic with its numbers
    /// intact.
    /// </summary>
    /// <remarks>
    /// <c>PI_Fire_B</c> is the animation a user photographed as an armless splicer, and it is the
    /// reason the audit grew a rigidity check at all — see <c>docs/HANDOFF.md</c> §6.0c. The
    /// measurement is taken here from the shipped animation rather than invented, so if the decode is
    /// ever fixed this test changes with it instead of enshrining the fault.
    /// </remarks>
    [RequiresGameFact]
    public void ACollapsedBoneMeasurementBecomesADiagnostic()
    {
        using var package = BioShockPackage.Open(Map("1-Medical"));

        var wrapper = package.Exports
            .Where(e => e.ObjectName == "UAPW_AggressorBabyJane"
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize)!;

        var animations = AnimationPackage.Load(package, wrapper);
        var fire = animations.Animations.First(a =>
            string.Equals(a.Name, "PI_Fire_B", StringComparison.OrdinalIgnoreCase));

        var (count, frame, bone) = AnimationAudit.WorstCollapse(
            animations.Skeleton, animations.Decode(fire));

        Assert.True(count > 0, "PI_Fire_B no longer collapses any bone — update §6.0c and this test");

        var report = AssetDiagnostics.FromAnimationAudit(new AnimationAuditReport
        {
            Rows =
            [
                Row(fire.Name, AnimationStatus.Playable, string.Empty) with
                {
                    SkeletonName = animations.Skeleton.Name,
                    BoneCount = animations.Skeleton.BoneCount,
                    TrackCount = fire.TransformTrackCount,
                    FrameCount = fire.FrameCount,
                    FrameRate = fire.FrameRate,
                    BlocksLookComplete = true,
                    WorstCollapsedBones = count,
                    WorstCollapseFrame = frame,
                    WorstCollapseBone = bone,
                },
            ],
            PackageFailures = [],
            PackageCount = 1,
            WrapperCount = 1,
            SkeletonCount = 1,
        });

        var collapse = Assert.Single(report.Diagnostics);
        Assert.Equal(DiagnosticCodes.AnimationBonesCollapse, collapse.Code);
        Assert.Equal(DiagnosticSeverity.Degraded, collapse.Severity);
        Assert.Equal("PI_Fire_B", collapse.Asset);
        Assert.Contains($"{count} bone(s)", collapse.Summary, StringComparison.Ordinal);
        Assert.Contains($"frame {frame}", collapse.Evidence, StringComparison.Ordinal);
        Assert.Contains("§6.0c", collapse.Reference, StringComparison.Ordinal);
        Assert.Equal(1, report.Coverage.Animations);
    }

    /// <summary>
    /// Each animation status maps to the severity that matches what the user loses.
    /// </summary>
    /// <remarks>
    /// A failed animation is <c>Broken</c> — there is nothing to export. An unsupported compression
    /// is a <c>Note</c>, because it is a limit of this tool rather than a fault in the data, and
    /// filing it as broken would bury the faults that are real.
    /// </remarks>
    [Fact]
    public void EachAnimationStatusMapsToItsOwnSeverity()
    {
        var report = AssetDiagnostics.FromAnimationAudit(new AnimationAuditReport
        {
            Rows =
            [
                // Deliberately left with BlocksLookComplete false, its default: an animation that
                // did not decode never walked a block, and must not be reported for that as well.
                Row("a", AnimationStatus.Failed, "decode threw"),
                Row("b", AnimationStatus.Unsupported, "hkaWaveletCompressedAnimation is not implemented"),
                Row("c", AnimationStatus.Partial, "a rotation key has length 1.4") with { BlocksLookComplete = true },
                Row("d", AnimationStatus.Playable, string.Empty) with
                {
                    BlocksLookComplete = false, WorstBlockSlack = 96,
                },
                Row("e", AnimationStatus.Playable, string.Empty) with { BlocksLookComplete = true },
            ],
            PackageFailures = [("Entry", "UAPW_Broken", "no Havok magic")],
            PackageCount = 1,
            WrapperCount = 1,
            SkeletonCount = 1,
        });

        var byCode = report.Diagnostics.ToDictionary(d => d.Code);

        Assert.Equal(DiagnosticSeverity.Broken, byCode[DiagnosticCodes.AnimationPackageFailed].Severity);
        Assert.Equal(DiagnosticSeverity.Broken, byCode[DiagnosticCodes.AnimationFailed].Severity);
        Assert.Equal(DiagnosticSeverity.Note, byCode[DiagnosticCodes.AnimationUnsupported].Severity);
        Assert.Equal(DiagnosticSeverity.Degraded, byCode[DiagnosticCodes.AnimationPartial].Severity);
        Assert.Equal(DiagnosticSeverity.Broken, byCode[DiagnosticCodes.AnimationBlockSlack].Severity);

        // The playable, complete one produces nothing. A diagnostic on a healthy animation would
        // make the panel noise, and noise is what stops a panel being read.
        Assert.Equal(5, report.Diagnostics.Count);
        Assert.DoesNotContain(report.Diagnostics, d => d.Asset == "e");
    }

    /// <summary>An animation that never decoded is not also reported as an unconsumed block.</summary>
    /// <remarks>
    /// An animation this tool cannot decompress, or that threw, never walks a block, so its block
    /// walk is trivially incomplete. Reporting that as a second, separate decode fault would blame
    /// the reader twice for one thing and would inflate the broken count.
    /// </remarks>
    [Fact]
    public void AnAnimationThatNeverDecodedIsNotAlsoReportedAsAnUnreadBlock()
    {
        var report = AssetDiagnostics.FromAnimationAudit(new AnimationAuditReport
        {
            Rows =
            [
                Row("a", AnimationStatus.Unsupported, "not implemented"),
                Row("b", AnimationStatus.Failed, "decode threw"),
            ],
            PackageFailures = [],
            PackageCount = 1,
            WrapperCount = 1,
            SkeletonCount = 1,
        });

        Assert.DoesNotContain(report.Diagnostics, d => d.Code == DiagnosticCodes.AnimationBlockSlack);

        // But a decoded animation with an unconsumed block still is — the check has to fire.
        var incomplete = AssetDiagnostics.FromAnimationAudit(new AnimationAuditReport
        {
            Rows = [Row("c", AnimationStatus.Playable, string.Empty) with { WorstBlockSlack = 96 }],
            PackageFailures = [],
            PackageCount = 1,
            WrapperCount = 1,
            SkeletonCount = 1,
        });

        Assert.Contains(incomplete.Diagnostics, d => d.Code == DiagnosticCodes.AnimationBlockSlack);
    }

    /// <summary>The summary states coverage even when nothing is wrong.</summary>
    [Fact]
    public void AnEmptyReportStillSaysWhatWasExamined()
    {
        string summary = new DiagnosticReport
        {
            Diagnostics = [],
            Coverage = new DiagnosticCoverage { Packages = 1, Meshes = 610 },
        }.Summarise();

        Assert.Contains("610", summary, StringComparison.Ordinal);
        Assert.Contains("none fired", summary, StringComparison.Ordinal);
    }

    private static AnimationAuditRow Row(string name, AnimationStatus status, string reason) => new()
    {
        Package = "Entry",
        Wrapper = "UAPW_Test",
        Owner = "Pistol",
        Name = name,
        Status = status,
        Reason = reason,
        Compression = "Spline",
        SkeletonName = "Test",
        BoneCount = 10,
        FrameCount = 4,
        FrameRate = 30f,
        TrackCount = 10,
        BoundTrackCount = 10,
        EventCount = 0,
    };
}
