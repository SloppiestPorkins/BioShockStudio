using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Packages;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// A weapon class's own <c>OnFiredEffects</c>/<c>TracerEffects</c> arrays -- muzzle flash, tracer
/// and shell-eject effects declared on the weapon's class defaults, not on any placed level actor.
/// <see cref="WeaponEffects.For"/> reuses <c>LevelAnalyzer.ReadEmitterTemplate</c> for each
/// <c>EmitterClass</c> reference, the exact same reader a placed actor's own <c>Emitters</c> array
/// already uses (<see cref="EmitterTemplateFieldTests"/>) -- these are pinned against real bytes
/// too, not re-derived.
/// <para>
/// <b>A real bug this test would have caught</b>: the first working draft only accepted
/// <c>EmitterClass</c>/<c>LightClass</c> fields typed <c>UnrealPropertyType.Class</c>. Every one of
/// them actually wire-encodes as <c>UnrealPropertyType.Object</c> here -- <c>Class'...'</c> is only
/// how the UELib decompiler renders an Object reference whose UnrealScript-declared type happens to
/// be <c>class&lt;Something&gt;</c>. Every emitter/light silently resolved to null with no
/// exception until this was caught by actually running the CLI against real data and looking at the
/// output, not by trusting a clean build.
/// </para>
/// </summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Fast)]
public sealed class WeaponEffectsTests(GameFixture game)
{
    [RequiresGameFact]
    public void MachineGunsOnFiredAndTracerEffectsDecodeWithResolvedEmittersAndLights()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        var data = WeaponEffects.For(package, "MachineGun");

        Assert.NotNull(data);
        Assert.Equal("MachineGun", data!.ClassName);
        Assert.Equal(4, data.OnFiredEffects.Count);
        Assert.Equal(3, data.TracerEffects.Count);

        var bulletShot = data.OnFiredEffects[0];
        Assert.Equal("muzzle", bulletShot.AttachmentBone);
        Assert.Equal("MachineGun_Bullet", bulletShot.AmmoType);
        Assert.Equal(0, bulletShot.UpgradeType);
        Assert.Equal(0, bulletShot.EmitterAction);
        Assert.Equal("MachineGun_MuzzleFX", bulletShot.Emitter?.Source.ObjectName);
        Assert.Equal("DynamicLight_MuzzleMG", bulletShot.Light?.Source.ObjectName);
        Assert.Equal(350f, bulletShot.Light?.LightRadius);

        // The shell-eject entry carries no ammo type and no light -- a real, valid "this field
        // isn't set on this element" answer, not a decode failure.
        var shellEject = data.OnFiredEffects[3];
        Assert.Equal("shelleject", shellEject.AttachmentBone);
        Assert.Equal("None", shellEject.AmmoType);
        Assert.Equal("MG_ShellEject", shellEject.Emitter?.Source.ObjectName);
        Assert.Null(shellEject.Light);

        // Every TracerEffects element resolves to the same shared tracer emitter.
        Assert.All(data.TracerEffects, effect => Assert.Equal("MG_Tracer", effect.Emitter?.Source.ObjectName));
    }

    [RequiresGameFact]
    public void APistolsSingleOnFiredEffectResolvesItsMuzzleFlashAndLight()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        var data = WeaponEffects.For(package, "Pistol");

        Assert.NotNull(data);
        var effect = Assert.Single(data!.OnFiredEffects);
        Assert.Equal("muzzle", effect.AttachmentBone);
        Assert.Equal("Pistol_MuzzleFX", effect.Emitter?.Source.ObjectName);
        Assert.Equal("DynamicLightMuzzleFlash", effect.Light?.Source.ObjectName);
        Assert.Empty(data.TracerEffects);
    }

    [RequiresGameFact]
    public void AClassWithNeitherArrayReturnsEmptyListsNotNull()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);

        // ChemicalThrower_LiquidNitrogen names its FX classes directly on flat EmitterClass/
        // HighPressureEmitterClass properties, not through OnFiredEffects/TracerEffects -- a
        // different, not-yet-decoded shape (see docs/research/interaction.md §6). The class itself
        // is real and present, so this must not be confused with the "class doesn't exist" case.
        var data = WeaponEffects.For(package, "ChemicalThrower_LiquidNitrogen");

        Assert.NotNull(data);
        Assert.Empty(data!.OnFiredEffects);
        Assert.Empty(data.TracerEffects);
    }

    [RequiresGameFact]
    public void ANonexistentClassNameReturnsNull()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        Assert.Null(WeaponEffects.For(package, "ThisClassDoesNotExist"));
    }
}
