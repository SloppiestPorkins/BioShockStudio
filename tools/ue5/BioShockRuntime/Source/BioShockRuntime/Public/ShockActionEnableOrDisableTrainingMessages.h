#pragma once

#include "ShockAction.h"
#include "ShockActionEnableOrDisableTrainingMessages.generated.h"

/** UnrealScript `ActionEnableOrDisableTrainingMessages`. Records enable flag; no training manager yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEnableOrDisableTrainingMessages : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEnableOrDisableTrainingMessages();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnableTrainingMessages = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastEnableTrainingMessages = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(bool bInEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnableTrainingMessages() const { return bEnableTrainingMessages; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
