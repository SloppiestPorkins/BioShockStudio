#pragma once

#include "ShockAction.h"
#include "ShockActionDisableOrEnableResurrectionStation.generated.h"

/** UnrealScript `ActionDisableOrEnableResurrectionStation`. Records enable flag; no Vita-Chamber yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDisableOrEnableResurrectionStation : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDisableOrEnableResurrectionStation();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName StationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnable = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastStationLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InStation, bool bInEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnable() const { return bEnable; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastStationLabel() const { return LastStationLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
