#pragma once

#include "ShockAction.h"
#include "ShockActionCloseDoor.generated.h"

/** UnrealScript `ActionCloseDoor`. Records close request; no door mechanics yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionCloseDoor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionCloseDoor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName DoorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bForceClose = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastClosedDoorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InDoorLabel, bool bInForceClose);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetForceClose() const { return bForceClose; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastClosedDoorLabel() const { return LastClosedDoorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestClose();
};
