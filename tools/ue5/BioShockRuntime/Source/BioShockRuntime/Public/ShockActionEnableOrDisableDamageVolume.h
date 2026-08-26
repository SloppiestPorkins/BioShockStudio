#pragma once

#include "ShockAction.h"
#include "ShockActionEnableOrDisableDamageVolume.generated.h"

/** UnrealScript `ActionEnableOrDisableDamageVolume`. Records volume + enable; no volume gate yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionEnableOrDisableDamageVolume : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionEnableOrDisableDamageVolume();

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
