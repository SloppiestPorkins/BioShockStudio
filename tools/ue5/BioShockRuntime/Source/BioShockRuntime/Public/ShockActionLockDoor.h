#pragma once

#include "ShockAction.h"
#include "ShockActionLockDoor.generated.h"

class UWorld;

/** UnrealScript `ActionLockDoor`. Sets AShockDoor locked when present; else records request. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionLockDoor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionLockDoor();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
