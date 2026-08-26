#pragma once

#include "ShockAction.h"
#include "ShockActionStopAIHeadTracking.generated.h"

/** UnrealScript `ActionStopAIHeadTracking`. Records AILabel; no look-at stop yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionStopAIHeadTracking : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionStopAIHeadTracking();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestStop();
};
