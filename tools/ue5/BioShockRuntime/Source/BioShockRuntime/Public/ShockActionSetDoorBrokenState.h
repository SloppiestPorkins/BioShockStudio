#pragma once

#include "ShockAction.h"
#include "ShockActionSetDoorBrokenState.generated.h"

class UWorld;

/** UnrealScript `ActionSetDoorBrokenState`. ApplyInWorld stores broken flag on ShockPlayer by door label. */
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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
