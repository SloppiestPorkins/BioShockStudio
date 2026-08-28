#pragma once

#include "ShockAction.h"
#include "ShockActionTellAIToContinue.generated.h"

class UWorld;

/** UnrealScript `ActionTellAIToContinue`. ApplyInWorld clears bToldToWait. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionTellAIToContinue : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionTellAIToContinue();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestContinue();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
