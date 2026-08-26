#pragma once

#include "ShockAction.h"
#include "ShockActionInitiateDamage.generated.h"

/** UnrealScript `ActionInitiateDamage`. Records damage request; no combat yet. */
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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InDamager, FName InSource, FName InTarget, FName InDamageClass, float InVelocity);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestDamage();
};
