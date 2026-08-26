#pragma once

#include "ShockAction.h"
#include "ShockActionWaitForGoal.generated.h"

/**
 * UnrealScript `ActionWaitForGoal`: wait for named AI goal (optional TimeOut).
 * First slice records the wait request; no Tyrion goal notifications yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionWaitForGoal : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionWaitForGoal();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString GoalName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float TimeOut = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastGoalName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, const FString& InGoalName, float InTimeOut);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetTimeOut() const { return TimeOut; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastGoalName() const { return LastGoalName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestWait();
};
