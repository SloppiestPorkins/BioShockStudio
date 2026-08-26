#pragma once

#include "ShockAction.h"
#include "ShockActionChangeAnimationRate.generated.h"

/** UnrealScript `ActionChangeAnimationRate`. Records rate request; no mesh playback yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangeAnimationRate : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangeAnimationRate();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetAnimationName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float TargetAnimationRate = 1.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float RateChangeTime = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, FName InAnim, float InRate, float InTime);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetTargetAnimationRate() const { return TargetAnimationRate; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestChange();
};
