#pragma once

#include "ShockAction.h"
#include "ShockActionEnableOrDisableLevelSwitching.generated.h"

/** UnrealScript `ActionEnableOrDisableLevelSwitching`. Records DisableLevelSwitching. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEnableOrDisableLevelSwitching : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEnableOrDisableLevelSwitching();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bDisableLevelSwitching = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastDisableLevelSwitching = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInDisable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetDisableLevelSwitching() const { return bDisableLevelSwitching; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastDisableLevelSwitching() const { return bLastDisableLevelSwitching; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
