#pragma once

#include "ShockAction.h"
#include "ShockActionDisableOrEnableAdaptiveDifficulty.generated.h"

/** UnrealScript `ActionDisableOrEnableAdaptiveDifficulty`. Records enable flag; no difficulty mgr yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDisableOrEnableAdaptiveDifficulty : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDisableOrEnableAdaptiveDifficulty();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnable = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastEnable = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnable() const { return bEnable; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
