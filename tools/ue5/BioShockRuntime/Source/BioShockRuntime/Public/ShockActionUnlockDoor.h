#pragma once

#include "ShockAction.h"
#include "ShockActionUnlockDoor.generated.h"

class UWorld;

/** UnrealScript `ActionUnlockDoor`: unlock by DoorLabel. Clears AShockDoor lock when present. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionUnlockDoor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionUnlockDoor();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
