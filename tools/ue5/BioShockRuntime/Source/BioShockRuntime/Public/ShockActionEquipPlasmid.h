#pragma once

#include "ShockAction.h"
#include "ShockActionEquipPlasmid.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEquipPlasmid : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionEquipPlasmid();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Plasmid;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 SlotNumber = 0;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InPlasmid, int32 InSlot);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestEquip();
};
