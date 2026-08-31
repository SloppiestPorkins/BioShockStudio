#pragma once

#include "GameFramework/Actor.h"
#include "ShockSecurityDeviceTypes.h"
#include "ShockSecurityDevice.generated.h"

class UWorld;
class UStaticMeshComponent;

/**
 * Playable-slice base for BioShock security actors (turrets, cameras, bots).
 * Perception + allegiance only in this slice; subclasses implement TickDevice.
 */
UCLASS(Abstract)
class BIOSHOCKRUNTIME_API AShockSecurityDevice : public AActor
{
	GENERATED_BODY()

public:
	AShockSecurityDevice();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Security")
	FName DeviceLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Security")
	EShockDeviceAllegiance Allegiance = EShockDeviceAllegiance::Neutral;

	/** ShockAI ViewDistance default (Turret.uc PreBeginPlay / ShockAI.uc). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security")
	float DetectionRange = 3000.0f;

	/** PLAUSIBLE — standby acquisition cone; shipped turret StandbyFOV is 360 (full sweep). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security")
	float DetectionHalfAngleDeg = 90.0f;

	/** PLAUSIBLE — security turret HP; no explicit default found in decompiled Turret.uc. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security")
	float Health = 40.0f;

	/** PLAUSIBLE — alarm-active range multiplier when ShockPlayer reports security alarm on. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security")
	float AlarmRangeMultiplier = 1.5f;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	void SetDeviceLabel(FName Label) { DeviceLabel = Label; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	void SetAllegiance(EShockDeviceAllegiance NewAllegiance);

	UFUNCTION(BlueprintPure, Category = "BioShock|Security")
	EShockDeviceAllegiance GetAllegiance() const { return Allegiance; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	float ApplyAuthoredDamage(float Damage);

	UFUNCTION(BlueprintPure, Category = "BioShock|Security")
	float GetHealth() const { return Health; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	bool IsDeviceOperational() const;

	/** Security-system shutdown: Disabled for Duration, then Friendly→Neutral / Hostile restored. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	void ApplySecurityShutdown(float Duration);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	void AdvanceDeviceForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintPure, Category = "BioShock|Security")
	uint8 GetAllegianceForVerify() const { return static_cast<uint8>(Allegiance); }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	void ConfigureForVerify(FName Label, uint8 InAllegiance, float InHealth = 40.0f);

	static AShockSecurityDevice* FindByLabel(UWorld* World, FName Label);
	static void ForEachDevice(UWorld* World, TFunctionRef<void(AShockSecurityDevice*)> Fn);

protected:
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;

	/** Perception + behaviour; no-op when Disabled. */
	virtual void TickDevice(float DeltaSeconds);

	float GetEffectiveDetectionRange() const;
	bool CanDetectActor(const AActor* Target) const;
	bool IsOpposingSide(const AActor* Target) const;

	void OnDeviceKilled();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Security")
	TObjectPtr<UStaticMeshComponent> RootMesh;

	float SecurityShutdownRemaining = 0.0f;
	EShockDeviceAllegiance AllegianceBeforeShutdown = EShockDeviceAllegiance::Neutral;
	bool bInSecurityShutdown = false;
};
