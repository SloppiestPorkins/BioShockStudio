#pragma once

#include "ShockAction.h"
#include "ShockActionAttackTarget.generated.h"

class AShockPawn;
class UWorld;

/**
 * UnrealScript `ActionAttackTarget` (ShockAI.U): tell AIs labeled AILabel to attack TargetLabel
 * (immediate ScriptedAttackTarget, or AddTargetToAttackOnSight when bAttackOnSight).
 *
 * ApplyInWorld resolves the first alive ShockPawn with TargetLabel, then every alive BaseShockAI
 * with AILabel (editor actor label or ScriptLabel). No sight cone, pathing, or weapons.
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

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LastAppliedCount = 0;

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLastAppliedCount() const { return LastAppliedCount; }

	/** Records the attack order. Returns false if either label is None. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAttack();

	/**
	 * Playable-slice stand-in: records RequestAttack then ApplyAuthoredDamage on Target.
	 * Not what execute() does — that is ApplyInWorld.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyImmediateDamage(AShockPawn* Target, float DamageAmount);

	/**
	 * UC execute(): first alive TargetLabel pawn, then each alive AILabel AI gets
	 * ScriptedAttackTarget or AddTargetToAttackOnSight. Returns how many AIs were ordered.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);

	/** @deprecated Use ApplyInWorld. Kept so older Python still binds. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAttackInWorld(UWorld* World, float DamageAmount = 0.0f);
};
