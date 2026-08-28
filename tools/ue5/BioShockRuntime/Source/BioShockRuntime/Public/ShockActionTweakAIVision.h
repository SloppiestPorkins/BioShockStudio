#pragma once

#include "ShockAction.h"
#include "ShockActionTweakAIVision.generated.h"

class UWorld;

/**
 * UnrealScript `ActionTweakAIVision`: SetVisionState / SetPlayerVisionState / SetAlwaysSeePlayer
 * on AIs by label. ApplyInWorld writes the flags on labeled BaseShockAI (no perception component).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionTweakAIVision : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionTweakAIVision();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AIClass;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bTurnVisionOn = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bAffectVisionOfPlayerOnly = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bAlwaysSeePlayer = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTweakedAILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastTurnVisionOn = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, bool bInTurnVisionOn, bool bInPlayerOnly, bool bInAlwaysSeePlayer);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetTurnVisionOn() const { return bTurnVisionOn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTweakedAILabel() const { return LastTweakedAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastTurnVisionOn() const { return bLastTurnVisionOn; }

	/** Records the vision tweak. Returns false if AILabel is None. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestTweak();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
