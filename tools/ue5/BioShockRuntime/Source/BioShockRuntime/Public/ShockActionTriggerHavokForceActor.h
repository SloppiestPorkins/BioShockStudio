#pragma once

#include "ShockAction.h"
#include "ShockActionTriggerHavokForceActor.generated.h"

class UWorld;

/** UnrealScript `ActionTriggerHavokForceActor`. PLAUSIBLE radial impulse at labeled force actor. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionTriggerHavokForceActor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionTriggerHavokForceActor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestTrigger();

	/** Find TargetLabel and apply PLAUSIBLE radial impulse when enabled. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
