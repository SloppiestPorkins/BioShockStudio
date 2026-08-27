#pragma once

#include "ShockAction.h"
#include "ShockActionShowNeedleElement.generated.h"

/** UnrealScript `ShowNeedleElement`. Records show request; no HUD needle yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionShowNeedleElement : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionShowNeedleElement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShowRequested = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetShowRequested() const { return bShowRequested; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestShow();
};
