#include "ShockWeaponDef.h"

#include "ShockProjectile.h"
#include "UObject/Package.h"
#include "UObject/SoftObjectPath.h"

namespace
{
/** Content path convention matching import_bioshock into /Game/BioShockWeapons. */
FSoftObjectPath WeaponMeshPath(const TCHAR* FolderAndAsset)
{
	return FSoftObjectPath(FString::Printf(
		TEXT("/Game/BioShockWeapons/%s/%s.%s"),
		FolderAndAsset,
		FolderAndAsset,
		FolderAndAsset));
}

void AddAmmoType(
	UShockWeaponDef* Def,
	FName AmmoName,
	float Damage,
	EAmmoEffect Effect,
	int32 InReserveAmmo)
{
	if (!Def)
	{
		return;
	}
	FShockAmmoType Entry;
	Entry.Name = AmmoName;
	Entry.Damage = Damage;
	Entry.Effect = Effect;
	Entry.ReserveAmmo = InReserveAmmo;
	Def->AmmoTypes.Add(Entry);
}

UShockWeaponDef* MakeDef(
	EWeaponFireMode FireMode,
	FName Name,
	float Damage,
	float Range,
	float Spread,
	float FireRate,
	int32 MagazineSize,
	int32 ReserveAmmo,
	float ReloadSeconds,
	bool bCanZoom,
	float MeleeArc,
	float MeleeReach,
	float ProjectileInitialSpeed,
	float ProjectileImpactRadius,
	float ProjectileLifeSeconds,
	int32 InPelletCount = 1,
	float InPelletSpreadDeg = 0.0f,
	float InBeamTickInterval = 0.1f,
	float InBeamRange = 800.0f,
	EBeamStatus InBeamStatus = EBeamStatus::None)
{
	UShockWeaponDef* Def = NewObject<UShockWeaponDef>(GetTransientPackage(), NAME_None, RF_Transient);
	if (!Def)
	{
		return nullptr;
	}
	Def->WeaponName = Name;
	Def->FireMode = FireMode;
	Def->Damage = Damage;
	Def->Range = Range;
	Def->Spread = Spread;
	Def->FireRate = FireRate;
	Def->MagazineSize = MagazineSize;
	Def->ReserveAmmo = ReserveAmmo;
	Def->ReloadSeconds = ReloadSeconds;
	Def->bCanZoom = bCanZoom;
	Def->MeleeArc = MeleeArc;
	Def->MeleeReach = MeleeReach;
	Def->ProjectileInitialSpeed = ProjectileInitialSpeed;
	Def->ProjectileImpactRadius = ProjectileImpactRadius;
	Def->ProjectileLifeSeconds = ProjectileLifeSeconds;
	Def->PelletCount = InPelletCount;
	Def->PelletSpreadDeg = InPelletSpreadDeg;
	Def->BeamTickInterval = InBeamTickInterval;
	Def->BeamRange = InBeamRange;
	Def->BeamStatus = InBeamStatus;
	if (FireMode == EWeaponFireMode::Projectile)
	{
		Def->ProjectileClass = AShockProjectile::StaticClass();
	}
	return Def;
}
} // namespace

UShockWeaponDef* UShockWeaponDef::Resolve(FName InWeaponName)
{
	// TStrongObjectPtr, not TObjectPtr: a function-local static container is NOT a GC root. The
	// collector only visits UPROPERTY members, FGCObject implementers, TStrongObjectPtr and
	// AddToRoot'd objects — so these RF_Transient defs, owned by nothing, were collected on the
	// first GC while this cache went on handing out their freed addresses. AShockWeapon::ApplyDef
	// then read Def->AmmoTypes off a dangling pointer and the editor died with
	// EXCEPTION_ACCESS_VIOLATION on Play. Every headless verify passed because those commandlets
	// are short-lived and never run a GC; only a real editor session does.
	static TMap<FName, TStrongObjectPtr<UShockWeaponDef>> Cache;
	if (const TStrongObjectPtr<UShockWeaponDef>* Found = Cache.Find(InWeaponName))
	{
		return Found->Get();
	}

	const FString Key = InWeaponName.ToString();
	UShockWeaponDef* Def = nullptr;

	if (Key.Equals(TEXT("TommyGun"), ESearchCase::IgnoreCase))
	{
		// Slice parity: 25 dmg / 50 mag / 150 reserve / 10 rps / 2.5s reload (weapons-config Machine Gun
		// is mag 40, rate 0.9, GenericPiercing 40 — slice intentionally tuned softer).
		Def = MakeDef(
			EWeaponFireMode::Hitscan,
			TEXT("TommyGun"),
			25.0f,
			10000.0f,
			1.9f,
			10.0f,
			50,
			150,
			2.5f,
			true,
			0.0f,
			0.0f,
			0.0f,
			0.0f,
			0.0f);
		// weapons-config Machine Gun: MG Rounds GenericPiercing 40 / Antipersonnel Auto 18 /
		// Armor-piercing Auto 30 — slice keeps index 0 at 25 dmg; variants use raw config numbers.
		AddAmmoType(Def, TEXT("MG Rounds"), 25.0f, EAmmoEffect::None, 150);
		AddAmmoType(Def, TEXT("Antipersonnel Auto"), 18.0f, EAmmoEffect::AntiPersonnel, 150);
		AddAmmoType(Def, TEXT("Armor-piercing Auto"), 30.0f, EAmmoEffect::ArmorPiercing, 150);
		Def->MeshAssetPath = WeaponMeshPath(TEXT("WP_TommyGun"));
		Def->bAutomatic = true; // Machine Gun — hold trigger to keep firing at FireRate
		// 1-Medical SoundEventReader: MachineGun + IsFiring / Hands + ReloadTommy.
		Def->FireSoundCue = TEXT("weapons_tommy_fire");
		Def->ReloadSoundCue = TEXT("weapons_tommy_reload");
	}
	else if (Key.Equals(TEXT("Wrench"), ESearchCase::IgnoreCase))
	{
		// weapons-config: mag 10 acc 0 rate 1 reload 1; WrenchAmmo AIBludgeoning 20.
		// StaticMesh viewmodel (WP_WrenchMesh in ShockGame.U) — swing comes from ViewHands, not a
		// weapon skeletal rig. Path matches import_wrench_mesh.py → /Game/BioShockWeapons/WP_Wrench.
		Def = MakeDef(
			EWeaponFireMode::Melee,
			TEXT("Wrench"),
			20.0f,
			0.0f,
			0.0f,
			1.0f,
			10,
			0,
			1.0f,
			false,
			90.0f,
			180.0f,
			0.0f,
			0.0f,
			0.0f);
		Def->MeshAssetPath = WeaponMeshPath(TEXT("WP_Wrench"));
		// 1-Medical SoundEventReader: Hands + SwingWrench; Actor + WeaponImpacted.
		Def->FireSoundCue = TEXT("weapons_wrench_swipe");
		Def->ImpactSoundCue = TEXT("weapons_wrench_hit");
	}
	else if (Key.Equals(TEXT("GrenadeLauncher"), ESearchCase::IgnoreCase))
	{
		// weapons-config: mag 6 rate 1 reload 1; Frag Grenade GenericPiercing 30 / Explosive 30;
		// GrenadeLauncher_FragGrenade.uc OuterDamageRadius=650.
		// Viewmodel: WP_GrenadeLauncherMesh (SkeletalMesh) + UAPW_WP_GrenadeLauncher in ShockGame.U.
		// Hands socket is "Launcher"; export-firstperson Launcher --group=WP_GrenadeLauncher.
		Def = MakeDef(
			EWeaponFireMode::Projectile,
			TEXT("GrenadeLauncher"),
			30.0f,
			10000.0f,
			0.0f,
			1.0f,
			6,
			12,
			1.0f,
			false,
			0.0f,
			0.0f,
			2500.0f,
			650.0f,
			10.0f);
		Def->MeshAssetPath = WeaponMeshPath(TEXT("WP_GrenadeLauncher"));
		// 1-Medical SoundEventReader: GrenadeLauncher + FiredSound.
		Def->FireSoundCue = TEXT("weapons_GL_launch");
	}
	else if (Key.Equals(TEXT("Pistol"), ESearchCase::IgnoreCase))
	{
		// weapons-config: mag 6 acc 0.5 rate 1 reload 1 zoom; Pistol Rounds GenericPiercing 40.
		Def = MakeDef(
			EWeaponFireMode::Hitscan,
			TEXT("Pistol"),
			40.0f,
			10000.0f,
			1.0f, // PLAUSIBLE — BaseAccuracy 0.5 mapped to ~1° cone (spread not wired to traces yet)
			1.0f,
			6,
			48, // Pistol_Bullet.uc MaximumStackSize=48
			1.0f,
			true,
			0.0f,
			0.0f,
			0.0f,
			0.0f,
			0.0f);
		AddAmmoType(Def, TEXT("Pistol Rounds"), 40.0f, EAmmoEffect::None, 48);
		AddAmmoType(Def, TEXT("Armor-piercing"), 40.0f, EAmmoEffect::ArmorPiercing, 48);
		AddAmmoType(Def, TEXT("Antipersonnel"), 40.0f, EAmmoEffect::AntiPersonnel, 48);
		Def->MeshAssetPath = WeaponMeshPath(TEXT("WP_Pistol"));
		// 1-Medical SoundEventReader: Pistol + FiredSound / Hands + ReloadPistolOne.
		Def->FireSoundCue = TEXT("pistol_fire");
		Def->ReloadSoundCue = TEXT("weapons_pistol_reload_one");
	}
	else if (Key.Equals(TEXT("Shotgun"), ESearchCase::IgnoreCase))
	{
		// weapons-config: mag 4 acc 0 rate 1 reload 1; 00 Buck GenericPiercing 35 total across 8 traces.
		// Shotgun_00Buck.uc NumTracesToFire=8, SpreadOfFire Pitch/Yaw=910 (~5°); PLAUSIBLE 6° half-angle.
		Def = MakeDef(
			EWeaponFireMode::Shotgun,
			TEXT("Shotgun"),
			4.375f, // PLAUSIBLE — 35 total / 8 pellets (per-pellet; sum ≈ 35 when all hit)
			10000.0f,
			0.0f,
			1.0f,
			4,
			24, // PLAUSIBLE — ~6 pickup stacks of 4 shells
			1.0f,
			false,
			0.0f,
			0.0f,
			0.0f,
			0.0f,
			0.0f,
			8,
			6.0f);
		AddAmmoType(Def, TEXT("00 Buck"), 35.0f, EAmmoEffect::None, 24);
		AddAmmoType(Def, TEXT("Electric Buck"), 35.0f, EAmmoEffect::Electric, 24);
		AddAmmoType(Def, TEXT("Exploding Buck"), 49.0f, EAmmoEffect::Explosive, 24);
		Def->MeshAssetPath = WeaponMeshPath(TEXT("WP_Shotgun"));
		// 1-Medical SoundEventReader: Shotgun + FiredSound / Hands + ReloadShotgun.
		Def->FireSoundCue = TEXT("weapons_shotgun_launch");
		Def->ReloadSoundCue = TEXT("weapons_shotgun_reload");
	}
	else if (
		Key.Equals(TEXT("ChemicalThrower"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("ChemThrower"), ESearchCase::IgnoreCase))
	{
		// weapons-config: mag 100 acc 0 rate 1 reload 1; Napalm stack 400, Burning 1.2 / Heat 1.
		// ChemicalThrower.uc BaseAmmoConsumptionRate=0.05; BeamTickInterval 0.1 PLAUSIBLE.
		Def = MakeDef(
			EWeaponFireMode::Beam,
			TEXT("ChemicalThrower"),
			3.0f, // PLAUSIBLE per-tick direct damage
			10000.0f,
			0.0f,
			10.0f, // PLAUSIBLE — 1/BeamTickInterval for CanFireNow gate
			100,
			300, // PLAUSIBLE — Napalm stack 400 minus full mag
			1.0f,
			false,
			0.0f,
			0.0f,
			0.0f,
			0.0f,
			0.0f,
			1,
			0.0f,
			0.1f,
			800.0f, // PLAUSIBLE beam reach
			EBeamStatus::Burning);
		Def->MeshAssetPath = WeaponMeshPath(TEXT("WP_ChemicalThrower"));
		Def->bAutomatic = true; // Beam ticks while Fire is held
	}
	else if (Key.Equals(TEXT("Crossbow"), ESearchCase::IgnoreCase))
	{
		// weapons-config: mag 5 acc 0 rate 1 reload 1 zoom; Steel-Tip AIGenericPiercing 450.
		// Crossbow_Bolt.uc InitialVelocity=6000; slice mag 1 / reserve 6 / reload 1.5 PLAUSIBLE.
		// TODO: bolt retrieval after impact.
		Def = MakeDef(
			EWeaponFireMode::Projectile,
			TEXT("Crossbow"),
			45.0f, // PLAUSIBLE — config lacks player GenericPiercing for Steel-Tip
			10000.0f,
			0.0f,
			1.0f,
			1,
			6,
			1.5f,
			true,
			0.0f,
			0.0f,
			6000.0f,
			0.0f,
			10.0f);
		Def->MeshAssetPath = WeaponMeshPath(TEXT("WP_Crossbow"));
		Def->FireSoundCue = TEXT("weapons_xbow_launch");
	}

	if (Def)
	{
		Cache.Add(InWeaponName, TStrongObjectPtr<UShockWeaponDef>(Def));
	}
	return Def;
}
