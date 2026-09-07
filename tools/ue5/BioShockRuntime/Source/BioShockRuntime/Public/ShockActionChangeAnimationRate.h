#pragma once

#include "ShockAction.h"
#include "ShockActionChangeAnimationRate.generated.h"

class UWorld;

/**
 * UnrealScript `ActionChangeAnimationRate`. Records the rate request and, when a matching
 * AShockAnimatedProp exists, sets its spin / keyframe rate scale.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangeAnimationRate : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangeAnimationRate();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

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

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LastAppliedRate = 0.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, FName InAnim, float InRate, float InTime);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetTargetAnimationRate() const { return TargetAnimationRate; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetLastAppliedRate() const { return LastAppliedRate; }

	/** Records LastTargetLabel. Pair with ApplyInWorld / ApplyRateInWorld for the real effect. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestChange();

	/** Find AShockAnimatedProp by TargetLabel and set its rate scale. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyRateInWorld(UWorld* World);
};
