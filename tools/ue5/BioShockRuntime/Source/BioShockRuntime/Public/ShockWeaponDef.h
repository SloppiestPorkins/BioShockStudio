#pragma once

#include "Engine/DataAsset.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "ShockWeaponDef.generated.h"

class AShockProjectile;

UENUM(BlueprintType)
enum class EWeaponFireMode : uint8
{
	Hitscan,
	Projectile,
	Melee,
	Shotgun,
	Beam,
};

UENUM(BlueprintType)
enum class EBeamStatus : uint8
{
	None,
	Burning,
	Electric,
	Freeze,
};

/** Per-ammo stimuli from weapons-config (GenericPiercing / Shocked / Burning / etc.). */
UENUM(BlueprintType)
enum class EAmmoEffect : uint8
{
	None,
	ArmorPiercing,
	AntiPersonnel,
	Electric,
	Incendiary,
	Explosive,
};

USTRUCT(BlueprintType)
struct FShockAmmoType
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "BioShock")
	FName Name;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "BioShock")
	float Damage = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "BioShock")
	EAmmoEffect Effect = EAmmoEffect::None;

	/** Independent reserve pool for this ammo type (not shared when cycling). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "BioShock")
	int32 ReserveAmmo = 0;
};

/**
 * Per-weapon tuning from Weapons.ini (`bioshock-tool weapons-config`) plus slice overrides.
 * Headless-constructable via Resolve(); no content-browser asset required.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockWeaponDef : public UDataAsset
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	FName WeaponName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	EWeaponFireMode FireMode = EWeaponFireMode::Hitscan;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float Damage = 20.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float Range = 10000.0f;

	/** From Weapons.ini BaseAccuracy. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float Spread = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float FireRate = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 MagazineSize = 1;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 ReserveAmmo = 0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float ReloadSeconds = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCanZoom = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	TSubclassOf<AShockProjectile> ProjectileClass;

	/** PLAUSIBLE: melee swing arc half-angle in degrees (Wrench collision phantom stand-in). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float MeleeArc = 90.0f;

	/** PLAUSIBLE: melee reach in uu (Wrench phantom radius stand-in). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float MeleeReach = 180.0f;

	/** PLAUSIBLE: launch speed when FireMode is Projectile. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float ProjectileInitialSpeed = 2500.0f;

	/** Outer blast radius; 0 = direct-hit damage only. Frag grenade uc = 650. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float ProjectileImpactRadius = 0.0f;

	/** PLAUSIBLE: projectile lifetime in seconds. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float ProjectileLifeSeconds = 10.0f;

	/** Per-pellet traces when FireMode is Shotgun (`Shotgun_00Buck.uc` NumTracesToFire=8). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 PelletCount = 1;

	/** Cone half-angle in degrees (`Shotgun_00Buck.uc` SpreadOfFire ~910/65536*360 ≈ 5°; PLAUSIBLE 6). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float PelletSpreadDeg = 0.0f;

	/** Seconds between beam ticks when FireMode is Beam. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float BeamTickInterval = 0.1f;

	/** Beam trace length in uu when FireMode is Beam. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	float BeamRange = 800.0f;

	/** Status applied to struck pawns each beam tick. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock")
	EBeamStatus BeamStatus = EBeamStatus::None;

	/** Alternate ammo types (index 0 = default round; independent reserve per entry). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "BioShock")
	TArray<FShockAmmoType> AmmoTypes;

	/**
	 * First-person viewmodel under /Game/BioShockWeapons/WP_<Name>/WP_<Name>.
	 * Empty when the viewmodel is not a skeletal mesh (e.g. Wrench is StaticMesh in ShockGame.U).
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "BioShock")
	FSoftObjectPath MeshAssetPath;

	/** Resolve baked defs for TommyGun / Wrench / GrenadeLauncher / Pistol / Shotgun / ChemicalThrower / Crossbow. Unknown keys return nullptr. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	static UShockWeaponDef* Resolve(FName InWeaponName);
};

UCLASS()
class BIOSHOCKRUNTIME_API UShockWeaponDefLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	static UShockWeaponDef* ResolveWeaponDef(FName InWeaponName)
	{
		return UShockWeaponDef::Resolve(InWeaponName);
	}
};
