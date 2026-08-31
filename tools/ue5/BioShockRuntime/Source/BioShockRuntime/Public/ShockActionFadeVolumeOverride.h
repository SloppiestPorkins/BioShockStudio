#pragma once

#include "ShockAction.h"
#include "ShockActionFadeVolumeOverride.generated.h"

class UWorld;

/** UnrealScript `ActionFadeVolumeOverride`. ApplyInWorld stores volume/duration on the ShockPlayer. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionFadeVolumeOverride : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionFadeVolumeOverride();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Volume = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Duration = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LastVolume = 0.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(float InVolume, float InDuration);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetVolume() const { return Volume; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetLastVolume() const { return LastVolume; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestFade();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
