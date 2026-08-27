#pragma once

#include "ShockAction.h"
#include "ShockActionDealDamage.generated.h"

class UWorld;

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDealDamage : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDealDamage();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float DamageAmount = 100.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float DamageChance = 1.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LastDamageAmount = 0.0f;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTargetLabel, float InDamageAmount, float InDamageChance);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetDamageAmount() const { return DamageAmount; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetLastDamageAmount() const { return LastDamageAmount; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestDamage();

	/** Find ShockPawns by TargetLabel and ApplyAuthoredDamage each. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
