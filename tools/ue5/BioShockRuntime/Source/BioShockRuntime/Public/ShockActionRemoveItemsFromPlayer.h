#pragma once

#include "ShockActionShockInventory.h"
#include "ShockActionRemoveItemsFromPlayer.generated.h"

class UWorld;

/**
 * UnrealScript `ActionRemoveItemsFromPlayer` (ActionShockInventory).
 * ApplyInWorld subtracts StackSize from the local ShockPlayer inventory map.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionRemoveItemsFromPlayer : public UShockActionShockInventory
{
	GENERATED_BODY()

public:
	UShockActionRemoveItemsFromPlayer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastRemovedItemClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LastRemovedStackSize = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LastAppliedCount = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastRemovedItemClass() const { return LastRemovedItemClass; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLastRemovedStackSize() const { return LastRemovedStackSize; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLastAppliedCount() const { return LastAppliedCount; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestRemove();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
