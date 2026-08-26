#pragma once

#include "ShockAction.h"
#include "ShockActionWaitUntilActorHasLanded.generated.h"

/** UnrealScript `ActionWaitUntilActorHasLanded`. Records TargetLabel; no latent wait yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionWaitUntilActorHasLanded : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionWaitUntilActorHasLanded();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestWait();
};
