#pragma once

#include "ShockAction.h"
#include "ShockActionStopEffect.generated.h"

class AActor;

/**
 * UnrealScript `ActionStopEffect`: UnTriggerEffectEvent(EffectEvent, EffectTag) on actors labeled
 * ActorLabel. Twin of ActionPlayEffect. First slice records the stop intent; no FX tear-down.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionStopEffect : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionStopEffect();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName EffectEvent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName EffectTag;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastStoppedEvent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastStoppedTag;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastStoppedActorName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InEffectEvent, FName InEffectTag, FName InActorLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetEffectEvent() const { return EffectEvent; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastStoppedEvent() const { return LastStoppedEvent; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastStoppedTag() const { return LastStoppedTag; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastStoppedActorName() const { return LastStoppedActorName; }

	/** Records the UnTriggerEffectEvent call. Does not tear down FX. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool StopOnActor(AActor* Target);
};
