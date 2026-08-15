using BioShockStudio.Core.Audio;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The game's own binding from an animation event to a sound name.
/// </summary>
/// <remarks>
/// <para>
/// An animation's events are the authoritative timing source for anything audio, and this project
/// already reads 47,560 of them. <c>EventResponse_SoundEffectsSubsystem</c> is what says what one
/// <i>means</i>: its <c>Event</c> is the same string the notify carries, so the link is structural
/// rather than a name resemblance.
/// </para>
/// <para>
/// <b>These tests cover a resolved name and nothing else.</b> No sample is decoded and none is
/// played — where sound-effect data ships is still unknown. See <c>docs/research/audio.md</c>.
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
public sealed class SoundEventTests(GameFixture game)
{
    private string Map(string name) =>
        Path.Combine(Core.Game.GameLocator.MapsDirectory(game.RequireRoot), name + ".bsm");

    /// <summary>
    /// The pistol reload's three events resolve to the three pistol reload sounds.
    /// </summary>
    /// <remarks>
    /// This is the whole finding in one assertion. The sound name is an <c>FCompactIndex</c> into the
    /// package's own name table, and the check that makes it a decode rather than a fit is that three
    /// independent values each land on the semantically correct sound. Reading the same field as a
    /// little-endian <c>uint16</c> gives <c>machines_damage_sparks_04</c>, <c>door_lowrent_01</c> and
    /// <c>door_highrent_02</c> — real sound names, right domain, entirely wrong.
    /// </remarks>
    [RequiresGameFact]
    public void ThePistolReloadEventsResolveToTheirSounds()
    {
        using var package = BioShockPackage.Open(Map("1-Medical"));
        var responses = SoundEventReader.Read(package);

        Assert.NotEmpty(responses);

        var expected = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["ReloadPistolOne"] = "weapons_pistol_reload_one",
            ["ReloadPistolTwo"] = "weapons_pistol_reload_two",
            ["ReloadPistolThree"] = "weapons_pistol_reload_three",
        };

        foreach (var (eventName, sound) in expected)
        {
            var response = responses.SingleOrDefault(r =>
                r.Event == eventName && r.SourceClassName == "Hands");

            Assert.True(response is not null,
                $"no Hands response for {eventName}; found: "
                + string.Join(", ", responses.Where(r => r.Event == eventName)
                    .Select(r => $"{r.ObjectName}({r.SourceClassName})")));

            Assert.Equal(sound, response!.SoundName);
        }
    }

    /// <summary>
    /// The animation's own events are the same strings the responses answer.
    /// </summary>
    /// <remarks>
    /// The link is only structural if both halves really do name the same thing. This reads the
    /// events out of <c>FastReloadPistol</c> through the ordinary animation path and checks them
    /// against the responses, rather than trusting the two notes to agree.
    /// </remarks>
    [RequiresGameFact]
    public void TheAnimationsEventsAreTheEventsTheResponsesAnswer()
    {
        // 0-Lighthouse rather than 1-Medical: every map embeds its own copy of the hands, the copies
        // are not byte-identical, and 1-Medical's metadata object for this animation reads no events.
        // Whether that is a smaller copy or a different one is its own question — this test is about
        // whether the two halves name the same events, so it uses a copy that has them.
        using var package = BioShockPackage.Open(Map("0-Lighthouse"));

        var metadata = package.Exports
            .Where(e => e.ObjectName.Equals(
                Core.Assets.AnimationMetadataReader.ObjectPrefix + "FastReloadPistol",
                StringComparison.OrdinalIgnoreCase))
            .MaxBy(e => e.SerialSize);

        Assert.True(metadata is not null, "FastReloadPistol has no metadata object in 0-Lighthouse");

        // The duration is not decoration: ReadEvents stops at the first event outside it, so passing
        // zero returns an empty list and looks exactly like "this animation has no events". The real
        // duration comes from the animation itself.
        var wrapper = package.Exports
            .Where(e => e.ObjectName == "UAPW_NEWPlayerHands"
                        && package.GetClassName(e) == Core.Assets.AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize)!;

        var animations = Core.Assets.AnimationPackage.Load(package, wrapper);
        var reload = animations.Animations.First(a =>
            string.Equals(a.Name, "FastReloadPistol", StringComparison.OrdinalIgnoreCase));

        var events = Core.Assets.AnimationMetadataReader.ReadEvents(package, metadata!, reload.Duration);
        Assert.NotEmpty(events);

        // One event can have SEVERAL responses — `EveArmJab` has two on the Hands class — which is
        // what FilteredState, Chance and LevelContext are presumably choosing between. Nothing here
        // decides which one wins; that is open question 5 in docs/research/audio.md.
        var responses = SoundEventReader.Read(package)
            .Where(r => r.SourceClassName == "Hands")
            .GroupBy(r => r.Event, StringComparer.Ordinal)
            .ToDictionary(g => g.Key, g => g.ToList(), StringComparer.Ordinal);

        // Every event this animation fires has at least one Hands response that names a sound. If a
        // future animation has events that do not, that is a finding to record — not a reason to
        // loosen this test, which is about the ones that provably do.
        foreach (string name in events.Select(e => e.EventName).Distinct(StringComparer.Ordinal))
        {
            Assert.True(responses.TryGetValue(name, out var answering),
                $"the animation fires '{name}' but no Hands sound response answers it");
            Assert.Contains(answering!, r => r.IsResolved);
        }
    }

    /// <summary>
    /// A specification this reader does not recognise resolves to nothing rather than to a name.
    /// </summary>
    /// <remarks>
    /// 18 of the 19 specification bytes are <c>UNKNOWN</c> and are used only as a shape check. This
    /// asserts the refusal actually happens: across a whole map, every response either matches the
    /// template and names a real entry in the name table, or reports unresolved. A reader that
    /// decoded whatever it was given would fail this by producing rubbish names.
    /// </remarks>
    [RequiresGameFact]
    public void AnUnrecognisedSpecificationIsUnresolvedRatherThanGuessed()
    {
        using var package = BioShockPackage.Open(Map("1-Medical"));
        var responses = SoundEventReader.Read(package);

        var names = package.Names.Select(n => n.Name).ToHashSet(StringComparer.Ordinal);

        foreach (var response in responses)
        {
            Assert.False(string.IsNullOrEmpty(response.Event));

            if (response.SoundName is null) continue;

            Assert.Contains(response.SoundName, names);
        }

        // Both outcomes have to occur somewhere in the map, or this is not testing the refusal.
        Assert.Contains(responses, r => r.IsResolved);
    }
}
