#pragma once

#include "ShockAction.h"
#include "ShockActionHackTurret.generated.h"

/** UnrealScript `ActionHackTurret`. Records TurretLabel + SetHacked; no turret state yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionHackTurret : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionHackTurret();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TurretLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bSetHacked = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTurretLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTurret, bool bInHacked);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetSetHacked() const { return bSetHacked; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTurretLabel() const { return LastTurretLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestHack();
};
