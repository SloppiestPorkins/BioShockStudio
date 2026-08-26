#pragma once

#include "ShockAction.h"
#include "ShockActionEnableOrDisableCascadingWaterVolume.generated.h"

/** UnrealScript `ActionEnableOrDisableCascadingWaterVolume`. Records volume + enable; no volume yet. */
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
};
