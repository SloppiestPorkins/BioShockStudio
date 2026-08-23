using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Havok.Animation;
using BioShockStudio.Core.Havok.Animation.SplineCompression;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// Which quantisation formats the shipped animations actually use.
/// </summary>
/// <remarks>
/// <para>
/// Gate 2 item 1's "compression edge cases". The item has no known-broken case to chase — the
/// decoder reports zero failures across every shipped animation — so the honest question is not
/// "what is broken" but <b>"what has never been exercised"</b>. A decoder branch that no shipped
/// animation reaches is unvalidated code, and it will stay unvalidated however many times the suite
/// passes.
/// </para>
/// <para>
/// The selectors live in each track's <see cref="TransformMask"/>, four bytes per track at the front
/// of every block, so this reads them directly rather than through the decoder — the point is to
/// measure the input space, not to re-test the decode.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class QuantizationCensusTests(GameFixture game)
{
    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    [RequiresGameFact]
    public void CensusQuantizationSelectors()
    {
        var translation = new Dictionary<ScalarQuantization, long>();
        var rotation = new Dictionary<RotationQuantization, long>();
        var scale = new Dictionary<ScalarQuantization, long>();
        var rawBytes = new Dictionary<byte, long>();

        int animations = 0, splineAnimations = 0, packages = 0;

        foreach (string file in GameLocator.EnumeratePackages(game.RequireRoot))
        {
            BioShockPackage package;
            try { package = BioShockPackage.Open(file); }
            catch (Exception ex) when (ex is InvalidDataException or IOException) { continue; }

            using (package)
            {
                var wrappers = package.Exports
                    .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
                    .ToList();
                if (wrappers.Count == 0) continue;
                packages++;

                foreach (var wrapper in wrappers)
                {
                    AnimationPackage pack;
                    try { pack = AnimationPackage.Load(package, wrapper); }
                    catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                                   or ArgumentOutOfRangeException or NotSupportedException)
                    {
                        continue;
                    }

                    foreach (var animation in pack.Animations)
                    {
                        animations++;

                        SplineAnimationHeader header;
                        try
                        {
                            var section = pack.Packfile.ResolvedSections[animation.SectionIndex];
                            header = HkaSplineCompressedAnimationReader.Read(section, animation.Offset);

                            if (header.DataOffset is not { } dataOffset) continue;
                            var data = section.Data.Span.Slice(dataOffset, header.DataSize);

                            splineAnimations++;

                            foreach (int blockOffset in header.BlockOffsets)
                            {
                                if (blockOffset < 0 || blockOffset >= data.Length) continue;

                                int maskBytes = header.TransformTrackCount * TransformMask.Size;
                                if (blockOffset + maskBytes > data.Length) continue;

                                for (int t = 0; t < header.TransformTrackCount; t++)
                                {
                                    var mask = TransformMask.Read(
                                        data.Slice(blockOffset + t * TransformMask.Size, TransformMask.Size));

                                    rawBytes[mask.QuantizationTypes] =
                                        rawBytes.GetValueOrDefault(mask.QuantizationTypes) + 1;
                                    translation[mask.TranslationQuantization] =
                                        translation.GetValueOrDefault(mask.TranslationQuantization) + 1;
                                    rotation[mask.RotationQuantization] =
                                        rotation.GetValueOrDefault(mask.RotationQuantization) + 1;
                                    scale[mask.ScaleQuantization] =
                                        scale.GetValueOrDefault(mask.ScaleQuantization) + 1;
                                }
                            }
                        }
                        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                                       or ArgumentOutOfRangeException or NotSupportedException)
                        {
                            // Counting the input space, not testing the decode; a section this
                            // census cannot reach is covered by the decode tests elsewhere.
                        }
                    }
                }
            }
        }

        Log($"{packages} packages, {animations:N0} animations, {splineAnimations:N0} spline-compressed");
        Log("  translation quantization:");
        foreach (var (key, count) in translation.OrderByDescending(p => p.Value)) Log($"    {key,-14} {count,10:N0}");
        Log("  rotation quantization:");
        foreach (var (key, count) in rotation.OrderByDescending(p => p.Value)) Log($"    {key,-14} {count,10:N0}");
        Log("  scale quantization:");
        foreach (var (key, count) in scale.OrderByDescending(p => p.Value)) Log($"    {key,-14} {count,10:N0}");
        Log("  raw QuantizationTypes bytes:");
        foreach (var (key, count) in rawBytes.OrderByDescending(p => p.Value)) Log($"    0x{key:X2}         {count,10:N0}");

        Assert.True(animations > 10_000, $"only {animations} animations were walked");
        Assert.NotEmpty(rawBytes);

        // THE FINDING: every track mask in the game is the same byte. 884,855 of them, one value.
        // The shipped corpus uses exactly one quantisation combination, so there is no compression
        // edge case to validate — every other branch of the decoder is unreachable by shipped data.
        Assert.Single(rawBytes);
        Assert.True(rawBytes.ContainsKey(0x45),
            "the single quantisation byte is no longer 0x45: " + string.Join(", ",
                rawBytes.Keys.Select(k => $"0x{k:X2}")));
        Assert.True(rawBytes[0x45] > 800_000, $"only {rawBytes[0x45]:N0} track masks were read");

        // ...which decomposes to exactly these three, per the SDK's own unpackQuantizationTypes.
        Assert.Single(translation);
        Assert.True(translation.ContainsKey(ScalarQuantization.Bits16));
        Assert.Single(scale);
        Assert.True(scale.ContainsKey(ScalarQuantization.Bits16));
        Assert.Single(rotation);
        Assert.True(rotation.ContainsKey(RotationQuantization.ThreeComp40));

        // If this ever fails, a shipped animation has appeared that uses a second format and the
        // decoder will refuse it loudly (SplineDecompressor.DecodeRotation throws for anything but
        // ThreeComp40). That is the correct failure — it must not be "fixed" by guessing a layout.
    }
}
