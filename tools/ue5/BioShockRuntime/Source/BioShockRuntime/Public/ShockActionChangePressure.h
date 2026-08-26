#pragma once

#include "ShockAction.h"
#include "ShockActionChangePressure.generated.h"

/**
 * UnrealScript `ActionChangePressure`: SetPressureForRegion(RegionName, DesiredPressure).
 * DesiredPressure is Engine.Actor.EPressureLevel — stored as uint8 until Engine.U enum is pinned.
 * First slice records the request; no pressure regions yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangePressure : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangePressure();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName RegionName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	uint8 DesiredPressure = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastRegionName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InRegion, uint8 InPressure);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	uint8 GetDesiredPressure() const { return DesiredPressure; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastRegionName() const { return LastRegionName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestChange();
};
