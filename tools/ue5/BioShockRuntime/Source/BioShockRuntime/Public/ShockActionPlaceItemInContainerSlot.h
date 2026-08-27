#pragma once

#include "ShockActionShockInventory.h"
#include "ShockActionPlaceItemInContainerSlot.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPlaceItemInContainerSlot : public UShockActionShockInventory
{
	GENERATED_BODY()
public:
	UShockActionPlaceItemInContainerSlot();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ContainerLabel;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 Slot = 0;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bOverwriteExistingItem = false;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void ConfigureSlot(FName InContainer, int32 InSlot, bool bInOverwrite);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestPlace();
};
