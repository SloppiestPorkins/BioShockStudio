#pragma once

#include "ShockAction.h"
#include "ShockActionSetMovableSpotlightTarget.generated.h"

class UWorld;

/** UnrealScript `ActionSetMovableSpotlightTarget`. Records track request; no spotlight yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetMovableSpotlightTarget : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetMovableSpotlightTarget();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpotlightLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSpotlightLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetActorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InSpotlight, FName InTarget);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSpotlightLabel() const { return LastSpotlightLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetActorLabel() const { return LastTargetActorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSetTarget();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
