#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "ShockAIGoal.generated.h"

class AActor;

/** Named objective for UShockAIBrain goal selection (mirrors ShockAI AI_Goal types). */
UENUM(BlueprintType)
enum class EShockAIGoalType : uint8
{
	Idle,
	Patrol,
	KillTarget,
	MoveTo,
	Flee,
	Investigate,
	React
};

/**
 * One candidate objective with parameters and priority.
 * Higher Priority wins when multiple goals are satisfiable.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockAIGoal : public UObject
{
	GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadOnly, Category="BioShock|AI")
	EShockAIGoalType GoalType = EShockAIGoalType::Idle;

	UPROPERTY(BlueprintReadOnly, Category="BioShock|AI")
	TObjectPtr<AActor> TargetActor;

	UPROPERTY(BlueprintReadOnly, Category="BioShock|AI")
	FVector TargetLocation = FVector::ZeroVector;

	UPROPERTY(BlueprintReadOnly, Category="BioShock|AI")
	FName TargetName = NAME_None;

	UPROPERTY(BlueprintReadOnly, Category="BioShock|AI")
	float Priority = 0.0f;
};
