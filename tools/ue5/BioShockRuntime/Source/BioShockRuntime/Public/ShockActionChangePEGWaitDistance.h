#pragma once

#include "ShockAction.h"
#include "ShockActionChangePEGWaitDistance.generated.h"

/** UnrealScript `ActionChangePEGWaitDistance`. Records PEG + wait distance; no PEG tweak yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangePEGWaitDistance : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangePEGWaitDistance();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName PEGLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float WaitDistance = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastPEGLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InPEG, float InWaitDistance);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetWaitDistance() const { return WaitDistance; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastPEGLabel() const { return LastPEGLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
