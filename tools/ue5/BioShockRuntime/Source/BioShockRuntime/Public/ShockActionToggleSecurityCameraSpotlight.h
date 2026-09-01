#pragma once

#include "ShockAction.h"
#include "ShockActionToggleSecurityCameraSpotlight.generated.h"

class UWorld;

/** UnrealScript `ActionToggleSecurityCameraSpotlight`. Records camera + on/off; no spotlight yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionToggleSecurityCameraSpotlight : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionToggleSecurityCameraSpotlight();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName CameraLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bSpotlightOn = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastCameraLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InCamera, bool bInOn);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetSpotlightOn() const { return bSpotlightOn; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastCameraLabel() const { return LastCameraLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestToggle();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
