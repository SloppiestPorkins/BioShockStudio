#pragma once

#include "ShockAction.h"
#include "ShockActionInitiateDamage.generated.h"

class UWorld;

/** UnrealScript `ActionInitiateDamage`. ApplyInWorld applies stand-in damage via UShockDamageLibrary. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionInitiateDamage : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionInitiateDamage();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName DamagerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SourceLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName DamageClassName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float OverrideInitialVelocity = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LastAppliedCount = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InDamager, FName InSource, FName InTarget, FName InDamageClass, float InVelocity);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLastAppliedCount() const { return LastAppliedCount; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestDamage();

	/** Resolves TargetLabel and applies stand-in damage (no damage-class lookup yet). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
