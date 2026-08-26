#pragma once

#include "ShockAction.h"
#include "ShockActionControlPlant.generated.h"

/** UnrealScript `ActionControlPlant`. Records Duration/bRevive; PlantShaders array deferred. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionControlPlant : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionControlPlant();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Duration = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bRevive = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LastDuration = 0.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(float InDuration, bool bInRevive);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetDuration() const { return Duration; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetRevive() const { return bRevive; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestControl();
};
