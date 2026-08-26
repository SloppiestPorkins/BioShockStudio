#pragma once

#include "ShockAction.h"
#include "ShockActionDoorKeypadUsed.generated.h"

/** UnrealScript `ActionDoorKeypadUsed`. Records keypad label + Success. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDoorKeypadUsed : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDoorKeypadUsed();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName DoorKeypadControlLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bSuccess = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastDoorKeypadControlLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InKeypad, bool bInSuccess);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetSuccess() const { return bSuccess; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastDoorKeypadControlLabel() const { return LastDoorKeypadControlLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestUsed();
};
