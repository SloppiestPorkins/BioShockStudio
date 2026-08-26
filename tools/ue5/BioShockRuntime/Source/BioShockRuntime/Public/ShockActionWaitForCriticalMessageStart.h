#pragma once

#include "ShockAction.h"
#include "ShockActionWaitForCriticalMessageStart.generated.h"

/** UnrealScript `ActionWaitForCriticalMessageStart`. Records wait params; no CMQ wait yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionWaitForCriticalMessageStart : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionWaitForCriticalMessageStart();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName EffectEventToWaitFor;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float TimeoutSeconds = 60.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastEffectEventToWaitFor;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InEvent, float InTimeout, FName InActor);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetTimeoutSeconds() const { return TimeoutSeconds; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastEffectEventToWaitFor() const { return LastEffectEventToWaitFor; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestWait();
};
