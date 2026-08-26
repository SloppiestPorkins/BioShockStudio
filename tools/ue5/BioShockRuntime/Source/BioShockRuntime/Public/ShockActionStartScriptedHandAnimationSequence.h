#pragma once

#include "ShockAction.h"
#include "ShockActionStartScriptedHandAnimationSequence.generated.h"

/** UnrealScript `ActionStartScriptedHandAnimationSequence`. Records start; no hand seq yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionStartScriptedHandAnimationSequence : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionStartScriptedHandAnimationSequence();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bStarted = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetStarted() const { return bStarted; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestStart();
};
