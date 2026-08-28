#pragma once

#include "ShockAction.h"
#include "ShockActionSetMovableSpotlightState.generated.h"

class UWorld;

/** UnrealScript `ActionSetMovableSpotlightState`. Records on/off; no spotlight yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetMovableSpotlightState : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetMovableSpotlightState();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpotlightLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bSpotlightOn = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSpotlightLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InSpotlight, bool bInOn);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetSpotlightOn() const { return bSpotlightOn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSpotlightLabel() const { return LastSpotlightLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSetState();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
