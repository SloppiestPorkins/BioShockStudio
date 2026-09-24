#pragma once

#include "ShockAction.h"
#include "ShockActionWaitForGoal.generated.h"

class UWorld;

/**
 * UnrealScript `ActionWaitForGoal`: wait for the labeled AI's named scripted movement goal to
 * complete/fail, or for the optional TimeOut. UShockScriptRunner treats this as a latent action.
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

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastSatisfied = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float WaitStartedAt = -1.0f;

	/** UC return: 0 completed (including when the named goal doesn't exist -- confirmed against
	 * the shipped UnrealEd guide, not a guess), 1 explicit failure, 2 timeout, -1 pending. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 Result = -1;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, const FString& InGoalName, float InTimeOut);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetTimeOut() const { return TimeOut; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastGoalName() const { return LastGoalName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastSatisfied() const { return bLastSatisfied; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestWait();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool PrepareWait(UWorld* World, float WorldTimeSeconds);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool IsReady(UWorld* World, float WorldTimeSeconds);

	UFUNCTION(BlueprintPure, Category="BioShock|Action")
	int32 GetResult() const { return Result; }

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
