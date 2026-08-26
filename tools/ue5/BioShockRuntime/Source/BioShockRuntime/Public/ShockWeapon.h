#pragma once

#include "GameFramework/Actor.h"
#include "ShockWeapon.generated.h"

class AShockPawn;
class USkeletalMeshComponent;

/**
 * UnrealScript class `Weapon` (super `Holdable`).
 * Playable-slice stand-in: hitscan FireAt that damages AShockPawn.CurrentHealth.
 * Not ammo, not projectile classes, not TommyGun mesh fire anims.
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

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	void ConfigureHitscan(float InDamage, float InRange);

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	int32 GetFireCount() const { return FireCount; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	AShockPawn* GetLastHitPawn() const { return LastHitPawn.Get(); }

	/**
	 * Line-trace from Start along Direction. On AShockPawn hit, ApplyAuthoredDamage.
	 * Returns true if a ShockPawn was damaged.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Weapon")
	bool FireAt(AActor* InstigatorActor, FVector Start, FVector Direction);
};
