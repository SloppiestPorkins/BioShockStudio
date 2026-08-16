using System.Reflection;
using Xunit;
using Xunit.Sdk;

namespace BioShockStudio.Tests;

/// <summary>
/// The two tiers the suite is split into, and the trait that selects them.
/// </summary>
/// <remarks>
/// <para>
/// The whole suite reads the installed game and takes about ten minutes, and a ten-minute suite
/// changes how carefully changes get verified — it is cheaper to reason about a change than to run
/// the tests, which is the wrong way round. So it is split:
/// </para>
/// <code>
/// dotnet test --filter Tier=Fast     # seconds — run this constantly
/// dotnet test --filter Tier=Sweep    # minutes — run this before finishing
/// dotnet test                        # both, which is what CI and a handover want
/// </code>
/// <para>
/// <b>Speed comes from reading less real data, never from fabricating any.</b> There are no
/// synthetic fixtures in this suite and this split does not introduce one: a fast test still reads
/// real shipped bytes, just from <c>Entry.bsm</c> — the smallest shipped package — or from a single
/// map, rather than from all 33 packages. Nothing is stubbed and nothing is weakened; the whole-game
/// censuses still exist, they are just in the other tier.
/// </para>
/// <para>
/// Every test class declares exactly one tier and <see cref="TierCoverageTests"/> fails if one does
/// not, so a test cannot fall out of both tiers and quietly stop running. That guard is the reason
/// this is a whitelist on both sides rather than "sweep is whatever is left".
/// </para>
/// </remarks>
public static class Tiers
{
    /// <summary>The trait name. <c>dotnet test --filter Tier=Fast</c>.</summary>
    public const string Name = "Tier";

    /// <summary>
    /// Reads one package, or none. The tier you run while working.
    /// </summary>
    public const string Fast = "Fast";

    /// <summary>
    /// Opens every shipped package, decodes every animation, or builds the whole catalogue —
    /// including the UI tests, which build a catalogue to have something to show.
    /// </summary>
    public const string Sweep = "Sweep";
}

/// <summary>
/// The two tiers together are the whole suite.
/// </summary>
/// <remarks>
/// A split suite has one failure mode that matters: a test that belongs to neither tier still passes
/// <c>dotnet test</c> and never runs in either filtered command, so it rots unnoticed. This asserts
/// that every class holding tests declares exactly one tier, which is what makes
/// <c>Fast + Sweep = everything</c> true by construction rather than by having been checked once.
/// </remarks>
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class TierCoverageTests
{
    /// <summary>Types in this assembly that hold at least one test.</summary>
    private static IReadOnlyList<Type> TestClasses() => typeof(TierCoverageTests).Assembly
        .GetTypes()
        .Where(t => TestCount(t) > 0)
        .OrderBy(t => t.Name, StringComparer.Ordinal)
        .ToList();

    /// <summary>
    /// Tests declared on a type — anything carrying <c>Fact</c> or an attribute derived from it,
    /// which is what <c>RequiresGameFact</c> and <c>AvaloniaFact</c> both are.
    /// </summary>
    private static int TestCount(Type type) => type
        .GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly)
        .Count(m => m.GetCustomAttributes<FactAttribute>(inherit: true).Any());

    /// <summary>
    /// The tiers a type declares.
    /// </summary>
    /// <remarks>
    /// Read off <see cref="CustomAttributeData"/> rather than off the attribute instance: xUnit's
    /// <see cref="TraitAttribute"/> takes its name and value as constructor arguments and exposes
    /// neither as a property, because the traits themselves are produced by a discoverer at
    /// collection time.
    /// </remarks>
    private static List<string> TiersOf(Type type) => type
        .GetCustomAttributesData()
        .Where(a => a.AttributeType == typeof(TraitAttribute)
                    && a.ConstructorArguments.Count == 2
                    && a.ConstructorArguments[0].Value as string == Tiers.Name)
        .Select(a => a.ConstructorArguments[1].Value as string ?? string.Empty)
        .ToList();

    [Fact]
    public void EveryTestClassDeclaresExactlyOneTier()
    {
        var classes = TestClasses();
        Assert.NotEmpty(classes);

        var untiered = new List<string>();

        foreach (var type in classes)
        {
            var tiers = TiersOf(type);

            if (tiers.Count != 1 || (tiers[0] != Tiers.Fast && tiers[0] != Tiers.Sweep))
            {
                untiered.Add($"{type.Name} declares [{string.Join(", ", tiers)}]");
            }
        }

        Assert.True(untiered.Count == 0,
            "every test class must carry exactly one [Trait(Tiers.Name, ...)], or its tests run in "
            + "neither --filter Tier=Fast nor --filter Tier=Sweep and stop being run at all:"
            + Environment.NewLine + string.Join(Environment.NewLine, untiered));
    }

    /// <summary>
    /// The tiers account for every test method, so the two commands together are the whole suite.
    /// </summary>
    /// <remarks>
    /// Counted from the methods rather than from the classes, because a class-level trait is what
    /// carries the tier and it is the per-test total that has to add up.
    /// </remarks>
    [Fact]
    public void TheTwoTiersAccountForEveryTest()
    {
        int fast = 0, sweep = 0, total = 0;

        foreach (var type in TestClasses())
        {
            int tests = TestCount(type);
            total += tests;

            string? tier = TiersOf(type).FirstOrDefault();

            if (tier == Tiers.Fast) fast += tests;
            else if (tier == Tiers.Sweep) sweep += tests;
        }

        Assert.Equal(total, fast + sweep);
    }
}
