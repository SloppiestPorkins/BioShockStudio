#pragma once

#include "ShockAction.h"
#include "ShockActionWaitForQuestLogToFinish.generated.h"

class UWorld;

/**
 * UnrealScript `ActionWaitForQuestLogToFinish` (ActionWaitForCriticalMessage). Playback code marks
 * the corresponding class on AShockPlayer; UShockScriptRunner keeps this action pending until the
 * mark clears or TimeoutSeconds expires.
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

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float WaitStartedAt = -1.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastTimedOut = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InQuestLogClass, float InTimeout);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetTimeoutSeconds() const { return TimeoutSeconds; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastQuestLogClassName() const { return LastQuestLogClassName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestWait();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool PrepareWait(UWorld* World, float WorldTimeSeconds);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool IsReady(UWorld* World, float WorldTimeSeconds);

	UFUNCTION(BlueprintPure, Category="BioShock|Action")
	bool DidLastWaitTimeOut() const { return bLastTimedOut; }

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
