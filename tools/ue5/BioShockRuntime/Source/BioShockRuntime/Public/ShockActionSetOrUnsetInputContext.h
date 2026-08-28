#pragma once

#include "ShockAction.h"
#include "ShockActionSetOrUnsetInputContext.generated.h"

class UWorld;

/**
 * UnrealScript `ActionSetOrUnsetInputContext`: PUSH/POPINPUTCONTEXT console commands.
 * ApplyInWorld writes CurrentInputContext on the local ShockPlayer.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetOrUnsetInputContext : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetOrUnsetInputContext();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Context;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bUnset = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastContext;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InContext, bool bInUnset);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetUnset() const { return bUnset; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastContext() const { return LastContext; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestContext();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
