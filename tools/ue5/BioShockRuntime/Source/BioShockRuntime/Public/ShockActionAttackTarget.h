#pragma once

#include "ShockAction.h"
#include "ShockActionAttackTarget.generated.h"

class AShockPawn;
class UWorld;

/**
 * UnrealScript `ActionAttackTarget` (ShockAI.U): tell AIs labeled AILabel to attack TargetLabel
 * (immediate ScriptedAttackTarget, or AddTargetToAttackOnSight when bAttackOnSight).
 * First slice records the request; no AI combat / label foreach yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAttackTarget : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAttackTarget();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bAttackOnSight = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastRequestedAILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastRequestedTargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastRequestedOnSight = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, FName InTargetLabel, bool bInAttackOnSight);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetAILabel() const { return AILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetTargetLabel() const { return TargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetAttackOnSight() const { return bAttackOnSight; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastRequestedAILabel() const { return LastRequestedAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastRequestedTargetLabel() const { return LastRequestedTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool WasLastRequestedOnSight() const { return bLastRequestedOnSight; }

	/** Records the attack order. Returns false if either label is None. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAttack();

	/**
	 * Playable-slice stand-in: records RequestAttack then ApplyAuthoredDamage on Target.
	 * No label foreach / ScriptedAttackTarget.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyImmediateDamage(AShockPawn* Target, float DamageAmount);

	/**
	 * Records RequestAttack; if TargetLabel resolves to a ShockPawn, applies authored damage.
	 * Returns true when the request was recorded (damage is best-effort).
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAttackInWorld(UWorld* World, float DamageAmount = 1.0f);
};
