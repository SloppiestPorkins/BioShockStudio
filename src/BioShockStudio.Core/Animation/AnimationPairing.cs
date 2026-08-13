namespace BioShockStudio.Core.Animation;

/// <summary>
/// Which attachment animation plays with which host animation — the pistol's <c>FastReload</c>
/// against the hands' <c>FastReloadPistol</c>.
/// <para>
/// A first-person animation is one performance on two rigs. Nothing in the data names the partner,
/// so this is a <c>HEURISTIC</c>; what is evidence is the <b>duration</b>, and the name only breaks
/// ties among candidates that already agree on it.
/// </para>
/// <para>
/// <b>It is not the frame count.</b> That was the previous rule and the shipped data disproves it: a
/// weapon rig is often authored sparsely, so the launcher's 0.70s <c>FireLast</c> is 2 frames at
/// 1.43 fps against the hands' 22 frames at 30, and its <c>Equip</c> is 2 frames against 8.
/// Requiring equal frame counts silently dropped the weapon's motion from the crossbow reload
/// (93 frames against 91), the launcher's <c>FireLast</c> and <c>Equip</c>, and every zoomed fire —
/// which looks exactly like a broken attachment, because the weapon sits in its rest pose while the
/// hands perform.
/// </para>
/// <para>
/// This lives in one place so the preview and the FBX manifest cannot disagree about what pairs
/// with what.
/// </para>
/// </summary>
public static class AnimationPairing
{
    /// <summary>
    /// How far two durations may differ and still be one performance.
    /// </summary>
    /// <remarks>
    /// Measured rather than chosen. Across the pistol, launcher, crossbow and Tommy gun sets every
    /// correct pairing is within 10% — most are exact, the crossbow's reload is 2.3% and its zoomed
    /// fire 9.1% — and the one pairing that has to be rejected, the hands' 1.43s
    /// <c>FireLauncher</c> against the weapon's 0.70s <c>FireLast</c>, is 51% apart. Anything from
    /// about 11% to 50% would separate them; 15% sits in that gap without hugging either edge.
    /// </remarks>
    public const float DurationTolerance = 0.15f;

    /// <summary>Whether two animations are the same performance, judged on how long they last.</summary>
    public static bool PlaysTogether(float hostDuration, float attachmentDuration)
    {
        if (hostDuration <= 0f || attachmentDuration <= 0f)
            return MathF.Abs(hostDuration - attachmentDuration) < 1e-3f;

        float larger = MathF.Max(hostDuration, attachmentDuration);
        return MathF.Abs(hostDuration - attachmentDuration) / larger <= DurationTolerance;
    }

    /// <summary>
    /// The candidate that plays with <paramref name="hostName"/>, or null if none is convincing.
    /// <para>
    /// Candidates whose duration disagrees are excluded outright; the rest are ranked by longest
    /// shared name prefix, and a match shorter than four characters is rejected rather than guessed
    /// at.
    /// </para>
    /// </summary>
    public static string? Counterpart(
        string hostName, float hostDuration, IEnumerable<(string Name, float Duration)> candidates)
    {
        string? best = null;
        int bestScore = 0;

        foreach (var (name, duration) in candidates)
        {
            if (!PlaysTogether(hostDuration, duration)) continue;

            int score = 0;
            while (score < hostName.Length && score < name.Length
                   && char.ToLowerInvariant(hostName[score]) == char.ToLowerInvariant(name[score]))
            {
                score++;
            }

            if (score > bestScore) (best, bestScore) = (name, score);
        }

        return bestScore >= 4 ? best : null;
    }

    /// <summary>
    /// The attachment frame that plays alongside a host frame, by normalised time.
    /// <para>
    /// The two rigs agree on duration, not on frame count, so sampling the attachment at the host's
    /// own frame index reads a 2-frame weapon animation off the end of its own track and holds it on
    /// its last key for the rest of the performance.
    /// </para>
    /// </summary>
    public static int AttachmentFrame(int hostFrameCount, int attachmentFrameCount, int hostFrame)
    {
        int hostLast = hostFrameCount - 1;
        int attachmentLast = attachmentFrameCount - 1;
        if (hostLast <= 0 || attachmentLast <= 0) return 0;

        int frame = (int)MathF.Round(hostFrame * attachmentLast / (float)hostLast);
        return Math.Clamp(frame, 0, attachmentLast);
    }
}
