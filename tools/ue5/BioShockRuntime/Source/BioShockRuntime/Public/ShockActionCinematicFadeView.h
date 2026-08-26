#pragma once

#include "ShockAction.h"
#include "ShockActionCinematicFadeView.generated.h"

/** UnrealScript `ActionCinematicFadeView`: latent fade. First slice holds params + RequestFade. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionCinematicFadeView : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionCinematicFadeView();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float FadeAlphaStart = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float FadeAlphaEnd = 1.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Duration = 2.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float HoldDuration = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LastRequestedDuration = 0.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(float InAlphaStart, float InAlphaEnd, float InDuration, float InHold);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetDuration() const { return Duration; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetLastRequestedDuration() const { return LastRequestedDuration; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestFade();
};
