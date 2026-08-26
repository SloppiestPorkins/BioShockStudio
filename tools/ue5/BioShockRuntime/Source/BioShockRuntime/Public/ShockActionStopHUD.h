#pragma once

#include "ShockAction.h"
#include "ShockActionStopHUD.generated.h"

/** UnrealScript `ActionStopHUD`. Records stop request; no Flash HUD yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionStopHUD : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionStopHUD();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bStopRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetStopRequested() const { return bStopRequested; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestStop();
};
