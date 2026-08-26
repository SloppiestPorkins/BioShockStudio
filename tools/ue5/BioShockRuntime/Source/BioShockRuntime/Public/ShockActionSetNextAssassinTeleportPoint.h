#pragma once

#include "ShockAction.h"
#include "ShockActionSetNextAssassinTeleportPoint.generated.h"

/** UnrealScript `ActionSetNextAssassinTeleportPoint`. Records assassin + teleport labels; no AI yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetNextAssassinTeleportPoint : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetNextAssassinTeleportPoint();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AssassinLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TeleportLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAssassinLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAssassin, FName InTeleport);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAssassinLabel() const { return LastAssassinLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
