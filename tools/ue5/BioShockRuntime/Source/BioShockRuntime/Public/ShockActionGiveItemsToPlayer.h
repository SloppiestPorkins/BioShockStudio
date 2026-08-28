#pragma once

#include "ShockActionShockInventory.h"
#include "ShockActionGiveItemsToPlayer.generated.h"

class UWorld;

/**
 * UnrealScript `ActionGiveItemsToPlayer`: AddStackToInventory(ItemClass, StackSize) on the
 * local ShockPlayer (first placed ShockPlayer in editor/headless when no possessed pawn).
 * No Item actors, no inventory-warning UI, no max-stack clamp.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionGiveItemsToPlayer : public UShockActionShockInventory
{
	GENERATED_BODY()

public:
	UShockActionGiveItemsToPlayer();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastGrantedItemClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LastGrantedStackSize = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastGrantedItemClass() const { return LastGrantedItemClass; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLastGrantedStackSize() const { return LastGrantedStackSize; }

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LastAppliedCount = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLastAppliedCount() const { return LastAppliedCount; }

	/** Records the grant. Returns false if ItemClass is None or StackSize <= 0. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestGive();

	/** UC execute(): grant onto the local / first ShockPlayer. Returns 1 on success. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
