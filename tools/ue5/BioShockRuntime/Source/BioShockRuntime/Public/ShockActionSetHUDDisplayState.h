#pragma once

#include "ShockAction.h"
#include "ShockActionSetHUDDisplayState.generated.h"

/** UnrealScript `ActionSetHUDDisplayState`. Records EnableHUD; no HUD widget yet. */
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
};
