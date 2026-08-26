#pragma once

#include "ShockAction.h"
#include "ShockActionWaitForQuestLogToFinish.generated.h"

/**
 * UnrealScript `ActionWaitForQuestLogToFinish` (ActionWaitForCriticalMessage).
 * First slice records QuestLog class name + TimeoutSeconds; no audio wait yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionWaitForQuestLogToFinish : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionWaitForQuestLogToFinish();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName QuestLogClassName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float TimeoutSeconds = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastQuestLogClassName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InQuestLogClass, float InTimeout);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetTimeoutSeconds() const { return TimeoutSeconds; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastQuestLogClassName() const { return LastQuestLogClassName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestWait();
};
