#pragma once

#include "ShockAction.h"
#include "ShockActionIncrementNumRosesPlayerPickedUp.generated.h"

/** UnrealScript `ActionIncrementNumRosesPlayerPickedUp`. Records rose increment; no achievement yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionIncrementNumRosesPlayerPickedUp : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionIncrementNumRosesPlayerPickedUp();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRoseIncrementRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetRoseIncrementRequested() const { return bRoseIncrementRequested; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestIncrement();
};
