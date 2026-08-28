#pragma once

#include "ShockAction.h"
#include "ShockActionTweakAIHearing.generated.h"

class UWorld;

/**
 * UnrealScript `ActionTweakAIHearing`: turn AI hearing on/off by label.
 * ApplyInWorld writes bHearingOn on labeled BaseShockAI (no hearing component).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionTweakAIHearing : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionTweakAIHearing();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AIClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bTurnHearingOn = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTweakedAILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastTurnHearingOn = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, bool bInTurnHearingOn);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetTurnHearingOn() const { return bTurnHearingOn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTweakedAILabel() const { return LastTweakedAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastTurnHearingOn() const { return bLastTurnHearingOn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestTweak();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
