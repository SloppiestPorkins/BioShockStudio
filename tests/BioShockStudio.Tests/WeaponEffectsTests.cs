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
    public void AnEmitterAmmoClassResolvesItsFlatEmitterClassPairInsteadOfTheArrayShape()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);

        // ChemicalThrower ammo types name their FX classes directly on flat EmitterClass/
        // HighPressureEmitterClass properties, not through OnFiredEffects/TracerEffects -- both
        // arrays are correctly empty (not confused with "class doesn't exist", which returns null).
        var liquidNitrogen = WeaponEffects.For(package, "ChemicalThrower_LiquidNitrogen");
        Assert.NotNull(liquidNitrogen);
        Assert.Empty(liquidNitrogen!.OnFiredEffects);
        Assert.Empty(liquidNitrogen.TracerEffects);
        Assert.Equal("LiquidNitrogen_Player", liquidNitrogen.EmitterClass?.Source.ObjectName);
        Assert.Equal("LiquidNitrogenUp_Player", liquidNitrogen.HighPressureEmitterClass?.Source.ObjectName);

        var ionicGel = WeaponEffects.For(package, "ChemicalThrower_IonicGel");
        Assert.Equal("IonGel", ionicGel?.EmitterClass?.Source.ObjectName);
        Assert.Equal("IonGelUp", ionicGel?.HighPressureEmitterClass?.Source.ObjectName);

        // A weapon that declares the array shape instead must not also report flat properties it
        // never set -- the two shapes are mutually exclusive in the shipped data, and a false
        // positive here would mean the flat lookup is matching something unrelated.
        var machineGun = WeaponEffects.For(package, "MachineGun");
        Assert.Null(machineGun?.EmitterClass);
        Assert.Null(machineGun?.HighPressureEmitterClass);
    }

    [RequiresGameFact]
    public void ANonexistentClassNameReturnsNull()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        Assert.Null(WeaponEffects.For(package, "ThisClassDoesNotExist"));
    }

    [RequiresGameFact]
    public void PlasmidAbilityClassesResolveTheirOwnDifferentlyNamedEffectProperty()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);

        // Three ability classes, three different property names -- ResolveEffectProperty is the
        // generalization of EmitterAmmo's fixed EmitterClass/HighPressureEmitterClass pair for
        // exactly this heterogeneity (docs/research/interaction.md §6).
        Assert.Equal("BeaconProjectile",
            WeaponEffects.ResolveEffectProperty(package, "SecurityBeaconAbility", "ProjectileClass")?.Source.ObjectName);
        Assert.Equal("SpringBoard_Cursor",
            WeaponEffects.ResolveEffectProperty(package, "SpringBoardTrapAbility", "TargetIndicatorClass")?.Source.ObjectName);
        Assert.Equal("TrapBoltBeam",
            WeaponEffects.ResolveEffectProperty(package, "TrapBoltProjectile", "BeamEffectClass")?.Source.ObjectName);
    }

    [RequiresGameFact]
    public void ANonexistentPropertyOrClassReturnsNullRatherThanThrowing()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        Assert.Null(WeaponEffects.ResolveEffectProperty(package, "Pistol", "NoSuchProperty"));
        Assert.Null(WeaponEffects.ResolveEffectProperty(package, "ThisClassDoesNotExist", "EmitterClass"));
    }

    /// <summary>
    /// Pins a currently-known-wrong answer, not a correct one — see
    /// docs/research/interaction.md §6. <c>BerserkRageAbility.ProjectileClass</c> is real and present
    /// in the decompiled source (the very first line of its defaultproperties), but
    /// <c>ClassDefaults</c>' offset search recovers a property list that silently starts six
    /// properties later, at <c>FriendlyName</c> -- so this currently, correctly-for-the-wrong-reason
    /// returns null. If a future <c>ClassDefaults</c> fix recovers the true leading properties, this
    /// assertion should flip to resolving <c>EnrageProjectile</c> -- that is the intended signal a
    /// change here is meant to send, not a regression.
    /// </summary>
    [RequiresGameFact]
    public void BerserkRageAbilityDemonstratesAKnownClassDefaultsGap()
    {
        using var package = BioShockPackage.Open(game.WeaponPackage);
        Assert.Null(WeaponEffects.ResolveEffectProperty(package, "BerserkRageAbility", "ProjectileClass"));
    }
}
