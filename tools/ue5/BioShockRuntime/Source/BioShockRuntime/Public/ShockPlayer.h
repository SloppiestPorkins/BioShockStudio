#pragma once

#include "ShockPawn.h"
#include "ShockPlayer.generated.h"

class AShockWeapon;

/** UnrealScript `ShockPlayer`. CollisionRadius=34 is on this class's own defaults, not the parent. */
UCLASS()
class BIOSHOCKRUNTIME_API AShockPlayer : public AShockPawn
{
	GENERATED_BODY()

public:
	AShockPlayer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<AShockWeapon> EquippedWeapon;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void EquipWeapon(AShockWeapon* Weapon);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	AShockWeapon* GetEquippedWeapon() const { return EquippedWeapon; }

	/**
	 * Fires EquippedWeapon from Eye height along ControlRotation (or ActorRotation).
	 * Playable-slice stand-in — no input binding, no holdable inventory.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool TryFireEquippedWeapon();
};
