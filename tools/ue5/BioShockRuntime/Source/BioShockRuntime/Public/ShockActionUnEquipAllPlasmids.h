#pragma once

#include "ShockAction.h"
#include "ShockActionUnEquipAllPlasmids.generated.h"

/** UnrealScript `ActionUnEquipAllPlasmids`. Records unequip request; no plasmid slots yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionUnEquipAllPlasmids : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionUnEquipAllPlasmids();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bUnequipRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetUnequipRequested() const { return bUnequipRequested; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestUnequip();
};
