#pragma once

#include "ShockAction.h"
#include "ShockActionHideNeedleElement.generated.h"

/** UnrealScript `HideNeedleElement`. Records hide request; no HUD needle yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionHideNeedleElement : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionHideNeedleElement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bHideRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetHideRequested() const { return bHideRequested; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestHide();
};
