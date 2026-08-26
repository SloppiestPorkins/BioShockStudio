#pragma once

#include "ShockAction.h"
#include "ShockActionSpawnReactiveActor.generated.h"

/**
 * UnrealScript `ActionSpawnReactiveActor` (via ActionSpawnActorAtActorLocation).
 * First slice records class / labels / StartsPhysical; no spawn yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSpawnReactiveActor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSpawnReactiveActor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ReactiveActorClassName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bStartsPhysical = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetActorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InActorLabel, FName InTarget, FName InClass, bool bInStartsPhysical);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetActorLabel() const { return LastTargetActorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetStartsPhysical() const { return bStartsPhysical; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSpawn();
};
