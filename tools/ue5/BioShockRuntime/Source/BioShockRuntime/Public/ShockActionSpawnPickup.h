#pragma once

#include "ShockAction.h"
#include "ShockActionSpawnPickup.generated.h"

/**
 * UnrealScript `ActionSpawnPickup` (via ActionSpawnActorAtActorLocation).
 * Records class / labels / stack; no pickup spawn yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSpawnPickup : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSpawnPickup();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName PickupClassName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ItemClassName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 StackSize = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bStartsPhysical = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetActorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(
		FName InActorLabel,
		FName InTarget,
		FName InPickupClass,
		FName InItemClass,
		int32 InStack,
		bool bInStartsPhysical);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetActorLabel() const { return LastTargetActorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetStackSize() const { return StackSize; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSpawn();
};
