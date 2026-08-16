using System.Numerics;
using BioShockStudio.Core.Animation;
using BioShockStudio.Core.Diagnostics;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The whole-game animation audit.
/// <para>
/// The sweep currently reports every one of the game's animations as playable, and a check that
/// never fires would report exactly the same thing. So the checks are exercised directly against
/// each kind of breakage: a clean result is only meaningful once the audit is known to be able to
/// produce a dirty one.
/// </para>
/// </summary>
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class AnimationAuditTests
{
    [Fact]
    public void AWellFormedAnimation_IsPlayable()
    {
        Assert.Equal(string.Empty, AnimationAudit.WhyNotPlayable(Decoded(4, 2), Animation(2), 2));
    }

    [Fact]
    public void ZeroFrames_IsNotPlayable()
    {
        var decoded = new DecodedAnimation { FrameCount = 0, Tracks = Decoded(4, 1).Tracks };
        Assert.Contains("zero frames", AnimationAudit.WhyNotPlayable(decoded, Animation(1), 1));
    }

    [Fact]
    public void ZeroTracks_IsNotPlayable()
    {
        var decoded = new DecodedAnimation { FrameCount = 4, Tracks = [] };
        Assert.Contains("zero tracks", AnimationAudit.WhyNotPlayable(decoded, Animation(0), 0));
    }

    [Fact]
    public void AnUnboundTrack_IsNotPlayable()
    {
        // Two tracks declared by the binding, only one of them landing on a bone.
        string reason = AnimationAudit.WhyNotPlayable(Decoded(4, 2), Animation(2), bound: 1);
        Assert.Contains("bind to no bone", reason);
    }

    [Fact]
    public void AShortTrack_IsNotPlayable()
    {
        var decoded = Decoded(4, 1);
        var truncated = decoded.Tracks[0] with { Translations = new Vector3[3] };
        var broken = new DecodedAnimation { FrameCount = 4, Tracks = [truncated] };

        Assert.Contains("every frame", AnimationAudit.WhyNotPlayable(broken, Animation(1), 1));
    }

    [Fact]
    public void ANonFiniteKey_IsNotPlayable()
    {
        var decoded = Decoded(4, 1);

        var translations = decoded.Tracks[0].Translations.ToArray();
        translations[2] = new Vector3(float.NaN, 0f, 0f);
        var broken = new DecodedAnimation
        {
            FrameCount = 4,
            Tracks = [decoded.Tracks[0] with { Translations = translations }],
        };
        Assert.Contains("translation key is not finite", AnimationAudit.WhyNotPlayable(broken, Animation(1), 1));

        var scales = decoded.Tracks[0].Scales.ToArray();
        scales[1] = new Vector3(0f, float.PositiveInfinity, 0f);
        broken = new DecodedAnimation
        {
            FrameCount = 4,
            Tracks = [decoded.Tracks[0] with { Scales = scales }],
        };
        Assert.Contains("scale key is not finite", AnimationAudit.WhyNotPlayable(broken, Animation(1), 1));
    }

    [Fact]
    public void ANonUnitRotation_IsNotPlayable()
    {
        // A quaternion that is not unit length is not a rotation; it would shear the mesh.
        var decoded = Decoded(4, 1);
        var rotations = decoded.Tracks[0].Rotations.ToArray();
        rotations[3] = new Quaternion(0f, 0f, 0f, 0.5f);

        var broken = new DecodedAnimation
        {
            FrameCount = 4,
            Tracks = [decoded.Tracks[0] with { Rotations = rotations }],
        };

        Assert.Contains("length", AnimationAudit.WhyNotPlayable(broken, Animation(1), 1));
    }

    private static DecodedAnimation Decoded(int frames, int trackCount)
    {
        var tracks = new DecodedTrack[trackCount];
        for (int t = 0; t < trackCount; t++)
        {
            var rotations = new Quaternion[frames];
            var scales = new Vector3[frames];
            for (int f = 0; f < frames; f++)
            {
                rotations[f] = Quaternion.Identity;
                scales[f] = Vector3.One;
            }

            tracks[t] = new DecodedTrack
            {
                OriginalTrackIndex = t,
                Translations = new Vector3[frames],
                Rotations = rotations,
                Scales = scales,
                TargetBoneIndex = t,
            };
        }

        return new DecodedAnimation { FrameCount = frames, Tracks = tracks };
    }

    private static BioShockAnimation Animation(int trackCount) => new()
    {
        Name = "Test",
        Owner = "Default",
        Duration = 1f,
        FrameCount = 4,
        FrameDuration = 1f / 30f,
        TransformTrackCount = trackCount,
        FloatTrackCount = 0,
        Compression = CompressionKind.Spline,
        HavokClassName = "hkaSplineCompressedAnimation",
        RawAnimationTypeValue = 3,
        Binding = new AnimationBinding
        {
            OriginalSkeletonName = "Test",
            TransformTrackToBoneIndex = Enumerable.Range(0, trackCount).Select(i => (short)i).ToList(),
            FloatTrackToFloatSlotIndex = [],
            BlendHint = 0,
        },
        SectionTag = "__data__",
        SectionIndex = 0,
        Offset = 0,
    };
}
