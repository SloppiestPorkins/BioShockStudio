#pragma once

#include "ShockAction.h"
#include "ShockActionSetAIRangedWeaponAccuracy.generated.h"

/**
 * UnrealScript `ActionSetAIRangedWeaponAccuracy`.
 * Records weapon label + Range pairs as FVector2D (X=Min, Y=Max); no weapon tweak yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetAIRangedWeaponAccuracy : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetAIRangedWeaponAccuracy();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName RangedWeaponLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector2D AccuracyRangeVsPlayer = FVector2D::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector2D AccuracyChangeTimeRangeVsPlayer = FVector2D::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector2D AccuracyRangeVsAI = FVector2D::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector2D AccuracyChangeTimeRangeVsAI = FVector2D::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastRangedWeaponLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(
		FName InLabel,
		FVector2D InAccPlayer,
		FVector2D InTimePlayer,
		FVector2D InAccAI,
		FVector2D InTimeAI);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastRangedWeaponLabel() const { return LastRangedWeaponLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FVector2D GetAccuracyRangeVsPlayer() const { return AccuracyRangeVsPlayer; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();
};
