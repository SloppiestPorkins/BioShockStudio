#pragma once

#include "CoreMinimal.h"
#include "ShockAIGoal.h"
#include "UObject/Object.h"
#include "ShockAIAbility.generated.h"

class ABaseShockAI;
class UShockAIGoal;

UENUM(BlueprintType)
enum class EShockAIAbilityStatus : uint8
{
	Running,
	Succeeded,
	Failed
};

/** Per-tick context passed to UShockAIAbility::CanAchieve and Tick. */
USTRUCT(BlueprintType)
struct FShockAIContext
{
	GENERATED_BODY()

	UPROPERTY()
	TObjectPtr<ABaseShockAI> AI;

	UPROPERTY()
	TObjectPtr<const UShockAIGoal> Goal;

	float DeltaSeconds = 0.0f;
};

/**
 * Behaviour unit that achieves one or more EShockAIGoalType values.
 * Latent-safe: Enter/Tick/Exit must not block the game thread.
 */
UCLASS(Abstract, BlueprintType, EditInlineNew, DefaultToInstanced)
class BIOSHOCKRUNTIME_API UShockAIAbility : public UObject
{
	GENERATED_BODY()

public:
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category="BioShock|AI")
	TArray<EShockAIGoalType> AchievableGoals;

	virtual bool CanAchieve(const UShockAIGoal& Goal, const FShockAIContext& Context) const;
	virtual void Enter(const FShockAIContext& Context);
	virtual void Tick(const FShockAIContext& Context);
	virtual void Exit(const FShockAIContext& Context);
	virtual EShockAIAbilityStatus GetStatus() const { return Status; }

protected:
	UPROPERTY()
	EShockAIAbilityStatus Status = EShockAIAbilityStatus::Running;

	UPROPERTY()
	TWeakObjectPtr<ABaseShockAI> OwnerAI;
};
