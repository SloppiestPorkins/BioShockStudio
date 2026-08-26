#pragma once

#include "ShockAction.h"
#include "ShockActionSetEffectsSystemContext.generated.h"

/** UnrealScript `ActionSetEffectsSystemContext`. Records context + target; no effects wiring yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetEffectsSystemContext : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetEffectsSystemContext();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Context;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	uint8 ContextAppliesTo = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRemoveInsteadOfAdd = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLogTriggerInfo = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastContext;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InContext, uint8 InAppliesTo, bool bInRemove, bool bInLog);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	uint8 GetContextAppliesTo() const { return ContextAppliesTo; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetRemoveInsteadOfAdd() const { return bRemoveInsteadOfAdd; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastContext() const { return LastContext; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
