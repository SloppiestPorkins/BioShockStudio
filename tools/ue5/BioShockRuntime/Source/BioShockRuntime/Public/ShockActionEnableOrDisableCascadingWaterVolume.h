#pragma once

#include "ShockAction.h"
#include "ShockActionEnableOrDisableCascadingWaterVolume.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionEnableOrDisableCascadingWaterVolume`. Toggles `AShockWaterVolume::bCascading`
 * (the waterfall/ripple look) on the labeled volume and refreshes its surface material.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEnableOrDisableCascadingWaterVolume : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEnableOrDisableCascadingWaterVolume();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName VolumeLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bEnableVolume = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastVolumeLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InVolume, bool bInEnable);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetEnableVolume() const { return bEnableVolume; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastVolumeLabel() const { return LastVolumeLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToActor(AActor* Target);

	/** Find VolumeLabel actor and ApplyToActor. */
	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
