#pragma once

#include "ShockSecurityDevice.h"
#include "ShockSecurityCamera.generated.h"

class USpotLightComponent;
class AShockPawn;

/**
 * Security camera stand-in (SecurityCamera.uc). No weapon — inspection timer raises alarm + bot spawn.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockSecurityCamera : public AShockSecurityDevice
{
	GENERATED_BODY()

public:
	AShockSecurityCamera();

	/** SecurityCamera.uc PlayerBaseInspectionTimerAmount=4. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Camera")
	float AlertThreshold = 4.0f;

	/** SecurityCamera.uc NumSecurityBotsSpawned=1. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Camera")
	int32 NumSecurityBotsSpawned = 1;

	/** PLAUSIBLE — alert buildup decay per second when target not visible. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Camera")
	float AlertDecayPerSecond = 1.0f;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security|Camera")
	void SetSpotlightEnabled(bool bEnabled);

	UFUNCTION(BlueprintPure, Category = "BioShock|Security|Camera")
	bool IsSpotlightEnabled() const { return bSpotlightEnabled; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Security|Camera")
	float GetAlertBuildupForVerify() const { return AlertBuildupSeconds; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Security|Camera")
	bool HasTriggeredAlertForVerify() const { return bAlertTriggered; }

protected:
	virtual void TickDevice(float DeltaSeconds) override;

private:
	AShockPawn* FindBestOpposingTarget() const;
	void RaiseAlert(AShockPawn* Target);
	void ResetAlertState();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Security|Camera", meta = (AllowPrivateAccess = "true"))
	TObjectPtr<USpotLightComponent> Spotlight;

	float AlertBuildupSeconds = 0.0f;
	bool bAlertTriggered = false;
	bool bSpotlightEnabled = false;
};
