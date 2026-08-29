#pragma once

#include "ShockAction.h"
#include "ShockActionSetHUDDisplayState.generated.h"

class UWorld;

/** UnrealScript `ActionSetHUDDisplayState`. ApplyInWorld sets HUD enabled on ShockPlayer. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetHUDDisplayState : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetHUDDisplayState();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnableHUD = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastEnableHUD = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnableHUD() const { return bEnableHUD; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastEnableHUD() const { return bLastEnableHUD; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
