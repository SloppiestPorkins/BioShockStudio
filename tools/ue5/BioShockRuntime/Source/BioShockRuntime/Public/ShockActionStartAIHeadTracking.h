#pragma once

#include "ShockAction.h"
#include "ShockActionStartAIHeadTracking.generated.h"

/** UnrealScript `ActionStartAIHeadTracking`. Records head-track request; no look-at yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionStartAIHeadTracking : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionStartAIHeadTracking();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName HeadTrackTargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bIsQuickLook = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Duration = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector Offset = FVector::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, FName InTarget, bool bInQuickLook, float InDuration, FVector InOffset);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestStart();
};
