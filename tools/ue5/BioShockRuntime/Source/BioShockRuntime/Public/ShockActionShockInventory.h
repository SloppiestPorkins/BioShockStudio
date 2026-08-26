#pragma once

#include "ShockAction.h"
#include "ShockActionShockInventory.generated.h"

/**
 * UnrealScript `ActionShockInventory` (abstract): ItemClass + StackSize for inventory actions.
 */
UCLASS(Abstract, BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionShockInventory : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionShockInventory();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ItemClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 StackSize = 1;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void ConfigureInventory(FName InItemClass, int32 InStackSize);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetItemClass() const { return ItemClass; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetStackSize() const { return StackSize; }
};
