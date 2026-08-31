#pragma once

#include "Components/ActorComponent.h"
#include "ShockAIGoal.h"
#include "ShockAIAbility.h"
#include "ShockAIBrain.generated.h"

class ABaseShockAI;
class AShockPawn;

/**
 * Goal-oriented AI controller on ABaseShockAI.
 * Picks the highest-priority satisfiable goal each think tick and runs the achieving ability.
 */
UCLASS(ClassGroup=(BioShock), meta=(BlueprintSpawnableComponent))
class BIOSHOCKRUNTIME_API UShockAIBrain : public UActorComponent
{
	GENERATED_BODY()

public:
	UShockAIBrain();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|AI")
	float ThinkInterval = 0.2f;

	/** PLAUSIBLE: flee when CurrentHealth / max drops below this fraction. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|AI")
	float FleeHealthFraction = 0.25f;

	UFUNCTION(BlueprintPure, Category="BioShock|AI")
	EShockAIGoalType GetActiveGoalType() const;

	UFUNCTION(BlueprintPure, Category="BioShock|AI")
	FName GetActiveAbilityName() const;

	UFUNCTION(BlueprintPure, Category="BioShock|AI")
	int32 GetAbilityCount() const { return Abilities.Num(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|AI")
	void InitializeForAI(ABaseShockAI* AI);
	void Think(float DeltaSeconds);
	void NotifyAggro(AShockPawn* Instigator);
	void NotifyPendingKillTarget(AShockPawn* Target);

private:
	UPROPERTY()
	TArray<TObjectPtr<UShockAIAbility>> Abilities;

	UPROPERTY()
	TObjectPtr<UShockAIAbility> ActiveAbility;

	UPROPERTY()
	TObjectPtr<UShockAIGoal> ActiveGoal;

	UPROPERTY()
	TWeakObjectPtr<AShockPawn> PendingKillTarget;

	float ThinkAccumulator = 0.0f;

	void SeedDefaultAbilities(ABaseShockAI* AI);
	TArray<UShockAIGoal*> BuildCandidateGoals(ABaseShockAI* AI, float DeltaSeconds);
	UShockAIAbility* FindAbilityForGoal(const UShockAIGoal& Goal, const FShockAIContext& Context) const;
	void SwitchAbility(UShockAIAbility* NewAbility, UShockAIGoal* NewGoal, const FShockAIContext& Context);
	UShockAIGoal* MakeGoal(EShockAIGoalType Type, float Priority, AActor* TargetActor = nullptr);
};
