#pragma once

#include "ShockAction.h"
#include "ShockActionPlayEffectAndWaitForStart.generated.h"

/** UnrealScript `ActionPlayEffectAndWaitForStart`. Records effect wait params; no audio wait yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPlayEffectAndWaitForStart : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionPlayEffectAndWaitForStart();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName EffectEventToPlay;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName EffectTag;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float TimeoutSeconds = 60.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bSlowAlsoTriggerOnStaticActors = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLogTriggerInfo = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastEffectEventToPlay;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InEvent, FName InTag, float InTimeout, FName InActor, bool bInSlowStatic, bool bInLog);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetTimeoutSeconds() const { return TimeoutSeconds; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastEffectEventToPlay() const { return LastEffectEventToPlay; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestPlay();
};
