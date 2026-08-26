#pragma once

#include "ShockAction.h"
#include "ShockActionActivateResurrectionStation.generated.h"

/** UnrealScript `ActionActivateResurrectionStation`. Records activate request only. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionActivateResurrectionStation : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionActivateResurrectionStation();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ResurrectionStationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bActivateStation = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastStationLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InStation, bool bInActivate);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetActivateStation() const { return bActivateStation; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastStationLabel() const { return LastStationLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestActivate();
};
