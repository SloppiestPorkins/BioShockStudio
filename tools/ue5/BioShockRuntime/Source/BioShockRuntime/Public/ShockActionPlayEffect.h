#pragma once

#include "ShockAction.h"
#include "ShockActionPlayEffect.generated.h"

class AActor;

/**
 * UnrealScript `ActionPlayEffect` (Scripting.U). Finds actors by `ActorLabel` and calls
 * `TriggerEffectEvent(EffectEvent,,,,,,,, EffectTag)`. This slice holds the params and records
 * the intended fire; the BioShock effect configurator is not ported yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPlayEffect : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionPlayEffect();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName EffectEvent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName EffectTag;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bSlowAlsoTriggerOnStaticActors = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLogTriggerInfo = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastFiredEvent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastFiredTag;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastFiredActorName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InEffectEvent, FName InEffectTag, FName InActorLabel);

	/** Records the TriggerEffectEvent call that script would make. Does not spawn FX. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool FireOnActor(AActor* Target);
};
