#pragma once

#include "ShockAction.h"
#include "ShockActionSetPlayerFOV.generated.h"

/** UnrealScript `ActionSetPlayerFOV`. Records desired FOV; no camera yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetPlayerFOV : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionSetPlayerFOV();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float FOV = 0.f;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LastFOV = 0.f;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(float InFOV);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetFOV() const { return FOV; }
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
