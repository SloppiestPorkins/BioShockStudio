#include "ShockWeaponDef.h"

#include "ShockProjectile.h"
#include "UObject/Package.h"

namespace
{
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
	float InPelletSpreadDeg = 0.0f)
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
	if (FireMode == EWeaponFireMode::Projectile)
	{
		Def->ProjectileClass = AShockProjectile::StaticClass();
	}
	return Def;
}
} // namespace

UShockWeaponDef* UShockWeaponDef::Resolve(FName InWeaponName)
{
	static TMap<FName, TObjectPtr<UShockWeaponDef>> Cache;
	if (const TObjectPtr<UShockWeaponDef>* Found = Cache.Find(InWeaponName))
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
	}
	else if (Key.Equals(TEXT("Wrench"), ESearchCase::IgnoreCase))
	{
		// weapons-config: mag 10 acc 0 rate 1 reload 1; WrenchAmmo AIBludgeoning 20.
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
	}
	else if (Key.Equals(TEXT("GrenadeLauncher"), ESearchCase::IgnoreCase))
	{
		// weapons-config: mag 6 rate 1 reload 1; Frag Grenade GenericPiercing 30 / Explosive 30;
		// GrenadeLauncher_FragGrenade.uc OuterDamageRadius=650.
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
	}

	if (Def)
	{
		Cache.Add(InWeaponName, Def);
	}
	return Def;
}
