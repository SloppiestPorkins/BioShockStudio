#pragma once

#include "ShockSecurityDevice.h"
#include "ShockTurret.generated.h"

class AShockPawn;
class AShockWeapon;
class UStaticMeshComponent;

/**
 * Minimum-security turret stand-in (Turret.uc / TurretMiniGun.uc defaults where known).
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockTurret : public AShockSecurityDevice
{
	GENERATED_BODY()

public:
	AShockTurret();

	/** TurretMiniGun.uc BaseFireRate=3 → 3 shots/s. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Turret")
	float FireInterval = 0.333333f;

	/** PLAUSIBLE — minigun trace damage; stimuli set only in shipped data. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Turret")
	float HitscanDamage = 8.0f;

	/** TurretMiniGunAmmo.uc AttackRange / TraceDistance. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Turret")
	float HitscanRange = 3000.0f;

	/** Turret.uc YawSpeed=90 (deg/s) for idle sweep. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Turret")
	float IdleSweepYawRate = 90.0f;

	UFUNCTION(BlueprintPure, Category = "BioShock|Security|Turret")
	int32 GetFireCountForVerify() const { return FireCount; }

protected:
	virtual void BeginPlay() override;
	virtual void TickDevice(float DeltaSeconds) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Security|Turret")
	TObjectPtr<UStaticMeshComponent> BarrelMesh;

	UPROPERTY()
	TObjectPtr<AShockWeapon> TurretWeapon;

	float FireCooldownRemaining = 0.0f;
	float IdleSweepYaw = 0.0f;
	int32 FireCount = 0;

	AShockPawn* FindBestTarget() const;
	void TryFireAt(AShockPawn* Target);
	void UpdateAimToward(const FVector& WorldLocation, float DeltaSeconds);
	void IdleSweep(float DeltaSeconds);
	void EnsureWeapon();
	void PlayTurretFireFeedback(const FVector& Muzzle, const FVector& End, bool bPawnHit);
};
