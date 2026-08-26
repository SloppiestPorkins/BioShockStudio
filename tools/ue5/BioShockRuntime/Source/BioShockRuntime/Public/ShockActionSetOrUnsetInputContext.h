#pragma once

#include "ShockAction.h"
#include "ShockActionSetOrUnsetInputContext.generated.h"

/**
 * UnrealScript `ActionSetOrUnsetInputContext`: PUSH/POPINPUTCONTEXT console commands.
 * First slice records Context + Unset; no console / input stack yet.
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
};
