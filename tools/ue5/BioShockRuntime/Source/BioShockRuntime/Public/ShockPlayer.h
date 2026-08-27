#pragma once

#include "ShockPawn.h"
#include "ShockPlayer.generated.h"

class AShockWeapon;
class UCameraComponent;
class UInputComponent;

/** UnrealScript `ShockPlayer`. CollisionRadius=34 is on this class's own defaults, not the parent. */
UCLASS()
class BIOSHOCKRUNTIME_API AShockPlayer : public AShockPawn
{
	GENERATED_BODY()

public:
	AShockPlayer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<AShockWeapon> EquippedWeapon;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|Camera")
	TObjectPtr<UCameraComponent> FirstPersonCamera;

	/**
	 * When true, SetupPlayerInputComponent binds Fire + Move/Look axes.
	 * Defaults true so GameMode-spawned PIE pawns walk/fire without an extra script call.
	 */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bPlayableInputEnabled = true;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void EquipWeapon(AShockWeapon* Weapon);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	AShockWeapon* GetEquippedWeapon() const { return EquippedWeapon; }

	/**
	 * Playable-slice helpers. AutoPossess stays Disabled (GameMode + PlayerStart spawn path).
	 * Needs project ActionMapping "Fire" and AxisMappings MoveForward/MoveRight/Turn/LookUp.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void EnablePlayableInput(bool bEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsPlayableInputEnabled() const { return bPlayableInputEnabled; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool TryFireEquippedWeapon();

	virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

private:
	void HandleFireInput();
	void MoveForward(float Value);
	void MoveRight(float Value);
	void TurnAtRate(float Value);
	void LookUpAtRate(float Value);
};
