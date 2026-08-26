#pragma once

#include "ShockAction.h"
#include "ShockActionOpenDoor.generated.h"

/** UnrealScript `ActionOpenDoor`: Open / OpenAndHold by DoorLabel. Records request only. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionOpenDoor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionOpenDoor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName DoorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bStayOpen = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastOpenedDoorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InDoorLabel, bool bInStayOpen);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetStayOpen() const { return bStayOpen; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastOpenedDoorLabel() const { return LastOpenedDoorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestOpen();
};
