#pragma once

#include "ShockAction.h"
#include "ShockActionSetDoorBrokenState.generated.h"

/** UnrealScript `ActionSetDoorBrokenState`. Records door + broken flag; no door state yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetDoorBrokenState : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetDoorBrokenState();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName DoorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bIsBroken = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastDoorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InDoor, bool bInBroken);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetIsBroken() const { return bIsBroken; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastDoorLabel() const { return LastDoorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
