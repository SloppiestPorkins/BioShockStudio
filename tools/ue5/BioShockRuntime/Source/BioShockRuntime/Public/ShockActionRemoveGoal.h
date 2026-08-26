#pragma once

#include "ShockAction.h"
#include "ShockActionRemoveGoal.generated.h"

/** UnrealScript `ActionRemoveGoal`. Records Target + goalName; no Tyrion goal stack yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionRemoveGoal : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionRemoveGoal();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString GoalName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastGoalName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, const FString& InGoalName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastGoalName() const { return LastGoalName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestRemove();
};
