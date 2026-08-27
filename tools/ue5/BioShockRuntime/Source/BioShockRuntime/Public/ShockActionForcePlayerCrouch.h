#pragma once

#include "ShockAction.h"
#include "ShockActionForcePlayerCrouch.generated.h"

/** UnrealScript `ActionForcePlayerCrouch`. Records crouch flag; no player duck yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionForcePlayerCrouch : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionForcePlayerCrouch();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShouldCrouch = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInShouldCrouch);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetShouldCrouch() const { return bShouldCrouch; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestCrouch();
};
