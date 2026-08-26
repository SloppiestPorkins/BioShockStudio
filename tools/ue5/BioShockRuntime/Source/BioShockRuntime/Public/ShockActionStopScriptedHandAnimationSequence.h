#pragma once

#include "ShockAction.h"
#include "ShockActionStopScriptedHandAnimationSequence.generated.h"

/** UnrealScript `ActionStopScriptedHandAnimationSequence`. Records stop; twin of Start. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionStopScriptedHandAnimationSequence : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionStopScriptedHandAnimationSequence();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bStopped = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetStopped() const { return bStopped; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestStop();
};
