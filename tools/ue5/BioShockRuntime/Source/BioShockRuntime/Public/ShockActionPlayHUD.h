#pragma once

#include "ShockAction.h"
#include "ShockActionPlayHUD.generated.h"

class UWorld;

/** UnrealScript `ActionPlayHUD`. Records play request; no Flash HUD yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPlayHUD : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionPlayHUD();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bPlayRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetPlayRequested() const { return bPlayRequested; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestPlay();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
