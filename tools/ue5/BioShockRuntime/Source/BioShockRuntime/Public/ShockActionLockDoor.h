#pragma once

#include "ShockAction.h"
#include "ShockActionLockDoor.generated.h"

/** UnrealScript `ActionLockDoor`. Records lock request; twin of UnlockDoor. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionLockDoor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionLockDoor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName DoorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastLockedDoorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InDoorLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastLockedDoorLabel() const { return LastLockedDoorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestLock();
};
