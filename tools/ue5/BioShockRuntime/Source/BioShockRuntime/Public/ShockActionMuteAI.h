#pragma once

#include "ShockAction.h"
#include "ShockActionMuteAI.generated.h"

/** UnrealScript `ActionMuteAI`: MuteAI(bShouldMuteAI) on AIs by label. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionMuteAI : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionMuteAI();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShouldMuteAI = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastMutedAILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastMuted = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, bool bInShouldMuteAI);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastMutedAILabel() const { return LastMutedAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastMuted() const { return bLastMuted; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestMute();
};
