#pragma once

#include "ShockActionShockInventory.h"
#include "ShockActionGiveItemsToPlayer.generated.h"

/**
 * UnrealScript `ActionGiveItemsToPlayer`: AddStackToInventory(ItemClass, StackSize) on local
 * ShockPlayer. First slice records the grant request; no inventory system yet.
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

	/** Records the grant. Returns false if ItemClass is None or StackSize <= 0. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestGive();
};
