#pragma once

#include "ShockPawn.h"
#include "ShockPlayer.generated.h"

class AShockWeapon;
class UCameraComponent;
class UInputComponent;
class UWorld;

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

	/**
	 * UnrealScript `ShockPlayer.AddStackToInventory` stand-in: merge StackSize into the
	 * named ItemClass. No Item actors, no UI warnings, no max-stack clamp.
	 * Returns the new stack total, or 0 if the grant is refused.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 AddStackToInventory(FName ItemClass, int32 StackSize);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 RemoveStackFromInventory(FName ItemClass, int32 StackSize);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 GetInventoryStack(FName ItemClass) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetForcedCrouch(bool bShouldCrouch);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsForcedCrouch() const { return bForcedCrouch; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetMovementDisabled(bool bDisable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsMovementDisabled() const { return bMovementDisabled; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetConceptEnabled(FName ConceptName, bool bEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool IsConceptEnabled(FName ConceptName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetTipPriority(FName TipName, int32 Priority);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 GetTipPriority(FName TipName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetScriptedSequenceRunNow(FName SequenceLabel, int32 RunNow);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	int32 GetScriptedSequenceRunNow(FName SequenceLabel) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetInputContext(FName Context, bool bUnset);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetCurrentInputContext() const { return CurrentInputContext; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	FName GetLastInputContext() const { return LastInputContext; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void SetRegionPressure(FName RegionName, uint8 Pressure);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	uint8 GetRegionPressure(FName RegionName) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void AssertFact(FName Slot1, const FString& Slot2, const FString& Slot3);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	void RetractFact(FName Slot1, const FString& Slot2, const FString& Slot3);

	UFUNCTION(BlueprintCallable, Category="BioShock|Player")
	bool HasFact(FName Slot1, const FString& Slot2, const FString& Slot3) const;

	/** Possessed ShockPlayer, or the first placed one (editor/headless). */
	static AShockPlayer* FindLocalOrFirst(UWorld* World);

	virtual void PossessedBy(AController* NewController) override;
	virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

private:
	void HandleFireInput();
	void MoveForward(float Value);
	void MoveRight(float Value);
	void TurnAtRate(float Value);
	void LookUpAtRate(float Value);

	UPROPERTY()
	TMap<FName, int32> InventoryStacks;

	UPROPERTY()
	TMap<FName, int32> TipPriorities;

	UPROPERTY()
	TMap<FName, bool> ConceptEnabled;

	UPROPERTY()
	bool bForcedCrouch = false;

	UPROPERTY()
	bool bMovementDisabled = false;

	UPROPERTY()
	TMap<FName, int32> ScriptedSequenceRunNow;

	UPROPERTY()
	FName CurrentInputContext;

	UPROPERTY()
	FName LastInputContext;

	UPROPERTY()
	TMap<FName, uint8> RegionPressure;

	UPROPERTY()
	TSet<FString> Facts;
};
