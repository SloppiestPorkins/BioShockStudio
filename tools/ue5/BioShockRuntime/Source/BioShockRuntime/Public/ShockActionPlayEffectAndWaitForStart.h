#pragma once

#include "ShockAction.h"
#include "ShockActionPlayEffectAndWaitForStart.generated.h"

/**
 * UnrealScript `ActionPlayEffectAndWaitForStart`. R3.1/3.2: resolves `ActorLabel`, plays the
 * effect bundle via `UShockEffectsSubsystem`, and returns immediately — the presentation spawn
 * is synchronous in this port, so "wait for start" and "started" are the same instant (no
 * latent re-poll needed the way the UE2 original waited on an async particle/audio handle).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPlayEffectAndWaitForStart : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionPlayEffectAndWaitForStart();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

	/** Python/Blueprint-visible entry point (FShockActionContext is a native-only struct). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyInWorld(UWorld* World);

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
