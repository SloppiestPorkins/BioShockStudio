using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// <c>LevelLightReader</c> reads seven light parameters, not the three it used to. The four added
/// 28 Aug 2026 — <c>LightCone</c>, <c>LightType</c>, <c>LightEffect</c>, <c>LightPeriod</c> — are
/// surfaced as raw bytes with confidence deliberately left low (see <see cref="LevelLight"/>).
/// </summary>
/// <remarks>
/// <para>
/// This is the census the decode is built on, pinned so it cannot drift silently. It also carries
/// the evidence for what little is asserted about the bytes:
/// </para>
/// <list type="bullet">
///   <item><b><c>LightCone</c></b> is written by roughly a third of the game's lights — far too many
///   to be an exception, so "this light is a spotlight" is a real signal a UE5 importer can use even
///   without the exact aperture formula.</item>
///   <item><b><c>LightEffect</c></b> is almost always exactly <c>2</c>. A 20-value stock
///   <c>ELightEffect</c> enum would not look like that; the near-constant is the evidence that the
///   stock reading is wrong for BioShock, recorded here rather than in prose only.</item>
///   <item><b><c>LightType</c></b>'s values all fall inside stock <c>ELightType</c>'s range and skip
///   its default (<c>LT_Steady</c>), which is consistent with "only animated lights write it".</item>
/// </list>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class LevelLightFieldTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void TheFourAddedLightFieldsDecodeAndTheirWholeGameCensusHolds()
    {
        long lights = 0, withCone = 0, coneNonZero = 0, withType = 0, withEffect = 0, withPeriod = 0;
        long effectIsTwo = 0;
        var typeValues = new SortedDictionary<byte, int>();
        byte coneMax = 0;

        foreach (string map in Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm")
                     .Where(f => !Path.GetFileNameWithoutExtension(f).Contains('_'))
                     .OrderBy(f => f, StringComparer.Ordinal))
        {
            LevelContext context;
            try { context = LevelAnalyzer.Analyze(map); }
            catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException) { continue; }

            foreach (var actor in context.Actors)
            {
                if (LevelLightReader.Read(actor) is not { } light) continue;
                lights++;

                if (light.Cone is { } cone)
                {
                    withCone++;
                    if (cone > 0) coneNonZero++;
                    coneMax = Math.Max(coneMax, cone);
                }

                if (light.Type is { } type)
                {
                    withType++;
                    typeValues[type] = typeValues.GetValueOrDefault(type) + 1;
                }

                if (light.Effect is { } effect)
                {
                    withEffect++;
                    if (effect == 2) effectIsTwo++;
                }

                if (light.Period is not null) withPeriod++;
            }
        }

        Log($"lights {lights:N0}  cone {withCone:N0} ({coneNonZero:N0} non-zero)  type {withType:N0}  effect {withEffect:N0}  period {withPeriod:N0}");
        Log($"  effect==2: {effectIsTwo:N0} of {withEffect:N0}");
        Log($"  type values: {string.Join(", ", typeValues.Select(kv => $"{kv.Key}×{kv.Value}"))}");
        Log($"  cone max: {coneMax}");

        // The decode reaches a real, large population — not a handful of actors.
        Assert.True(lights > 9_000, $"only {lights} lights");

        // A non-zero LightCone is common enough to be a first-class spotlight signal, not an edge
        // case. Some lights also write LightCone 0 explicitly — an omnidirectional light stating so.
        Assert.True(coneNonZero > lights / 5,
            $"only {coneNonZero} of {lights} lights carry a non-zero LightCone — too few for a spotlight signal");
        Assert.True(withCone - coneNonZero > 0, "no light writes LightCone 0, so the explicit-omni case is untested");
        Assert.True(coneMax >= 200, $"LightCone tops out at {coneMax}");

        // LightType: written by a minority, every value inside stock ELightType's 0..9 range, and
        // never 1 (LT_Steady, the default a light would not bother writing).
        Assert.True(withType is > 400 and < 3_000, $"{withType} lights write LightType");
        Assert.All(typeValues.Keys, v => Assert.InRange(v, (byte)0, (byte)9));
        Assert.DoesNotContain((byte)1, typeValues.Keys);

        // LightEffect: near-constant 2. This is the assertion that says the stock enum reading is wrong.
        Assert.True(withEffect > 1_500, $"only {withEffect} lights write LightEffect");
        Assert.True(effectIsTwo > withEffect * 0.9,
            $"LightEffect is only {effectIsTwo}/{withEffect} == 2 — the near-constant this test relies on has moved");

        Assert.True(withPeriod > 500, $"only {withPeriod} lights write LightPeriod");
    }
}
