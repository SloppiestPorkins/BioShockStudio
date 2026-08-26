#pragma once

#include "ShockAction.h"
#include "ShockActionDealDamageInRadius.generated.h"

/** UnrealScript `ActionDealDamageInRadius`. Records radii + damage; no stim set yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionDealDamageInRadius : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionDealDamageInRadius();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SourceActorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float DamageAmount = 100.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 DamageType = 8;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 InnerRadius = 256;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 OuterRadius = 256;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSourceActorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InSource, float InDamage, int32 InInner, int32 InOuter);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetDamageAmount() const { return DamageAmount; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSourceActorLabel() const { return LastSourceActorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestDeal();
};
