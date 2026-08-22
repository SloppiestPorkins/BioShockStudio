using System.Numerics;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// This project's actor placement, checked against the reference level editor's own matrix
/// construction — on every rotation the shipped game actually contains, not on a chosen case.
/// </summary>
/// <remarks>
/// <para>
/// <b>Why this exists.</b> The pitch sign in <see cref="UnrealRotator.ToQuaternion"/> was wrong for
/// the whole life of the level viewer and was found by a user's screenshot of one warped ceiling
/// arch. It was then settled by matching this project's composition against Nyko's
/// <c>BuildActorTransform</c> numerically — but that comparison was a throwaway probe run in one
/// session, and the only thing committed from it was
/// <c>LevelSceneTests.TheMedicalPavilionCeilingArchFormsOneContinuousSurface</c>: a single-case
/// geometric assertion on four instances of one mesh in one map. A rule verified on one view is
/// exactly what produced the bug in the first place, so the reference comparison is committed here
/// and run against the whole shipped population.
/// </para>
/// <para>
/// <b>The reference.</b> <c>Bioshock1REMSDK-WIP--main/tools/level_editor/src/viewport.cpp</c>,
/// <c>BuildActorTransform</c>, is reimplemented literally below — same column-major <c>float[16]</c>,
/// same index arithmetic, same multiplication order — so it can be diffed against the C++ by eye
/// rather than trusted as a paraphrase. Its rotator-to-degrees conversion is
/// <c>bsm_document.cpp:449-457</c>, and it reads the same three int32s in the same order this
/// project does.
/// </para>
/// <para>
/// <b>The one deliberate difference, stated rather than hidden.</b> The reference builds
/// <c>T · R · S</c> and does <b>not</b> apply <c>PrePivot</c> to an actor — the field appears in its
/// source only as a name in a skip list. This project does apply it, on separate and stronger
/// evidence (33,631 of 33,632 world polygons land in a plane of their own brush under
/// <c>Location − PrePivot</c>, against 2.9% without it — <c>BrushPlacementTests</c>). So the
/// comparison here is over the three fields the reference actually composes, and the pre-pivot
/// term is held at zero. That is a boundary of what this test can say, not a defect in either side.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class ActorTransformReferenceTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    // ---------------------------------------------------------------------------------------
    // Nyko's viewport.cpp, transcribed. Column-major float[16], m[col * 4 + row], v' = M · v.
    // ---------------------------------------------------------------------------------------

    private static float[] MulMat4(float[] a, float[] b)
    {
        var r = new float[16];
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
            {
                r[j * 4 + i] = 0;
                for (int k = 0; k < 4; k++)
                    r[j * 4 + i] += a[k * 4 + i] * b[j * 4 + k];
            }
        return r;
    }

    private static float[] TranslateMat4(float x, float y, float z)
    {
        var m = new float[16];
        m[0] = 1; m[5] = 1; m[10] = 1; m[15] = 1;
        m[12] = x; m[13] = y; m[14] = z;
        return m;
    }

    private static float[] ScaleMat4xyz(float sx, float sy, float sz)
    {
        var m = new float[16];
        m[0] = sx; m[5] = sy; m[10] = sz; m[15] = 1;
        return m;
    }

    private static float[] RotateYMat4(float deg)
    {
        float r = deg * 3.14159265f / 180.0f;
        float c = MathF.Cos(r), s = MathF.Sin(r);
        var m = new float[16];
        m[0] = c; m[2] = s;
        m[5] = 1;
        m[8] = -s; m[10] = c;
        m[15] = 1;
        return m;
    }

    private static float[] RotateXMat4(float deg)
    {
        float r = deg * 3.14159265f / 180.0f;
        float c = MathF.Cos(r), s = MathF.Sin(r);
        var m = new float[16];
        m[0] = 1;
        m[5] = c; m[6] = s;
        m[9] = -s; m[10] = c;
        m[15] = 1;
        return m;
    }

    private static float[] RotateZMat4(float deg)
    {
        float r = deg * 3.14159265f / 180.0f;
        float c = MathF.Cos(r), s = MathF.Sin(r);
        var m = new float[16];
        m[0] = c; m[1] = s;
        m[4] = -s; m[5] = c;
        m[10] = 1;
        m[15] = 1;
        return m;
    }

    /// <summary>
    /// <c>BuildActorTransform</c>: <c>T · Yaw · Pitch · Roll · S</c>, with rot = (pitch, yaw, roll)
    /// in degrees, yaw about Z, pitch about Y, roll about X.
    /// </summary>
    private static float[] BuildActorTransform(Vector3 loc, Vector3 rot, Vector3 scale)
    {
        var t = TranslateMat4(loc.X, loc.Y, loc.Z);
        var s = ScaleMat4xyz(scale.X, scale.Y, scale.Z);
        var ry = RotateZMat4(rot.Y);
        var rp = RotateYMat4(rot.X);
        var rr = RotateXMat4(rot.Z);
        var r = MulMat4(ry, MulMat4(rp, rr));
        return MulMat4(t, MulMat4(r, s));
    }

    /// <summary>The reference's own rotator-to-degrees conversion (<c>bsm_document.cpp:454-456</c>).</summary>
    private static Vector3 ReferenceDegrees(UnrealRotator rotation) => new(
        rotation.Pitch * (360.0f / 65536.0f),
        rotation.Yaw * (360.0f / 65536.0f),
        rotation.Roll * (360.0f / 65536.0f));

    /// <summary>
    /// The reference construction with the one correction this project has evidence for: roll
    /// negated.
    /// </summary>
    /// <remarks>
    /// <b>Feeding a negated roll into the reference is the same thing as negating roll in our own
    /// composition</b>, so comparing against this still exercises everything else the reference
    /// defines — the axis assignment, the multiplication order, the scale and translation terms, the
    /// row/column convention. Only the one term this project deliberately differs on is normalised
    /// out, and <see cref="TheDivergenceFromTheReferencesRollIsDeliberateAndMeasured"/> pins how
    /// large that difference is so it cannot be mistaken for agreement.
    /// </remarks>
    private static Vector3 ReferenceDegreesWithCorrectedRoll(UnrealRotator rotation) => new(
        rotation.Pitch * (360.0f / 65536.0f),
        rotation.Yaw * (360.0f / 65536.0f),
        -rotation.Roll * (360.0f / 65536.0f));

    // ---------------------------------------------------------------------------------------

    /// <summary>
    /// The worst single-component difference between this project's row-vector matrix and the
    /// reference's column-vector one.
    /// </summary>
    /// <remarks>
    /// A row-vector local-to-world matrix is the transpose of the column-vector one for the same
    /// transform, so <c>ours[i][j] == theirs[j][i]</c>, which in the reference's own storage
    /// (<c>m[col * 4 + row]</c>) is <c>reference[i * 4 + j]</c>. Checking all sixteen components is
    /// strictly stronger than applying both to probe vectors, and it needs no probe choice to
    /// justify.
    /// </remarks>
    private static float WorstComponentDifference(Matrix4x4 ours, float[] reference)
    {
        var oursByIndex = new[]
        {
            ours.M11, ours.M12, ours.M13, ours.M14,
            ours.M21, ours.M22, ours.M23, ours.M24,
            ours.M31, ours.M32, ours.M33, ours.M34,
            ours.M41, ours.M42, ours.M43, ours.M44,
        };

        float worst = 0f;
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                worst = MathF.Max(worst, MathF.Abs(oursByIndex[i * 4 + j] - reference[i * 4 + j]));
        return worst;
    }

    /// <summary>
    /// Whether this rotation's roll is unchanged by negating it — a roll of 0 or ±180°.
    /// </summary>
    /// <remarks>
    /// These are the rotations on which this project and the reference still agree exactly, because
    /// the one correction this project applies on top of the reference (negating roll) is the
    /// identity for them. The Medical Pavilion arch that produced the pitch fix is entirely in this
    /// set, which is why that fix and the roll fix are independent.
    /// </remarks>
    private static bool RollIsItsOwnNegation(UnrealRotator rotation)
    {
        float roll = rotation.ToDegrees().X;
        return MathF.Abs(MathF.Sin(roll * MathF.PI / 180f)) < 1e-5f;
    }

    private sealed record Placement(string Map, string Actor, ActorTransform Transform)
    {
        public bool IsThreeAxis =>
            Transform.Rotation.Pitch != 0 && Transform.Rotation.Yaw != 0 && Transform.Rotation.Roll != 0;

        /// <summary>Pitch in degrees, wrapped to -180..180 — the angle that is actually applied.</summary>
        public float PitchDegrees => Transform.Rotation.ToDegrees().Y;

        /// <summary>
        /// How far negating this actor's pitch would move its matrix.
        /// </summary>
        /// <remarks>
        /// <para>
        /// <b>Derived, then checked against the measurement.</b> Flipping the sign replaces
        /// <c>Ry(−p)</c> with <c>Ry(p)</c>, so the off-diagonal terms move by <c>2·sin(p)</c> and
        /// every rotation component carries the actor's scale. The prediction
        /// <c>2·|sin(p)|·max(scale)</c> was checked against measured differences and reproduces them
        /// to four significant figures — <c>1-Medical ShrubLarge6</c> (pitch −8 units, scale 0.6)
        /// predicted 0.00092039 against 0.00092039 measured; <c>3-Arcadia StaticMeshActor1449</c>
        /// (pitch 12, scale 3.1) 0.0071330 against 0.0071330; <c>2-Fisheries StaticMeshActor4946</c>
        /// (pitch −208, scale 0.06) 0.0023930 against 0.0023929. It is the model, not a curve fit.
        /// <see cref="ThePitchSignIsMathematicallyInvisibleAtZeroAndAHalfTurn"/> pins the two angles
        /// where it is exactly zero.
        /// </para>
        /// <para>
        /// This is not a fudge factor. It is the reason a whole-game sweep cannot simply assert
        /// "every rotated actor rejects the wrong sign". Of the game's 12,557 distinct
        /// rotation/scale pairs, <b>6,215 are observable</b> at this threshold; of the 6,342 that
        /// are not, <b>6,167 sit at a pitch of exactly 0° or 180°</b>, where the two signs are the
        /// same rotation, and the remaining <b>175 combine a pitch of under ~1.2° with a scale
        /// small enough</b> that the error, though real, falls below float noise on a level-sized
        /// translation. Naming that quantity is what lets the falsification check assert on the
        /// population it can actually judge, instead of a tolerance tuned until the count came out
        /// even.
        /// </para>
        /// </remarks>
        public float PitchSignObservability =>
            2f * MathF.Abs(MathF.Sin(PitchDegrees * MathF.PI / 180f))
            * MathF.Max(MathF.Max(Transform.Scale.X, Transform.Scale.Y), Transform.Scale.Z);
    }

    /// <summary>
    /// Comfortably above <see cref="Tolerance"/>: a rotation this far from its mirror is one the
    /// comparison is entitled to insist on.
    /// </summary>
    private const float Observable = 0.05f;

    /// <summary>
    /// A level's translations reach ~130,000 cm, where a <c>float</c> step is already ~0.016, so
    /// this is a float-precision allowance rather than a chosen tolerance. The measured worst
    /// difference across the whole game is ~1e-5, three orders inside it.
    /// </summary>
    private const float Tolerance = 1e-2f;

    private static bool IsUniform(Vector3 scale) =>
        MathF.Abs(scale.X - scale.Y) < 1e-6f && MathF.Abs(scale.Y - scale.Z) < 1e-6f;

    /// <summary>
    /// Every distinct rotation-and-scale the shipped maps place an actor at, with a real actor
    /// carrying it.
    /// </summary>
    /// <remarks>
    /// Keyed on the scale as well as the rotation so the sweep exercises the <i>composition order</i>
    /// and not only the rotation: <c>T · R · S</c> and <c>T · S · R</c> agree for every uniform
    /// scale and diverge for a non-uniform one, so a population of uniform scales would leave that
    /// ordering as unverified as a yaw-only population leaves the pitch sign.
    /// </remarks>
    private List<Placement> ShippedPlacements()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
            .OrderBy(f => f, StringComparer.Ordinal).ToList();

        var distinct = new Dictionary<(UnrealRotator Rotation, Vector3 Scale), Placement>();
        int actors = 0, rotated = 0;

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var context = LevelAnalyzer.Analyze(package);
            string name = Path.GetFileNameWithoutExtension(map);

            foreach (var actor in context.Actors)
            {
                actors++;
                if (actor.Transform.Rotation.IsIdentity) continue;
                rotated++;
                distinct.TryAdd(
                    (actor.Transform.Rotation, actor.Transform.Scale),
                    new Placement(name, actor.Source.ObjectName, actor.Transform));
            }
        }

        Log($"{maps.Count} .bsm packages, {actors} actors, {rotated} rotated, "
            + $"{distinct.Count} distinct rotation/scale pairs");

        Assert.True(maps.Count >= 20, $"only {maps.Count} packages were swept");
        return [.. distinct.Values.OrderBy(p => p.Map, StringComparer.Ordinal)];
    }

    /// <summary>
    /// The whole-game check: every distinct actor rotation in the shipped game, composed with that
    /// actor's own location and scale, against the reference editor's construction.
    /// </summary>
    [RequiresGameFact]
    public void EveryRotationTheGameShipsMatchesTheReferenceEditorsConstruction()
    {
        var placements = ShippedPlacements();

        float worst = 0f;
        Placement? worstAt = null;

        foreach (var placement in placements)
        {
            // PrePivot held at zero: the reference does not compose it, per this class's remarks.
            var transform = placement.Transform with { PrePivot = Vector3.Zero };

            var reference = BuildActorTransform(
                transform.Location, ReferenceDegreesWithCorrectedRoll(transform.Rotation), transform.Scale);

            float difference = WorstComponentDifference(transform.ToMatrix(), reference);
            if (difference > worst) { worst = difference; worstAt = placement; }
        }

        int threeAxis = placements.Count(p => p.IsThreeAxis);
        int pitchObservable = placements.Count(p => p.PitchSignObservability > Observable);
        int nonUniformScale = placements.Count(p => !IsUniform(p.Transform.Scale));

        Log($"{placements.Count} distinct rotation/scale pairs, {threeAxis} three-axis, "
            + $"{pitchObservable} where the pitch sign is observable, "
            + $"{nonUniformScale} non-uniformly scaled");
        foreach (var p in placements.Where(p => !IsUniform(p.Transform.Scale)))
            Log($"  non-uniform scale: {p.Map} {p.Actor} {p.Transform.Rotation} "
                + $"scale {p.Transform.Scale}");
        Log($"worst component difference {worst:0.######}"
            + (worstAt is null ? "" : $" at {worstAt.Map} {worstAt.Actor} {worstAt.Transform.Rotation}"));

        // Not vacuous, and specifically not blind the way the skyline render was: a yaw-only
        // population cannot see a pitch sign at all, which is how the arch bug survived a rendered
        // level. Assert the population contains rotations that can see it.
        Assert.True(placements.Count > 1_000,
            $"only {placements.Count} distinct rotation/scale pairs found across the game");
        Assert.True(pitchObservable > 1_000,
            $"only {pitchObservable} of {placements.Count} rotations can distinguish the pitch sign, "
            + "so this sweep would be as blind to it as the skyline render was");
        Assert.True(threeAxis > 0, "no genuinely three-axis rotation in the whole game");

        // The same argument applied to the scale term, and here the answer is the uncomfortable
        // one: a uniform scale commutes with the rotation, so only a non-uniform one can tell
        // T·R·S from T·S·R — and the whole shipped game contains exactly TWO rotated actors that
        // carry one, both in 1-Welcome, both scaled <0.7, 0.687, 0.7>. That is 1.8% off uniform,
        // which moves the matrix by about a hundredth of a unit: present, but not a sample this
        // comparison could claim settles the ordering. Asserted as the census it is, so a future
        // session that finds it red has found a better sample.
        // TheScaleCompositionOrderIsCheckedAgainstTheReferenceUnderAProbeScale covers the ordering
        // itself, because shipped data cannot.
        Assert.Equal(2, nonUniformScale);

        Assert.True(worst < Tolerance,
            $"worst component difference {worst} against the reference construction"
            + (worstAt is null ? "" : $", at {worstAt.Map} {worstAt.Actor} {worstAt.Transform.Rotation}"));
    }

    /// <summary>
    /// The same comparison, run against the sign this project actually shipped, to prove the check
    /// above can fail.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A passing comparison means nothing unless the wrong answer fails it. This rebuilds the
    /// quaternion with <c>+pitch</c> — the exact composition that shipped, and that drew every
    /// three-axis actor in the game wrong — and asserts the reference comparison rejects it by a
    /// wide margin.
    /// </para>
    /// <para>
    /// This project has been caught by precisely this gap before: two geometric metrics written to
    /// catch the backwards first-person pistol both passed the broken pistol
    /// (<c>docs/HANDOFF.md</c> §"Several sockets share one bone"). A check that has never been seen
    /// to fail is not evidence.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheReferenceComparisonRejectsTheWrongPitchSign()
    {
        var placements = ShippedPlacements()
            .Where(p => p.PitchSignObservability > Observable)
            .ToList();

        float worstUnderWrongSign = 0f;
        var survived = new List<string>();

        foreach (var placement in placements)
        {
            var transform = placement.Transform with { PrePivot = Vector3.Zero };
            var reference = BuildActorTransform(
                transform.Location, ReferenceDegreesWithCorrectedRoll(transform.Rotation), transform.Scale);

            float difference = WorstComponentDifference(WithPositivePitch(transform), reference);
            worstUnderWrongSign = MathF.Max(worstUnderWrongSign, difference);

            if (difference <= Tolerance)
                survived.Add($"{placement.Map} {placement.Actor} {transform.Rotation} "
                             + $"scale {transform.Scale:0.##} diff {difference}");
        }

        Log($"wrong pitch sign: {placements.Count - survived.Count} of {placements.Count} rotations "
            + $"rejected, worst component difference {worstUnderWrongSign:0.######}");
        foreach (string line in survived.Take(20)) Log("  SURVIVED " + line);

        Assert.True(placements.Count > 1_000,
            $"only {placements.Count} rotations are observable enough to judge the sign");
        Assert.Empty(survived);
        Assert.True(worstUnderWrongSign > 0.5f,
            $"the wrong sign is only {worstUnderWrongSign} away from the reference, which is not a "
            + "margin this comparison could be relied on to catch");
    }

    /// <summary>
    /// The scale/rotation composition order, checked against the reference under a deliberately
    /// non-uniform probe scale — because the shipped game does not contain a sample that can.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Why a probe, and what that does and does not license.</b> <c>T·R·S</c> and <c>T·S·R</c>
    /// produce the identical matrix for every uniform scale, so the ordering is only observable on
    /// a non-uniform one. The whole game ships <b>two</b> rotated actors with a non-uniform scale
    /// and both are 1.8% off uniform — real, but far too weak to settle an ordering. This is the
    /// same situation as the brush placement rule, where a sweep found 0 of 13,443 brushes scaled
    /// and every rotated one a gameplay volume: <b>no shipped sample can decide it.</b>
    /// </para>
    /// <para>
    /// <b>This does not fabricate game data and does not stand in for it.</b> The rotations are
    /// every real rotation the shipped maps use; only the scale factor is chosen. What it verifies
    /// is that this project's composition agrees with the reference implementation's under a scale
    /// that can tell them apart — an equivalence between two implementations of a documented
    /// order, not a claim about what BioShock ships. The corresponding claim about shipped data
    /// stays where it belongs: <c>UNKNOWN</c>, recorded in
    /// <see cref="EveryRotationTheGameShipsMatchesTheReferenceEditorsConstruction"/>'s census.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheScaleCompositionOrderIsCheckedAgainstTheReferenceUnderAProbeScale()
    {
        // Deliberately non-uniform, and deliberately not near-uniform: the two shipped samples
        // differ by 1.8% and that is the problem this probe exists to get past.
        var probe = new Vector3(0.5f, 2f, 3.5f);

        var placements = ShippedPlacements()
            .Where(p => !p.Transform.Rotation.IsIdentity)
            .ToList();

        float worst = 0f, worstUnderSwappedOrder = 0f;
        Placement? worstAt = null;

        foreach (var placement in placements)
        {
            var transform = placement.Transform with
            {
                PrePivot = Vector3.Zero, DrawScale = 1f, DrawScale3D = probe,
            };
            var reference = BuildActorTransform(
                transform.Location, ReferenceDegreesWithCorrectedRoll(transform.Rotation), transform.Scale);

            float difference = WorstComponentDifference(transform.ToMatrix(), reference);
            if (difference > worst) { worst = difference; worstAt = placement; }

            // The same transform with scale and rotation swapped — the ordering this test exists to
            // rule out. It must not also match, or the check is not distinguishing anything.
            var swapped = Matrix4x4.CreateFromQuaternion(transform.Rotation.ToQuaternion())
                * Matrix4x4.CreateScale(transform.Scale)
                * Matrix4x4.CreateTranslation(transform.Location);
            worstUnderSwappedOrder = MathF.Max(
                worstUnderSwappedOrder, WorstComponentDifference(swapped, reference));
        }

        Log($"probe scale {probe}: {placements.Count} rotations, worst difference {worst:0.######}"
            + (worstAt is null ? "" : $" at {worstAt.Map} {worstAt.Actor} {worstAt.Transform.Rotation}")
            + $"; worst under the swapped order {worstUnderSwappedOrder:0.###}");

        Assert.True(worst < Tolerance,
            $"worst component difference {worst} against the reference under a non-uniform scale"
            + (worstAt is null ? "" : $", at {worstAt.Map} {worstAt.Actor} {worstAt.Transform.Rotation}"));

        // Proved able to fail: with the scale applied after the rotation instead of before, the
        // same comparison diverges by a wide margin.
        Assert.True(worstUnderSwappedOrder > 0.5f,
            $"scaling after the rotation instead of before differs by only {worstUnderSwappedOrder}, "
            + "so this check cannot actually distinguish the two orders");
    }

    /// <summary>
    /// How far this project deliberately departs from the reference on roll, pinned so a silent
    /// revert to the reference's own roll cannot pass unnoticed.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The other tests here normalise the roll correction out, so on its own the suite would look
    /// like unbroken agreement with Nyko's editor. It is not: on every rotation whose roll is not
    /// its own negation this project builds a <b>different matrix on purpose</b>, because the
    /// reference's roll buries 25.85% of the game's rolled geometry inside solid architecture
    /// against 15.38% for the negated one (<c>BspSolidityTests</c>, six maps, 147,466 points).
    /// </para>
    /// <para>
    /// Recording the size of that gap is what stops a future session "fixing" the disagreement.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheDivergenceFromTheReferencesRollIsDeliberateAndMeasured()
    {
        var placements = ShippedPlacements();

        int canDiverge = 0, diverging = 0;
        float worst = 0f;

        foreach (var placement in placements)
        {
            var transform = placement.Transform with { PrePivot = Vector3.Zero };
            if (RollIsItsOwnNegation(transform.Rotation)) continue;

            // Only rolls large enough for the difference to clear float noise on a level-sized
            // translation can be judged — the same observability argument as the pitch sign.
            float roll = transform.Rotation.ToDegrees().X;
            float observable = 2f * MathF.Abs(MathF.Sin(roll * MathF.PI / 180f))
                               * MathF.Max(MathF.Max(transform.Scale.X, transform.Scale.Y), transform.Scale.Z);
            if (observable <= Observable) continue;

            canDiverge++;
            var raw = BuildActorTransform(
                transform.Location, ReferenceDegrees(transform.Rotation), transform.Scale);
            float difference = WorstComponentDifference(transform.ToMatrix(), raw);
            worst = MathF.Max(worst, difference);
            if (difference > Tolerance) diverging++;
        }

        Log($"{canDiverge} rotations carry an observable roll; {diverging} differ from the "
            + $"reference's construction, worst component difference {worst:0.###}");

        Assert.True(canDiverge > 500,
            $"only {canDiverge} rotations carry an observable roll, too few to pin the divergence");

        // Every one of them must differ. If this ever reports agreement, the roll correction has
        // been reverted and the level is quietly worse.
        Assert.Equal(canDiverge, diverging);
    }

    /// <summary>
    /// The two pitches at which the sign cannot be seen at all, asserted as the mathematical fact
    /// they are rather than left as an unexplained gap in the falsification sweep.
    /// </summary>
    /// <remarks>
    /// <c>Ry(−p) ≡ Ry(p)</c> at <c>p = 0°</c> and <c>p = 180°</c>, so an actor pitched to either
    /// draws identically under both signs. The shipped game contains <b>6,167 such placements</b>
    /// of its 12,557 — <b>essentially half the game is blind to this class of bug</b>, because most
    /// of Rapture is placed by yaw alone at <c>pitch = 0</c>, and the half-turn cases are
    /// <c>±32768</c> and <c>−65536</c> units. Recording this is what stops a future session reading
    /// the falsification test's population filter as a tolerance that was widened until the numbers
    /// agreed.
    /// </remarks>
    [RequiresGameFact]
    public void ThePitchSignIsMathematicallyInvisibleAtZeroAndAHalfTurn()
    {
        var mirrored = ShippedPlacements()
            .Where(p => MathF.Abs(MathF.Sin(p.PitchDegrees * MathF.PI / 180f)) < 1e-5f)
            .Where(p => !p.Transform.Rotation.IsIdentity)
            .ToList();

        Assert.NotEmpty(mirrored);

        float worst = 0f;
        foreach (var placement in mirrored)
        {
            var transform = placement.Transform with { PrePivot = Vector3.Zero };
            worst = MathF.Max(worst, WorstComponentDifference(
                WithPositivePitch(transform), MatrixOf(transform)));
        }

        Log($"{mirrored.Count} rotations at a pitch of 0 or 180 degrees; "
            + $"worst difference between the two signs {worst:0.#######}");

        // Both signs must agree to floating-point precision, which is what makes these unjudgeable
        // rather than merely inconvenient.
        Assert.True(worst < 1e-4f,
            $"the two pitch signs differ by {worst} at a pitch where they should be identical");
    }

    /// <summary>
    /// This project's own matrix in the same flat layout <see cref="WorstComponentDifference"/>
    /// reads, so the two pitch signs can be compared to each other rather than to the reference.
    /// </summary>
    private static float[] MatrixOf(ActorTransform transform)
    {
        var m = transform.ToMatrix();
        return
        [
            m.M11, m.M12, m.M13, m.M14,
            m.M21, m.M22, m.M23, m.M24,
            m.M31, m.M32, m.M33, m.M34,
            m.M41, m.M42, m.M43, m.M44,
        ];
    }

    /// <summary>
    /// <see cref="ActorTransform.ToMatrix"/> rebuilt with the pre-fix <c>+pitch</c> quaternion, for
    /// the falsification check above. Deliberately a copy rather than a switch in the production
    /// type — the shipped code has one composition and no flag to get wrong.
    /// </summary>
    private static Matrix4x4 WithPositivePitch(ActorTransform transform)
    {
        var degrees = transform.Rotation.ToDegrees();
        const float toRadians = MathF.PI / 180f;
        var rotation =
            Quaternion.CreateFromAxisAngle(Vector3.UnitZ, degrees.Z * toRadians)
            * Quaternion.CreateFromAxisAngle(Vector3.UnitY, degrees.Y * toRadians)
            // Roll stays negated: this helper isolates the PITCH sign, so every other term must
            // match the shipped composition or the comparison measures two changes at once.
            * Quaternion.CreateFromAxisAngle(Vector3.UnitX, -degrees.X * toRadians);

        return Matrix4x4.CreateTranslation(-transform.PrePivot)
            * Matrix4x4.CreateScale(transform.Scale)
            * Matrix4x4.CreateFromQuaternion(rotation)
            * Matrix4x4.CreateTranslation(transform.Location);
    }
}
