#pragma once

#include "ShockAction.h"
#include "ShockActionToggleAIWeaponVisibility.generated.h"

/** UnrealScript `ActionToggleAIWeaponVisibility`. Records show/hide; no weapon mesh yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionToggleAIWeaponVisibility : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionToggleAIWeaponVisibility();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShowWeapon = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, bool bInShow);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetShowWeapon() const { return bShowWeapon; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestToggle();
};
