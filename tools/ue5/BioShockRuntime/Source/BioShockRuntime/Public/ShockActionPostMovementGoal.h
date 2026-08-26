#pragma once

#include "ShockAction.h"
#include "ShockActionPostMovementGoal.generated.h"

/**
 * UnrealScript `ActionPostMovementGoal`: post CharacterMoveToGoal on AI Target toward
 * DestinationLabel. First slice records the goal request; no Tyrion goal stack yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPostMovementGoal : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionPostMovementGoal();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName DestinationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString GoalName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 Priority = 50;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShouldRun = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastDestinationLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, FName InDestination, const FString& InGoalName, int32 InPriority, bool bInShouldRun);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastDestinationLabel() const { return LastDestinationLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetPriority() const { return Priority; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestPost();
};
