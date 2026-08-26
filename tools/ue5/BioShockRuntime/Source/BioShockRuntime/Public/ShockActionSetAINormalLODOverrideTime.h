#pragma once

#include "ShockAction.h"
#include "ShockActionSetAINormalLODOverrideTime.generated.h"

/** UnrealScript `ActionSetAINormalLODOverrideTime`. Records AILabel + time; no LOD yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetAINormalLODOverrideTime : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetAINormalLODOverrideTime();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LODOverrideTime = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, float InTime);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetLODOverrideTime() const { return LODOverrideTime; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
