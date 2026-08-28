#pragma once

#include "ShockAction.h"
#include "ShockActionSetMaterialSwitchIndex.generated.h"

class UWorld;

/**
 * UnrealScript `ActionSetMaterialSwitchIndex`. MaterialSwitch object + Index.
 * First slice records Material name + Index; no material switch apply yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetMaterialSwitchIndex : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetMaterialSwitchIndex();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MaterialSwitchName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Index = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LastIndex = -1.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InMaterial, float InIndex);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetIndex() const { return Index; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetLastIndex() const { return LastIndex; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
