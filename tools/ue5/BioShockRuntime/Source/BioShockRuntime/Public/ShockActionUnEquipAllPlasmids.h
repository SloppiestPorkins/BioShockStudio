#pragma once

#include "ShockAction.h"
#include "ShockActionUnEquipAllPlasmids.generated.h"

/** UnrealScript `ActionUnEquipAllPlasmids`. Clears plasmid slots on the local ShockPlayer. */
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

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyInWorld(UWorld* World);
};
