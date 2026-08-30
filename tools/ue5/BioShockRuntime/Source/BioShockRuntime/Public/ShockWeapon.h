#pragma once

#include "GameFramework/Actor.h"
#include "ShockWeapon.generated.h"

class AShockPawn;
class USkeletalMeshComponent;

/**
 * UnrealScript class `Weapon` (super `Holdable`).
 * Playable-slice stand-in: hitscan FireAt that damages AShockPawn.CurrentHealth.
 * Trace is pawn-object-type only (world static does not eat the shot). Not projectile
 * classes, not TommyGun mesh fire anims.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockWeapon : public AActor
{
	GENERATED_BODY()

public:
	AShockWeapon();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USkeletalMeshComponent> Mesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float HitscanDamage = 20.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float HitscanRange = 10000.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 FireCount = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TWeakObjectPtr<AShockPawn> LastHitPawn;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	int32 MagazineSize = 50;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	int32 RoundsInMagazine = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	int32 ReserveAmmo = 0;

	/** Rounds per second (TommyGun slice ~10). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	float FireRate = 10.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	float ReloadSeconds = 2.5f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	bool bAutoReload = true;

	/** When false, FireAt skips magazine/reload/rate gates (AI stand-ins). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	bool bEnforceAmmo = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Ammo")
	bool bIsReloading = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void ConfigureHitscan(float InDamage, float InRange);

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void ConfigureAmmo(int32 InMagazineSize, int32 InReserveAmmo, float InFireRate, float InReloadSeconds);

	/** Full magazine plus reserve pool (slice TommyGun start state). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void InitializeAmmoFullMag(int32 InReserveAmmo);

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	int32 GetFireCount() const { return FireCount; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	AShockPawn* GetLastHitPawn() const { return LastHitPawn.Get(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	int32 GetRoundsInMagazine() const { return RoundsInMagazine; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	int32 GetReserveAmmo() const { return ReserveAmmo; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	int32 GetMagazineSize() const { return MagazineSize; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	bool IsReloading() const { return bIsReloading; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	int32 AddReserveAmmo(int32 Amount);

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	bool Reload();

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void SetAutoReload(bool bEnable) { bAutoReload = bEnable; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void SetEnforceAmmo(bool bEnable) { bEnforceAmmo = bEnable; }

	/** Headless verify: advance reload countdown without real-time wait. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void AdvanceReloadForVerify(float DeltaSeconds);

	/** Headless verify: allow the next shot through the fire-rate gate. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void ClearFireCooldownForVerify();

	/** Headless verify: advance the fire-rate clock without real-time wait. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Ammo")
	void AdvanceFireRateClockForVerify(float DeltaSeconds);

	/**
	 * Line-trace from Start along Direction. On AShockPawn hit, ApplyAuthoredDamage.
	 * Returns true if a ShockPawn was damaged. Refuses when empty, reloading, or fire-rate gated.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	bool FireAt(AActor* InstigatorActor, FVector Start, FVector Direction);

private:
	void FinishReload();
	void LogAmmoState() const;
	void TryAutoReloadOnEmpty();
	float GetMinFireInterval() const;
	bool CanFireNow(UWorld* World) const;

	FTimerHandle ReloadTimerHandle;
	float ReloadCountdown = 0.0f;
	double LastFireWorldSeconds = -1.0;
};
