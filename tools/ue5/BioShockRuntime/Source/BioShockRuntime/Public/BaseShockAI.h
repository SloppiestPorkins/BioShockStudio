#pragma once

#include "ShockPawn.h"
#include "BaseShockAI.generated.h"

class UWorld;

/**
 * UnrealScript `BaseShockAI`. No states — playable-slice home for a spawnable AI pawn.
 * ScriptLabel mirrors level actor labels for Action* lookups (not a full label system).
 */
UCLASS()
class BIOSHOCKRUNTIME_API ABaseShockAI : public AShockPawn
{
	GENERATED_BODY()

public:
	ABaseShockAI();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ScriptLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AITypeName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<AShockPawn> CurrentScriptedAttackTarget;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TArray<FName> AttackOnSightLabels;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bVisionOn = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHearingOn = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bAlwaysSeePlayer = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bAffectVisionOfPlayerOnly = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bMuted = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bToldToWait = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCanAttack = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 ScriptedAIState = 2;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName PatrolName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MovementDestinationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString MovementGoalName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 MovementGoalPriority = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bMovementShouldRun = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector MovementGoalLocation = FVector::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	uint8 FullBodyHitReactions = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	uint8 QuickHitReactions = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LODOverrideTime = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 ScriptedSequenceRunNow = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bWaitForGoalSatisfied = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void ConfigureIdentity(FName InType, FName InLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FName GetScriptLabel() const { return ScriptLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void ScriptedAttackTarget(AShockPawn* Target);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void AddTargetToAttackOnSight(FName InTargetLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	AShockPawn* GetScriptedAttackTarget() const { return CurrentScriptedAttackTarget; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool HasAttackOnSightLabel(FName InTargetLabel) const;

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsVisionOn() const { return bVisionOn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsHearingOn() const { return bHearingOn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsMuted() const { return bMuted; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsToldToWait() const { return bToldToWait; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool CanAttack() const { return bCanAttack; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	int32 GetScriptedAIState() const { return ScriptedAIState; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FName GetPatrolName() const { return PatrolName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FName GetMovementDestinationLabel() const { return MovementDestinationLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool GetAlwaysSeePlayer() const { return bAlwaysSeePlayer; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	uint8 GetFullBodyHitReactions() const { return FullBodyHitReactions; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	uint8 GetQuickHitReactions() const { return QuickHitReactions; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	float GetLODOverrideTime() const { return LODOverrideTime; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	int32 GetScriptedSequenceRunNow() const { return ScriptedSequenceRunNow; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	bool IsWaitForGoalSatisfied() const { return bWaitForGoalSatisfied; }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	FString GetMovementGoalName() const { return MovementGoalName; }

	/** Editor actor label or ScriptLabel. Not a UFunction — C++ action helpers only. */
	static TArray<ABaseShockAI*> CollectLabeled(UWorld* World, FName Label);
};
