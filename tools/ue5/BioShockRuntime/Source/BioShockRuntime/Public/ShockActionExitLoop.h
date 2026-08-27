#pragma once

#include "ShockAction.h"
#include "ShockActionExitLoop.generated.h"

/** UnrealScript `ActionExitLoop`. Signals the current script loop to stop. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionExitLoop : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionExitLoop();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bExitRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestExitLoop();
};
