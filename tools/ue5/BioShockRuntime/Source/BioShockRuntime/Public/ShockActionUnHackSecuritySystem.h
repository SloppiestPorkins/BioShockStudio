#pragma once

#include "ShockAction.h"
#include "ShockActionUnHackSecuritySystem.generated.h"

/** UnrealScript `ActionUnHackSecuritySystem`. Records un-hack request; no security mgr yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionUnHackSecuritySystem : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionUnHackSecuritySystem();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bUnHackRequested = false;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestUnHack();
};
