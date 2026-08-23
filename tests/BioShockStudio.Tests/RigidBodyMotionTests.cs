using System.Numerics;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Havok.Physics;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// <c>hkpRigidBody</c>'s world transform and mass properties.
/// </summary>
/// <remarks>
/// <para>
/// Gate 2 item 3's named follow-up — the fields a previous session left explicitly unattempted
/// (rather than blocked) after an inconclusive first pass. The offsets were <b>located by search
/// and confirmed by structure</b>, not by arithmetic through <c>hkpEntity</c>'s inheritance chain,
/// which is the kind of derivation that yields a confident wrong answer.
/// </para>
/// <para>
/// <b>Four independent structural properties agree</b>, which is what promotes this past
/// "plausible":
/// </para>
/// <list type="number">
/// <item>Exactly one offset in the object yields an orthonormal basis, on every body.</item>
/// <item>That basis is right-handed — determinant +1 — on every body, so it is a rotation and not
/// a reflection or a coincidence of magnitudes.</item>
/// <item>The translations show <b>bilateral symmetry</b>: a humanoid ragdoll's limbs come in
/// near-exact ± pairs on the lateral axis. Random data does not mirror itself.</item>
/// <item><c>1/w</c> of the mass field is an <b>exactly round kilogram value</b> on every shipped
/// body, and the inertia values mirror in the same pairs as the translations.</item>
/// </list>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class RigidBodyMotionTests(GameFixture game)
{
    private static List<HkpRigidBodyMotion> Motions(AnimationPackage pack)
    {
        var result = new List<HkpRigidBodyMotion>();

        foreach (var body in pack.Packfile.EnumerateObjects()
                     .Where(o => o.ClassName == HkpRigidBodyReader.ClassName)
                     .OrderBy(o => o.Offset))
        {
            var motion = HkpRigidBodyReader.ReadMotion(
                pack.Packfile.ResolvedSections[body.SectionIndex], body.Offset);
            if (motion is not null) result.Add(motion);
        }

        return result;
    }

    private AnimationPackage BabyJane()
    {
        var package = BioShockPackage.Open(
            Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm"));

        var wrapper = package.Exports
            .Where(e => e.ObjectName == "UAPW_AggressorBabyJane"
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize)!;

        return AnimationPackage.Load(package, wrapper);
    }

    [RequiresGameFact]
    public void EveryBodysBasisIsAProperRotation()
    {
        var motions = Motions(BabyJane());

        Assert.Equal(17, motions.Count);
        Assert.All(motions, m => Assert.True(m.IsProperRotation,
            $"basis is not a proper rotation: det={m.Determinant:F4}"));
    }

    /// <summary>
    /// The masses are round authored numbers — the arithmetic that settles the offset.
    /// </summary>
    [RequiresGameFact]
    public void MassesAreExactlyRoundKilograms()
    {
        var motions = Motions(BabyJane());

        foreach (var motion in motions)
        {
            Assert.True(motion.InverseMass > 0, "a ragdoll body has zero inverse mass (fixed?)");

            // Round to the nearest kilogram and require the original to match. A misread offset
            // gives arbitrary reals; this passes only if the field really is 1/mass.
            float mass = motion.Mass;
            Assert.Equal(MathF.Round(mass), mass, 2);
        }

        // The authored set, and its total.
        Assert.Equal(224f, motions.Sum(m => m.Mass), 1);
        Assert.Equal(60f, motions.Max(m => m.Mass), 2);
        Assert.Equal(1f, motions.Min(m => m.Mass), 2);
    }

    /// <summary>
    /// A humanoid ragdoll is bilaterally symmetric, and the decoded data shows it.
    /// </summary>
    /// <remarks>
    /// The strongest single check here. Limb bodies come in left/right pairs, so for each body
    /// offset from the midline there is another at nearly the opposite offset, with matching height
    /// and matching inertia. Nothing but a correctly-decoded humanoid transform does that.
    /// </remarks>
    [RequiresGameFact]
    public void TheTranslationsAreBilaterallySymmetric()
    {
        var motions = Motions(BabyJane());

        // The lateral axis is the one whose values are signed and paired; Y here.
        var offMidline = motions.Where(m => Math.Abs(m.Translation.Y) > 0.15f).ToList();
        Assert.True(offMidline.Count >= 8, $"only {offMidline.Count} bodies sit off the midline");

        foreach (var motion in offMidline)
        {
            var mirror = offMidline.FirstOrDefault(other =>
                Math.Abs(other.Translation.Y + motion.Translation.Y) < 0.05f
                && Math.Abs(other.Translation.Z - motion.Translation.Z) < 0.05f);

            Assert.True(mirror is not null,
                $"body at Y={motion.Translation.Y:F3}, Z={motion.Translation.Z:F3} has no mirror");

            // ...and the pair weighs the same, which a coincidence of positions would not give.
            Assert.Equal(motion.Mass, mirror!.Mass, 2);
        }
    }

    /// <summary>
    /// Positions are metres, agreeing with the capsules and not with the mesh data.
    /// </summary>
    [RequiresGameFact]
    public void PositionsAreInMetres()
    {
        var motions = Motions(BabyJane());

        // A standing humanoid: every body within a few metres of the origin, and the tallest
        // clearly above the shortest. In centimetres these would be in the hundreds.
        Assert.All(motions, m => Assert.InRange(m.Translation.Length(), 0f, 10f));

        float highest = motions.Max(m => m.Translation.Z);
        float lowest = motions.Min(m => m.Translation.Z);
        Assert.InRange(highest - lowest, 1f, 5f);
    }
}
