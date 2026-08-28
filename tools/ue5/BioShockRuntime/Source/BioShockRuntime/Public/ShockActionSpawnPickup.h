#pragma once

#include "ShockAction.h"
#include "ShockActionSpawnPickup.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionSpawnPickup` (via ActionSpawnActorAtActorLocation).
 * RequestSpawn records class / labels / stack. SpawnInWorld places a TargetPoint
 * stand-in at the labeled actor — not a real pickup mesh or item grant.
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

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TWeakObjectPtr<AActor> LastSpawnedActor;

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
	AActor* GetLastSpawnedActor() const { return LastSpawnedActor.Get(); }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSpawn();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	AActor* SpawnAtLocation(UObject* WorldContextObject, FVector Location);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	AActor* SpawnInWorld(UWorld* World);
};
