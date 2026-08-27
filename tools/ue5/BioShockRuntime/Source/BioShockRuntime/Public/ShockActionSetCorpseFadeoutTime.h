#pragma once

#include "ShockAction.h"
#include "ShockActionSetCorpseFadeoutTime.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetCorpseFadeoutTime : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionSetCorpseFadeoutTime();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float FadeOutDuration = 3.f;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InLabel, float InDuration);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetFadeOutDuration() const { return FadeOutDuration; }
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestFade();
};
