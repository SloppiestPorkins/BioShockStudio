#pragma once

#include "ShockAction.h"
#include "ShockActionEnableOrDisableHudMessages.generated.h"

/** UnrealScript `ActionEnableOrDisableHudMessages`. Records suppress flag; no HUD gate yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEnableOrDisableHudMessages : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEnableOrDisableHudMessages();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bDisableHudMessages = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastDisableHudMessages = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInDisable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetDisableHudMessages() const { return bDisableHudMessages; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
