#pragma once

#include "ShockAction.h"
#include "ShockActionDealShockingDamageInRadius.generated.h"

/** UnrealScript `ActionDealShockingDamageInRadius`. Records Tesla radius params; no stim set yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDealShockingDamageInRadius : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDealShockingDamageInRadius();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SourceActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float DamageAmount = 100.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 DamageType = 24;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 InnerRadius = 1024;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 OuterRadius = 1024;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 MaxNumBolts = 5;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName EffectClassName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float EffectTime = 3.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FVector2D NewBeamDelay = FVector2D::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSourceActorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(
		FName InSource,
		float InDamage,
		int32 InDamageType,
		int32 InInner,
		int32 InOuter,
		int32 InMaxNumBolts,
		FName InEffectClass,
		float InEffectTime,
		FVector2D InNewBeamDelay);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetDamageAmount() const { return DamageAmount; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetMaxNumBolts() const { return MaxNumBolts; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSourceActorLabel() const { return LastSourceActorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestDeal();
};
