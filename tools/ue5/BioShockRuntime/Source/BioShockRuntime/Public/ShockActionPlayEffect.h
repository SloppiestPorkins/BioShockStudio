#pragma once

#include "ShockAction.h"
#include "ShockActionPlayEffect.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionPlayEffect` (Scripting.U). Finds actors by `ActorLabel` and calls
 * `TriggerEffectEvent(EffectEvent,,,,,,,, EffectTag)` — R3.1/3.2: routes through
 * `UShockEffectsSubsystem::PlayEffect` (event/tag → particle+sound+decal bundle, keyword-matched
 * since the real per-event authoring tables were not recovered; see
 * `docs/research/effects-system.md`).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPlayEffect : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionPlayEffect();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

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

	/** Records the TriggerEffectEvent call and spawns the resolved presentation bundle. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool FireOnActor(AActor* Target);

	/** Find actors by ActorLabel and FireOnActor each. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 FireInWorld(UWorld* World);
};
