#pragma once

#include "ShockAction.h"
#include "ShockActionTriggerHavokForceActor.generated.h"

/** UnrealScript `ActionTriggerHavokForceActor`. Records Target; no Havok force yet. */
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
};
