#pragma once

#include "ShockAction.h"
#include "ShockActionResetProtectorAttackTargets.generated.h"

/** UnrealScript `ActionResetProtectorAttackTargets`. Records ProtectorLabel; no reset yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionResetProtectorAttackTargets : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionResetProtectorAttackTargets();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ProtectorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastProtectorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InProtector);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastProtectorLabel() const { return LastProtectorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestReset();
};
