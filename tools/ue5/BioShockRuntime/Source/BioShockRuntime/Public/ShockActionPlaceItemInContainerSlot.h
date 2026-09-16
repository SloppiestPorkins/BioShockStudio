#pragma once

#include "ShockActionShockInventory.h"
#include "ShockActionPlaceItemInContainerSlot.generated.h"

class UWorld;

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

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
