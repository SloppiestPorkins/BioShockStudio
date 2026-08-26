#pragma once

#include "ShockAction.h"
#include "ShockActionUnlockDoor.generated.h"

/** UnrealScript `ActionUnlockDoor`: unlock door by DoorLabel. Records request only. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionUnlockDoor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionUnlockDoor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName DoorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastUnlockedDoorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InDoorLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastUnlockedDoorLabel() const { return LastUnlockedDoorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestUnlock();
};
