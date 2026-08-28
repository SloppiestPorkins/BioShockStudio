#pragma once

#include "ShockAction.h"
#include "ShockActionDisplayMapHUDRegion.generated.h"

class UWorld;

/** UnrealScript `ActionDisplayMapHUDRegion`. Holds description; no HUD ClientMessage yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDisplayMapHUDRegion : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDisplayMapHUDRegion();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString MapHUDRegionDescription;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InDescription);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestDisplay();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
