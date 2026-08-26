#pragma once

#include "ShockAction.h"
#include "ShockActionForcePlayerMove.generated.h"

/** UnrealScript `ActionForcePlayerMove`. Records marker + rates; no latent move yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionForcePlayerMove : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionForcePlayerMove();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MarkerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MarkerBoneName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float TimeOut = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LocationDeltaPerSecond = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float RotationDeltaPerSecond = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastMarkerLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InMarker, FName InBone, float InTimeOut, float InLocDelta, float InRotDelta);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastMarkerLabel() const { return LastMarkerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetTimeOut() const { return TimeOut; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestMove();
};
