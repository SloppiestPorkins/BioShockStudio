using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class AssetContextTests(GameFixture game)
{
    [RequiresGameFact]
    public void HandsGroup_ContainsEverythingTheViewmodelNeeds()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = AssetContextResolver.Resolve(package, "NEWPlayerHands");

        var byClass = context.Members
            .GroupBy(e => package.GetClassName(e))
            .ToDictionary(g => g.Key, g => g.Select(e => e.ObjectName).ToList());

        // The Package object groups the whole first-person asset set, which is what makes it the
        // game's own notion of asset context rather than a naming convention.
        Assert.Contains("NEWPlayerHands", byClass["SkeletalMesh"]);
        Assert.Contains("UAPW_NEWPlayerHands", byClass["AnimationPackageWrapper"]);

        // Hand materials.
        foreach (string texture in new[] { "Hand_DIFF", "Hand_NORM", "Hand_SPEC" })
            Assert.Contains(texture, byClass["Texture"]);

        // Static meshes that attach to the hand sockets.
        foreach (string attachment in new[] { "CS_photo", "CS_butt", "Player_Wallet" })
            Assert.Contains(attachment, byClass["StaticMesh"]);

        // One metadata object per animation.
        Assert.Equal(130, byClass[AnimationMetadataReader.ClassName].Count);
    }

    [RequiresGameFact]
    public void EveryAnimationHasMetadata()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var context = AssetContextResolver.Resolve(package, "NEWPlayerHands");

        var metadata = context.OfClass(package, AnimationMetadataReader.ClassName)
            .Select(e => e.ObjectName)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var export = package.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && package.GetClassName(e) == "AnimationPackageWrapper");
        var animations = AnimationPackage.Load(package, export);

        // Casing differs between the Havok root table and the Unreal object names — the table says
        // "Generic_HandUnequip" where the object is "Generic_HandUnEquip" — so the match has to be
        // case-insensitive, exactly as with R_Grip/R_grip on the socket side.
        foreach (var animation in animations.Animations)
            Assert.Contains(AnimationMetadataReader.ObjectPrefix + animation.Name, metadata);
    }

    [RequiresGameFact]
    public void ReloadAnimation_FiresItsSoundEventsInOrder()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var metadataExport = package.Exports.First(e =>
            e.ObjectName == AnimationMetadataReader.ObjectPrefix + "FastReloadPistol");

        var events = AnimationMetadataReader.ReadEvents(package, metadataExport, animationDuration: 1.8f);

        Assert.Equal(6, events.Count);

        // The three reload beats, in order and inside the animation.
        Assert.Equal("ReloadPistolOne", events[0].EventName);
        Assert.Equal("ReloadPistolTwo", events[1].EventName);
        Assert.Equal("ReloadPistolThree", events[2].EventName);

        Assert.Equal(0.30f, events[0].Time, 2);
        Assert.Equal(1.06f, events[1].Time, 2);
        Assert.Equal(1.53f, events[2].Time, 2);

        Assert.All(events, e => Assert.InRange(e.Time, 0f, 1.8f));
        Assert.All(events, e => Assert.Equal("AnimNotify_EffectEvent", e.NotifyClass));
    }

    [RequiresGameFact]
    public void EquipAnimation_FiresEquipEvents()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var metadataExport = package.Exports.First(e =>
            e.ObjectName == AnimationMetadataReader.ObjectPrefix + "EquipPistol");

        var events = AnimationMetadataReader.ReadEvents(package, metadataExport, animationDuration: 0.24f);

        var names = events.Select(e => e.EventName).ToList();
        Assert.Contains("EquipPistolSound", names);
        Assert.Contains("EquipPistol", names);
    }

    [RequiresGameFact]
    public void EveryPistolAnimationsEventsStayInsideTheirAnimation()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var export = package.Exports.First(e =>
            e.ObjectName == "UAPW_NEWPlayerHands" && package.GetClassName(e) == "AnimationPackageWrapper");
        var animations = AnimationPackage.Load(package, export);

        int withEvents = 0;
        foreach (var animation in animations.ForOwner("Pistol"))
        {
            var metadataExport = package.Exports.FirstOrDefault(e =>
                e.ObjectName == AnimationMetadataReader.ObjectPrefix + animation.Name);
            if (metadataExport is null) continue;

            var events = AnimationMetadataReader.ReadEvents(package, metadataExport, animation.Duration);
            if (events.Count > 0) withEvents++;

            Assert.All(events, e => Assert.InRange(e.Time, 0f, animation.Duration));
        }

        Assert.True(withEvents >= 3, $"expected several pistol animations to carry events, got {withEvents}");
    }

    [RequiresGameFact]
    public void PackageGroups_CoverEveryExport()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var groups = AssetContextResolver.EnumerateGroups(package);

        Assert.Equal(package.Exports.Count, groups.Values.Sum());
        Assert.Contains("NEWPlayerHands", groups.Keys);
    }
}
