#pragma once

#include "ShockAction.h"
#include "ShockActionCloseDoor.generated.h"

class UWorld;

/** UnrealScript `ActionCloseDoor`. Drives AShockDoor when present; else records request. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionCloseDoor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionCloseDoor();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
