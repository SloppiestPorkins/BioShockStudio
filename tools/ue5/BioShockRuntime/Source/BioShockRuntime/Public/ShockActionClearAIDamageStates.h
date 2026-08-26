#pragma once

#include "ShockAction.h"
#include "ShockActionClearAIDamageStates.generated.h"

/** UnrealScript `ActionClearAIDamageStates`. Records AILabel; no damage-state clear yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionClearAIDamageStates : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionClearAIDamageStates();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestClear();
};
